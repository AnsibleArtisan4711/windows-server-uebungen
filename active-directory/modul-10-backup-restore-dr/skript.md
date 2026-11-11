# Modul 10 - Backup, Restore und Disaster Recovery

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Tabellen als Markdown-Tabellen, Übungsaufgaben und Lösungen als Absätze). Die Überschriften sind wie in der Quelle nach Modul und Lerneinheit nummeriert (10.1 bis 10.9; 10.10 Übungsaufgaben, 10.11 Lösungen). **Die PowerShell-Beispiele wurden für dieses Repository nicht ausgeführt**; sie setzen eine Windows-Server-Laborumgebung mit der fiktiven Domain `corp.contoso.com` voraus und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain. Übersicht zum Modul: [README](README.md).

|                                       |              |
|:--------------------------------------|:-------------|
| Dauer laut Modulübersicht             | 12 Stunden   |
| Summe der Lerneinheiten (Detailblatt) | 10,5 Stunden |
| Priorität                             | 1            |

|  Nr. | Lerneinheit               | Dauer (h) | Prio |
|-----:|:--------------------------|----------:|-----:|
| 10.1 | System State Backup       |         1 |    1 |
| 10.2 | AD Recycle Bin            |         1 |    1 |
| 10.3 | Non-authoritative Restore |       1,5 |    1 |
| 10.4 | Authoritative Restore     |         1 |    1 |
| 10.5 | Tombstone Lifetime        |         1 |    1 |
| 10.6 | SYSVOL Restore            |       1,5 |    1 |
| 10.7 | Forest Recovery           |         1 |    2 |
| 10.8 | DR Tests                  |         1 |    2 |
| 10.9 | BCDR Runbook              |       1,5 |    2 |
|      | **Summe**                 |  **10,5** |      |

> **Merke**
>
> Die Stundensumme der Lerneinheiten im Detailblatt (10,5 h) weicht von der Dauer in der Modulübersicht (12 h) ab. Dieses Skript behandelt alle Lerneinheiten des Detailblatts vollständig; die Abweichung ist im Lehrplan selbst zu klären.

Alles, was in den vorigen Modulen aufgebaut wurde, kann verloren gehen: durch einen Bedienfehler, durch defekte Hardware, durch Schadsoftware oder durch einen Angreifer, der die Domain übernommen hat. Dieses Modul behandelt, wie man Active Directory sichert und wieder herstellt. Die Aufgabe ist ernster, als sie klingt, denn das Verzeichnis ist *ein verteiltes System*: Jeder Domain Controller trägt eine Kopie, die Kopien gleichen sich laufend ab (Replikation, Modul 5), und eine zurückgespielte alte Kopie kann dadurch den aktuellen Stand der anderen Domain Controller beschädigen oder von ihnen überschrieben werden. Wer wiederherstellt, muss deshalb zuerst entscheiden, *was* verloren ist (ein Objekt, eine OU, ein einzelner Domain Controller, die ganze Gesamtstruktur) und *welcher Weg* zu diesem Schaden passt.

Die Einteilung lautet grob: Ein gelöschtes Objekt holt man mit dem Papierkorb zurück (Lerneinheit 10.2) oder, wenn es ihn nicht gibt, mit einer autoritativen Wiederherstellung (10.4). Ein ausgefallener Domain Controller wird neu installiert oder mit einer nicht-autoritativen Wiederherstellung aus der Sicherung gebracht (10.3). Ein beschädigter SYSVOL-Ordner wird mit einer gezielten Synchronisation repariert (10.6). Eine zerstörte Gesamtstruktur wird nach einem festen Ablauf neu aufgebaut (10.7). Alles davon muss geübt (10.8) und in einem Notfallhandbuch beschrieben sein (10.9). Zur Grundlage von Replikation, FSMO-Rollen, SYSVOL und Zeit siehe Modul 5 und Modul 6; die Überwachung, die Ausfälle früh meldet, behandelt Modul 11. Die Beispiele laufen in der Laborumgebung `corp.contoso.com` mit `DC01` und `DC02`.

## 10.1 System State Backup

Ein *System-State-Backup* ist die Sicherung der Komponenten, die einen Server als Domain Controller ausmachen. Auf einem Domain Controller gehören dazu die Active-Directory-Datenbank (`ntds.dit`) mit ihren Transaktionsprotokollen, der Ordner SYSVOL, die Registrierung, die Systemdateien, die Daten der Zertifikatsdienste (falls installiert) und die COM+-Klassenregistrierung. Das Besondere: Der System State lässt sich nicht beliebig zusammenstellen. Er wird als Einheit gesichert, damit alle Teile zum selben Zeitpunkt zusammenpassen. Die Sicherung erfolgt über den Schattenkopie-Dienst (Volume Shadow Copy Service, VSS), der einen konsistenten Schnappschuss erzeugt, ohne dass der Domain Controller angehalten werden muss. Die Microsoft-Dokumentation zu den Überlegungen für die Datensicherung von Active Directory Domain Services betont, dass die Sicherung auf den Wiederherstellungsfall hin geplant werden soll und dass nur eine Sicherung, die ein vollständiges Wiederherstellungsverfahren bestanden hat, eine echte Sicherung ist.

Windows Server bringt dafür die *Windows Server-Sicherung* (Windows Server Backup) als Serverfeature mit. Sie wird über die Konsole oder das Befehlszeilenprogramm `wbadmin` bedient. Eine Sicherung des System State erzeugt man mit `wbadmin start systemstatebackup`; die Sicherung ist unabhängig von einer vollständigen Serversicherung und mit nur wenigen Gigabyte meist sehr klein. Wer auch den Server selbst (Betriebssystem, Treiber, Startkonfiguration) sichern möchte, nimmt die Variante für Bare-Metal-Wiederherstellung (`-allCritical`); diese wird gebraucht, wenn die Hardware ersetzt werden muss. Wo Azure Backup im Einsatz ist, kann man den System State des Domain Controllers auch dorthin sichern und wiederherstellen; die Dokumentation zu Azure Backup beschreibt den Ablauf der Systemzustand-Wiederherstellung.

Wie oft und wie viele Domain Controller sichert man? Eine Faustregel: mindestens zwei Domain Controller je Domain, davon wenigstens einer, der die FSMO-Rollen (Modul 6) trägt, sowie je Standort ein weiterer, und das mindestens einmal täglich, in jedem Fall aber öfter als die Tombstone-Lebensdauer (Lerneinheit 10.5) lang ist. Wichtig ist außerdem, wohin die Sicherung geschrieben wird: nicht auf dasselbe Laufwerk, das gesichert wird, und möglichst auf ein Ziel, das von einem Angreifer mit Domänenrechten nicht beschrieben oder gelöscht werden kann (getrennte Anmeldedaten, unveränderlicher Speicher, Offline-Kopie).

Das folgende Skript installiert das Feature, erstellt eine Sicherung des System State, zeigt die vorhandenen Sicherungen und prüft, wie alt die jüngste ist. Es lässt sich als geplante Aufgabe täglich ausführen.

```powershell
# Auf dem Domain Controller (Administrator-PowerShell)

# 1) Feature installieren (einmalig)
Install-WindowsFeature -Name Windows-Server-Backup

# 2) System State auf ein eigenes Sicherungslaufwerk E: sichern
wbadmin start systemstatebackup -backupTarget:E: -quiet

# 3) Vorhandene Sicherungen anzeigen
wbadmin get versions

# 4) Alter der letzten Sicherung pruefen und bei Ueberschreitung warnen
$letzte = (Get-WBSummary).LastSuccessfulBackupTime
$alter  = (Get-Date) - $letzte
"Letzte erfolgreiche Sicherung: $letzte  (vor {0:N1} Tagen)" -f $alter.TotalDays
if ($alter.TotalDays -gt 1) { Write-Warning "Sicherung ist aelter als 24 Stunden!" }

# 5) Als geplante Aufgabe taeglich um 02:00 Uhr einrichten
$aktion = New-ScheduledTaskAction -Execute "wbadmin.exe" -Argument "start systemstatebackup -backupTarget:E: -quiet"
$zeit   = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -TaskName "AD-SystemState-Sicherung" -Action $aktion -Trigger $zeit -User "SYSTEM" -RunLevel Highest
```

Schritt 1 installiert das Feature. Schritt 2 sichert den System State auf das Laufwerk E:; der Schalter `-quiet` unterdrückt die Rückfrage. Beim Ziel ist zu beachten, dass die Sicherung nicht auf ein Laufwerk geschrieben werden darf, das selbst Teil der Sicherung ist; ein eigenes Laufwerk oder eine Freigabe vermeidet das. Schritt 3 listet alle Sicherungsversionen mit Kennung und Datum; die Kennung (ein Zeitstempel im Format `MM/TT/JJJJ-HH:MM`) wird später für die Wiederherstellung gebraucht. Schritt 4 liest mit `Get-WBSummary` den Zeitpunkt der letzten erfolgreichen Sicherung und warnt, wenn sie älter als 24 Stunden ist. Schritt 5 legt die geplante Aufgabe an, die als Systemkonto mit höchsten Rechten täglich um zwei Uhr nachts läuft.

### Typische Fehler und Stolperfallen

Der erste häufige Fehler ist, einen Domain Controller als virtuelle Maschine nur über einen Schnappschuss des Hypervisors zu „sichern“. Ein solcher Schnappschuss ist kein unterstütztes Sicherungsverfahren für Active Directory, wenn er zurückgespielt wird, ohne dass das Betriebssystem davon weiß; die Folge ist ein sogenannter USN-Rollback (siehe Lerneinheit 10.3), bei dem der zurückgesetzte Domain Controller und seine Partner über denselben Änderungszähler unterschiedliche Daten führen. Der zweite Fehler ist, die Sicherung nie zu testen. Der dritte ist, die Sicherung auf einem Laufwerk abzulegen, das derselbe Angreifer mit denselben Rechten löschen kann wie das Verzeichnis selbst.

```powershell
# FALSCH: Sicherung auf das Laufwerk, das selbst gesichert wird, und nie getestet
wbadmin start systemstatebackup -backupTarget:C: -quiet

# RICHTIG: Eigenes Sicherungsziel, danach die Sicherung pruefen
wbadmin start systemstatebackup -backupTarget:E: -quiet
wbadmin get versions
wbadmin get items -version:10/25/2026-02:00
```

