# Modul 06 - FSMO-Rollen, Global Catalog und Domain Controller Betrieb

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Tabellen als Markdown-Tabellen, Übungsaufgaben und Lösungen als Absätze). Die Überschriften sind wie in der Quelle nach Modul und Lerneinheit nummeriert (6.1 bis 6.9; 6.10 Übungsaufgaben, 6.11 Lösungen). **Die PowerShell-Beispiele wurden für dieses Repository nicht ausgeführt**; sie setzen eine Windows-Server-Laborumgebung mit der fiktiven Domain `corp.contoso.com` voraus und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain. Übersicht zum Modul: [README](README.md).

|                                       |              |
|:--------------------------------------|:-------------|
| Dauer laut Modulübersicht             | 10 Stunden   |
| Summe der Lerneinheiten (Detailblatt) | 10,5 Stunden |
| Priorität                             | 1            |

| Nr. | Lerneinheit           | Dauer (h) | Prio |
|----:|:----------------------|----------:|-----:|
| 6.1 | FSMO Rollen           |         1 |    1 |
| 6.2 | Schema Master         |         1 |    1 |
| 6.3 | Domain Naming Master  |       1,5 |    1 |
| 6.4 | PDC Emulator          |         1 |    1 |
| 6.5 | RID Master            |         1 |    1 |
| 6.6 | Infrastructure Master |       1,5 |    1 |
| 6.7 | Global Catalog        |         1 |    2 |
| 6.8 | SYSVOL und DFSR       |         1 |    2 |
| 6.9 | Zeitdienst            |       1,5 |    2 |
|     | **Summe**             |  **10,5** |      |

> **Merke**
>
> Die Stundensumme der Lerneinheiten im Detailblatt (10,5 h) weicht von der Dauer in der Modulübersicht (10 h) ab. Dieses Skript behandelt alle Lerneinheiten des Detailblatts vollständig; die Abweichung ist im Lehrplan selbst zu klären.

Active Directory ist überwiegend *multimaster*: Jeder schreibbare Domain Controller darf fast alle Änderungen selbst annehmen. Einige Aufgaben lassen sich aber nicht sinnvoll auf mehreren Servern gleichzeitig erledigen, etwa die Änderung des Schemas oder das Vergeben eindeutiger Kennungen für neue Objekte. Für diese Aufgaben gibt es Sonderrollen, die immer nur ein einziger Domain Controller innehat: die *FSMO-Rollen*. Dieses Modul erklärt diese Rollen, den Global Catalog sowie die Dienste, ohne die ein Domain Controller nicht stabil läuft: SYSVOL mit DFSR und den Zeitdienst. Es ist damit das Betriebsmodul für den Domain Controller.

## 6.1 FSMO Rollen

Die Abkürzung steht für *Flexible Single Master Operations*; synonym spricht man von *Operations-Master-Rollen*. Die Microsoft-Dokumentation erklärt das Prinzip so: Um widersprüchliche Änderungen zu vermeiden, führt Active Directory bestimmte Aktualisierungen nach dem *Single-Master-Modell* aus, bei dem nur ein einziger Domain Controller im ganzen Verzeichnis sie verarbeiten darf. Anders als bei der Windows-NT-Zeit, als ein einzelner Primary Domain Controller alle Änderungen annahm, ist die Rolle aber nicht an einen Server gebunden, sondern kann auf jeden anderen Domain Controller übertragen werden; deshalb heißen sie „flexibel“.

Es gibt fünf Rollen. Zwei gelten für den ganzen *Forest* und existieren dort genau einmal: der *Schema Master* und der *Domain Naming Master*. Drei gelten je *Domain* und existieren in jeder Domain einmal: der *PDC Emulator*, der *RID Master* und der *Infrastructure Master*. Beim Anlegen des Forests erhält der erste Domain Controller alle fünf Rollen; beim Anlegen weiterer Domains erhält deren erster Domain Controller die drei domänenweiten Rollen. Die Microsoft-Dokumentation weist darauf hin, dass die Zuweisung nur beim Anlegen einer Domain und beim Herabstufen eines Rolleninhabers automatisch erfolgt; jede weitere Änderung muss ein Administrator veranlassen. Schreibgeschützte Domain Controller (RODC) können keine Rolle übernehmen, weil sie nicht schreiben dürfen.

Wann braucht man die Rollen? Die Rollen sind nur *im Moment der jeweiligen Operation* nötig. Fällt der Schema Master aus, merkt niemand etwas, bis jemand das Schema ändert. Fällt der PDC Emulator aus, merken es dagegen sofort alle: Zeitsynchronisation, Kennwortänderungen, Sperrungen und viele Verwaltungswerkzeuge hängen an ihm. Der RID Master ist wichtig, wenn Domain Controller neue Kennungen brauchen. Diese Abstufung bestimmt, wie man die Rollen verteilt, überwacht und im Notfall behandelt.

Es gibt zwei Wege, eine Rolle zu verlagern. Bei der *Übertragung* (Transfer) geben der alte und der neue Rolleninhaber die Rolle kontrolliert weiter; dabei wird vorher repliziert, damit der neue Inhaber alles Wichtige kennt. Das ist der Normalfall bei Wartung oder beim Außerbetriebnehmen eines Servers. Bei der *Übernahme* (Seizure) schreibt ein Domain Controller sich selbst als Inhaber ins Verzeichnis, ohne mit dem alten zu sprechen. Die Microsoft-Dokumentation warnt, dass man diesen Schritt mit äußerster Vorsicht und nur dann ausführen soll, wenn der alte Inhaber nie wieder ins Netz kommt. Danach muss er neu aufgebaut werden, bevor er wieder verwendet wird.

Das folgende Skript zeigt, wie man die Rolleninhaber ermittelt, eine Rolle kontrolliert überträgt und die Inhaber in einer Liste dokumentiert. Die Rollen werden mit den Zahlen 0 bis 4 oder ihren Namen angegeben (0 = PDCEmulator, 1 = RIDMaster, 2 = InfrastructureMaster, 3 = SchemaMaster, 4 = DomainNamingMaster).

```powershell
Import-Module ActiveDirectory

# 1) Alle fuenf Rolleninhaber anzeigen
$forest = Get-ADForest
$domain = Get-ADDomain
[pscustomobject]@{
    SchemaMaster       = $forest.SchemaMaster
    DomainNamingMaster = $forest.DomainNamingMaster
    PDCEmulator        = $domain.PDCEmulator
    RIDMaster          = $domain.RIDMaster
    InfrastructureMaster = $domain.InfrastructureMaster
} | Format-List
netdom query fsmo          # dieselbe Information als klassisches Werkzeug

# 2) Rolle kontrolliert uebertragen (Wartung von DC01): PDC-Emulator und RID-Master nach DC02
Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole PDCEmulator, RIDMaster

# 3) Rolle uebernehmen (nur bei dauerhaftem Ausfall des alten Inhabers!)
# Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole PDCEmulator -Force

# 4) Dokumentation: Rolleninhaber mit Datum in eine Datei schreiben
"{0}  {1}" -f (Get-Date -Format s), (netdom query fsmo | Out-String) | Add-Content ".\FSMO-Dokumentation.txt"
```

Schritt 1 liest die Inhaber der Forest-Rollen aus dem Forest-Objekt und die der Domain-Rollen aus dem Domain-Objekt; `netdom query fsmo` liefert die gleiche Auskunft als Text. In Schritt 2 überträgt das Cmdlet zwei Rollen auf DC02, und zwar kontrolliert, also ohne `-Force`. Schritt 3 zeigt, wie man eine Rolle *übernimmt*; der Schalter `-Force` macht aus der Übertragung eine Übernahme und ist deshalb auskommentiert. Schritt 4 hält den Zustand mit Datum fest, damit man später nachvollziehen kann, wer wann welche Rolle hatte.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, nicht zu wissen, wo die Rollen liegen. Bei einem Ausfall verliert man dann Zeit mit der Suche, und im ungünstigsten Fall wird die Rolle an einen Server gebunden, der gerade in Wartung ist. Der zweite Fehler ist, einen Domain Controller mit Rollen einfach auszuschalten, statt die Rollen vorher zu übertragen; bei einer ordnungsgemäßen Herabstufung werden sie zwar automatisch weitergereicht, bei hartem Ausschalten aber nicht. Der dritte Fehler ist, ohne Not eine Rolle zu übernehmen, *und den alten Inhaber später wieder einzuschalten*: Dann glauben zwei Server, Inhaber der Rolle zu sein, und es kommt zu Konflikten.

```powershell
# FALSCH: DC01 (alle FSMO-Rollen) ausschalten, "wird schon gehen"
Stop-Computer -ComputerName DC01 -Force

# RICHTIG: Rollen vorher uebertragen, Replikation pruefen, erst dann abschalten
Move-ADDirectoryServerOperationMasterRole -Identity DC02 -OperationMasterRole 0,1,2,3,4
netdom query fsmo
repadmin /replsummary
```

### Praxisbezug

