<#
.SYNOPSIS
    Legt die OU-Struktur der Uebung "Alpenwerk" an (idempotent).

.DESCRIPTION
    Erstellt unter der Domaenenwurzel:
      Alpenwerk
        Benutzer  (Vertrieb, Produktion, IT, Ehemalige)
        Gruppen
        Computer
    Vorhandene OUs werden uebersprungen. Mit -WhatIf wird nur angezeigt, was passieren wuerde.

.EXAMPLE
    .\01.1-ou-struktur-anlegen.ps1 -WhatIf
    .\01.1-ou-struktur-anlegen.ps1

.NOTES
    Zu Uebung 01.1 (Benutzerverwaltung im Active Directory).
    Ausfuehren auf DC01 in einer PowerShell als Domaenen-Administrator.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Root = 'Alpenwerk'
)

Import-Module ActiveDirectory -ErrorAction Stop

function New-OuIfMissing {
    param([string]$Name, [string]$Path)
    $dn = "OU=$Name,$Path"
    $vorhanden = Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $Path -SearchScope OneLevel -ErrorAction SilentlyContinue
    if ($vorhanden) {
        Write-Host "vorhanden: $dn"
    }
    elseif ($PSCmdlet.ShouldProcess($dn, 'OU anlegen')) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ErrorAction Stop
        Write-Host "angelegt:  $dn" -ForegroundColor Green
    }
    return $dn
}

$domainDn = (Get-ADDomain).DistinguishedName

$rootDn     = New-OuIfMissing -Name $Root -Path $domainDn
$benutzerDn = New-OuIfMissing -Name 'Benutzer' -Path $rootDn
foreach ($abteilung in 'Vertrieb', 'Produktion', 'IT', 'Ehemalige') {
    [void](New-OuIfMissing -Name $abteilung -Path $benutzerDn)
}
[void](New-OuIfMissing -Name 'Gruppen' -Path $rootDn)
[void](New-OuIfMissing -Name 'Computer' -Path $rootDn)
