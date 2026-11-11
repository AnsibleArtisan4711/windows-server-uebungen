# Modul 04 - Benutzer, Gruppen, Computer und Objektverwaltung

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Tabellen als Markdown-Tabellen, Übungsaufgaben und Lösungen als Absätze). Die Überschriften sind wie in der Quelle nach Modul und Lerneinheit nummeriert (4.1 bis 4.9; 4.10 Übungsaufgaben, 4.11 Lösungen). **Die PowerShell-Beispiele wurden für dieses Repository nicht ausgeführt**; sie setzen eine Windows-Server-Laborumgebung mit der fiktiven Domain `corp.contoso.com` voraus und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain. Übersicht zum Modul: [README](README.md).

|                                       |              |
|:--------------------------------------|:-------------|
| Dauer laut Modulübersicht             | 12 Stunden   |
| Summe der Lerneinheiten (Detailblatt) | 10,5 Stunden |
| Priorität                             | 1            |

| Nr. | Lerneinheit              | Dauer (h) | Prio |
|----:|:-------------------------|----------:|-----:|
| 4.1 | User Accounts            |         1 |    1 |
| 4.2 | Computer Accounts        |         1 |    1 |
| 4.3 | Gruppenarten             |       1,5 |    1 |
| 4.4 | Gruppenbereiche          |         1 |    1 |
| 4.5 | Servicekonten            |         1 |    1 |
| 4.6 | Managed Service Accounts |       1,5 |    1 |
| 4.7 | Attribute Management     |         1 |    2 |
| 4.8 | Join und Offboarding     |         1 |    2 |
| 4.9 | Objekt Review            |       1,5 |    2 |
|     | **Summe**                |  **10,5** |      |

> **Merke**
>
> Die Stundensumme der Lerneinheiten im Detailblatt (10,5 h) weicht von der Dauer in der Modulübersicht (12 h) ab. Dieses Skript behandelt alle Lerneinheiten des Detailblatts vollständig; die Abweichung ist im Lehrplan selbst zu klären.

Dieses Modul behandelt die Objekte, mit denen Administratoren täglich arbeiten: Benutzer, Computer, Gruppen und Dienstkonten. Während die vorherigen Module den Rahmen gesetzt haben, geht es hier um den *Lebenszyklus* der Objekte. Jedes Objekt wird angelegt, ändert sich, wird irgendwann nicht mehr gebraucht und muss dann sauber entfernt werden. Wer diesen Zyklus beherrscht und automatisiert, hat ein ordentliches Verzeichnis. Wer ihn dem Zufall überlässt, hat nach wenigen Jahren tausende verwaiste Konten, überflüssige Gruppen und Berechtigungen, die niemand mehr erklären kann.

Die Beispiele verwenden die in Modul 3 aufgebaute Struktur (`OU=Contoso` mit den Unter-OUs `Benutzer`, `Computer`, `Gruppen`, `Dienstkonten` und `Deaktiviert`). Wer sie noch nicht angelegt hat, erzeugt sie mit dem Skript aus Lerneinheit 3.4.

## 4.1 User Accounts

Ein *Benutzerkonto* repräsentiert eine Person (oder, bei Dienstkonten, einen Dienst) im Verzeichnis. Es besteht aus Anmeldedaten (Anmeldename, Kennwort), Eigenschaften (Name, Abteilung, Telefon), Einstellungen (Kennwortablauf, Ablaufdatum des Kontos, Anmeldezeiten) und Beziehungen (Gruppen, Vorgesetzter). Der Anmeldename existiert in zwei Formen: dem alten `sAMAccountName` (`CORP\amuster`) und dem *User Principal Name* (`amuster@corp.contoso.com`). Technisch steuert das Attribut `userAccountControl` viele Einstellungen als Bits: Ist Bit 2 gesetzt, ist das Konto deaktiviert; weitere Bits steuern, ob das Kennwort nie abläuft, ob kein Kennwort nötig ist oder ob eine Smartcard erforderlich ist. PowerShell zeigt diese Bits als lesbare Eigenschaften wie `Enabled` oder `PasswordNeverExpires`.

Der *Lebenszyklus* eines Benutzerkontos hat vier Phasen. Beim *Onboarding* (Eintritt) wird das Konto nach der Namenskonvention angelegt, in der richtigen OU abgelegt, mit Basisgruppen ausgestattet und mit einem Startkennwort versehen, das bei der ersten Anmeldung geändert werden muss. Beim *Rollenwechsel* (Versetzung, Abteilungswechsel) werden Gruppenmitgliedschaften, Attribute und gegebenenfalls die OU angepasst; das ist die fehleranfälligste Phase, weil alte Rechte gern „mitgenommen“ werden. Bei der *Sperrung* (längere Abwesenheit, Verdacht auf Missbrauch) wird das Konto deaktiviert, ohne Daten zu verlieren. Beim *Offboarding* (Austritt) wird es deaktiviert, entrechtet, verschoben und nach einer Aufbewahrungsfrist gelöscht (Lerneinheit 4.8).

Wichtig ist, jede Phase *standardisiert* und *nachvollziehbar* zu machen. Das gelingt am besten durch Skripte, die aus einer Datenquelle (zum Beispiel der Liste der Personalabteilung) arbeiten und jede Aktion protokollieren. Das folgende Skript legt Benutzer aus einer CSV-Datei an. Es erzeugt den Anmeldenamen nach der Konvention aus Lerneinheit 3.8, legt nur Konten an, die es noch nicht gibt, setzt ein Startkennwort mit erzwungener Änderung und protokolliert jede Aktion. Mit dem Schalter `-WhatIf` lässt sich ein Probelauf durchführen.

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$CsvPfad,       # Spalten: Vorname,Nachname,Abteilung,Standort,Titel
    [string]$Domain = "corp.contoso.com",
    [string]$ZielOuBasis = "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com"
)
Import-Module ActiveDirectory

function ConvertTo-AsciiName([string]$Text) {
    $t = $Text.ToLower() -replace "ä","ae" -replace "ö","oe" -replace "ü","ue" -replace "ß","ss"
    $t = $t.Normalize([Text.NormalizationForm]::FormD) -replace "\p{Mn}",""
    $t -replace "[^a-z0-9]",""
}

$startKennwort = Read-Host -AsSecureString "Startkennwort fuer alle neuen Konten (wird bei der ersten Anmeldung geaendert)"
$log = New-Object System.Collections.Generic.List[object]

