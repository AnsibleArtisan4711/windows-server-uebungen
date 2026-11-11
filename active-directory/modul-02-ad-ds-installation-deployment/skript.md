# Modul 02 - AD DS Installation und Domain Controller Deployment

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Tabellen als Markdown-Tabellen, Übungsaufgaben und Lösungen als Absätze). Die Überschriften sind wie in der Quelle nach Modul und Lerneinheit nummeriert (2.1 bis 2.9; 2.10 Übungsaufgaben, 2.11 Lösungen). **Die PowerShell-Beispiele wurden für dieses Repository nicht ausgeführt**; sie setzen eine Windows-Server-Laborumgebung mit der fiktiven Domain `corp.contoso.com` voraus und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain. Übersicht zum Modul: [README](README.md).

|                                       |              |
|:--------------------------------------|:-------------|
| Dauer laut Modulübersicht             | 12 Stunden   |
| Summe der Lerneinheiten (Detailblatt) | 10,5 Stunden |
| Priorität                             | 1            |

| Nr. | Lerneinheit                    | Dauer (h) | Prio |
|----:|:-------------------------------|----------:|-----:|
| 2.1 | Installationsvoraussetzungen   |         1 |    1 |
| 2.2 | AD DS Rolle                    |         1 |    1 |
| 2.3 | DNS Rolle                      |       1,5 |    1 |
| 2.4 | Neuer Forest                   |         1 |    1 |
| 2.5 | Zusätzlicher Domain Controller |         1 |    1 |
| 2.6 | Read-Only Domain Controller    |       1,5 |    1 |
| 2.7 | Server Core Deployment         |         1 |    2 |
| 2.8 | PowerShell Deployment          |         1 |    2 |
| 2.9 | Installationsreview            |       1,5 |    2 |
|     | **Summe**                      |  **10,5** |      |

> **Merke**
>
> Die Stundensumme der Lerneinheiten im Detailblatt (10,5 h) weicht von der Dauer in der Modulübersicht (12 h) ab. Dieses Skript behandelt alle Lerneinheiten des Detailblatts vollständig; die Abweichung ist im Lehrplan selbst zu klären.

In diesem Modul wird aus der Theorie von Modul 1 eine laufende Umgebung. Sie lernen, wie ein Windows Server für die Rolle des Domain Controllers vorbereitet wird, wie AD DS und DNS installiert werden, wie ein neuer Forest entsteht, wie weitere und schreibgeschützte Domain Controller dazukommen und wie man das Ergebnis prüft. Die Installation selbst dauert nur wenige Minuten; die Qualität einer Active-Directory-Umgebung entscheidet sich aber fast immer davor (Planung) und danach (Prüfung). Deshalb ist die Reihenfolge der Lerneinheiten bewusst so gewählt: Voraussetzungen, Rolle, DNS, Forest, weitere Domain Controller, Sonderfälle und zum Schluss die Abnahme.

Die Laborumgebung bleibt dieselbe wie in Modul 1: Domain `corp.contoso.com`, erster Domain Controller `DC01` (IP-Adresse `10.10.0.11`), zweiter Domain Controller `DC02` (`10.10.0.12`), Standardgateway `10.10.0.1`. Alle Skripte sind in einer erhöhten (als Administrator gestarteten) PowerShell auszuführen.

## 2.1 Installationsvoraussetzungen

Ein Domain Controller ist eines der wichtigsten Systeme einer Organisation, und viele Entscheidungen, die man vor der Installation trifft, lassen sich später nur mit großem Aufwand ändern. Dazu gehört der Servername: Ein Domain Controller sollte nach der Promotion nicht mehr umbenannt werden (das ist technisch möglich, aber fehleranfällig), und der Name sollte den NetBIOS-Regeln genügen, also höchstens 15 Zeichen lang sein. Wer einen Namen wie `DC01` verwendet, nutzt ein bewährtes Muster aus Rolle und Nummer. Namen mit Standortbezug (`WIEN-DC01`) sind ebenfalls üblich, solange sie bei einer Verlagerung nicht irreführend werden. Die Microsoft-Namensempfehlungen raten außerdem, nur die in RFC 1123 genannten Zeichen (A–Z, a–z, 0–9 und den Bindestrich) zu verwenden.

Die zweite zwingende Voraussetzung ist eine *statische IP-Adresse*. Ein Domain Controller darf seine Adresse nicht per DHCP beziehen, weil Clients und andere Server ihn anhand der IP-Adresse und der DNS-Einträge finden. Dazu gehört die richtige *DNS-Konfiguration*: Der erste Domain Controller eines Forests trägt sich selbst als DNS-Server ein (Microsoft beschreibt, dass bei AD-integriertem DNS die Adresse des bevorzugten DNS-Servers auf dem ersten DC automatisch auf die Loopback-Adresse `127.0.0.1` gesetzt wird). Jeder weitere Domain Controller verwendet zunächst einen bereits vorhandenen Domain Controller als DNS-Server und kann sich später zusätzlich selbst eintragen.

Drittens müssen *Updates* installiert sein, bevor der Server zum Domain Controller wird, denn nach der Promotion sind Neustarts folgenreicher. Viertens braucht jede Umgebung eine verlässliche *Zeitquelle*, denn Kerberos toleriert standardmäßig nur wenige Minuten Zeitabweichung. Fünftens gehört die *Rollenplanung* dazu: Welche Rollen soll der Server haben (Global Catalog, DNS, später FSMO-Rollen)? Auf welchem Laufwerk liegen Datenbank, Protokolle und SYSVOL? Wie viel Speicher und welche CPU braucht er? Ein Domain Controller sollte keine fremden Rollen übernehmen, weil das die Angriffsfläche und die Komplexität erhöht.

Schließlich müssen die *Berechtigungen* stimmen. Für den allerersten Domain Controller einer neuen Gesamtstruktur reicht ein lokaler Administrator. Für einen zusätzlichen Domain Controller in einer bestehenden Domain braucht man ein Konto in der Gruppe *Domain Admins*. Für die Erstellung einer neuen Domain in einem bestehenden Forest braucht man die Gruppe *Enterprise Admins*. Wird eine neuere Windows-Server-Version in eine bestehende Umgebung eingeführt, bereitet der Promotionsvorgang das Schema vor (früher mit `adprep` manuell); dafür sind Mitgliedschaften in den Gruppen *Schema Admins* und *Enterprise Admins* nötig.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zum Windows-Zeitdienst beschreibt die Zeithierarchie einer Domain: Domänenmitglieder beziehen die Zeit von Domain Controllern, diese vom Domain Controller mit der Rolle PDC-Emulator, und der PDC-Emulator der Forest-Root-Domain steht an der Spitze und sollte mit einer externen, verlässlichen Zeitquelle synchronisiert werden. Die Synchronisierung läuft über das Protokoll NTP auf dem UDP-Port 123. Für virtualisierte Domain Controller empfiehlt Microsoft, die Zeitsynchronisierung mit dem Hostsystem teilweise zu deaktivieren, damit der Domain Controller seine Zeit aus der Domain-Hierarchie bezieht und nach einer Wiederherstellung aus einem gespeicherten Zustand keine Zeitabweichung entsteht. Details zum Zeitdienst folgen in Modul 6.

Das folgende Skript ist eine Vorprüfung, die alle genannten Punkte auf dem künftigen Domain Controller abfragt. Es verändert nichts, sondern gibt eine Übersicht aus, die man vor der Installation abhaken kann. So erkennt man Fehler wie eine per DHCP vergebene Adresse oder eine abweichende Zeit, bevor sie zum Problem werden.

```powershell
# Vorpruefung fuer einen kuenftigen Domain Controller (nur lesend)
$os   = Get-CimInstance Win32_OperatingSystem
$cs   = Get-CimInstance Win32_ComputerSystem
$nic  = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway }

"Servername            : " + $env:COMPUTERNAME + " (" + $env:COMPUTERNAME.Length + " Zeichen)"
"Betriebssystem        : " + $os.Caption + " " + $os.Version
"Domaenenmitglied      : " + $cs.PartOfDomain
"RAM (GB)              : " + [math]::Round($cs.TotalPhysicalMemory/1GB,1)

foreach ($n in $nic) {
    $dhcp = (Get-NetIPInterface -InterfaceIndex $n.InterfaceIndex -AddressFamily IPv4).Dhcp
    "Adapter               : " + $n.InterfaceAlias
    "  IPv4-Adresse        : " + $n.IPv4Address.IPAddress
    "  DHCP aktiv          : " + $dhcp
    "  Gateway             : " + $n.IPv4DefaultGateway.NextHop
    "  DNS-Server          : " + ($n.DNSServer.ServerAddresses -join ", ")
}

# Zeitquelle und Zeitabweichung
w32tm /query /status | Select-String "Quelle|Source|Letzte erfolgreiche|Last Successful"

# Freier Speicher auf den Laufwerken (fuer NTDS, Logs, SYSVOL)
Get-Volume | Where-Object DriveLetter |
    Select-Object DriveLetter, FileSystemLabel,
        @{n="FreiGB";e={[math]::Round($_.SizeRemaining/1GB,1)}}
```