> **Praxisbeispiel**
>
> Bei einem Hardwaretausch soll der einzige physische Domain Controller ersetzt werden, auf dem noch alle fünf Rollen liegen. Das Team überträgt die Rollen vorab auf den neuen Domain Controller, kontrolliert mit `netdom query fsmo`, wartet die Replikation ab, führt die Wartung durch und überträgt die Rollen danach wieder (oder lässt sie dort). Das Protokoll aus Schritt 4 des Skripts dient als Nachweis für die Änderungsdokumentation.

## 6.2 Schema Master

Das *Schema* ist der Bauplan des Verzeichnisses: Es legt fest, welche Objektklassen (Benutzer, Computer, Gruppe, Drucker) es gibt und welche Attribute sie haben dürfen. Es wird forestweit in einer eigenen Partition gespeichert und auf alle Domain Controller repliziert. Der *Schema Master* ist der einzige Domain Controller, der Änderungen am Schema annehmen darf. Die Microsoft-Dokumentation beschreibt, dass jede manuelle oder programmatische Schemaänderung ihn braucht, einschließlich der Änderungen, die `adprep /forestprep`, Exchange Server oder andere Anwendungen vornehmen; er muss bei Schemaänderungen online sein, und die Rolle ist nur aktiv, wenn der Inhaber die Schemapartition seit dem Start des Verzeichnisdienstes erfolgreich repliziert hat.

Schemaänderungen sind *selten* und *riskant*: Sie sind forestweit wirksam, laufen automatisch auf allen Domain Controllern und sind im Wesentlichen nicht rückgängig zu machen. Die Microsoft-Dokumentation zur Schemaerweiterung nennt dazu die Voraussetzungen: Man braucht Mitgliedschaft in der Gruppe *Schema Admins*, den Zugriff auf den Schema Master und ein genaues Konzept, welche Klassen oder Attribute man hinzufügt (jedes neue Objekt erhält eine weltweit eindeutige Objektkennung, OID, die man bei einer Registrierungsstelle oder aus dem eigenen Namensraum bezieht). Anlegen kann man neue Klassen und Attribute, *löschen* kann man sie nicht, sondern nur deaktivieren. Typische Anlässe sind der Wechsel auf eine neue Windows-Server-Version (die `adprep`-Schritte erweitern das Schema), die Einführung von Exchange, Configuration Manager oder Microsoft LAPS sowie eigene Attribute für Fachanwendungen.

Die Gruppe *Schema Admins* sollte im Normalbetrieb leer sein. Ein Konto wird nur für die Dauer der Änderung aufgenommen und danach wieder entfernt; das gilt als anerkannte Sicherheitsmaßnahme, weil diese Gruppe Rechte besitzt, mit denen sich das gesamte Verzeichnis verändern lässt. Außerdem gehört zum Betrieb eine Prüfung: Man notiert vor einer Änderung die Schemaversion, die Replikation muss gesund sein, und man hat eine Wiederherstellungsmöglichkeit (aktuelle Systemstatussicherung von mindestens einem Domain Controller, in Testumgebungen oft auch ein isolierter Test der Änderung).

Das folgende Skript prüft, ob der Schema Master erreichbar ist, liest die Schemaversion und die Mitglieder der Gruppe Schema Admins aus und zeigt, wie man Konten für eine geplante Schemaänderung kontrolliert aufnimmt und wieder entfernt.

```powershell
Import-Module ActiveDirectory
$forest = Get-ADForest

# 1) Wer ist Schema Master, und ist er erreichbar?
$forest.SchemaMaster
Test-NetConnection $forest.SchemaMaster -Port 389 | Select-Object ComputerName, TcpTestSucceeded

# 2) Aktuelle Schemaversion lesen (Zahl mit der Dokumentation der Windows-Server-Version vergleichen)
(Get-ADObject (Get-ADRootDSE).schemaNamingContext -Properties objectVersion).objectVersion

# 3) Mitglieder der Gruppe Schema Admins pruefen (sollte im Normalbetrieb leer sein)
Get-ADGroupMember "Schema Admins" | Select-Object Name, SamAccountName

# 4) Fuer die Dauer einer Aenderung: Konto aufnehmen, Aenderung durchfuehren, Konto wieder entfernen
Add-ADGroupMember -Identity "Schema Admins" -Members "adm.huber"
#   ... Schemaaenderung, z. B. adprep /forestprep oder Installation einer Anwendung ...
Remove-ADGroupMember -Identity "Schema Admins" -Members "adm.huber" -Confirm:$false

# 5) Neu angelegte Klassen und Attribute im Schema auflisten (Aenderungen der letzten 30 Tage)
Get-ADObject -SearchBase (Get-ADRootDSE).schemaNamingContext `
    -Filter 'whenCreated -gt $((Get-Date).AddDays(-30)) -and (objectClass -eq "attributeSchema" -or objectClass -eq "classSchema")' `
    -Properties whenCreated | Select-Object Name, whenCreated
```

Schritt 1 prüft die Erreichbarkeit des Schema Masters auf dem LDAP-Port. Schritt 2 liest die Schemaversion als Zahl aus (`objectVersion`); die Zahl ordnet man anhand der Microsoft-Dokumentation einer Windows-Server-Version zu. Schritt 3 listet die Mitglieder der Gruppe auf, Schritt 4 zeigt das Verfahren „aufnehmen, ändern, entfernen“. Schritt 5 findet Klassen und Attribute, die in den letzten 30 Tagen angelegt wurden, und ist eine einfache Kontrolle nach einer Änderung.

> **Ergänzung aus der Nachrecherche**
>
> Die Hinweise zu Schema Admins, zur Unmöglichkeit des Löschens von Klassen und Attributen und zu OIDs entsprechen den abgerufenen Microsoft-Seiten zur Schemaerweiterung (When to extend the schema, Prerequisites for installing a schema extension, Obtaining an object identifier). Die Zuordnung der Zahlenwerte von `objectVersion` zu Windows-Server-Versionen wurde nicht abgerufen und ist deshalb hier bewusst nicht aufgeführt; sie steht in der Dokumentation zur jeweiligen Windows-Server-Version.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, Mitglieder dauerhaft in der Gruppe *Schema Admins* zu lassen oder sie mit *Enterprise Admins* zu vermischen. Die Gruppe ist ein bevorzugtes Angriffsziel. Der zweite Fehler ist, Schemaänderungen direkt in der Produktion auszuprobieren: Weil man sie nicht zurücknehmen kann, gehören sie zuerst in eine Testumgebung, die ein Abbild der Produktion ist. Der dritte Fehler ist, die Replikation nach einer Änderung nicht zu prüfen: Ändert man das Schema am Schema Master, und ein Domain Controller erhält es nicht, treten später Fehler beim Anlegen von Objekten auf (zum Beispiel der Fehler 8606).

```powershell
# FALSCH: Dauerhaft ein Alltags-Admin in Schema Admins
Add-ADGroupMember "Schema Admins" -Members "a.muster"

# RICHTIG: Nur ein eigenes Admin-Konto, nur fuer die Dauer der Aenderung (siehe Schritt 4 oben)
Add-ADGroupMember "Schema Admins" -Members "adm.huber"
# ... Aenderung ...
Remove-ADGroupMember "Schema Admins" -Members "adm.huber" -Confirm:$false
```

### Praxisbezug

> **Praxisbeispiel**
>
> Vor der Einführung eines neuen Domain Controllers mit Windows Server 2025 muss das Schema erweitert werden. Das Team nimmt für den Wartungstag ein dediziertes Konto in *Schema Admins* auf, prüft Replikation und Sicherung, führt `adprep` am Schema Master aus, wartet die Replikation ab, kontrolliert die Schemaversion und entfernt das Konto wieder. Die Schritte stehen im Änderungsprotokoll, und ein Zweitprüfer bestätigt die Ergebnisse.

## 6.3 Domain Naming Master

Der *Domain Naming Master* verwaltet den *Namensraum des Forests*: Er darf als einziger Domain Controller Domains zum Forest hinzufügen oder aus ihm entfernen. Dasselbe gilt für *Anwendungspartitionen* (zum Beispiel für DNS), die er ebenfalls anlegt und entfernt, sowie für Querverweise (Cross References) auf Domains in anderen Verzeichnissen. Die Informationen stehen in der Partition `CN=Partitions,CN=Configuration`. Es gibt genau einen Domain Naming Master pro Forest. Wie der Schema Master ist er nur dann gefragt, wenn tatsächlich eine Domain oder Partition hinzukommt oder verschwindet.

Die Rolle ist leicht zu verwechseln mit dem *Global Catalog*, weil sie früher (unter Windows 2000) auf einem Global Catalog liegen musste. Ab Windows Server 2003 ist das nicht mehr nötig, wie die Microsoft-Dokumentation zur Rollenverteilung ausdrücklich festhält. Ebenfalls zu unterscheiden ist sie vom *Namensdienst DNS*: Der Domain Naming Master verwaltet *Domains im Forest*, nicht DNS-Namen. Für den Betrieb gilt: Er soll auf einem zuverlässigen, gut gesicherten Domain Controller liegen, zum Beispiel dem PDC Emulator der Forest-Root-Domain, wie es die Microsoft-Dokumentation zur Platzierung empfiehlt, und er muss bei der Anlage oder dem Entfernen einer Domain erreichbar sein. Für diese Operationen braucht man außerdem Mitgliedschaft in der Gruppe *Enterprise Admins*.