foreach ($z in Import-Csv -Path $CsvPfad -Delimiter ";" -Encoding UTF8) {
    $sam = (ConvertTo-AsciiName $z.Vorname).Substring(0,1) + "." + (ConvertTo-AsciiName $z.Nachname)
    if ($sam.Length -gt 20) { $sam = $sam.Substring(0,20) }
    $upn = "{0}.{1}@{2}" -f (ConvertTo-AsciiName $z.Vorname), (ConvertTo-AsciiName $z.Nachname), $Domain
    $ou  = "OU=$($z.Standort),$ZielOuBasis"

    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ou'")) {
        $log.Add([pscustomobject]@{ Konto=$sam; Aktion="uebersprungen"; Grund="OU $ou fehlt" }); continue
    }
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'") {
        $log.Add([pscustomobject]@{ Konto=$sam; Aktion="uebersprungen"; Grund="Konto existiert bereits" }); continue
    }
    if ($PSCmdlet.ShouldProcess($sam, "Benutzer anlegen in $ou")) {
        New-ADUser -Name "$($z.Vorname) $($z.Nachname)" -GivenName $z.Vorname -Surname $z.Nachname `
            -SamAccountName $sam -UserPrincipalName $upn -DisplayName "$($z.Nachname), $($z.Vorname)" `
            -Department $z.Abteilung -Title $z.Titel -Path $ou `
            -AccountPassword $startKennwort -ChangePasswordAtLogon $true -Enabled $true
        $log.Add([pscustomobject]@{ Konto=$sam; Aktion="angelegt"; Grund=$ou })
    }
}
$log | Format-Table -AutoSize
$log | Export-Csv ".\Onboarding-$(Get-Date -Format yyyyMMdd-HHmm).csv" -NoTypeInformation -Encoding UTF8
```

Die Datei wird mit `Import-Csv` gelesen (Trennzeichen Semikolon, wie es deutsche Excel-Versionen erzeugen). Für jede Zeile entsteht aus Vor- und Nachname der Anmeldename; die Funktion `ConvertTo-AsciiName` entfernt Umlaute und Akzente. Das Skript prüft, ob die Ziel-OU existiert und ob das Konto schon vorhanden ist, und überspringt solche Fälle mit Begründung, statt abzubrechen. `ShouldProcess` macht den Probelauf mit `-WhatIf` möglich. Das Konto wird mit `-ChangePasswordAtLogon $true` angelegt, damit das gemeinsame Startkennwort nach der ersten Anmeldung wertlos ist. Das Protokoll listet für jede Zeile, was passiert ist, und wird zusätzlich als CSV gespeichert.

### Typische Fehler und Stolperfallen

Der häufigste Fehler beim Onboarding ist ein *gemeinsames, dauerhaft gültiges Startkennwort*, zum Beispiel „Willkommen2025“, das im Team bekannt ist und nie geändert wird. Das ist ein Sicherheitsrisiko; die Änderung bei der ersten Anmeldung und ein zufälliges, individuelles Startkennwort sind der bessere Weg. Ein zweiter Fehler ist das Kopieren eines bestehenden Benutzers als Vorlage, wobei alle Gruppenmitgliedschaften der Vorlage mitkommen. Ein dritter Fehler ist das Anlegen von Konten ohne Zuordnung zu einem Verantwortlichen: Bei Dienst- und Funktionskonten weiß später niemand mehr, wer sie braucht.

```powershell
# FALSCH: Alle Konten mit demselben dauerhaften Kennwort, ohne Aenderungspflicht
New-ADUser -Name "Anna Muster" -SamAccountName amuster `
    -AccountPassword (ConvertTo-SecureString "Willkommen2025" -AsPlainText -Force) `
    -Enabled $true -PasswordNeverExpires $true

# RICHTIG: Aenderungspflicht bei der ersten Anmeldung, Kennwortablauf normal
New-ADUser -Name "Anna Muster" -SamAccountName amuster `
    -AccountPassword (Read-Host -AsSecureString "Startkennwort") `
    -Enabled $true -ChangePasswordAtLogon $true
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen stellt jeden Monat zwischen zehn und zwanzig Mitarbeiter ein. Die Personalabteilung liefert eine CSV-Datei, das IT-Team führt zunächst einen Probelauf mit `-WhatIf` durch, prüft das Protokoll und startet das Skript dann produktiv. Das Skript legt die Konten an, trägt sie in die Basisgruppen ein und schreibt das Protokoll in ein Archiv. Nach einem Jahr fragt die interne Revision, wann welches Konto angelegt wurde. Die Antwort steht in den archivierten Protokollen.

## 4.2 Computer Accounts

Auch ein *Computer* ist ein Sicherheitsprinzipal mit einem eigenen Konto. Beim Beitritt zur Domain legt Windows ein Computerobjekt an, das einen Namen (mit angehängtem Dollarzeichen als `sAMAccountName`, also `PC01$`) und ein Kennwort besitzt. Dieses Kennwort kennt nur der Computer selbst, und er ändert es standardmäßig alle 30 Tage automatisch. Über das Kennwort baut der Computer einen *sicheren Kanal* (Secure Channel) zum Domain Controller auf; erst darüber kann er sich authentifizieren, Gruppenrichtlinien beziehen und Benutzer anmelden. Ist der Kanal gestört, etwa weil das Computerkonto gelöscht wurde oder die Kennwörter von Computer und Domain Controller nicht mehr übereinstimmen, erscheint die bekannte Meldung „Die Vertrauensstellung zwischen dieser Arbeitsstation und der primären Domäne ist fehlgeschlagen“.

Computerkonten können auf zwei Wegen entstehen. Beim *normalen Beitritt* legt der Beitrittsvorgang das Objekt an, standardmäßig im Container `Computers`, sofern der Standard nicht umgeleitet wurde (siehe Lerneinheit 1.7) oder der Beitrittsbefehl eine Ziel-OU angibt. Bei der *Vorbereitung* (Pre-Staging) legt ein Administrator das Konto vorab in der richtigen OU an; der Computer übernimmt es dann beim Beitritt. Das ist nützlich, wenn die Computer von Anfang an die richtigen Gruppenrichtlinien erhalten sollen.

Ein Sicherheitsaspekt, der oft übersehen wird, ist das Attribut `ms-DS-MachineAccountQuota` am Domänenobjekt. Es legt fest, wie viele Computer ein normaler authentifizierter Benutzer in die Domain aufnehmen darf; der Standardwert ist 10. Dadurch kann jeder Benutzer Computerkonten anlegen, die dann in keiner kontrollierten OU liegen. Aus Sicherheitsgründen setzt man den Wert üblicherweise auf 0 und delegiert das Recht zum Beitritt gezielt an eine Rolle (zum Beispiel an das Team, das Rechner installiert). Das folgende Skript zeigt, wie man ein Konto vorbereitet, den Beitritt durchführt, den Sicherheitskanal prüft und repariert und die Quote ausliest.

```powershell
Import-Module ActiveDirectory
$ouComputer = "OU=Arbeitsplaetze,OU=Computer,OU=Contoso,DC=corp,DC=contoso,DC=com"

# 1) Konto vorbereiten (Pre-Staging) mit Beschreibung und Verantwortlichem
New-ADComputer -Name "PC-WIEN-017" -SamAccountName "PC-WIEN-017" -Path $ouComputer `
    -Description "Arbeitsplatz Vertrieb Wien, Anna Muster" -Enabled $true

# 2) Auf dem Client: Domainbeitritt mit Ziel-OU (Neustart erforderlich)
#    Add-Computer -DomainName "corp.contoso.com" -OUPath $ouComputer `
#        -Credential (Get-Credential "CORP\join-service") -Restart

# 3) Auf dem Client: Sicherheitskanal pruefen, bei Bedarf reparieren
Test-ComputerSecureChannel -Verbose
Test-ComputerSecureChannel -Repair -Credential (Get-Credential "CORP\join-service")
#    Alternative bei Kennwortabweichung:
#    Reset-ComputerMachinePassword -Server DC01 -Credential (Get-Credential "CORP\join-service")

# 4) Wer darf Computer beitreten lassen? Quote am Domaenenobjekt lesen
Get-ADObject -Identity (Get-ADDomain).DistinguishedName -Properties "ms-DS-MachineAccountQuota" |
    Select-Object "ms-DS-MachineAccountQuota"

# 5) Quote auf 0 setzen (Beitritt nur noch ueber delegierte Konten)
Set-ADDomain -Identity (Get-ADDomain) -Replace @{ "ms-DS-MachineAccountQuota" = 0 }
```

Schritt 1 legt das Konto vorab an, mit einem sprechenden Namen und einer Beschreibung. Schritt 2 (auskommentiert, weil er auf dem Client läuft) zeigt den Beitritt mit der Ziel-OU, damit das Konto nicht im Container `Computers` landet. Schritt 3 prüft mit `Test-ComputerSecureChannel` den Kanal und repariert ihn bei Bedarf; das Reparieren setzt das Computerkennwort zurück und verlangt Zugangsdaten mit entsprechenden Rechten. Schritt 4 liest die Quote aus, Schritt 5 setzt sie auf 0. Vor dieser Änderung muss ein Beitrittskonto mit delegiertem Recht bereitstehen, sonst scheitern Beitritte durch normale Benutzer.

### Typische Fehler und Stolperfallen

Ein klassischer Fehler: Ein Computerkonto wird *gelöscht* und neu erstellt, weil der Rechner nicht mehr funktioniert. Das neue Konto hat eine neue SID, alle Berechtigungen, die auf der alten SID beruhten (Gruppenmitgliedschaften, ACLs), gehen verloren. Besser ist es, den Sicherheitskanal zu reparieren. Ein zweiter Fehler ist das Wiederverwenden eines Computernamens für ein anderes Gerät, ohne das alte Konto zurückzusetzen. Ein dritter ist das Vergessen verwaister Computerkonten: Geräte, die längst verschrottet sind, bleiben aktiv und können missbraucht werden.

```powershell
# FALSCH: Konto loeschen und neu anlegen, nur weil der Secure Channel gestoert ist
Remove-ADComputer -Identity "PC-WIEN-017" -Confirm:$false

# RICHTIG: Kanal reparieren (auf dem betroffenen Client)
Test-ComputerSecureChannel -Repair -Credential (Get-Credential "CORP\join-service")
```

### Praxisbezug

> **Praxisbeispiel**
>
> In einer Schule wurden die Rechner der Computerräume aus Sicherungsabbildern zurückgesetzt. Nach der Wiederherstellung meldet sich kein Benutzer mehr an: Die Computerkennwörter in den Abbildern stimmen nicht mehr mit denen im Active Directory überein. Statt alle Konten neu zu erzeugen, verwendet die IT ein Skript, das über die Liste der Rechnernamen läuft und per Fernzugriff `Reset-ComputerMachinePassword` ausführt. Innerhalb einer Stunde sind alle 90 Rechner wieder funktionsfähig.

## 4.3 Gruppenarten

*Gruppen* fassen Konten zusammen, damit man Rechte und Einstellungen nicht einzeln, sondern an einer Stelle vergibt. Es gibt zwei *Gruppentypen* (Arten). *Sicherheitsgruppen* (Security Groups) sind sicherheitsrelevant: Sie können in Zugriffssteuerungslisten (ACLs) von Dateien, Ordnern, Freigaben, Druckern und Verzeichnisobjekten verwendet werden, erscheinen im Sicherheitstoken (Access Token) des angemeldeten Benutzers und können auch als E-Mail-Verteiler dienen. *Verteilergruppen* (Distribution Groups) sind nicht sicherheitsrelevant: Sie dienen ausschließlich dem Versand von E-Mails (zum Beispiel über Exchange Server) und können nicht in ACLs aufgenommen werden. Die Microsoft-Dokumentation hält ausdrücklich fest, dass Verteilergruppen nicht sicherheitsaktiviert sind und deshalb nicht in DACLs aufgenommen werden können.

Technisch gibt es nur eine Objektklasse `group`; Typ und Bereich stecken im Attribut `groupType`, einer Zahl, die als Bitfeld gelesen wird. Die Werte für die Bereiche sind 2 (Global), 4 (Domain Local), 8 (Universal) und 1 (System), und das höchste Bit (Wert `0x80000000`, als negative Zahl `-2147483648`) kennzeichnet eine Sicherheitsgruppe. Eine globale Sicherheitsgruppe hat deshalb den Wert `-2147483646`, eine globale Verteilergruppe den Wert `2`. Mit dem Bit-Filter von LDAP lassen sich Gruppen nach Typ und Bereich abfragen; die Microsoft-Dokumentation zeigt dazu Beispielfilter mit der Regel `1.2.840.113556.1.4.803`.

Ein Typwechsel zwischen Sicherheits- und Verteilergruppe ist in einer Domain mit hinreichender Funktionsebene jederzeit möglich. Er hat aber Folgen: Wird eine Sicherheitsgruppe in eine Verteilergruppe umgewandelt, ignoriert das Sicherheitssystem alle Zugriffssteuerungseinträge, die diese Gruppe enthalten, die Berechtigungen verschwinden also stillschweigend. Außerdem gibt es *Standardgruppen* (Built-in und Users-Container) mit vordefinierten Rechten, etwa *Backup Operators* oder *Account Operators*; ihre Mitglieder erhalten damit weitreichende Rechte. Und es gibt *spezielle Identitäten* wie *Authenticated Users* oder *Creator Owner*, deren Mitgliedschaft nicht verwaltet wird, sondern sich aus den Umständen ergibt.

Das folgende Skript zeigt, wie man Gruppen nach Typ und Bereich auswertet, wie man den Typ umstellt und wie man die vordefinierten Gruppen mit Mitgliedern findet. Es hilft bei der ersten Bestandsaufnahme eines unbekannten Verzeichnisses.

```powershell
Import-Module ActiveDirectory

# 1) Uebersicht: Anzahl der Gruppen je Typ und Bereich
Get-ADGroup -Filter * |
    Group-Object GroupCategory, GroupScope |
    Select-Object @{n="Typ/Bereich";e={$_.Name}}, Count |
    Sort-Object "Typ/Bereich" | Format-Table -AutoSize

# 2) Dasselbe mit dem LDAP-Bitfilter: alle Sicherheitsgruppen
#    (-2147483648 = Bit "security enabled")
(Get-ADGroup -LDAPFilter "(groupType:1.2.840.113556.1.4.803:=-2147483648)").Count

# 3) Neue Gruppen anlegen: Sicherheitsgruppe und Verteilergruppe
$pfad = "OU=Berechtigung,OU=Gruppen,OU=Contoso,DC=corp,DC=contoso,DC=com"
New-ADGroup -Name "G-Vertrieb" -GroupScope Global -GroupCategory Security -Path $pfad `
    -Description "Alle Mitarbeiter Vertrieb"
New-ADGroup -Name "VT-Vertrieb-Info" -GroupScope Universal -GroupCategory Distribution `
    -Path "OU=Verteiler,OU=Gruppen,OU=Contoso,DC=corp,DC=contoso,DC=com"

# 4) Typ umstellen (Achtung: ACLs mit dieser Gruppe wirken danach nicht mehr)
Set-ADGroup -Identity "VT-Vertrieb-Info" -GroupCategory Security

# 5) Vordefinierte Gruppen mit Mitgliedern auflisten
Get-ADGroup -Filter * -SearchBase "CN=Builtin,$((Get-ADDomain).DistinguishedName)" |
    ForEach-Object {
        $m = @(Get-ADGroupMember $_)
        if ($m.Count -gt 0) { "{0,-35} {1} Mitglied(er)" -f $_.Name, $m.Count }
    }
```

Die erste Auswertung nutzt `Group-Object`, um nach Typ und Bereich zu zählen. Die zweite Zeile verwendet den Bit-Filter aus der Dokumentation und liefert die Anzahl aller Sicherheitsgruppen. In Schritt 3 werden eine Sicherheitsgruppe (global) und eine Verteilergruppe (universal) angelegt, Schritt 4 stellt den Typ der Verteilergruppe um; der Kommentar warnt vor den Folgen für bestehende ACLs. Schritt 5 listet die vordefinierten Gruppen des Containers `Builtin`, die tatsächlich Mitglieder haben, was sofort zeigt, wo privilegierte Rechte vergeben sind.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, Verteilergruppen für die Rechtevergabe zu verwenden: Wer eine Verteilergruppe in eine Dateiberechtigung einträgt, erhält keine Fehlermeldung, aber auch keinen Zugriff. Der umgekehrte Fehler ist die Verwendung von Sicherheitsgruppen als reine E-Mail-Verteiler: Jede Mitgliedschaft vergrößert das Sicherheitstoken des Benutzers, und große Tokens führen bei sehr vielen Gruppen zu Anmeldeproblemen. Der dritte Fehler ist die Verwendung der Standardgruppe *Domain Users* für Berechtigungen: Sie enthält alle Konten der Domain, eine Berechtigung für diese Gruppe ist praktisch eine Berechtigung für alle.

```powershell
# FALSCH: Verteilergruppe fuer eine Dateiberechtigung (wirkt nicht, ohne Fehlermeldung)
icacls "D:\Shares\Vertrieb" /grant "CORP\VT-Vertrieb-Info:(OI)(CI)M"

# RICHTIG: Sicherheitsgruppe, die genau fuer Berechtigungen gedacht ist
icacls "D:\Shares\Vertrieb" /grant "CORP\DL-Share-Vertrieb-RW:(OI)(CI)M"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Nach einer Umstellung beschweren sich Mitarbeiter, dass sie nicht mehr auf eine Freigabe zugreifen können. Die Ursache: Ein Administrator hatte zur „Aufräumaktion“ mehrere Sicherheitsgruppen in Verteilergruppen umgewandelt, weil sie scheinbar nur für E-Mails benutzt wurden. Die Berechtigungen in den ACLs wurden dadurch wirkungslos. Seitdem prüft das Team vor jeder Typänderung per Skript, in welchen ACLs und Richtlinien die Gruppe vorkommt.

## 4.4 Gruppenbereiche

Der *Bereich* (Scope) einer Gruppe legt fest, wer Mitglied sein darf, wo die Gruppe verwendet werden kann und wie weit ihre Mitgliedschaft repliziert wird. Active Directory kennt drei Bereiche: *Domain Local* (domänenlokal), *Global* und *Universal*. Die folgende Tabelle fasst die Regeln aus der Microsoft-Dokumentation zusammen.

| Bereich      | Mögliche Mitglieder                                                                                                                   | Kann Berechtigungen vergeben                                 | Kann Mitglied sein in                                                                                   |
|:-------------|:--------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------|
| Domain Local | Konten und globale Gruppen aus jeder Domain (auch vertrauten); universale Gruppen des Forests; domänenlokale Gruppen derselben Domain | nur in der eigenen Domain                                    | domänenlokalen Gruppen derselben Domain                                                                 |
| Global       | Konten und globale Gruppen *derselben* Domain                                                                                         | in jeder Domain des Forests und vertrauenden Domains/Forests | universalen Gruppen des Forests, globalen Gruppen derselben Domain, domänenlokalen Gruppen jeder Domain |
| Universal    | Konten, globale und universale Gruppen aus dem ganzen Forest                                                                          | in jeder Domain des Forests und vertrauenden Forests         | anderen universalen Gruppen, domänenlokalen Gruppen                                                     |

Aus den Regeln ergibt sich das bewährte Muster *AGDLP*: **A**ccounts (Konten) kommen in **G**lobale Gruppen (nach Funktion, zum Beispiel Abteilung), diese in **D**omain-**L**ocal-Gruppen (nach Ressource und Zugriffsart, zum Beispiel „Freigabe Vertrieb, Ändern“), und die Domain-Local-Gruppen erhalten die **P**ermissions (Berechtigungen). Der Vorteil: Ein neuer Mitarbeiter wird nur an einer Stelle (der globalen Gruppe) aufgenommen und erhält automatisch alle Zugriffe der Abteilung. Soll eine Ressource einer weiteren Abteilung zugänglich werden, ergänzt man deren globale Gruppe in der Domain-Local-Gruppe, ohne die ACL anzufassen. In Umgebungen mit mehreren Domains erweitert man das Muster zu *AGUDLP*, indem man die globalen Gruppen der einzelnen Domains in eine *universale* Gruppe aufnimmt. Universale Gruppen werden im Global Catalog gespeichert, weshalb man sie sparsam einsetzt und mit relativ stabilen Mitgliedern befüllt.

Bereichswechsel sind eingeschränkt. Die Microsoft-Dokumentation nennt die Regeln: Eine domänenlokale Gruppe lässt sich in eine universale umwandeln, wenn sie keine anderen domänenlokalen Gruppen enthält; eine globale in eine universale, wenn sie nicht Mitglied einer anderen globalen Gruppe ist; eine universale in eine globale, wenn sie keine anderen universalen Gruppen enthält, und in eine domänenlokale, wenn sie nicht Mitglied einer anderen universalen Gruppe ist. Der Wechsel zwischen global und domänenlokal geht deshalb nur über den Zwischenschritt „universal“.

Das folgende Beispiel setzt AGDLP vollständig um: Es legt den Ordner und die Gruppen an, verschachtelt sie und vergibt die Berechtigung über die Domain-Local-Gruppe. Anschließend zeigt es mit `Get-ADPrincipalGroupMembership`, welche Gruppen ein Benutzer erbt.

```powershell
Import-Module ActiveDirectory
$gruppenOu = "OU=Berechtigung,OU=Gruppen,OU=Contoso,DC=corp,DC=contoso,DC=com"
$ordner    = "D:\Shares\Vertrieb"

# A -> G: Funktionsgruppe (Wer?)  und  DL: Ressourcengruppe (Was darf wer wo?)
New-ADGroup -Name "G-Vertrieb"             -GroupScope Global      -Path $gruppenOu -Description "Mitarbeiter Vertrieb"
New-ADGroup -Name "DL-Share-Vertrieb-RW"   -GroupScope DomainLocal -Path $gruppenOu -Description "Aendern auf \\FS01\Vertrieb"
New-ADGroup -Name "DL-Share-Vertrieb-R"    -GroupScope DomainLocal -Path $gruppenOu -Description "Lesen auf \\FS01\Vertrieb"

# Konten in die globale Gruppe, globale Gruppe in die Ressourcengruppe
Add-ADGroupMember -Identity "G-Vertrieb" -Members "a.muster"
Add-ADGroupMember -Identity "DL-Share-Vertrieb-RW" -Members "G-Vertrieb"

# P: Berechtigung nur fuer die Domain-Local-Gruppen vergeben
New-Item -ItemType Directory -Path $ordner -Force | Out-Null
icacls $ordner /inheritance:r | Out-Null
icacls $ordner /grant "CORP\DL-Share-Vertrieb-RW:(OI)(CI)M" "CORP\DL-Share-Vertrieb-R:(OI)(CI)RX" "BUILTIN\Administrators:(OI)(CI)F" | Out-Null
icacls $ordner

# Kontrolle: Welche Gruppen hat der Benutzer (auch indirekt)?
Get-ADPrincipalGroupMembership -Identity "a.muster" | Select-Object Name, GroupScope
Get-ADUser "a.muster" -Properties TokenGroups | Select-Object -ExpandProperty TokenGroups | Measure-Object | Select-Object Count

# Bereichswechsel von global nach domaenenlokal nur ueber universal
Set-ADGroup -Identity "G-Test" -GroupScope Universal
Set-ADGroup -Identity "G-Test" -GroupScope DomainLocal
```

Die Funktionsgruppe `G-Vertrieb` beantwortet die Frage „Wer?“, die Ressourcengruppen beantworten „Was?“ (Lesen oder Ändern auf der Freigabe). Die ACL des Ordners enthält ausschließlich Domain-Local-Gruppen und die Administratoren; die Vererbung wird zunächst entfernt (`/inheritance:r`), damit keine ungewollten Rechte übernommen werden. `(OI)(CI)` bedeutet Vererbung auf Dateien und Unterordner, `M` steht für „Ändern“, `RX` für „Lesen und Ausführen“ und `F` für „Vollzugriff“. Die beiden Abfragen am Ende zeigen die Gruppenmitgliedschaft des Benutzers und die Anzahl aller Gruppen im Sicherheitstoken. Der Bereichswechsel ganz unten setzt voraus, dass die Gruppe `G-Test` existiert und die oben genannten Bedingungen erfüllt.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die Abkürzung „Benutzer direkt in die ACL“: Jede Berechtigung auf Ordnerebene für einzelne Personen verursacht später Aufräumarbeit. Ein zweiter Fehler ist die Verwendung von *universalen* Gruppen für alles, weil sie „überall gehen“. Jede Änderung der Mitgliedschaft einer universalen Gruppe wird im gesamten Global Catalog repliziert, was in großen Umgebungen Last verursacht. Ein dritter Fehler ist die Verschachtelung ohne Plan, die zu zirkulären Mitgliedschaften und unübersichtlichen Rechtewegen führt.

```powershell
# FALSCH: einzelne Benutzer direkt in der ACL
icacls "D:\Shares\Vertrieb" /grant "CORP\a.muster:(OI)(CI)M"

# RICHTIG: Rechte nur ueber Rollengruppen (AGDLP), Personen nur in der Funktionsgruppe
Add-ADGroupMember -Identity "G-Vertrieb" -Members "a.muster"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Das Unternehmen stellt eine zweite Abteilung („Marketing“) für die Freigabe „Vertrieb“ frei, aber nur lesend. Der Administrator nimmt die globale Gruppe `G-Marketing` in die Ressourcengruppe `DL-Share-Vertrieb-R` auf. An der ACL des Ordners ändert sich nichts. Wenn später eine Mitarbeiterin aus dem Marketing in den Vertrieb wechselt, tauscht der Administrator ihre Mitgliedschaft von `G-Marketing` nach `G-Vertrieb`; alle Zugriffe passen sich an.

## 4.5 Servicekonten

Ein *Servicekonto* ist ein Konto, unter dem ein Dienst, eine Aufgabe oder eine Anwendung läuft, etwa der SQL-Server-Dienst, ein Backup-Agent oder ein geplanter Task. Es gehört keiner Person, sondern einer Aufgabe, und genau das macht es zum Risiko: Servicekonten haben oft zu viele Rechte, Kennwörter, die nie ablaufen, und niemand fühlt sich verantwortlich. Weil Dienste mit dem Kennwort des Kontos Kerberos-Tickets anfordern können, sind Servicekonten mit einem *Service Principal Name* (SPN) ein bevorzugtes Ziel für *Kerberoasting*: Ein Angreifer fordert ein Ticket für den Dienst an und knackt das darin verschlüsselte Kennwort offline. Je schwächer das Kennwort, desto leichter gelingt das. Die Microsoft-Dokumentation zu den neuen Kontotypen nennt die Verhinderung dieses Kennwort-Diebstahls ausdrücklich als Ziel.

Aus dem Risiko ergeben sich Grundregeln für klassische Servicekonten (Benutzerkonten, die als Dienstkonto verwendet werden). Sie erhalten *minimale Rechte* (nur das, was der Dienst braucht, und nie Mitgliedschaft in privilegierten Gruppen wie Domain Admins). Sie erhalten *lange, zufällige Kennwörter* (mindestens 25 Zeichen), die nicht von Menschen verwendet werden. Sie dürfen sich *nicht interaktiv anmelden*, was man über Gruppenrichtlinien (Benutzerrechte „Lokal anmelden verweigern“ und „Anmelden über Remotedesktopdienste verweigern“) durchsetzt. Sie haben einen *dokumentierten Verantwortlichen* (Ownership), einen Zweck und eine Kennwortrotation. Und sie sind *benannt* nach einer Konvention (`svc-` und Zweck), liegen in einer eigenen OU und sind aus Sicht der Verwaltung leicht zu finden. Wo immer möglich, ersetzt man klassische Servicekonten durch verwaltete Konten (Lerneinheit 4.6).

Das folgende Skript prüft den Bestand an Servicekonten. Es findet alle Benutzerkonten mit SPN (potentielle Kerberoasting-Ziele), zeigt Alter des Kennworts, Ablaufeinstellung, letzte Anmeldung und Mitgliedschaft in privilegierten Gruppen und bewertet jedes Konto. Es verändert nichts, liefert aber die Grundlage für das Aufräumen.

```powershell
Import-Module ActiveDirectory
$privilegiert = "Domain Admins","Enterprise Admins","Schema Admins","Administrators",
                "Account Operators","Backup Operators","Server Operators"
$privSids = $privilegiert | ForEach-Object {
    Get-ADGroup $_ -ErrorAction SilentlyContinue | Get-ADGroupMember -Recursive |
        Where-Object objectClass -eq "user" | Select-Object -ExpandProperty distinguishedName
} | Sort-Object -Unique

$konten = Get-ADUser -Filter 'ServicePrincipalName -like "*"' `
    -Properties ServicePrincipalName, PasswordLastSet, PasswordNeverExpires, LastLogonDate, Enabled, Description

$bericht = foreach ($k in $konten) {
    $alter    = if ($k.PasswordLastSet) { [int]((Get-Date) - $k.PasswordLastSet).TotalDays } else { $null }
    $risiken  = @()
    if ($k.DistinguishedName -in $privSids) { $risiken += "PRIVILEGIERT" }
    if ($k.PasswordNeverExpires)            { $risiken += "Kennwort laeuft nie ab" }
    if ($alter -gt 365)                      { $risiken += "Kennwort aelter als 1 Jahr" }
    if (-not $k.Description)                 { $risiken += "kein Verantwortlicher/Zweck" }
    [pscustomobject]@{
        Konto = $k.SamAccountName; Aktiv = $k.Enabled; KennwortAlterTage = $alter
        SPNs = ($k.ServicePrincipalName -join "; "); Risiken = ($risiken -join ", ")
    }
}
$bericht | Sort-Object { $_.Risiken.Length } -Descending | Format-Table -AutoSize -Wrap
$bericht | Export-Csv ".\Servicekonten-Audit.csv" -NoTypeInformation -Encoding UTF8
```

Zuerst werden die Mitglieder der privilegierten Gruppen (rekursiv) gesammelt. Anschließend sucht der Filter alle Benutzerkonten, bei denen das Attribut `ServicePrincipalName` gesetzt ist, und lädt die relevanten Eigenschaften. Für jedes Konto werden das Kennwortalter berechnet und vier Risiken geprüft: Mitgliedschaft in einer privilegierten Gruppe, Kennwort läuft nie ab, Kennwort älter als ein Jahr und fehlende Beschreibung (als Hinweis auf fehlende Verantwortung). Die Ausgabe ist nach der Länge der Risikoliste sortiert, sodass die auffälligsten Konten oben stehen. Die CSV-Datei dient als Arbeitsliste.

### Typische Fehler und Stolperfallen

Der gefährlichste Fehler ist, einen Dienst unter einem Konto mit Domain-Admin-Rechten laufen zu lassen, „weil es sonst nicht funktioniert“. Ein kompromittierter Dienst ist dann ein kompromittiertes Verzeichnis. Fast immer genügen spezifische Rechte auf dem Server oder an einzelnen Ressourcen. Ein zweiter Fehler ist das *dauerhaft gleiche Kennwort*: Wer ein Servicekonto nach fünf Jahren löscht, entdeckt, dass niemand weiß, wo es überall eingetragen ist, und scheut deshalb jede Änderung. Ein dritter Fehler sind *geteilte* Servicekonten: Ein Konto für fünf Anwendungen macht es unmöglich, Rechte sauber zu begrenzen.

```powershell
# FALSCH: Dienstkonto als Domain Admin, Kennwort laeuft nie ab
Add-ADGroupMember -Identity "Domain Admins" -Members "svc-backup"
Set-ADUser "svc-backup" -PasswordNeverExpires $true

# RICHTIG: konkrete Rechte, nicht-interaktiv, mit Verantwortlichem
Set-ADUser "svc-backup" -Description "Backup-Agent FS01, Verantwortlich: M. Huber (IT-Betrieb)"
Add-ADGroupMember -Identity "Backup Operators" -Members "svc-backup"     # nur wenn wirklich noetig
# Interaktive Anmeldung per GPO verweigern (siehe Modul 7)
```

### Praxisbezug

> **Praxisbeispiel**
>
> Bei einem Penetrationstest gelingt es den Prüfern, aus dem Netz das Kennwort des Kontos `svc-sql` zu ermitteln, weil es seit acht Jahren `Sommer2017!` lautet und das Konto Mitglied der Domain Admins ist. Der Bericht führt zu einem Projekt: Alle Servicekonten werden inventarisiert, Verantwortliche benannt, Rechte reduziert, Kennwörter erneuert und, wo technisch möglich, durch gMSA ersetzt. Das Skript dieser Lerneinheit ist das Werkzeug dafür.

## 4.6 Managed Service Accounts

Die Probleme klassischer Servicekonten (schwache Kennwörter, fehlende Rotation, unklare Verantwortung) lassen sich weitgehend beseitigen, indem man das Kennwortmanagement der Domain überlässt. Genau das leisten die *verwalteten Dienstkonten*. Es gibt zwei Varianten. Das *Managed Service Account* (MSA, auch *standalone MSA* oder sMSA) gehört zu genau einem Server; das *Group Managed Service Account* (gMSA) kann von mehreren Servern gleichzeitig verwendet werden und eignet sich deshalb für Serverfarmen, Cluster und Lastverteilung. In beiden Fällen erzeugt und ändert die Domain das Kennwort automatisch; es ist sehr lang und zufällig, kein Mensch kennt es, und der Dienst holt es sich bei Bedarf vom Domain Controller. Dadurch ist das beschriebene Kerberoasting-Risiko stark vermindert, weil sich ein solches Kennwort nicht durch Raten ermitteln lässt.

Beim gMSA steht die Berechtigung zum Abruf des Kennworts in einem Attribut des Kontos (`PrincipalsAllowedToRetrieveManagedPassword`). Dort trägt man die Computerkonten oder, besser, eine Sicherheitsgruppe mit den Computerkonten der berechtigten Server ein. Das Kennwort wird mit Hilfe eines *Root-Schlüssels des Key Distribution Service* (KDS Root Key) berechnet, der einmalig pro Forest erzeugt werden muss. Voraussetzung auf den Servern ist ein unterstütztes Windows Server und das PowerShell-Modul für Active Directory. Dienste, die gMSA unterstützen, sind unter anderem Windows-Dienste, geplante Aufgaben, IIS-Anwendungspools und SQL Server; nicht jede Software kann es, weil das Konto keine interaktive Anmeldung und kein Kennwort-Eingabefeld kennt.

Das folgende Skript führt den gesamten Ablauf aus: den KDS-Root-Key anlegen, eine Gruppe für die berechtigten Server erzeugen, das gMSA anlegen, es auf dem Server installieren und testen. Die Schritte auf dem Server (ab Schritt 4) werden auf dem Mitgliedsserver `SRV01` ausgeführt. Der Domänenname und die Servernamen entsprechen der Laborumgebung.

```powershell
Import-Module ActiveDirectory

# 1) Einmalig pro Forest: KDS-Root-Key. Im Labor sofort wirksam machen (10 Stunden zurueckdatieren).
#    In Produktion: Add-KdsRootKey -EffectiveImmediately und die Replikationszeit abwarten.
if (-not (Get-KdsRootKey)) {
    Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))
}

# 2) Gruppe der Server, die das Kennwort abrufen duerfen
$ouDienst = "OU=Dienstkonten,OU=Contoso,DC=corp,DC=contoso,DC=com"
New-ADGroup -Name "SRV-gMSA-Web" -GroupScope Global -Path $ouDienst `
    -Description "Server, die gMSA svc-web nutzen duerfen"
Add-ADGroupMember -Identity "SRV-gMSA-Web" -Members (Get-ADComputer "SRV01")
#    Danach SRV01 neu starten, damit das Computer-Token die neue Gruppe enthaelt.

# 3) gMSA anlegen (Kennwortwechsel alle 30 Tage ist der Standard)
New-ADServiceAccount -Name "svc-web" -DNSHostName "svc-web.corp.contoso.com" `
    -PrincipalsAllowedToRetrieveManagedPassword "SRV-gMSA-Web" `
    -Description "gMSA fuer IIS-Anwendungspool Intranet, Verantwortlich: IT-Betrieb" `
    -Path $ouDienst

# 4) Auf SRV01: Konto installieren und testen
Install-ADServiceAccount -Identity "svc-web"
Test-ADServiceAccount -Identity "svc-web"          # muss True liefern

# 5) Verwendung, z. B. als Dienstkonto (Kennwort leer lassen, Konto mit $ am Ende)
#    sc.exe config MeinDienst obj= "CORP\svc-web$" password= ""
Get-ADServiceAccount -Identity "svc-web" -Properties PrincipalsAllowedToRetrieveManagedPassword |
    Select-Object Name, Enabled, PrincipalsAllowedToRetrieveManagedPassword
```

Schritt 1 legt den Root-Key an, falls es noch keinen gibt; ohne ihn schlägt die Anlage eines gMSA fehl. Das Zurückdatieren ist eine Labor-Abkürzung, weil die Domain Controller dem Schlüssel sonst eine Wartezeit zugestehen, damit er überall repliziert ist. Schritt 2 sammelt die berechtigten Server in einer Gruppe; so muss später beim Hinzufügen eines Servers nur die Gruppe geändert werden. Schritt 3 legt das Konto an. Das Kennwort wird nie angegeben, denn die Domain berechnet es. Schritt 4 installiert das Konto lokal und prüft, ob der Server das Kennwort abrufen kann. In Schritt 5 sieht man, dass das Konto als Dienstkonto mit angehängtem Dollarzeichen und leerem Kennwort eingetragen wird.

> **Ergänzung aus der Nachrecherche**
>
> Die Angaben zu den Parametern von `New-ADServiceAccount`, dem KDS-Root-Key und der Wartezeit entsprechen dem Fachwissen zu gMSA; sie wurden im Rahmen dieses Moduls *nicht einzeln gegen die aktuelle Dokumentation abgerufen*. Prüfen Sie vor dem produktiven Einsatz die aktuelle Microsoft-Dokumentation zu „Group Managed Service Accounts“, insbesondere die unterstützten Windows-Server-Versionen und das Verhalten bei mehreren Domain Controllern.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, den Server nach dem Eintragen in die Gruppe nicht neu zu starten. Das Kerberos-Ticket des Computers enthält die Gruppenmitgliedschaften zum Zeitpunkt der Anmeldung; ohne Neustart (oder `klist -li 0x3e7 purge`) schlägt `Test-ADServiceAccount` mit `False` fehl. Ein zweiter Fehler ist, ein gMSA für eine Software zu planen, die interaktive Anmeldung oder ein eingetragenes Kennwort benötigt; hier hilft nur der Test im Labor. Ein dritter Fehler ist die Verwendung von Einzelcomputern statt einer Gruppe: Jeder neue Server erfordert dann eine Änderung am Konto selbst.

```powershell
# FALSCH: Einzelner Server direkt eingetragen, spaeter nicht erweiterbar ohne Kontoaenderung
New-ADServiceAccount -Name svc-web -DNSHostName svc-web.corp.contoso.com `
    -PrincipalsAllowedToRetrieveManagedPassword "SRV01$"

# RICHTIG: Gruppe verwenden; neue Server kommen nur in die Gruppe
New-ADServiceAccount -Name svc-web -DNSHostName svc-web.corp.contoso.com `
    -PrincipalsAllowedToRetrieveManagedPassword "SRV-gMSA-Web"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Webanwendung läuft auf drei Servern hinter einem Lastverteiler. Früher teilten sich die Server ein Dienstkonto, dessen Kennwort seit vier Jahren unverändert war, weil ein Wechsel einen Wartungstag erfordert hätte. Mit einem gMSA entfällt das Problem: Das Kennwort wechselt alle 30 Tage von selbst, ein vierter Server wird einfach in die Gruppe aufgenommen, und kein Administrator kennt das Kennwort.

## 4.7 Attribute Management

Jedes Objekt im Verzeichnis besteht aus *Attributen*, also benannten Eigenschaften mit einem Datentyp. Welche Attribute eine Objektklasse haben darf, legt das Schema fest (Modul 3). Für die Verwaltung unterscheidet man vier Arten. *Einfache Attribute* wie `givenName` oder `department` enthalten einen Wert. *Mehrwertige Attribute* wie `memberOf`, `proxyAddresses` oder `servicePrincipalName` enthalten eine Liste. *Berechnete Attribute* wie `memberOf` (das aus den Mitgliederlisten der Gruppen abgeleitet wird) kann man nicht direkt ändern. Und *Systemattribute* wie `objectSid` oder `whenCreated` werden vom System gesetzt und sind in der Regel nicht änderbar.

Attribute sind das Rückgrat jeder Automatisierung. Gruppen lassen sich dynamisch aus Attributen bilden, Berechtigungen und Richtlinien hängen von Abteilung oder Standort ab, Adressbücher, Verzeichnisabgleich mit Cloud-Diensten und Berichte nutzen sie. Daher sollten sie vollständig, einheitlich und aktuell sein. Dazu gehören feste Regeln: Schreibweise der Abteilungsnamen, Format von Telefonnummern (international mit Landesvorwahl), Pflege des Vorgesetzten (`manager`) als Verweis auf ein Benutzerobjekt, nicht als Freitext.

Das folgende Beispiel zeigt die drei Grundoperationen: Eigenschaften lesen (nur benötigte, mit `-Properties`), gezielt ändern (mit `-Replace`, `-Add`, `-Remove` für mehrwertige Attribute) und eine Qualitätsprüfung, die Konten mit unvollständigen Pflichtattributen findet. Zusätzlich wird ein Massenupdate aus einer CSV-Datei gezeigt, das mit `-WhatIf` geprüft werden kann.

```powershell
Import-Module ActiveDirectory

# 1) Nur die benoetigten Eigenschaften lesen (Standard liefert nur eine kleine Auswahl)
Get-ADUser -Identity "a.muster" -Properties Department, Title, Manager, telephoneNumber, proxyAddresses |
    Select-Object Name, Department, Title, Manager, telephoneNumber, proxyAddresses

# 2) Einfache Attribute aendern
Set-ADUser -Identity "a.muster" -Department "Vertrieb" -Title "Teamleiterin" `
    -OfficePhone "+43 1 5551234" -Manager "m.huber"

# 3) Mehrwertiges Attribut gezielt ergaenzen/entfernen (nicht ueberschreiben!)
Set-ADUser -Identity "a.muster" -Add @{ proxyAddresses = "smtp:anna.muster@contoso.com" }
Set-ADUser -Identity "a.muster" -Remove @{ proxyAddresses = "smtp:alt@contoso.com" }

# 4) Attribut leeren
Set-ADUser -Identity "a.muster" -Clear telephoneNumber

# 5) Qualitaetspruefung: aktive Benutzer ohne Abteilung oder Vorgesetzten
Get-ADUser -Filter 'Enabled -eq $true' -Properties Department, Manager -SearchBase "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" |
    Where-Object { -not $_.Department -or -not $_.Manager } |
    Select-Object SamAccountName, Department, Manager

# 6) Massenupdate aus CSV (Spalten: Sam;Abteilung;Telefon), erst mit -WhatIf pruefen
Import-Csv .\Aktualisierung.csv -Delimiter ";" -Encoding UTF8 | ForEach-Object {
    Set-ADUser -Identity $_.Sam -Department $_.Abteilung -OfficePhone $_.Telefon -WhatIf
}
```

Schritt 1 zeigt, dass `Get-ADUser` standardmäßig nur wenige Eigenschaften liefert und weitere mit `-Properties` angefordert werden müssen; `-Properties *` sollte man nur zur Erkundung verwenden, weil es viel Last erzeugt. Schritt 2 ändert einfache Attribute über benannte Parameter. Schritt 3 ist wichtig: Für mehrwertige Attribute verwendet man `-Add` und `-Remove`, denn `-Replace` würde die gesamte Liste überschreiben. Schritt 4 löscht ein Attribut. Schritt 5 findet Datenqualitätsprobleme, und Schritt 6 aktualisiert viele Konten auf einmal; durch `-WhatIf` wird nur angezeigt, was passieren würde.

### Typische Fehler und Stolperfallen

Der klassische Fehler ist `-Replace` bei mehrwertigen Attributen, wodurch zum Beispiel alle bisherigen E-Mail-Adressen verloren gehen. Ein zweiter Fehler ist, Attributwerte frei zu schreiben, sodass „Vertrieb“, „vertrieb“ und „Sales“ nebeneinander existieren; dynamische Gruppen und Berichte erfassen dann nur einen Teil. Ein dritter Fehler ist ein Massenupdate ohne Probelauf und ohne Sicherung der Ausgangswerte.

```powershell
# FALSCH: Replace ueberschreibt alle bisherigen Adressen
Set-ADUser a.muster -Replace @{ proxyAddresses = "smtp:neu@contoso.com" }

# RICHTIG: Add ergaenzt, bestehende Adressen bleiben erhalten
Set-ADUser a.muster -Add @{ proxyAddresses = "smtp:neu@contoso.com" }

# Vor jedem Massenupdate: Ausgangswerte sichern
Get-ADUser -Filter * -Properties Department, Title | Export-Csv .\Sicherung-Attribute.csv -NoTypeInformation -Encoding UTF8
```

### Praxisbezug

> **Praxisbeispiel**
>
> Das Unternehmen führt eine neue Abteilungsstruktur ein. Die Personalabteilung liefert eine Liste, das IT-Team sichert zunächst alle betroffenen Attribute, prüft das Massenupdate mit `-WhatIf` und führt es dann aus. Anschließend ändern sich die Mitgliedschaften der dynamisch gepflegten Gruppen, die ein Skript aus dem Attribut `department` ableitet, ohne dass jemand einzelne Konten anfassen muss.

## 4.8 Join und Offboarding

Der Lebenszyklus eines Kontos wird in der Praxis oft mit dem Begriff *Joiner–Mover–Leaver* beschrieben: Eintritt (Join), Wechsel (Move) und Austritt (Leave). Lerneinheit 4.1 hat den Eintritt behandelt. Hier geht es um den Wechsel und vor allem um den *Austritt*, denn ein vergessenes Konto eines ausgeschiedenen Mitarbeiters ist eines der häufigsten Einfallstore. Ein sauberer Austritt besteht aus mehreren Schritten: Das Konto wird sofort *deaktiviert*, aktive Sitzungen und Tokens verlieren ihre Gültigkeit durch Kennwortänderung, die Gruppenmitgliedschaften werden entfernt (nach Dokumentation, damit sie bei einer Wiedereinstellung rekonstruiert werden können), das Konto wird in eine OU für deaktivierte Konten *verschoben*, mit einem Vermerk (Datum, Ticketnummer) versehen und nach der Aufbewahrungsfrist *gelöscht*.

Das Löschen verdient Aufmerksamkeit. Ist der *Active Directory-Papierkorb* aktiviert, wird ein gelöschtes Objekt zunächst nur als „logisch gelöscht“ markiert und kann mit allen Attributen wiederhergestellt werden; ohne Papierkorb bleibt nur ein *Tombstone*, der kaum noch Attribute enthält. Die Aktivierung des Papierkorbs ist ein Forest-weiter, nicht umkehrbarer Schritt, den man vorher plant; er setzt die passende Forest-Funktionsebene voraus. Der Rollenwechsel (Mover) wird häufig vergessen: Wer die Abteilung wechselt, behält sonst die Rechte der alten Abteilung.

Das folgende Skript führt den Austritt standardisiert aus. Es dokumentiert den Zustand vor der Änderung in einer Datei, deaktiviert das Konto, setzt ein zufälliges Kennwort, entfernt die Gruppen (außer der primären), verschiebt das Konto und trägt den Grund in die Beschreibung ein. Mit `-WhatIf` ist ein Probelauf möglich.

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$Sam,
    [Parameter(Mandatory)][string]$Ticket,
    [string]$ZielOu = "OU=Deaktiviert,OU=Contoso,DC=corp,DC=contoso,DC=com"
)
Import-Module ActiveDirectory
$u = Get-ADUser -Identity $Sam -Properties MemberOf, Description, Manager
$gruppen = $u.MemberOf | Get-ADGroup | Select-Object -ExpandProperty Name