Das Skript nutzt `Get-CimInstance` für Informationen zu Betriebssystem und Hardware, `Get-NetIPConfiguration` für die Netzwerkkonfiguration und `w32tm` für den Zeitdienst. Die Schleife prüft pro Adapter mit Standardgateway, ob DHCP aktiv ist; die Ausgabe `DHCP aktiv: Disabled` ist hier das gewünschte Ergebnis. Die Zeile `w32tm /query /status` zeigt die aktuelle Zeitquelle: Auf einem frischen Server steht dort meist „Local CMOS Clock“ oder der Host des Hypervisors, was vor der Promotion zu klären ist. Der letzte Block zeigt, ob genügend Platz auf den Datenträgern vorhanden ist.

### Typische Fehler und Stolperfallen

Einer der häufigsten Fehler ist ein Domain Controller, der als DNS-Server eine öffentliche Adresse wie `8.8.8.8` verwendet. Der Server kann dann zwar im Internet suchen, findet aber die `SRV`-Einträge seiner eigenen Domain nicht und kann sich weder anmelden noch replizieren. Domain Controller und Domänenmitglieder dürfen nur interne DNS-Server eintragen, die externe Namen über Weiterleitungen (Forwarder) auflösen. Ebenfalls häufig: Die Installation startet mit einem Standardnamen wie `WIN-4K9SDL2PQ7A`, und der Name wird danach geändert. Nach der Promotion ist das mühsam.

```powershell
# FALSCH: DC mit oeffentlichem DNS und Zufallsnamen
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8
# Computername bleibt WIN-4K9SDL2PQ7A

# RICHTIG: statische IP, interner DNS, sprechender Name VOR der Promotion
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.10.0.11 -PrefixLength 24 -DefaultGateway 10.10.0.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 127.0.0.1
Rename-Computer -NewName "DC01" -Restart
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Dienstleister soll für einen Kunden eine neue Domain aufbauen. Statt direkt zu installieren, lässt er den Kunden eine Checkliste ausfüllen: Domainname, NetBIOS-Name, IP-Plan, Zeitquelle, Backup-Konzept, Hostsystem. Während des Kundentermins fällt auf, dass der Domainname `firma.local` gewünscht ist, die Firma aber `firma.at` besitzt. Die Vorbereitung verhindert eine Fehlentscheidung, die später ein Migrationsprojekt kosten würde.

## 2.2 AD DS Rolle

Die Installation von Active Directory läuft in zwei Schritten. Im ersten Schritt wird die *Serverrolle* installiert, das heißt, die Programmdateien, Dienste und Verwaltungswerkzeuge werden auf den Server kopiert. Dabei entsteht noch kein Domain Controller und noch keine Domain; der Server ist weiterhin ein gewöhnlicher Server. Im zweiten Schritt, der *Promotion* (Heraufstufung), konfiguriert der Server sich als Domain Controller: Er legt die Datenbank an, erstellt oder repliziert die Domain, registriert sich im DNS und startet neu. Diese Trennung ist sinnvoll, weil man Rollen vorab verteilen und die Promotion später planen kann.

Für die Rolleninstallation gibt es zwei Wege: den *Server-Manager* mit dem Assistenten „Rollen und Features hinzufügen“ und die *PowerShell* mit `Install-WindowsFeature`. Der Assistent installiert die Verwaltungswerkzeuge automatisch mit, bei PowerShell muss man dafür den Schalter `-IncludeManagementTools` setzen. Zu den Werkzeugen gehören die Konsolen „Active Directory-Benutzer und -Computer“, „Active Directory-Standorte und -Dienste“ und das PowerShell-Modul `ActiveDirectory`, das auch Gegenstand der RSAT-Tools auf Verwaltungsrechnern ist.

Ein Hinweis aus der Microsoft-Dokumentation ist für den Betrieb wichtig: Die Rolle AD DS wird wie jede andere Rolle entfernt, wobei das Entfernen die vorherige *Herabstufung* (Demotion) des Domain Controllers voraussetzt. Das ist nötig, damit der Domain Controller nicht ohne saubere Bereinigung der Metadaten im Forest verschwindet. Microsoft warnt ausdrücklich davor, die Rolle nach der Promotion mit `Dism.exe` oder dem DISM-PowerShell-Modul zu entfernen; das wird nicht unterstützt und verhindert, dass der Server normal startet.

Das folgende Beispiel installiert die Rolle auf `DC01`, prüft das Ergebnis und zeigt, welche Cmdlets für die Promotion nun zur Verfügung stehen. Der Test-Cmdlet-Satz (`Test-ADDS*`) wird in der Lerneinheit 2.4 verwendet.

```powershell
# Rolle AD DS inklusive Verwaltungswerkzeuge installieren
$ergebnis = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
$ergebnis | Select-Object Success, RestartNeeded, ExitCode, FeatureResult

# Status der Rolle und der zugehoerigen Features pruefen
Get-WindowsFeature -Name AD-Domain-Services, RSAT-AD-Tools, RSAT-AD-PowerShell |
    Select-Object DisplayName, Name, InstallState

# Welche Promotions-Cmdlets stehen jetzt bereit?
Get-Command -Module ADDSDeployment | Select-Object Name | Sort-Object Name
```

Das erste Kommando installiert die Rolle und gibt ein Ergebnisobjekt zurück; wichtig sind `Success` (Erfolg) und `RestartNeeded`, das angibt, ob ein Neustart erforderlich ist. Das zweite Kommando fragt den Installationsstatus der Rolle und der Verwaltungstools ab; der Status `Installed` bedeutet, dass die Rolle verfügbar ist. Das dritte Kommando listet die Cmdlets des Moduls `ADDSDeployment`, darunter `Install-ADDSForest`, `Install-ADDSDomain`, `Install-ADDSDomainController` und die `Test-ADDS*`-Cmdlets für die Vorabprüfungen.

### Typische Fehler und Stolperfallen

Anfänger verwechseln häufig „Rolle installiert“ mit „Domain Controller“. Wer die Rolle installiert und den Server als Domain Controller ansieht, wundert sich, dass keine Anmeldung funktioniert. Erst nach der Promotion existiert eine Domain. Ein zweiter Fehler ist der Versuch, die Rolle auf einem produktiven Domain Controller per Befehl zu entfernen, statt ihn herabzustufen: Das Entfernen mit dem Cmdlet `Uninstall-WindowsFeature` verlangt zuerst `Uninstall-ADDSDomainController`.

```powershell
# FALSCH: Rolle auf einem laufenden DC einfach entfernen
Uninstall-WindowsFeature -Name AD-Domain-Services

# RICHTIG: erst sauber herabstufen, danach Rolle entfernen
Uninstall-ADDSDomainController -DemoteOperationMasterRole:$false -Confirm:$false
# (Der Befehl fragt nach einem lokalen Administratorkennwort; danach Neustart und erst dann:)
Uninstall-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

### Praxisbezug

> **Praxisbeispiel**
>
> Bei einem Windows-Server-Upgrade-Projekt installiert das Team die Rolle AD DS auf drei neuen Servern per Skript, noch bevor die Netzwerkfreigaben für die Promotion bereitstehen. Am Tag der Umstellung läuft nur noch die Promotion, ein Schritt von wenigen Minuten pro Server. Die Rollenvorbereitung im Voraus verkürzt das Wartungsfenster erheblich.

## 2.3 DNS Rolle

Active Directory ist ohne DNS nicht funktionsfähig. Das liegt daran, dass Clients ihre Domain Controller nicht über Broadcast oder feste Listen finden, sondern über *Service Records* (SRV-Einträge) im DNS. Meldet sich ein Client an, fragt er zum Beispiel nach `_ldap._tcp.dc._msdcs.corp.contoso.com` und erhält die Namen der Domain Controller, die LDAP anbieten. Fehlen diese Einträge, kann der Client keinen Domain Controller finden und die Anmeldung scheitert, obwohl alle Server laufen. Deshalb ist die DNS-Konfiguration die häufigste Ursache für Probleme in Active Directory.