Das folgende Skript zeigt, wie man den Domain Naming Master und die Domains des Forests ermittelt, die Partitionen im Forest anzeigt (Cross-Reference-Objekte) und die Erreichbarkeit der Rolle vor einer Domänenänderung prüft.

```powershell
Import-Module ActiveDirectory
$forest = Get-ADForest

# 1) Rolleninhaber, Domains und Global Catalogs im Forest
$forest.DomainNamingMaster
$forest.Domains
$forest.GlobalCatalogs

# 2) Alle Partitionen des Forests (Cross-Reference-Objekte in der Partitions-Container)
$cfg = (Get-ADRootDSE).configurationNamingContext
Get-ADObject -SearchBase "CN=Partitions,$cfg" -Filter 'objectClass -eq "crossRef"' -Properties nCName, dnsRoot |
    Select-Object Name, nCName, dnsRoot | Format-Table -AutoSize

# 3) Erreichbarkeit pruefen vor dem Anlegen einer Domain / Anwendungspartition
Test-NetConnection $forest.DomainNamingMaster -Port 389
Get-ADDomainController -Discover -Service TimeService | Select-Object HostName

# 4) Wer darf Domains anlegen? Mitglieder von Enterprise Admins pruefen (Root-Domain)
Get-ADGroupMember "Enterprise Admins" -Server $forest.RootDomain | Select-Object Name
```

Schritt 1 liefert den Inhaber der Rolle und gleich die Domains und Global Catalogs des Forests. Schritt 2 listet die Partitionen: Jede Domain und jede Anwendungspartition (zum Beispiel `DomainDnsZones`) hat ein Cross-Reference-Objekt. Schritt 3 prüft vor einer Änderung, ob die Rolle erreichbar ist. Schritt 4 zeigt die Berechtigten.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist der Versuch, eine Domain oder DNS-Anwendungspartition hinzuzufügen, während der Domain Naming Master nicht erreichbar ist; die Operation scheitert dann mit Fehlern, die auf den ersten Blick nach DNS-Problemen aussehen. Der zweite Fehler ist, die Rolle auf einen Domain Controller in einer langsamen Außenstelle zu legen. Der dritte Fehler ist die Verwechslung mit anderen Rollen: Wer den Domain Naming Master „repariert“, obwohl in Wahrheit der PDC Emulator das Problem verursacht, verliert Zeit.

```powershell
# FALSCH: Rolle in einer Aussenstelle mit schwacher WAN-Anbindung
Move-ADDirectoryServerOperationMasterRole -Identity "DC-AUSSENSTELLE" -OperationMasterRole DomainNamingMaster

# RICHTIG: Rolle beim Forest-Root-PDC (gut angebunden, gut ueberwacht)
Move-ADDirectoryServerOperationMasterRole -Identity "DC01" -OperationMasterRole DomainNamingMaster
```

### Praxisbezug

> **Praxisbeispiel**
>
> Nach einer Übernahme eines Unternehmens soll dessen Domain als Tochterdomain in den Forest aufgenommen werden. Bei der Heraufstufung des ersten Domain Controllers der neuen Domain bricht der Assistent mit einer Fehlermeldung zum Verzeichnisdienst ab. Die Prüfung zeigt, dass der Domain Naming Master des Forests wegen einer Firewall-Regel vom neuen Standort nicht erreichbar ist. Nach Freigabe der Ports (LDAP, RPC) läuft die Heraufstufung durch.

## 6.4 PDC Emulator

Der *PDC Emulator* ist die wichtigste der fünf Rollen im Alltag. Die Microsoft-Dokumentation beschreibt ihn als Domain Controller, der sich gegenüber Arbeitsstationen, Mitgliedsservern und älteren Domain Controllern als *Primary Domain Controller* ausgibt. Er hat mehrere Aufgaben, die man kennen muss. Er ist die *Zeitquelle* der Domain: Alle anderen Domain Controller holen ihre Zeit direkt oder indirekt von ihm (Lerneinheit 6.9). Er erhält *Kennwortänderungen* sofort: Wenn ein Benutzer sein Kennwort an einem anderen Domain Controller ändert, wird die Änderung unverzüglich an den PDC Emulator gemeldet, und wenn sich ein Benutzer mit einem Kennwort anmeldet, das ein Domain Controller nicht akzeptiert, fragt dieser vorher noch beim PDC Emulator nach, ob das Kennwort inzwischen geändert wurde. Er ist der *Standardserver für Gruppenrichtlinien*: Die Gruppenrichtlinien-Verwaltung bearbeitet Richtlinien standardmäßig auf ihm. Und er ist Ziel für *ältere Anwendungen* und manche Verwaltungswerkzeuge, die schreibende Zugriffe ausführen. Die Dokumentation verlangt, dass er rund um die Uhr erreichbar sein muss.

Außerdem verarbeitet er die *Kontosperrungen* (Lockouts) bevorzugt: Sperrungen werden sofort an ihn weitergegeben, damit sie überall gelten, und die Ereignisse zur Fehlersuche (Ereignis 4740) findet man typischerweise dort. Das ist der Grund, warum Fehlersuchen bei gesperrten Konten fast immer auf dem PDC Emulator beginnen (Modul 8).

Wegen dieser Aufgaben empfiehlt die Microsoft-Dokumentation, den PDC Emulator auf der *besten Hardware* in einem zuverlässig angebundenen Hub-Standort zu betreiben, mit mehreren Domain Controllern derselben Domain in der gleichen Site. Er hat in großen Umgebungen oft die höchste CPU-Last. Alle Domain Controller und die Computer mit Administrationswerkzeugen, die den PDC Emulator ansprechen, müssen ihn per Netzwerk erreichen können. Bei Standorten mit schwacher WAN-Anbindung kann die Registrierungseinstellung `AvoidPdcOnWan` verhindern, dass Domain Controller den PDC Emulator über das WAN befragen; dann fällt aber auch die sofortige Prüfung geänderter Kennwörter weg.

Das folgende Skript zeigt typische Prüfungen am PDC Emulator: Erreichbarkeit und Auslastung, Zeitquelle, sowie die Kontrolle, auf welchem Domain Controller ein gesperrtes Konto gesperrt wurde. Es zeigt außerdem, wie man das Gruppenrichtlinien-Werkzeug gezielt auf einen anderen Domain Controller richtet.

```powershell
Import-Module ActiveDirectory
$pdc = (Get-ADDomain).PDCEmulator

# 1) Erreichbarkeit und einfache Auslastungsmessung des PDC-Emulators
Test-Connection $pdc -Count 2
Get-CimInstance Win32_Processor -ComputerName $pdc | Measure-Object LoadPercentage -Average

# 2) Zeitquelle und Abweichung des PDC-Emulators
w32tm /query /computer:$pdc /source
w32tm /monitor /computers:$pdc

# 3) Sperrungen: Ereignis 4740 (Kontosperrung) der letzten 24 Stunden auf dem PDC-Emulator
Get-WinEvent -ComputerName $pdc -FilterHashtable @{ LogName="Security"; Id=4740; StartTime=(Get-Date).AddHours(-24) } |
    Select-Object TimeCreated, @{n="Konto";e={$_.Properties[0].Value}}, @{n="Quellrechner";e={$_.Properties[1].Value}}

# 4) Passwort-Replikation sofort anstossen: Aenderung vom PDC-Emulator an alle Partner
repadmin /syncall $pdc /AdeP
```

Schritt 1 prüft, ob der Server erreichbar ist und wie stark die Prozessoren ausgelastet sind. Schritt 2 liest die Zeitquelle (wichtig: Auf dem PDC Emulator darf sie nicht „Local CMOS Clock“ sein, siehe Lerneinheit 6.9) und vergleicht die Zeit mit der von anderen Servern. Schritt 3 sucht Kontosperrungen und gibt den Quellrechner aus, der die falschen Kennwörter geschickt hat. Schritt 4 stößt eine Replikation an.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, den PDC Emulator zu „vergessen“: Er läuft auf dem ältesten Server, hat eine falsche Zeitquelle, ist nicht gesichert und überwacht. Fällt er aus oder geht seine Uhr falsch, bricht die Kerberos-Authentifizierung zusammen, weil alle Uhren abdriften. Der zweite Fehler ist das Verschieben der Rolle in eine Außenstelle, deren Netz langsam ist. Der dritte Fehler ist, die Zeit am PDC Emulator „nebenbei“ mit einem Hypervisor synchronisieren zu lassen, während gleichzeitig NTP aktiv ist: Zwei Zeitquellen kämpfen dann um die Uhr.

