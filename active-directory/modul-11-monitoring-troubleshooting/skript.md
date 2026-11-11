# Modul 11 - Monitoring, Troubleshooting und Betrieb

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Tabellen als Markdown-Tabellen, Übungsaufgaben und Lösungen als Absätze). Die Überschriften sind wie in der Quelle nach Modul und Lerneinheit nummeriert (11.1 bis 11.9; 11.10 Übungsaufgaben, 11.11 Lösungen). **Die PowerShell-Beispiele wurden für dieses Repository nicht ausgeführt**; sie setzen eine Windows-Server-Laborumgebung mit der fiktiven Domain `corp.contoso.com` voraus und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain. Übersicht zum Modul: [README](README.md).

|                                       |              |
|:--------------------------------------|:-------------|
| Dauer laut Modulübersicht             | 10 Stunden   |
| Summe der Lerneinheiten (Detailblatt) | 10,5 Stunden |
| Priorität                             | 1            |

|  Nr. | Lerneinheit              | Dauer (h) | Prio |
|-----:|:-------------------------|----------:|-----:|
| 11.1 | Event Viewer             |         1 |    1 |
| 11.2 | dcdiag                   |         1 |    1 |
| 11.3 | repadmin                 |       1,5 |    1 |
| 11.4 | nltest                   |         1 |    1 |
| 11.5 | PowerShell AD Modul      |         1 |    1 |
| 11.6 | Performance Monitoring   |       1,5 |    1 |
| 11.7 | Health Checks            |         1 |    2 |
| 11.8 | Troubleshooting Methodik |         1 |    2 |
| 11.9 | Incident Runbooks        |       1,5 |    2 |
|      | **Summe**                |  **10,5** |      |

> **Merke**
>
> Die Stundensumme der Lerneinheiten im Detailblatt (10,5 h) weicht von der Dauer in der Modulübersicht (10 h) ab. Dieses Skript behandelt alle Lerneinheiten des Detailblatts vollständig; die Abweichung ist im Lehrplan selbst zu klären.

Ein Active Directory, das jahrelang fehlerfrei läuft, ist selten das Ergebnis von Glück. Meist hat jemand die Anzeichen von Störungen früh gelesen: eine auffällige Meldung im Ereignisprotokoll, eine Replikation, die länger dauert als sonst, ein Domain Controller, der langsamer antwortet. Dieses Modul vermittelt das Handwerkszeug dafür. Es beginnt mit den Quellen, die Windows selbst liefert (Ereignisanzeige), geht über die vier wichtigsten Diagnosewerkzeuge für Domain Controller (`dcdiag`, `repadmin`, `nltest` und das PowerShell-Modul für Active Directory), behandelt die Messung der Leistung und endet mit dem planvollen Vorgehen bei Störungen: Prüfungen, Methodik und Runbooks.

Die Grundlagen zu Replikation, DNS, FSMO-Rollen und Zeit stehen in Modul 5 und Modul 6, die Anmeldung und ihre Fehlerbilder in Modul 8, die Wiederherstellung nach schweren Ausfällen in Modul 10. Dieses Modul setzt sie voraus und zeigt, wie man sie im Betrieb überwacht und prüft. Alle Beispiele laufen in der Laborumgebung `corp.contoso.com` mit `DC01` (10.10.0.11) und `DC02` (10.10.0.12); `SRV01` ist ein Mitgliedsserver und `PC01` ein Arbeitsplatz.

## 11.1 Event Viewer

Die *Ereignisanzeige* (Event Viewer) ist die erste Anlaufstelle bei jeder Störung. Windows protokolliert in mehreren Protokollen, die nach Herkunft getrennt sind. Auf einem Domain Controller sind neben den klassischen Protokollen „Anwendung“, „Sicherheit“ und „System“ vor allem fünf weitere wichtig, die im Zweig „Anwendungs- und Dienstprotokolle“ stehen: *Directory Service* (Ereignisse der Active-Directory-Datenbank und der Replikation), *DNS Server*, *DFS Replication* (SYSVOL, siehe Modul 10), *File Replication Service* (nur noch in alten Domänen) und *Microsoft-Windows-GroupPolicy/Operational* auf den Clients. Jedes Ereignis hat eine Quelle, eine Ereignis-ID, eine Ebene (Information, Warnung, Fehler, Kritisch) und einen beschreibenden Text. Die Ereignis-ID ist das Wichtigste: Sie ist die Nummer, mit der man in der Dokumentation nachschlägt.

Einige Ereignisse sollte man auswendig kennen. Im Protokoll *Directory Service*: 1311 (die Replikationstopologie ist nicht mehr zusammenhängend, der KCC konnte keine Verbindung herstellen), 1388 und 1988 (Lingering Objects, siehe Modul 10), 2042 (der Domain Controller hat zu lange nicht repliziert), 2087 und 2088 (DNS-Auflösung des Replikationspartners fehlgeschlagen), 1644 (teure oder ineffiziente LDAP-Abfrage, nur wenn die Diagnoseprotokollierung dafür erhöht wurde). Im *System*-Protokoll: Quelle NETLOGON mit 5719 (kein Domain Controller erreichbar, Anmeldeserver nicht verfügbar), 5805 (Computerkonto kann den sicheren Kanal nicht herstellen), Quelle Kerberos und KDC mit Zeit- und SPN-Problemen, Quelle Time-Service mit Zeitabweichungen. Im *Sicherheits*-Protokoll: 4624 und 4625 (Anmeldung erfolgreich und fehlgeschlagen), 4740 (Kontosperrung), 4768, 4769 und 4771 (Kerberos-Ticketanforderungen und Fehler), 4776 (NTLM-Prüfung), 1102 (Sicherheitsprotokoll gelöscht). Die Liste der wichtigen Ereignisse auf Domain Controllern führt die Microsoft-Dokumentation im Anhang „Events to Monitor“ auf.

Ereignisse liest man nicht nur an der Konsole, sondern mit `Get-WinEvent`. Der Vorteil: Man filtert serverseitig mit einer Hashtabelle, was auch bei riesigen Protokollen schnell ist, und kann mehrere Domain Controller nacheinander abfragen. Das folgende Skript durchsucht alle Domain Controller nach den Ereignissen, die auf Probleme mit der Replikation, mit DNS oder der Zeit hinweisen, und zeigt sie in einer gemeinsamen Tabelle. Dazu liest es auch die Detaildaten eines Ereignisses (zum Beispiel den Namen des betroffenen Partners) aus dem XML.

```powershell
Import-Module ActiveDirectory
$dcs = (Get-ADDomainController -Filter *).HostName
$seit = (Get-Date).AddDays(-2)

# 1) Wichtige Fehler und Warnungen aus den AD-relevanten Protokollen aller Domain Controller
$abfragen = @(
  @{ Log="Directory Service"; Ids=1311,1388,1988,2042,2087,2088,1865,1566 },
  @{ Log="DNS Server";        Ids=4000,4004,4013,4015 },
  @{ Log="DFS Replication";   Ids=2212,2213,4012,4614,4604 },
  @{ Log="System";            Ids=5719,5805,36,1129 }
)
$treffer = foreach ($dc in $dcs) {
  foreach ($a in $abfragen) {
    Get-WinEvent -ComputerName $dc -FilterHashtable @{ LogName=$a.Log; Id=$a.Ids; StartTime=$seit } -ErrorAction SilentlyContinue |
      Select-Object @{n="DC";e={$dc}}, TimeCreated, LogName, Id, LevelDisplayName,
                    @{n="Text";e={($_.Message -split "`n")[0]}}
  }
}
$treffer | Sort-Object TimeCreated -Descending | Format-Table -AutoSize -Wrap

# 2) Haeufigkeit je Ereignis und Domain Controller: Was kommt oft vor?
$treffer | Group-Object DC, Id | Sort-Object Count -Descending | Select-Object -First 10 Count, Name

# 3) Sicherheitsprotokoll: Kontosperrungen (4740) und wer sie ausloest
Get-WinEvent -ComputerName (Get-ADDomain).PDCEmulator -FilterHashtable @{ LogName="Security"; Id=4740; StartTime=$seit } -ErrorAction SilentlyContinue |
  ForEach-Object {
    $d=@{}; foreach ($n in ([xml]$_.ToXml()).Event.EventData.Data) { $d[$n.Name]=$n.'#text' }
    [pscustomobject]@{ Zeit=$_.TimeCreated; Konto=$d["TargetUserName"]; QuellRechner=$d["TargetDomainName"] }
  } | Format-Table -AutoSize

# 4) Ein benutzerdefinierte Ansicht fuer die Konsole anlegen (XML-Filter) - hier nur anzeigen
$xml = @'
<QueryList><Query Id="0" Path="Directory Service"><Select Path="Directory Service">*[System[(Level=1 or Level=2 or Level=3)]]</Select></Query></QueryList>
'@
Get-WinEvent -FilterXml $xml -MaxEvents 20 | Select-Object TimeCreated, Id, LevelDisplayName | Format-Table -AutoSize
```

Schritt 1 definiert eine Liste von Protokollen mit den dazugehörigen Ereignis-IDs und fragt jeden Domain Controller danach ab; `-ErrorAction SilentlyContinue` verhindert, dass ein fehlendes Ereignis (Get-WinEvent meldet in diesem Fall einen Fehler) den Lauf abbricht. Von der mehrzeiligen Meldung wird nur die erste Zeile gezeigt. Schritt 2 gruppiert die Treffer, damit man sieht, was sich wiederholt; ein einzelnes Ereignis kann Zufall sein, hundert gleiche sind ein Muster. Schritt 3 liest die Kontosperrungen auf dem PDC-Emulator, bei dem alle Sperren zusammenlaufen (Modul 8), und zeigt Konto und Quellrechner. Schritt 4 zeigt einen XML-Filter, wie ihn auch die Ereignisanzeige für benutzerdefinierte Ansichten verwendet; Level 1, 2 und 3 entsprechen kritisch, Fehler und Warnung. Die Ereignis-IDs im Beispiel sind eine Auswahl und sollten an die eigene Umgebung angepasst werden.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, nur das Protokoll „System“ anzusehen und die spezialisierten Protokolle zu ignorieren; die wichtigsten Hinweise stehen in „Directory Service“ und „DNS Server“. Der zweite ist, nur die Meldung zu lesen, nicht aber die Ereignis-ID nachzuschlagen: Der Text sagt oft nur, *dass* etwas fehlschlägt, die Dokumentation zur ID sagt, *warum* und was zu tun ist. Der dritte ist, ein überfülltes Protokoll nicht zu erkennen: Ist das Sicherheitsprotokoll auf 20 MB eingestellt, enthält es oft nur die letzten Stunden. Der vierte ist, dass ein Angreifer das Protokoll löscht (Ereignis 1102); wer die Ereignisse nicht zentral sammelt, verliert die Spuren.

```powershell
# FALSCH: Ganzes Protokoll laden und danach filtern (langsam, speicherhungrig)
Get-WinEvent -LogName Security | Where-Object { $_.Id -eq 4740 }