Die Installation von DNS auf den Domain Controllern ist in den meisten Umgebungen die beste Wahl. Microsoft stellt in der Beschreibung von `Install-ADDSForest` klar, dass der DNS-Server-Dienst bei der Erstellung eines neuen Forests standardmäßig installiert wird und dass die Verwendung des Windows-DNS-Servers ausdrücklich empfohlen wird. Der Grund: Die AD-integrierten Zonen werden mit Active Directory repliziert, unterstützen sichere dynamische Updates und benötigen keine getrennte Zonenübertragung. Die Zone `corp.contoso.com` enthält dann automatisch die Host-Einträge der Domain Controller und die SRV-Einträge in den Unterbereichen `_msdcs`, `_sites`, `_tcp` und `_udp`.

Für externe Namen (zum Beispiel `www.example.org`) wird der interne DNS-Server mit einem *Forwarder* ausgestattet, der Anfragen außerhalb der eigenen Zonen an einen externen Resolver weiterleitet. Bei der Erstellung eines neuen Forests kann außerdem eine *DNS-Delegierung* angelegt werden, wenn die übergeordnete Zone (hier `contoso.com`) auf einem anderen DNS-Server liegt. Bei `Install-ADDSForest` steuert der Schalter `-CreateDnsDelegation` dieses Verhalten.

Das folgende Beispiel installiert die DNS-Rolle auf einem Server (falls man DNS getrennt vorbereiten möchte), richtet einen Forwarder ein und prüft, ob die Domain Controller im DNS gefunden werden. Dabei lernt man die wichtigsten DNS-Prüfbefehle kennen, die später auch im Betrieb gebraucht werden.

```powershell
# DNS-Rolle installieren (wird bei Install-ADDSForest sonst automatisch erledigt)
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Forwarder fuer externe Namen setzen (Beispiel: oeffentliche Resolver)
Add-DnsServerForwarder -IPAddress 1.1.1.1, 9.9.9.9
Get-DnsServerForwarder

# Zonen anzeigen: AD-integriert?
Get-DnsServerZone | Select-Object ZoneName, ZoneType, IsDsIntegrated, DynamicUpdate

# Domain Controller per SRV-Eintrag finden (so macht es auch ein Client)
Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.corp.contoso.com" -Type SRV |
    Select-Object Name, NameTarget, Port, Priority

# Host-Eintrag des DC pruefen und Namensaufloesung testen
Resolve-DnsName -Name "dc01.corp.contoso.com" -Type A
```

`Add-DnsServerForwarder` legt die Weiterleitungsziele fest; diese Adressen sind externe, vertrauenswürdige DNS-Server, aber *nicht* die Adressen, die auf Clients oder Domain Controllern in den Netzwerkeinstellungen stehen. `Get-DnsServerZone` zeigt, ob die Zonen AD-integriert sind und ob dynamische Updates erlaubt sind; der empfohlene Wert für interne AD-Zonen ist *Secure* (sichere dynamische Updates). Die Abfrage mit `Resolve-DnsName -Type SRV` ahmt nach, was ein Client bei der Anmeldung tut: Er fragt nach den Domain Controllern. Wenn die Ausgabe leer ist, liegt das Problem im DNS, nicht in Active Directory selbst.

### Typische Fehler und Stolperfallen

Der Klassiker: Auf den Clients ist als DNS-Server der Router oder ein externer Resolver eingetragen. Die Maschinen können im Internet surfen, den Domain Controller aber nicht finden. Der Beitritt zur Domain bricht mit der Meldung ab, dass kein Domain Controller für die Domain kontaktiert werden konnte. Die Lösung ist immer, die Clients über DHCP oder Konfiguration auf die internen DNS-Server (die Domain Controller) zu verweisen und externe Auflösung über Forwarder zu regeln.

```powershell
# FALSCH: Client nutzt den Router als DNS (loest die Domain nicht auf)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 10.10.0.1
Test-ComputerSecureChannel   # Fehler / Beitritt zur Domain scheitert

# RICHTIG: Clients verwenden die Domain Controller als DNS
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 10.10.0.11, 10.10.0.12
Resolve-DnsName corp.contoso.com
```

### Praxisbezug

> **Praxisbeispiel**
>
> Nach dem Umzug in ein neues Rechenzentrum meldet der Helpdesk, dass sich niemand mehr anmelden kann, obwohl die Domain Controller laufen. Der Administrator führt von einem Client `nslookup -type=SRV _ldap._tcp.dc._msdcs.corp.contoso.com` aus und erhält keine Antwort. Ursache: Der DHCP-Server im neuen Netz verteilt noch die alte DNS-Adresse. Nach Korrektur des DHCP-Bereichs ist das Problem in Minuten behoben.

## 2.4 Neuer Forest

Ein neuer Forest entsteht, wenn der erste Domain Controller einer neuen Organisation heraufgestuft wird. Dieser Schritt legt die Forest-Root-Domain, das Schema, die Konfigurationspartition und die erste Site (`Default-First-Site-Name`) an. Da sich die Grundentscheidungen später kaum ändern lassen, sollte man sie vorher dokumentieren: den *DNS-Namen* der Root-Domain, den *NetBIOS-Namen*, die *Funktionsebene*, den Speicherort von Datenbank, Protokollen und SYSVOL sowie das *DSRM-Kennwort*. DSRM steht für *Directory Services Restore Mode*, einen Wiederherstellungsmodus, in dem der Domain Controller ohne gestartetes AD DS hochfährt; das Kennwort dafür ist ein lokales Administratorkennwort und muss sicher aufbewahrt werden.

Beim Namen gelten die Hinweise der Microsoft-Dokumentation. Wenn die Organisation einen registrierten Internetnamen besitzt, verwendet man einen Namen relativ dazu (zum Beispiel `corp.contoso.com`); einen Namen wie `.local` sollte man vermeiden, und ein einzelnes Label (zum Beispiel `contoso`) ist zu vermeiden, weil sich solche Namen nicht registrieren lassen und zusätzliche Konfiguration erfordern. Vermeiden sollte man außerdem Unterstriche in Domainnamen und Namen von Geschäftsbereichen, die sich ändern können. Der NetBIOS-Name wird standardmäßig aus der ersten Beschriftung (bis zu 15 Zeichen) abgeleitet.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft-Dokumentation müssen neue Active-Directory-Forests mindestens auf der Funktionsebene Windows Server 2016 laufen. In der Beschreibung von `Install-ADDSForest` wird für Windows Server 2025 der Wert `Win2025` für `-ForestMode` gezeigt; die Funktionsebene Windows Server 2025 ist Voraussetzung für die optionale 32-KB-Datenbankseite. Außerdem werden neue Forests unter Windows Server 2025 mit einem 32-KB-fähigen Datenbankformat installiert, das aber zunächst im 8-KB-Simulationsmodus arbeitet. Diese Angaben ändern sich mit neuen Windows-Server-Versionen; vor einer Installation sollte die aktuelle Dokumentation geprüft werden.

Das Beispiel führt die Installation eines neuen Forests in der sicheren Reihenfolge durch: zuerst die Vorabprüfung mit `Test-ADDSForestInstallation`, dann die Installation mit allen Parametern in einer *Hashtable* (Splatting), anschließend automatischer Neustart. Das DSRM-Kennwort wird nicht im Klartext im Skript abgelegt, sondern interaktiv abgefragt.

```powershell
# DSRM-Kennwort abfragen (nicht im Skript speichern)
$dsrm = Read-Host -Prompt "DSRM-Kennwort" -AsSecureString

$parameter = @{
    DomainName                    = "corp.contoso.com"
    DomainNetbiosName             = "CORP"
    ForestMode                    = "WinThreshold"      # Windows Server 2016
    DomainMode                    = "WinThreshold"
    InstallDns                    = $true
    DatabasePath                  = "D:\NTDS"
    LogPath                       = "E:\NTDSLogs"
    SysvolPath                    = "D:\SYSVOL"
    SafeModeAdministratorPassword = $dsrm
    NoRebootOnCompletion          = $false
}

# 1) Vorabpruefung: veraendert nichts, meldet Probleme
Test-ADDSForestInstallation @parameter

# 2) Erst wenn Schritt 1 ohne Fehler endet: Installation
Install-ADDSForest @parameter -Force
```