```powershell
# FALSCH: PDC-Emulator zeigt auf die eigene Hardware-Uhr (Standard bei neu aufgesetzten Servern)
w32tm /query /source        # Ausgabe: Local CMOS Clock

# RICHTIG: Externe, zuverlaessige Zeitquellen eintragen und Zeit neu synchronisieren
w32tm /config /manualpeerlist:"0.at.pool.ntp.org 1.at.pool.ntp.org" /syncfromflags:manual /reliable:yes /update
w32tm /resync /rediscover
```

### Praxisbezug

> **Praxisbeispiel**
>
> Montagmorgen melden sich Benutzer reihenweise nicht mehr an, Kerberos-Fehler häufen sich. Die Uhr des PDC Emulators, der virtuell läuft und seine Zeit vom Hypervisor bezieht, ging nach einem Wartungsfenster am Wochenende zwölf Minuten falsch. Das Team stellt die Zeitquelle um, synchronisiert den PDC Emulator mit externen NTP-Servern, deaktiviert die Zeitsynchronisierung über den Hypervisor für diese VM und überwacht seitdem die Abweichung automatisch.

## 6.5 RID Master

Jedes Sicherheitsobjekt (Benutzer, Computer, Gruppe) hat eine eindeutige *Sicherheitskennung* (Security Identifier, SID), die sich aus der SID der Domain und einer fortlaufenden Nummer, dem *Relative Identifier* (RID), zusammensetzt. Eine Beispiel-SID ist `S-1-5-21-111-222-333-1105`; die letzte Zahl 1105 ist der RID. Damit kein RID doppelt vergeben wird, obwohl jeder Domain Controller Objekte anlegt, vergibt der *RID Master* Nummernbereiche. Die Microsoft-Dokumentation beschreibt, dass er den globalen RID-Pool der Domain pflegt und allen Domain Controllern lokale RID-Pools zuteilt; deshalb sind alle Sicherheitsobjekte der Domain eindeutig gekennzeichnet.

Die Funktionsweise ist einfach. Jeder Domain Controller erhält vom RID Master einen *aktiven Pool* (standardmäßig 500 Nummern) und einen *Reservepool*. Wenn er ein Objekt anlegt, nimmt er die nächste Nummer aus seinem Pool. Ist der aktive Pool zur Hälfte aufgebraucht, fordert er beim RID Master einen neuen an (so die Beschreibung aus dem Fachwissen zur RID-Zuteilung). Der RID Master muss deshalb nicht ständig erreichbar sein; er muss nur erreichbar sein, wenn ein neu heraufgestufter Domain Controller seinen ersten Pool braucht oder wenn ein vorhandener Domain Controller seinen Pool erneuern muss. Die Dokumentation formuliert es so: Er muss online sein, wenn neue Domain Controller einen lokalen Pool brauchen, den sie zum Ankündigen benötigen, und wenn bestehende Domain Controller ihre Pools erneuern.

Probleme entstehen in zwei Fällen. Erstens, wenn *massenhaft Objekte* angelegt werden, etwa durch ein fehlerhaftes Skript, das in einer Schleife Konten erzeugt und löscht: Jedes angelegte Objekt verbraucht einen RID, auch wenn es sofort wieder gelöscht wird. Der Gesamtvorrat einer Domain ist begrenzt (etwa eine Milliarde), und wenn er ausgeschöpft ist, können keine Objekte mehr angelegt werden. Ein Schutzmechanismus (Ereignis 16644, 16645 und folgende) warnt vorher. Zweitens, wenn ein Domain Controller aus einem *Snapshot* wiederhergestellt wird: Er würde RIDs doppelt vergeben, weshalb moderne Plattformen mit VM-Generation-ID ihn schützen und den Pool verwerfen. Das Anlegen doppelter SIDs hat gravierende Folgen und gehört deshalb zu den Katastrophenfällen in der Active-Directory-Verwaltung.

Das folgende Skript prüft den RID-Vorrat: Es ermittelt den RID Master, liest den Stand der global vergebenen RIDs aus und führt den eingebauten Test aus. Mit dem Wert lässt sich abschätzen, wie viel Spielraum es noch gibt.

```powershell
Import-Module ActiveDirectory
$domain = Get-ADDomain
$ridMaster = $domain.RIDMaster

# 1) Stand des globalen RID-Pools: oberer Teil = Obergrenze, unterer Teil = bisher global zugeteilter Bereich
$rid = Get-ADObject -Identity "CN=RID Manager`$,CN=System,$($domain.DistinguishedName)" `
        -Server $ridMaster -Properties rIDAvailablePool
$pool = [int64]$rid.rIDAvailablePool
$obereGrenze = [int64]($pool / [math]::Pow(2,32))             # hoechster RID, der vergeben werden darf
$naechster   = [int64]($pool % [math]::Pow(2,32))             # bisher global zugeteilt
"Global vergeben: {0:N0} von {1:N0} ({2:P2})" -f $naechster, $obereGrenze, ($naechster / $obereGrenze)

# 2) Eingebauter Test des RID-Managers auf einem DC
dcdiag /test:ridmanager /v /s:DC01

# 3) Wann wurden zuletzt RID-Probleme gemeldet? (Ereignis 16644-16650 im Verzeichnisdienst-Protokoll)
Get-WinEvent -FilterHashtable @{ LogName="Directory Service"; Id=16644,16645,16650 } -MaxEvents 5 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, Message
```

In Schritt 1 steht im Attribut `rIDAvailablePool` eine 64-Bit-Zahl, deren oberer Teil die Obergrenze der vergebbaren RIDs und deren unterer Teil den nächsten freien Wert enthält; das Skript trennt die beiden Teile und berechnet den Anteil. Für eine ältere, kleine Domain ist der Wert winzig, bei einer Domain mit fehlerhaften Skripten kann er auffällig hoch sein. Schritt 2 ruft den Test des RID-Managers auf. Schritt 3 liest die Warnereignisse, falls welche vorhanden sind.

> **Ergänzung aus der Nachrecherche**
>
> Die Angaben zu Poolgröße 500, der Hälfte als Auslöser für die Neuanforderung, zur Obergrenze von etwa einer Milliarde und zu den Ereignis-IDs stammen aus dem allgemeinen Fachwissen zur RID-Verwaltung. Sie wurden nicht einzeln abgerufen und sind deshalb mit der aktuellen Microsoft-Dokumentation zu prüfen, bevor man sie als Grenzwerte für die Überwachung verwendet. Abgerufen und bestätigt ist die Funktion des RID Masters, die Poolverteilung und die Anforderung an seine Erreichbarkeit (FSMO placement and optimization on Active Directory domain controllers; Planning Operations Master Role Placement).

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, Skripte ohne Probelauf Objekte in Massen anlegen und wieder löschen zu lassen; der RID-Vorrat sinkt, ohne dass es auffällt. Der zweite Fehler ist das Kopieren oder Wiederherstellen eines Domain Controllers aus einem Snapshot oder einer Sicherung ohne die dafür vorgesehenen Mechanismen. Der dritte Fehler ist, den RID Master nicht an einem erreichbaren, gut angebundenen Domain Controller zu betreiben: Neue Domain Controller in Außenstellen können dann keinen RID-Pool bekommen und starten nicht mit der Ankündigung.

```powershell
# FALSCH: Testskript legt 100000 Konten an und loescht sie wieder (jedes verbraucht einen RID)
1..100000 | ForEach-Object { New-ADUser -Name "test$_" ; Remove-ADUser "test$_" -Confirm:$false }