> **Ergänzung aus der Nachrecherche**
>
> Die Hinweise zur Planung der Datensicherung von Active Directory, zur Sicherung des System State im Rahmen der Gesamtstruktur-Wiederherstellung und zur Wiederherstellung des Systemzustands mit Azure Backup stützen sich auf die abgerufenen Seiten „Considerations for Active Directory Domain Services backup“, „Active Directory Forest Recovery Guide“ und „Restore System State with Azure Backup“ (Microsoft Learn, nur Suchauszüge). Die genauen `wbadmin`-Parameter, die Inhalte des System State auf einem Domain Controller und die Aussage, dass Hypervisor-Schnappschüsse nicht als Sicherung gelten, stammen aus dem Fachwissen; die VM-GenerationID-Funktion (Lerneinheit 10.3) mildert das Problem, ersetzt aber die Sicherung nicht.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen mit zwei Domain Controllern in einem Rechenzentrum und einem dritten in der Filiale sichert den System State jede Nacht auf ein Laufwerk, das nur das Sicherungskonto beschreiben darf, und kopiert die Sicherung wöchentlich auf ein Band, das im Tresor liegt. Als ein Softwarefehler die Datenbank auf DC01 beschädigt, ist die Wiederherstellung aus der Sicherung vom Vortag in einer Stunde erledigt. Der Administrator ist erleichtert, aber vor allem, dass die Wiederherstellung im Quartal davor geübt wurde.

## 10.2 AD Recycle Bin

Gelöschte Objekte endeten früher in einem Zustand, der Wiederherstellung schwer machte: Beim Löschen eines Benutzers entfernte Active Directory fast alle Attribute und behielt nur ein kleines Gerippe, den sogenannten *Tombstone*. Damit konnte man das Konto zwar zurückholen, aber ohne Gruppenmitgliedschaften, Telefonnummer, Abteilung und alles andere. Der *Active Directory-Papierkorb* (Recycle Bin) löst das: Gelöschte Objekte behalten alle ihre Attribute (auch die verknüpften wie Gruppenmitgliedschaften) und lassen sich vollständig und mit einem einzigen Befehl wieder herstellen.

Der Papierkorb ist ein *optionales Feature* der Gesamtstruktur. Er setzt die Funktionsebene Windows Server 2008 R2 für die Gesamtstruktur voraus. Das Aktivieren gilt für die gesamte Gesamtstruktur und *lässt sich nicht rückgängig machen*; die Microsoft-Dokumentation zum Cmdlet `Enable-ADOptionalFeature` nennt als Beispiel genau diesen Papierkorb. Der Lebenszyklus eines gelöschten Objekts bekommt dadurch eine zusätzliche Phase: Zuerst ist das Objekt *gelöscht* (deleted) und liegt im Container „Deleted Objects“ mit allen Attributen, vollständig wiederherstellbar. Nach Ablauf der *Lebensdauer gelöschter Objekte* (Attribut `msDS-deletedObjectLifetime`, standardmäßig gleich der Tombstone-Lebensdauer, siehe 10.5) wird es zum *recycled object*, hat die meisten Attribute verloren und lässt sich nicht mehr mit allen Daten wiederherstellen. Nach einer weiteren Frist von der Länge der Tombstone-Lebensdauer wird es endgültig vom Garbage Collector entfernt.

Die Wiederherstellung ist mit dem Cmdlet `Restore-ADObject` oder im *Active Directory-Verwaltungscenter* (Active Directory Administrative Center, ADAC) möglich; Letzteres hat den Container „Deleted Objects“ in der Domänenansicht und bietet „Wiederherstellen“ und „Wiederherstellen in“ (an einen anderen Ort) an. Wichtig ist, dass der Papierkorb nur in der Wiederherstellung hilft, nicht gegen Löschen schützt; gegen versehentliches Löschen schützt das Kontrollkästchen „Objekt vor zufälligem Löschen schützen“ auf OUs, das in Modul 3 behandelt wurde.

```powershell
Import-Module ActiveDirectory

# 1) Voraussetzung pruefen: Funktionsebene der Gesamtstruktur (mind. Windows2008R2Forest)
(Get-ADForest).ForestMode

# 2) Papierkorb aktivieren - Gesamtstruktur-weit, NICHT rueckgaengig zu machen
Enable-ADOptionalFeature -Identity "Recycle Bin Feature" `
    -Scope ForestOrConfigurationSet -Target "corp.contoso.com" -Confirm:$true

# 3) Testlauf: Testbenutzer anlegen, Gruppe zuordnen, loeschen
New-ADUser -Name "Test Papierkorb" -SamAccountName "t.papierkorb" -Path "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" -Enabled $false
Add-ADGroupMember -Identity "G-Helpdesk" -Members "t.papierkorb"
Remove-ADUser -Identity "t.papierkorb" -Confirm:$false

# 4) Geloeschte Objekte der letzten Tage anzeigen
Get-ADObject -Filter 'isDeleted -eq $true -and Name -like "Test*"' -IncludeDeletedObjects `
    -Properties lastKnownParent, whenChanged | Select-Object Name, lastKnownParent, whenChanged, DistinguishedName

# 5) Wiederherstellen - mit allen Attributen und Gruppenmitgliedschaften
Get-ADObject -Filter 'isDeleted -eq $true -and samAccountName -eq "t.papierkorb"' -IncludeDeletedObjects |
    Restore-ADObject

# 6) Pruefen
Get-ADUser "t.papierkorb" -Properties MemberOf | Select-Object Name, Enabled, MemberOf
```

Schritt 1 prüft die Voraussetzung. Schritt 2 aktiviert das Feature; dabei fragt PowerShell wegen der Unumkehrbarkeit nach. Die Schritte 3 bis 6 sind ein Testlauf, den man vor dem Ernstfall durchführen sollte: Er legt einen Benutzer an, gibt ihm eine Gruppenmitgliedschaft und löscht ihn. Schritt 4 zeigt, dass das gelöschte Objekt über `-IncludeDeletedObjects` auffindbar ist; das Attribut `lastKnownParent` verrät, in welcher OU es lag. Schritt 5 holt das Objekt zurück, und Schritt 6 bestätigt, dass die Gruppenmitgliedschaft wieder da ist. Soll das Objekt nicht in seine alte OU zurückkehren (etwa weil die OU selbst gelöscht wurde), nutzt man `Restore-ADObject -TargetPath "OU=..."`; wurde eine ganze OU gelöscht, stellt man zuerst die OU und danach ihren Inhalt wieder her.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, den Papierkorb nicht zu aktivieren, weil „es nie vorkommt“: Er kostet fast nichts, aber ohne ihn bleibt nur die aufwendige autoritative Wiederherstellung. Der zweite ist, die Fristen zu übersehen: Nach der Lebensdauer ist das Objekt recycled, und der Papierkorb hilft nicht mehr. Der dritte ist, ein Objekt wiederherzustellen, dessen übergeordnete OU ebenfalls gelöscht wurde; die Wiederherstellung scheitert mit einer Fehlermeldung, bis die OU zuerst zurückgeholt ist.

```powershell
# FALSCH: Objekt zuerst ohne Pruefung wiederherstellen, obwohl die uebergeordnete OU geloescht ist
Get-ADObject -Filter 'isDeleted -eq $true -and Name -like "Max*"' -IncludeDeletedObjects | Restore-ADObject

# RICHTIG: Erst die OU, dann ihren Inhalt (Reihenfolge nach DN-Laenge)
Get-ADObject -Filter 'isDeleted -eq $true -and Name -like "Benutzer*"' -IncludeDeletedObjects | Restore-ADObject
Get-ADObject -Filter 'isDeleted -eq $true -and Name -like "Max*"' -IncludeDeletedObjects | Restore-ADObject
```

> **Ergänzung aus der Nachrecherche**
>
> Dass der Papierkorb ein optionales Feature ist, das mit `Enable-ADOptionalFeature` für die gesamte Gesamtstruktur aktiviert wird, stützt sich auf die abgerufenen Seiten „Enable-ADOptionalFeature“, „Advanced AD DS Management Using Active Directory Administrative Center“ und „Restore deleted accounts and groups in Active Directory“ (Microsoft Learn, Suchauszüge). Die Funktionsebene 2008 R2, die Phasen des Lebenszyklus (deleted, recycled), das Attribut `msDS-deletedObjectLifetime` und der Parameter `-TargetPath` stammen aus dem Fachwissen.

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Mitarbeiterin im Helpdesk löscht beim Aufräumen versehentlich die OU „Vertrieb“ mit 40 Konten, weil der Schutz vor versehentlichem Löschen zuvor für eine Migration entfernt wurde. Mit aktiviertem Papierkorb dauert die Rettung zehn Minuten: erst die OU, dann alle Objekte darunter mit `Restore-ADObject`, Gruppenmitgliedschaften inklusive. Ohne Papierkorb hätte es einen Neustart im DSRM und eine autoritative Wiederherstellung bedeutet, mit Stillstand für den betroffenen Domain Controller.

## 10.3 Non-authoritative Restore

Bei der *nicht-autoritativen Wiederherstellung* (Non-authoritative Restore) wird ein Domain Controller aus der Sicherung zurückgeholt und danach durch die normale Replikation von seinen Partnern auf den aktuellen Stand gebracht. Der Begriff „nicht autoritativ“ bedeutet, dass die wiederhergestellten Daten *keine Vorrangstellung* haben: Was die anderen Domain Controller inzwischen geändert haben, setzt sich durch. Das ist der Standardfall, etwa nach einem Hardwaredefekt oder einer beschädigten Datenbank, und die Microsoft-Dokumentation zur Gesamtstruktur-Wiederherstellung beschreibt dieses Verfahren als den Weg, einen Domain Controller wieder in Betrieb zu nehmen, wenn andere intakte Domain Controller existieren.

Der Ablauf hat feste Schritte. Der Domain Controller wird im *Verzeichnisdienst-Wiederherstellungsmodus* (Directory Services Restore Mode, DSRM) gestartet. Das ist ein spezieller Startmodus, in dem die Active-Directory-Datenbank nicht geladen wird, sodass sie überschrieben werden kann. Der Anmeldename im DSRM ist ein lokales Konto (`.\Administrator`) mit dem bei der Heraufstufung festgelegten DSRM-Kennwort, nicht das Domänenkennwort; dieses Kennwort sollte deshalb dokumentiert oder mit Windows LAPS verwaltet werden (Modul 9). Im DSRM wird der System State mit `wbadmin` zurückgespielt, danach startet der Server normal und fragt die Partner nach allen Änderungen seit der Sicherung. Für den SYSVOL-Ordner gilt dabei: Bei einer nicht-autoritativen Wiederherstellung kommt der Inhalt von den Partnern (Lerneinheit 10.6).

Eine wichtige Gefahr sind *virtuelle Domain Controller*. Wird eine VM aus einem Schnappschuss zurückgesetzt, ohne dass das Betriebssystem es merkt, nutzt der Domain Controller wieder Änderungsnummern (USNs), die er schon einmal vergeben hat; die Partner halten sie für bereits repliziert und ignorieren die neuen Änderungen. Das nennt man *USN-Rollback*, und die Folge sind Verzeichniskopien, die auseinanderlaufen, ohne dass dies jemand sofort bemerkt. Windows Server 2012 und neuer verwenden dagegen die *VM-GenerationID*: Der Hypervisor stellt dem Gast eine Kennung bereit, die sich bei Schnappschuss-Rücksetzungen ändert; der Domain Controller erkennt die Änderung, verwirft seine Invocation-ID und synchronisiert sich neu, womit der Rollback verhindert wird. Dazu müssen Hypervisor und Gast diese Funktion unterstützen (die Dokumentation zu virtualisierten Domain Controllern beschreibt die Architektur und die Fehlersuche).

