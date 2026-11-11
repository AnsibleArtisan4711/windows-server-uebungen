<#
.SYNOPSIS
    Legt Benutzer aus einer CSV-Datei im Active Directory an (idempotent, mit Protokoll).

.DESCRIPTION
    Pro CSV-Zeile (Spalten: Personalnummer;Vorname;Nachname;Abteilung;Position):
      1. Pflichtfelder pruefen.
      2. Existiert bereits ein Konto mit dieser Personalnummer (Attribut employeeID)? Dann ueberspringen.
      3. Zielort bestimmen: OU=<Abteilung>,<BaseOU>. Fehlt die OU, wird die Zeile als Fehler gemeldet.
      4. Anmeldenamen bilden: vorname.nachname, nur a-z, 0-9 und "-", Umlaute ersetzt,
         maximal 20 Zeichen. Ist der Name vergeben, wird eine Zahl angehaengt (anna.huber2).
      5. Konto anlegen: aktiv, Kennwortaenderung bei der ersten Anmeldung erzwungen.
    Das Startkennwort wird einmal abgefragt (nicht im Skript, nicht im Protokoll).
    Das Protokoll (CSV) enthaelt keine Kennwoerter.

.PARAMETER CsvPath
    Pfad zur CSV-Datei (Trennzeichen Semikolon, UTF-8).

.PARAMETER BaseOU
    OU, unter der die Abteilungs-OUs liegen.

.PARAMETER UpnSuffix
    Domaenenteil des UserPrincipalName.

.PARAMETER InitialPassword
    Optional als SecureString. Ohne Angabe wird abgefragt.

.PARAMETER LogPath
    Pfad der Protokolldatei (CSV).

.EXAMPLE
    .\01.1-benutzer-anlegen.ps1 -CsvPath .\01.1-mitarbeiter.csv -WhatIf

.EXAMPLE
    .\01.1-benutzer-anlegen.ps1 -CsvPath .\01.1-mitarbeiter.csv

.NOTES
    Zu Uebung 01.1 (Benutzerverwaltung im Active Directory).
    Mit -WhatIf wird nichts angelegt und auch kein Protokoll geschrieben.
    Bei -WhatIf werden zwei gleichnamige Personen nicht unterschieden, weil das erste Konto fehlt.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$CsvPath,

    [string]$BaseOU = 'OU=Benutzer,OU=Alpenwerk,DC=alpenwerk,DC=example',

    [string]$UpnSuffix = 'alpenwerk.example',

    [securestring]$InitialPassword,

    [string]$LogPath = (Join-Path -Path $PSScriptRoot -ChildPath 'benutzer-anlegen-protokoll.csv')
)

Import-Module ActiveDirectory -ErrorAction Stop

# --- Hilfsfunktionen ----------------------------------------------------

function Protect-FilterValue {
    # Verdoppelt Hochkommas, damit Namen wie O'Brien den -Filter nicht zerbrechen.
    param([string]$Text)
    return $Text.Replace("'", "''")
}

function ConvertTo-AsciiName {
    # "Jürgen" -> "juergen", "Böhm" -> "boehm", "Lang-Kurz" -> "lang-kurz"
    param([string]$Text)
    $t = $Text.Trim().ToLowerInvariant()
    $t = $t.Replace([string][char]0x00E4, 'ae').Replace([string][char]0x00F6, 'oe').Replace([string][char]0x00FC, 'ue').Replace([string][char]0x00DF, 'ss')
    $zerlegt = $t.Normalize([Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $zerlegt.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($c)
        }
    }
    return ($sb.ToString() -replace '[^a-z0-9\-]', '')
}

function Get-FreeSamName {
    # Bildet vorname.nachname (max. 20 Zeichen) und haengt bei Bedarf 2, 3, ... an.
    param([string]$Vorname, [string]$Nachname)
    $basis = '{0}.{1}' -f (ConvertTo-AsciiName $Vorname), (ConvertTo-AsciiName $Nachname)
    $n = 1
    do {
        $zusatz = if ($n -eq 1) { '' } else { [string]$n }
        $laenge = [Math]::Min($basis.Length, 20 - $zusatz.Length)
        $kandidat = $basis.Substring(0, $laenge).TrimEnd('.', '-') + $zusatz
        $belegt = Get-ADUser -Filter "SamAccountName -eq '$kandidat'" -ErrorAction SilentlyContinue
        $n++
    } while ($belegt)
    return $kandidat
}

# --- Vorbereitung -------------------------------------------------------

if (-not (Test-Path -LiteralPath $CsvPath)) {
    throw "CSV-Datei nicht gefunden: $CsvPath"
}
if (-not $InitialPassword) {
    $InitialPassword = Read-Host -Prompt 'Startkennwort fuer alle neuen Konten' -AsSecureString
}