# RICHTIG: Mit kleiner Stichprobe testen, und -WhatIf nutzen
1..5 | ForEach-Object { New-ADUser -Name "test$_" -WhatIf }
```

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Software legt bei jeder Synchronisation tausende Konten an und löscht sie wieder. Nach einigen Monaten häufen sich in den Verzeichnisdienst-Ereignissen Warnungen zum RID-Verbrauch. Die Analyse mit dem Skript dieser Lerneinheit zeigt, dass bereits ein großer Teil des Vorrats verbraucht ist. Das Team schaltet die fehlerhafte Synchronisation ab, wertet aus, welche Anwendung verursacht hat, und richtet eine Überwachung ein, die bei steigendem RID-Verbrauch Alarm schlägt.

## 6.6 Infrastructure Master

Objekte in einer Domain verweisen oft auf Objekte einer *anderen* Domain, zum Beispiel wenn ein Benutzer aus Domain A Mitglied einer Gruppe in Domain B ist. Ein solcher Verweis enthält die GUID, bei Sicherheitsobjekten die SID und den Distinguished Name des Zielobjekts. Wird das Zielobjekt später umbenannt oder verschoben, ändert sich der Distinguished Name, und der Verweis wäre veraltet. Die Microsoft-Dokumentation erklärt, dass der *Infrastructure Master* der Domain Controller ist, der die SID und den Distinguished Name solcher domänenübergreifenden Verweise aktualisiert. Er tut das, indem er Informationen aus einem *Global Catalog* bezieht und mit seinen eigenen Verweisen (den sogenannten *Phantomen*) vergleicht.

Daraus ergibt sich eine Besonderheit, die oft zu Verwirrung führt: Hostet der Infrastructure Master selbst einen Global Catalog, dann hat er alle Objekte des Forests (als Teilkopie) und erzeugt keine Phantome; er findet deshalb nichts zu aktualisieren, und die Verweise in der Domain werden nicht mehr nachgeführt. Die Microsoft-Dokumentation hält daher fest, dass in einer Mehrdomänenumgebung die Rolle *nicht* auf einem Global Catalog liegen darf, falls nicht alle Domain Controller der Domain Global Catalogs sind; im Ereignisprotokoll erscheint sonst fortlaufend die Meldung mit der Nummer 1419. Der Hinweis betrifft vor allem die erste Domain des Forests: Dort liegen anfangs alle fünf Rollen auf einem Domain Controller, der zugleich Global Catalog ist, deshalb muss man die Rolle verschieben, sobald man eine zweite Domain plant.

Die Dokumentation nennt zwei Fälle, in denen man sich um die Lage der Rolle *nicht* kümmern muss: Wenn der Forest nur *eine Domain* hat, gibt es keine domänenübergreifenden Verweise, und die Rolle hat nichts zu tun. Und wenn *alle Domain Controller* der Domain Global Catalogs sind (die heute übliche Konfiguration), haben alle die aktuellen Daten. Als dritter Fall gilt ein Forest, in dem der *Active Directory-Papierkorb* aktiviert ist: Gelöschte Verweise werden dann nicht zu Phantomen, sondern bleiben als logisch gelöschte Objekte erhalten. In diesen Fällen sollte die Rolle trotzdem auf einem gültigen Domain Controller stehen, damit Überwachungssysteme keine Fehler melden.

Das folgende Skript prüft die Platzierung der Rolle: Es ermittelt, ob der Infrastructure Master ein Global Catalog ist, wie viele Domains der Forest hat und ob alle Domain Controller der Domain Global Catalogs sind, und bewertet daraus, ob eine Änderung nötig ist.

```powershell
Import-Module ActiveDirectory
$domain = Get-ADDomain
$forest = Get-ADForest

$im       = $domain.InfrastructureMaster
$imDc     = Get-ADDomainController -Identity $im
$alleDcs  = Get-ADDomainController -Filter * -Server $domain.DNSRoot
$alleGc   = ($alleDcs | Where-Object IsGlobalCatalog).Count
$papierkorb = [bool](Get-ADOptionalFeature -Filter "Name -eq 'Recycle Bin Feature'" |
                     Where-Object { $_.EnabledScopes.Count -gt 0 })

[pscustomobject]@{
    InfrastructureMaster = $im
    IstGlobalCatalog     = $imDc.IsGlobalCatalog
    DomainsImForest      = @($forest.Domains).Count
    DCsInDomain          = @($alleDcs).Count
    DavonGlobalCatalog   = $alleGc
    Papierkorb           = $papierkorb
}

if (@($forest.Domains).Count -gt 1 -and $imDc.IsGlobalCatalog -and $alleGc -lt @($alleDcs).Count -and -not $papierkorb) {
    "WARNUNG: Infrastructure Master liegt auf einem Global Catalog, obwohl nicht alle DCs GC sind."
} else {
    "Platzierung in Ordnung."
}
```

Das Skript sammelt die vier Größen, die für die Entscheidung relevant sind: Anzahl der Domains, Global-Catalog-Eigenschaft des Rolleninhabers, ob alle Domain Controller Global Catalogs sind und ob der Papierkorb aktiv ist. Die Warnung erscheint nur in dem einen Fall, in dem es ein Problem gibt. In allen anderen Konstellationen gibt das Skript „in Ordnung“ aus, und die Rolle kann dort bleiben, wo sie ist.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die Panik beim Anblick der Warnung 1419 in einer Einzeldomain: Dort ist sie harmlos. Der zweite Fehler ist die entgegengesetzte Haltung, nach der man die Rolle in einer Mehrdomänenumgebung nie anpasst und sich wundert, dass nach Umbenennungen von Gruppen oder Benutzern in einer Nachbardomain veraltete Namen in Gruppenmitgliedschaften stehen. Ein dritter Fehler ist es, den Global Catalog von allen Domain Controllern zu entfernen, „um Last zu sparen“, ohne die Folgen für die Anmeldung zu bedenken (siehe Lerneinheit 6.7).

```powershell
# FALSCH: In einer Mehrdomaenen-Umgebung bleibt die Rolle auf dem ersten DC, der auch GC ist
netdom query fsmo      # InfrastructureMaster = DC01 (GC), obwohl nicht alle DCs GC sind

# RICHTIG: Rolle auf einen Nicht-GC verschieben - oder alle DCs der Domain zu GCs machen
Move-ADDirectoryServerOperationMasterRole -Identity "DC-NOGC" -OperationMasterRole InfrastructureMaster
```

### Praxisbezug

> **Praxisbeispiel**
>
> In einem Unternehmen mit Konzerndomain und Tochterdomain steht in Gruppen der Konzerndomain weiterhin der alte Name eines Mitarbeiters der Tochterdomain, obwohl er längst umbenannt wurde. Ursache: Der Infrastructure Master der Konzerndomain läuft auf einem Global Catalog. Nach dem Verschieben der Rolle auf einen Domain Controller ohne Global Catalog stimmen die Namen nach wenigen Replikationszyklen. Seit der Einführung des Papierkorbs und weil alle Domain Controller Global Catalogs sind, hat das Team die Aufgabe allerdings von der Checkliste gestrichen.

## 6.7 Global Catalog

Der *Global Catalog* (GC) ist ein Domain Controller, der zusätzlich zu den Daten seiner eigenen Domain eine *teilweise, schreibgeschützte Kopie aller anderen Domains des Forests* speichert. Wie die Microsoft-Dokumentation beschreibt, enthalten diese Teilkopien jedes Objekt der anderen Domains, aber nur eine Teilmenge der Attribute (die am häufigsten für Suchen verwendeten). Die Teilmenge nennt man das *Partial Attribute Set*; Administratoren können sie im Schema erweitern, indem sie ein Attribut für den Global Catalog markieren. Ein Global Catalog wird nicht durch eine eigene Rolle, sondern durch eine *Einstellung am Domain Controller* festgelegt. Der erste Domain Controller eines Forests ist automatisch ein Global Catalog.

Wozu braucht man das? Es gibt drei Hauptaufgaben. Erstens ermöglicht er *forestweite Suchen*: Wer im Adressbuch nach einem Benutzer sucht, ohne zu wissen, in welcher Domain er liegt, fragt den Global Catalog, der über den Port 3268 (unverschlüsselt) oder 3269 (verschlüsselt) erreichbar ist. Zweitens liefert er die *Gruppenmitgliedschaften universaler Gruppen* bei der Anmeldung: Universale Gruppen können Mitglieder aus allen Domains haben, und ihre Mitgliedschaft ist nur im Global Catalog vollständig bekannt. Deshalb muss bei der Anmeldung eines Benutzers ein Global Catalog erreichbar sein (in einem Forest mit mehreren Domains); fehlt er, scheitert die Anmeldung, es sei denn, die *Zwischenspeicherung der universalen Gruppenmitgliedschaft* (Universal Group Membership Caching) ist an der Site aktiviert. Drittens benötigt auch der *UPN-Login* den Global Catalog, um das Konto zu finden, wenn der UPN-Suffix nicht eindeutig zu einer Domain passt. In einem Forest mit nur einer Domain enthält jeder Domain Controller bereits alle Daten; ein Global Catalog verursacht dort kaum Zusatzkosten.

Für die *Platzierung* gilt eine einfache Faustregel, die auch die Microsoft-Dokumentation zur FSMO-Platzierung erwähnt: Praktisch machen die meisten Administratoren *alle* Domain Controller zu Global Catalogs. Das vereinfacht den Betrieb (keine Sonderfälle bei der Infrastructure-Master-Rolle), beschleunigt die Anmeldungen und macht die Anwendungen unabhängig von der Erreichbarkeit einzelner Server. Die Kosten sind etwas mehr Speicher, mehr Replikationsverkehr und, bei schmalen WAN-Leitungen oder sehr vielen Domains, eine zusätzliche Last. Für Außenstellen ohne eigene Domain Controller sorgt die Site dafür, dass Clients den nächsten Global Catalog finden. Für Außenstellen mit *einem* Domain Controller ist der Global Catalog fast immer die bessere Wahl gegenüber dem Zwischenspeicher.

Das folgende Skript zeigt, wie man die Global Catalogs im Forest ermittelt, einen Domain Controller zum Global Catalog macht und die Funktion prüft. Der Global-Catalog-Status steht im Attribut `options` des Objekts *NTDS Settings* (Bit 0, Wert 1).

```powershell
Import-Module ActiveDirectory