Die Hashtable `$parameter` sammelt alle Einstellungen an einem Ort; `@parameter` „entpackt“ sie beim Aufruf (Splatting). `ForestMode` und `DomainMode` legen die Funktionsebene fest; `WinThreshold` entspricht Windows Server 2016. Datenbank, Protokolle und SYSVOL werden auf getrennte Laufwerke gelegt, falls vorhanden. Der Aufruf `Test-ADDSForestInstallation` führt dieselben Voraussetzungsprüfungen durch wie die Installation, ohne etwas zu verändern. Erst dann folgt `Install-ADDSForest`; der Schalter `-Force` unterdrückt die Rückfrage, und der Server startet nach Abschluss automatisch neu (laut Dokumentation ist das Überschreiben des Neustarts nicht empfohlen). Nach dem Neustart sind alle Anmeldungen im Format `CORP\Administrator`.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die Eingabe des DSRM-Kennworts in Klartext in einem Skript, das später in einem Repository oder auf einer Freigabe landet. Die Microsoft-Dokumentation nennt diese Praxis ausdrücklich nicht empfehlenswert. Der zweite Fehler ist das Überspringen der Vorprüfung mit `-SkipPreChecks`; Microsoft warnt, dass dies zu einer teilweisen Promotion oder einem beschädigten Forest führen kann. Der dritte Fehler ist ein zu langer NetBIOS-Name: Namen über 15 Zeichen werden nicht automatisch akzeptiert, hier muss `-DomainNetbiosName` bewusst gesetzt werden.

```powershell
# FALSCH: Kennwort im Klartext, Pruefungen uebersprungen
Install-ADDSForest -DomainName corp.contoso.com `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "Passw0rd!" -AsPlainText -Force) `
    -SkipPreChecks -Force

# RICHTIG: Kennwort interaktiv, Vorpruefung zuerst
$dsrm = Read-Host -AsSecureString "DSRM-Kennwort"
Test-ADDSForestInstallation -DomainName corp.contoso.com -SafeModeAdministratorPassword $dsrm
Install-ADDSForest -DomainName corp.contoso.com -SafeModeAdministratorPassword $dsrm -Force
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen baut eine neue, abgeschottete Verwaltungsumgebung für privilegierte Konten auf (ein sogenannter Admin-Forest, siehe Modul 9). Das IT-Team installiert den Forest mit dem beschriebenen Verfahren: Vorprüfung, dokumentierte Parameter in einem versionierten Skript, DSRM-Kennwort im Passwortsafe. Die Dokumentation der Parameter hilft später, wenn der Forest nach einem Fehler neu aufgebaut werden muss.

## 2.5 Zusätzlicher Domain Controller

Ein einzelner Domain Controller ist ein Risiko. Fällt er aus, ist die Anmeldung gestört, und alle Dienste, die auf Active Directory angewiesen sind, stehen still. Deshalb gehört mindestens ein zweiter Domain Controller zur Grundausstattung. Zusätzliche Domain Controller dienen der *Redundanz* (Ausfallsicherheit), der *Standortnähe* (Anmeldung vor Ort statt über die WAN-Leitung) und der *Lastverteilung*. Sie werden dem bestehenden Verzeichnis über die Replikation hinzugefügt: Der neue Server kopiert alle Daten von einem vorhandenen Domain Controller und wird dann zu einem gleichberechtigten Partner.

Für die Promotion braucht der Server zuvor die Rolle AD DS (Lerneinheit 2.2), muss mit einem DNS-Server aus der Domain sprechen (zum Beispiel `DC01`) und sollte bereits Mitglied der Domain oder zumindest im Netz der Domain sein. Ein Konto aus der Gruppe Domain Admins führt die Promotion durch. Die Daten werden *über das Netzwerk* repliziert; bei großen Datenbanken oder schmalen Leitungen kann man stattdessen die Funktion *Install From Media* (IFM) nutzen, bei der die Datenbank aus einer Sicherung eingelesen wird und nur die Änderungen seit der Sicherung repliziert werden.

Ein weiterer Punkt ist die Standortzuordnung. Der neue Domain Controller ordnet sich anhand seiner IP-Adresse einer Site zu; ist das Subnetz nicht definiert, landet er in der Standardsite. Mit dem Parameter `-SiteName` kann man die Site beim Promotion festlegen. Nach der Promotion sollte man prüfen, ob die Replikation läuft, ob der Server im DNS registriert ist und ob er (bei Bedarf) auch Global Catalog ist. Für kleine und mittlere Umgebungen empfiehlt sich, alle Domain Controller zu Global-Catalog-Servern zu machen; Details zur Planung folgen in Modul 6.

```powershell
# Auf DC02: DNS zeigt zunaechst auf DC01, danach Rolle installieren
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 10.10.0.11
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

$cred = Get-Credential -Message "Domain-Admin (z. B. CORP\Administrator)"
$dsrm = Read-Host -AsSecureString "DSRM-Kennwort fuer DC02"

$p = @{
    DomainName                    = "corp.contoso.com"
    Credential                    = $cred
    SiteName                      = "Default-First-Site-Name"
    InstallDns                    = $true
    NoGlobalCatalog               = $false
    SafeModeAdministratorPassword = $dsrm
}
Test-ADDSDomainControllerInstallation @p
Install-ADDSDomainController @p -Force
```

Der Ablauf entspricht dem des Forests: Zuerst zeigt `DC02` auf `DC01` als DNS-Server, damit die Domain aufgelöst werden kann. Dann wird die Rolle installiert. Für die Promotion werden Zugangsdaten abgefragt, das DSRM-Kennwort ist ebenfalls interaktiv. In der Hashtable stehen der Domainname, die Site, die DNS-Rolle und die Information, dass der Server Global Catalog sein soll (`NoGlobalCatalog = $false`). `Test-ADDSDomainControllerInstallation` prüft die Voraussetzungen, `Install-ADDSDomainController` führt die Heraufstufung durch. Nach dem Neustart erscheint der Server in `Get-ADDomainController`.

Wenn der neue Domain Controller sein Pendant sicher erreicht, kann man die Qualität der Promotion sofort kontrollieren. Das folgende Skript zeigt, ob beide Domain Controller sichtbar sind, ob die Replikation gesund ist und ob SYSVOL und NETLOGON freigegeben sind.

```powershell
Get-ADDomainController -Filter * |
    Select-Object Name, Site, IsGlobalCatalog, IPv4Address | Format-Table -AutoSize

repadmin /replsummary                      # Zusammenfassung der Replikation
repadmin /showrepl DC02                    # Details zu DC02
Get-SmbShare -Name SYSVOL, NETLOGON        # Freigaben vorhanden?
dcdiag /s:DC02 /q                          # nur Fehler anzeigen
```

### Typische Fehler und Stolperfallen

Die häufigste Ursache für Promotion-Fehler bei zusätzlichen Domain Controllern ist wieder DNS: Der neue Server kann den vorhandenen Domain Controller nicht per Namen auflösen. Ein weiterer Stolperstein ist die Zeitabweichung zum bestehenden Domain Controller, die Kerberos-Authentifizierung verhindert. Und: Wer einen virtuellen Domain Controller durch Klonen einer bestehenden VM erzeugt, ohne die Schutzmechanismen von *Cloneable Domain Controllers* zu beachten, erhält doppelte Identitäten im Verzeichnis. Zusätzliche Domain Controller werden immer durch Promotion erzeugt.

```powershell
# FALSCH: VM von DC01 kopieren und als DC02 starten (doppelte Identitaet)

