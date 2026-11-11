# Modul 05 - DNS, Sites, Subnetze und Replikation

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Tabellen als Markdown-Tabellen, Übungsaufgaben und Lösungen als Absätze). Die Überschriften sind wie in der Quelle nach Modul und Lerneinheit nummeriert (5.1 bis 5.9; 5.10 Übungsaufgaben, 5.11 Lösungen). **Die PowerShell-Beispiele wurden für dieses Repository nicht ausgeführt**; sie setzen eine Windows-Server-Laborumgebung mit der fiktiven Domain `corp.contoso.com` voraus und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain. Übersicht zum Modul: [README](README.md).

|                                       |              |
|:--------------------------------------|:-------------|
| Dauer laut Modulübersicht             | 12 Stunden   |
| Summe der Lerneinheiten (Detailblatt) | 10,5 Stunden |
| Priorität                             | 1            |

| Nr. | Lerneinheit                 | Dauer (h) | Prio |
|----:|:----------------------------|----------:|-----:|
| 5.1 | AD-integriertes DNS         |         1 |    1 |
| 5.2 | SRV Records                 |         1 |    1 |
| 5.3 | Forward und Reverse Zones   |       1,5 |    1 |
| 5.4 | Sites                       |         1 |    1 |
| 5.5 | Subnets                     |         1 |    1 |
| 5.6 | Site Links                  |       1,5 |    1 |
| 5.7 | Replikationstopologie       |         1 |    2 |
| 5.8 | KCC                         |         1 |    2 |
| 5.9 | Replication Troubleshooting |       1,5 |    2 |
|     | **Summe**                   |  **10,5** |      |

> **Merke**
>
> Die Stundensumme der Lerneinheiten im Detailblatt (10,5 h) weicht von der Dauer in der Modulübersicht (12 h) ab. Dieses Skript behandelt alle Lerneinheiten des Detailblatts vollständig; die Abweichung ist im Lehrplan selbst zu klären.

Active Directory funktioniert nur, wenn drei Dinge zusammenspielen: ein zuverlässiger Namensdienst (DNS), eine Beschreibung der Netzwerkstruktur (Sites und Subnetze) und eine funktionierende Replikation der Verzeichnisdaten zwischen den Domain Controllern. Diese drei Themen hängen eng zusammen. Ein Client findet seinen Domain Controller über DNS, der passende Domain Controller wird anhand der Site ausgewählt, und damit alle Domain Controller dieselben Daten kennen, müssen die Änderungen repliziert werden. Fällt eines der drei Glieder aus, äußert sich das fast immer gleich: Anmeldungen dauern lange, Gruppenrichtlinien werden nicht angewendet, Änderungen „kommen nicht an“. Dieses Modul erklärt deshalb zuerst die Grundlagen (DNS, Sites, Subnetze, Site Links) und anschließend den Betrieb (Replikationstopologie, KCC, Fehlersuche).

Die Beispiele verwenden die Laborumgebung aus der Einleitung. Für die Standortbeispiele wird zusätzlich ein zweiter Standort „Salzburg“ angenommen, der über eine WAN-Leitung mit dem Hauptstandort „Wien“ verbunden ist. Wien verwendet das Netz 10.10.0.0/16, Salzburg das Netz 10.20.0.0/16; beide Netze sind frei erfunden.

## 5.1 AD-integriertes DNS

Das *Domain Name System* (DNS) übersetzt Namen in Adressen. Active Directory verwendet DNS aber nicht nur dafür, sondern auch zur *Lokalisierung von Diensten*: Ein Client, der sich anmelden will, fragt DNS nicht nach „der Adresse von DC01“, sondern nach „irgendeinem Domain Controller für die Domain corp.contoso.com in meiner Site“. Ohne funktionierendes DNS gibt es deshalb keine Domain. Ein DNS-Server speichert seine Daten in *Zonen*; eine Zone ist der Teil des Namensraums, für den ein Server zuständig ist, zum Beispiel die Zone `corp.contoso.com`.

Klassisch liegt eine Zone in einer Textdatei auf einem *primären* Server und wird auf *sekundäre* Server kopiert (Zonentransfer). Bei einer *Active Directory-integrierten Zone* dagegen speichert der Domain Controller die Zone als Objekte im Verzeichnis selbst. Das hat drei große Vorteile. Erstens wird die Zone mit der normalen AD-Replikation verteilt, es ist kein eigener Zonentransfer nötig, und jeder DNS-Server mit der Zone kann Änderungen annehmen (Multimaster). Zweitens unterstützt die Zone *sichere dynamische Updates*: Clients und Server tragen ihre Einträge selbst ein, und nur der Ersteller eines Eintrags (authentifiziert über Kerberos) darf ihn später ändern. Drittens sind die Zonendaten durch Zugriffssteuerungslisten geschützt wie jedes andere AD-Objekt.

Wichtig für die Planung ist der *Replikationsbereich* (Replication Scope) der Zone, also die Frage, auf welche Domain Controller sich die Zone verteilt. Es gibt vier Möglichkeiten. Der Bereich *Forest* (alle DNS-Server im Forest) speichert die Zone in der Anwendungspartition `ForestDnsZones`, der Bereich *Domain* (alle DNS-Server in der Domain) in der Partition `DomainDnsZones`. Der Bereich *Legacy* (alle Domain Controller der Domain) legt die Zone in der Domain-Partition ab, damit auch sehr alte Domain Controller sie sehen; er wird nur noch aus Kompatibilitätsgründen verwendet. Und schließlich kann man eine *benutzerdefinierte Anwendungspartition* anlegen und beliebige DNS-Server als Replikationspartner eintragen. Für eine Domain wie `corp.contoso.com` ist *Domain* der übliche Bereich; die Zone `_msdcs` der Forest-Root-Domain wird im Bereich *Forest* repliziert, weil alle Domain Controller des Forests sie brauchen.

Dynamische Updates kann man auf drei Stufen einstellen: *Keine*, *Nicht sichere und sichere* (jeder darf eintragen, nicht empfohlen) oder *Nur sichere*. Bei AD-integrierten Zonen ist *Nur sichere* die richtige Wahl. Ein weiterer Aspekt ist das *Aging und Scavenging*: Dynamisch eingetragene Einträge bleiben stehen, auch wenn der Rechner längst verschwunden ist. Scavenging löscht veraltete Einträge, ist aber standardmäßig ausgeschaltet und muss bewusst aktiviert werden (Zone und Server), weil falsch eingestellte Intervalle gültige Einträge löschen können.

Das folgende Skript zeigt die wichtigsten Verwaltungsaufgaben mit dem PowerShell-Modul `DnsServer`: den Zustand der vorhandenen Zonen lesen, eine AD-integrierte Zone mit sicherem Update anlegen, den Replikationsbereich ändern, Aging und Scavenging einschalten und die Einträge eines Domain Controllers prüfen. Es wird auf einem Domain Controller mit DNS-Rolle ausgeführt.

```powershell
Import-Module DnsServer

# 1) Uebersicht: alle Zonen mit Typ, Replikationsbereich und Update-Modus
Get-DnsServerZone | Where-Object { -not $_.IsAutoCreated } |
    Select-Object ZoneName, ZoneType, IsDsIntegrated, ReplicationScope, DynamicUpdate |
    Format-Table -AutoSize

# 2) AD-integrierte Zone anlegen (nur sichere Updates, Replikation an alle DNS-Server der Domain)
Add-DnsServerPrimaryZone -Name "lab.contoso.com" -ReplicationScope Domain -DynamicUpdate Secure

# 3) Replikationsbereich nachtraeglich aendern (z. B. forestweit)
Set-DnsServerPrimaryZone -Name "lab.contoso.com" -ReplicationScope Forest

# 4) Aging und Scavenging: erst fuer die Zone, dann fuer den Server (alle 7 Tage)
Set-DnsServerZoneAging -Name "corp.contoso.com" -Aging $true -NoRefreshInterval 7.00:00:00 -RefreshInterval 7.00:00:00
Set-DnsServerScavenging -ScavengingState $true -ScavengingInterval 7.00:00:00

# 5) Eintraege eines Rechners pruefen und DNS-Registrierung neu anstossen
Get-DnsServerResourceRecord -ZoneName "corp.contoso.com" -Name "DC01"
Register-DnsClient          # auf dem betroffenen Rechner
```

Die Abfrage in Schritt 1 zeigt auf einen Blick, ob eine Zone AD-integriert ist und wie sie repliziert wird; automatisch angelegte Zonen (zum Beispiel die Stammzone) werden ausgeblendet. Schritt 2 legt eine neue Zone an. Der Parameter `-ReplicationScope` bestimmt den Verteilungsbereich, `-DynamicUpdate Secure` erlaubt nur authentifizierte Updates. Schritt 3 ändert den Bereich im Betrieb; die Daten werden dann in die andere Partition kopiert. Schritt 4 aktiviert das Aufräumen: Ein Eintrag wird erst nach dem *No-Refresh-* und dem *Refresh-Intervall* (hier je 7 Tage) als veraltet angesehen und beim nächsten Lauf des Scavengers (alle 7 Tage) entfernt. Schritt 5 zeigt, wie man den Eintrag eines Rechners kontrolliert und die Registrierung von der Clientseite wiederholt.