# 1) Alle Global Catalogs im Forest, mit Site
Get-ADDomainController -Filter 'IsGlobalCatalog -eq $true' |
    Select-Object Name, Site, Domain, IPv4Address | Sort-Object Site

# 2) DC02 zum Global Catalog machen (Bit 0 im Attribut options setzen)
$ntds = (Get-ADDomainController -Identity "DC02").NTDSSettingsObjectDN
Set-ADObject -Identity $ntds -Replace @{ options = ((Get-ADObject $ntds -Properties options).options -bor 1) }

# 3) Nach der Aufnahme: Wartezeit bis die GC-Daten repliziert sind, dann Dienst pruefen
nltest /dsgetdc:corp.contoso.com /GC
Test-NetConnection DC02 -Port 3268
Resolve-DnsName -Type SRV "_gc._tcp.corp.contoso.com" | Where-Object Type -eq SRV | Select-Object NameTarget

# 4) Suche am Global Catalog (forestweit, Port 3268)
Get-ADUser -Filter "Surname -eq 'Muster'" -Server "DC02:3268" -Properties Department | Select-Object Name, Department, DistinguishedName

# 5) Zwischenspeicherung universaler Gruppen fuer eine Site ohne GC aktivieren (Bit 32 im options der Site)
$siteDn = (Get-ADReplicationSite "Salzburg").DistinguishedName
$ntdsSite = "CN=NTDS Site Settings,$siteDn"
Set-ADObject -Identity $ntdsSite -Replace @{ options = ((Get-ADObject $ntdsSite -Properties options).options -bor 32) }
```

Schritt 1 zeigt die Global Catalogs mit Site; für gute Anmeldezeiten sollte jede Site mit Benutzern entweder einen eigenen Global Catalog haben oder eine schnelle Verbindung zu einem. Schritt 2 setzt das Bit im Objekt *NTDS Settings*, wodurch der Domain Controller beginnt, die Teilkopien der anderen Domains zu replizieren; das kann je nach Verzeichnisgröße lange dauern, und erst danach meldet er sich als Global Catalog. Schritt 3 prüft, ob der Server als Global Catalog gefunden wird, ob der Port erreichbar ist und ob der SRV-Eintrag da ist. Schritt 4 zeigt eine Suche mit dem Port 3268. Schritt 5 aktiviert in der Site das Zwischenspeichern der universalen Gruppen, wenn dort kein Global Catalog stehen soll.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die Anmeldung in einer Außenstelle ohne Global Catalog und ohne Zwischenspeicher: Fällt die WAN-Leitung aus, kann sich niemand mehr anmelden, obwohl ein Domain Controller vor Ort läuft. Der zweite Fehler ist die Annahme, dass sich alle Anwendungen auf Port 389 beziehen können, wenn sie forestweit suchen sollen: Anwendungen, die Benutzer in mehreren Domains finden müssen, müssen den Global-Catalog-Port 3268 oder 3269 verwenden. Der dritte Fehler ist, Attribute, die man im Global Catalog haben möchte, ohne Plan zum Partial Attribute Set hinzuzufügen: Das löst eine vollständige Neureplikation in den Global Catalogs aus und kann zu viel Verkehr führen.

```powershell
# FALSCH: Anwendung sucht Benutzer aller Domains ueber Port 389 (nur die eigene Domain)
Get-ADUser -Filter "Surname -eq 'Muster'" -Server DC01

# RICHTIG: Forestweite Suche ueber den Global Catalog
Get-ADUser -Filter "Surname -eq 'Muster'" -Server "DC01:3268"
```

### Praxisbezug

> **Praxisbeispiel**
>
> In einer Filiale mit einem Domain Controller fällt abends die Leitung zur Zentrale aus. Obwohl der lokale Server läuft, können sich die Mitarbeiter am nächsten Morgen nicht anmelden: Der Domain Controller ist kein Global Catalog, und die Zwischenspeicherung ist nicht aktiviert. Nach der Umstellung auf einen Global Catalog (die Datenmenge ist klein) melden sich die Benutzer auch bei Leitungsausfällen an. Das Team nimmt dieses Kriterium in die Standardkonfiguration für neue Außenstellen auf.

## 6.8 SYSVOL und DFSR

Hinter dem Namen *SYSVOL* verbirgt sich ein Ordner auf jedem Domain Controller (standardmäßig `C:\Windows\SYSVOL`), der als Freigabe zur Verfügung gestellt wird und zwei Dinge enthält: den Inhalt der *Gruppenrichtlinienobjekte* (die Dateien, nicht die AD-Einträge; sie liegen im Unterordner `Policies`) und die *Anmeldeskripte* (Freigabe `NETLOGON`). Clients lesen beim Start und bei der Anmeldung die Richtlinien aus diesem Ordner. Damit alle Domain Controller denselben Inhalt haben, muss SYSVOL repliziert werden. Für diese Replikation sind zwei Technologien relevant: der alte *File Replication Service* (FRS) und sein Nachfolger *Distributed File System Replication* (DFSR). FRS ist seit Langem veraltet; Windows Server 2025 und die aktuellen Versionen unterstützen nur noch DFSR, und neue Domains verwenden es von Anfang an.

DFSR repliziert nur die geänderten Teile von Dateien (blockweise), komprimiert die Daten und ist robuster als FRS. Es verwaltet seine Daten in einer eigenen Datenbank pro Domain Controller und führt sie in der *Replikationsgruppe* „Domain System Volume“ zusammen. Wichtig ist, dass DFSR *unabhängig* von der AD-Replikation arbeitet: Ein Gruppenrichtlinienobjekt besteht aus einem Teil im Verzeichnis (Gruppenrichtlinien-Container) und einem Teil in SYSVOL (Gruppenrichtlinienvorlage). Beide Teile werden getrennt repliziert; sind sie nicht synchron, spricht man von einer *Inkonsistenz*, die zu Fehlern bei der Anwendung der Richtlinie führen kann. Der Gruppenrichtlinienmanager meldet das mit der Meldung, dass die Version von AD und SYSVOL nicht übereinstimmt.

Domänen, die vor Windows Server 2008 entstanden sind, verwenden möglicherweise noch FRS und müssen *migriert* werden. Die Migration erfolgt mit dem Werkzeug `dfsrmig` in vier Zuständen: Start (0), Prepared (1), Redirected (2) und Eliminated (3). Man führt sie Stufe für Stufe aus und prüft nach jeder Stufe, ob alle Domain Controller den Zustand erreicht haben. Wer heute eine Domain aufbaut, trifft FRS höchstens in sehr alten Produktivumgebungen an.

Das folgende Skript prüft SYSVOL und DFSR: Es kontrolliert die Freigaben, den Migrationsstatus und den Zustand des DFSR-Dienstes, wertet Ereignisse aus und zeigt, wie man eine Replikation anstößt und mit `dfsrdiag` den Replikationsstatus liest.

```powershell
# 1) Freigaben SYSVOL und NETLOGON vorhanden?
Get-SmbShare -Name SYSVOL, NETLOGON | Select-Object Name, Path

# 2) Migrationsstatus: sollte "Eliminated" sein (FRS nicht mehr aktiv)
dfsrmig /getglobalstate
dfsrmig /getmigrationstate

# 3) DFSR-Dienst und Ereignisse der letzten 7 Tage auf Fehler und Warnungen
Get-Service DFSR | Select-Object Status, StartType
Get-WinEvent -FilterHashtable @{ LogName="DFS Replication"; Level=2,3; StartTime=(Get-Date).AddDays(-7) } -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap

# 4) Replikationsstatus und Backlog (offene Dateien) zwischen zwei DCs
dfsrdiag replicationstate /member:DC01
dfsrdiag backlog /rgname:"Domain System Volume" /rfname:"SYSVOL Share" /smem:DC01 /rmem:DC02

# 5) AD-Konfiguration neu einlesen und DFSR zum Abgleich auffordern
dfsrdiag pollad
dcdiag /test:sysvolcheck /test:netlogons /test:frsevent
```

Schritt 1 prüft, ob die beiden Freigaben existieren; fehlen sie, ist der Domain Controller nicht richtig „bereit“ und meldet sich nicht als Domain Controller. Schritt 2 liest den Migrationsstatus; der Wert „Eliminated“ bedeutet, dass FRS vollständig abgelöst ist. Schritt 3 sucht Fehler und Warnungen der letzten Woche im DFSR-Protokoll. Schritt 4 zeigt den Replikationsstatus eines Domain Controllers und den *Backlog*, also die Anzahl von Dateien, die zwischen zwei Servern noch zu replizieren sind; ein Backlog nahe null ist gesund. Schritt 5 liest die AD-Konfiguration neu ein und führt die SYSVOL-Diagnose aus.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, auf FRS zu verbleiben, weil „es ja läuft“: Neue Windows-Server-Versionen können dann nicht mehr als Domain Controller hinzugefügt werden, und der alte Dienst wird nicht mehr unterstützt. Ein zweiter Fehler ist das Kopieren von Dateien *direkt* in den SYSVOL-Ordner eines einzelnen Servers; die Datei wird zwar repliziert, aber nach einem Konflikt kann die Version eines anderen Servers gewinnen. Ein dritter Fehler ist, nach einer plötzlichen Abschaltung eines Domain Controllers (Stromausfall) die Warnung „Dirty Shutdown“ (Ereignis 2213) zu ignorieren: DFSR hält die Replikation an, bis ein Administrator sie freigibt, und das fällt oft erst auf, wenn Gruppenrichtlinien nicht mehr ankommen. Ein vierter Fehler ist, einen Domain Controller längere Zeit vom Netz zu nehmen: Ist er länger als die maximale Offline-Zeit (in der Standardeinstellung 60 Tage) getrennt, hält DFSR die Replikation an (Ereignis 4012).

```powershell
# FALSCH: Ein Skript direkt in den SYSVOL-Ordner eines einzelnen DCs kopieren
Copy-Item .\anmeldung.bat "\\DC02\SYSVOL\corp.contoso.com\scripts\"