```powershell
# Auf dem wiederherzustellenden Domain Controller (Beispiel DC02)

# 1) Naechsten Start im Verzeichnisdienst-Wiederherstellungsmodus (DSRM) festlegen und neu starten
bcdedit /set safeboot dsrepair
shutdown /r /t 0

# --- Nach dem Neustart: Anmeldung als .\Administrator mit dem DSRM-Kennwort ---

# 2) Verfuegbare Sicherungen anzeigen und eine Version auswaehlen
wbadmin get versions

# 3) System State zurueckspielen (Version aus Schritt 2 einsetzen)
wbadmin start systemstaterecovery -version:10/24/2026-02:00 -quiet

# 4) DSRM-Startmarke entfernen und normal neu starten
bcdedit /deletevalue safeboot
shutdown /r /t 0

# --- Nach dem normalen Start: Replikation und Zustand pruefen ---

# 5) Replikation mit den Partnern pruefen und anstossen
repadmin /replsummary
repadmin /syncall /AdeP
dcdiag /test:replications /test:advertising /test:services
```

Schritt 1 setzt die Startoption `safeboot dsrepair`, die den Domain Controller beim nächsten Start in den DSRM bringt. Schritt 2 listet die Sicherungen; es wird die jüngste verwendet, die vor dem Fehler liegt. Schritt 3 spielt den System State zurück und überschreibt dabei die Datenbank; der Vorgang kann je nach Größe lange dauern. Schritt 4 entfernt die Startmarke, sonst startet der Server bei jedem Neustart wieder im DSRM. Schritt 5 prüft nach dem Start mit `repadmin /replsummary` den Zustand der Replikation und stößt mit `/syncall /AdeP` die Synchronisation an (alle Partner, alle Namenskontexte, über Standortgrenzen hinweg, mit Meldungen); `dcdiag` bestätigt, dass der Domain Controller seine Dienste anbietet. Wie diese Werkzeuge im Alltag eingesetzt werden, zeigt Modul 11.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, das DSRM-Kennwort nicht zu kennen. Es lässt sich im laufenden Betrieb mit `ntdsutil` (`set dsrm password`) neu festlegen; ohne Kennwort und ohne Möglichkeit, es zurückzusetzen, ist die Wiederherstellung unmöglich. Der zweite Fehler ist, eine zu alte Sicherung zu nehmen (älter als die Tombstone-Lebensdauer, siehe 10.5). Der dritte ist, die Startmarke `safeboot` nicht zu entfernen. Der vierte ist, auf einem virtuellen Domain Controller einen Schnappschuss zurückzuspielen, statt aus der Sicherung wiederherzustellen.

```powershell
# FALSCH: Virtuellen Domain Controller per Hypervisor-Schnappschuss zuruecksetzen (Gefahr USN-Rollback)
# (Aktion in der Verwaltung des Hypervisors: "Auf Pruefpunkt zuruecksetzen")

# RICHTIG: Aus der Sicherung im DSRM wiederherstellen oder den Domain Controller neu heraufstufen
bcdedit /set safeboot dsrepair
wbadmin start systemstaterecovery -version:10/24/2026-02:00 -quiet
```

> **Ergänzung aus der Nachrecherche**
>
> Das Verfahren zur nicht-autoritativen Wiederherstellung innerhalb der Gesamtstruktur-Wiederherstellung und die Architektur der VM-GenerationID mit der Verhinderung des USN-Rollbacks stützen sich auf die abgerufenen Seiten „AD Forest Recovery - Perform a nonauthoritative restore“, „Virtualized domain controller architecture“ und „Virtualized domain controller troubleshooting“ (Microsoft Learn, Suchauszüge). Die konkreten Befehle (`bcdedit`, `wbadmin start systemstaterecovery`, `repadmin`-Schalter) stammen aus dem Fachwissen und sind im Labor zu testen. Die Variante, den Domain Controller nach einem Totalausfall einfach neu heraufzustufen statt wiederherzustellen, ist in der Praxis oft schneller, wenn andere gesunde Domain Controller vorhanden sind.

### Praxisbezug

> **Praxisbeispiel**
>
> Nach einem Festplattenausfall auf DC02 entscheidet sich das Team zunächst gegen die Wiederherstellung und für eine Neuinstallation: Der Server wird neu aufgesetzt, zum Domain Controller heraufgestuft und holt sich alle Daten von DC01. Das dauert nur eine Stunde und vermeidet das Risiko alter Daten. Die Wiederherstellung aus der Sicherung bleibt für Fälle reserviert, in denen es keinen anderen gesunden Domain Controller gibt oder die FSMO-Rollen schnell wieder verfügbar sein müssen.

## 10.4 Authoritative Restore

Die *autoritative Wiederherstellung* ist der Ausnahmefall: Man möchte, dass ein bestimmter Teil der wiederhergestellten Daten *gewinnt*, auch gegen den aktuellen Stand auf den anderen Domain Controllern. Der Anlass ist fast immer ein versehentlich gelöschtes Objekt oder Teilbaum, wenn der Papierkorb nicht aktiviert ist oder die Fristen abgelaufen sind. Würde man nur eine nicht-autoritative Wiederherstellung durchführen, würden die Partner dem wiederhergestellten Domain Controller die Löschung einfach erneut mitteilen, und das Objekt verschwände sofort wieder. Deshalb muss der Wiederhergestellte Stand *als neuer* markiert werden.

Technisch geschieht das über die Versionsnummern der Attribute. Jede Änderung an einem Attribut erhöht eine Versionsnummer, und bei der Replikation gewinnt der höhere Wert. Das Werkzeug `ntdsutil` erhöht die Versionsnummern der betroffenen Objekte in der wiederhergestellten Datenbank um einen großen Betrag (standardmäßig 100 000 je Tag seit der Sicherung), sodass diese Werte höher sind als alles, was die Partner kennen, und bei der nächsten Replikation auf alle anderen Domain Controller verteilt werden. Für Gruppenmitgliedschaften und andere verknüpfte Attribute erzeugt `ntdsutil` zusätzlich eine LDIF-Datei, die man mit `ldifde` auf einem aktuellen Domain Controller importiert, damit die Rückverweise auf die wiederhergestellten Objekte stimmen.

Die Ablaufreihenfolge ist: Erst wird der Domain Controller im DSRM aus der Sicherung wiederhergestellt (wie in 10.3), dann *vor dem Neustart* die autoritative Markierung für das Objekt oder den Teilbaum gesetzt, dann normal gestartet. Der Domain Controller repliziert die markierten Objekte nun an die Partner. Die Microsoft-Dokumentation unterscheidet das autoritative Wiederherstellen eines einzelnen Objekts oder Teilbaums (`restore object`, `restore subtree`) und die seltenere Wiederherstellung einer ganzen Partition (`restore database`).

```powershell
# Auf dem Domain Controller im DSRM, NACH der Wiederherstellung des System State (wbadmin) und VOR dem Neustart

ntdsutil
activate instance ntds
authoritative restore
restore subtree "OU=Vertrieb,OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com"
quit
quit

# Ntdsutil meldet die Zahl der markierten Objekte und legt eine LDIF-Datei an, z. B.:
#   ar_20261025-021500_links_corp.contoso.com.ldf

# Danach normal starten:
bcdedit /deletevalue safeboot
shutdown /r /t 0

# Nach dem Start (im normalen Betrieb) die Rueckverweise (Gruppenmitgliedschaften) einspielen:
ldifde -i -k -f ar_20261025-021500_links_corp.contoso.com.ldf

# Pruefen, ob die Objekte repliziert wurden
repadmin /syncall /AdeP
Get-ADUser -Filter * -SearchBase "OU=Vertrieb,OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" | Measure-Object
```

Der Block beginnt im interaktiven `ntdsutil`: `activate instance ntds` wählt die Active-Directory-Datenbank, `authoritative restore` wechselt in den entsprechenden Modus und `restore subtree` markiert eine OU samt Inhalt. Zwei `quit` beenden das Programm. Für ein einzelnes Objekt nimmt man `restore object` mit dem vollständigen Distinguished Name. Nach dem Neustart wird die erzeugte LDIF-Datei mit `ldifde -i -k -f` importiert; `-i` bedeutet Import, `-k` ignoriert bereits vorhandene Einträge und Konstraint-Fehler. Zuletzt wird per Synchronisation und Zählung geprüft, dass die Objekte da sind.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, zu viel autoritativ wiederherzustellen. Wer die ganze Domain markiert, überschreibt alle Änderungen, die seit der Sicherung gemacht wurden, auf allen Domain Controllern: neue Konten, geänderte Kennwörter, Gruppenmitgliedschaften. Der zweite ist, die LDIF-Datei zu vergessen: Die Benutzer sind dann zwar zurück, aber ohne ihre Gruppenmitgliedschaften. Der dritte ist, die Sicherung auf einem Domain Controller auszuführen, der sofort wieder repliziert, bevor die Markierung gesetzt ist.

```powershell
# FALSCH: Ganze Domaenen-Partition autoritativ, um eine einzelne OU zurueckzuholen
ntdsutil "activate instance ntds" "authoritative restore" "restore database" quit quit

# RICHTIG: Nur die betroffene OU markieren
ntdsutil "activate instance ntds" "authoritative restore" "restore subtree \"OU=Vertrieb,OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com\"" quit quit
```

> **Ergänzung aus der Nachrecherche**
>
> Das Konzept der autoritativen Wiederherstellung, die Notwendigkeit des DSRM und der Zweck der Ntdsutil-Befehle werden in den abgerufenen Seiten zur Wiederherstellung gelöschter Konten und Gruppen in Active Directory („Restore deleted accounts and groups in Active Directory“) und zur Gesamtstruktur-Wiederherstellung beschrieben (Microsoft Learn, Suchauszüge). Die Erhöhung um 100 000 je Tag, die Erzeugung der LDIF-Datei und die genauen Schalter von `ldifde` stammen aus dem Fachwissen und sollten im Labor überprüft werden.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Administrator hat in einem Skript einen Filter falsch gesetzt und 200 Benutzer einer Abteilung gelöscht; der Papierkorb war nicht aktiviert. Das Team stellt DC02 vom Vortag im DSRM wieder her, markiert die OU autoritativ, startet neu und spielt die LDIF-Datei ein. Nach einer Stunde sind die Konten samt Gruppenmitgliedschaften zurück. Als Lehre aus dem Vorfall aktiviert das Team den Papierkorb und führt für Massenänderungen ein Vier-Augen-Prinzip ein.

## 10.5 Tombstone Lifetime