> **Ergänzung aus der Nachrecherche**
>
> Das Zusammenspiel von Zonen, Anwendungspartitionen und Delegationen ist umfangreich; die Aussagen in dieser Lerneinheit zu Replikationsbereichen und sicheren Updates entsprechen dem Fachwissen zu AD-integriertem DNS und wurden nicht einzeln gegen eine Seite der Microsoft-Dokumentation abgerufen. Die Seiten zur Replikation (Active Directory Replication Concepts) in der Quellenliste sind abgerufen und stützen die Ausführungen zu Sites und Topologie in den folgenden Lerneinheiten.

### Typische Fehler und Stolperfallen

Der häufigste Konfigurationsfehler ist, Clients und Domain Controller auf einen *externen* DNS-Server (zum Beispiel den des Providers oder 8.8.8.8) zu verweisen. Dieser Server kennt die internen SRV-Einträge nicht; die Domain wird nicht gefunden, die Anmeldung scheitert oder verzögert sich. Interne Clients müssen ausschließlich interne DNS-Server verwenden, und diese leiten Anfragen für externe Namen über *Weiterleitungen* (Forwarders) oder Root Hints weiter. Ein zweiter Fehler sind nicht sichere dynamische Updates: Jeder im Netz könnte dann Einträge anlegen oder überschreiben. Ein dritter Fehler ist das ungeprüfte Einschalten des Scavengings mit sehr kurzen Intervallen, wodurch Einträge von Rechnern verschwinden, die nur selten online sind.

```powershell
# FALSCH: Domain Controller und Clients zeigen auf einen oeffentlichen DNS-Server
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8

# RICHTIG: nur interne DNS-Server; externe Namen ueber Weiterleitung am DNS-Server
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 10.10.0.11,10.10.0.12
Add-DnsServerForwarder -IPAddress 1.1.1.1,9.9.9.9
```

### Praxisbezug

> **Praxisbeispiel**
>
> Nach dem Umzug in ein neues Rechenzentrum meldet die Hotline, dass sich Notebooks „irgendwann nach zwei Minuten“ anmelden. Die Analyse zeigt, dass die DHCP-Einstellungen zusätzlich zum internen DNS einen öffentlichen DNS-Server verteilen. Clients fragen abwechselnd beide Server, bekommen vom öffentlichen Server eine Absage und warten das Timeout ab. Nach dem Entfernen des öffentlichen Servers aus dem DHCP-Bereich und dem Einrichten einer Weiterleitung sind die Anmeldungen wieder schnell.

## 5.2 SRV Records

Ein *SRV-Record* (Service Record) ist ein DNS-Eintrag, der nicht auf einen Rechner, sondern auf einen *Dienst* zeigt. Er enthält den Dienstnamen, das Protokoll, den Zielhost, den Port sowie *Priorität* und *Gewicht*, mit denen sich mehrere Server für denselben Dienst steuern lassen. Active Directory legt beim Heraufstufen eines Domain Controllers automatisch eine große Zahl solcher Einträge an. Sie sorgen dafür, dass Clients Dienste wie LDAP, Kerberos, Kerberos-Kennwortänderung (`kpasswd`) und den Global Catalog finden, ohne feste Servernamen zu kennen.

Die Namen folgen einem festen Schema: `_dienst._protokoll.[_sites.Sitename.]_msdcs.Domainname`. Der wichtigste Eintrag ist `_ldap._tcp.dc._msdcs.corp.contoso.com`: Er listet alle Domain Controller der Domain. Für die standortbezogene Suche gibt es zusätzlich Einträge in der Form `_ldap._tcp.Wien._sites.dc._msdcs.corp.contoso.com`; damit findet ein Client in Wien zuerst die Domain Controller seiner eigenen Site. Der Dienst *Netlogon* auf jedem Domain Controller registriert diese Einträge beim Start und schreibt sie zusätzlich in die Datei `netlogon.dns` im Verzeichnis `%SystemRoot%\System32\Config`.

Der Ablauf einer Anmeldung zeigt, warum das so wichtig ist. Der Client ermittelt zunächst seine Site (aus seiner IP-Adresse und den Subnetzen, siehe Lerneinheit 5.5). Dann fragt er per DNS nach den SRV-Einträgen der Domain Controller seiner Site. Antwortet keiner, nimmt er die Einträge der gesamten Domain. Aus der Antwortliste wählt er mit Hilfe von Priorität und Gewicht einen Server und baut mit ihm die Verbindung auf. Ist ein Eintrag falsch oder fehlt er, scheitert dieser Ablauf an der ersten Stelle; die Fehlermeldungen sagen dann meist nur „Domäne nicht gefunden“.

Das folgende Skript zeigt, wie man die SRV-Einträge prüft und reparieren kann. Zuerst fragt es die wichtigsten Einträge ab, dann fordert es den Domain Controller auf, seine Einträge neu zu registrieren, und prüft anschließend mit `dcdiag` den DNS-Zustand. Die Abfragen funktionieren von jedem Mitgliedsrechner aus.

```powershell
$domain = "corp.contoso.com"

# 1) Alle Domain Controller der Domain (LDAP-SRV)
Resolve-DnsName -Type SRV -Name "_ldap._tcp.dc._msdcs.$domain" |
    Where-Object Type -eq SRV | Select-Object NameTarget, Port, Priority, Weight

# 2) Domain Controller der eigenen Site (Site-Name aus der Clientabfrage)
$site = (nltest /dsgetsite)[0]
Resolve-DnsName -Type SRV -Name "_ldap._tcp.$site._sites.dc._msdcs.$domain" -ErrorAction SilentlyContinue |
    Where-Object Type -eq SRV | Select-Object NameTarget, Port

# 3) Kerberos- und Global-Catalog-Eintraege
Resolve-DnsName -Type SRV -Name "_kerberos._tcp.dc._msdcs.$domain" | Where-Object Type -eq SRV | Select-Object NameTarget
Resolve-DnsName -Type SRV -Name "_gc._tcp.$domain"                 | Where-Object Type -eq SRV | Select-Object NameTarget

# 4) Auf dem Domain Controller: Eintraege neu registrieren und pruefen
nltest /dsregdns
ipconfig /registerdns
dcdiag /test:dns /v /s:DC01

# 5) Welchen DC findet dieser Client tatsaechlich?
nltest /dsgetdc:corp.contoso.com
Get-ADDomainController -Discover -Service ADWS
```

Schritt 1 fragt den wichtigsten SRV-Eintrag ab und zeigt für jeden Domain Controller Port, Priorität und Gewicht; es sollten alle Domain Controller der Domain erscheinen. In Schritt 2 wird die eigene Site mit `nltest /dsgetsite` ermittelt und derselbe Eintrag in der Site-Variante abgefragt. Schritt 3 prüft Kerberos und Global Catalog. In Schritt 4 sorgt `nltest /dsregdns` dafür, dass der Domain Controller die Einträge neu registriert; `dcdiag /test:dns` prüft DNS umfassend. Schritt 5 zeigt, welchen Domain Controller der Client tatsächlich wählt, und ist damit die Probe auf alle vorherigen Schritte.

### Typische Fehler und Stolperfallen

Ein typischer Fehler ist, fehlende SRV-Einträge von Hand nachzutragen, statt die Ursache zu beseitigen. Meist ist der Netlogon-Dienst gestört, der Domain Controller zeigt auf einen falschen DNS-Server, oder die Zone erlaubt keine dynamischen Updates. Ein manueller Eintrag verschwindet beim nächsten Fehler wieder oder verdeckt das Problem. Ein zweiter Fehler ist, einen Domain Controller wegen eines Hardwaredefekts ohne ordentliche Herabstufung zu entfernen: Seine SRV-Einträge bleiben stehen, Clients versuchen ihn weiterhin zu erreichen und warten auf Timeouts. Solche „Leichen“ müssen aus DNS und aus dem Verzeichnis entfernt werden (Metadatenbereinigung).

```powershell
# FALSCH: Einzelne SRV-Eintraege von Hand anlegen und weiter mit kaputtem Netlogon arbeiten
Add-DnsServerResourceRecord -Srv -ZoneName "corp.contoso.com" -Name "_ldap._tcp" `
    -DomainName "dc01.corp.contoso.com" -Port 389 -Priority 0 -Weight 100