# RICHTIG: Serverseitig filtern
Get-WinEvent -FilterHashtable @{ LogName="Security"; Id=4740; StartTime=(Get-Date).AddDays(-1) }
```

> **Ergänzung aus der Nachrecherche**
>
> Die Liste der auf Domain Controllern zu beobachtenden Ereignisse (Anhang „Events to Monitor“) und die Empfehlung zur Überwachung stützen sich auf die abgerufenen Seiten „Appendix L: Events to Monitor“ und „Monitoring Active Directory for Signs of Compromise“ (Microsoft Learn, Suchauszüge). Die Ereignisse 1388, 1988, 2042 und 2087 sowie der Zusammenhang mit der Replikation werden auf den abgerufenen Fehlersuche-Seiten zur Active-Directory-Replikation beschrieben. Die übrigen Ereignis-IDs im Skript (zum Beispiel 1311, 4013, 5719) stammen aus dem Fachwissen und sind in der Dokumentation nachzuschlagen. Das Ereignis 1644 setzt eine erhöhte Diagnoseprotokollierung voraus (Abschnitt 11.6).

### Praxisbezug

> **Praxisbeispiel**
>
> Montagmorgen melden mehrere Benutzer der Filiale, dass die Anmeldung dauert. Der Administrator filtert die Ereignisse seit Freitag und sieht auf dem Filial-Domain-Controller 200-mal das Ereignis 2087 (DNS-Auflösung des Partners fehlgeschlagen). Ohne Ereignisanzeige hätte er stundenlang im Netzwerk gesucht; so führt ihn der Hinweis direkt zum DNS-Eintrag, der nach einem Wartungsfenster fehlte.

## 11.2 dcdiag

Das Programm `dcdiag` ist das Standardwerkzeug zur Diagnose von Domain Controllern. Es führt eine ganze Reihe von Einzeltests aus und prüft, ob ein Domain Controller seine Aufgaben erfüllt: Ist er im Netz erreichbar, hat er die erforderlichen Dienste gestartet, bietet er seine Rollen an, kann er replizieren, stimmen DNS-Einträge, SYSVOL und die FSMO-Rollen. Die Microsoft-Dokumentation zu `dcdiag` nennt es ein Befehlszeilenprogramm, das Domain Controller analysiert und Probleme in der Gesamtstruktur meldet, und die Hinweise zur Fehlersuche beschreiben, wie man die Ausgabe der einzelnen Tests liest. Das Werkzeug ist Bestandteil der Rolle Active Directory-Domänendienste beziehungsweise der Remoteserver-Verwaltungstools.

Die wichtigsten Aufrufe sind diese: `dcdiag` allein führt die Standardtests auf dem lokalen Domain Controller aus. `dcdiag /v` gibt ausführliche Meldungen aus. `dcdiag /s:DC02` prüft einen entfernten Domain Controller. `dcdiag /c` läuft zusätzlich alle nicht-standardmäßigen Tests, `dcdiag /e` prüft alle Domain Controller der Gesamtstruktur, `dcdiag /a` alle Domain Controller des Standorts. Mit `/q` werden nur Fehler ausgegeben, was für Skripte ideal ist. Einzelne Tests wählt man mit `/test:Name`, schließt sie mit `/skip:Name` aus. Wichtige Tests sind *Connectivity* (DNS-Eintrag, LDAP- und RPC-Erreichbarkeit), *Advertising* (bietet der Domain Controller sich als Domain Controller an), *Services* (laufen die nötigen Dienste), *Replications* (letzte Replikation erfolgreich), *FsmoCheck* (sind die Rollen erreichbar), *KnowsOfRoleHolders* (kennt er die Rolleninhaber), *RidManager* (hat er einen RID-Pool), *MachineAccount* (Computerkonto in Ordnung), *NetLogons* (Anmelderechte), *SysVolCheck* (Freigaben vorhanden), *SystemLog* (Fehler im Systemprotokoll), *DFSREvent* und *KccEvent* (Fehler in den jeweiligen Protokollen) sowie *DNS* mit eigenen Unterprüfungen.

Die Ausgabe ist zunächst ungewohnt: Jeder Test beginnt mit der Zeile „Starting test: Name“ und endet mit „passed test Name“ oder „failed test Name“. Der Domain Controller wird in Teilen geprüft, die Tests sind aufeinander aufgebaut: Schlägt *Connectivity* fehl, brechen die meisten weiteren Tests ab, und man sieht nur eine Folge von Folgefehlern. Man sucht deshalb immer den *ersten* Fehler und beseitigt ihn zuerst. Die Microsoft-Dokumentation zur Fehlerbehebung bei `dcdiag` und zu Problemen der Domain-Controller-Ortung zeigt, wie typische Fehler (zum Beispiel ein falscher DNS-Eintrag oder ein Kontoproblem) zu deuten sind.

```powershell
# 1) Standardtest auf dem lokalen DC, nur Fehler anzeigen (Skript-tauglich)
dcdiag /q

# 2) Ausfuehrlich mit Ergebnis in eine Datei, fuer die Dokumentation oder den Support
dcdiag /v /c /e /f:"D:\Berichte\dcdiag-$(Get-Date -f yyyyMMdd).txt"

# 3) Einzelne Tests: Konnektivitaet, Replikation, Dienste, FSMO, DNS-Details
dcdiag /s:DC02 /test:Connectivity
dcdiag /s:DC02 /test:Replications
dcdiag /s:DC02 /test:Services /test:Advertising /test:FsmoCheck /test:KnowsOfRoleHolders /test:RidManager
dcdiag /s:DC02 /test:DNS /DnsAll /v

# 4) Alle Domain Controller der Gesamtstruktur pruefen und die fehlgeschlagenen Tests extrahieren
$ausgabe = dcdiag /e /c 2>&1
$aktDC = $null
foreach ($z in $ausgabe) {
    if ($z -match "Testing server: .*\\(.+)$") { $aktDC = $Matches[1] }
    if ($z -match "failed test (\S+)") { [pscustomobject]@{ DC=$aktDC; Test=$Matches[1] } }
}

# 5) Als Skript fuer die Ueberwachung: Rueckgabe 0 = ok, 1 = Fehler
$fehler = dcdiag /q
if ($fehler) { $fehler; exit 1 } else { "dcdiag: alle Standardtests bestanden"; exit 0 }
```

Schritt 1 ist die tägliche Kurzprüfung: Mit `/q` erscheint nur etwas, wenn ein Test fehlschlägt. Schritt 2 erzeugt die vollständige Ausgabe und schreibt sie mit `/f` in eine Datei. Dieser Bericht gehört in jedes Ticket, das an einen Dienstleister oder den Hersteller geht. Schritt 3 zeigt gezielte Tests auf einem Partner und die ausführlichen DNS-Prüfungen, die auch die Delegierungen und Weiterleitungen testen. Schritt 4 wertet die Ausgabe aller Domain Controller mit regulären Ausdrücken aus: Er merkt sich, welcher Domain Controller gerade geprüft wird (die Zeile „Testing server: Standort\Name“), und gibt für jeden fehlgeschlagenen Test ein Objekt aus. Schritt 5 verpackt die Prüfung als Skript für ein Überwachungssystem: Der Rückgabewert entscheidet über OK oder Alarm. Das Auswerten der Textausgabe hängt von der Sprache des Betriebssystems ab („failed test“ erscheint auf deutschen Servern in englischer Form, weil `dcdiag` die Testnamen nicht übersetzt; die Begleittexte sind je nach Version unterschiedlich), deshalb sollte man das Muster am eigenen System prüfen.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, jede Warnung in der Ausgabe als Störung zu behandeln: Einige Tests melden bekannte, harmlose Hinweise (zum Beispiel im Systemprotokoll ältere Fehler, die schon behoben sind; sie bleiben dort für 24 Stunden sichtbar). Der zweite ist, die Reihenfolge zu ignorieren und mit dem letzten Fehler zu beginnen. Der dritte ist, `dcdiag` ohne ausreichende Rechte auszuführen; für entfernte Tests sind Administratorrechte nötig, sonst scheitern Tests mit Zugriffsfehlern, die wie Probleme des Domain Controllers aussehen. Der vierte ist, die DNS-Tests wegzulassen: Die Mehrzahl der Probleme mit Active Directory ist ein DNS-Problem.

```powershell
# FALSCH: Nur den letzten Fehler anschauen und dort reparieren
dcdiag | Select-String "failed" | Select-Object -Last 1

# RICHTIG: Ersten Fehler suchen, Folgefehler ignorieren, nach der Behebung erneut pruefen
dcdiag /s:DC02 /test:Connectivity
dcdiag /s:DC02 /test:DNS /DnsBasic
dcdiag /s:DC02 /q
```

> **Ergänzung aus der Nachrecherche**
>
> Zweck und Syntax von `dcdiag` beschreibt die abgerufene Seite „dcdiag“ der Befehlsreferenz, die Deutung der Ausgabe und die Ursachen typischer Fehler (inklusive der Ortung von Domain Controllern) die abgerufenen Seiten „DCDIAG.EXE /E or /A or /C expected errors“ und „Troubleshoot domain controller location issues in Windows“ (Microsoft Learn, Suchauszüge). Die Liste der Einzeltests und die Auswertung mit regulären Ausdrücken stammen aus dem Fachwissen; die Ausgabetexte sind versions- und sprachabhängig.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Administrator führt jeden Morgen `dcdiag /q` auf allen Domain Controllern aus, in einer geplanten Aufgabe, die bei Fehlern eine E-Mail schickt. An einem Dienstag meldet der Test *Advertising* auf DC02, dass der Domain Controller nicht als solcher auftritt. Ursache ist, dass der Dienst Netlogon nach einem Update nicht gestartet wurde. Nach dem Neustart des Dienstes ist der Test grün, und bevor sich ein Benutzer beschwert hat, ist das Problem behoben.

## 11.3 repadmin

Das Programm `repadmin` ist das Werkzeug für die Replikation. Es zeigt, wie die Domain Controller verbunden sind, wann sie zuletzt erfolgreich Änderungen ausgetauscht haben und woran es hakt, und es kann die Replikation anstoßen. Die Microsoft-Dokumentation zur Fehlersuche bei der Replikation nennt es als das Hauptwerkzeug. Die Funktion folgt dem Modell aus Modul 5: Jeder Domain Controller hat eingehende Replikationsverbindungen zu seinen Partnern, die vom KCC (Knowledge Consistency Checker) erzeugt werden; für jeden Namenskontext (Domain, Konfiguration, Schema, Anwendungspartitionen wie die DNS-Zonen) gibt es eine eigene Replikationsbeziehung.

Die wichtigsten Befehle: `repadmin /replsummary` zeigt eine Übersicht aller Domain Controller mit größter Verzögerung und Zahl der Fehler; es ist die erste Abfrage am Morgen. `repadmin /showrepl` zeigt für einen Domain Controller alle eingehenden Partner, den Zeitpunkt der letzten erfolgreichen und der letzten versuchten Replikation und den Fehlercode. `repadmin /showrepl * /csv` liefert dasselbe für alle Domain Controller in einer CSV-Tabelle, die man in Excel oder PowerShell weiterverarbeiten kann. `repadmin /syncall /AdeP` stößt die Synchronisation an. `repadmin /queue` zeigt, wie viele Replikationsaufträge warten. `repadmin /kcc` startet den KCC neu, damit er die Topologie neu berechnet. `repadmin /failcache` zeigt Verbindungsfehler, `repadmin /showutdvec` die Aktualitätsvektoren (welche Änderungen ein Domain Controller von welchem Partner kennt) und `repadmin /showobjmeta` die Replikationsmetadaten eines Objekts: wann und von welchem Domain Controller jedes Attribut zuletzt geändert wurde. Letzteres ist unschätzbar, wenn man wissen möchte, wer ein Kennwort zurückgesetzt hat. Mit `repadmin /options` kann man Optionen eines Domain Controllers lesen, zum Beispiel, ob er sich als Globaler Katalog anbietet. Zu den Eingriffen gehört `repadmin /removelingeringobjects` (siehe Modul 10).

Die Fehlercodes sind eine zweite Sprache, die man lernen muss. Die Dokumentation beschreibt unter anderem den Fehler 1722 (der RPC-Server ist nicht verfügbar; meist DNS, Firewall oder der Dienst ist nicht erreichbar), 8453 (Replikationszugriff verweigert; fehlende Rechte, oft nach einer Domänenverbindung oder bei einer Vertrauensstellung), 8606 (unzureichende Attribute, um ein Objekt zu erstellen; häufig Lingering Objects), 8461 (die Replikation wurde von einer Aufgabe höherer Priorität unterbrochen; laut Dokumentation kein Fehler, sondern meist ein vorübergehender Zustand), 8524 (DNS-Suche fehlgeschlagen, der Partner wird nicht über seine GUID im DNS gefunden) und 8456/8457 (Quelle oder Ziel akzeptiert keine ausgehende Replikation, oft durch bewusst gesetzte Optionen).

```powershell
# 1) Gesamtuebersicht (erste Pruefung am Morgen)
repadmin /replsummary