Wenn ein Objekt gelöscht wird, kann Active Directory es nicht einfach aus der Datenbank entfernen, denn die anderen Domain Controller müssen vom Löschen erfahren. Deshalb wird das Objekt zuerst als gelöscht markiert (der Tombstone) und diese Information repliziert. Erst nach der *Tombstone-Lebensdauer* (Tombstone Lifetime) räumt der Garbage Collector den Tombstone endgültig weg. Der Wert ist im Attribut `tombstoneLifetime` des Objekts „Directory Service“ in der Konfigurationspartition gespeichert und beträgt in einer neu erstellten Gesamtstruktur 180 Tage; in sehr alten Gesamtstrukturen (vor Windows Server 2003 mit Service Pack 1) waren es 60 Tage.

Die Frist hat zwei weitreichende Folgen. Erstens: Eine Sicherung ist nur so lange brauchbar, wie sie jünger als die Tombstone-Lebensdauer ist. Eine ältere Sicherung kennt Objekte, die inzwischen gelöscht und endgültig entfernt wurden. Würde man sie zurückspielen, trägt dieser Domain Controller Objekte, die auf den anderen Domain Controllern nicht mehr existieren und für die die Löschmeldung nicht mehr verteilt wird: sogenannte *Lingering Objects* (abgelaufene Objekte). Sie können sich später über die Replikation wieder verbreiten oder die Replikation mit Fehlermeldungen (zum Beispiel Ereignis 1988 oder 2042) blockieren. Zweitens: Ein Domain Controller, der länger als die Tombstone-Lebensdauer nicht repliziert hat (zum Beispiel ein Server in einer Filiale, der drei Monate im Schrank lag), darf nicht einfach wieder ans Netz. Er kennt die Löschungen nicht mehr und würde Lingering Objects einschleppen. Windows blockiert in solchen Fällen die Replikation (Ereignis 2042, die strikte Replikationskonsistenz ist standardmäßig aktiv).

Die Lebensdauer lässt sich anzeigen und ändern, wobei die Änderung selten sinnvoll ist: Verkürzt man den Wert, werden Sicherungen früher unbrauchbar. Verlängert man ihn, bleiben Tombstones länger in der Datenbank. Wichtig ist, dass die Sicherungsstrategie die Lebensdauer einhält. Die Reparatur von Lingering Objects geschieht mit `repadmin /removelingeringobjects`, wobei man einen Referenz-Domain-Controller angibt, der den aktuellen Stand kennt; mit der Option `/advisory_mode` lässt sich vorher prüfen, was gelöscht würde. Die Microsoft-Dokumentation zur Fehlerbehebung beschreibt genau diese Fälle (Ereignisse 1388, 1988, 2042 und die Fehlercodes 8453, 8606).

```powershell
Import-Module ActiveDirectory
$cfg = (Get-ADRootDSE).configurationNamingContext

# 1) Tombstone-Lebensdauer und Lebensdauer geloeschter Objekte anzeigen
Get-ADObject "CN=Directory Service,CN=Windows NT,CN=Services,$cfg" -Properties tombstoneLifetime, 'msDS-DeletedObjectLifetime' |
    Select-Object tombstoneLifetime, 'msDS-DeletedObjectLifetime'

# 2) Alter der letzten Sicherung gegen die Lebensdauer pruefen
$tsl = (Get-ADObject "CN=Directory Service,CN=Windows NT,CN=Services,$cfg" -Properties tombstoneLifetime).tombstoneLifetime
if (-not $tsl) { $tsl = 60 }          # nicht gesetzt: aelterer Standardwert
$alt = ((Get-Date) - (Get-WBSummary).LastSuccessfulBackupTime).TotalDays
"Tombstone-Lebensdauer: $tsl Tage, letzte Sicherung: {0:N0} Tage alt" -f $alt

# 3) Wann hat jeder Domain Controller zuletzt erfolgreich repliziert? (Alter in Tagen)
Get-ADReplicationPartnerMetadata -Target (Get-ADDomainController -Filter *).HostName -Scope Server |
    Select-Object Server, Partner, LastReplicationSuccess,
        @{n="TageSeit";e={[math]::Round(((Get-Date)-$_.LastReplicationSuccess).TotalDays,1)}} |
    Sort-Object TageSeit -Descending | Format-Table -AutoSize

# 4) Lingering Objects: erst nur pruefen (Advisory Mode), dann loeschen
repadmin /removelingeringobjects DC02.corp.contoso.com <GUID-von-DC01> "DC=corp,DC=contoso,DC=com" /advisory_mode
```

Schritt 1 liest die zwei Werte aus der Konfigurationspartition. Ist `tombstoneLifetime` nicht gesetzt, gilt der ältere Standard von 60 Tagen, was Schritt 2 berücksichtigt; er vergleicht das Alter der letzten Sicherung mit der Frist und ist eine einfache Plausibilitätsprüfung. Schritt 3 zeigt für jeden Domain Controller, wann er zuletzt von welchem Partner erfolgreich replizierte; Werte in der Nähe der Tombstone-Lebensdauer sind alarmierend. Schritt 4 zeigt den Aufruf zur Prüfung von Lingering Objects; die Platzhalter `<GUID-von-DC01>` (die Objekt-GUID des DSA-Objekts des Referenz-Domain-Controllers) müssen durch den echten Wert ersetzt werden, und die Zeile ist bewusst kein ausführbarer Befehl, bevor man sie angepasst hat.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, einen lange abgeschalteten Domain Controller einfach wieder einzuschalten. Der zweite ist, dass niemand die Tombstone-Lebensdauer kennt, wenn er die Aufbewahrung der Sicherungen plant (zum Beispiel archiviert man Sicherungen ein Jahr lang und glaubt, sie seien für die Wiederherstellung brauchbar). Der dritte ist, die strikte Replikationskonsistenz zu deaktivieren, um die Fehlermeldung loszuwerden; dadurch wandern Lingering Objects ungehindert in die Datenbank.

```powershell
# FALSCH: Domain Controller nach 8 Monaten Stillstand einfach starten und Replikationsfehler "abschalten"
repadmin /regkey * +allowDivergent

# RICHTIG: Server entfernen (Metadatenbereinigung) und neu heraufstufen
dcpromo /forceremoval                       # alte Methode; moderne: Uninstall-ADDSDomainController -ForceRemoval
# danach: Metadaten bereinigen, Server neu installieren und heraufstufen
```

> **Ergänzung aus der Nachrecherche**
>
> Die Folgen abgelaufener Tombstones, Lingering Objects und die Fehlerbilder (Ereignisse 1388, 1988, 2042, Fehlercodes 8453 und 8606) werden in den abgerufenen Seiten „Information about lingering objects in a Windows Server Active Directory forest“, „Active Directory replication Event ID 1388/1988“, „Event ID 2042“ und „Troubleshoot AD replication error 8606“ (Microsoft Learn, Suchauszüge) beschrieben. Die abgerufene Seite zu Lingering Objects nennt als Standard für alle derzeit unterstützten Windows-Server-Versionen 180 Tage, weist darauf hin, dass der Wert vom Betriebssystem des ersten Domain Controllers der Gesamtstruktur abhängt und bei Upgrades unverändert bleibt; die Seite zum Ereignis 2042 spricht von 60 bis 180 Tagen. Dort sind auch die Optionen bei Ereignis 2042 (Domain Controller herabstufen oder neu installieren, Lingering Objects mit `repadmin /removelingeringobjects` entfernen, Replikation fortsetzen), der Advisory-Modus, der Registrywert für die strikte Replikationskonsistenz und das Werkzeug Lingering Object Liquidator v2 beschrieben; die Fehlerseite zu 8606 empfiehlt, Domain Controller, die länger als 50 Prozent der Tombstone-Lebensdauer nicht repliziert haben, auf eine Beobachtungsliste zu setzen und solche, die 90 Prozent überschreiten, zwangsweise herabzustufen. Der Ablageort des Werts und die weiteren Schalter von `repadmin` stammen teils aus dem Fachwissen; bitte vor dem Einsatz im Labor prüfen.

### Praxisbezug

> **Praxisbeispiel**
>
> Bei der Aufräumaktion nach einem Umzug findet das Team einen Domain Controller in einem alten Schaltschrank, der seit 14 Monaten ausgeschaltet war. Statt ihn einzuschalten, wird er von der Domäne entfernt und seine Metadaten bereinigt. In der Prüfung zeigt sich, dass die Sicherungen der Filiale zwei Jahre lang aufbewahrt wurden; seit dem Gespräch gilt die Regel, dass die Sicherungen mindestens so oft erneuert werden, wie es die Tombstone-Lebensdauer verlangt, und dass ältere Stände nur für Dateien, nicht für das Verzeichnis nützlich sind.

## 10.6 SYSVOL Restore

Der Ordner SYSVOL liegt auf jedem Domain Controller und enthält die Gruppenrichtlinien (die Vorlagen unter `Policies`) und die Anmeldeskripte (`Scripts`); er wird über die Freigaben `SYSVOL` und `NETLOGON` bereitgestellt. Weil er für die Anwendung von Gruppenrichtlinien auf jedem Client gebraucht wird, ist ein defekter oder leerer SYSVOL ein ernster Ausfall: Anmeldungen werden langsam, Richtlinien greifen nicht, und die Meldung „Die Netzwerkanmeldung ist fehlgeschlagen“ oder fehlende Freigaben `SYSVOL` und `NETLOGON` sind die typischen Zeichen. Die Aufgabe dieser Lerneinheit ist, SYSVOL wieder in einen konsistenten Zustand zu bringen. Wie SYSVOL aufgebaut ist und mit DFSR repliziert wird, steht in Modul 6; hier geht es um die Wiederherstellung.

Zu unterscheiden sind zwei Replikationsverfahren. Die Domänen, die seit Windows Server 2008 im Domänenfunktionsebene 2008 oder höher laufen und von FRS auf DFSR migriert wurden, replizieren SYSVOL mit *DFSR* (Distributed File System Replication). Ältere Domänen verwenden den *File Replication Service* (FRS), der heute als veraltet gilt und in neueren Windows-Server-Versionen nicht mehr unterstützt wird. Die Wiederherstellungsverfahren hängen davon ab: Bei FRS steuert man die Wiederherstellung über den Registrywert `BurFlags` (D2 für nicht-autoritativ, D4 für autoritativ). Bei DFSR gibt es dazu zwei Attribute am Replikationsobjekt des Domain Controllers im Verzeichnis: `msDFSR-Enabled` und `msDFSR-Options`. Ob ein Domain Controller schon auf DFSR migriert ist, prüft man mit `dfsrmig /getglobalstate`.

Die *nicht-autoritative Synchronisation* ist der Normalfall: Ein Domain Controller verliert seinen SYSVOL (Ordner fehlt, ist beschädigt oder leer) und soll den Inhalt von einem Partner erhalten. Die Microsoft-Dokumentation zur Erzwingung einer autoritativen und nicht-autoritativen Synchronisation beschreibt den Ablauf: Man deaktiviert die DFSR-Mitgliedschaft des betroffenen Domain Controllers (`msDFSR-Enabled` auf FALSE), lässt die Änderung im Verzeichnis replizieren, startet den DFSR-Dienst neu, setzt den Wert wieder auf TRUE und fordert den Dienst auf, die Konfiguration neu einzulesen (`dfsrdiag pollad`). Ereignis 4114 meldet dann, dass die Replikation des Ordners deaktiviert wurde, 4614 den Beginn der Anfangssynchronisation und 4604 deren erfolgreichen Abschluss.