# RICHTIG: Ursache pruefen (DNS-Server des DC, Zone, Netlogon) und neu registrieren
Get-DnsClientServerAddress -InterfaceAlias "Ethernet"
Restart-Service Netlogon
nltest /dsregdns
```

### Praxisbezug

> **Praxisbeispiel**
>
> Nach dem Ausfall von DC02 meldet die Service-Desk-Software sporadisch „Domäne nicht erreichbar“. Ursache: Der Server wurde abgeschaltet und nie ordentlich herabgestuft, seine SRV-Einträge existieren weiter. Etwa jeder zweite Client wählt zuerst den toten Server und läuft in ein Timeout. Das Team bereinigt die Metadaten, löscht die verwaisten DNS-Einträge und prüft die Antwortliste von `_ldap._tcp.dc._msdcs` mit dem Skript dieser Lerneinheit; danach sind die Meldungen verschwunden.

## 5.3 Forward und Reverse Zones

Eine *Forward-Lookupzone* beantwortet die Frage „Welche Adresse gehört zu diesem Namen?“, eine *Reverse-Lookupzone* die umgekehrte Frage „Welcher Name gehört zu dieser Adresse?“. Für die Funktion von Active Directory sind die Forward-Zonen entscheidend: Die Zone der Domain (`corp.contoso.com`) und die Zone `_msdcs.corp.contoso.com` enthalten alle Einträge, die Clients zum Finden der Domain Controller brauchen. Reverse-Zonen sind nicht zwingend, aber für viele Werkzeuge und Dienste wichtig: Protokolle und Diagnoseprogramme zeigen sonst nur Adressen statt Namen, manche Anwendungen und E-Mail-Systeme prüfen den Rückwärtseintrag, und Kerberos-basierte Zugriffe auf Basis von IP-Adressen können Probleme machen.

Reverse-Zonen heißen nach dem Netz, dessen Adressen sie auflösen, in umgekehrter Schreibweise mit der Endung `in-addr.arpa`. Das Netz 10.10.0.0/24 wird zur Zone `0.10.10.in-addr.arpa`; innerhalb der Zone steht dann ein *PTR-Record* (Pointer) mit dem letzten Oktett als Namen. Wichtig ist, dass jede Reverse-Zone einem tatsächlich verwendeten Subnetz entspricht. Bei größeren Netzen wählt man die Zone passend zum Netz (zum Beispiel /16 für 10.10.0.0/16). IPv6 verwendet entsprechend die Domain `ip6.arpa`.

Weitere Zonenarten ergänzen das Bild. Eine *Stub-Zone* enthält nur die Einträge, die man braucht, um die zuständigen Server einer anderen Zone zu finden; sie wird zum Beispiel bei Namensauflösung zwischen getrennten Forests verwendet. Eine *Bedingte Weiterleitung* (Conditional Forwarder) leitet Anfragen für einen bestimmten Namensraum an bestimmte Server weiter und ist die einfachere Lösung für die Zusammenarbeit mit einem Partnernetz. Der gewöhnliche *Forwarder* leitet alle übrigen Anfragen an einen externen oder übergeordneten Server weiter. Schließlich sorgt ein *DHCP-Server* dafür, dass bei Clients mit DHCP die PTR-Einträge zuverlässig angelegt werden (Option „DNS-Einträge dynamisch aktualisieren“).

Das folgende Skript legt eine Reverse-Zone für die Netze beider Standorte an, trägt einen PTR-Eintrag ein, richtet eine bedingte Weiterleitung auf einen Partner-Namensraum ein und prüft die Auflösung in beide Richtungen.

```powershell
Import-Module DnsServer

# 1) Reverse-Zonen fuer die Netze beider Standorte (AD-integriert, nur sichere Updates)
Add-DnsServerPrimaryZone -NetworkId "10.10.0.0/16" -ReplicationScope Domain -DynamicUpdate Secure
Add-DnsServerPrimaryZone -NetworkId "10.20.0.0/16" -ReplicationScope Domain -DynamicUpdate Secure

# 2) Statischen A-Record mit zugehoerigem PTR anlegen (-CreatePtr)
Add-DnsServerResourceRecordA -ZoneName "corp.contoso.com" -Name "srv02" -IPv4Address "10.10.0.21" -CreatePtr

# 3) Bedingte Weiterleitung auf den DNS-Server eines Partnerunternehmens (im Verzeichnis gespeichert)
Add-DnsServerConditionalForwarderZone -Name "partner.example" -MasterServers 192.0.2.53 -ReplicationScope Forest

# 4) Pruefen: Vorwaerts- und Rueckwaertsaufloesung
Resolve-DnsName srv02.corp.contoso.com -Type A
Resolve-DnsName 10.10.0.21 -Type PTR
Get-DnsServerZone | Select-Object ZoneName, ZoneType, IsReverseLookupZone, ReplicationScope
```

In Schritt 1 erzeugt `-NetworkId` den Zonennamen automatisch in der umgekehrten Schreibweise. Schritt 2 legt den A-Record an und mit `-CreatePtr` zugleich den PTR-Eintrag in der passenden Reverse-Zone; ohne passende Zone wäre dieser Schritt nicht möglich. Schritt 3 trägt die Weiterleitung ein; die Beispieladresse stammt aus dem für Dokumentation reservierten Bereich 192.0.2.0/24. Schritt 4 kontrolliert, ob beide Richtungen funktionieren, und gibt eine Zonenübersicht aus.

### Typische Fehler und Stolperfallen

Ein häufiger Fehler ist eine falsch benannte Reverse-Zone: Wer die Zone für das Netz 10.10.0.0/24 als `10.10.0.in-addr.arpa` anlegt (also nicht umgekehrt), erhält eine Zone, die nie abgefragt wird. Ein zweiter Fehler ist, dass die Reverse-Zonen nicht zu den tatsächlichen Subnetzen passen, etwa wenn eine Zone nur für ein /24 existiert, die Clients aber im Netz 10.10.1.x liegen: Dort entstehen keine PTR-Einträge. Ein dritter Fehler ist der Betrieb einer Zone mit veralteten statischen Einträgen, die nie bereinigt werden und zu falschen Auflösungen führen.

```powershell
# FALSCH: Zone nicht in umgekehrter Reihenfolge benannt
Add-DnsServerPrimaryZone -Name "10.10.0.in-addr.arpa" -ReplicationScope Domain

# RICHTIG: NetworkId verwenden, der Name wird korrekt gebildet (0.10.10.in-addr.arpa)
Add-DnsServerPrimaryZone -NetworkId "10.10.0.0/24" -ReplicationScope Domain
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Druckserver zeigt im Protokoll nur IP-Adressen, und die Sicherheitssoftware meldet „Rückwärtsauflösung fehlgeschlagen“. Der Administrator legt Reverse-Zonen für alle genutzten Netze an, aktiviert in DHCP die Aktualisierung der DNS-Einträge und prüft mit dem Skript dieser Lerneinheit, dass für jeden Domain Controller und Server ein PTR-Eintrag existiert. Die Fehlermeldungen entfallen, und die Protokolle werden lesbar.

## 5.4 Sites

Eine *Site* im Sinne von Active Directory ist eine Gruppe von IP-Subnetzen, die gut und schnell miteinander verbunden sind, typischerweise ein Standort mit lokalem Netz. Sites haben nichts mit Domains zu tun: Eine Domain kann sich über mehrere Sites erstrecken, und eine Site kann Domain Controller mehrerer Domains enthalten. Das Konzept erfüllt zwei Aufgaben. Erstens steuert es die *Client-DC-Zuordnung*: Ein Client soll sich möglichst an einem Domain Controller seiner eigenen Site anmelden, nicht über eine langsame WAN-Leitung. Zweitens steuert es die *Replikation*: Innerhalb einer Site wird schnell und unkomprimiert repliziert, zwischen Sites gebündelt, komprimiert und nach Zeitplan, damit die WAN-Leitung geschont wird.

Aus dieser Doppelrolle folgt, dass die Sites zur *realen Netzwerktopologie* passen müssen. Die Microsoft-Dokumentation beschreibt, dass Sites Objekte sind, die ein oder mehrere TCP/IP-Subnetze mit zuverlässigen, schnellen Verbindungen repräsentieren, dass jeder Domain Controller anhand seiner IP-Adresse einer Site zugeordnet wird und dass Sites Domain Controller mehrerer Domains enthalten können. Ein neu erstellter Forest hat bereits eine Site mit dem Namen „Default-First-Site-Name“. Kleine Umgebungen mit einem Standort kommen mit dieser einen Site aus; sobald es mehrere Standorte mit WAN-Verbindungen gibt, legt man für jeden eine eigene Site an und benennt die erste sinnvoll um.

Eine gute Site-Planung beginnt mit einer Liste der Standorte, ihrer Netze und der Verbindungen zwischen ihnen, einschließlich Bandbreite und Zuverlässigkeit. Pro Standort entscheidet man, ob dort ein Domain Controller stehen soll. Kleine Außenstellen mit schlechter Verbindung und wenig Personal erhalten oft einen Domain Controller mit nur lesendem Zugriff (RODC, siehe Modul 2) oder gar keinen: Die Clients dort melden sich dann über die WAN-Leitung am Hauptstandort an, und die Site stellt sicher, dass sie wenigstens den *nächstgelegenen* Domain Controller wählen („Next Closest Site“, siehe Lerneinheit 5.6).

Das folgende Skript legt die Sites des Beispielunternehmens an, benennt die Standardsite um und verschiebt einen Domain Controller in seine Site. Dies ist die Standardreihenfolge bei der Einrichtung eines weiteren Standorts: Site anlegen, Subnetz anlegen, Domain Controller dorthin verschieben.

```powershell
Import-Module ActiveDirectory

# 1) Standardsite umbenennen, zweite Site anlegen
Get-ADReplicationSite -Filter * | Select-Object Name, Description
Rename-ADObject -Identity (Get-ADReplicationSite "Default-First-Site-Name").DistinguishedName -NewName "Wien"
New-ADReplicationSite -Name "Salzburg" -Description "Aussenstelle Salzburg (WAN 100 Mbit/s)"

# 2) Domain Controller in die richtige Site verschieben (DC02 steht in Salzburg)
Move-ADDirectoryServer -Identity "DC02" -Site "Salzburg"

# 3) Kontrolle: welcher DC liegt in welcher Site?
Get-ADDomainController -Filter * | Select-Object Name, Site, IPv4Address | Sort-Object Site

# 4) Auf einem Client: Zu welcher Site gehoert dieser Rechner?
nltest /dsgetsite
```