# 2) Details fuer einen Domain Controller; nur Fehler anzeigen
repadmin /showrepl DC02 /errorsonly

# 3) Alle Domain Controller als CSV, in PowerShell auswerten
repadmin /showrepl * /csv | ConvertFrom-Csv |
    Where-Object { $_."Number of Failures" -gt 0 } |
    Select-Object "Source DSA","Destination DSA","Naming Context","Number of Failures","Last Failure Time","Last Failure Status" |
    Format-Table -AutoSize

# 4) Sofort synchronisieren (alle Partner, alle Partitionen, ueber Standorte hinweg)
repadmin /syncall DC02 /AdeP

# 5) Wer hat wann die Gruppe "G-Helpdesk" geaendert? Metadaten des Objekts
repadmin /showobjmeta DC01 "CN=G-Helpdesk,OU=Gruppen,OU=Contoso,DC=corp,DC=contoso,DC=com"

# 6) Warteschlange und Topologie
repadmin /queue DC02
repadmin /kcc DC02
repadmin /bridgeheads

# 7) PowerShell-Alternative mit Objekten
Get-ADReplicationFailure -Target DC02
Get-ADReplicationPartnerMetadata -Target DC02 -Scope Server | Select-Object Partner, LastReplicationSuccess, LastReplicationResult
Get-ADReplicationUpToDatenessVectorTable -Target DC02 | Select-Object Partner, LastReplicationSuccess
```

Schritt 1 ist die Übersicht, in der die Spalten „largest delta“ (größte Verzögerung) und „fails“ (Fehlerzahl) beachtet werden. Schritt 2 reduziert die Ausgabe auf die Fehler. Schritt 3 lädt die Tabelle im CSV-Format, wandelt sie in PowerShell-Objekte um und filtert die Zeilen mit Fehlern; die Spaltennamen entsprechen der englischen Ausgabe. Schritt 4 startet die Synchronisation (`A` alle Partitionen, `d` IDs statt Namen, `e` über Standortgrenzen hinweg, `P` Push); danach sieht man in den Ergebnissen, welche Verbindungen funktionierten. Schritt 5 zeigt die Metadaten einer Gruppe: für jedes Attribut die Version, den Zeitpunkt und den Domain Controller, der die Änderung zuerst vorgenommen hat. Schritt 6 sind Eingriffe in die Topologie. Schritt 7 zeigt die PowerShell-Cmdlets, die dieselben Informationen als Objekte liefern, was für Berichte praktischer ist.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, bei Fehlern `repadmin /syncall` immer wieder zu starten, ohne die Ursache zu klären. Der zweite ist, dass man die Richtung vergisst: „Ziel“ ist der Empfänger, „Quelle“ der Absender; die Fehlermeldung steht beim *Empfänger*. Der dritte ist, Fehler 8453 als Netzwerkproblem zu behandeln, obwohl es ein Rechteproblem ist. Der vierte ist, die Replikation per Aktion „erzwingen“ als Heilung zu sehen: Sie beweist nur, dass der Weg im Moment funktioniert.

```powershell
# FALSCH: Bei Fehler 1722 wiederholt syncall starten
repadmin /syncall /AdeP
repadmin /syncall /AdeP

# RICHTIG: Ursache klaeren - Namensaufloesung, Erreichbarkeit, Ports, Dienste
nslookup dc02.corp.contoso.com
Test-NetConnection dc02.corp.contoso.com -Port 135
Test-NetConnection dc02.corp.contoso.com -Port 389
dcdiag /s:DC02 /test:Connectivity
```

> **Ergänzung aus der Nachrecherche**
>
> Den Einsatz von `repadmin` bei der Fehlersuche und die Bedeutung der Fehlercodes 1722, 8453, 8606, 8461 und 8524 behandeln die abgerufenen Seiten „Diagnose Active Directory replication failures“, „Troubleshoot AD replication error 1722“, „8453“, „8606“, „8461“ und „Troubleshooting Active Directory replication problems“ (Microsoft Learn, Suchauszüge). Die Auswahl der Befehlsschalter, die Spaltennamen der CSV-Ausgabe und die PowerShell-Cmdlets stammen aus dem Fachwissen und sind in der eigenen Version zu prüfen.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein neu installierter Domain Controller wird nicht in der Replikationsübersicht angezeigt. `repadmin /showrepl` meldet Fehler 8524 gegenüber DC01. Die Ursache: Der CNAME-Eintrag in der Zone `_msdcs`, mit dem Partner einen Domain Controller über seine GUID finden, wurde nicht angelegt, weil der Netlogon-Dienst auf dem neuen Server beim ersten Start keine Verbindung zu DNS hatte. Nach dem Neuregistrieren (`ipconfig /registerdns` und Neustart von Netlogon) ist die Replikation in Ordnung.

## 11.4 nltest

Das Programm `nltest` prüft die Teile von Windows, die für die Anmeldung zuständig sind: den *sicheren Kanal* (Secure Channel) zwischen einem Rechner und seinem Domain Controller und die *Domain-Controller-Ortung* (Locator). Wenn sich ein Mitgliedsrechner anmeldet oder ein Benutzer authentifiziert werden muss, fragt der Dienst Netlogon zuerst per DNS nach den SRV-Einträgen, ermittelt einen Domain Controller im eigenen Standort (Modul 5), verbindet sich und baut einen sicheren Kanal auf, der durch das Kennwort des Computerkontos geschützt ist. Ist dieses Kennwort nicht mehr synchron (zum Beispiel nach der Wiederherstellung eines Rechners aus einem alten Abbild), schlägt der sichere Kanal fehl, und der Rechner meldet „Die Vertrauensstellung zwischen dieser Arbeitsstation und der primären Domäne ist fehlgeschlagen“.

Die wichtigsten Befehle: `nltest /dsgetdc:corp.contoso.com` zeigt den Domain Controller, den dieser Rechner für die Domäne verwendet, und Eigenschaften wie Standort und Rollen; mit Schaltern wie `/GC`, `/PDC` oder `/FORCE` wählt man eine bestimmte Rolle beziehungsweise einen neuen Suchlauf. `nltest /dsgetsite` zeigt den Active-Directory-Standort des Rechners; ist er falsch, authentifiziert der Rechner an einem weit entfernten Domain Controller (Modul 5). `nltest /dclist:corp.contoso.com` listet alle Domain Controller der Domäne. `nltest /sc_query:corp.contoso.com` zeigt den Zustand des sicheren Kanals, `nltest /sc_verify:corp.contoso.com` prüft ihn, und `nltest /sc_reset:corp.contoso.com` baut ihn neu auf. `nltest /domain_trusts` listet die Vertrauensstellungen. `nltest /whowill:corp.contoso.com benutzer` zeigt, welcher Domain Controller einen Benutzer authentifizieren würde.

In den abgerufenen Microsoft-Seiten kommen `nltest`-Aufrufe vor allem in Anleitungen zur Domänenverbindung und zur Standort-Zuordnung vor; als eigene Befehlsreferenz wurde die Seite nicht gelesen. Die Aussagen in dieser Lerneinheit zu den Schaltern folgen daher dem Fachwissen und sollten mit `nltest /?` am eigenen System abgeglichen werden.

```powershell
# 1) Welchen Domain Controller nutzt dieser Rechner? Standort?
nltest /dsgetdc:corp.contoso.com
nltest /dsgetsite

# 2) Alle Domain Controller der Domaene und die Rollen
nltest /dclist:corp.contoso.com
nltest /dsgetdc:corp.contoso.com /PDC
nltest /dsgetdc:corp.contoso.com /GC

# 3) Sicheren Kanal pruefen und bei Bedarf reparieren
nltest /sc_query:corp.contoso.com
nltest /sc_verify:corp.contoso.com
nltest /sc_reset:corp.contoso.com

# 4) Alternative per PowerShell (reparieren des sicheren Kanals mit Anmeldedaten)
Test-ComputerSecureChannel -Verbose
Test-ComputerSecureChannel -Repair -Credential (Get-Credential CORP\adm.mmeier)

# 5) Wer wuerde einen Benutzer authentifizieren, und welche Vertrauensstellungen gibt es?
nltest /whowill:corp.contoso.com mmeier
nltest /domain_trusts /all_trusts

# 6) Auswertung als Skript: Pruefen, ob der Rechner im richtigen Standort ist
$site = (nltest /dsgetsite)[0]
"Aktueller Standort: $site"
if ($site -notmatch "Wien") { Write-Warning "Rechner PC01 sollte im Standort Wien sein - Subnetz pruefen!" }
```

Schritt 1 zeigt, welcher Domain Controller verwendet wird; in der Ausgabe stehen Name, Adresse, GUID, Domäne, Standort und Flags. Schritt 2 zeigt die Liste und die Rollen. Schritt 3 fragt den sicheren Kanal ab: `sc_query` zeigt den letzten Status und den verwendeten Domain Controller, `sc_verify` prüft aktiv, `sc_reset` baut ihn neu auf. Schritt 4 zeigt das PowerShell-Pendant: `Test-ComputerSecureChannel` prüft, und mit `-Repair` und administrativen Anmeldedaten setzt es das Computerkennwort zurück. Schritt 5 untersucht die Authentifizierung und die Vertrauensstellungen. Schritt 6 wertet die Standortausgabe aus und warnt, wenn sie nicht zum erwarteten Wert passt; der Standortname „Wien“ ist ein Beispiel.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, bei einer defekten Vertrauensstellung eines Rechners das Konto zu löschen und den Rechner neu in die Domäne aufzunehmen, obwohl `Test-ComputerSecureChannel -Repair` genügt hätte; beim Löschen gehen die Gruppenmitgliedschaften und SIDs des Computerkontos verloren. Der zweite ist, nach einem falschen Standort im Subnetz-Eintrag zu suchen, aber nicht im Active Directory Standorte und Dienste (Modul 5). Der dritte ist, dass `nltest /dsgetdc` die Antwort aus einem Zwischenspeicher liefert; mit `/force` erzwingt man eine neue Suche.

```powershell
# FALSCH: Computerkonto loeschen und Rechner neu aufnehmen
Remove-ADComputer -Identity "PC01" -Confirm:$false