Die *autoritative Synchronisation* ist nötig, wenn ein SYSVOL auf einem bestimmten Domain Controller als einziger korrekter Stand gelten soll, zum Beispiel nach dem Löschen von Gruppenrichtlinien oder bei der Wiederherstellung der ersten Domain Controller einer Domäne aus der Sicherung. Dann wird zusätzlich auf dem autoritativen Domain Controller `msDFSR-Options` auf 1 gesetzt, und die Domain Controller, die abgeglichen werden sollen, werden wie eben beschrieben nicht-autoritativ synchronisiert. Eine autoritative Synchronisation überschreibt Änderungen auf den anderen Domain Controllern; man verwendet sie so selten wie möglich.

```powershell
Import-Module ActiveDirectory

# 0) Zustand pruefen: Freigaben vorhanden? Replikationsstatus? Migrationsstand?
net share | Select-String "SYSVOL|NETLOGON"
dfsrmig /getglobalstate
dfsrdiag replicationstate
Get-WinEvent -FilterHashtable @{LogName="DFS Replication"; Id=4114,4604,4614,4602,2213} -MaxEvents 15 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, Message

# 1) NICHT-AUTORITATIV fuer DC02: DFSR-Mitgliedschaft deaktivieren
$dom  = (Get-ADDomain).DistinguishedName
$dc   = "DC02"
$obj  = "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$dc,OU=Domain Controllers,$dom"
Set-ADObject -Identity $obj -Replace @{ "msDFSR-Enabled" = $false }
repadmin /syncall /AdeP                      # Aenderung an alle Domain Controller verteilen

# 2) Auf DC02: Dienst anhalten, Mitgliedschaft wieder aktivieren, Konfiguration einlesen
Stop-Service DFSR
Set-ADObject -Identity $obj -Replace @{ "msDFSR-Enabled" = $true }
repadmin /syncall /AdeP
Start-Service DFSR
dfsrdiag pollad

# 3) Ergebnis pruefen: Ereignis 4614 (Anfang) und 4604 (Ende), Freigaben, Inhalt
Get-WinEvent -FilterHashtable @{LogName="DFS Replication"; Id=4614,4604} -MaxEvents 5 | Select-Object TimeCreated, Id
net share | Select-String "SYSVOL|NETLOGON"
Get-ChildItem "C:\Windows\SYSVOL\domain\Policies" | Measure-Object

# 4) AUTORITATIV (Ausnahme!): auf dem Quell-Domain-Controller zusaetzlich msDFSR-Options = 1 setzen,
#    waehrend msDFSR-Enabled = FALSE ist; die uebrigen Domain Controller wie in Schritt 1 und 2 behandeln.
Set-ADObject -Identity "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=DC01,OU=Domain Controllers,$dom" `
    -Replace @{ "msDFSR-Options" = 1 }
```

Schritt 0 sammelt die Ausgangslage: Sind die Freigaben da, wie ist der Migrationszustand, und welche DFSR-Ereignisse gab es zuletzt. Schritt 1 baut den Distinguished Name des SYSVOL-Abonnements von DC02 auf. Dieses Objekt liegt unter dem Objekt des Domain Controllers und bestimmt, ob er an der Replikation teilnimmt; mit `msDFSR-Enabled` gleich FALSE verlässt er sie, und `repadmin /syncall` verteilt die Änderung an alle Domain Controller, damit sie davon wissen. Schritt 2 hält den Dienst an, aktiviert die Mitgliedschaft wieder und startet den Dienst; `dfsrdiag pollad` zwingt ihn, die Konfiguration aus dem Verzeichnis neu einzulesen und die Anfangssynchronisation zu beginnen. Schritt 3 prüft Erfolg an den Ereignissen, den Freigaben und dem Inhalt des Ordners `Policies`. Schritt 4 zeigt die autoritative Variante in Kurzform; sie ist mit Vorsicht zu verwenden, weil sie auf allen anderen Domain Controllern den Stand überschreibt. Die Namen im Objektpfad entsprechen der Standardstruktur und sollten im Verzeichnis (zum Beispiel mit ADSI Edit) kontrolliert werden.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, SYSVOL auf Dateiebene zu „reparieren“: Man kopiert Ordner von einem Domain Controller auf den anderen. Das umgeht die Replikation, verursacht Versionskonflikte und lässt DFSR in einen Zustand wechseln, in dem es die Dateien als geändert erkennt und verschiebt (Ordner `ConflictAndDeleted`, `PreExisting`). Der zweite ist, eine autoritative Synchronisation zu starten, wo eine nicht-autoritative genügt hätte. Der dritte ist, bei einem Domain Controller, dessen SYSVOL-Freigabe fehlt, nach einem Fehler in der DNS- oder Zeit-Konfiguration zu suchen, ohne die Ereignisse im Protokoll „DFS Replication“ zu lesen. Der vierte ist, ein altes FRS-Handbuch (BurFlags) auf eine DFSR-Domäne anzuwenden.

```powershell
# FALSCH: SYSVOL von Hand kopieren
robocopy \\DC01\SYSVOL\corp.contoso.com C:\Windows\SYSVOL\domain /MIR

# RICHTIG: Den Domain Controller nicht-autoritativ per DFSR neu synchronisieren (siehe oben)
Set-ADObject -Identity $obj -Replace @{ "msDFSR-Enabled" = $false }
# ... Replikation abwarten, dann wieder aktivieren und "dfsrdiag pollad"
```

> **Ergänzung aus der Nachrecherche**
>
> Den Ablauf der nicht-autoritativen und der autoritativen DFSR-Synchronisation, die Rolle von `msDFSR-Enabled` und `msDFSR-Options` sowie die Ereignisse 4114, 4614 und 4604 beschreibt die abgerufene Seite „Force authoritative and non-authoritative synchronization for DFSR-replicated sysvol replication“ (Microsoft Learn, Suchauszug). Ebenfalls abgerufen wurden die Seiten zu fehlenden SYSVOL- und NETLOGON-Freigaben, zum Zurücksetzen von FRS mit `BurFlags` und zur Sicherung und Wiederherstellung eines FRS-replizierten SYSVOL (Auszüge). Die vollständigen Objektpfade und die Ereignis-ID 4602 stammen aus dem Fachwissen. FRS wird nur noch für sehr alte Umgebungen erwähnt; in aktuellen Domänen ist DFSR Standard.

### Praxisbezug

> **Praxisbeispiel**
>
> Nach einem Stromausfall meldet der Domain Controller in der Filiale, dass seine Freigaben `SYSVOL` und `NETLOGON` nicht vorhanden sind; Clients der Filiale bekommen keine Gruppenrichtlinien. Das Team liest im DFSR-Protokoll, dass die Datenbank nach dem Absturz als nicht vertrauenswürdig markiert wurde. Statt Dateien zu kopieren, führt es die nicht-autoritative Synchronisation durch: Nach 20 Minuten erscheint das Ereignis 4604, die Freigaben sind wieder da, und die Richtlinien greifen wieder.

## 10.7 Forest Recovery

Die *Gesamtstruktur-Wiederherstellung* (Forest Recovery) ist der schlimmste Fall: Es ist kein Domain Controller mehr da, dem man trauen kann. Das ist der Fall bei einem Angriff mit Verschlüsselungs-Schadsoftware auf alle Domain Controller, bei einer bösartigen Änderung, die sich über die Replikation überall verbreitet hat (ein Skript hat das Schema zerstört, ein Angreifer hat Hintertüren in die Konfiguration gesetzt), oder bei einem Ausfall des ganzen Rechenzentrums. Die Microsoft-Dokumentation hat dafür einen eigenen *Forest Recovery Guide*, der Schritt für Schritt beschreibt, wie man ihn vorbereitet, durchführt und prüft. Er beginnt mit der Feststellung, ob eine Gesamtstruktur-Wiederherstellung überhaupt nötig ist: Die Ursache muss feststehen, und Ausfälle, die durch einzelne Domain Controller, den Papierkorb oder eine autoritative Wiederherstellung zu beheben sind, rechtfertigen den Aufwand nicht.

Der Grundgedanke ist, die Gesamtstruktur von einem *einzigen* Domain Controller je Domain aus neu aufzubauen. In jeder Domain der Gesamtstruktur wird ein Domain Controller aus einer vertrauenswürdigen Sicherung wiederhergestellt, die vor dem Ereignis liegt. Ab diesem Punkt gilt: Er ist die Quelle der Wahrheit. Alle anderen Domain Controller werden entweder neu installiert oder bereinigt und danach zusätzlich heraufgestuft. Der Ablauf besteht aus mehreren Stufen, die die Dokumentation auflistet.

Zuerst steht die Entscheidung, welche Domain Controller die Wiederherstellungsquelle sein sollen (je Domain einer; er sollte die Rolle des Betriebsmasters für relative IDs haben oder sie erhalten) und welche Sicherung dafür verwendet wird. Dann wird der erste Domain Controller der Stammdomäne wiederhergestellt, und zwar mit dem Verfahren der *nicht-autoritativen Wiederherstellung*. Nach dem Neustart müssen alle FSMO-Rollen durch *Übernahme* (Seize) auf diesen Domain Controller gelegt werden, weil die bisherigen Inhaber nicht mehr verfügbar sind. Danach wird der Wert für den Pool der relativen IDs um 100 000 erhöht, um Dopplungen von Sicherheitskennungen auszuschließen, die zwischen Sicherung und Ausfall vergeben wurden; die Microsoft-Dokumentation schreibt dazu ausdrücklich eine Erhöhung vor. Ebenfalls wird der Domain Controller als autoritative Zeitquelle und Globaler Katalog eingerichtet und der DNS-Dienst geprüft. Als Sicherheitsmaßnahme wird das Kennwort des Kontos `krbtgt` zweimal zurückgesetzt, die Kennwörter aller Domain-Controller-Computerkonten, Vertrauensstellungs-Kennwörter und der Administratorkonten ebenso, falls die Gesamtstruktur durch einen Angriff kompromittiert war. Die anderen Domain Controller werden bereinigt (Metadaten entfernen) und neu heraufgestuft, die übrigen Domänen der Gesamtstruktur folgen demselben Muster, und zuletzt werden Clients, Server und Dienste geprüft.

Das folgende Skript fasst die wichtigsten Schritte nach der Wiederherstellung des ersten Domain Controllers zusammen. Es ist als *Gedächtnisstütze* gedacht, nicht als automatisierter Ablauf, denn eine Gesamtstruktur-Wiederherstellung wird nie vollautomatisch durchgeführt.

```powershell
# Nach der nicht-autoritativen Wiederherstellung des ersten Domain Controllers (hier DC01), normal gestartet.