# RICHTIG: neue VM, Rolle installieren, Promotion
Install-ADDSDomainController @p -Force
```

### Praxisbezug

> **Praxisbeispiel**
>
> In einem Unternehmen mit zwei Standorten läuft der einzige Domain Controller am Hauptstandort. Als die WAN-Leitung für drei Stunden ausfällt, kann sich im Zweigstandort niemand mehr anmelden. Nach dem Projekt „zusätzlicher Domain Controller vor Ort“ funktionieren Anmeldungen und Dateizugriffe auch bei Leitungsausfall, und die Replikation holt die Änderungen nach, sobald die Leitung wieder verfügbar ist.

## 2.6 Read-Only Domain Controller

Ein *Read-Only Domain Controller* (RODC) ist ein Domain Controller mit einer schreibgeschützten Kopie der Datenbank. Er ist für Standorte gedacht, an denen die physische Sicherheit gering ist (kein abschließbarer Serverraum, Filiale, Außenstelle) oder an denen kein qualifiziertes Personal für die Verwaltung vorhanden ist. Die Idee: Wird ein solcher Server gestohlen oder kompromittiert, soll der Schaden begrenzt bleiben. Dafür unterscheidet sich der RODC in vier Punkten von einem normalen, schreibbaren Domain Controller: Er nimmt keine Änderungen direkt entgegen, sondern leitet sie an einen schreibbaren Domain Controller weiter; er repliziert nur in eine Richtung (eingehend); er speichert standardmäßig *keine* Kennwörter der Konten; und seine lokale Verwaltung kann einer bestimmten Gruppe oder einem Benutzer ohne weitere Domänenrechte übertragen werden.

Welche Kennwörter ein RODC zwischenspeichern darf, regelt die *Kennwortreplikationsrichtlinie* (Password Replication Policy, PRP). Sie besteht aus einer *Zulassungsliste* und einer *Ablehnungsliste*. Standardmäßig ist die Zulassungsliste leer, und die Ablehnungsliste enthält sensible Gruppen. Zu den Standardgruppen gehören die *Allowed RODC Password Replication Group* und die *Denied RODC Password Replication Group*, die in der Microsoft-Dokumentation zu den PRP-Cmdlets als Beispiel für die Ausgabe erscheinen. Der Ablauf ist: Ein Benutzer meldet sich am Standort an; der RODC leitet die Anfrage an einen schreibbaren Domain Controller weiter; ist das Konto in der Zulassungsliste, wird das Kennwort anschließend auf den RODC kopiert, sodass spätere Anmeldungen auch bei WAN-Ausfall funktionieren. Alle Konten, die nicht freigegeben sind, können sich bei WAN-Ausfall nicht anmelden.

Die Kunst besteht darin, die Liste klein zu halten: Nur die Konten der Mitarbeiter, die am Standort arbeiten, und die Computerkonten der Geräte vor Ort gehören in die Zulassungsliste. Administratoren und Dienstkonten mit hohen Rechten gehören in die Ablehnungsliste. Außerdem gibt es das Konzept der *gestaffelten Installation* (Staged Installation): Ein Administrator legt das RODC-Konto vorab im Active Directory an und benennt eine Person oder Gruppe, die den Server vor Ort heraufstufen darf. Diese Person braucht dann keine Domain-Admin-Rechte.

Das folgende Skript legt zunächst das RODC-Konto an (gestaffelte Installation), konfiguriert die Kennwortreplikationsrichtlinie und stuft den Server später vor Ort herauf. Dazu verwendet es die Cmdlets `Add-ADDSReadOnlyDomainControllerAccount` und `Add-ADDomainControllerPasswordReplicationPolicy`.

```powershell
# --- Schritt 1: Auf einem schreibbaren DC (Domain-Admin); Site "Graz" muss existieren ---
$delegiert = "CORP\Filiale-Admins"       # darf den RODC vor Ort heraufstufen und verwalten
Add-ADDSReadOnlyDomainControllerAccount `
    -DomainControllerAccountName "RODC-GRAZ01" `
    -DomainName "corp.contoso.com" `
    -SiteName "Graz" `
    -DelegatedAdministratorAccountName $delegiert `
    -AllowPasswordReplicationAccountName "CORP\Graz-Benutzer" `
    -DenyPasswordReplicationAccountName "Domain Admins","Enterprise Admins"

# --- Schritt 2: Pruefen, welche Konten zwischengespeichert werden duerfen ---
Get-ADDomainController -Filter "IsReadOnly -eq `$true" |
    Get-ADDomainControllerPasswordReplicationPolicy -Allowed
Get-ADDomainController -Filter "IsReadOnly -eq `$true" |
    Get-ADDomainControllerPasswordReplicationPolicy -Denied

# --- Schritt 3: Weitere Konten freigeben (Beispiel: Computerkonto) ---
Add-ADDomainControllerPasswordReplicationPolicy -Identity "RODC-GRAZ01" `
    -AllowedList 'GRAZ-PC01$'

# --- Schritt 4: Vor Ort auf dem Server (Rolle bereits installiert) ---
$dsrm = Read-Host -AsSecureString "DSRM-Kennwort"
Install-ADDSDomainController -DomainName "corp.contoso.com" `
    -UseExistingAccount `
    -Credential (Get-Credential "CORP\Filiale-Admin1") `
    -SafeModeAdministratorPassword $dsrm -Force
```

Schritt 1 erzeugt das RODC-Konto, ordnet es der Site `Graz` zu und legt die Standardlisten fest: Das Konto der Filialbenutzergruppe darf zwischengespeichert werden, Domain Admins und Enterprise Admins nie. Die delegierte Gruppe darf den Server später selbst heraufstufen und lokal verwalten. In Schritt 2 liest man die resultierenden Listen aus; der Bezeichner ```$true`` schützt das Dollarzeichen in einem Filter-String vor der Auswertung durch PowerShell. Schritt 3 zeigt, wie man ein einzelnes Computerkonto freigibt; die Microsoft-Dokumentation weist darauf hin, dass das Cmdlet an schreibbaren Domain Controllern funktioniert, nicht an einem RODC selbst. Schritt 4 läuft auf dem Server in der Filiale, der laut Microsoft-Dokumentation noch nicht Mitglied der Domain sein darf und auf dem die Rolle AD DS bereits installiert ist: `-UseExistingAccount` bindet ihn an das vorbereitete RODC-Konto, sodass die dort festgelegten Optionen (Site, Kennwortrichtlinie, Delegierung) übernommen werden. Ohne vorbereitetes Konto würde man stattdessen `-ReadOnlyReplica` verwenden und die Optionen direkt angeben. Die Site muss in beiden Fällen bereits existieren, denn die Cmdlets legen keine Sites an.

### Typische Fehler und Stolperfallen

Der größte Fehler ist, die Zulassungsliste zu großzügig zu füllen, etwa durch Aufnahme der Gruppe `Domain Users`. Dann liegen die Kennwörter fast aller Konten auf dem RODC, und der Sicherheitsgewinn ist dahin. Ein zweiter Fehler: Dienste oder Anwendungen in der Filiale, die Schreibzugriffe auf das Verzeichnis erwarten, funktionieren nicht, weil ein RODC keine direkten Änderungen annimmt. Ein dritter: Wer nach einem Diebstahl des Servers nicht weiß, welche Kennwörter dort lagen, kann sie nicht gezielt zurücksetzen. Die Liste der zwischengespeicherten Konten sollte daher bekannt und dokumentiert sein.

```powershell
# FALSCH: Alle Benutzer duerfen auf den RODC repliziert werden
Add-ADDomainControllerPasswordReplicationPolicy -Identity "RODC-GRAZ01" -AllowedList "Domain Users"

# RICHTIG: nur die Filialgruppe, Admins explizit ausschliessen
Add-ADDomainControllerPasswordReplicationPolicy -Identity "RODC-GRAZ01" -AllowedList "Graz-Benutzer"
Add-ADDomainControllerPasswordReplicationPolicy -Identity "RODC-GRAZ01" -DeniedList "Domain Admins","Schema Admins"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Handelskette betreibt 40 Filialen. In jeder Filiale steht ein kleiner Server im Büro des Filialleiters. Statt 40 schreibbarer Domain Controller kommen 40 RODCs zum Einsatz. Die Filialen arbeiten mit lokaler Anmeldung, die WAN-Anbindung ist nur für Replikation nötig. Wird ein Server gestohlen, setzt die IT die Kennwörter der zwischengespeicherten Konten dieser Filiale zurück; Konten anderer Standorte sind nicht betroffen.

## 2.7 Server Core Deployment

Windows Server gibt es in zwei Installationsoptionen: *Server mit Desktopdarstellung* (die klassische grafische Oberfläche) und *Server Core* (eine reduzierte Installation ohne Desktop). Server Core hat weniger Komponenten, benötigt weniger Updates und Neustarts, verbraucht weniger Ressourcen und bietet eine kleinere Angriffsfläche. Für Domain Controller ist das ideal, denn sie sollen genau eine Aufgabe erfüllen und möglichst selten angefasst werden. Microsoft empfiehlt Server Core seit Jahren als bevorzugte Variante für Infrastrukturrollen wie AD DS, DNS und DHCP. Wichtig: Eine Umstellung zwischen den beiden Installationsoptionen ist nach der Installation nicht ohne Neuinstallation möglich, die Entscheidung gehört also in die Planung.

Auf Server Core gibt es keine grafische Verwaltung. Die lokale Konsole bietet eine Eingabeaufforderung (oder PowerShell) und das Werkzeug `sconfig`, ein textbasiertes Menü für Grundeinstellungen wie Computername, Netzwerk, Domänenbeitritt, Updates und Remotedesktop. Die tägliche Verwaltung erfolgt *remote*: von einem Verwaltungsrechner mit RSAT, mit dem Windows Admin Center oder per PowerShell-Remoting. Wer Server Core verwendet, lernt, dass ein Domain Controller nicht von Hand „bedient“ werden muss, sondern skriptgesteuert und reproduzierbar eingerichtet wird.

Die Rolle AD DS lässt sich auf Server Core mit denselben PowerShell-Befehlen installieren und heraufstufen wie auf einem Server mit Desktop. Der Unterschied liegt darin, dass die Verwaltungswerkzeuge (die grafischen Konsolen) nicht lokal installiert werden (und nicht installiert werden können), sondern auf dem Verwaltungsrechner liegen. Das folgende Beispiel zeigt die Konfiguration eines frischen Server-Core-Computers von einem Admin-PC aus, per PowerShell-Remoting.

```powershell
# Auf dem Server Core (lokal, einmalig): Grundkonfiguration ueber das Menue
sconfig
#   -> Option 2: Computername setzen; Option 8: Netzwerkeinstellungen (statische IP, DNS);
#   -> Option 4: Remoteverwaltung aktivieren