Schritt 1 listet die vorhandenen Sites und benennt die Standardsite um; `Rename-ADObject` ist notwendig, weil es kein eigenes Umbenennungs-Cmdlet gibt. Anschließend legt `New-ADReplicationSite` die Site Salzburg an. In Schritt 2 wird DC02, der physisch in Salzburg steht, in die neue Site verschoben; ohne diesen Schritt bliebe er in der Site Wien, weil neue Domain Controller zunächst anhand ihrer IP-Adresse eingeordnet werden, sofern ein passendes Subnetz existiert, sonst in der Standardsite. Schritt 3 zeigt die Zuordnung, und Schritt 4 prüft sie aus der Sicht eines Clients.

### Typische Fehler und Stolperfallen

Der klassische Fehler ist, bei mehreren Standorten alles in der Standardsite zu belassen. Dann kennt Active Directory keinen Unterschied zwischen „lokal“ und „WAN“ und verteilt Anmeldungen und Replikation ohne Rücksicht auf die Leitung. Ein zweiter Fehler ist, eine Site zu früh anzulegen, bevor das passende Subnetz existiert: Der neue Domain Controller wird dann in die falsche Site einsortiert, und die Replikation läuft über die falsche Strecke. Ein dritter Fehler ist es, Sites nach Abteilungen oder Domains statt nach der Netzwerktopologie zu schneiden.

```powershell
# FALSCH: Zweiten Standort in Betrieb nehmen, aber alle Server bleiben in der Standardsite
Install-ADDSDomainController -DomainName corp.contoso.com -InstallDns -Credential (Get-Credential)

# RICHTIG: Reihenfolge einhalten: Site -> Subnetz -> Domain Controller
New-ADReplicationSite -Name "Salzburg"
New-ADReplicationSubnet -Name "10.20.0.0/16" -Site "Salzburg"
Install-ADDSDomainController -DomainName corp.contoso.com -InstallDns -SiteName "Salzburg" -Credential (Get-Credential)
```

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Firma eröffnet eine Niederlassung in Salzburg und stellt dort einen Domain Controller auf. Ohne Site-Konfiguration melden sich die Wiener Clients zum Teil über die WAN-Leitung in Salzburg an, weil beide Domain Controller derselben Site angehören; die Anmeldungen in Wien dauern zeitweise Minuten. Nach dem Anlegen der zwei Sites und der Subnetze und dem Verschieben von DC02 melden sich Wiener Clients wieder in Wien an, und die Replikation zwischen den Standorten läuft gebündelt nach Zeitplan.

## 5.5 Subnets

Ein *Subnetz*-Objekt im Verzeichnis ordnet einen IP-Adressbereich (in der Schreibweise CIDR, zum Beispiel `10.20.0.0/16`) einer Site zu. Dadurch kann Active Directory aus der IP-Adresse eines Clients ableiten, in welcher Site er sich befindet. Das ist die Grundlage für alle standortbezogenen Entscheidungen: Wenn ein Client sich anmeldet, schickt der Domain Controller bei der Antwort den Namen der Site des Clients mit, und der Client verwendet ihn für die Suche nach dem nächsten Domain Controller und speichert ihn zwischen. Auch Domain Controller selbst werden bei der Heraufstufung anhand ihrer Adresse einer Site zugeordnet.

Subnetze sollten die tatsächliche Adressplanung vollständig und genau abbilden. Vollständig bedeutet, dass jede im Unternehmen genutzte Client-Adresse in einem Subnetz-Objekt liegt, auch die der VPN-Pools, WLANs und Testnetze. Wenn ein Client in keinem Subnetz liegt, kann der Domain Controller die Site nicht bestimmen, und der Client wird irgendeinem Domain Controller zugewiesen, möglicherweise in einem anderen Land. Der Domain Controller meldet solche Fälle in seinem Systemprotokoll (Netlogon-Ereignis 5807, „Clients ohne passendes Subnetz“) und schreibt die Namen und Adressen der betroffenen Clients in das Netlogon-Protokoll `%SystemRoot%\debug\netlogon.log` (Kennung `NO_CLIENT_SITE`); diese Auswertung ist die Arbeitsgrundlage, um fehlende Subnetze zu ergänzen.

Genau bedeutet, dass die Subnetz-Objekte möglichst nicht größer sind als nötig. Ist ein größeres Subnetz (zum Beispiel 10.0.0.0/8) einer Site zugeordnet und ein kleineres darin (10.20.0.0/16) einer anderen, gewinnt immer das *genauere* (längere Präfix). Dieses Verhalten kann man bewusst nutzen: Man ordnet ein großes Sammelsubnetz der Zentrale zu und trägt nur die Ausnahmen für die Außenstellen ein. Ein Subnetz darf genau einer Site zugeordnet sein, aber eine Site kann beliebig viele Subnetze haben.

Das folgende Skript pflegt die Subnetze für das Beispielunternehmen, zeigt die Zuordnung an und wertet die Clients ohne passendes Subnetz aus. Es verwendet das Cmdlet `New-ADReplicationSubnet` und liest das Netlogon-Protokoll eines Domain Controllers.

```powershell
Import-Module ActiveDirectory

# 1) Subnetze anlegen (CIDR-Schreibweise) und der Site zuordnen
New-ADReplicationSubnet -Name "10.10.0.0/16"    -Site "Wien"     -Description "LAN Wien"
New-ADReplicationSubnet -Name "10.20.0.0/16"    -Site "Salzburg" -Description "LAN Salzburg"
New-ADReplicationSubnet -Name "10.99.0.0/24"    -Site "Wien"     -Description "VPN-Pool (Anbindung ueber Wien)"

# 2) Bestehende Subnetze ausgeben
Get-ADReplicationSubnet -Filter * | Select-Object Name, Site, Description | Sort-Object Name

# 3) Subnetz einer anderen Site zuordnen (Umzug eines Netzes)
Set-ADReplicationSubnet -Identity "10.99.0.0/24" -Site "Salzburg"

# 4) Auf dem DC: Clients, die in kein Subnetz passen, aus dem Netlogon-Protokoll lesen
Get-Content "C:\Windows\debug\netlogon.log" -ErrorAction SilentlyContinue |
    Select-String "NO_CLIENT_SITE" | Select-Object -Last 20

# 5) Aus Clientsicht: nur die Site ermitteln
nltest /dsgetsite
```

Die ersten drei Anweisungen legen drei Subnetze an, darunter einen VPN-Adresspool als eigenes, kleines Subnetz. Schritt 2 prüft die Liste, Schritt 3 zeigt, wie ein Subnetz einer anderen Site zugeordnet wird. Schritt 4 sucht im Netlogon-Protokoll nach Einträgen, die einen Client ohne Site melden; damit findet man fehlende Subnetze systematisch. Schritt 5 prüft die Site eines einzelnen Clients.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist ein vergessenes Subnetz, etwa beim Hinzufügen eines neuen VLANs, eines WLAN-Gästenetzes oder eines VPN-Pools. Die Folge sind langsame Anmeldungen und zufällige Domain-Controller-Zuordnung. Ein zweiter Fehler ist eine zu grobe Zuordnung: Wer nur ein riesiges Subnetz der Zentrale zuordnet und die Außenstellen nicht eigens einträgt, hat im Zweifel Außenstellen-Clients, die über das WAN zur Zentrale authentifizieren. Ein dritter Fehler ist die Änderung der IP-Planung ohne Anpassung des Verzeichnisses; die Netzwerkabteilung und das AD-Team müssen hier zusammenarbeiten.