# 1) Zustand sichern (fuer Wiedereinstellung und Revision)
[pscustomobject]@{
    Konto = $u.SamAccountName; DN = $u.DistinguishedName; Gruppen = ($gruppen -join "; ")
    Vorgesetzter = $u.Manager; Datum = Get-Date -Format s; Ticket = $Ticket
} | Export-Csv ".\Offboarding-$Sam-$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation -Encoding UTF8

if ($PSCmdlet.ShouldProcess($Sam, "Offboarding")) {
    # 2) Konto deaktivieren und Kennwort durch Zufallswert ersetzen
    Disable-ADAccount -Identity $u
    $zufall = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 40 | ForEach-Object { [char]$_ })
    Set-ADAccountPassword -Identity $u -Reset -NewPassword (ConvertTo-SecureString $zufall -AsPlainText -Force)

    # 3) Gruppen entfernen (Domain Users bleibt als primaere Gruppe bestehen)
    foreach ($dn in $u.MemberOf) { Remove-ADGroupMember -Identity $dn -Members $u -Confirm:$false }

    # 4) Vermerk setzen und verschieben
    Set-ADUser -Identity $u -Description "Deaktiviert $(Get-Date -Format yyyy-MM-dd), Ticket $Ticket" -Clear manager
    Move-ADObject -Identity $u.DistinguishedName -TargetPath $ZielOu
}