# Auf dem Admin-PC: Verbindung testen und Rolle remote installieren
$server = "DC03"
Test-WSMan -ComputerName $server
$cred = Get-Credential "$server\Administrator"

Invoke-Command -ComputerName $server -Credential $cred -ScriptBlock {
    Install-WindowsFeature AD-Domain-Services
}

# Verwaltungstools (nur auf dem Admin-PC): RSAT fuer AD
Get-WindowsCapability -Online -Name "Rsat.ActiveDirectory*" |
    Add-WindowsCapability -Online
```

Die Datei `sconfig` wird lokal auf dem Server Core gestartet; Optionen wie Computername und Netzwerk sind dort nummeriert. Die Prüfung mit `Test-WSMan` zeigt, ob PowerShell-Remoting auf dem Zielserver erreichbar ist. `Invoke-Command` führt den Skriptblock auf dem Remote-Server aus; dort wird die Rolle ohne das Flag `-IncludeManagementTools` installiert, denn grafische Tools gehören nicht auf Server Core. Die RSAT-Funktionen werden auf dem Admin-PC als Windows-Funktion nachinstalliert; unter Windows 10 und 11 geschieht das über `Add-WindowsCapability`, auf Windows Server über `Install-WindowsFeature RSAT-AD-Tools`.

### Typische Fehler und Stolperfallen

Ein typischer Fehler ist, Server Core zu wählen, ohne Fernverwaltung vorbereitet zu haben: Wer die Netzwerkkonfiguration oder die Firewallregeln für Remoting nicht gesetzt hat, sitzt vor einer Eingabeaufforderung und kann nichts bequem erledigen. Der zweite Fehler ist das Starten von grafischen Programmen auf Server Core, das nicht funktioniert. Wer ein Programm braucht, das eine grafische Oberfläche voraussetzt, plant ohnehin eine falsche Rolle für diesen Server.

```powershell
# FALSCH: auf Server Core versuchen, die grafische Konsole zu starten
dsa.msc      # funktioniert nicht, es gibt keine GUI

# RICHTIG: vom Admin-PC aus verwalten (RSAT) oder PowerShell verwenden
Get-ADUser -Filter * -Server DC03 | Select-Object -First 5
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen rüstet seine Domain Controller auf Server Core um. Das Update-Fenster pro Monat schrumpft, weil weniger Patches nötig sind, und die Sicherheitsprüfung findet weniger Angriffsfläche. Die Administratoren arbeiten mit einem gemeinsamen Verwaltungsserver und einer Sammlung von Skripten, mit denen sie jede Konfiguration reproduzierbar anwenden können.

## 2.8 PowerShell Deployment

Automatisierung ist bei der Domain-Controller-Installation kein Luxus. Ein Skript dokumentiert zugleich, *wie* der Server eingerichtet wurde, und lässt sich bei Bedarf wiederholen (Neuaufbau nach Katastrophen, Testumgebungen, Rollouts an mehreren Standorten). Ein gutes Skript ist *reproduzierbar* (gleiche Eingaben, gleiches Ergebnis), *überprüfbar* (die Vorprüfung ist Teil des Ablaufs), *sicher* (keine Kennwörter im Klartext) und *protokolliert* (das Ergebnis steht in einer Logdatei).

Drei Techniken sind dabei zentral. *Parameter*: Das Skript erwartet Eingaben wie Domainname und Server, statt sie fest einzuprogrammieren. *Splatting*: Viele Parameter werden in einer Hashtable gesammelt und gemeinsam übergeben, was die Lesbarkeit erhöht und Fehler durch vergessene Backticks verhindert. *Fehlerbehandlung*: Mit `try/catch` und `$ErrorActionPreference = 'Stop'` bricht das Skript beim ersten Fehler ab, statt mit einem halb konfigurierten System weiterzumachen. Der Umgang mit Zugangsdaten verdient besondere Aufmerksamkeit: Die Microsoft-Dokumentation nennt die Umwandlung eines Klartextkennworts mit `ConvertTo-SecureString -AsPlainText` ausdrücklich nicht empfehlenswert; besser ist die interaktive Abfrage oder ein Geheimnisspeicher (zum Beispiel die PowerShell-Module `SecretManagement` und `SecretStore`, oder ein Passwortsafe der Organisation).

Das folgende Skript ist eine vollständige, wiederverwendbare Vorlage für die Erstellung eines neuen Forests, die diese Prinzipien vereint. Es protokolliert in eine Datei, prüft Voraussetzungen, bricht bei Fehlern ab und trennt den Prüfmodus (`-WhatIf`) von der Ausführung.

```powershell
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$DomainName,
    [Parameter(Mandatory)] [string]$NetbiosName,
    [string]$DatabasePath = "D:\NTDS",
    [string]$LogPath      = "E:\NTDSLogs",
    [string]$SysvolPath   = "D:\SYSVOL"
)

$ErrorActionPreference = "Stop"
$logDatei = "C:\Install\Forest-Setup-{0:yyyyMMdd-HHmm}.log" -f (Get-Date)
New-Item -ItemType Directory -Path (Split-Path $logDatei) -Force | Out-Null
Start-Transcript -Path $logDatei

try {
    # 1) Rolle sicherstellen
    if ((Get-WindowsFeature AD-Domain-Services).InstallState -ne "Installed") {
        Install-WindowsFeature AD-Domain-Services -IncludeManagementTools | Out-Null
    }

    # 2) Pfade pruefen
    foreach ($pfad in $DatabasePath, $LogPath, $SysvolPath) {
        $laufwerk = Split-Path $pfad -Qualifier
        if (-not (Test-Path $laufwerk)) { throw "Laufwerk $laufwerk fehlt (fuer $pfad)." }
    }

    # 3) DSRM-Kennwort sicher erfragen
    $dsrm = Read-Host -Prompt "DSRM-Kennwort" -AsSecureString

    $p = @{
        DomainName                    = $DomainName
        DomainNetbiosName             = $NetbiosName
        ForestMode                    = "WinThreshold"
        DomainMode                    = "WinThreshold"
        InstallDns                    = $true
        DatabasePath                  = $DatabasePath
        LogPath                       = $LogPath
        SysvolPath                    = $SysvolPath
        SafeModeAdministratorPassword = $dsrm
    }

    # 4) Vorpruefung (immer) und Installation (nur ohne -WhatIf)
    Test-ADDSForestInstallation @p | Out-Host
    if ($PSCmdlet.ShouldProcess($DomainName, "Neuen Forest installieren")) {
        Install-ADDSForest @p -Force
    }
}
catch {
    Write-Error "Abbruch: $($_.Exception.Message)"
    throw
}
finally {
    Stop-Transcript
}
```

Die Kopfzeile `#Requires -RunAsAdministrator` verhindert den Start ohne erhöhte Rechte. `SupportsShouldProcess` aktiviert die Schalter `-WhatIf` und `-Confirm`. Das Skript beendet sich bei jedem Fehler (`$ErrorActionPreference = "Stop"`), und der `Transcript` schreibt alles in eine Logdatei. Die Pfadprüfung stellt sicher, dass die gewünschten Laufwerke existieren, bevor die Installation beginnt. Der Aufruf `$PSCmdlet.ShouldProcess` führt die eigentliche Installation nur aus, wenn kein `-WhatIf` gesetzt ist.

### Typische Fehler und Stolperfallen

Ein Klassiker: Das Skript läuft in der Entwicklungsumgebung einwandfrei und scheitert in der Produktion, weil Laufwerksbuchstaben oder Pfade abweichen. Pfade und Namen gehören deshalb in Parameter oder eine Konfigurationsdatei. Ein zweiter Stolperstein sind Skripte, die ein Kennwort in einer Datei ablegen. Auch mit `ConvertFrom-SecureString` verschlüsselte Dateien sind nur an Benutzer und Computer gebunden, nicht aber „sicher“ im Sinne eines Passwortsafes. Drittens: Wer ohne `try/catch` und ohne `ErrorActionPreference` arbeitet, bekommt Fehler als rote Meldung, aber das Skript läuft weiter und richtet ein halbes System ein.