# RICHTIG: Sicheren Kanal reparieren (Kennwort des Computerkontos neu abstimmen)
Test-ComputerSecureChannel -Repair -Credential (Get-Credential CORP\adm.mmeier)
nltest /sc_verify:corp.contoso.com
```

> **Ergänzung aus der Nachrecherche**
>
> Die abgerufenen Microsoft-Learn-Seiten zeigen `nltest /dsgetdc` (auch mit `/force`), `/dsgetsite`, `/dclist` und `/sc_reset` in Anleitungen, darunter die Seite zum Ereignis 5719 („Domain controller or domain not found“) und die Seite zur Ortung von Domain Controllern, die außerdem das Netlogon-Debugprotokoll mit `nltest /dbflag` nennt (Suchauszüge); die vollständige Befehlsreferenz wurde nicht gelesen. Die Erklärung des sicheren Kanals, der Ortung und der weiteren Schalter, sowie das Cmdlet `Test-ComputerSecureChannel`, stammen aus dem Fachwissen. Die Standortzuordnung und die SRV-Einträge werden in Modul 5 und Modul 6 erklärt.

### Praxisbezug

> **Praxisbeispiel**
>
> Nach der Wiederherstellung eines Arbeitsplatz-Abbilds von vor drei Monaten kann sich niemand mehr anmelden: „Die Vertrauensstellung ... ist fehlgeschlagen“. Der Techniker meldet sich lokal an, führt `Test-ComputerSecureChannel -Repair` mit administrativen Anmeldedaten aus und der Rechner ist in einer Minute wieder in der Domäne, mit allen Gruppenrichtlinien und Mitgliedschaften. Hätte er das Konto gelöscht, wäre die Software-Verteilung und die Zuordnung zur Gruppe der Drucker verloren gewesen.

## 11.5 PowerShell AD Modul

Das PowerShell-Modul *ActiveDirectory* ist seit Modul 2 ein ständiger Begleiter. Hier steht es unter dem Gesichtspunkt des *Betriebs*: Wie fragt man das Verzeichnis zuverlässig ab, wie schreibt man Skripte, die auch bei zehntausenden Objekten funktionieren, und wie baut man daraus Berichte und Prüfungen. Das Modul spricht über die *Active Directory Web Services* (ADWS) mit dem Verzeichnis; der Dienst läuft auf Domain Controllern auf Port 9389. Ist er nicht gestartet, melden alle Cmdlets Verbindungsfehler, obwohl Active Directory läuft, ein oft übersehener Fehler.

Für den Betrieb gelten einige Grundregeln. Erstens: Immer *serverseitig filtern*. Der Parameter `-Filter` wird vom Domain Controller ausgewertet und liefert nur die passenden Objekte; wer erst alle Objekte lädt und dann mit `Where-Object` filtert, überträgt unnötig viele Daten. Zweitens: Nur die *benötigten Eigenschaften* anfordern. Standardmäßig liefern die Cmdlets nur einen kleinen Satz; mit `-Properties` fordert man weitere an, mit `-Properties *` alle, was bei großen Abfragen langsam ist. Drittens: Mit `-SearchBase` und `-SearchScope` den Suchbereich begrenzen. Viertens: Bei großen Ergebnismengen den Parameter `-ResultPageSize` und `-ResultSetSize` beachten und gezielte Server mit `-Server` wählen, damit man weiß, welchen Domain Controller man abfragt (wichtig bei Replikationsverzug). Fünftens: Änderungen immer zuerst mit `-WhatIf` testen und mit `-Confirm` absichern.

Das Modul enthält ferner Cmdlets für den Betrieb selbst: `Get-ADDomainController`, `Get-ADReplicationPartnerMetadata`, `Get-ADReplicationFailure`, `Get-ADReplicationQueueOperation`, `Sync-ADObject` (ein einzelnes Objekt sofort replizieren), `Get-ADForest` und `Get-ADDomain` mit den Rolleninhabern sowie `Get-ADRootDSE` mit Informationen zum Domain Controller, zum Beispiel der aktuellen Zeit und den Namenskontexten. Wichtig für Berichte sind die Attribute `lastLogonTimestamp` (wird nur ca. alle 14 Tage aktualisiert, aber repliziert) und `lastLogon` (genau, aber nicht repliziert, daher auf jedem Domain Controller einzeln abzufragen).

```powershell
Import-Module ActiveDirectory

# 1) Dienst und Erreichbarkeit pruefen (ADWS, Port 9389)
Get-Service ADWS -ComputerName DC01 | Select-Object MachineName, Status
Test-NetConnection DC01 -Port 9389 | Select-Object ComputerName, TcpTestSucceeded

# 2) Effiziente Abfrage: serverseitiger Filter, Suchbereich, nur noetige Eigenschaften
$grenzeFile = (Get-Date).AddDays(-90).ToFileTime()
Get-ADUser -Filter "Enabled -eq 'true' -and lastLogonTimestamp -lt $grenzeFile" `
    -SearchBase "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" -SearchScope Subtree `
    -Properties lastLogonTimestamp, Department |
  Select-Object SamAccountName, Department, @{n="LetzteAnmeldung";e={[datetime]::FromFileTime($_.lastLogonTimestamp)}} |
  Sort-Object LetzteAnmeldung | Select-Object -First 20

# 3) Genaue letzte Anmeldung: lastLogon auf JEDEM Domain Controller abfragen und den neuesten Wert nehmen
function Get-LetzteAnmeldung($sam) {
    $zeiten = foreach ($dc in (Get-ADDomainController -Filter *).HostName) {
        (Get-ADUser $sam -Server $dc -Properties lastLogon -ErrorAction SilentlyContinue).lastLogon
    }
    $max = ($zeiten | Measure-Object -Maximum).Maximum
    if ($max) { [datetime]::FromFileTime($max) }
}
Get-LetzteAnmeldung "mmeier"

# 4) Aenderung zuerst testen, dann ausfuehren, dann sofort replizieren
Get-ADUser -Filter 'Department -eq "Vertrieb"' -SearchBase "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" |
    Set-ADUser -Description "Vertrieb 2026" -WhatIf
Set-ADUser "mmeier" -Description "Teamleitung" -Server DC01
Sync-ADObject -Object (Get-ADUser "mmeier").DistinguishedName -Source DC01 -Destination DC02

# 5) Betriebsabfrage: Domain Controller, Rollen, Zeit laut RootDSE
Get-ADDomainController -Filter * | Select-Object Name, Site, IsGlobalCatalog, OperationMasterRoles | Format-Table -AutoSize
(Get-ADRootDSE -Server DC02).currentTime
```

Schritt 1 prüft, ob der Dienst ADWS auf dem Domain Controller läuft und der Port erreichbar ist; fehlt der Dienst, versagt jedes weitere Cmdlet. Schritt 2 zeigt die effiziente Abfrage: Der Zeitpunkt wird in das Dateizeit-Format umgerechnet, weil `lastLogonTimestamp` als 64-Bit-Zahl gespeichert ist; der Filter enthält diese Zahl, wird auf dem Domain Controller ausgewertet, und der Suchbereich ist die OU der Benutzer. Schritt 3 zeigt eine Funktion, die den genauen Wert abfragt: Weil `lastLogon` nicht repliziert wird, fragt sie alle Domain Controller ab und nimmt den größten Wert. Schritt 4 zeigt die sichere Reihenfolge einer Änderung: Mit `-WhatIf` anzeigen, was passieren würde, dann ausführen, dann das einzelne Objekt sofort replizieren. Schritt 5 liest betriebliche Informationen, darunter die Zeit des Domain Controllers, mit der sich Zeitabweichungen erkennen lassen.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, mit `Get-ADUser -Filter * -Properties *` zu arbeiten und dann in PowerShell zu filtern; bei 50 000 Objekten dauert das Minuten und belastet den Domain Controller. Der zweite ist, `lastLogonTimestamp` als genauen Wert zu lesen und deshalb Konten als „inaktiv“ zu löschen, die erst gestern verwendet wurden. Der dritte ist, ein Skript mit einem Filterausdruck zu schreiben, der in PowerShell-Syntax, nicht in der Syntax des Filters, gebaut ist (zum Beispiel Verwendung von `-like` mit Platzhaltern, die der Filter nicht kennt). Der vierte ist, Änderungen ohne `-Server` an einem zufälligen Domain Controller vorzunehmen und dann eine Replikationsverzögerung zu übersehen.

```powershell
# FALSCH: Alles laden und lokal filtern, alle Eigenschaften holen
Get-ADUser -Filter * -Properties * | Where-Object { $_.Department -eq "Vertrieb" }

# RICHTIG: Serverseitig filtern, Suchbereich begrenzen, nur noetige Eigenschaften
Get-ADUser -Filter 'Department -eq "Vertrieb"' -SearchBase "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" `
    -Properties Department, Title | Select-Object SamAccountName, Title
```

> **Ergänzung aus der Nachrecherche**
>
> Das Cmdlet `Enable-ADOptionalFeature` und das Verwaltungscenter mit seiner PowerShell-Verlaufsanzeige sind in den abgerufenen Seiten der Microsoft-Dokumentation beschrieben (Suchauszüge). Die Betriebsregeln (serverseitig filtern, Eigenschaften begrenzen, `-Server` verwenden), die Rolle des Dienstes ADWS auf Port 9389, die Eigenschaften von `lastLogon` und `lastLogonTimestamp` sowie die Cmdlets zur Replikation stammen aus dem Fachwissen und sind nicht einzeln abgerufen worden.

### Praxisbezug

> **Praxisbeispiel**
>
> Der Administrator bekommt den Auftrag, jede Woche eine Liste inaktiver Konten zu liefern. Seine erste Version mit `Get-ADUser -Filter * -Properties *` läuft zwanzig Minuten und liefert zu viele Treffer, weil `lastLogonTimestamp` nicht genau ist. Die verbesserte Version filtert serverseitig auf einen 100-Tage-Zeitraum, prüft die Kandidaten zusätzlich mit dem genauen `lastLogon` auf allen Domain Controllern und läuft in zwei Minuten. Die Liste ist genauer und belastet die Domain Controller kaum.

## 11.6 Performance Monitoring

Ein Domain Controller ist ein Dienstleister, der im Hintergrund unzählige Anfragen beantwortet: Anmeldungen, Ticketanforderungen, LDAP-Abfragen von Anwendungen, DNS-Auflösungen, Replikation. Wird er langsam, spürt das jeder Benutzer, aber meist ohne zu wissen, warum. Die *Leistungsüberwachung* (Performance Monitoring) soll zwei Fragen beantworten: Ist der Domain Controller im Moment überlastet, und wird er es in absehbarer Zeit sein? Die zweite Frage heißt *Kapazitätsplanung* und ist wichtiger, weil sie Zeit lässt, vor dem Problem zu reagieren.

Die Microsoft-Dokumentation zur Kapazitätsplanung für Active Directory Domain Services gliedert die Betrachtung in vier Ressourcen: Speicher (Arbeitsspeicher und Festplatte), Netzwerk, Prozessor und die Antwortzeiten. Die zentrale Erkenntnis ist, dass der wichtigste Faktor der *Arbeitsspeicher* ist. Active Directory arbeitet am besten, wenn die Verzeichnisdatenbank (`ntds.dit`) möglichst vollständig im Cache des Betriebssystems liegt, denn dann entfällt der langsame Zugriff auf die Festplatte. Als Faustformel gilt: Der Domain Controller sollte so viel Arbeitsspeicher haben, wie die Datenbank groß ist, zuzüglich dem Bedarf für das Betriebssystem und die Dienste (Windows, `lsass.exe`, DNS), und für Domain Controller mit Globalem Katalog entsprechend die Größe der Datenbank der gesamten Gesamtstruktur. Die Prozessorlast wird im Wesentlichen vom Prozess `lsass.exe` verursacht, der die Authentifizierung und die LDAP-Anfragen bearbeitet; die Dokumentation empfiehlt, die Auslastung im Normalbetrieb deutlich unter 40 Prozent zu halten, damit bei Ausfall eines Partners die Last aufgefangen werden kann (das Prinzip „N+1“).