# RICHTIG: Aenderungen immer an einem definierten DC vornehmen (z. B. dem PDC-Emulator), Replikation pruefen
$pdc = (Get-ADDomain).PDCEmulator
Copy-Item .\anmeldung.bat "\\$pdc\SYSVOL\corp.contoso.com\scripts\"
dfsrdiag backlog /rgname:"Domain System Volume" /rfname:"SYSVOL Share" /smem:$pdc /rmem:DC02
```

### Praxisbezug

> **Praxisbeispiel**
>
> Nach einem Stromausfall in der Außenstelle zeigt der dortige Domain Controller veraltete Gruppenrichtlinien: Clients erhalten alte Einstellungen. Das DFSR-Protokoll enthält Ereignis 2213 (Dirty Shutdown); die Replikation von SYSVOL ist angehalten. Nach der Freigabe der Replikation (Anleitung im Ereignistext) kopiert DFSR die Änderungen nach, und die Clients erhalten die aktuellen Richtlinien. Das Team nimmt die Ereignisse 2213 und 4012 in die automatische Überwachung auf.

## 6.9 Zeitdienst

Kerberos, die Standardauthentifizierung von Active Directory, funktioniert nur, wenn die Uhren der beteiligten Rechner *nahezu gleich* gehen. Standardmäßig akzeptiert Windows eine Abweichung von höchstens fünf Minuten zwischen Client und Domain Controller; ist sie größer, scheitert die Anmeldung mit Fehlern, die oft nur „Zugriff verweigert“ oder „Zeitunterschied“ lauten. Auch die AD-Replikation löst gleichzeitige Änderungen anhand von Zeitstempeln auf und ist deshalb auf eine einheitliche Zeit angewiesen. Der *Windows-Zeitdienst* (W32Time) verteilt die Zeit mit dem *Network Time Protocol* (NTP, UDP-Port 123) in der Domain.

Die Hierarchie ist fest vorgegeben, wie auch die Microsoft-Dokumentation zur Funktionsweise des Windows-Zeitdienstes beschreibt: Mitgliedsrechner holen sich die Zeit von einem Domain Controller (ihrer Site), Domain Controller von ihrem Eltern-Domain-Controller, und an der Spitze steht der *PDC Emulator der Forest-Root-Domain* als *zuverlässige Zeitquelle* (Reliable Time Source). Weil alle Domain Controller der Hierarchie folgen, genügt es, genau *eine* Maschine korrekt mit einer externen Quelle zu verbinden: den PDC Emulator der Root-Domain. Die PDC Emulator der Kind-Domains beziehen ihre Zeit vom PDC Emulator der Eltern-Domain. Dort bleibt die interne Zeit konsistent, auch wenn die externe Quelle einmal ausfällt.

Für die Konfiguration gibt es die Werte `NT5DS` (Zeit aus der Domain-Hierarchie, Standard bei Domänenmitgliedern) und `NTP` (manuell eingetragene Server, für den PDC Emulator der Root-Domain). Als externe Quellen eignen sich mehrere zuverlässige NTP-Server, etwa regionale Pool-Server, die Zeitdienste des Providers oder eine lokale Funkuhr. Virtuelle Domain Controller bergen eine Falle: Viele Virtualisierungsplattformen synchronisieren die Zeit der virtuellen Maschine zusätzlich mit dem Host (Integrationsdienst); zwei Quellen können sich dann gegenseitig stören. Man deaktiviert deshalb bei Domain Controllern in der Regel entweder die Zeitsynchronisierung des Hosts oder konfiguriert den Host sauber mit denselben NTP-Quellen.

Das folgende Skript zeigt, wie man den Zeitdienst in der Domain prüft und den PDC Emulator der Forest-Root-Domain konfiguriert. Außerdem zeigt es die Prüfung der Zeitabweichung aller Domain Controller und die Wirkung einer Zeitabweichung auf Kerberos.

```powershell
Import-Module ActiveDirectory
$forest  = Get-ADForest
$rootPdc = (Get-ADDomain -Identity $forest.RootDomain).PDCEmulator

# 1) Zeitquelle jedes DC anzeigen (Hierarchie pruefen)
Get-ADDomainController -Filter * | ForEach-Object {
    [pscustomobject]@{ DC = $_.HostName; Quelle = (w32tm /query /computer:$($_.HostName) /source) }
}

# 2) Zeitabweichung aller DCs gegen den Root-PDC messen
w32tm /monitor /computers:$((Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName) -join ",")

# 3) Auf dem Root-PDC: externe Quellen eintragen, als zuverlaessig markieren, neu starten
w32tm /config /computer:$rootPdc /manualpeerlist:"0.at.pool.ntp.org,0x8 1.at.pool.ntp.org,0x8" `
      /syncfromflags:manual /reliable:yes /update
Invoke-Command -ComputerName $rootPdc { Restart-Service w32time; w32tm /resync /rediscover }

# 4) Status und Konfiguration anzeigen
w32tm /query /computer:$rootPdc /status /verbose
w32tm /query /computer:$rootPdc /configuration | Select-String "Type|NtpServer|AnnounceFlags"

# 5) Auf einem Client: Zeit gegen einen DC pruefen und neu synchronisieren
w32tm /stripchart /computer:DC01 /samples:5 /dataonly
w32tm /resync
```

Schritt 1 liest die Quelle jedes Domain Controllers und zeigt damit die Hierarchie; bei einem nicht-root Domain Controller sollte als Quelle ein anderer Domain Controller stehen, beim Root-PDC der externe Server. Schritt 2 misst die Abweichung der Domain Controller. Schritt 3 konfiguriert den Root-PDC: `manualpeerlist` listet die externen Server (die Markierung `0x8` bedeutet Clientmodus), `syncfromflags:manual` schaltet auf manuelle Quellen, `reliable:yes` kennzeichnet ihn als zuverlässige Zeitquelle. Schritt 4 liest Status und Konfiguration, Schritt 5 prüft einen Client.

> **Ergänzung aus der Nachrecherche**
>
> Die Hierarchie des Zeitdienstes, die Typen `NT5DS` und `NTP` und die Befehle `w32tm` entsprechen den abgerufenen Seiten „How the Windows Time service works“ und „Windows Time service tools and settings“ (Microsoft Learn). Die Angabe von höchstens fünf Minuten Abweichung bei Kerberos ist der Standardwert der Richtlinie „Maximale Toleranz für die Synchronisation der Computeruhr“ und kann in Gruppenrichtlinien geändert werden; sie wurde hier nicht erneut abgerufen.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, die Zeit *auf allen Domain Controllern* mit externen Quellen zu verbinden: Die Hierarchie wird so umgangen, und die Server weichen untereinander ab, wenn ihre Quellen etwas abweichen. Ein zweiter Fehler ist die Konfiguration auf dem falschen Server, zum Beispiel auf einem Domain Controller, der nicht (mehr) PDC Emulator der Root-Domain ist, nachdem die Rolle verschoben wurde. Ein dritter Fehler ist es, die Uhrzeit *manuell* zu verstellen, um ein Zeitproblem schnell zu beheben, ohne die Ursache zu beheben. Ein vierter Fehler ist das Blockieren des UDP-Ports 123 an der Firewall zum externen NTP-Server, sodass die Quelle nie erreicht wird.