```powershell
# FALSCH: Fehler werden nicht behandelt, Kennwort im Skript
$pw = ConvertTo-SecureString "Passw0rd!" -AsPlainText -Force
Install-ADDSForest -DomainName corp.contoso.com -SafeModeAdministratorPassword $pw -Force
Write-Host "Fertig"      # laeuft auch bei Fehlschlag

# RICHTIG: Abbruch bei Fehler, Kennwort interaktiv
$ErrorActionPreference = "Stop"
try {
    $pw = Read-Host -AsSecureString "DSRM-Kennwort"
    Install-ADDSForest -DomainName corp.contoso.com -SafeModeAdministratorPassword $pw -Force
}
catch { Write-Error $_; exit 1 }
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Systemhaus betreut 30 Kunden mit kleinen Domains. Das Team pflegt ein Git-Repository mit einem getesteten Deployment-Skript und einer Konfigurationsdatei pro Kunde. Beim Neuaufbau eines Domain Controllers nach einem Hardwarefehler genügt es, das Skript mit der Konfiguration des Kunden zu starten. Das spart Zeit, und die Konfiguration aller Kunden bleibt einheitlich und nachvollziehbar.

## 2.9 Installationsreview

Die Installation ist erst abgeschlossen, wenn sie überprüft ist. Ein *Installationsreview* ist eine strukturierte Abnahme: Man prüft, ob die Dienste laufen, ob DNS-Einträge existieren, ob die Replikation funktioniert, ob die Freigaben `SYSVOL` und `NETLOGON` vorhanden sind, ob Zeit und Standort stimmen, ob Ereignisprotokolle Fehler zeigen und ob die Sicherungen eingerichtet sind. Der Review ist zugleich die Dokumentation für später: Wer in zwei Jahren ein Problem untersucht, möchte den Sollzustand kennen.

Die wichtigsten Prüfpunkte lassen sich in vier Gruppen einteilen. *Dienste und Freigaben*: laufen NTDS, KDC, Netlogon, DNS, DFSR und W32Time, und sind SYSVOL und NETLOGON freigegeben? *DNS*: sind die Host-Einträge und SRV-Einträge vorhanden, ist der Domain Controller sein eigener (und ein zweiter) DNS-Server? *Replikation*: meldet `repadmin` keine Fehler, ist die Verzögerung klein? *Betrieb*: ist die Zeit korrekt, sind Sicherungen konfiguriert, ist der Server im Monitoring und in der Dokumentation? Dazu kommt die *Sicherheit*: Standardkonten, Gruppenmitgliedschaften (Schema Admins sollte leer sein) und die Firewall.

Das nachfolgende Skript automatisiert einen Teil dieser Prüfung und erzeugt einen Bericht, den man im Abnahmeprotokoll ablegen kann. Es liest, ohne etwas zu verändern, und gibt eine Tabelle mit Prüfpunkt, Ergebnis und Soll-Hinweis aus. Die Ergebnisse werden zusätzlich als CSV-Datei gespeichert.

```powershell
Import-Module ActiveDirectory
$ergebnis = New-Object System.Collections.Generic.List[object]
function Pruefe($Name, $Ok, $Detail) {
    $ergebnis.Add([pscustomobject]@{ Pruefpunkt = $Name; OK = $Ok; Detail = $Detail })
}

# 1) Dienste
foreach ($d in "NTDS","KDC","Netlogon","DNS","DFSR","W32Time") {
    $s = Get-Service -Name $d -ErrorAction SilentlyContinue
    Pruefe "Dienst $d" ($s.Status -eq "Running") $s.Status
}

# 2) Freigaben
foreach ($f in "SYSVOL","NETLOGON") {
    Pruefe "Freigabe $f" ([bool](Get-SmbShare -Name $f -ErrorAction SilentlyContinue)) ""
}

# 3) DNS: SRV-Eintrag fuer diesen DC vorhanden?
$srv = Resolve-DnsName "_ldap._tcp.dc._msdcs.$((Get-ADDomain).DNSRoot)" -Type SRV -ErrorAction SilentlyContinue
Pruefe "SRV-Eintraege fuer LDAP" ([bool]$srv) ("{0} Eintraege" -f @($srv).Count)

# 4) Mindestens zwei Domain Controller?
$dcs = Get-ADDomainController -Filter *
Pruefe "Mindestens 2 DCs" ($dcs.Count -ge 2) ("{0} DC(s)" -f $dcs.Count)

# 5) Replikationsfehler?
$fehler = Get-ADReplicationFailure -Target $env:COMPUTERNAME -ErrorAction SilentlyContinue
Pruefe "Keine Replikationsfehler" (-not $fehler) ("{0} Fehler" -f @($fehler).Count)

# 6) Schema Admins leer?
$sa = Get-ADGroupMember "Schema Admins" -ErrorAction SilentlyContinue
Pruefe "Schema Admins leer" (-not $sa) ("{0} Mitglieder" -f @($sa).Count)

$ergebnis | Format-Table -AutoSize
$ergebnis | Export-Csv -Path ".\DC-Review-$($env:COMPUTERNAME).csv" -NoTypeInformation -Encoding UTF8
```

Die Hilfsfunktion `Pruefe` sammelt jede Prüfung als Objekt in einer Liste. Die Dienstschleife liest Status und Starttyp, die Freigabenprüfung nutzt `Get-SmbShare`. Der SRV-Test fragt, was ein Client fragen würde. Die Prüfung „mindestens zwei Domain Controller“ erkennt die häufigste Schwäche kleiner Umgebungen. `Get-ADReplicationFailure` fasst Replikationsfehler zusammen. Am Ende erscheint eine Tabelle, die zusätzlich als CSV-Datei im aktuellen Ordner gespeichert wird. Ein grünes Ergebnis ersetzt die *manuelle* Durchsicht der Ereignisprotokolle (`Directory Service`, `DNS Server`, `System`) nicht, die Teil des Reviews bleibt.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, den Review ganz auszulassen, weil „alles ja gut aussieht“. Typische Probleme wie ein fehlender DNS-Eintrag, ein vergessener Standort oder ein nicht freigegebenes SYSVOL zeigen sich oft erst Tage später durch scheinbar unrelatierte Symptome. Ein zweiter Fehler ist, nur zu prüfen, ob der Server startet, und nicht, ob die Replikation in beide Richtungen funktioniert. Ein dritter ist die Abnahme ohne Dokumentation; wenn die Ergebnisse nicht abgelegt sind, hilft der Review nicht bei späteren Fehlersuchen.

```powershell
# FALSCH: Nur kontrollieren, ob sich jemand anmelden kann
whoami

# RICHTIG: Replikation in beide Richtungen und Diagnose
repadmin /replsummary
repadmin /showrepl * /csv > repl-status.csv
dcdiag /v /c /e > dcdiag-vollstaendig.txt
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Auditor fragt bei einer ISO-27001-Prüfung, wie der Zustand der Domain Controller bei Inbetriebnahme dokumentiert wurde. Das IT-Team legt die archivierten Abnahmeberichte vor, die für jeden Domain Controller zum Datum der Installation das Ergebnis der Prüfskripte und der `dcdiag`-Ausgabe enthalten. Der Nachweis ist in wenigen Minuten erbracht, weil die Abnahme immer nach demselben Muster erfolgt ist.

## 2.10 Übungsaufgaben zu Modul 02

Die Aufgaben 1 bis 3 prüfen das Verständnis, die Aufgaben 4 bis 8 sind praktisch und setzen eine Laborumgebung mit mindestens zwei Windows-Servern voraus (zum Beispiel zwei virtuelle Maschinen ohne Anbindung an das Produktionsnetz).

**Aufgabe 2.1** **Zwei Schritte.** Erklären Sie, warum die Installation von Active Directory in die Schritte „Rolle installieren“ und „Promotion“ getrennt ist, und nennen Sie je einen Befehl dafür.

**Aufgabe 2.2** **DNS-Ursachen.** Ein neuer Client kann der Domain nicht beitreten, die Fehlermeldung lautet, dass kein Domain Controller kontaktiert werden konnte. Nennen Sie drei Dinge, die Sie prüfen, und die Reihenfolge.

**Aufgabe 2.3** **RODC-Sicherheit.** Beschreiben Sie in eigenen Worten, wie ein RODC den Schaden bei Diebstahl begrenzt, und welche Rolle die Kennwortreplikationsrichtlinie dabei spielt.