```powershell
# FALSCH: Ein Sammelnetz fuer alles, Aussenstellen fehlen
New-ADReplicationSubnet -Name "10.0.0.0/8" -Site "Wien"

# RICHTIG: Sammelnetz als Auffangnetz, dazu die genaueren Netze der Aussenstellen
New-ADReplicationSubnet -Name "10.0.0.0/8"   -Site "Wien"
New-ADReplicationSubnet -Name "10.20.0.0/16" -Site "Salzburg"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Nach der Einführung eines neuen WLAN-Netzes für Besucher und Mitarbeiter-Handys häufen sich Meldungen, dass die Anmeldung im WLAN lange dauert. Die Auswertung des Netlogon-Protokolls zeigt Hunderte Clients ohne Subnetz-Zuordnung aus dem Bereich 172.16.0.0/20. Das Team legt das Subnetz an, ordnet es der Site Wien zu und dokumentiert das Verfahren, damit künftig jedes neue Netz auf der Checkliste der Netzwerkabteilung auch einen Eintrag im Active Directory verlangt.

## 5.6 Site Links

Sites und Subnetze beschreiben, *wo* Rechner stehen. Wie die Standorte miteinander verbunden sind, beschreiben die *Site Links*. Ein Site Link ist ein Objekt im Verzeichnis, das eine Menge von Sites mit einheitlichen Kosten über einen gemeinsamen Transport verbindet. Die Microsoft-Dokumentation hält ausdrücklich fest, dass Sites manuell durch Site Links verbunden werden müssen, damit Domain Controller verschiedener Sites miteinander replizieren; ohne Site Link gibt es keine Replikation zwischen den Sites. Ein Site Link entspricht außerdem nicht dem tatsächlichen Weg der Pakete im Netzwerk, sondern ist ein logisches Modell. Deshalb ist es nicht nötig, für mehr Replikationsleistung zusätzliche Links anzulegen.

Jeder Site Link hat drei Eigenschaften, die das Replikationsverhalten steuern. Die *Kosten* (Cost) sind eine Zahl, mit der der Knowledge Consistency Checker (siehe Lerneinheit 5.8) den günstigsten Weg zwischen zwei Sites bestimmt; niedrigere Kosten bedeuten einen bevorzugten Weg. Die Microsoft-Dokumentation enthält dazu eine Tabelle, die Bandbreiten in Kosten umrechnet: Je schneller die Verbindung, desto kleiner die Kosten (zum Beispiel 4.096 kbit/s entspricht Kosten von 283, 512 kbit/s Kosten von 378). Der Standardwert eines neuen Links ist 100. Wichtig ist nicht der absolute Wert, sondern das *Verhältnis* der Kosten verschiedener Wege: Der KCC addiert die Kosten der Links entlang eines Weges. Das *Intervall* (Replication Interval) legt fest, wie oft innerhalb des erlaubten Zeitfensters repliziert wird; der Standard ist 180 Minuten, das Minimum 15 Minuten. Der *Zeitplan* (Schedule) definiert, zu welchen Zeiten die Replikation überhaupt stattfinden darf; standardmäßig ist er rund um die Uhr geöffnet.

Mehrere Site Links lassen sich verketten. Standardmäßig sind alle Site Links *transitiv* („Bridge all site links“ ist aktiv): Wenn Wien mit Salzburg und Salzburg mit Graz verbunden ist, darf der KCC auch eine Verbindung von Wien nach Graz konstruieren, deren Kosten die Summe der beiden Links sind. Die Dokumentation empfiehlt, diese Einstellung nur zu ändern, wenn das Netzwerk nicht vollständig geroutet ist oder wenn der Replikationsfluss gezielt gesteuert werden soll; dann deaktiviert man die automatische Überbrückung und legt *Site Link Bridges* an, die genau die zusammengehörenden Links zusammenfassen. In den meisten Umgebungen sind Bridges nicht nötig.

Für den praktischen Entwurf haben sich zwei Topologien bewährt. Bei der *Hub-and-Spoke-Topologie* laufen alle Außenstellen (Spokes) über eine Zentrale (Hub); jede Außenstelle erhält einen Site Link zum Hub. Das passt zu den meisten Firmennetzen mit zentralem Rechenzentrum. Bei einem *Ring* oder *Mesh* sind die Standorte untereinander verbunden; hier müssen die Kosten so gewählt werden, dass der gewünschte Weg bevorzugt wird. Außerdem hilft die Gruppenrichtlinie „Try Next Closest Site“ (im Zweig *Netlogon*, *DC Locator DNS Records* der administrativen Vorlagen): Wenn in der eigenen Site kein Domain Controller erreichbar ist, wählt der Client dann den Domain Controller der nächsten Site nach den Link-Kosten, statt irgendeinen zufälligen Server der Domain.

Das folgende Skript baut für das Beispielunternehmen eine Hub-and-Spoke-Topologie mit einer dritten Site Graz auf, setzt Kosten und Intervall, zeigt die Links an und aktiviert für einen Link die Änderungsbenachrichtigung.

```powershell
Import-Module ActiveDirectory

# 1) Dritte Site und Subnetz
New-ADReplicationSite -Name "Graz"
New-ADReplicationSubnet -Name "10.30.0.0/16" -Site "Graz"

# 2) Site Links: Hub = Wien; Salzburg schnell (Kosten 100, alle 15 min), Graz langsam (Kosten 300, alle 60 min)
New-ADReplicationSiteLink -Name "Wien-Salzburg" -SitesIncluded "Wien","Salzburg" `
    -Cost 100 -ReplicationFrequencyInMinutes 15 -InterSiteTransportProtocol IP
New-ADReplicationSiteLink -Name "Wien-Graz" -SitesIncluded "Wien","Graz" `
    -Cost 300 -ReplicationFrequencyInMinutes 60 -InterSiteTransportProtocol IP

# 3) Den Standard-Link DEFAULTIPSITELINK nicht mehr benutzen: erst Sites entfernen, dann Link loeschen
Get-ADReplicationSiteLink -Filter * | Select-Object Name, Cost, ReplicationFrequencyInMinutes, SitesIncluded
Set-ADReplicationSiteLink -Identity "DEFAULTIPSITELINK" -SitesIncluded @{Remove="Wien","Salzburg","Graz"} -ErrorAction SilentlyContinue

# 4) Aenderungsbenachrichtigung zwischen Wien und Salzburg einschalten (Bit 1 im Attribut options)
$dn = (Get-ADReplicationSiteLink "Wien-Salzburg").DistinguishedName
Set-ADObject -Identity $dn -Replace @{ options = ((Get-ADObject $dn -Properties options).options -bor 1) }

# 5) Kosten pruefen: welcher Weg gilt zwischen den Sites? (nur auf dem DC mit ISTG-Rolle)
repadmin /showism
```

Schritt 1 legt die Site und das Subnetz an. In Schritt 2 entstehen zwei Site Links: Der Link zum Hub Salzburg hat niedrige Kosten und ein kurzes Intervall, der Link nach Graz höhere Kosten und ein längeres Intervall, weil die Leitung langsamer ist. Schritt 3 zeigt die Links an und entfernt die Sites aus dem Standard-Link, der von Anfang an alle Sites enthält und sonst die gewünschten Kosten umgeht; dass der Befehl mit `-ErrorAction SilentlyContinue` läuft, liegt daran, dass der Link in manchen Umgebungen bereits geändert wurde. Schritt 4 setzt das erste Bit im Attribut `options`, wodurch die Domain Controller beider Sites Änderungen sofort melden (Change Notification), statt auf das Intervall zu warten. Schritt 5 zeigt die Kostenmatrix aus Sicht des KCC; sie besteht aus Kosten, Intervall und Optionen je Standortpaar.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist der unveränderte Standard-Link `DEFAULTIPSITELINK`, der alle neuen Sites mit Kosten 100 enthält. Dadurch sind scheinbar alle Standorte gleich weit voneinander entfernt, der KCC verbindet die Spokes untereinander, und die WAN-Leitungen der Außenstellen müssen Datenverkehr tragen, für den sie nicht gedacht sind. Ein zweiter Fehler sind zu aggressive Intervalle: Wer das Intervall überall auf 15 Minuten stellt, erzeugt auf schwachen Leitungen unnötig Last. Ein dritter Fehler ist eine Site, die in keinem Site Link steht; die Microsoft-Dokumentation beschreibt, dass solche Sites vom KCC nicht berücksichtigt werden und das Ereignis 1311 auslösen.

```powershell
# FALSCH: Alle Sites im Standard-Link, Kosten 100 -> jede Site ist "gleich nah"
Get-ADReplicationSiteLink DEFAULTIPSITELINK | Select-Object SitesIncluded, Cost

# RICHTIG: Pro WAN-Strecke ein eigener Link mit Kosten passend zur Bandbreite
New-ADReplicationSiteLink -Name "Wien-Salzburg" -SitesIncluded Wien,Salzburg -Cost 100 -ReplicationFrequencyInMinutes 15
New-ADReplicationSiteLink -Name "Wien-Graz"     -SitesIncluded Wien,Graz     -Cost 300 -ReplicationFrequencyInMinutes 60
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen mit zehn Filialen und einem zentralen Rechenzentrum stellt fest, dass die schwachen Leitungen der Filialen abends durch Replikationsverkehr stark belastet sind. Ursache: Alle Sites liegen im Standard-Site-Link, und die Filial-Domain-Controller replizieren auch untereinander. Das Team ersetzt den Standard-Link durch zehn Hub-and-Spoke-Links (Kosten nach Bandbreite) und lässt die Filialen nur noch mit dem Rechenzentrum replizieren. Die Last der Leitungen sinkt sichtbar.

## 5.7 Replikationstopologie

Active Directory verwendet *Multimaster-Replikation*: Jeder schreibbare Domain Controller darf Änderungen annehmen und gibt sie an die anderen weiter. Damit das ohne Chaos funktioniert, speichert jeder Domain Controller zu jeder Änderung eine *Update Sequence Number* (USN) und merkt sich, welche USN er von welchem Partner zuletzt erhalten hat. Bei der Replikation fragt ein Domain Controller seinen Partner: „Was hast du seit USN x geändert?“ und bekommt nur diese Änderungen. Gleichzeitige Änderungen am selben Attribut werden nach einer festen Regel aufgelöst (die Änderung mit der höheren Versionsnummer, dann dem späteren Zeitstempel, dann der größeren Invocation-ID gewinnt). Deshalb müssen die Uhren der Domain Controller stimmen (Lerneinheit 6.9).

Welche Verzeichnisdaten werden repliziert? Das Verzeichnis ist in *Partitionen* (Naming Contexts) aufgeteilt: Die *Schema-* und die *Konfigurationspartition* sind forestweit identisch auf allen Domain Controllern; die *Domänenpartition* gilt nur innerhalb einer Domain; die *Anwendungspartitionen* (zum Beispiel für DNS) haben ihren eigenen Replikationsbereich; und der *Global Catalog* enthält zusätzlich eine unvollständige Kopie fremder Domänenpartitionen (Lerneinheit 6.7).