# 5) Spaeter: Konten, die seit 180 Tagen deaktiviert in der Ziel-OU liegen, anzeigen
Get-ADUser -Filter 'Enabled -eq $false' -SearchBase $ZielOu -Properties whenChanged |
    Where-Object whenChanged -lt (Get-Date).AddDays(-180) | Select-Object SamAccountName, whenChanged
```

Die Sicherung in Schritt 1 ist entscheidend: Wenn eine Mitarbeiterin nach drei Monaten zurückkehrt, kann man aus der Datei die früheren Gruppen ablesen. Das zufällige Kennwort in Schritt 2 stellt sicher, dass auch ein bekanntes altes Kennwort nicht mehr nutzbar ist. In Schritt 3 werden alle Gruppen entfernt, die im Attribut `memberOf` stehen; die primäre Gruppe (in der Regel *Domain Users*) steht dort nicht und bleibt erhalten. Schritt 4 verschiebt das Konto; Schritt 5 zeigt, wie man später Kandidaten für das endgültige Löschen findet.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, nur zu deaktivieren und nichts weiter zu tun: Das Konto behält alle Rechte, und wird es versehentlich reaktiviert, ist der alte Zugriff wieder da. Der zweite Fehler ist das sofortige Löschen ohne Papierkorb, wodurch Datenzugriffe (Postfach, Dateibesitz, SID-basierte Berechtigungen) verloren gehen. Der dritte Fehler ist das Vergessen des Rollenwechsels.

```powershell
# FALSCH: Nur deaktiviert, Gruppen und Kennwort bleiben unveraendert
Disable-ADAccount -Identity "a.muster"