Für die Messung gibt es die Leistungsindikatoren (Performance Counter), die man mit der *Leistungsüberwachung* (perfmon) oder dem Cmdlet `Get-Counter` liest. Wichtig sind: `Processor\% Processor Time` und `Process(lsass)\% Processor Time` für die Rechenlast; `Memory\Available MBytes` und `Memory\Pages/sec` für den Speicherdruck; `LogicalDisk\Avg. Disk sec/Read` (Lesedauer pro Zugriff) für die Festplatte, wobei Werte dauerhaft über etwa 10 bis 15 Millisekunden auf eine zu langsame Platte oder einen zu kleinen Cache hindeuten; `NTDS\LDAP Searches/sec`, `NTDS\LDAP Client Sessions` und `NTDS\DRA Inbound Bytes Total/sec` für die Verzeichnisaktivität und Replikation; `Security System-Wide Statistics\Kerberos Authentications` und `NTLM Authentications` für die Anmeldelast sowie `Netlogon(*)\Semaphore Waiters` und `Semaphore Timeouts` als Zeichen eines überlasteten sicheren Kanals. Bei Letzterem entstehen Engpässe, wenn zu viele Anmeldungen auf einen Domain Controller treffen.

Neben den Zählern gibt es die *Diagnoseprotokollierung* von Active Directory. Setzt man im Registrierungsschlüssel `HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics` den Wert „15 Field Engineering“ auf 5, dann schreibt der Domain Controller bei teuren, ineffizienten oder lange laufenden LDAP-Abfragen das Ereignis 1644 in das Protokoll „Directory Service“, mit Angabe des Clients, des Filters und der durchsuchten Objekte. So findet man die Anwendung, die den Domain Controller mit unscharfen Suchen belastet. Auf Produktivsystemen setzt man diese Protokollierung nur zeitweise ein, da sie viele Ereignisse erzeugt.

```powershell
# 1) Momentaufnahme der wichtigsten Zaehler auf dem lokalen Domain Controller (3 Messungen im Abstand von 5 s)
$zaehler = @(
  '\Processor(_Total)\% Processor Time',
  '\Process(lsass)\% Processor Time',
  '\Memory\Available MBytes',
  '\LogicalDisk(C:)\Avg. Disk sec/Read',
  '\NTDS\LDAP Searches/sec',
  '\NTDS\LDAP Client Sessions',
  '\NTDS\DRA Inbound Bytes Total/sec',
  '\Security System-Wide Statistics\Kerberos Authentications',
  '\Netlogon(*)\Semaphore Waiters'
)
Get-Counter -Counter $zaehler -SampleInterval 5 -MaxSamples 3 -ErrorAction SilentlyContinue |
  ForEach-Object { $_.CounterSamples | Select-Object @{n="Zeit";e={$_.Timestamp}}, Path, CookedValue }

# 2) Datenbank- und Speichergroesse vergleichen (Faustformel: RAM >= Groesse der ntds.dit + Betriebssystem)
$dbPfad = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters")."DSA Database file"
$dbGB   = [math]::Round((Get-Item $dbPfad).Length / 1GB, 2)
$ramGB  = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
"ntds.dit: $dbGB GB, Arbeitsspeicher: $ramGB GB"

# 3) Datensammler-Satz anlegen, der alle 15 Sekunden misst und eine CSV schreibt (Basislinie!)
$dsName = "AD-Basislinie"
logman create counter $dsName -c $zaehler -si 00:00:15 -o "D:\Perf\AD-Basislinie" -f csv --v
logman start $dsName
# spaeter: logman stop $dsName

# 4) Teure LDAP-Abfragen sichtbar machen (nur zeitweise!) - Ereignis 1644 im Protokoll "Directory Service"
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" -Name "15 Field Engineering" -Value 5
# Auswertung nach einigen Stunden:
Get-WinEvent -FilterHashtable @{ LogName="Directory Service"; Id=1644; StartTime=(Get-Date).AddHours(-4) } -ErrorAction SilentlyContinue |
  Select-Object TimeCreated, @{n="Client";e={($_.Message -split "`n" | Select-String "Client")[0]}} | Group-Object Client | Sort-Object Count -Descending
# Danach wieder ausschalten:
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" -Name "15 Field Engineering" -Value 0
```

Schritt 1 liest neun Zähler dreimal im Abstand von fünf Sekunden; die Zählerpfade stehen in Hochkommas, damit PowerShell das Prozentzeichen nicht deutet. Die Zählernamen sind auf Systemen mit deutscher Oberfläche lokalisiert (zum Beispiel „Prozessor“ statt „Processor“); auf solchen Servern ruft man `typeperf -q` auf, um die Namen zu sehen, oder nutzt die englischen Namen auf einem englischsprachigen System. Schritt 2 vergleicht die Datenbankgröße mit dem Arbeitsspeicher und prüft die Faustformel. Schritt 3 legt einen Datensammler-Satz mit `logman` an, der alle 15 Sekunden misst und in eine CSV-Datei schreibt: Die so gewonnene *Basislinie* (Baseline) ist die wertvollste Datenquelle überhaupt, weil sie zeigt, was normal ist. Ohne Basislinie weiß man bei einem Messwert von 60 Prozent Prozessorlast nicht, ob das ein Problem ist. Schritt 4 schaltet die Protokollierung für teure Abfragen ein, wertet die Ereignisse 1644 aus (gruppiert nach Client) und schaltet sie wieder aus.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, nur bei Problemen zu messen: Ohne Basislinie sind die Zahlen wertlos. Der zweite ist, die Last als Prozentzahl des einzelnen Servers zu betrachten, ohne den Ausfall eines Partners einzuplanen. Der dritte ist, den Speicher zu knapp zu bemessen und stattdessen die Prozessoren aufzustocken. Der vierte ist, die Diagnoseprotokollierung dauerhaft eingeschaltet zu lassen, wodurch das Protokoll in Stunden überläuft und Platz und Leistung kostet.

```powershell
# FALSCH: Diagnoseprotokollierung dauerhaft auf hoher Stufe
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" -Name "15 Field Engineering" -Value 5

# RICHTIG: Zeitlich begrenzt einschalten, auswerten, wieder auf 0 setzen
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" -Name "15 Field Engineering" -Value 5
Start-Sleep -Seconds 3600
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" -Name "15 Field Engineering" -Value 0
```

> **Ergänzung aus der Nachrecherche**
>
> Die vier Ressourcen der Kapazitätsplanung (Speicher, Netzwerk, Prozessor, Antwortzeit), die zentrale Rolle des Arbeitsspeichers für den Datenbank-Cache, die Rolle von `lsass.exe` bei der Prozessorlast und die Überlegungen zu LDAP-Abfragen und zum Ereignis 1644 beruhen auf den abgerufenen Seiten „Capacity planning for Active Directory Domain Services“ und „LDAP considerations“ (Microsoft Learn, Suchauszüge, die vollständigen Seiten wurden nicht gelesen). Die genauen Zählernamen, die Richtwerte für die Festplattenlatenz (10 bis 15 Millisekunden) und die 40-Prozent-Grenze sind aus dem Fachwissen genannt; die Dokumentation nennt eigene Zahlen, die vor einer Planung nachzulesen sind. Der Registrierungspfad der Diagnoseprotokollierung ist Fachwissen und im Labor zu prüfen.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen klagt über langsame Anmeldungen am Montagmorgen. Die Basislinie zeigt, dass die Prozessorlast von `lsass` zwischen 7:45 und 8:15 Uhr auf 90 Prozent steigt, und die Ereignisse 1644 verraten einen Dienstleister-Server, der alle fünf Sekunden die gesamte Domäne durchsucht. Die Anwendung wird auf einen eingeschränkten Filter umgestellt, die Last sinkt, und der Plan für zusätzliche Hardware wird nicht gebraucht. Ohne Messung wäre die Lösung ein teurerer Server gewesen.

## 11.7 Health Checks

Ein *Health Check* ist die planmäßige Prüfung des Gesundheitszustands. Er unterscheidet sich von der Störungssuche dadurch, dass er nicht auf ein Problem reagiert, sondern es sucht, bevor es auftritt. Ein guter Health Check hat feste Bestandteile, läuft nach festem Plan und liefert ein Ergebnis, das man mit dem letzten vergleichen kann. Er stützt sich auf die Werkzeuge der vorigen Lerneinheiten: `dcdiag` für den Zustand der Domain Controller, `repadmin` für die Replikation, die Ereignisprotokolle für Warnungen, `nltest` und DNS-Prüfungen für die Erreichbarkeit, die Zähler für die Leistung und die Sicherung (Modul 10) für die Wiederherstellbarkeit.

Eine sinnvolle Gliederung ist nach Häufigkeit: *Täglich* (automatisch): Dienste laufen, Replikation fehlerfrei, keine kritischen Ereignisse, Sicherung erfolgreich, Speicherplatz in Ordnung. *Wöchentlich*: Zeit und Zeitquelle (die Hierarchie aus Modul 6), DNS-Einträge der Domain Controller, SYSVOL-Freigaben, Zahl und Mitglieder der privilegierten Gruppen (Modul 9), Anzahl der Konten ohne Anmeldung. *Monatlich*: Patchstand, Leistungsbasislinie im Vergleich zum Vormonat, Funktionsebene und Schema-Version, Ablauf von Zertifikaten der Domain Controller, Test der Wiederherstellung eines Objekts. *Jährlich*: vollständiger DR-Test (Modul 10), Überprüfung des Tier-Modells (Modul 9), Kennwörter der Notfallkonten, Überprüfung des Runbooks. Die Prüfpunkte, die sich in einem Skript automatisieren lassen, gehören in das Skript; was nur der Mensch beurteilen kann, steht in der Checkliste.

Wichtig ist die Form des Ergebnisses. Ein Health Check, der mit „alles in Ordnung“ endet, hilft niemandem, wenn man später nicht sehen kann, was geprüft wurde. Deshalb schreibt man das Ergebnis als Bericht mit Datum, Prüfpunkten, Ergebnis (OK, Warnung, Fehler), Messwerten und Bemerkungen. Der Bericht der Vorwoche liegt daneben, und Abweichungen werden hervorgehoben.

```powershell
Import-Module ActiveDirectory
$datum  = Get-Date -Format "yyyy-MM-dd HH:mm"
$bericht = [System.Collections.Generic.List[object]]::new()
function Pruefpunkt($Bereich, $Name, $Status, $Wert) {
    $bericht.Add([pscustomobject]@{ Bereich=$Bereich; Pruefung=$Name; Status=$Status; Wert=$Wert })
}
$dcs = Get-ADDomainController -Filter *