Die Replikation läuft *innerhalb einer Site* anders als *zwischen Sites*. Innerhalb einer Site verbindet der KCC alle schreibbaren Domain Controller zu einem bidirektionalen Ring, der bei Bedarf um Abkürzungsverbindungen ergänzt wird, damit zwischen zwei Domain Controllern höchstens drei Teilstrecken liegen. Änderungen werden hier *sofort* gemeldet (Change Notification, nach einer kurzen Verzögerung von etwa 15 Sekunden), unkomprimiert übertragen, und zusätzlich gibt es eine regelmäßige Abfrage als Sicherheitsnetz. Zwischen Sites wird dagegen nur im erlaubten Zeitfenster im konfigurierten Intervall repliziert (Standard alle 180 Minuten), die Daten werden komprimiert, und die Domain Controller, die die Verbindung tragen, heißen *Bridgehead-Server*. Die Microsoft-Dokumentation beschreibt, dass in einer Site alle Domain Controller mit der betreffenden Partition als Bridgehead-Kandidaten infrage kommen und die Verbindungen zufällig auf sie verteilt werden. Die Topologie zwischen Sites besteht aus einem *aufspannenden Baum* je Partition, es gibt also zwischen zwei Sites normalerweise nur eine Verbindung pro Partition.

Aus diesen Regeln folgt die *Replikationslatenz*, also die Zeit, bis eine Änderung überall angekommen ist. Innerhalb einer Site liegt sie im Bereich von Sekunden bis Minuten (die Microsoft-Dokumentation rechnet im Worst Case mit 15 Minuten); zwischen Sites addiert sie sich aus den Intervallen entlang der Strecke. Bei einem Hub-and-Spoke mit 180 Minuten pro Link kann eine Änderung von einer Außenstelle zu einer anderen im ungünstigsten Fall mehrere Stunden brauchen. Das ist für die meisten Änderungen akzeptabel, nicht aber für sicherheitskritische, wie das Sperren eines Kontos. Dafür gibt es *dringende Replikation*: Bestimmte Änderungen (Kontensperrung durch Lockout, Änderung des Kennworts durch Administratoren an den PDC-Emulator, Änderung einer RID-Zuweisung) werden sofort verteilt, ohne auf das Intervall zu warten.

Das folgende Skript macht die Topologie sichtbar. Es listet die Partner jedes Domain Controllers, die Zeitpunkte der letzten erfolgreichen Replikation und die Ausfälle, wertet die Verbindungsobjekte aus und zeigt, welche Domain Controller als Bridgehead-Server dienen.

```powershell
Import-Module ActiveDirectory

# 1) Replikationspartner und Zeitpunkt der letzten erfolgreichen Replikation
Get-ADReplicationPartnerMetadata -Target * -Scope Server |
    Select-Object Server, Partner, Partition, LastReplicationSuccess, LastReplicationResult |
    Sort-Object LastReplicationSuccess | Format-Table -AutoSize

# 2) Verbindungsobjekte (die vom KCC erzeugten oder manuellen Verbindungen)
Get-ADObject -SearchBase (Get-ADRootDSE).configurationNamingContext -Filter 'objectClass -eq "nTDSConnection"' `
    -Properties fromServer, options, enabledConnection |
    Select-Object @{n="Ziel";e={($_.DistinguishedName -split ",")[3]}}, fromServer, enabledConnection

# 3) Zusammenfassung ueber alle DCs und die Bridgehead-Server
repadmin /replsummary
repadmin /bridgeheads

# 4) Aenderung bewusst erzeugen und Verteilung messen
Set-ADUser -Identity "a.muster" -Description "Replikationstest $(Get-Date -Format s)"
repadmin /syncall DC01 /AdeP        # alle Partner, alle Partitionen, ueber Sites hinweg
Get-ADUser "a.muster" -Server DC02 -Properties Description | Select-Object Description
```

Schritt 1 gibt für jeden Partner und jede Partition die Zeit des letzten erfolgreichen Abgleichs und den Ergebniscode aus; ein Ergebnis von 0 bedeutet Erfolg. Schritt 2 liest die Verbindungsobjekte direkt aus der Konfigurationspartition: Jedes Objekt steht für eine eingehende Verbindung und nennt den Quellserver. Schritt 3 liefert die Zusammenfassung mit den größten Verzögerungen und eine Liste der Bridgehead-Server. Schritt 4 erzeugt eine Änderung, stößt die Replikation an und liest den Wert vom anderen Domain Controller; so prüft man die Replikation praktisch von Ende zu Ende.

### Typische Fehler und Stolperfallen

Ein häufiger Irrtum ist, nach einer Änderung auf einem Domain Controller sofort das Ergebnis auf einem anderen zu erwarten, besonders über WAN-Grenzen. Wer in einer Außenstelle ein Konto anlegt und es in der Zentrale sofort sucht, findet es möglicherweise nicht. Ein zweiter Fehler ist es, einen einzelnen Bridgehead-Server durch zu viele Außenstellen zu überlasten oder ihn manuell als einzigen zuzulassen, ohne an den Ausfall zu denken. Ein dritter Fehler ist eine Replikationstopologie, die sich über Jahre unbemerkt verschlechtert hat, weil niemand die Replikation überwacht.

```powershell
# FALSCH: Nach einer Aenderung nur auf dem lokalen DC pruefen und "fertig" sagen
New-ADUser -Name "Test Replikation" -SamAccountName t.repl

# RICHTIG: Replikation anstossen und auf dem entfernten DC ueberpruefen
repadmin /syncall DC01 /AdeP
Get-ADUser -Identity t.repl -Server DC02
```

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Helpdesk-Mitarbeiterin legt in der Filiale Salzburg ein Konto an, und der neue Mitarbeiter in Wien kann sich zwei Stunden lang nicht anmelden. Die Ursache ist kein Fehler, sondern die Latenz: Das Intervall des Site Links beträgt 120 Minuten. Das Team ändert den Prozess: Neue Konten werden an einem Domain Controller der Zentrale angelegt, und die Hotline kennt die Wartezeiten. Für dringende Fälle starten sie die Replikation per `repadmin /syncall`.

## 5.8 KCC

Der *Knowledge Consistency Checker* (KCC) ist ein Dienst auf jedem Domain Controller, der die Replikationstopologie automatisch erzeugt und laufend anpasst. Die Microsoft-Dokumentation beschreibt ihn als eingebauten Prozess, der auf allen Domain Controllern läuft und die Replikationstopologie des Forests erzeugt; er legt getrennte Topologien für die Replikation innerhalb von Sites und zwischen Sites an und passt sie dynamisch an, wenn Domain Controller hinzukommen, entfernt oder verschoben werden, wenn sich Kosten und Zeitpläne ändern oder wenn Domain Controller vorübergehend ausfallen. Er arbeitet mit *Verbindungsobjekten* (Connection Objects): Das sind eingehende, einseitige Replikationsverbindungen, die die Quelle einer Replikation festlegen.

In jeder Site gibt es genau einen Domain Controller mit der Rolle *Intersite Topology Generator* (ISTG). Er berechnet auf Basis der Site Links und ihrer Kosten die Verbindungen *zwischen* den Sites, während der KCC jedes einzelnen Domain Controllers die Verbindungen *innerhalb* seiner Site pflegt. Der KCC läuft in regelmäßigen Abständen (standardmäßig alle 15 Minuten) und wird außerdem bei bestimmten Änderungen ausgelöst; fällt der ISTG aus, wird nach einiger Zeit automatisch ein anderer Domain Controller der Site zum ISTG gewählt.

Als Grundsatz gilt: *Der KCC macht seine Arbeit besser als jeder Mensch.* Manuell angelegte Verbindungsobjekte sind selten nötig, werden vom KCC nicht gelöscht, wenn sie gültig sind, und sorgen dafür, dass die Topologie bei Änderungen nicht mehr automatisch angepasst wird. In der Praxis sind manuelle Eingriffe nur in Ausnahmefällen begründet, etwa bei besonders restriktiven Firewalls, die nur bestimmte Domain-Controller-Paare zulassen, oder zum zeitweisen Testen. Wo ein Eingriff nötig ist, wird er dokumentiert (wer, wann, warum, wann wird er zurückgenommen).

Das folgende Skript zeigt, wie man den KCC kontrolliert: Es ermittelt den ISTG jeder Site, startet eine Neuberechnung der Topologie, liest die KCC-Ereignisse aus dem Verzeichnisdienst-Protokoll und zeigt manuell angelegte Verbindungen (solche, die nicht vom KCC erzeugt wurden) an.

```powershell
Import-Module ActiveDirectory

# 1) Welcher DC ist je Site der ISTG?
Get-ADReplicationSite -Filter * -Properties InterSiteTopologyGenerator |
    Select-Object Name, InterSiteTopologyGenerator

# 2) Topologie neu berechnen lassen (auf allen DCs)
repadmin /kcc *

# 3) KCC-Ereignisse der letzten 24 Stunden (Verzeichnisdienst-Protokoll, Quelle NTDS KCC)
Get-WinEvent -FilterHashtable @{ LogName="Directory Service"; ProviderName="Microsoft-Windows-ActiveDirectory_DomainService"; StartTime=(Get-Date).AddHours(-24) } |
    Where-Object { $_.Id -in 1311, 1865, 1566, 1925 } |
    Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-List

# 4) Manuell angelegte Verbindungen suchen (nicht vom KCC: Option "IsGenerated" = Bit 0 fehlt)
Get-ADObject -SearchBase (Get-ADRootDSE).configurationNamingContext -Filter 'objectClass -eq "nTDSConnection"' -Properties options, fromServer |
    Where-Object { ($_.options -band 1) -eq 0 } | Select-Object DistinguishedName, fromServer