# RICHTIG: Zustand sichern, deaktivieren, Gruppen entfernen, verschieben, dokumentieren
.\Invoke-Offboarding.ps1 -Sam "a.muster" -Ticket "INC-4711" -WhatIf   # Probelauf
.\Invoke-Offboarding.ps1 -Sam "a.muster" -Ticket "INC-4711"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Bei der jährlichen Revision fällt auf, dass 37 aktive Konten ehemaligen Mitarbeitern gehören. Eine Auswertung der letzten Anmeldung (`LastLogonDate`) zeigt, dass sich mit zwei Konten noch in den letzten Wochen jemand angemeldet hat. Das Unternehmen führt daraufhin den beschriebenen standardisierten Austrittsprozess ein, gekoppelt an das Ticketsystem der Personalabteilung.

## 4.9 Objekt Review

Ein Verzeichnis veraltet von selbst. Daher gehört zu einer professionellen Verwaltung der regelmäßige *Review*: Man prüft in festem Rhythmus (zum Beispiel vierteljährlich), welche Objekte nicht mehr gebraucht werden, welche Konten zu viele Rechte haben und welche Daten falsch sind. Typische Prüffragen sind: Welche Benutzer haben sich seit 90 Tagen nicht mehr angemeldet? Welche Computer haben ihr Kennwort seit 60 Tagen nicht geändert und sind vermutlich nicht mehr im Netz? Welche Gruppen sind leer oder enthalten nur ein Mitglied? Wer ist Mitglied der privilegierten Gruppen? Welche Konten haben „Kennwort läuft nie ab“? Welche Konten sind gesperrt oder abgelaufen?