$zeilen = Import-Csv -LiteralPath $CsvPath -Delimiter ';' -Encoding UTF8
$protokoll = New-Object System.Collections.Generic.List[object]
$nr = 0

# --- Verarbeitung -------------------------------------------------------

foreach ($z in $zeilen) {
    $nr++
    $eintrag = [ordered]@{
        Zeile          = $nr
        Personalnummer = $z.Personalnummer
        Name           = ('{0} {1}' -f $z.Vorname, $z.Nachname).Trim()
        SamAccountName = ''
        Ziel           = ''
        Status         = ''
        Meldung        = ''
    }

    try {
        foreach ($feld in 'Personalnummer', 'Vorname', 'Nachname', 'Abteilung') {
            if ([string]::IsNullOrWhiteSpace($z.$feld)) {
                throw "Pflichtfeld '$feld' fehlt."
            }
        }
        $id        = $z.Personalnummer.Trim()
        $vorname   = $z.Vorname.Trim()
        $nachname  = $z.Nachname.Trim()
        $abteilung = $z.Abteilung.Trim()

        if ($id -notmatch '^\d+$') { throw "Personalnummer '$id' ist nicht numerisch." }
        if ($abteilung -notmatch '^[\p{L} \-]+$') { throw "Abteilung '$abteilung' enthaelt ungueltige Zeichen." }

        # Ist diese Person schon angelegt? (Personalnummer ist der eindeutige Schluessel)
        $vorhanden = Get-ADUser -Filter "EmployeeID -eq '$id'" -Properties EmployeeID -ErrorAction SilentlyContinue
        if ($vorhanden) {
            $eintrag.SamAccountName = $vorhanden.SamAccountName
            $eintrag.Status  = 'Uebersprungen'
            $eintrag.Meldung = "Personalnummer $id existiert bereits."
        }
        else {
            $ziel = "OU=$abteilung,$BaseOU"
            try {
                [void](Get-ADOrganizationalUnit -Identity $ziel -ErrorAction Stop)
            }
            catch {
                throw "Ziel-OU nicht gefunden: $ziel"
            }
            $eintrag.Ziel = $ziel

            $sam = Get-FreeSamName -Vorname $vorname -Nachname $nachname
            $upn = "$sam@$UpnSuffix"
            $eintrag.SamAccountName = $sam
            if (Get-ADUser -Filter "UserPrincipalName -eq '$upn'" -ErrorAction SilentlyContinue) {
                throw "UserPrincipalName $upn ist bereits vergeben."
            }

            # Der Name (CN) muss innerhalb einer OU eindeutig sein.
            $cn = "$vorname $nachname"
            $cnFilter = Protect-FilterValue $cn
            if (Get-ADUser -Filter "Name -eq '$cnFilter'" -SearchBase $ziel -SearchScope OneLevel -ErrorAction SilentlyContinue) {
                $cn = "$cn ($id)"
            }
            # Gleichnamige Personen im Adressbuch unterscheidbar machen.
            $anzeige = "$vorname $nachname"
            if ($sam -match '\d$') { $anzeige = "$anzeige ($abteilung)" }

            $param = @{
                Name                  = $cn
                GivenName             = $vorname
                Surname               = $nachname
                DisplayName           = $anzeige
                SamAccountName        = $sam
                UserPrincipalName     = $upn
                EmployeeID            = $id
                Department            = $abteilung
                Path                  = $ziel
                AccountPassword       = $InitialPassword
                Enabled               = $true
                ChangePasswordAtLogon = $true
            }
            if (-not [string]::IsNullOrWhiteSpace($z.Position)) { $param.Title = $z.Position.Trim() }

            if ($PSCmdlet.ShouldProcess("$sam in $ziel", 'Benutzer anlegen')) {
                New-ADUser @param -ErrorAction Stop
                $eintrag.Status = 'Angelegt'
            }
            else {
                $eintrag.Status = 'Simuliert'
            }
        }
    }
    catch {
        $eintrag.Status  = 'Fehler'
        $eintrag.Meldung = $_.Exception.Message
    }

    $protokoll.Add([pscustomobject]$eintrag)
}

# --- Ergebnis -----------------------------------------------------------

$protokoll | Format-Table Zeile, Personalnummer, SamAccountName, Status, Meldung -AutoSize
$protokoll | Group-Object Status | Select-Object Name, Count | Format-Table -AutoSize
$protokoll | Export-Csv -Path $LogPath -NoTypeInformation -Delimiter ';' -Encoding UTF8
Write-Host "Protokoll: $LogPath"