foreach ($dc in $dcs) {
    $n = $dc.HostName
    # 1) Erreichbarkeit und Dienste
    $ping = Test-Connection $n -Count 1 -Quiet
    Pruefpunkt "Netz" "$n erreichbar" ($(if ($ping) {"OK"} else {"FEHLER"})) $ping
    if (-not $ping) { continue }
    $dienste = Get-Service -ComputerName $n NTDS, Netlogon, DNS, KDC, DFSR, W32Time -ErrorAction SilentlyContinue |
               Where-Object Status -ne "Running"
    Pruefpunkt "Dienste" "$n Dienste" ($(if ($dienste) {"FEHLER"} else {"OK"})) (($dienste.Name) -join ",")

    # 2) Freier Speicherplatz auf dem Systemlaufwerk
    $d = Get-CimInstance Win32_LogicalDisk -ComputerName $n -Filter "DeviceID='C:'"
    $frei = [math]::Round($d.FreeSpace / $d.Size * 100, 1)
    Pruefpunkt "Speicher" "$n freier Platz C:" ($(if ($frei -lt 15) {"WARNUNG"} else {"OK"})) "$frei %"

    # 3) Zeitabweichung zum PDC-Emulator
    $off = (w32tm /stripchart /computer:$n /samples:1 /dataonly 2>$null | Select-Object -Last 1)
    Pruefpunkt "Zeit" "$n Zeitabweichung" "INFO" $off

    # 4) Kritische Ereignisse in den letzten 24 Stunden
    $ev = Get-WinEvent -ComputerName $n -FilterHashtable @{ LogName="Directory Service","DNS Server","DFS Replication"; Level=1,2; StartTime=(Get-Date).AddDays(-1) } -ErrorAction SilentlyContinue
    Pruefpunkt "Ereignisse" "$n Fehler (24 h)" ($(if (@($ev).Count -gt 0) {"WARNUNG"} else {"OK"})) @($ev).Count
}

# 5) Replikation: Fehler zaehlen
$fehler = @(repadmin /showrepl * /csv | ConvertFrom-Csv | Where-Object { [int]$_."Number of Failures" -gt 0 }).Count
Pruefpunkt "Replikation" "Verbindungen mit Fehlern" ($(if ($fehler -gt 0) {"FEHLER"} else {"OK"})) $fehler

# 6) Ausgabe und Ablage (mit Datum, damit Vergleiche moeglich sind)
$bericht | Format-Table -AutoSize
$bericht | Export-Csv "D:\Berichte\HealthCheck-$(Get-Date -f yyyyMMdd).csv" -NoTypeInformation -Encoding UTF8
$bericht | Where-Object Status -in "FEHLER","WARNUNG" | Format-Table -AutoSize
```

Der Bericht entsteht aus einer Liste von Prüfpunkten, die jeweils Bereich, Name, Status und Wert tragen. Für jeden Domain Controller werden vier Dinge geprüft: Erreichbarkeit mit `Test-Connection`, Dienste (alle sollen laufen), freier Speicherplatz auf C: (unter 15 Prozent gibt es eine Warnung) und kritische Ereignisse in den wichtigen Protokollen der letzten 24 Stunden. Die Zeitabweichung wird mit `w32tm /stripchart` als Information ausgegeben (die Ausgabe hängt von der Sprache ab, deshalb wird sie nicht automatisch bewertet). Die Replikation wird insgesamt mit `repadmin /showrepl * /csv` geprüft. Das Ergebnis wird mit Datum im Namen als CSV gespeichert; die letzte Zeile zeigt nur Warnungen und Fehler, damit man bei einem Blick sieht, was zu tun ist. Der Ausdruck `($(if ...))` liefert in Klammern den Statuswert.

### Typische Fehler und Stolperfallen

Der erste Fehler ist ein Health Check, der nur manuell und unregelmäßig läuft: Er wird dann eingestellt, sobald Zeitdruck herrscht. Der zweite ist, Ergebnisse nicht aufzuheben. Der dritte ist, zu viele Prüfpunkte zu automatisieren, so dass die Berichte voller Warnungen sind, die niemand liest („Alarmmüdigkeit“); lieber wenige, wichtige Punkte mit klaren Schwellen. Der vierte ist, die Prüfung ausschließlich mit dem Konto eines Domänenadministrators auszuführen: Ein Konto mit Leserechten auf Domain Controllern genügt (Modul 9).

```powershell
# FALSCH: Health Check nur im Kopf - "ich schaue gelegentlich in die Konsole"
Get-ADDomainController -Filter * | Out-Null

# RICHTIG: Geplante Aufgabe, die jeden Morgen den Bericht erzeugt und Fehler per Mail meldet
$aktion = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File D:\Skripte\HealthCheck.ps1"
Register-ScheduledTask -TaskName "AD-HealthCheck" -Action $aktion -Trigger (New-ScheduledTaskTrigger -Daily -At 6am) -User "CORP\svc-healthcheck" -Password "<Kennwort>" -RunLevel Limited
```

> **Ergänzung aus der Nachrecherche**
>
> Die Auswahl der Prüfpunkte folgt den Leitfäden der Microsoft-Dokumentation zur Überwachung von Active Directory („Monitoring Active Directory for Signs of Compromise“, „Appendix L: Events to Monitor“) und den Hinweisen zur Kapazitätsplanung, die in den vorangehenden Lerneinheiten abgerufen und genannt wurden. Die Einteilung in tägliche, wöchentliche, monatliche und jährliche Prüfungen, die Schwellenwerte (15 Prozent freier Platz) und das Skript sind betriebliche Erfahrungswerte und kein Microsoft-Standard. Als Konto für geplante Prüfungen ist ein gruppenverwaltetes Dienstkonto (gMSA, Modul 4) dem im Beispiel gezeigten Konto mit Kennwort vorzuziehen.

### Praxisbezug

> **Praxisbeispiel**
>
> Der tägliche Bericht erreicht das Team um 6:30 Uhr als kurze E-Mail: drei Zeilen, wenn alles in Ordnung ist, sonst die Liste der Abweichungen. An einem Morgen im Herbst steht dort eine Warnung: Auf DC02 sind nur noch 9 Prozent Speicherplatz frei. Die Ursache sind angewachsene Protokolldateien, die der Administrator vor dem Arbeitsbeginn bereinigt. Nach der Einführung der Prüfung gab es in zwei Jahren keinen Ausfall wegen eines vollen Laufwerks mehr, vorher zwei.

## 11.8 Troubleshooting Methodik

Gute Fehlersuche ist weniger eine Frage des Wissens als eine Frage der Disziplin. Wer bei einer Störung sofort Befehle eintippt, ändert oft mehrere Dinge gleichzeitig und weiß hinterher nicht mehr, was gewirkt hat. Eine bewährte Methodik besteht aus sechs Schritten, die man sich wie einen Kreislauf vorstellen kann. Erstens: *Problem beschreiben*. Was genau funktioniert nicht, für wen, seit wann, an welchem Standort, auf welchem Gerät? „Das Internet geht nicht“ ist keine Beschreibung; „Benutzer in der Filiale kommen seit 8:10 Uhr nicht mehr an die Dateifreigabe, per IP-Adresse schon“ schon. Zweitens: *Umfang eingrenzen*. Ist ein Benutzer betroffen oder alle? Ein Rechner oder ein Standort? Ein Domain Controller oder die ganze Domäne? Dieser Schritt reduziert die möglichen Ursachen am stärksten. Drittens: *Änderungen erfragen*. Was wurde zuletzt geändert (Update, neue Richtlinie, Firewall-Regel, Umzug, Zertifikatserneuerung)? Die meisten Störungen haben eine Änderung als Auslöser. Viertens: *Hypothese bilden und prüfen*, wobei man mit der wahrscheinlichsten und billigsten Prüfung beginnt. Fünftens: *Eine Änderung machen* und die Wirkung prüfen; wirkt sie nicht, wird sie zurückgenommen. Sechstens: *Dokumentieren und Ursache beseitigen*, damit die Störung nicht wiederkommt.

Für Active Directory hat sich außerdem eine Prüfreihenfolge nach Abhängigkeiten bewährt, denn die Bausteine bauen aufeinander auf. An unterster Stelle steht das *Netzwerk* (Erreichbarkeit, Ports, Routing, Namensauflösung). Darauf ruht *DNS*: Active Directory findet seine Domain Controller über SRV-Einträge, und die meisten Fehlerbilder (Anmeldung langsam, Replikation scheitert, Domänenbeitritt klappt nicht) haben ihre Ursache in DNS. Dann folgt die *Zeit*: Kerberos toleriert nur eine kleine Abweichung (standardmäßig fünf Minuten, Modul 8). Darauf liegen die *Dienste* (NTDS, Netlogon, KDC, DNS, DFSR) und erst dann die *Replikation* und *SYSVOL*, schließlich *Rechte und Richtlinien*. Wer diese Reihenfolge einhält, spart oft Stunden, weil er nicht auf der Ebene der Replikation sucht, wenn die Namensauflösung nicht stimmt.

Zu den typischen Symptomen gibt es Standardwege. Eine *Anmeldung scheitert*: Zuerst fragt man, ob alle oder einzelne Benutzer betroffen sind; dann prüft man mit `nltest /dsgetdc` den Domain Controller, die Zeit, die Ereignisse 4625, 4771 und 4776 auf dem Domain Controller und das Konto (gesperrt, abgelaufen, deaktiviert). Eine *Anmeldung ist langsam*: Standortzuordnung (`nltest /dsgetsite`), DNS-Antwortzeiten, Last des Domain Controllers, Anmeldeskripte und Gruppenrichtlinien (`gpresult`). Eine *Replikation scheitert*: `repadmin /replsummary`, Fehlercode nachschlagen, DNS und Ports prüfen, Zeit prüfen, Rechte prüfen. Ein *Rechner verliert die Vertrauensstellung*: `nltest /sc_verify`, `Test-ComputerSecureChannel`. *Gruppenrichtlinien greifen nicht*: SYSVOL-Freigabe, DFSR-Zustand, `gpresult /r`, Ereignisse im Protokoll „GroupPolicy“ und die Anwendungsreihenfolge (Modul 7).

```powershell
# Erstdiagnose-Skript: in 30 Sekunden den Zustand der Grundlagen erfassen
param([string]$Domaene = "corp.contoso.com", [string]$Zielserver = "DC01")

function Zeige($titel) { "`n=== $titel ===" }

Zeige "1. Netzwerk"
Test-Connection $Zielserver -Count 2 | Select-Object Address, ResponseTime
foreach ($port in 53,88,135,389,445,636,3268) {
    $t = Test-NetConnection $Zielserver -Port $port -WarningAction SilentlyContinue
    "{0,-6} {1}" -f $port, $(if ($t.TcpTestSucceeded) {"offen"} else {"GESCHLOSSEN"})
}

Zeige "2. DNS: SRV-Eintraege der Domain Controller"
Resolve-DnsName "_ldap._tcp.dc._msdcs.$Domaene" -Type SRV -ErrorAction SilentlyContinue |
    Select-Object NameTarget, Port, Priority | Format-Table -AutoSize
Resolve-DnsName $Zielserver -ErrorAction SilentlyContinue | Select-Object Name, IPAddress

Zeige "3. Zeit"
w32tm /monitor /computers:$Zielserver 2>$null

Zeige "4. Domain-Controller-Ortung und Standort"
nltest /dsgetdc:$Domaene
nltest /dsgetsite

Zeige "5. Dienste auf dem Zielserver"
Get-Service -ComputerName $Zielserver NTDS, Netlogon, DNS, KDC, DFSR, W32Time -ErrorAction SilentlyContinue |
    Select-Object Name, Status