Eine Besonderheit beim Auswerten der Anmeldezeiten: Das Attribut `lastLogon` wird nicht repliziert und ist nur auf dem jeweiligen Domain Controller gültig. Das Attribut `lastLogonTimestamp`, das PowerShell als `LastLogonDate` ausgibt, wird dagegen repliziert, aber nur zeitverzögert (standardmäßig bis zu 14 Tage) aktualisiert. Für Aufräumaktionen im Abstand von Monaten genügt das; für eine genaue Aussage zu einer einzelnen Anmeldung nicht. Wichtig ist auch, vor dem Löschen immer erst zu *deaktivieren und zu verschieben*, nicht gleich zu löschen. Der Review-Bericht ist das Ergebnis; über Maßnahmen entscheidet der Verantwortliche.

Das folgende Skript erstellt einen Review-Bericht als HTML-Datei und CSV. Es verändert nichts und kann daher regelmäßig, auch automatisiert, laufen.

```powershell
Import-Module ActiveDirectory
$basis  = (Get-ADDomain).DistinguishedName
$grenze = (Get-Date).AddDays(-90)
$grenzeComputer = (Get-Date).AddDays(-60)

$inaktiveBenutzer = Get-ADUser -Filter 'Enabled -eq $true' -Properties LastLogonDate, PasswordNeverExpires, whenCreated |
    Where-Object { $_.LastLogonDate -lt $grenze -and $_.whenCreated -lt $grenze } |
    Select-Object SamAccountName, LastLogonDate, PasswordNeverExpires

$veralteteComputer = Get-ADComputer -Filter 'Enabled -eq $true' -Properties PasswordLastSet, LastLogonDate, OperatingSystem |
    Where-Object { $_.PasswordLastSet -lt $grenzeComputer } |
    Select-Object Name, OperatingSystem, PasswordLastSet, LastLogonDate

$leereGruppen = Get-ADGroup -Filter * -Properties Members, ManagedBy |
    Where-Object { $_.Members.Count -eq 0 } | Select-Object Name, GroupScope, ManagedBy

$privilegiert = "Domain Admins","Enterprise Admins","Schema Admins" | ForEach-Object {
    $g = $_; Get-ADGroupMember $g -Recursive | Select-Object @{n="Gruppe";e={$g}}, SamAccountName
}

$kennwortNieAblauf = Get-ADUser -Filter 'PasswordNeverExpires -eq $true -and Enabled -eq $true' |
    Select-Object SamAccountName

$bericht = @(
    [pscustomobject]@{ Pruefung="Aktive Benutzer ohne Anmeldung seit 90 Tagen"; Anzahl=@($inaktiveBenutzer).Count }
    [pscustomobject]@{ Pruefung="Computer ohne Kennwortwechsel seit 60 Tagen";  Anzahl=@($veralteteComputer).Count }
    [pscustomobject]@{ Pruefung="Leere Gruppen";                                Anzahl=@($leereGruppen).Count }
    [pscustomobject]@{ Pruefung="Mitglieder privilegierter Gruppen";            Anzahl=@($privilegiert).Count }
    [pscustomobject]@{ Pruefung="Aktive Konten mit Kennwort laeuft nie ab";     Anzahl=@($kennwortNieAblauf).Count }
)
$bericht | Format-Table -AutoSize
$stamp = Get-Date -Format yyyyMMdd
$inaktiveBenutzer  | Export-Csv ".\Review-$stamp-Benutzer.csv"  -NoTypeInformation -Encoding UTF8
$veralteteComputer | Export-Csv ".\Review-$stamp-Computer.csv"  -NoTypeInformation -Encoding UTF8
$bericht | ConvertTo-Html -Title "AD-Review $stamp" | Out-File ".\Review-$stamp.html" -Encoding UTF8
```