# 1) Alle FSMO-Rollen uebernehmen (Seize), weil die bisherigen Inhaber ausgefallen sind
Move-ADDirectoryServerOperationMasterRole -Identity "DC01" `
    -OperationMasterRole SchemaMaster, DomainNamingMaster, PDCEmulator, RIDMaster, InfrastructureMaster -Force
netdom query fsmo

# 2) RID-Pool um 100000 erhoehen: Aktuellen Wert lesen (Attribut rIDAvailablePool auf dem RID-Manager-Objekt)
$rid = Get-ADObject "CN=RID Manager$,CN=System,$((Get-ADDomain).DistinguishedName)" -Properties rIDAvailablePool
$rid.rIDAvailablePool

# 3) Als Globaler Katalog sicherstellen, DNS und Dienste pruefen
Get-ADDomainController -Identity "DC01" | Select-Object Name, IsGlobalCatalog, OperationMasterRoles
dcdiag /v /c /e /q
w32tm /query /status

# 4) krbtgt-Kennwort zweimal zuruecksetzen (mit Abstand ueber die Ticketlebensdauer, bei Kompromittierung)
Set-ADAccountPassword -Identity "krbtgt" -Reset -NewPassword (ConvertTo-SecureString -AsPlainText (New-Guid).Guid -Force)
# ... mindestens 10 Stunden warten (maximale Ticketlebensdauer), dann ein zweites Mal wiederholen

# 5) Tote Domain Controller aus dem Verzeichnis entfernen (Metadatenbereinigung) und neue heraufstufen
Get-ADDomainController -Filter * | Select-Object Name, Site
Remove-ADObject -Identity "CN=DC02,OU=Domain Controllers,DC=corp,DC=contoso,DC=com" -Recursive -Confirm:$true
Install-ADDSDomainController -DomainName "corp.contoso.com" -InstallDns -Credential (Get-Credential)
```

Schritt 1 übernimmt die fünf Rollen mit `-Force`; das entspricht dem Seize, das Modul 6 vorgestellt hat, und `netdom query fsmo` kontrolliert das Ergebnis. Schritt 2 liest den Pool der relativen IDs; das Skript erhöht ihn nicht selbst, weil das Verfahren dafür (Änderung des Attributs über LDAP) laut Dokumentation sorgfältig ausgeführt werden muss; wichtig ist zu verstehen, *warum* man es tut. Schritt 3 prüft, ob der Domain Controller ein Globaler Katalog ist, ob seine Dienste laufen (`dcdiag`) und seine Zeit stimmt. Schritt 4 setzt das `krbtgt`-Kennwort zurück; ein einziges Zurücksetzen genügt nicht, weil Active Directory die letzten zwei Kennwörter akzeptiert, und das zweite Zurücksetzen (nach Ablauf der maximalen Ticketlebensdauer, damit gültige Tickets nicht sofort ihre Wirkung verlieren) entwertet alle gestohlenen Tickets, einschließlich gefälschter Golden Tickets. Schritt 5 bereinigt tote Domain Controller und zeigt, wie ein neuer heraufgestuft wird; das Entfernen sollte mit dem Menü der Metadatenbereinigung oder der Konsole geschehen, nicht blind mit `Remove-ADObject`, sondern nur nach Prüfung, was daran hängt.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, eine Gesamtstruktur-Wiederherstellung zu beginnen, ohne die Ursache zu kennen. Wenn die Hintertür des Angreifers in der Sicherung steckt, stellt man den Angriff mit wieder her. Der zweite ist, *zwei* Domain Controller wiederherzustellen, die aus unterschiedlichen Sicherungen stammen; dann entstehen zwei Quellen der Wahrheit, die sich widersprechen. Der dritte ist, die Rollen nicht zu übernehmen, sondern auf die alten Inhaber zu warten. Der vierte ist, die Kennwörter nicht zu erneuern.

```powershell
# FALSCH: Zwei Domain Controller derselben Domaene aus der Sicherung wiederherstellen und beide online nehmen
wbadmin start systemstaterecovery -version:10/20/2026-02:00 -quiet     # auf DC01
wbadmin start systemstaterecovery -version:10/23/2026-02:00 -quiet     # auf DC02 (andere Sicherung!)

# RICHTIG: Genau einen Domain Controller je Domaene wiederherstellen; alle anderen neu installieren
wbadmin start systemstaterecovery -version:10/23/2026-02:00 -quiet     # nur auf DC01
Install-ADDSDomainController -DomainName "corp.contoso.com" -InstallDns -Credential (Get-Credential)   # auf DC02
```

> **Ergänzung aus der Nachrecherche**
>
> Die Entscheidung, ob eine Gesamtstruktur-Wiederherstellung nötig ist, die Wiederherstellung eines Domain Controllers je Domain, die nicht-autoritative Wiederherstellung als Ausgangspunkt, die Übernahme der Rollen, den Umgang mit den relativen IDs und die Bereinigung der übrigen Domain Controller beschreiben die abgerufenen Seiten des „Active Directory Forest Recovery Guide“ („Determine how to recover“, „Perform initial recovery“, „Perform a nonauthoritative restore“, „Steps for restoring the forest“; Microsoft Learn, Suchauszüge, die vollständigen Unterseiten wurden nicht gelesen). Die konkreten Beträge (Erhöhung des RID-Pools um 100 000, zehn Stunden Wartezeit zwischen den `krbtgt`-Zurücksetzungen) und die Skriptzeilen stammen aus dem Fachwissen. Vor dem Ernstfall muss der vollständige Guide gelesen und mit dem eigenen Aufbau abgeglichen werden.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Industrieunternehmen wird Opfer eines Verschlüsselungsangriffs; alle sechs Domain Controller sind betroffen. Der Notfallplan sieht vor, aus der Offline-Sicherung vom Vortag der Entdeckung jeweils einen Domain Controller je Domain wiederherzustellen. Vor dem Neustart wird das Netzwerk isoliert, nach der Wiederherstellung werden `krbtgt` und die Administratorkennwörter zweimal gewechselt. Die Wiederherstellung der Gesamtstruktur dauert zwei Tage, die der Anwendungen eine Woche. Die Sicherung auf einem getrennten Medium war der Unterschied zwischen zwei Tagen und dem Neuaufbau der Domäne von Grund auf.

## 10.8 DR Tests

Eine Wiederherstellung, die nie getestet wurde, ist eine Hoffnung, kein Plan. *Disaster-Recovery-Tests* (DR-Tests) prüfen in regelmäßigen Abständen, ob die Sicherungen brauchbar sind, ob die Anleitungen stimmen und ob die Beteiligten den Ablauf beherrschen. Sie zeigen auch, wie lange die Wiederherstellung tatsächlich dauert. Zwei Kennzahlen sind dabei zentral: die *Recovery Time Objective* (RTO), also wie lange der Dienst höchstens ausfallen darf, und die *Recovery Point Objective* (RPO), also wie viele Daten höchstens verloren gehen dürfen. Für Active Directory ergibt sich das RPO aus der Sicherungshäufigkeit und der Replikation (bei einem einzelnen Ausfall verliert man fast nichts, weil andere Domain Controller die Daten haben), das RTO aus dem Ablauf der Wiederherstellung.

Es gibt mehrere Stufen von Tests. Der *Dokumentationstest* (Tabletop) geht das Handbuch mit den Beteiligten gedanklich durch, ohne etwas zu verändern, und deckt fehlende Informationen auf. Der *Teilwiederherstellungstest* stellt einzelne Bausteine wieder her, etwa ein gelöschtes Objekt, einen Domain Controller in einer isolierten Umgebung oder SYSVOL. Der *Gesamttest* stellt eine Kopie der Gesamtstruktur in einem abgeschotteten Netz her. Die Dokumentation zur Gesamtstruktur-Wiederherstellung nennt als Voraussetzung, dass der Test in einer isolierten Umgebung stattfindet, damit die wiederhergestellte Kopie nicht mit der echten Umgebung kommuniziert; sonst droht ein Konflikt, der der echten Domäne schaden kann.

Der Ablauf eines Tests beginnt mit der Planung: Ziel, Umfang, Verantwortliche, Zeitrahmen, Erfolgskriterien. Dann folgt die Durchführung mit Zeitnahme für jeden Schritt, danach die Auswertung mit Befunden und Maßnahmen. Zu den Erfolgskriterien gehören technische Prüfungen (Replikation fehlerfrei, SYSVOL-Freigaben vorhanden, Anmeldung funktioniert, Gruppenrichtlinien werden angewendet, DNS-Auflösung stimmt) und organisatorische (alle Beteiligten erreichbar, Zugangsdaten verfügbar, Dokumentation aktuell).

```powershell
# Pruefskript fuer einen DR-Test in der ISOLIERTEN Testumgebung (nach der Wiederherstellung)
$start = Get-Date
$ergebnis = [System.Collections.Generic.List[object]]::new()
function Pruefe($Name, [scriptblock]$Test) {
    try   { $ok = & $Test } catch { $ok = $false }
    $ergebnis.Add([pscustomobject]@{ Pruefung=$Name; Bestanden=[bool]$ok; Zeit=Get-Date })
}

Pruefe "AD-Dienste laufen"        { (Get-Service NTDS, DNS, Netlogon, KDC | Where-Object Status -ne "Running").Count -eq 0 }
Pruefe "SYSVOL/NETLOGON-Freigaben" { (net share | Select-String "SYSVOL|NETLOGON").Count -ge 2 }
Pruefe "FSMO-Rollen vorhanden"     { (Get-ADDomain).PDCEmulator -and (Get-ADDomain).RIDMaster -and (Get-ADForest).SchemaMaster }
Pruefe "Replikation fehlerfrei"    { (repadmin /replsummary | Select-String " fail").Count -eq 0 }
Pruefe "dcdiag ohne Fehler"        { -not (dcdiag /q | Select-String "failed|fehler") }
Pruefe "Benutzeranzahl plausibel"  { (Get-ADUser -Filter *).Count -gt 100 }
Pruefe "Gruppenrichtlinien da"     { (Get-GPO -All).Count -gt 0 }
Pruefe "Papierkorb aktiv"          { [bool](Get-ADOptionalFeature -Filter 'Name -eq "Recycle Bin Feature"').EnabledScopes }

$ergebnis | Format-Table -AutoSize
"Dauer der Pruefungen: {0:N1} Minuten" -f ((Get-Date) - $start).TotalMinutes
$ergebnis | Export-Csv "D:\Berichte\DR-Test-$(Get-Date -f yyyyMMdd).csv" -NoTypeInformation -Encoding UTF8
```