Zeige "6. Replikation und letzte Fehler"
repadmin /replsummary
Get-WinEvent -ComputerName $Zielserver -FilterHashtable @{ LogName="Directory Service","DNS Server","System"; Level=1,2; StartTime=(Get-Date).AddHours(-6) } -MaxEvents 15 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, LogName, Id, @{n="Text";e={($_.Message -split "`n")[0]}} | Format-Table -AutoSize -Wrap
```

Das Skript folgt der Prüfreihenfolge nach Abhängigkeiten. Abschnitt 1 prüft Erreichbarkeit und die wichtigsten Ports der Active-Directory-Dienste: DNS (53), Kerberos (88), RPC-Endpunktzuordnung (135), LDAP (389), SMB (445), LDAP über SSL (636) und Globaler Katalog (3268). Abschnitt 2 fragt die SRV-Einträge ab, über die Clients Domain Controller finden, und löst den Namen des Zielservers auf. Abschnitt 3 prüft die Zeit. Abschnitt 4 zeigt, welchen Domain Controller der Rechner verwendet und in welchem Standort er liegt. Abschnitt 5 zeigt die Dienste. Abschnitt 6 fasst die Replikation zusammen und listet die letzten Fehler. Das Skript ändert nichts; es sammelt nur die Ausgangslage für den nächsten Schritt.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, mehrere Änderungen gleichzeitig zu machen und danach nicht zu wissen, welche geholfen hat. Der zweite ist, „Neustart“ als Methode zu verwenden: Er behebt manchmal das Symptom, vernichtet aber die Spuren und lässt die Ursache bestehen. Der dritte ist, mit Annahmen zu arbeiten, statt zu messen („das kann nicht an DNS liegen“). Der vierte ist, die Störung nicht zu dokumentieren; dieselbe Ursache taucht in sechs Monaten wieder auf, und niemand erinnert sich.

```powershell
# FALSCH: Mehrere Aenderungen auf einmal, ohne Beobachtung
ipconfig /flushdns; net stop netlogon; net start netlogon; w32tm /resync /force; gpupdate /force

# RICHTIG: Eine Aenderung, Wirkung pruefen, notieren
Resolve-DnsName "_ldap._tcp.dc._msdcs.corp.contoso.com" -Type SRV      # Hypothese: SRV-Eintraege fehlen?
# Ergebnis notieren; erst dann die naechste Massnahme
```

> **Ergänzung aus der Nachrecherche**
>
> Die Prüfreihenfolge Netzwerk, DNS, Zeit, Dienste, Replikation entspricht dem Aufbau der abgerufenen Fehlersuche-Anleitungen der Microsoft-Dokumentation zur Replikation („Troubleshooting Active Directory replication problems“, „Diagnose Active Directory replication failures“) und zur Ortung von Domain Controllern („Troubleshoot domain controller location issues“; Microsoft Learn, Suchauszüge). Die sechs Schritte der Methodik sind allgemeines Fachwissen der Störungsbehebung. Die genannten Ports sind die gängigen Ports der Active-Directory-Dienste; die vollständige Portliste (inklusive des dynamischen RPC-Bereichs) steht in der Dokumentation zu den Firewallanforderungen und wurde nicht abgerufen.

### Praxisbezug

> **Praxisbeispiel**
>
> Nach einem Wartungsfenster melden Benutzer einer Filiale, dass Anmeldungen mehrere Minuten dauern. Der Administrator beginnt nicht beim Domain Controller, sondern bei der Frage, was geändert wurde: Das Netzwerkteam hat die DNS-Server der Filiale umgestellt. Der Erstdiagnose-Lauf zeigt, dass die SRV-Einträge von der Filiale aus nicht aufgelöst werden; die Clients suchen ewig nach einem Domain Controller. Nach Korrektur der DNS-Einstellung ist alles in Ordnung. Das Vorgehen hat 15 Minuten gedauert, die Fehlersuche an der Replikation hätte Stunden gekostet.

## 11.9 Incident Runbooks

Ein *Incident Runbook* ist eine kurze, handlungsorientierte Anleitung für einen bestimmten wiederkehrenden Störungstyp. Er unterscheidet sich vom BCDR-Runbook aus Modul 10, das den Gesamtausfall behandelt, durch seinen engen Zuschnitt: Es gibt ein Runbook für „Domain Controller nicht erreichbar“, eines für „Replikationsfehler“, eines für „massenhafte Kontosperrungen“ und so weiter. Der Nutzen liegt darin, dass im Störungsfall nicht neu nachgedacht werden muss: Der Erfahrene hat sein Wissen aufgeschrieben, und der Neue kann es abarbeiten. Außerdem sorgt ein Runbook dafür, dass Störungen einheitlich behandelt, eskaliert und dokumentiert werden.

Ein gutes Runbook hat immer denselben Aufbau, damit man sich im Ernstfall zurechtfindet. Es beginnt mit dem *Symptom* (woran man den Fall erkennt), dann folgen *Auswirkung und Dringlichkeit* (wer ist betroffen, wie schnell muss gehandelt werden), die *Erstprüfung* (zwei oder drei Befehle, die die Lage klären), die *wahrscheinlichen Ursachen mit Gegenmaßnahmen* in der Reihenfolge ihrer Häufigkeit, die *Eskalation* (wann und an wen weitergeben), die *Prüfung des Erfolgs* und die *Nachbereitung*. Es verweist auf die Lerneinheiten dieses und der anderen Module, statt deren Inhalt zu wiederholen.

Welche Runbooks braucht man? Eine sinnvolle Grundausstattung für Active Directory enthält: (1) Domain Controller ausgefallen oder nicht erreichbar, mit den Zweigen „nur Netzwerk“, „Dienst“, „Server defekt“ (Neuinstallation oder Wiederherstellung, Modul 10, FSMO-Rollen übernehmen, Modul 6); (2) Replikation gestört (`repadmin`, Fehlercodes, DNS, Zeit, Lingering Objects); (3) Anmeldungen scheitern oder sind langsam (Standort, DNS, Zeit, sicherer Kanal); (4) Kontosperrungen häufen sich (Ereignis 4740 auf dem PDC-Emulator, Quellrechner finden, Modul 8); (5) SYSVOL oder Gruppenrichtlinien nicht verfügbar (Modul 10); (6) Zeitabweichung (Zeithierarchie, Modul 6); (7) Verdacht auf Kompromittierung eines privilegierten Kontos (Konto sperren, Sitzungen beenden, Ereignisse sichern, Kennwörter erneuern, Modul 9); (8) versehentliches Löschen von Objekten (Papierkorb, Modul 10).

Eine gut gepflegte Sammlung lässt sich zum Teil als Skript ablegen, damit die Erstprüfung auf Knopfdruck läuft. Das folgende Beispiel zeigt ein Runbook als Text in einem Skriptrahmen, der die Erstprüfung ausführt und die Ergebnisse protokolliert. Es steht für den Fall „massenhafte Kontosperrungen“, der häufig vorkommt und leicht zu diagnostizieren ist, wenn man weiß, wo die Information liegt.

```powershell
<#
RUNBOOK: Massenhafte Kontosperrungen
SYMPTOM:     Mehrere Benutzer melden "Konto gesperrt", Ereignis 4740 haeuft sich.
AUSWIRKUNG:  Benutzer koennen nicht arbeiten; moeglicher Angriff (Password Spraying) oder falsch konfigurierter Dienst.
DRINGLICHKEIT: Hoch, wenn > 10 Konten in 10 Minuten betroffen sind.
ESKALATION:  Nach 30 Minuten ohne Ursache an das Sicherheitsteam (Verdacht auf Angriff).
#>
Import-Module ActiveDirectory
$pdc  = (Get-ADDomain).PDCEmulator
$seit = (Get-Date).AddHours(-1)

# SCHRITT 1: Wie viele Sperrungen, wer, von wo? (Ereignis 4740 auf dem PDC-Emulator)
$sperren = Get-WinEvent -ComputerName $pdc -FilterHashtable @{ LogName="Security"; Id=4740; StartTime=$seit } -ErrorAction SilentlyContinue |
  ForEach-Object {
    $d=@{}; foreach ($n in ([xml]$_.ToXml()).Event.EventData.Data) { $d[$n.Name]=$n.'#text' }
    [pscustomobject]@{ Zeit=$_.TimeCreated; Konto=$d["TargetUserName"]; QuellRechner=$d["TargetDomainName"] }
  }
"Sperrungen in der letzten Stunde: $(@($sperren).Count)"
$sperren | Group-Object QuellRechner | Sort-Object Count -Descending | Select-Object -First 5 Count, Name

# SCHRITT 2: Gleiche Quelle fuer viele Konten -> Rechner pruefen (Dienst, gespeicherte Kennwoerter, Angriff)
# SCHRITT 3: Viele Quellen fuer ein Konto -> gespeichertes altes Kennwort (Handy, Mapping, Dienst)
$sperren | Group-Object Konto | Sort-Object Count -Descending | Select-Object -First 5 Count, Name

# SCHRITT 4: Gesperrte Konten anzeigen und (nach Klaerung) entsperren
Search-ADAccount -LockedOut | Select-Object SamAccountName, LockedOut, LastLogonDate
# Unlock-ADAccount -Identity "mmeier"       # erst nach Klaerung der Ursache!

# SCHRITT 5: Erfolg pruefen und dokumentieren
"Nach der Massnahme erneut pruefen: Search-ADAccount -LockedOut"
```

Der Kommentarblock am Anfang ist der Kopf des Runbooks mit Symptom, Auswirkung, Dringlichkeit und Eskalation. Schritt 1 zählt die Sperrungen der letzten Stunde auf dem PDC-Emulator, gruppiert nach dem Rechner, von dem die falschen Anmeldungen kamen. Viele Sperrungen von einer Quelle weisen auf einen Rechner mit einem veralteten gespeicherten Kennwort (zum Beispiel ein Dienst, eine Netzwerkfreigabe, ein Mobilgerät) oder auf einen Angriff hin. Schritt 3 dreht die Sicht um und zeigt, welche Konten mehrfach gesperrt wurden. Schritt 4 zeigt die aktuell gesperrten Konten und enthält als Kommentar den Befehl zum Entsperren, der bewusst erst nach der Klärung der Ursache ausgeführt wird, denn ein entsperrtes Konto wird sonst sofort wieder gesperrt. Schritt 5 erinnert an die Erfolgskontrolle.

### Typische Fehler und Stolperfallen

Der erste Fehler ist ein Runbook, das so allgemein ist, dass es nichts hilft („Ursache suchen und beheben“). Der zweite ist veralteter Inhalt: Namen von Servern, die es nicht mehr gibt. Der dritte ist, dass das Runbook nie ausprobiert wird; es sollte bei der nächsten echten Störung mit Notizen verbessert werden. Der vierte ist die fehlende Eskalationsregel: Wer nicht weiß, wann er Hilfe holen muss, verliert Zeit oder wartet zu lange.

```powershell
# FALSCH: Sofort alle gesperrten Konten entsperren, ohne Ursache zu suchen
Search-ADAccount -LockedOut | Unlock-ADAccount