Das Skript sammelt fünf Prüfungen. Bei den Benutzern wird zusätzlich geprüft, dass das Konto älter als 90 Tage ist, damit neue Konten, die sich noch nie angemeldet haben, nicht fälschlich auftauchen. Bei den Computern dient der letzte Kennwortwechsel als Indikator, weil ein aktiver Rechner sein Kennwort standardmäßig alle 30 Tage ändert. Leere Gruppen und privilegierte Mitglieder ergeben Aufräum- und Sicherheitskandidaten. Die Ausgabe als Tabelle, CSV und HTML erlaubt den Versand an die Verantwortlichen.

### Typische Fehler und Stolperfallen

Ein häufiger Fehler ist, `lastLogon` auf einem einzelnen Domain Controller abzufragen und daraus zu schließen, ein Konto sei unbenutzt; es kann sich an einem anderen DC angemeldet haben. Ein zweiter Fehler ist das automatische Löschen aller Treffer: Notebooks, die drei Monate im Urlaub waren, oder Konten für saisonale Mitarbeiter sind keine Leichen. Ein dritter Fehler ist ein Review ohne Verantwortliche und Frist; dann bleibt der Bericht liegen.

```powershell
# FALSCH: Treffer sofort loeschen
Get-ADUser -Filter * -Properties LastLogonDate | Where-Object LastLogonDate -lt (Get-Date).AddDays(-90) |
    Remove-ADUser -Confirm:$false

# RICHTIG: erst deaktivieren und in die Pruef-OU verschieben, Loeschung nach Frist und Freigabe
Get-ADUser -Filter 'Enabled -eq $true' -Properties LastLogonDate |
    Where-Object LastLogonDate -lt (Get-Date).AddDays(-90) |
    ForEach-Object { Disable-ADAccount $_; Move-ADObject $_ -TargetPath "OU=Deaktiviert,OU=Contoso,DC=corp,DC=contoso,DC=com" -WhatIf }
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen führt vierteljährlich einen Review durch. Das Skript erzeugt den Bericht, der Teamleiter bestätigt oder widerspricht in einer Liste, das IT-Team setzt die Maßnahmen um. Beim ersten Durchlauf werden 212 inaktive Konten und 64 verwaiste Computer gefunden; beim vierten nur noch 11, weil der Austrittsprozess aus Lerneinheit 4.8 greift.

## 4.10 Übungsaufgaben zu Modul 04

Die Aufgaben 1 bis 3 prüfen das Verständnis, die Aufgaben 4 bis 8 sind praktische Skriptaufgaben für die Laborumgebung.

**Aufgabe 4.1** **Gruppentyp.** Erklären Sie den Unterschied zwischen einer Sicherheits- und einer Verteilergruppe. Was passiert mit den Berechtigungen, wenn eine Sicherheitsgruppe in eine Verteilergruppe umgewandelt wird?

**Aufgabe 4.2** **AGDLP.** Eine Abteilung „Einkauf“ soll auf die Freigabe `\\FS01\Einkauf` Lese- und Schreibzugriff erhalten, die Abteilung „Controlling“ nur Lesezugriff. Skizzieren Sie, welche Gruppen Sie anlegen, wie sie verschachtelt sind und wo Berechtigungen vergeben werden.

**Aufgabe 4.3** **Servicekonto bewerten.** Das Konto `svc-sql` ist Mitglied der Domain Admins, sein Kennwort ist sechs Jahre alt und läuft nie ab. Benennen Sie die Risiken und schlagen Sie drei Maßnahmen vor.

**Aufgabe 4.4** **Onboarding.** Legen Sie mit dem Skript aus Lerneinheit 4.1 fünf Benutzer aus einer selbst erstellten CSV-Datei an. Führen Sie zuerst einen Lauf mit `-WhatIf` durch und kontrollieren Sie das Protokoll.

**Aufgabe 4.5** **AGDLP umsetzen.** Setzen Sie Aufgabe 4.2 in der Laborumgebung um und prüfen Sie mit `Get-ADPrincipalGroupMembership`, welche Gruppen ein Testbenutzer erhält.

**Aufgabe 4.6** **Gruppenstatistik.** Schreiben Sie ein Skript, das alle Gruppen nach Typ und Bereich zählt und zusätzlich alle leeren Gruppen auflistet.

**Aufgabe 4.7** **gMSA.** Legen Sie ein gMSA `svc-test` für `SRV01` an, installieren Sie es und weisen Sie mit `Test-ADServiceAccount` nach, dass es funktioniert. Welcher Fehler tritt auf, wenn Sie SRV01 nach dem Eintragen in die Gruppe nicht neu starten?

**Aufgabe 4.8** **Offboarding und Review.** Führen Sie das Offboarding-Skript für ein Testkonto im Probelauf und produktiv aus. Erstellen Sie danach mit dem Review-Skript einen Bericht und wählen Sie zwei Auffälligkeiten aus, für die Sie Maßnahmen mit Verantwortlichem und Frist formulieren.

## 4.11 Lösungen zu den Übungsaufgaben

**Lösung 4.1.** Sicherheitsgruppen können in Zugriffssteuerungslisten verwendet werden und erscheinen im Sicherheitstoken, Verteilergruppen dienen nur dem E-Mail-Versand. Wird eine Sicherheitsgruppe in eine Verteilergruppe umgewandelt, ignoriert das Sicherheitssystem die Einträge dieser Gruppe in ACLs; die Berechtigungen wirken nicht mehr, ohne dass eine Fehlermeldung erscheint.

**Lösung 4.2.** Anzulegen sind die globalen Gruppen `G-Einkauf` und `G-Controlling` (Wer?) sowie die Domain-Local-Gruppen `DL-Share-Einkauf-RW` und `DL-Share-Einkauf-R` (Was?). `G-Einkauf` wird in `DL-Share-Einkauf-RW`, `G-Controlling` in `DL-Share-Einkauf-R` aufgenommen. Die Berechtigungen (Ändern beziehungsweise Lesen und Ausführen) werden ausschließlich für die beiden Domain-Local-Gruppen im Dateisystem vergeben. Die Benutzer sind nur Mitglied ihrer globalen Gruppe.

**Lösung 4.3.** Risiken: Ein Angriff auf den Dienst führt zur Übernahme der Domain, das Kennwort lässt sich per Kerberoasting offline angreifen, ein sechs Jahre altes Kennwort ist vermutlich weit verbreitet oder schwach, und es gibt keine Rotation. Maßnahmen: (1) das Konto aus den Domain Admins entfernen und nur die tatsächlich benötigten Rechte vergeben; (2) auf ein gMSA umstellen oder, wenn nicht möglich, ein langes zufälliges Kennwort setzen und die Rotation planen; (3) einen Verantwortlichen dokumentieren und interaktive Anmeldung per Richtlinie verbieten.

**Lösung 4.4.** Beispiel einer CSV-Datei (Trennzeichen Semikolon, UTF-8):

```text
Vorname;Nachname;Abteilung;Standort;Titel
Anna;Muster;Vertrieb;Wien;Sachbearbeiterin
Bernd;Beispiel;IT;Wien;Administrator
```

Beim Lauf mit `-WhatIf` werden die Konten nicht angelegt, das Protokoll bleibt aber leer, weil die Zeile mit dem Protokolleintrag nur innerhalb von `ShouldProcess` steht. Beim produktiven Lauf erscheint pro Konto die Aktion „angelegt“ oder „übersprungen“ mit Begründung. Ist die Ziel-OU (Standort) nicht vorhanden, wird die Zeile übersprungen.

**Lösung 4.5.**

```powershell
New-ADGroup -Name "G-Einkauf" -GroupScope Global -Path $ou
New-ADGroup -Name "DL-Share-Einkauf-RW" -GroupScope DomainLocal -Path $ou
Add-ADGroupMember -Identity "DL-Share-Einkauf-RW" -Members "G-Einkauf"
Add-ADGroupMember -Identity "G-Einkauf" -Members "testuser1"
Get-ADPrincipalGroupMembership -Identity "testuser1" | Select-Object Name, GroupScope
```

Die Abfrage zeigt auch die über Verschachtelung erworbenen Gruppen, wenn man statt der direkten Mitgliedschaft die Token-Gruppen (`TokenGroups`) verwendet; `Get-ADPrincipalGroupMembership` liefert nur die direkten Mitgliedschaften des Benutzers. Für die indirekte Mitgliedschaft in der Domain-Local-Gruppe ist daher die TokenGroups-Abfrage aus Lerneinheit 4.4 nötig.

**Lösung 4.6.**

```powershell
Get-ADGroup -Filter * -Properties Members |
    Group-Object GroupCategory, GroupScope |
    Select-Object Name, Count | Format-Table -AutoSize