**Aufgabe 2.4** **Vorprüfung.** Schreiben Sie ein Skript, das auf einem Server prüft, ob er für die Promotion bereit ist: statische IP (kein DHCP), Computername höchstens 15 Zeichen, mindestens 20 GB freier Platz auf dem Systemlaufwerk. Das Skript soll für jeden Punkt `OK` oder `FEHLER` ausgeben.

**Aufgabe 2.5** **Rolle und Vorabprüfung.** Installieren Sie auf Ihrem ersten Server die Rolle AD DS und führen Sie `Test-ADDSForestInstallation` für die Domain `lab.contoso.com` aus. Dokumentieren Sie die Meldungen und erklären Sie jede Warnung.

**Aufgabe 2.6** **Forest und zweiter DC.** Erstellen Sie den Forest und stufen Sie anschließend den zweiten Server als zusätzlichen Domain Controller herauf. Verwenden Sie Splatting und fragen Sie das DSRM-Kennwort interaktiv ab.

**Aufgabe 2.7** **Abnahme.** Führen Sie das Review-Skript aus Lerneinheit 2.9 aus (oder eine eigene Variante) und ergänzen Sie einen Prüfpunkt „Zeitquelle ist nicht Local CMOS Clock“ auf dem PDC-Emulator.

**Aufgabe 2.8** **RODC vorbereiten.** Legen Sie per Skript ein RODC-Konto `RODC-TEST01` für die Site `Filiale` an. Erlauben Sie die Replikation der Gruppe `Filiale-Benutzer` und verbieten Sie `Domain Admins`. Prüfen Sie die Listen mit `Get-ADDomainControllerPasswordReplicationPolicy`.

## 2.11 Lösungen zu den Übungsaufgaben

**Lösung 2.1.** Im ersten Schritt werden nur die Programmdateien und Dienste installiert (`Install-WindowsFeature AD-Domain-Services`). Die Trennung erlaubt es, Server vorab vorzubereiten, ohne bereits Entscheidungen über Domain, Forest oder Replikation zu treffen. Im zweiten Schritt, der Promotion (`Install-ADDSForest` oder `Install-ADDSDomainController`), wird der Server als Domain Controller konfiguriert, die Datenbank angelegt oder repliziert, DNS registriert und ein Neustart ausgeführt.

**Lösung 2.2.** Erstens: Welche DNS-Server hat der Client eingetragen (`Get-DnsClientServerAddress`)? Sie müssen auf Domain Controller zeigen, nicht auf Router oder öffentliche Resolver. Zweitens: Kann der Client die Domain und die SRV-Einträge auflösen (`Resolve-DnsName corp.contoso.com`, `Resolve-DnsName _ldap._tcp.dc._msdcs.corp.contoso.com -Type SRV`)? Drittens: Ist der Domain Controller erreichbar (Netzwerk, Firewall, `Test-NetConnection -Port 389`) und stimmt die Zeit? Die Reihenfolge folgt dem Prinzip „erst Namensauflösung, dann Erreichbarkeit, dann Authentifizierung“.

**Lösung 2.3.** Ein RODC speichert standardmäßig keine Kennwörter, nur die, die die Kennwortreplikationsrichtlinie in der Zulassungsliste erlaubt. Wird er gestohlen, sind nur die zwischengespeicherten Konten betroffen, deren Kennwörter sich gezielt zurücksetzen lassen. Die Ablehnungsliste stellt sicher, dass hochprivilegierte Konten niemals auf einem RODC landen. Je kleiner die Zulassungsliste, desto kleiner der mögliche Schaden.

**Lösung 2.4.**

```powershell
function Ausgabe($Text, $Ok) { "{0,-45} {1}" -f $Text, $(if ($Ok) { "OK" } else { "FEHLER" }) }

# 1) Statische IP: keine DHCP-aktive IPv4-Schnittstelle mit Gateway
$aktive = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway }
$dhcpAktiv = $false
foreach ($n in $aktive) {
    if ((Get-NetIPInterface -InterfaceIndex $n.InterfaceIndex -AddressFamily IPv4).Dhcp -eq "Enabled") { $dhcpAktiv = $true }
}
Ausgabe "Statische IP-Adresse (kein DHCP)" (-not $dhcpAktiv)

# 2) Computername
Ausgabe "Computername <= 15 Zeichen" ($env:COMPUTERNAME.Length -le 15)

# 3) Freier Platz auf dem Systemlaufwerk
$frei = (Get-Volume -DriveLetter $env:SystemDrive.TrimEnd(":")).SizeRemaining / 1GB
Ausgabe ("Mind. 20 GB frei auf {0} ({1:N1} GB)" -f $env:SystemDrive, $frei) ($frei -ge 20)
```

Die Funktion `Ausgabe` formatiert jede Zeile einheitlich. Die DHCP-Prüfung geht alle Adapter mit Standardgateway durch. Die Namenslänge ergibt sich aus `$env:COMPUTERNAME`. Für das Laufwerk wird der Doppelpunkt vom Systemlaufwerk abgeschnitten, weil `Get-Volume -DriveLetter` nur den Buchstaben erwartet.

**Lösung 2.5.**

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
$dsrm = Read-Host -AsSecureString "DSRM-Kennwort"
Test-ADDSForestInstallation -DomainName "lab.contoso.com" -DomainNetbiosName "LAB" `
    -InstallDns -SafeModeAdministratorPassword $dsrm
```

Typische Warnungen: Eine Meldung zur fehlenden Delegierung der DNS-Zone ist in einer isolierten Laborumgebung unkritisch, weil keine übergeordnete Zone existiert. Eine Warnung zu einer dynamischen IP-Adresse oder zu einem fehlenden statischen DNS-Eintrag sollte man dagegen beheben. Eine Warnung zu schwächeren Kryptografie-Einstellungen oder zum lokalen Administratorkennwort betrifft die Sicherheit und wird in Modul 9 aufgegriffen.

**Lösung 2.6.**

```powershell
# Auf Server 1
$dsrm = Read-Host -AsSecureString "DSRM-Kennwort"
$f = @{ DomainName="lab.contoso.com"; DomainNetbiosName="LAB"; InstallDns=$true
        ForestMode="WinThreshold"; DomainMode="WinThreshold"; SafeModeAdministratorPassword=$dsrm }
Test-ADDSForestInstallation @f
Install-ADDSForest @f -Force

# Auf Server 2 (DNS zeigt auf Server 1, Rolle installiert)
$cred = Get-Credential "LAB\Administrator"
$dsrm2 = Read-Host -AsSecureString "DSRM-Kennwort DC2"
$d = @{ DomainName="lab.contoso.com"; Credential=$cred; InstallDns=$true
        SafeModeAdministratorPassword=$dsrm2 }
Test-ADDSDomainControllerInstallation @d
Install-ADDSDomainController @d -Force
```

Beide Hashtables vermeiden Backticks. Nach den Neustarts prüft man mit `Get-ADDomainController -Filter *` und `repadmin /replsummary`.

**Lösung 2.7.** Der Erweiterungspunkt kann so aussehen:

```powershell
$pdc = (Get-ADDomain).PDCEmulator
if ($env:COMPUTERNAME -eq ($pdc -split "\.")[0]) {
    $quelle = (w32tm /query /source)
    Pruefe "Zeitquelle ist nicht Local CMOS Clock" ($quelle -notmatch "Local CMOS Clock") $quelle
}
```

Die Prüfung läuft nur auf dem PDC-Emulator, weil nur dieser (in der Forest-Root-Domain) eine externe Quelle haben soll. Andere Domain Controller beziehen die Zeit aus der Domain-Hierarchie. Die Zeitquelle liefert `w32tm /query /source`.

**Lösung 2.8.**

```powershell
Add-ADDSReadOnlyDomainControllerAccount -DomainControllerAccountName "RODC-TEST01" `
    -DomainName "lab.contoso.com" -SiteName "Filiale" `
    -AllowPasswordReplicationAccountName "Filiale-Benutzer" `
    -DenyPasswordReplicationAccountName "Domain Admins"

Get-ADDomainControllerPasswordReplicationPolicy -Identity "RODC-TEST01" -Allowed
Get-ADDomainControllerPasswordReplicationPolicy -Identity "RODC-TEST01" -Denied
```

Voraussetzung: Die Site `Filiale` und die Gruppe `Filiale-Benutzer` existieren bereits. Die Abfrage mit `-Allowed` und `-Denied` zeigt, ob die gewünschten Einträge gesetzt sind; zusätzlich enthält die Ablehnungsliste standardmäßig weitere sensible Gruppen.