# RICHTIG: Erst Quelle klaeren (Ereignis 4740), dann gezielt entsperren und beobachten
Get-WinEvent -ComputerName (Get-ADDomain).PDCEmulator -FilterHashtable @{ LogName="Security"; Id=4740; StartTime=(Get-Date).AddHours(-1) } -MaxEvents 20
Unlock-ADAccount -Identity "mmeier"
```

> **Ergänzung aus der Nachrecherche**
>
> Die Anwendung der Ereignisse 4740, 4625 und 4771 zur Untersuchung von Anmeldeproblemen folgt der abgerufenen Liste der zu beobachtenden Ereignisse auf Domain Controllern („Appendix L: Events to Monitor“; Microsoft Learn, Suchauszug) und dem in Modul 8 erläuterten Mechanismus der Kontosperrung. Die Gliederung eines Runbooks, die Auswahl der acht Grundszenarien, die Dringlichkeitsschwelle von zehn Konten in zehn Minuten und die Eskalationszeit von 30 Minuten sind Beispielwerte und müssen an die eigene Organisation angepasst werden. Rechtliche und vertragliche Meldepflichten bei Sicherheitsvorfällen (zum Beispiel Fristen nach Datenschutz- oder Sicherheitsgesetzen) sind in dieser Lerneinheit nicht behandelt; hier gilt der Hinweis: keine Rechtsberatung.

### Praxisbezug

> **Praxisbeispiel**
>
> Das Team pflegt acht Runbooks im Wiki und als Ausdruck, jedes auf einer Seite. Als eines Nachts der Bereitschaftstechniker wegen massenhafter Kontosperrungen angerufen wird, öffnet er das passende Runbook und findet in drei Minuten den Rechner, der die falschen Anmeldungen schickt: ein Anwendungsserver mit einem alten Kennwort des Dienstkontos nach einer Kennwortänderung. Er entsperrt die Konten erst, nachdem das Kennwort auf dem Server korrigiert ist. Am nächsten Morgen ergänzt er das Runbook um den Hinweis, bei Dienstkonten die Abhängigkeiten zu prüfen.

## 11.10 Übungsaufgaben zu Modul 11

**Aufgabe 11.1** Nennen Sie fünf Ereignisprotokolle, die auf einem Domain Controller für die Fehlersuche wichtig sind, und ordnen Sie jedem ein Beispiel für eine relevante Ereignis-ID zu. Warum reicht es nicht, nur das System-Protokoll zu lesen?

**Aufgabe 11.2** Welche Aussage macht `dcdiag /q`, wenn nichts ausgegeben wird? Erklären Sie, warum man bei mehreren Fehlschlägen mit dem *ersten* beginnt, und nennen Sie drei Einzeltests mit ihrer Bedeutung.

**Aufgabe 11.3** Was zeigen `repadmin /replsummary`, `repadmin /showrepl` und `repadmin /showobjmeta`? Welche Bedeutung haben die Fehlercodes 1722, 8453 und 8606, und wie geht man jeweils vor?

**Aufgabe 11.4** Ein Arbeitsplatz meldet, dass die Vertrauensstellung zur Domäne fehlgeschlagen ist. Welche Befehle prüfen und reparieren den sicheren Kanal? Warum ist das Löschen des Computerkontos meist die schlechtere Lösung?

**Aufgabe 11.5** Erklären Sie, warum der Arbeitsspeicher für Domain Controller so wichtig ist, nennen Sie vier Leistungsindikatoren mit ihrer Bedeutung, und beschreiben Sie, wozu eine Basislinie dient.

**Aufgabe 11.6** **Praxis:** Schreiben Sie ein PowerShell-Skript, das für alle Domain Controller die Ereignisse 1311, 1388, 1988, 2042 und 2087 des Protokolls „Directory Service“ der letzten 3 Tage ausliest und je Domain Controller und Ereignis-ID die Zahl der Treffer ausgibt.

**Aufgabe 11.7** **Praxis:** Schreiben Sie ein Skript, das mit `repadmin /showrepl * /csv` alle Replikationsverbindungen mit Fehlern anzeigt und zusätzlich für die betroffenen Partner prüft, ob der Name per DNS aufgelöst werden kann und ob die Ports 135 und 389 erreichbar sind.

**Aufgabe 11.8** **Praxis:** Entwerfen Sie ein Incident Runbook „Domain Controller nicht erreichbar“: mit Symptom, Auswirkung, Erstprüfung (mit Befehlen), mindestens drei wahrscheinlichen Ursachen mit Gegenmaßnahmen, Eskalation und Erfolgsprüfung. Beschreiben Sie außerdem, wie die sechs Schritte der Troubleshooting-Methodik darin sichtbar werden.

## 11.11 Lösungen zu den Übungsaufgaben

**Lösung 11.1.** Beispiele: *Directory Service* (1311 Topologie nicht zusammenhängend, 2042 zu lange nicht repliziert), *DNS Server* (4013, DNS-Server wartet auf Active Directory), *DFS Replication* (4614 und 4604 Anfangssynchronisation von SYSVOL, 2213 Datenbank nach Absturz), *System* (NETLOGON 5719, kein Domain Controller erreichbar), *Sicherheit* (4740 Kontosperrung, 4625 fehlgeschlagene Anmeldung, 1102 Protokoll gelöscht). Das System-Protokoll genügt nicht, weil die spezialisierten Dienste in eigenen Protokollen schreiben; die Replikationsprobleme stehen in „Directory Service“, DNS-Probleme in „DNS Server“, SYSVOL-Probleme in „DFS Replication“.

**Lösung 11.2.** Keine Ausgabe bei `dcdiag /q` bedeutet, dass alle Standardtests bestanden haben; Fehler werden ausgegeben, Erfolge nicht. Die Tests bauen aufeinander auf: Schlägt *Connectivity* fehl, scheitern die meisten späteren Tests als Folgefehler; deshalb beginnt man mit dem ersten Fehler. Beispiele: *Advertising* (der Domain Controller bietet sich als solcher an, Netlogon läuft), *Replications* (die letzten Replikationen waren erfolgreich), *FsmoCheck* (die Rollenbesitzer sind erreichbar), *Services* (die erforderlichen Dienste laufen), *DNS* (Namensauflösung und Registrierung stimmen).

**Lösung 11.3.** `/replsummary` liefert die Übersicht aller Domain Controller (größte Verzögerung, Fehlerzahl), `/showrepl` die eingehenden Partner eines Domain Controllers mit dem Zeitpunkt der letzten erfolgreichen und der letzten versuchten Replikation und dem Fehler, `/showobjmeta` die Replikationsmetadaten eines Objekts (wann und wo jedes Attribut zuletzt geändert wurde). Fehler 1722: RPC-Server nicht verfügbar, prüfen Namensauflösung, Erreichbarkeit der Ports (135 und dynamische RPC-Ports), Firewall und Dienst. Fehler 8453: Replikationszugriff verweigert, Rechte der Replikationspartner (Gruppenmitgliedschaft des Domain-Controller-Kontos, Vertrauensstellung, Kennwort des Computerkontos) prüfen. Fehler 8606: Attribute fehlen zum Erstellen eines Objekts, meist Lingering Objects; mit `repadmin /removelingeringobjects` beheben (Modul 10).

**Lösung 11.4.** Prüfen: `nltest /sc_verify:corp.contoso.com` oder `Test-ComputerSecureChannel -Verbose`; Reparieren: `Test-ComputerSecureChannel -Repair -Credential ...` oder `nltest /sc_reset`. Das Löschen und Neuanlegen des Computerkontos erzeugt eine neue SID, verliert Gruppenmitgliedschaften, die Zuordnung zu Richtlinien, Zertifikaten und Software-Verteilung; die Reparatur gleicht nur das Kennwort des vorhandenen Kontos an.

**Lösung 11.5.** Die Active-Directory-Datenbank arbeitet am schnellsten, wenn sie im Cache im Arbeitsspeicher liegt; Zugriffe auf die Festplatte sind um Größenordnungen langsamer. Indikatoren: `Process(lsass)\% Processor Time` (Rechenlast der Authentifizierung), `Memory\Available MBytes` (Speicherdruck), `LogicalDisk\Avg. Disk sec/Read` (Plattenlatenz), `NTDS\LDAP Searches/sec` (Abfragelast). Eine Basislinie ist die Messreihe im Normalbetrieb; sie macht Messwerte erst beurteilbar (was ist normal) und zeigt Trends für die Kapazitätsplanung.

**Lösung 11.6.** Ein mögliches Skript:

```powershell
Import-Module ActiveDirectory
$ids = 1311,1388,1988,2042,2087
$seit = (Get-Date).AddDays(-3)
$erg = foreach ($dc in (Get-ADDomainController -Filter *).HostName) {
    Get-WinEvent -ComputerName $dc -FilterHashtable @{ LogName="Directory Service"; Id=$ids; StartTime=$seit } -ErrorAction SilentlyContinue |
        Select-Object @{n="DC";e={$dc}}, Id
}
$erg | Group-Object DC, Id | Sort-Object Name | Select-Object Count, Name
```

Die Schleife fragt jeden Domain Controller serverseitig gefiltert ab. `-ErrorAction SilentlyContinue` unterdrückt die Meldung „keine Ereignisse gefunden“. Die Gruppierung nach Domain Controller und ID zählt die Treffer; ein Domain Controller ohne Treffer erscheint nicht in der Ausgabe, was als gutes Zeichen zu werten ist.

**Lösung 11.7.** Ein mögliches Skript:

```powershell
$fehler = repadmin /showrepl * /csv | ConvertFrom-Csv | Where-Object { [int]$_."Number of Failures" -gt 0 }
$fehler | Select-Object "Source DSA","Destination DSA","Naming Context","Number of Failures","Last Failure Status" | Format-Table -AutoSize
foreach ($p in ($fehler."Source DSA" | Sort-Object -Unique)) {
    $name = if ($p -match '\.') { $p } else { "$p.corp.contoso.com" }
    $dns = Resolve-DnsName $name -ErrorAction SilentlyContinue
    $t135 = (Test-NetConnection $name -Port 135 -WarningAction SilentlyContinue).TcpTestSucceeded
    $t389 = (Test-NetConnection $name -Port 389 -WarningAction SilentlyContinue).TcpTestSucceeded
    "{0}: DNS={1}, Port135={2}, Port389={3}" -f $name, [bool]$dns, $t135, $t389
}
```

Das Skript lädt die Replikationsdaten, behält die Zeilen mit Fehlern, und prüft die Quellserver auf DNS-Auflösung sowie die Erreichbarkeit der Ports 135 (RPC) und 389 (LDAP). Der Domänenname im Beispiel muss an die Umgebung angepasst werden; die Spaltennamen entsprechen der englischen Ausgabe von `repadmin`.

**Lösung 11.8.** Ein Beispiel: *Symptom:* Anmeldungen am Standort schlagen fehl, `repadmin /replsummary` zeigt einen Domain Controller als nicht erreichbar. *Auswirkung:* Benutzer des Standorts authentifizieren an entfernten Domain Controllern (langsam) oder gar nicht; hoch, wenn es der einzige am Standort ist. *Erstprüfung:* `Test-Connection DC02`, `Test-NetConnection DC02 -Port 389`, `Resolve-DnsName dc02.corp.contoso.com`, auf der Konsole oder per Hypervisor prüfen, ob der Server läuft, `Get-Service -ComputerName DC02 NTDS,Netlogon,DNS`. *Ursachen und Maßnahmen:* (1) Netzwerk oder Firewall (Netzwerkteam einbinden, Route prüfen); (2) Dienste nicht gestartet (Dienst starten, Ereignisse lesen); (3) Server defekt (neu installieren und heraufstufen oder aus der Sicherung wiederherstellen, Modul 10; falls er FSMO-Rollen trug, Rollen übernehmen, Modul 6). *Eskalation:* Nach 30 Minuten ohne Ursache an die Leitung und das Netzwerkteam. *Erfolgsprüfung:* `dcdiag /q` und `repadmin /replsummary` ohne Fehler. Die Methodik erscheint so: Problem beschreiben (Symptom), Umfang eingrenzen (ein oder alle Domain Controller), Änderungen erfragen (Frage nach Wartungsfenstern), Hypothese prüfen (Erstprüfung), Änderung machen (Maßnahme), Dokumentieren (Nachbereitung).