Get-ADGroup -Filter * -Properties Members |
    Where-Object { $_.Members.Count -eq 0 } | Select-Object Name, GroupScope
```

Die erste Abfrage gruppiert nach beiden Eigenschaften und zählt. Das Attribut `Members` muss mit `-Properties` angefordert werden, sonst ist es leer und alle Gruppen würden als leer erscheinen. Vorsicht: Die Standardgruppen im Container `Builtin` sind teilweise von Haus aus leer und sollten nicht gelöscht werden.

**Lösung 4.7.** Nach den Schritten aus Lerneinheit 4.6 (KDS-Root-Key, Gruppe, `New-ADServiceAccount`, `Install-ADServiceAccount`) liefert `Test-ADServiceAccount` den Wert `True`. Ohne Neustart von SRV01 nach dem Eintragen in die Gruppe liefert der Test `False`, weil das Computer-Token die neue Gruppenmitgliedschaft noch nicht enthält und der Server das Kennwort nicht abrufen darf.

**Lösung 4.8.** Beim Probelauf zeigt `-WhatIf` nur an, welche Aktionen ausgeführt würden; die Datei mit der Sicherung wird allerdings auch dann geschrieben, weil Schritt 1 außerhalb von `ShouldProcess` steht. Das ist beabsichtigt, weil die Sicherung nichts verändert. Im produktiven Lauf ist das Konto danach deaktiviert, ohne Gruppenmitgliedschaften (außer der primären Gruppe), ohne Vorgesetzten und in der OU `Deaktiviert`. Eine mögliche Maßnahme für den Review: „12 aktive Konten ohne Anmeldung seit 90 Tagen“ (Maßnahme: Abstimmung mit den Teamleitern, Deaktivierung nicht bestätigter Konten, Verantwortlich: AD-Team, Frist: 14 Tage) und „4 aktive Konten mit Kennwort läuft nie ab“ (Maßnahme: Prüfen, ob es Servicekonten sind, gMSA planen, Verantwortlich: Applikationsverantwortliche, Frist: 60 Tage).