```

Schritt 1 liest die Site-Eigenschaft `InterSiteTopologyGenerator` und zeigt, welcher Domain Controller die Topologie zwischen den Sites berechnet. Schritt 2 stößt auf allen Domain Controllern eine Neuberechnung an; das ist nützlich, nachdem man Sites, Links oder Kosten geändert hat und nicht auf die 15 Minuten warten will. Schritt 3 sucht nach den wichtigsten KCC-Ereignissen (zum Beispiel 1311: die Topologie ist nicht vollständig, 1865: Sites sind nicht verbunden, 1566 und 1925: Verbindungsprobleme). Schritt 4 findet Verbindungen, die nicht automatisch erzeugt wurden: Im Attribut `options` markiert Bit 0 (Wert 1) eine automatisch erstellte Verbindung.

> **Ergänzung aus der Nachrecherche**
>
> Die Ereignis-IDs und das Bit 0 im Attribut `options` stammen aus dem Fachwissen zur AD-Replikation und sollten vor der Verwendung in produktiven Überwachungsskripten gegen die aktuelle Dokumentation geprüft werden. Zu Ereignis 1311 beschreibt die abgerufene Microsoft-Seite „How to troubleshoot Event ID 1311 messages on a Windows domain“ den Fall nicht verbundener Sites und das Werkzeug `repadmin /showism`.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, den KCC „zu verbessern“: Wer Verbindungsobjekte von Hand anlegt, weil die automatisch erzeugte Topologie „nicht gefällt“, vergisst sie meist, und sie bleiben auch dann bestehen, wenn sich das Netzwerk ändert; der KCC repariert sie nicht und kann sie deshalb nicht umgehen. Der zweite Fehler ist, KCC-Ereignisse nicht auszuwerten. Der dritte ist die Annahme, die Replikation sei in Ordnung, weil keine Fehler im Protokoll stehen; ein deaktivierter KCC oder ein toter ISTG erzeugt gerade keine neuen Verbindungen und damit auch keine Fehler.

```powershell
# FALSCH: Verbindung von Hand anlegen, weil "es sonst nicht schnell genug repliziert"
New-ADObject -Name "Manuell DC02" -Type nTDSConnection -Path "CN=NTDS Settings,CN=DC01,CN=Servers,CN=Wien,CN=Sites,CN=Configuration,DC=corp,DC=contoso,DC=com" `
    -OtherAttributes @{ fromServer="CN=NTDS Settings,CN=DC02,CN=Servers,CN=Salzburg,CN=Sites,CN=Configuration,DC=corp,DC=contoso,DC=com" }

# RICHTIG: Ursache ueber die Site-Link-Eigenschaften loesen (Intervall, Aenderungsbenachrichtigung)
Set-ADReplicationSiteLink "Wien-Salzburg" -ReplicationFrequencyInMinutes 15
repadmin /kcc *
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Administrator hat vor Jahren eine direkte Verbindung zwischen zwei Filialen angelegt, weil die Zentrale überlastet schien. Heute ist das Netz umgebaut, die direkte Strecke gibt es nicht mehr, und die Replikation dieser beiden Filialen schlägt dauernd fehl. Der KCC kann die Verbindung nicht ersetzen, weil sie manuell angelegt ist. Erst nach dem Löschen der manuellen Verbindung erzeugt der KCC eine passende Topologie. Seitdem gilt im Team die Regel: Manuelle Verbindungen nur mit Ticket, Begründung und Ablaufdatum.

## 5.9 Replication Troubleshooting

Replikationsprobleme gehören zu den kritischsten Fehlern im Active Directory, weil sie lange unbemerkt bleiben und später große Schäden verursachen: Ein Domain Controller, der länger als die *Tombstone-Lebensdauer* (Tombstone Lifetime, in neuen Forests standardmäßig 180 Tage, im Attribut `tombstoneLifetime` der Konfigurationspartition einstellbar) nicht repliziert hat, darf nicht mehr ins Verzeichnis zurück, weil er gelöschte Objekte „wiederbeleben“ würde (*Lingering Objects*). Deshalb gehört die regelmäßige Prüfung der Replikation zu den Pflichtaufgaben jeder Administration.

Die Fehlersuche folgt einem festen Schema. Zuerst verschafft man sich einen *Überblick*: Welche Domain Controller und welche Partitionen sind betroffen, seit wann, mit welchem Fehlercode? Das liefert `repadmin /replsummary` und `repadmin /showrepl`. Danach prüft man die *Grundlagen*: Sind die Domain Controller im Netzwerk erreichbar (Ping, Portprüfung, DNS-Auflösung der Servernamen und der CNAME-Einträge mit der DSA-GUID)? Stimmen die Uhren? Läuft der Netlogon-Dienst? Dann folgt die Analyse mit `dcdiag`, das gezielt Replikation, DNS, Namensauflösung und Dienste testet. Erst danach beginnt die *Ursachenbehebung* je nach Fehlercode.

Einige häufige Fehlercodes und ihre typischen Ursachen: *1722* (der RPC-Server ist nicht verfügbar) weist auf Netzwerk-, Firewall- oder DNS-Probleme hin; *8524* (DSA-Operation nicht möglich, DNS-Lookup-Fehler) auf eine fehlende oder falsche DNS-Registrierung des CNAME-Eintrags; *8453* (Zugriff verweigert) auf fehlende Replikationsrechte oder ein kaputtes Computerkonto; *1396* oder *1789* auf Kerberos-Probleme (falscher Name, falsches Kennwort, Zeitabweichung); *8606* auf unvollständige Attribute beim Anlegen eines Objekts (meist Lingering Objects); *8614* auf einen Domain Controller, der länger als die Tombstone-Lebensdauer getrennt war. Die Fehlercodes sind wichtig, weil dieselbe Fehlermeldung in verschiedenen Fehlerbildern vorkommt.

Das folgende Skript führt eine strukturierte Replikationsprüfung durch. Es ermittelt die Fehler im Forest, listet fehlgeschlagene Replikationen mit Fehlertext und Zeit, prüft die Namensauflösung der Replikationspartner und die Uhrzeit und stößt abschließend die Replikation an.

```powershell
Import-Module ActiveDirectory

# 1) Ueberblick: Wer hat Fehler, wie alt ist die letzte erfolgreiche Replikation?
repadmin /replsummary

# 2) Fehler im Detail (alle DCs der Domain)
Get-ADReplicationFailure -Target (Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName) |
    Select-Object Server, Partner, FirstFailureTime, FailureCount, LastError |
    Sort-Object FailureCount -Descending | Format-Table -AutoSize

# 3) Fehlertext zu einem Fehlercode nachschlagen
net helpmsg 1722
repadmin /showrepl * /csv | ConvertFrom-Csv | Where-Object { $_."Number of Failures" -gt 0 } |
    Select-Object "Source DSA","Destination DSA","Naming Context","Last Failure Status","Number of Failures"

# 4) Grundlagen: Namensaufloesung, Erreichbarkeit, Zeit zwischen den beiden DCs
$partner = "DC02.corp.contoso.com"
Resolve-DnsName $partner
Test-NetConnection $partner -Port 135
Test-NetConnection $partner -Port 389
w32tm /stripchart /computer:$partner /samples:3 /dataonly

# 5) DC-Diagnose und erneuter Replikationsversuch
dcdiag /test:replications /test:dns /v /c /s:DC01
repadmin /syncall DC01 /AdeP
```

Schritt 1 zeigt in einer Tabelle, wie weit der letzte erfolgreiche Replikationslauf zurückliegt und wie hoch die Fehlerquote je Domain Controller ist. Schritt 2 liest dieselben Informationen als Objekte, sortiert sie nach Zahl der Fehler und gibt Fehlercode (`LastError`) und Beginn des Problems aus. Schritt 3 übersetzt einen Fehlercode in Text und filtert die Replikationspartner mit Fehlern aus der CSV-Ausgabe von `repadmin`. Schritt 4 prüft die Grundlagen: DNS, die Ports für RPC-Endpunktzuordnung (135) und LDAP (389) und die Zeitabweichung. Schritt 5 prüft mit `dcdiag` und löst die Replikation nochmals aus.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, bei Replikationsproblemen sofort „am Domain Controller etwas zu reparieren“, bevor die Ursache bekannt ist. In vielen Fällen liegt sie aber in DNS oder in der Firewall. Der zweite Fehler ist, einen längere Zeit getrennten Domain Controller einfach wieder anzuschließen, statt ihn zu prüfen, zu bereinigen oder neu aufzubauen; das erzeugt Lingering Objects. Ein dritter Fehler ist, den Domain Controller mit dem Fehler zu „reparieren“, indem man die Datenbank kopiert oder einen Snapshot zurückspielt: Dadurch kann ein sogenannter *USN Rollback* entstehen, bei dem der Domain Controller Änderungen verliert, die andere schon kennen. Virtualisierte Domain Controller sollten deshalb nur mit einer Plattform betrieben werden, die die Funktion *VM-Generation-ID* unterstützt.

```powershell
# FALSCH: Alter DC (mehr als die Tombstone-Lebensdauer getrennt) wird einfach wieder ans Netz gehaengt
Start-VM -Name "DC02"