```powershell
# FALSCH: Auf jedem DC die externen Server eintragen
w32tm /config /manualpeerlist:"pool.ntp.org" /syncfromflags:manual /update

# RICHTIG: Nur auf dem PDC-Emulator der Root-Domain; alle anderen DCs bleiben auf Domain-Hierarchie
w32tm /config /syncfromflags:domhier /update
w32tm /resync /rediscover
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Krankenhaus erlebt nach einem Rechenzentrumsumzug zufällige Anmeldefehler bei Medizingeräten. Eine Messung mit `w32tm /monitor` zeigt, dass zwei Domain Controller um sieben Minuten voraus sind: Sie wurden bei der Migration mit einem Gast-Zeitgeber des Hypervisors synchronisiert, der falsch eingestellt war. Das Team deaktiviert die Host-Synchronisierung für alle Domain Controller, konfiguriert den Root-PDC auf mehrere externe Quellen und hängt eine Überwachung an, die ab zwei Minuten Abweichung einen Alarm auslöst.

## 6.10 Übungsaufgaben zu Modul 06

Die Aufgaben 1 bis 3 prüfen das Verständnis, die Aufgaben 4 bis 8 sind praktische Skriptaufgaben für die Laborumgebung.

**Aufgabe 6.1** **Rollen zuordnen.** Ordnen Sie zu, welche der fünf FSMO-Rollen forestweit und welche domänenweit gilt, und beschreiben Sie in je einem Satz, was ausfällt, wenn die Rolle nicht erreichbar ist.

**Aufgabe 6.2** **Übertragung oder Übernahme?** Der Server DC01 mit dem PDC Emulator ist durch einen Hardwareschaden ausgefallen, die Reparatur dauert Wochen. Welche Schritte führen Sie durch, und was dürfen Sie mit DC01 später auf keinen Fall tun?

**Aufgabe 6.3** **Global Catalog planen.** Ein Unternehmen hat zwei Domains, vier Standorte und in jedem Standort ein bis zwei Domain Controller. Schlagen Sie eine Global-Catalog-Konfiguration vor, begründen Sie sie und sagen Sie, wohin der Infrastructure Master gehört.

**Aufgabe 6.4** **Rollen dokumentieren.** Schreiben Sie ein Skript, das alle fünf Rolleninhaber ermittelt und mit Datum in eine CSV-Datei anhängt. Das Skript soll melden, wenn sich ein Inhaber seit der letzten Zeile geändert hat.

**Aufgabe 6.5** **Rolle übertragen.** Übertragen Sie in der Laborumgebung den PDC Emulator und den RID Master von DC01 auf DC02 und danach wieder zurück. Prüfen Sie jedes Mal mit `netdom query fsmo`.

**Aufgabe 6.6** **Global Catalog prüfen.** Ermitteln Sie alle Global Catalogs des Forests, prüfen Sie für jeden, ob Port 3268 erreichbar ist, und suchen Sie einen Benutzer über den Global Catalog.

**Aufgabe 6.7** **SYSVOL-Gesundheit.** Erstellen Sie ein Skript, das für alle Domain Controller prüft, ob SYSVOL und NETLOGON freigegeben sind, und `dfsrmig /getglobalstate` auswertet.

**Aufgabe 6.8** **Zeitprüfung.** Messen Sie die Zeitabweichung aller Domain Controller gegen den PDC Emulator, geben Sie Abweichungen über 2 Sekunden aus, und beschreiben Sie, was Sie bei einer Abweichung von über 5 Minuten als Erstes prüfen.

## 6.11 Lösungen zu den Übungsaufgaben

**Lösung 6.1.** Forestweit: *Schema Master* (ohne ihn keine Schemaänderungen, Betrieb sonst unberührt) und *Domain Naming Master* (ohne ihn keine neuen oder entfernten Domains und Anwendungspartitionen). Domänenweit: *PDC Emulator* (ohne ihn Zeitsynchronisation, sofortige Kennwortprüfung, Gruppenrichtlinienbearbeitung und Sperrverarbeitung gestört; sofort spürbar), *RID Master* (ohne ihn bekommen neue Domain Controller keinen RID-Pool und bestehende irgendwann keinen Nachschub, sodass keine neuen Objekte mehr angelegt werden können) und *Infrastructure Master* (ohne ihn werden domänenübergreifende Verweise nicht mehr aktualisiert; im Einzelforest ohne Folgen).

**Lösung 6.2.** Da DC01 für lange Zeit nicht zur Verfügung steht, muss der PDC Emulator auf einem anderen Domain Controller übernommen werden: Mit `Move-ADDirectoryServerOperationMasterRole -Identity DC02 -OperationMasterRole PDCEmulator -Force` wird die Rolle *übernommen* (Seizure). Danach prüft man mit `netdom query fsmo`, konfiguriert die Zeitquelle am neuen PDC Emulator (Lerneinheit 6.9), prüft die Replikation und bereinigt, falls DC01 nicht zurückkehren soll, die Metadaten. DC01 darf nach der Reparatur *nicht einfach wieder ans Netz*: Er würde glauben, noch Inhaber der Rolle zu sein. Er muss vorher entweder neu aufgebaut oder zumindest vom Netz getrennt herabgestuft werden.

**Lösung 6.3.** Empfohlen: *Alle Domain Controller werden Global Catalogs.* Das vermeidet Anmeldeprobleme bei Leitungsausfällen und macht die Platzierung des Infrastructure Masters unerheblich, weil alle Domain Controller der Domain Global Catalogs sind. Gibt es Gründe gegen diese Lösung (sehr schwache Leitungen, sehr große Verzeichnisse), richtet man mindestens in jedem Standort einen Global Catalog ein oder aktiviert in kleinen Standorten die Zwischenspeicherung universaler Gruppen. Wenn nicht alle Domain Controller Global Catalogs sind, muss der Infrastructure Master jeder Domain auf einem Domain Controller liegen, der kein Global Catalog ist.

**Lösung 6.4.**

```powershell
$forest = Get-ADForest; $domain = Get-ADDomain
$jetzt = [pscustomobject]@{
    Datum = Get-Date -Format s
    Schema = $forest.SchemaMaster; Naming = $forest.DomainNamingMaster
    PDC = $domain.PDCEmulator; RID = $domain.RIDMaster; Infra = $domain.InfrastructureMaster
}
$datei = ".\FSMO-Verlauf.csv"
if (Test-Path $datei) {
    $alt = Import-Csv $datei | Select-Object -Last 1
    foreach ($r in "Schema","Naming","PDC","RID","Infra") {
        if ($alt.$r -ne $jetzt.$r) { Write-Warning "Rolle $r gewechselt: $($alt.$r) -> $($jetzt.$r)" }
    }
}
$jetzt | Export-Csv $datei -Append -NoTypeInformation -Encoding UTF8
```

Das Skript liest die Inhaber, vergleicht sie mit der letzten gespeicherten Zeile und meldet jeden Wechsel; anschließend hängt es die aktuelle Zeile an. Läuft es täglich als geplante Aufgabe, entsteht ein lückenloser Verlauf.

**Lösung 6.5.**

```powershell
Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole PDCEmulator, RIDMaster
netdom query fsmo
Move-ADDirectoryServerOperationMasterRole -Identity "DC01" -OperationMasterRole PDCEmulator, RIDMaster
netdom query fsmo
```

Beide Übertragungen werden ohne `-Force` durchgeführt, also kontrolliert. Nach der Übertragung des PDC Emulators muss die Zeitquelle neu geprüft werden, weil die externe Konfiguration am neuen Inhaber fehlt, falls er Root-PDC ist.

**Lösung 6.6.**

```powershell
Get-ADDomainController -Filter 'IsGlobalCatalog -eq $true' | ForEach-Object {
    [pscustomobject]@{
        DC   = $_.HostName
        Port = (Test-NetConnection $_.HostName -Port 3268 -WarningAction SilentlyContinue).TcpTestSucceeded
    }
}
Get-ADUser -Filter "Surname -eq 'Muster'" -Server "DC01:3268" | Select-Object Name, DistinguishedName
```

Ein Global Catalog mit `False` bei Port 3268 ist entweder noch nicht fertig repliziert oder durch eine Firewall getrennt. Die Suche mit dem Port 3268 findet Benutzer aus allen Domains des Forests.

**Lösung 6.7.**

```powershell
Get-ADDomainController -Filter * | ForEach-Object {
    $dc = $_.HostName
    $freigaben = Invoke-Command -ComputerName $dc { (Get-SmbShare -Name SYSVOL,NETLOGON -ErrorAction SilentlyContinue).Name }
    [pscustomobject]@{ DC=$dc; SYSVOL=($freigaben -contains "SYSVOL"); NETLOGON=($freigaben -contains "NETLOGON") }
}
dfsrmig /getglobalstate
```

Beide Freigaben müssen auf jedem Domain Controller vorhanden sein. Der globale Status muss „Eliminated“ lauten; ein anderer Wert zeigt eine unvollendete Migration von FRS zu DFSR.

**Lösung 6.8.** Mit `w32tm /stripchart /computer:DC01 /samples:3 /dataonly` gegen jeden Domain Controller; die Spalte mit der Abweichung gibt sie in Sekunden an. Bei mehr als fünf Minuten Abweichung prüft man zuerst die *Hierarchie* (Quelle jedes Domain Controllers mit `w32tm /query /source`), dann den PDC Emulator der Root-Domain (seine externe Quelle und die Erreichbarkeit über UDP 123) und danach auf virtuellen Maschinen die Zeitsynchronisierung mit dem Host. Die Zeit wird nicht von Hand verstellt, sondern über `w32tm /resync /rediscover` wieder in Takt gebracht, nachdem die Ursache behoben wurde.