Die Funktion `Pruefe` nimmt einen Namen und einen Codeblock entgegen, führt den Test aus, fängt Fehler ab und merkt sich das Ergebnis; so bricht das Skript bei der ersten Panne nicht ab. Die Prüfungen decken die wichtigsten Bausteine ab: Dienste, Freigaben, FSMO-Rollen, Replikation, Diagnose, Benutzer, Richtlinien und Papierkorb. Die Zahl der Benutzer (`-gt 100`) ist ein Platzhalter und muss durch einen Wert ersetzt werden, der zur Umgebung passt. Die Zeitangaben und die CSV-Ausgabe dokumentieren das Ergebnis. Wichtig: Das Skript wird in der isolierten Testumgebung ausgeführt, nicht in der Produktivdomäne.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, nie zu testen, weil „es sowieso klappt“. Der zweite ist, den Test in einer Umgebung durchzuführen, die mit dem Produktionsnetz verbunden ist; die wiederhergestellte Kopie meldet sich mit denselben Namen und Adressen und kann die echte Umgebung stören. Der dritte ist, den Test nur technisch zu betrachten: Ob jemand das DSRM-Kennwort, den Safe mit den Medien oder die Rufnummer des Dienstleisters im Notfall findet, zeigt erst der Test. Der vierte ist, nach dem Test keine Maßnahmen abzuleiten.

```powershell
# FALSCH: "Wiederherstellungstest" im Produktivnetz, die Kopie ist erreichbar
Restore-VM -Name "DC01-Test"      # Netzwerkadapter noch am Produktions-Switch

# RICHTIG: Kopie in isoliertes virtuelles Netz, erst danach starten
Get-VMNetworkAdapter -VMName "DC01-Test" | Connect-VMNetworkAdapter -SwitchName "Isoliert-Test"
Start-VM -Name "DC01-Test"
```

> **Ergänzung aus der Nachrecherche**
>
> Der Hinweis, dass eine Gesamtstruktur-Wiederherstellung vorbereitet und geübt werden muss, folgt dem abgerufenen „Active Directory Forest Recovery Guide“ (Microsoft Learn, Suchauszüge). Die Definitionen von RTO und RPO, die Teststufen, die Prüfliste und das Skript sind allgemeines Fachwissen der Betriebsplanung und nicht aus einer abgerufenen Quelle belegt. Die Testumgebung soll vom Produktionsnetz vollständig getrennt sein, wie es auch die Vorgehensweisen zur Wiederherstellung voraussetzen.

### Praxisbezug

> **Praxisbeispiel**
>
> Einmal im Jahr stellt ein Unternehmen die Gesamtstruktur in einem isolierten virtuellen Netz aus den Sicherungen wieder her. Beim ersten Test dauerte es elf Stunden, weil niemand das DSRM-Kennwort fand und ein Skript mit festen Servernamen scheiterte. Beim dritten Test dauerte es drei Stunden. Die Geschäftsleitung erhält das Ergebnis als Einseiter mit RTO, RPO und offenen Maßnahmen; dadurch bekommt das Team Budget für einen unveränderlichen Sicherungsspeicher.

## 10.9 BCDR Runbook

*Business Continuity and Disaster Recovery* (BCDR) beschreibt, wie ein Unternehmen den Betrieb aufrechterhält und nach einer Katastrophe wiederherstellt. Das *Runbook* (Betriebshandbuch für den Notfall) ist der Teil, den die Techniker im Ernstfall abarbeiten: eine Schritt-für-Schritt-Anleitung, geschrieben für Menschen unter Stress. Sie muss so gehalten sein, dass sie auch jemand ausführen kann, der das System nicht täglich betreut und der um drei Uhr nachts angerufen wird. Ein gutes Runbook enthält keine Erklärungen zur Theorie, sondern Entscheidungen und Befehle.

Der Aufbau folgt dem Ablauf eines Vorfalls. Am Anfang steht die *Alarmierung* und Einordnung: Wer wird informiert, wer entscheidet, ob es ein Notfall ist, wer führt die Kommunikation. Danach die *Lagebeurteilung* mit einem Entscheidungsbaum: Ist ein einzelnes Objekt betroffen (Papierkorb, 10.2, oder autoritative Wiederherstellung, 10.4)? Ein einzelner Domain Controller (Neuinstallation oder nicht-autoritative Wiederherstellung, 10.3)? SYSVOL (10.6)? Die ganze Gesamtstruktur (10.7)? Zu jedem Zweig gehören die konkreten Schritte, die Verantwortlichen, die benötigten Zugangsdaten und Medien, die erwartete Dauer und die Prüfkriterien für den Erfolg. Schließlich die *Nachbereitung*: Dokumentation, Ursachenanalyse, Anpassung der Maßnahmen.

Zu den Inhalten, die in keinem Runbook fehlen dürfen, gehören: Ansprechpartner mit Telefonnummern (nicht im Verzeichnis selbst abgelegt, weil es im Notfall nicht verfügbar ist), Standorte und Zugriff auf Sicherungsmedien, Namen und Adressen aller Domain Controller und ihrer Rollen, die FSMO-Rollenverteilung, die DSRM-Kennwörter (sicher aufbewahrt), die Tombstone-Lebensdauer, die Reihenfolge, in der Dienste wieder hochgefahren werden (Domain Controller und DNS zuerst, dann Zertifizierungsstellen, dann Anwendungen), und Verweise auf die Herstellerdokumentation. Das Runbook liegt außerhalb der Domäne, in Papierform und auf einem separaten Speicher, denn eine Anleitung, die nur auf dem Dateiserver der ausgefallenen Domäne liegt, ist im Ernstfall nutzlos.

Das folgende Beispiel erzeugt automatisch den Teil des Runbooks, der sich laufend ändert: die Bestandsaufnahme der Domain Controller, der Rollen, der Replikation und der Sicherungen. Diese Daten sollen regelmäßig an einen Ort außerhalb der Domäne kopiert werden.

```powershell
Import-Module ActiveDirectory
$datei = "D:\Runbook\AD-Bestand-$(Get-Date -f yyyyMMdd).txt"
$cfg = (Get-ADRootDSE).configurationNamingContext
$out = [System.Collections.Generic.List[string]]::new()
$out.Add("AD-Bestandsaufnahme vom $(Get-Date -f 'dd.MM.yyyy HH:mm')")
$out.Add("")

$out.Add("== Gesamtstruktur und Domaene ==")
$f = Get-ADForest; $d = Get-ADDomain
$out.Add("Forest: $($f.Name) (Ebene $($f.ForestMode)); Domain: $($d.DNSRoot) (Ebene $($d.DomainMode))")
$out.Add("Schema-Master: $($f.SchemaMaster); Domain-Naming-Master: $($f.DomainNamingMaster)")
$out.Add("PDC: $($d.PDCEmulator); RID: $($d.RIDMaster); Infrastructure: $($d.InfrastructureMaster)")

$out.Add("")
$out.Add("== Domain Controller ==")
Get-ADDomainController -Filter * | ForEach-Object {
    $out.Add(("{0,-8} {1,-15} Standort {2,-10} GC={3} RODC={4} OS={5}" -f $_.Name, $_.IPv4Address, $_.Site, $_.IsGlobalCatalog, $_.IsReadOnly, $_.OperatingSystem))
}

$out.Add("")
$out.Add("== Wiederherstellungsrelevante Werte ==")
$ts = (Get-ADObject "CN=Directory Service,CN=Windows NT,CN=Services,$cfg" -Properties tombstoneLifetime).tombstoneLifetime
$out.Add("Tombstone-Lebensdauer: $ts Tage")
$out.Add("Papierkorb: " + [bool](Get-ADOptionalFeature -Filter 'Name -eq "Recycle Bin Feature"').EnabledScopes)
$out.Add("Letzte erfolgreiche Sicherung (dieser DC): " + (Get-WBSummary).LastSuccessfulBackupTime)

$out | Set-Content $datei -Encoding UTF8
Copy-Item $datei "\\sicherung01\runbook\" -Force     # Ablage ausserhalb der Domaene
```

Das Skript sammelt in einer Liste von Textzeilen, was im Notfall gebraucht wird: Funktionsebenen, die Inhaber der fünf Rollen, die Liste der Domain Controller mit Adresse, Standort, Rolle als Globaler Katalog oder schreibgeschützter Domain Controller und Betriebssystem, die Tombstone-Lebensdauer, den Status des Papierkorbs und die letzte Sicherung. Die formatierte Ausgabe (`-f`) richtet Spalten aus, damit der Ausdruck lesbar bleibt. Die letzte Zeile kopiert die Datei auf einen Server außerhalb der Domäne; der Pfad `\\sicherung01\runbook` ist ein Platzhalter. Eine geplante Aufgabe führt das Skript wöchentlich aus, sodass das Runbook nie veraltete Rollenlisten enthält.

### Typische Fehler und Stolperfallen

Der erste Fehler ist ein Runbook, das nur auf dem Server liegt, der im Notfall nicht verfügbar ist. Der zweite ist veraltete Information: Domain Controller, die längst ersetzt wurden, Telefonnummern ehemaliger Mitarbeiter, Kennwörter, die nicht mehr stimmen. Der dritte ist ein Handbuch, das nur Theorie erklärt, statt Entscheidungen und Befehle zu liefern. Der vierte ist, dass nur eine Person das Runbook kennt.

```powershell
# FALSCH: Runbook als Datei auf dem Dateiserver der eigenen Domaene
Copy-Item "Runbook.docx" "\\fs01.corp.contoso.com\IT\Runbook\"

# RICHTIG: Zusaetzlich ausserhalb der Domaene und in Papierform; Bestandsdaten automatisch aktualisieren
Copy-Item "D:\Runbook\AD-Bestand-20261025.txt" "\\sicherung01\runbook\" -Force
```

> **Ergänzung aus der Nachrecherche**
>
> Dass Wiederherstellungsverfahren zu dokumentieren und zu üben sind und welche Angaben (Rollen, Domain Controller, Sicherungsstand) bekannt sein müssen, folgt der abgerufenen Beschreibung des „Active Directory Forest Recovery Guide“ (Microsoft Learn, Suchauszüge). Der Aufbau des Runbooks, die Reihenfolge der Dienste und die Hinweise zur Ablage außerhalb der Domäne sind allgemeines Fachwissen zur Betriebsplanung und nicht aus einer abgerufenen Quelle belegt. Rechtliche oder vertragliche Pflichten zur Notfallplanung (zum Beispiel aus Sicherheitsgesetzen) sind in dieser Lerneinheit nicht behandelt; dazu gilt der Hinweis: keine Rechtsberatung.

### Praxisbezug

> **Praxisbeispiel**
>
> Das Runbook eines Unternehmens besteht aus einem dünnen Ordner und einem USB-Stick im Tresor. Der Ordner enthält den Entscheidungsbaum auf einer Seite, die Schritte zu jeder Lage, die Telefonliste und die Adresse des Sicherungsorts. Der Stick enthält die aktuelle Bestandsaufnahme aus dem Skript und die Installationsmedien. Beim Test im Herbst schaffen es zwei Techniker, die das System kaum kennen, die Testwiederherstellung allein anhand des Ordners durchzuführen. Das war das Ziel.

## 10.10 Übungsaufgaben zu Modul 10