# RICHTIG: Pruefen, ob die Tombstone-Lebensdauer ueberschritten ist; wenn ja, DC herabstufen/neu aufbauen
(Get-ADObject "CN=Directory Service,CN=Windows NT,CN=Services,$((Get-ADRootDSE).configurationNamingContext)" -Properties tombstoneLifetime).tombstoneLifetime
repadmin /showrepl DC02
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen betreibt seit zwei Jahren einen Domain Controller in einer Außenstelle, der unbemerkt seit Monaten nicht repliziert. Als sich Benutzer über diesen Server anmelden, gelten alte Kennwörter, und gesperrte Konten funktionieren noch. Die Prüfung mit `repadmin /replsummary` zeigt „8524“ wegen fehlender DNS-Einträge. Nach der Korrektur der DNS-Konfiguration repliziert der Server wieder. Das Team richtet eine tägliche Prüfung ein, die dieses Skript ausführt und bei Fehlern eine E-Mail an die Administratoren schickt.

## 5.10 Übungsaufgaben zu Modul 05

Die Aufgaben 1 bis 3 prüfen das Verständnis, die Aufgaben 4 bis 8 sind praktische Skriptaufgaben für die Laborumgebung.

**Aufgabe 5.1** **Zonenart und Replikationsbereich.** Ein Unternehmen hat eine Domain `corp.contoso.com` und eine Tochterdomain `wien.corp.contoso.com`. Welchen Replikationsbereich wählen Sie für die Zone der Tochterdomain und welchen für `_msdcs`? Begründen Sie die Wahl und nennen Sie den Unterschied zum Bereich „Legacy“.

**Aufgabe 5.2** **Anmeldung erklären.** Beschreiben Sie in eigenen Worten, welche DNS-Abfragen ein Client durchführt, um einen Domain Controller zu finden, und was passiert, wenn der Eintrag `_ldap._tcp.dc._msdcs` fehlt.

**Aufgabe 5.3** **Kosten planen.** Drei Standorte (Wien, Salzburg, Graz): Wien-Salzburg 512 kbit/s, Wien-Graz 256 kbit/s, Salzburg-Graz 128 kbit/s. Welche Kosten tragen Sie ein, wenn Sie die Tabelle aus Lerneinheit 5.6 verwenden? Welchen Weg wählt der KCC für Salzburg nach Graz?

**Aufgabe 5.4** **Zonen anlegen.** Legen Sie in der Laborumgebung eine AD-integrierte Forward-Zone `lab.contoso.com` und eine Reverse-Zone für 10.10.0.0/16 an. Tragen Sie einen A-Record mit PTR ein und prüfen Sie beide Auflösungsrichtungen.

**Aufgabe 5.5** **SRV-Check.** Schreiben Sie ein Skript, das für alle Domain Controller der Domain prüft, ob der Eintrag in `_ldap._tcp.dc._msdcs` vorhanden ist, und fehlende Domain Controller ausgibt.

**Aufgabe 5.6** **Sites einrichten.** Legen Sie die Sites Wien, Salzburg und Graz mit je einem Subnetz an, verschieben Sie einen Domain Controller in die Site Salzburg und prüfen Sie die Zuordnung auf einem Client mit `nltest`.

**Aufgabe 5.7** **Site Links.** Bauen Sie die Hub-and-Spoke-Topologie aus Lerneinheit 5.6 nach, entfernen Sie die Sites aus `DEFAULTIPSITELINK` und lassen Sie sich die Kostenmatrix mit `repadmin /showism` anzeigen. Welche Aussage macht die Matrix zu Salzburg–Graz?

**Aufgabe 5.8** **Replikationsprüfung.** Erstellen Sie ein Skript, das für alle Domain Controller die Partner mit dem Zeitpunkt der letzten erfolgreichen Replikation ausgibt und alle Partner markiert, deren letzte erfolgreiche Replikation mehr als 24 Stunden zurückliegt.

## 5.11 Lösungen zu den Übungsaufgaben

**Lösung 5.1.** Für die Zone der Tochterdomain genügt der Bereich *Domain* (alle DNS-Server der Domain), weil nur deren Domain Controller die Einträge brauchen. Die Zone `_msdcs` der Forest-Root-Domain braucht der gesamte Forest und wird im Bereich *Forest* repliziert. Der Bereich *Legacy* speichert die Zone in der Domänenpartition auf allen Domain Controllern der Domain, auch denen ohne DNS-Rolle, und ist nur für sehr alte Domain Controller nötig; er erzeugt unnötige Replikation und wird nicht mehr empfohlen.

**Lösung 5.2.** Der Client bestimmt zunächst seine Site, fragt dann die SRV-Einträge der Domain Controller der eigenen Site (`_ldap._tcp.Sitename._sites.dc._msdcs.Domäne`) ab und fällt auf die Einträge der gesamten Domain zurück, wenn keiner antwortet. Er wählt per Priorität und Gewicht einen Server und baut die Verbindung auf. Fehlt der Eintrag `_ldap._tcp.dc._msdcs`, findet der Client keinen Domain Controller; die Anmeldung scheitert mit der Meldung, die Domäne sei nicht erreichbar. Die Ursache liegt meist in der DNS-Konfiguration des Domain Controllers oder im Netlogon-Dienst.

**Lösung 5.3.** Nach der Tabelle: 512 kbit/s entspricht Kosten von 378, 256 kbit/s Kosten von 425, 128 kbit/s Kosten von 486. Der direkte Link Salzburg–Graz kostet also 486; der Weg über Wien kostet 378 + 425 = 803. Der KCC wählt den direkten Link (486), weil er billiger ist. Wollte man Hub-and-Spoke erzwingen, müsste man den direkten Link weglassen oder die Kosten deutlich über 803 setzen.

**Lösung 5.4.**

```powershell
Add-DnsServerPrimaryZone -Name "lab.contoso.com" -ReplicationScope Domain -DynamicUpdate Secure
Add-DnsServerPrimaryZone -NetworkId "10.10.0.0/16" -ReplicationScope Domain -DynamicUpdate Secure
Add-DnsServerResourceRecordA -ZoneName "lab.contoso.com" -Name "test01" -IPv4Address "10.10.0.50" -CreatePtr
Resolve-DnsName test01.lab.contoso.com
Resolve-DnsName 10.10.0.50 -Type PTR
```

Beide Auflösungen müssen das passende Gegenstück liefern. Funktioniert die Rückwärtsauflösung nicht, prüfen Sie, ob die Reverse-Zone ein passendes Netz abdeckt (hier 10.10.0.0/16 für die Adresse 10.10.0.50) und ob `-CreatePtr` verwendet wurde.

**Lösung 5.5.**

```powershell
$domain = "corp.contoso.com"
$dcs   = Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName
$srv   = (Resolve-DnsName -Type SRV -Name "_ldap._tcp.dc._msdcs.$domain" | Where-Object Type -eq SRV).NameTarget
foreach ($dc in $dcs) {
    [pscustomobject]@{ DC = $dc; SrvEintrag = ($srv -contains $dc) }
}
```

Das Skript vergleicht die HostNamen aller Domain Controller (aus dem Verzeichnis) mit den Zielen der SRV-Einträge (aus dem DNS). Domain Controller mit dem Wert `False` haben keinen Eintrag; die Ursache liegt meist bei Netlogon oder der Zone. Umgekehrt zeigt ein SRV-Ziel, das nicht in der Liste der Domain Controller auftaucht, einen verwaisten Eintrag eines nicht mehr vorhandenen Servers.

**Lösung 5.6.**

```powershell
New-ADReplicationSite -Name "Salzburg"; New-ADReplicationSite -Name "Graz"
New-ADReplicationSubnet -Name "10.20.0.0/16" -Site "Salzburg"
New-ADReplicationSubnet -Name "10.30.0.0/16" -Site "Graz"
Move-ADDirectoryServer -Identity "DC02" -Site "Salzburg"
Get-ADDomainController -Filter * | Select-Object Name, Site
nltest /dsgetsite       # auf einem Client im Netz 10.20.0.0/16
```

Ein Client mit einer Adresse im Netz 10.20.0.0/16 muss als Site „Salzburg“ melden. Meldet er etwas anderes, fehlt das Subnetz oder wurde ein größeres Netz einer anderen Site zugeordnet, das überlagert wird. Hinweis: Der Client fragt die Site beim Domain Controller ab und speichert sie zwischen; nach Änderungen kann ein Neustart oder `nltest /dsgetsite` nach einiger Zeit nötig sein.

**Lösung 5.7.** Die Befehle entsprechen Lerneinheit 5.6. Die Kostenmatrix in `repadmin /showism` enthält für das Paar Salzburg–Graz die Summe der Kosten über Wien (hier 100 + 300 = 400), weil es keinen direkten Link gibt und die Links transitiv sind. Die Matrix zeigt also, dass Salzburg und Graz nur über Wien miteinander replizieren. Die Ausgabe erfolgt direkt auf der Konsole des Domain Controllers mit der ISTG-Rolle, nicht über Remote-Aufruf.

**Lösung 5.8.**

```powershell
Get-ADReplicationPartnerMetadata -Target * -Scope Server |
    Select-Object Server, Partner, Partition, LastReplicationSuccess,
        @{n="Alt";e={ $_.LastReplicationSuccess -lt (Get-Date).AddHours(-24) }} |
    Sort-Object Alt -Descending | Format-Table -AutoSize
```

Die berechnete Spalte `Alt` ist `True`, wenn die letzte erfolgreiche Replikation mehr als 24 Stunden zurückliegt. Wichtig: Dieser Wert ist nur aussagekräftig, wenn tatsächlich Änderungen anfallen; bei Partnern ohne Änderungen kann eine ältere Zeit auch normal sein. Eine zuverlässigere Prüfung kombiniert die Zeit mit dem Fehlerzähler aus `Get-ADReplicationFailure`.