**Aufgabe 10.1** Was gehört zum System State eines Domain Controllers, und warum sichert man ihn mit dem Schattenkopie-Dienst als Einheit? Warum ist ein Hypervisor-Schnappschuss keine Sicherung von Active Directory?

**Aufgabe 10.2** Erklären Sie den Unterschied zwischen einem gelöschten Objekt, einem Tombstone und einem „recycled object“. Welche Voraussetzungen hat der Papierkorb, und warum sollte man ihn vor dem Ernstfall aktivieren?

**Aufgabe 10.3** Beschreiben Sie die Schritte einer nicht-autoritativen Wiederherstellung eines Domain Controllers. Warum benötigt man das DSRM-Kennwort, und wo sollte es aufbewahrt werden?

**Aufgabe 10.4** Ein Mitarbeiter hat eine OU mit 200 Konten gelöscht. Der Papierkorb ist nicht aktiv. Beschreiben Sie das Vorgehen. Warum genügt eine nicht-autoritative Wiederherstellung nicht, und wozu dient die LDIF-Datei von `ntdsutil`?

**Aufgabe 10.5** Ein Domain Controller in einer Filiale war 7 Monate ausgeschaltet, die Tombstone-Lebensdauer beträgt 180 Tage. Darf man ihn einschalten? Begründen Sie und nennen Sie die Folgen sowie das richtige Vorgehen.

**Aufgabe 10.6** **Praxis:** Schreiben Sie ein PowerShell-Skript, das die Tombstone-Lebensdauer ausliest, für jeden Domain Controller die Zeit seit der letzten erfolgreichen eingehenden Replikation berechnet und eine Warnung ausgibt, wenn dieser Wert mehr als die Hälfte der Tombstone-Lebensdauer beträgt.

**Aufgabe 10.7** **Praxis:** Schreiben Sie die Befehle, um (a) den Papierkorb zu aktivieren, (b) einen Testbenutzer samt Gruppenmitgliedschaft anzulegen und zu löschen und (c) ihn wiederherzustellen und zu prüfen, dass die Mitgliedschaft erhalten blieb.

**Aufgabe 10.8** **Praxis:** Auf DC02 fehlen die Freigaben `SYSVOL` und `NETLOGON`. Beschreiben Sie die Diagnose (Befehle, Ereignisse) und schreiben Sie die Schritte der nicht-autoritativen DFSR-Synchronisation. Erklären Sie, wann man autoritativ synchronisieren würde und welche Gefahr damit verbunden ist. Skizzieren Sie danach die Gliederung eines Runbooks für den Fall „Gesamtstruktur verschlüsselt“ mit mindestens sieben Schritten in der richtigen Reihenfolge.

## 10.11 Lösungen zu den Übungsaufgaben

**Lösung 10.1.** Zum System State eines Domain Controllers gehören die Active-Directory-Datenbank mit ihren Protokollen, SYSVOL, die Registrierung, die Systemdateien, die COM+-Klassenregistrierung und gegebenenfalls Daten der Zertifikatsdienste. Diese Teile müssen zum selben Zeitpunkt zusammenpassen, deshalb werden sie über VSS als konsistenter Schnappschuss gemeinsam gesichert. Ein Hypervisor-Schnappschuss ist keine unterstützte Sicherung, weil beim Zurücksetzen der Domain Controller seine Änderungsnummern (USNs) wiederverwenden kann, die die Partner schon kennen; sie ignorieren dann seine neuen Änderungen (USN-Rollback). Die VM-GenerationID mildert das, ersetzt aber keine Sicherung mit Wiederherstellungstest.

**Lösung 10.2.** Ein *gelöschtes* Objekt (mit Papierkorb) behält alle Attribute und ist vollständig wiederherstellbar. Ohne Papierkorb bleibt nur ein *Tombstone* mit wenigen Attributen. Nach der Lebensdauer gelöschter Objekte wird es zum *recycled object* ohne die meisten Attribute und ist nicht mehr vollständig wiederherstellbar; nach einer weiteren Frist wird es endgültig entfernt. Voraussetzungen: Gesamtstruktur-Funktionsebene Windows Server 2008 R2 und das Aktivieren mit `Enable-ADOptionalFeature`, was nicht rückgängig zu machen ist. Man aktiviert ihn vorher, weil nachträglich gelöschte Objekte nur dann voll wiederherstellbar sind, wenn der Papierkorb schon aktiv war.

**Lösung 10.3.** (1) Startoption `safeboot dsrepair` setzen und neu starten; (2) im DSRM mit dem lokalen Administrator und dem DSRM-Kennwort anmelden; (3) mit `wbadmin get versions` die Sicherung wählen und mit `wbadmin start systemstaterecovery` zurückspielen; (4) Startoption entfernen und normal neu starten; (5) Replikation mit `repadmin /replsummary` und `/syncall` sowie `dcdiag` prüfen. Das DSRM-Kennwort ist nötig, weil im DSRM die Domänenkonten nicht verfügbar sind. Man bewahrt es sicher außerhalb der Domäne auf (Tresor, Passwort-Verwaltung) oder verwaltet es mit Windows LAPS (Modul 9) und kann es im laufenden Betrieb mit `ntdsutil` neu setzen.

**Lösung 10.4.** Vorgehen: Domain Controller im DSRM aus einer Sicherung vor dem Löschen wiederherstellen; vor dem Neustart in `ntdsutil` mit `authoritative restore` und `restore subtree` die OU markieren; normal starten und die Replikation abwarten; die erzeugte LDIF-Datei mit `ldifde -i -k -f` einspielen. Eine nicht-autoritative Wiederherstellung genügt nicht, weil die Partner dem Domain Controller die Löschung erneut mitteilen und die Objekte sofort wieder verschwinden. Die autoritative Markierung erhöht die Versionsnummern, sodass die wiederhergestellten Objekte gewinnen. Die LDIF-Datei enthält die Rückverweise (Gruppenmitgliedschaften), die nicht automatisch richtig gesetzt werden.

**Lösung 10.5.** Nein, man darf ihn nicht einschalten. Die 7 Monate (rund 210 Tage) überschreiten die Tombstone-Lebensdauer von 180 Tagen. Der Domain Controller kennt Löschungen nicht, deren Tombstones inzwischen entfernt wurden, und würde Lingering Objects einbringen; die Replikation wird mit Ereignissen wie 2042 gestoppt. Richtig: den Domain Controller offline lassen beziehungsweise zwangsweise herabstufen, seine Metadaten im Verzeichnis bereinigen, das System neu installieren und neu heraufstufen. Gibt es bereits Lingering Objects, werden sie mit `repadmin /removelingeringobjects` (zuerst im Advisory Mode) entfernt. Die strikte Replikationskonsistenz nicht abschalten.

**Lösung 10.6.** Ein mögliches Skript:

```powershell
Import-Module ActiveDirectory
$cfg = (Get-ADRootDSE).configurationNamingContext
$tsl = (Get-ADObject "CN=Directory Service,CN=Windows NT,CN=Services,$cfg" -Properties tombstoneLifetime).tombstoneLifetime
if (-not $tsl) { $tsl = 60 }
$grenze = $tsl / 2
$dcs = (Get-ADDomainController -Filter *).HostName
foreach ($dc in $dcs) {
    $meta = Get-ADReplicationPartnerMetadata -Target $dc -Scope Server -ErrorAction SilentlyContinue
    foreach ($m in $meta) {
        $tage = [math]::Round(((Get-Date) - $m.LastReplicationSuccess).TotalDays, 1)
        $status = if ($tage -gt $grenze) { "WARNUNG" } else { "ok" }
        "{0,-30} von {1,-30} vor {2,6} Tagen  {3}" -f $dc, $m.Partner, $tage, $status
    }
}
```

Die Schleife fragt für jeden Domain Controller die Replikationspartner und deren letzte erfolgreiche Replikation ab. Ist die Zeit größer als die halbe Tombstone-Lebensdauer, wird eine Warnung ausgegeben. Der Wert `$tsl` fällt auf 60 zurück, wenn das Attribut nicht gesetzt ist, was ein vorsichtiger Wert ist.

**Lösung 10.7.** Ein mögliches Vorgehen:

```powershell
# (a)
Enable-ADOptionalFeature -Identity "Recycle Bin Feature" -Scope ForestOrConfigurationSet -Target "corp.contoso.com" -Confirm:$false

# (b)
New-ADUser -Name "Test Papierkorb" -SamAccountName "t.papierkorb" -Path "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" -Enabled $false
Add-ADGroupMember -Identity "G-Helpdesk" -Members "t.papierkorb"
Remove-ADUser -Identity "t.papierkorb" -Confirm:$false

# (c)
Get-ADObject -Filter 'isDeleted -eq $true -and samAccountName -eq "t.papierkorb"' -IncludeDeletedObjects | Restore-ADObject
Get-ADUser "t.papierkorb" -Properties MemberOf | Select-Object Name, MemberOf
```

Die letzte Abfrage zeigt, dass die Gruppenmitgliedschaft nach der Wiederherstellung erhalten ist; ohne Papierkorb wäre sie verloren. Wichtig: (a) ist unumkehrbar und gehört zuvor im Labor getestet.

**Lösung 10.8.** Diagnose: `net share` prüft die Freigaben, im Protokoll „DFS Replication“ suchen nach den Ereignissen 4114, 4614, 4604, 2213 und 4012; `dfsrmig /getglobalstate` zeigt, ob DFSR in Verwendung ist; `dfsrdiag replicationstate` und `repadmin /replsummary` prüfen den Zustand. Nicht-autoritative Synchronisation: `msDFSR-Enabled` am SYSVOL-Abonnement von DC02 auf FALSE setzen, mit `repadmin /syncall /AdeP` verteilen, DFSR-Dienst anhalten, `msDFSR-Enabled` auf TRUE setzen, erneut verteilen, Dienst starten und `dfsrdiag pollad` ausführen; Erfolg an Ereignissen 4614 und 4604 und den Freigaben erkennen. Autoritativ synchronisiert man nur, wenn der SYSVOL eines bestimmten Domain Controllers als einzige richtige Quelle gelten soll (zum Beispiel nach dem Löschen von Richtlinien); die Gefahr ist, dass der Stand auf allen anderen Domain Controllern überschrieben wird. Gliederung des Runbooks „Gesamtstruktur verschlüsselt“: (1) Alarmierung und Entscheidung, Netzwerk isolieren; (2) Ursache und Zeitpunkt des Angriffs feststellen, vertrauenswürdige Sicherung bestimmen; (3) je Domain einen Domain Controller nicht-autoritativ im DSRM wiederherstellen; (4) FSMO-Rollen übernehmen, RID-Pool erhöhen; (5) DNS, Zeit, Globaler Katalog und Diensten prüfen; (6) `krbtgt`, Administratorkennwörter, Computerkonten der Domain Controller und Vertrauensstellungen zurücksetzen; (7) weitere Domain Controller bereinigen und neu heraufstufen; (8) Clients und Server prüfen und wieder anbinden; (9) Nachbereitung, Ursachenanalyse und Anpassung des Handbuchs.
