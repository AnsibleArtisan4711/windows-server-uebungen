# Modul 09 - Audit, Logging und Forensik

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Gruppenrichtlinien für Windows 11 – 100 Richtlinien im Detail“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Steckbriefe als Tabellen, Übungsaufgaben und Lösungen als fortlaufend nummerierte Absätze). **Nummerierung:** Die Überschriften der Richtlinien tragen hier die laufende Nummer 1 bis 100 aus der Modultabelle; die Verweise im Text („Abschnitt 43“) meinen diese Nummer. (Im LaTeX-Satz zählen die Überschriften je Modul neu, etwa 5.3.) **Die Beispiele (PowerShell, INF) wurden für dieses Repository nicht ausgeführt**; sie verändern Gruppenrichtlinien, Registry und Sicherheitseinstellungen und gehören nur in eine Testumgebung (Pilot-OU, Testdomäne). Übersicht zum Modul: [README](README.md).

**Dauer:** 10 Unterrichtsstunden (Annahme: 1 Stunde je Richtlinie)  
**Priorität:** 1 und 2 (sechs Richtlinien mit Priorität 1, vier mit Priorität 2)

| Nr. | Lerneinheit (Richtlinie)             | Prio | Stunden |
|----:|:-------------------------------------|:----:|:-------:|
|  81 | Audit Process Creation aktivieren    |  1   |    1    |
|  82 | Command Line in Prozessereignissen   |  1   |    1    |
|  83 | Audit Logon Events                   |  1   |    1    |
|  84 | Audit Account Lockout                |  1   |    1    |
|  85 | Audit Policy Change                  |  1   |    1    |
|  86 | Audit Privilege Use                  |  2   |    1    |
|  87 | Security Log Größe erhöhen           |  1   |    1    |
|  88 | PowerShell Script Block Logging      |  1   |    1    |
|  89 | PowerShell Module Logging            |  2   |    1    |
|  90 | Windows Event Forwarding vorbereiten |  2   |    1    |
|     | **Summe**                            |      | **10**  |

**Worum es in diesem Modul geht.** Alle Härtungen der vorherigen Module verhindern Angriffe, aber keine verhindert sie vollständig. Deshalb braucht jede Umgebung ein zweites Standbein: die Fähigkeit, einen Vorfall zu *erkennen* und hinterher zu *rekonstruieren*, was geschehen ist. Diese Disziplin heißt Forensik (englisch *digital forensics*), und ihre Rohstoffe sind Protokolle (*Logs*). Ein Windows-Rechner schreibt aber nur dann nützliche Ereignisse, wenn man es ihm sagt. Dieses Modul zeigt, welche Überwachungseinstellungen sich lohnen (81 bis 86), wie man verhindert, dass die Protokolle zu früh überschrieben werden (87), wie man PowerShell sichtbar macht (88 und 89) und wie die Ereignisse zentral gesammelt werden (90). Eine wichtige Randbedingung: Protokolle enthalten personenbezogene Daten (Benutzernamen, Rechnernamen, Befehlszeilen). In Österreich und der EU gehört die Einführung daher mit Datenschutz und Betriebsrat abgestimmt. Das ist ein Hinweis, keine Rechtsberatung.

> **Merke**
>
> Zwei Begriffe vorab. Die *Erweiterte Überwachungsrichtlinie* (*Advanced Audit Policy Configuration*) umfasst rund 60 Unterkategorien und ersetzt die neun groben Kategorien der älteren Basisüberwachung. Beide Verfahren nebeneinander zu betreiben führt zu unvorhersehbaren Ergebnissen. Die Sicherheitsoption „Überwachung: Einstellungen für Überwachungsrichtlinien-Unterkategorien erzwingen“ (*Audit: Force audit policy subcategory settings*, Registrywert `SCENoApplyLegacyAuditPolicy`, nach meiner Kenntnis) legt fest, dass die erweiterte Variante gewinnt. Sie sollte in jeder Umgebung gesetzt sein, die erweiterte Überwachung nutzt (im Pilot zu prüfen).

## 81 Audit Process Creation aktivieren

| **Feld**        | **Steckbrief**                                                                                                                                 |
|:----------------|:-----------------------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Erweiterte Überwachungsrichtlinie \> Detaillierte Nachverfolgung |
| Einstellung     | Prozesserstellung überwachen                                                                                                                   |
| Empfehlung      | Erfolg                                                                                                                                         |
| Ziel / Zweck    | Ermöglicht Prozessforensik                                                                                                                     |
| Zielbereich     | Computer                                                                                                                                       |
| Priorität       | 1                                                                                                                                              |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                                    |

Jede Aktion auf einem Rechner läuft in einem Prozess. Wenn ein Angreifer eine Schadsoftware startet, ein Skript ausführt oder ein Administrationswerkzeug missbraucht, entsteht ein Prozess. Die Überwachung der *Prozesserstellung* (*Audit Process Creation*) schreibt bei jedem neuen Prozess ein Ereignis in das Sicherheitsprotokoll. Laut Microsoft ist das die Ereignis-ID 4688 („A new process has been created“); die Überwachungseinstellung liegt unter Erweiterte Überwachungsrichtlinie \> Detaillierte Nachverfolgung, ist standardmäßig nicht konfiguriert und unterstützt Windows 7 und höher. Die Dokumentation beschreibt das Ereignisvolumen als niedrig bis mittel, abhängig von der Nutzung. Das Ereignis nennt, welches Programm gestartet wurde, durch welchen Benutzer und, wichtig für die Analyse, durch welchen übergeordneten Prozess (*Parent Process*) das geschah. Ohne diese Kette lässt sich nicht erkennen, ob ein PowerShell-Fenster vom Benutzer oder von einem Word-Makro geöffnet wurde.

Der Lehrplan empfiehlt „Erfolg“. Das ist sinnvoll: Gescheiterte Prozessstarts sind selten und selten interessant, während erfolgreiche das Rückgrat jeder Untersuchung bilden. Laut Policy-CSP-Dokumentation sind die Werte 0 (keine Überwachung, Standard), 1 (Erfolg), 2 (Fehler) und 3 (Erfolg und Fehler) möglich. Wichtig ist, dass diese Einstellung allein nur den Start, nicht die Befehlszeile protokolliert; das ergänzt Abschnitt 82. Verwandt ist die Unterkategorie „Prozessbeendigung“ (Ereignis 4689), die für die Dauer eines Prozesses nützlich sein kann, aber das Volumen erhöht.

> **Ergänzung aus der Nachrecherche**
>
> Microsoft beschreibt in der Dokumentation zur Erweiterten Überwachung, dass die Einstellung die Ereignisse 4688 sowie 4696 (Primärtoken einem Prozess zugewiesen) erzeugt und dass das Volumen „je nach Nutzung variiert“. Die Einstellung lässt sich auch per MDM/Intune über den Policy CSP `Audit/DetailedTracking_AuditProcessCreation` setzen (ab Windows 10, Version 1803 mit dem Update KB4516045 und höher bzw. 2004 und höher); in einer Gruppenrichtlinie liegt sie unter dem Pfad aus dem Steckbrief.

Das Beispiel zeigt, wie man die Einstellung auf einem Testrechner lokal setzt und prüft. Das Werkzeug `auditpol.exe` ist das Standardwerkzeug dafür; die Namen der Unterkategorien sind sprachabhängig (auf einem deutschen System heißt die Unterkategorie anders), deshalb ist die Ausgabe von `auditpol /list /subcategory:* /v` mit den GUIDs hilfreich, die sprachunabhängig sind. In der Produktion verteilt man die Einstellung über die GPO; der lokale Befehl dient dem Test und der Kontrolle.

```ps
# Sprachunabhaengige Liste aller Unterkategorien mit GUID
auditpol /list /subcategory:* /v | Select-String -Pattern 'Prozess|Process'

# Auf einem TESTRECHNER: Erfolg aktivieren (Name je nach Sprache anpassen oder GUID verwenden)
auditpol /set /subcategory:"Process Creation" /success:enable

# Aktuellen Stand der Kategorie "Detailed Tracking" lesen
auditpol /get /category:"Detailed Tracking"

# Ein Ereignis erzeugen und finden
notepad.exe; Start-Sleep 2; Stop-Process -Name notepad
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4688} -MaxEvents 3 |
    Select-Object TimeCreated, Id
```

Die erste Zeile zeigt alle Unterkategorien samt GUID; über die GUID kann man die Einstellung auch in gemischtsprachigen Umgebungen setzen. Die zweite Zeile aktiviert Erfolgsereignisse, die dritte liest den Stand zurück. Der Test startet Notepad und sucht anschließend das passende Ereignis 4688 im Sicherheitsprotokoll; dafür sind Administratorrechte nötig, weil das Sicherheitsprotokoll geschützt ist.

**Typische Fehler.** Falsch: die Überwachung nur lokal mit `auditpol` zu setzen und zu glauben, sie bleibe. Die Gruppenrichtlinie überschreibt bei der nächsten Verarbeitung die lokalen Werte, sofern sie dieselbe Unterkategorie setzt. Richtig: die Einstellung in der GPO pflegen. Zweiter Fehler: die Kategorien in Basis- und Erweiterter Überwachung zu mischen (siehe Merkkasten). Dritter Fehler: die Überwachung zu aktivieren, ohne die Protokollgröße anzupassen (Abschnitt 87); das Sicherheitsprotokoll läuft bei aktivierter Prozessüberwachung schnell über.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Benutzer meldet, sein Rechner verhalte sich seltsam. Der Administrator filtert im Sicherheitsprotokoll nach Ereignis 4688 der letzten Stunde und sieht, dass `cmd.exe` von `winword.exe` gestartet wurde. Das ist der entscheidende Hinweis auf ein bösartiges Makro. Ohne Prozessüberwachung gäbe es diesen Hinweis nicht.

## 82 Command Line in Prozessereignissen

| **Feld**        | **Steckbrief**                                                                                  |
|:----------------|:------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> Überwachung der Prozesserstellung |
| Einstellung     | Befehlszeile in Prozesserstellungsereignissen einschließen                                      |
| Empfehlung      | Aktiviert                                                                                       |
| Ziel / Zweck    | Erhöht Sichtbarkeit für Angriffe und Troubleshooting                                            |
| Zielbereich     | Computer                                                                                        |
| Priorität       | 1                                                                                               |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.     |

Dass `powershell.exe` gestartet wurde, ist für sich genommen kaum auffällig; erst die *Befehlszeile* (*Command Line*) zeigt, ob damit ein harmloses Skript oder ein verschlüsselter Download-Befehl lief. Die Einstellung „Include command line in process creation events“ ergänzt das Ereignis 4688 um genau dieses Feld, „Process Command Line“. Laut Microsoft gilt: Die Einstellung wirkt nur, wenn die Überwachung der Prozesserstellung aus Abschnitt 81 aktiv ist, sie ist standardmäßig nicht konfiguriert, und sie schreibt die Befehlszeile jedes Prozesses im Klartext in das Sicherheitsprotokoll. Der Registrywert heißt `ProcessCreationIncludeCmdLine_Enabled` im Schlüssel `Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit`; die Baseline erwartet den Wert 1.

Die Dokumentation enthält eine Warnung, die man ernst nehmen muss: Jeder, der Sicherheitsereignisse lesen darf, kann damit die Befehlszeile jedes erfolgreich gestarteten Prozesses lesen, und Befehlszeilen können Kennwörter oder Nutzerdaten enthalten (etwa `net use \\server /user:x Kennwort`). Das hat zwei Konsequenzen. Erstens darf das Sicherheitsprotokoll nur kleinem, berechtigtem Personenkreis lesbar sein. Zweitens gehört der Einsatz in die Datenschutzdokumentation, weil Befehlszeilen Rückschlüsse auf das Verhalten einzelner Personen zulassen.

> **Ergänzung aus der Nachrecherche**
>
> Der Schlüssel liegt laut Policy-CSP-Dokumentation im ADMX-gestützten Pfad „System \> Audit Process Creation“ (Datei `AuditSettings.admx`). Der Policy CSP `ADMX_AuditSettings/IncludeCmdLine` steht ab Windows 10, Version 2004 mit KB5005101 sowie ab Windows 11 zur Verfügung. Dasselbe Prinzip der Befehlszeile ist auch ein Teil von Microsofts Anleitung zur Fehlersuche bei Skripten, die die Einstellung mit einem `reg add`-Befehl aktiviert.

Das Beispiel legt die GPO an, setzt den Wert und liest später die Befehlszeile aus den Ereignissen. Die XML-Struktur des Ereignisses (das Feld `CommandLine` in den `EventData`) ist aus meiner Kenntnis; im Pilot ist zu prüfen, ob der Feldname auf allen Versionen gleich lautet. Die Auswertung zeigt, wie aus dem Ereignis ein lesbares Objekt wird.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "AUDIT-Prozess-Befehlszeile"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" `
    -ValueName ProcessCreationIncludeCmdLine_Enabled -Type DWord -Value 1

# Auswertung am Client: die letzten Prozessstarts mit Befehlszeile
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4688} -MaxEvents 20 |
    ForEach-Object {
        $x = [xml]$_.ToXml()
        $d = @{}
        $x.Event.EventData.Data | ForEach-Object { $d[$_.Name] = $_.'#text' }
        [pscustomobject]@{
            Zeit     = $_.TimeCreated
            Prozess  = $d['NewProcessName']
            Eltern   = $d['ParentProcessName']
            Befehl   = $d['CommandLine']
        }
    } | Format-Table -AutoSize
```

Der erste Block erzeugt die GPO mit dem Registrywert. Der zweite Block liest die Ereignisse und zerlegt das XML in ein Wörterbuch aus Feldname und Wert. Aus den Feldern entsteht ein Objekt mit Zeit, Prozess, Elternprozess und Befehlszeile; genau diese vier Angaben braucht man für eine erste Bewertung. Ist die Spalte `Befehl` leer, ist entweder die Einstellung nicht aktiv oder die GPO noch nicht verarbeitet.

**Typische Fehler.** Falsch: die Befehlszeile zu protokollieren, ohne den Lesezugriff auf das Sicherheitsprotokoll zu prüfen. Richtig: nur Administratoren und Auswertungsdienste; die Gruppe „Ereignisprotokollleser“ (*Event Log Readers*) sparsam pflegen. Zweiter Fehler: Kennwörter in Befehlszeilen von Skripten zu übergeben, weil es „ja nur intern“ ist; die Protokollierung macht sie plötzlich dauerhaft lesbar. Richtig: Anmeldeinformationen nie als Parameter, sondern über sichere Verfahren. Dritter Fehler: Die Einstellung nur zu setzen, aber Abschnitt 81 zu vergessen; dann bleibt das Feld leer.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Verdacht auf Datendiebstahl führt zur Auswertung. Die Befehlszeile zeigt einen Aufruf von `powershell.exe` mit einem langen kodierten Argument. Das Team dekodiert es und findet die Adresse des Servers, an den Daten flossen. Dank der Befehlszeile ist der Fall innerhalb einer Stunde geklärt statt in Tagen.

## 83 Audit Logon Events

| **Feld**        | **Steckbrief**                                                                                                                         |
|:----------------|:---------------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Erweiterte Überwachungsrichtlinie \> Anmeldung/Abmeldung |
| Einstellung     | Anmeldung überwachen                                                                                                                   |
| Empfehlung      | Erfolg und Fehler                                                                                                                      |
| Ziel / Zweck    | Unterstützt Angriffserkennung                                                                                                          |
| Zielbereich     | Computer                                                                                                                               |
| Priorität       | 1                                                                                                                                      |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                            |

Der Name „Audit Logon Events“ stammt aus der älteren Basisüberwachung. Gemeint ist heute die Unterkategorie „Anmelden“ (*Logon*) unter Anmeldung/Abmeldung der Erweiterten Überwachungsrichtlinie. Sie protokolliert jeden Anmeldeversuch an einem Rechner: erfolgreiche (nach meiner Kenntnis Ereignis 4624) und fehlgeschlagene (4625). Die Ereignisse nennen das Konto, den Anmeldetyp (interaktiv, Netzwerk, Remotedesktop, Dienst und andere), die Quelladresse und bei Fehlschlägen einen Statuscode. Daraus erkennt man typische Angriffsmuster: viele Fehlversuche in kurzer Zeit (Kennwort-Raten oder *Password Spraying*), Anmeldungen zu ungewöhnlichen Zeiten, ein Administratorkonto, das sich plötzlich auf vielen Rechnern per Netzwerk anmeldet (seitliche Bewegung).

Der Lehrplan empfiehlt „Erfolg und Fehler“. Der Preis ist ein erhöhtes Ereignisvolumen, vor allem auf Servern, bei denen Netzwerkanmeldungen im Sekundentakt anfallen (etwa Dateiserver). Für Clients ist das Volumen meist vertretbar. Eine ehrliche Planung beginnt mit einer Messung im Pilot und der Anpassung der Protokollgröße (Abschnitt 87). Wer zusätzlich Abmeldungen und besondere Anmeldungen („Spezielle Anmeldung“, wenn ein Konto mit Administratorrechten anmeldet) überwacht, gewinnt weitere Hinweise; das ist optional.

> **Ergänzung aus der Nachrecherche**
>
> Auf Domänencontrollern entstehen Anmeldeereignisse für alle Domänenkonten. Die Überwachung der Kontoanmeldung („Anmeldeinformationen überprüfen“, Kerberos-Authentifizierung) ist eine eigene Kategorie, die auf Domänencontrollern gesetzt wird und im Lehrplan nicht eigens vorkommt. Wer Angriffe auf das Verzeichnis erkennen will, sollte sie in einer eigenen GPO für die Domänencontroller-OU ergänzen (nach meiner Kenntnis eine verbreitete Empfehlung; Details in der Microsoft-Baseline für Domänencontroller prüfen).

Das Beispiel setzt die Unterkategorie lokal zum Test und zeigt dann eine praktische Auswertung: die Zahl der Fehlschläge je Konto in der letzten Stunde. Die Feldnamen `TargetUserName` und `IpAddress` sind aus meiner Kenntnis des Ereignisformats und im Pilot zu prüfen.

```ps
# Auf einem TESTRECHNER: Erfolg und Fehler fuer "Logon"
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /get /subcategory:"Logon"

# Auswertung: Fehlversuche (4625) der letzten Stunde je Konto und Quelle
$seit = (Get-Date).AddHours(-1)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$seit} -ErrorAction SilentlyContinue |
    ForEach-Object {
        $x = [xml]$_.ToXml(); $d = @{}
        $x.Event.EventData.Data | ForEach-Object { $d[$_.Name] = $_.'#text' }
        [pscustomobject]@{ Konto = $d['TargetUserName']; Quelle = $d['IpAddress'] }
    } |
    Group-Object Konto, Quelle | Sort-Object Count -Descending |
    Select-Object -First 10 Count, Name
```

Die ersten beiden Befehle aktivieren und prüfen die Überwachung. Die Auswertung holt die Fehlschläge der letzten Stunde, extrahiert Konto und Quelladresse und gruppiert sie. Wenige Fehlversuche je Konto sind normal (Tippfehler); Dutzende in kurzer Zeit von einer Quelle, oder je ein Fehlversuch für sehr viele verschiedene Konten, deuten auf Angriffe.

**Typische Fehler.** Falsch: Anmeldeereignisse zu sammeln, aber nie auszuwerten. Ein Protokoll ohne Auswertung ist nur Ballast. Richtig: wenigstens wenige einfache Regeln (Schwellenwerte) im SIEM oder per Skript. Zweiter Fehler: Servern denselben Umfang wie Clients zu geben und dann wegen der Menge das Protokoll zu verlieren. Dritter Fehler: den Anmeldetyp zu ignorieren; ein Netzwerkanmeldetyp bedeutet etwas anderes als eine Anmeldung am Bildschirm.

> **Praxisbeispiel**
>
> Beispielszenario: In der Nacht melden sich 300 Fehlversuche gegen 300 verschiedene Konten an, jeweils mit demselben Kennwort. Das ist klassisches *Password Spraying*. Die Auswertung der Ereignisse nach Quelladresse findet den ausgehenden Rechner; die Firewall-Regel (Modul 04) sperrt ihn, das betroffene Kennwort wird zurückgesetzt.

## 84 Audit Account Lockout

| **Feld**        | **Steckbrief**                                                                                                                         |
|:----------------|:---------------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Erweiterte Überwachungsrichtlinie \> Anmeldung/Abmeldung |
| Einstellung     | Kontosperrung überwachen                                                                                                               |
| Empfehlung      | Erfolg                                                                                                                                 |
| Ziel / Zweck    | Erkennt Passwortangriffe                                                                                                               |
| Zielbereich     | Computer                                                                                                                               |
| Priorität       | 1                                                                                                                                      |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                            |

Eine *Kontosperre* schützt vor dem Raten von Kennwörtern: Nach einer festgelegten Zahl von Fehlversuchen wird das Konto vorübergehend gesperrt. Die Kontosperrungsrichtlinie selbst (Schwellenwert, Dauer, Zurücksetzungszeitraum) gehört zu den Kontorichtlinien auf Domänenebene und ist nicht Gegenstand dieses Abschnitts. Hier geht es darum, Sperren *sichtbar* zu machen. Die Unterkategorie „Kontosperrung“ (*Account Lockout*) protokolliert nach meiner Kenntnis Anmeldefehlversuche, die an einem gesperrten Konto scheitern. Die eigentliche Sperrung im Verzeichnis erscheint als Ereignis 4740 auf dem Domänencontroller (nach meiner Kenntnis), der „Anrufer-Computername“ nennt die Quelle. Damit ist die zweite Hälfte der Aufgabe klar: Die Clientüberwachung zeigt *wo* jemand versucht hat, die Domänencontroller-Überwachung zeigt *dass* und *von wo* gesperrt wurde.

Warum nur „Erfolg“? Die Sperre selbst ist ein erfolgreicher Vorgang des Systems. Die Fehlversuche, die dazu führen, erfasst bereits die Anmeldungsüberwachung aus Abschnitt 83. Eine Häufung von Sperren ist ein eindeutiges Signal; allerdings erzeugen auch harmlose Ursachen Sperren, zum Beispiel ein altes Kennwort auf einem Smartphone, in einer gemappten Netzlaufwerk-Verbindung oder in einer geplanten Aufgabe. Die Auswertung muss daher beides trennen: Angriff oder Verwaltungsfehler.

> **Merke**
>
> Wichtig für die Planung: Die Sperren entstehen am *Domänencontroller*, nicht am Client. Die Richtlinie auf Clients ergänzt das Bild, ersetzt aber nicht die Überwachung auf den Domänencontrollern. Wer nur Clients überwacht, verpasst die zentrale Sperrmeldung. Setzen Sie die Unterkategorie daher auch in einer GPO, die auf die Domänencontroller-OU verknüpft ist.

Das Beispiel sucht auf einem Domänencontroller die Sperrereignisse und zeigt, von welchem Rechner die Fehlversuche kamen. Die Feldnamen `TargetUserName` und `TargetDomainName` (der Name des Quellrechners) sind aus meiner Kenntnis des Ereignisses 4740 und im Pilot zu prüfen. Das Cmdlet `Get-ADUser` mit `-Properties LockedOut` gehört zum Modul ActiveDirectory.

```ps
# Auf dem Domaenencontroller: Sperr-Ereignisse der letzten 24 Stunden
$seit = (Get-Date).AddDays(-1)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4740; StartTime=$seit} -ErrorAction SilentlyContinue |
    ForEach-Object {
        $x = [xml]$_.ToXml(); $d = @{}
        $x.Event.EventData.Data | ForEach-Object { $d[$_.Name] = $_.'#text' }
        [pscustomobject]@{ Zeit = $_.TimeCreated; Konto = $d['TargetUserName']; QuellRechner = $d['TargetDomainName'] }
    } | Sort-Object Zeit -Descending

# Aktuell gesperrte Konten
Search-ADAccount -LockedOut | Select-Object SamAccountName, LockedOut, LastLogonDate
```

Der erste Block listet Sperren mit Zeit, Konto und Quellrechner. Taucht immer derselbe Quellrechner auf, liegt meist ein altes Kennwort in einer Anwendung oder Aufgabe dort. Der zweite Block zeigt, welche Konten gerade gesperrt sind; ein Mitarbeiter des Helpdesks kann gezielt entsperren (`Unlock-ADAccount`), sollte aber vorher die Ursache klären.

**Typische Fehler.** Falsch: gesperrte Konten reflexartig zu entsperren, ohne die Quelle zu suchen. Die Sperre kehrt dann in Minuten zurück. Richtig: erst den Quellrechner aus dem Ereignis ermitteln. Zweiter Fehler: die Sperrschwelle so niedrig zu setzen, dass Angreifer mit absichtlichen Fehlversuchen Konten sperren können (ein einfacher Angriff auf die Verfügbarkeit). Richtig: moderate Schwelle, überwacht. Dritter Fehler: nur Clients zu überwachen.

> **Praxisbeispiel**
>
> Beispielszenario: Eine Mitarbeiterin ändert montags ihr Kennwort, danach wird ihr Konto stündlich gesperrt. Das Ereignis 4740 nennt als Quelle ihr Smartphone-Gateway, das noch das alte Kennwort verwendet. Nach der Aktualisierung des E-Mail-Profils auf dem Telefon sind die Sperren verschwunden.

## 85 Audit Policy Change

| **Feld**        | **Steckbrief**                                                                                                                         |
|:----------------|:---------------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Erweiterte Überwachungsrichtlinie \> Richtlinienänderung |
| Einstellung     | Richtlinienänderung überwachen                                                                                                         |
| Empfehlung      | Erfolg und Fehler                                                                                                                      |
| Ziel / Zweck    | Erkennt Manipulation an Sicherheitsrichtlinien                                                                                         |
| Zielbereich     | Computer                                                                                                                               |
| Priorität       | 1                                                                                                                                      |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                            |

Wer sich unbemerkt auf einem Rechner bewegen will, schaltet zuerst die Überwachung aus. Genau dagegen richtet sich die Kategorie „Richtlinienänderung“ (*Policy Change*). Die Unterkategorie „Überwachungsrichtlinie ändern“ (*Audit Policy Change*) schreibt nach meiner Kenntnis das Ereignis 4719, wenn die Überwachungsrichtlinie des Systems verändert wird. Es nennt, wer die Änderung vorgenommen hat und welche Unterkategorie von welchem Wert auf welchen gewechselt wurde. Eine solche Änderung ist im laufenden Betrieb selten und damit ein starkes Signal: Eine Gruppenrichtlinie ändert sie regelmäßig bei Einführung, danach sollte Ruhe sein.

Weitere Unterkategorien der Kategorie sind verwandt: die „Authentifizierungsrichtlinie ändern“ (Änderungen an Vertrauensstellungen und Kerberos-Richtlinie), die „Autorisierungsrichtlinie ändern“ (Änderungen an Benutzerrechten, siehe Modul 08) und die „MPSSVC-Regelebenen-Richtlinie ändern“ (Änderungen an Firewallregeln, Modul 04). Der Lehrplan nennt nur die erste. Für ein vollständiges Bild lohnt es sich, wenigstens die Autorisierungs- und Firewall-Änderungen mit zu überwachen, weil sie typische Angreiferschritte abbilden. Die Entscheidung ist im Pilot mit Blick auf das Ereignisvolumen zu treffen.

> **Ergänzung aus der Nachrecherche**
>
> Die Richtlinie selbst wird für Erweiterte Überwachung in der Datei `audit.csv` im SYSVOL-Ordner der GPO gespeichert (nach meiner Kenntnis unter `Machine\Microsoft\Windows NT\Audit`). Das ist für den Forensiker nützlich: Die Datei zeigt den Soll-Zustand, `auditpol /get /category:*` den Ist-Zustand. Weichen beide ab, hat jemand lokal eingegriffen oder die GPO wurde nicht verarbeitet.

Das Beispiel prüft den Ist-Zustand gegen einen Sollwert und sucht Änderungsereignisse. Das Skript liest die Ausgabe von `auditpol /get /category:*` in CSV-Form (der Schalter `/r` liefert CSV nach meiner Kenntnis der Ausgabeoptionen; im Pilot prüfen), vergleicht sie mit einer Sollliste und gibt Abweichungen aus. Die Ausgabespaltennamen sind sprachabhängig; das Beispiel nutzt daher Spaltenpositionen.

```ps
# Soll-Zustand (Beispiel): Unterkategorie -> erwarteter Wert (englische Namen)
$soll = @{ 'Process Creation' = 'Success'; 'Logon' = 'Success and Failure' }

# Ist-Zustand lesen (CSV) und mit Soll vergleichen
$ist = auditpol /get /category:* /r | ConvertFrom-Csv
$ist | ForEach-Object {
    $name = $_.PSObject.Properties.Value[2]    # Unterkategorie
    $wert = $_.PSObject.Properties.Value[4]    # Einstellung
    if ($soll.ContainsKey($name) -and $soll[$name] -ne $wert) {
        "ABWEICHUNG: $name ist '$wert', erwartet '$($soll[$name])'"
    }
}

# Wurde die Ueberwachungsrichtlinie veraendert? (Ereignis 4719)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4719} -MaxEvents 5 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Message
```

Die Sollliste enthält die erwarteten Werte; das Skript liest den Ist-Zustand, vergleicht und meldet Abweichungen. Auf einem deutschen System sind die Namen der Unterkategorien deutsch, die Liste müsste entsprechend angepasst werden. Der letzte Block listet die jüngsten Änderungen der Überwachungsrichtlinie. Im Normalbetrieb ist die Liste leer oder zeigt nur die Zeitpunkte der Gruppenrichtlinienverarbeitung.

**Typische Fehler.** Falsch: Änderungen an der Überwachung nicht zu überwachen, weil „das ja nie passiert“. Genau das macht sie für Angreifer attraktiv. Richtig: Erfolg *und* Fehler. Zweiter Fehler: die Ereignisse nur lokal zu halten; ein Angreifer mit Administratorrechten kann das lokale Protokoll löschen (Ereignis 1102, nach meiner Kenntnis). Richtig: Weiterleitung an einen Sammler (Abschnitt 90). Dritter Fehler: bei der Auswertung die eigenen Gruppenrichtlinienänderungen als Angriff zu werten; Änderungsfenster mit der Ereigniszeit abgleichen.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Eindringling schaltet auf einem Server die Prozessüberwachung aus. Das Ereignis 4719 wird noch geschrieben und leitet an den Sammler weiter. Die Auswertung meldet die Änderung außerhalb des Änderungsfensters, und der Vorfall wird bemerkt, bevor weiterer Schaden entsteht.

## 86 Audit Privilege Use

| **Feld**        | **Steckbrief**                                                                                                                      |
|:----------------|:------------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Erweiterte Überwachungsrichtlinie \> Rechteverwendung |
| Einstellung     | Sensible Rechteverwendung überwachen                                                                                                |
| Empfehlung      | Fehler/gezielt Erfolg                                                                                                               |
| Ziel / Zweck    | Erkennt Missbrauch erweiterter Rechte                                                                                               |
| Zielbereich     | Computer                                                                                                                            |
| Priorität       | 2                                                                                                                                   |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                         |

In Modul 08 ging es um Benutzerrechte wie das Debuggen von Programmen oder das Imitieren von Clients. Die Kategorie „Rechteverwendung“ (*Privilege Use*) protokolliert, wenn solche Rechte tatsächlich benutzt werden. Sie enthält die Unterkategorien „Verwendung vertraulicher Rechte“ (*Sensitive Privilege Use*), „Verwendung nicht vertraulicher Rechte“ und „Sonstige Rechteverwendung“. Die Microsoft-Community-Antwort zu unerwarteter Rechteverwendung nennt zwei Ereignisse: 4673 (ein privilegierter Dienst wurde aufgerufen) mit Konto, Anmelde-ID, Prozess-ID, Prozessname und dem verwendeten Recht, sowie 4674 (ein Vorgang an einem privilegierten Objekt wurde versucht). Entscheidend ist der Rat dieser Antwort: Man soll solche Ereignisse nicht isoliert bewerten, sondern mit der Prozesserstellung (Ereignis 4688) und den Anmeldeereignissen über die Anmelde-ID korrelieren.

Warum der Lehrplan „Fehler, gezielt Erfolg“ empfiehlt, ist schnell erklärt: Das Volumen der Erfolgsereignisse in der Unterkategorie „Vertraulich“ ist auf einem normalen Rechner sehr hoch, weil Systemprozesse ständig Rechte benutzen. Fehlgeschlagene Rechteverwendung ist dagegen selten und auffällig. Wer gezielt Erfolgsereignisse braucht, etwa für die Untersuchung eines bestimmten Rechts wie `SeDebugPrivilege`, aktiviert sie zeitlich begrenzt auf betroffenen Rechnern, nicht flächendeckend.

> **Merke**
>
> Die Einstellung ist ein Beispiel für den Unterschied zwischen „protokollieren, was möglich ist“ und „protokollieren, was man auswerten kann“. Eine Überwachung, deren Volumen das Sicherheitsprotokoll in Minuten überläuft, vernichtet wertvolle Ereignisse. Erst messen, dann aktivieren.

Das Beispiel aktiviert Fehlerüberwachung für die vertrauliche Rechteverwendung auf einem Testrechner und zählt anschließend, welche Rechte in den letzten Ereignissen vorkamen. Der Feldname `PrivilegeList` ist aus meiner Kenntnis des Ereignisses 4673 und im Pilot zu prüfen.

```ps
# Testrechner: nur Fehler in der Unterkategorie "Sensitive Privilege Use"
auditpol /set /subcategory:"Sensitive Privilege Use" /failure:enable
auditpol /get /subcategory:"Sensitive Privilege Use"

# Welche Rechte tauchen in den letzten Ereignissen auf, und welche Prozesse?
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4673} -MaxEvents 200 -ErrorAction SilentlyContinue |
    ForEach-Object {
        $x = [xml]$_.ToXml(); $d = @{}
        $x.Event.EventData.Data | ForEach-Object { $d[$_.Name] = $_.'#text' }
        [pscustomobject]@{ Prozess = $d['ProcessName']; Recht = $d['PrivilegeList'] }
    } | Group-Object Recht, Prozess | Sort-Object Count -Descending | Select-Object -First 10 Count, Name
```

Der erste Block schaltet nur Fehlerereignisse ein. Der zweite gruppiert die letzten 200 Ereignisse nach Recht und Prozess. In der Praxis zeigt sich ein Grundrauschen aus bekannten Systemprozessen; interessant sind seltene Kombinationen, zum Beispiel ein Office-Programm, das ein Debug-Recht anfordert.

**Typische Fehler.** Falsch: „Erfolg“ für sensible Rechte auf allen Rechnern zu aktivieren und das Protokoll zu überfluten. Richtig: gezielt und zeitlich begrenzt. Zweiter Fehler: Ereignisse ohne Kontext zu bewerten (siehe oben). Dritter Fehler: darauf zu vertrauen, dass die Einstellung Angriffe verhindert; sie ist nur eine Spur.

> **Praxisbeispiel**
>
> Beispielszenario: Nach einem Vorfall schaltet das Sicherheitsteam auf dem betroffenen Rechner kurzzeitig Erfolgsereignisse ein, stellt das Verhalten des Angreifers nach und erkennt, welche Rechte er genutzt hat. Danach wird die Einstellung auf den Normalzustand zurückgesetzt.

## 87 Security Log Größe erhöhen

| **Feld**        | **Steckbrief**                                                                                  |
|:----------------|:------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Ereignisprotokoll |
| Einstellung     | Maximale Größe Sicherheitsprotokoll                                                             |
| Empfehlung      | Mindestens 196 MB oder SIEM-Vorgabe                                                             |
| Ziel / Zweck    | Verhindert schnellen Logverlust                                                                 |
| Zielbereich     | Computer                                                                                        |
| Priorität       | 1                                                                                               |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.     |

Ein Ereignisprotokoll ist ein Ringpuffer: Ist es voll, überschreibt Windows standardmäßig die ältesten Einträge. Die Standardgröße des Sicherheitsprotokolls beträgt nach den Wiederherstellungsbefehlen in Microsofts Anleitung zur Skriptfehlersuche 20 MB (20971520 Byte). Schaltet man die Überwachung aus den Abschnitten 81 bis 86 ein, füllt sich dieser Puffer auf einem aktiven Rechner schnell, und Beweise von vor zwei Tagen sind bereits überschrieben, wenn man sie braucht. Deshalb verlangt der Lehrplan eine größere Protokolldatei.

Eine Anmerkung zur Zahl: Die Einstellung „Maximale Größe des Sicherheitsprotokolls“ wird in Kilobyte angegeben. Die in vielen Baselines genannte Zahl 196608 KB entspricht 192 MB; der Lehrplan schreibt „196 MB“ als Kurzform. Praktisch bedeutet das: Man wählt entweder 196608 KB oder den Wert, den das SIEM-Team vorgibt, wenn die Ereignisse ohnehin zentral gesammelt werden. Dann dient das lokale Protokoll nur als Puffer für Netzausfälle. Die zweite wichtige Einstellung ist die Aufbewahrungsmethode: „Ereignisse bei Bedarf überschreiben“ verhindert, dass das System stehen bleibt, wenn das Protokoll voll ist. Das „Herunterfahren bei vollem Protokoll“ (Sicherheitsoption „Audit: Shut down system immediately if unable to log security audits“) gehört in sehr hoch gesicherte Umgebungen und nicht in den Standard.

> **Ergänzung aus der Nachrecherche**
>
> Microsoft zeigt in seiner Anleitung zur Analyse von PowerShell-Ausführungen, wie man die Größe per Befehl ändert (`wevtutil set-log`). Das Prinzip gilt auch für die GPO: Die Anleitung zur Intrusion Detection mit Windows Event Forwarding verwendet für spezielle Kanäle Größen im Bereich von rund 50 bis 100 MB (Parameter `/ms:` in Byte). Der Wert ist stets eine Abwägung zwischen Speicherplatz und Aufbewahrungsdauer; die Rechner brauchen den Platz auf dem Systemlaufwerk.

Das Beispiel rechnet aus, wie lange das Protokoll bei gegebener Ereignisrate reicht, und zeigt, wie man die Größe per GPO bzw. am Testrechner setzt. Der Registrypfad `HKLM\SOFTWARE\Policies\Microsoft\Windows\EventLog\Security` mit dem Wert `MaxSize` (in KB) ist aus meiner Kenntnis und im Pilot zu prüfen; die Einstellung selbst wird in der GPO-Oberfläche unter dem Pfad des Steckbriefs vorgenommen.

```ps
# Wie lange reicht das Protokoll? Beispielhafte Schaetzung aus echten Daten
$log   = Get-WinEvent -ListLog Security
$erste = (Get-WinEvent -LogName Security -Oldest -MaxEvents 1).TimeCreated
$tage  = ((Get-Date) - $erste).TotalDays
"Maximale Groesse: {0:N0} MB, aktuell belegt: {1:N0} MB, Zeitraum im Protokoll: {2:N1} Tage" -f `
    ($log.MaximumSizeInBytes/1MB), ($log.FileSize/1MB), $tage

# Testrechner: Groesse auf 192 MB setzen (Wert in Byte)
wevtutil sl Security /ms:201326592

# Per GPO (Registry-Richtlinie, nach meiner Kenntnis): MaxSize in KB
Import-Module GroupPolicy
Set-GPRegistryValue -Name "AUDIT-Log-Groesse" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\EventLog\Security" `
    -ValueName MaxSize -Type DWord -Value 196608
```

Der erste Block liest Größe, Belegung und den Zeitraum, den das Protokoll aktuell abdeckt. Wer heute 20 MB hat und nur zwei Tage Historie sieht, kann abschätzen, wie viel mehr er braucht. Der zweite Befehl setzt die Größe lokal in Byte, der dritte setzt die Richtlinie in Kilobyte (196608 KB = 192 MB). Wichtig sind die unterschiedlichen Einheiten: `wevtutil` verlangt Byte, die Richtlinie Kilobyte.

**Typische Fehler.** Falsch: Byte und Kilobyte zu verwechseln und das Protokoll auf einen winzigen oder gigantischen Wert zu setzen. Richtig: nachrechnen (192 MB = 201326592 Byte = 196608 KB). Zweiter Fehler: nur das Sicherheitsprotokoll zu vergrößern und das PowerShell-Protokoll (Abschnitt 88) zu vergessen. Dritter Fehler: sich auf die lokale Größe zu verlassen, obwohl ein Angreifer das Protokoll löschen kann; die Weiterleitung (Abschnitt 90) ist der eigentliche Schutz.

> **Praxisbeispiel**
>
> Beispielszenario: Eine Untersuchung betrifft einen Vorfall vor neun Tagen. Auf Rechnern mit 20 MB Protokoll sind die Daten längst weg, auf Rechnern mit größerem Puffer und Weiterleitung liegen sie vollständig vor. Die Kosten der Maßnahme sind einige hundert Megabyte Plattenplatz.

## 88 PowerShell Script Block Logging

| **Feld**        | **Steckbrief**                                                                                |
|:----------------|:----------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows PowerShell |
| Einstellung     | PowerShell-Skriptblockprotokollierung aktivieren                                              |
| Empfehlung      | Aktiviert                                                                                     |
| Ziel / Zweck    | Erkennt Missbrauch von PowerShell                                                             |
| Zielbereich     | Computer                                                                                      |
| Priorität       | 1                                                                                             |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.   |

PowerShell ist das mächtigste Verwaltungswerkzeug von Windows und aus demselben Grund ein Lieblingswerkzeug von Angreifern: Es ist auf jedem Rechner vorhanden und kann Programme starten, Dateien laden und Systemeinstellungen ändern. Die Befehlszeile aus Abschnitt 82 zeigt nur, *dass* und mit welchen Argumenten PowerShell gestartet wurde. Wenn der Befehl aber ein verschleierter, kodierter Text ist, hilft das wenig. Die *Skriptblockprotokollierung* (*Script Block Logging*) schließt diese Lücke: Laut Microsoft-Dokumentation wird der Inhalt aller Skriptblöcke aufgezeichnet, die PowerShell verarbeitet, also Befehle, Funktionen und Skripte, ob interaktiv oder automatisiert. Der Skriptblock wird so protokolliert, wie er zur Ausführung gelangt, nachdem der Code dekodiert wurde; damit bringt die Protokollierung auch verschleierte Befehle an den Tag.

Technisch landen die Einträge in der Protokolldatei `Microsoft-Windows-PowerShell/Operational` als Ereignis 4104. Die Gruppenrichtlinie heißt „Turn on PowerShell Script Block Logging“ (Administrative Vorlagen \> Windows-Komponenten \> Windows PowerShell), der Registrywert `EnableScriptBlockLogging` im Schlüssel `Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging`. Die Einstellung existiert laut Policy-CSP-Dokumentation für Computer und Benutzer; die Computereinstellung hat Vorrang. Optional gibt es die „Skriptblock-Aufrufprotokollierung“ (*Invocation Logging*), die laut Microsoft ein hohes Ereignisvolumen erzeugt und in der Regel nicht empfohlen wird.

> **Ergänzung aus der Nachrecherche**
>
> Microsoft weist ausdrücklich darauf hin, dass man die „geschützte Ereignisprotokollierung“ (*Protected Event Logging*) aktivieren sollte, wenn die Skriptblockprotokollierung für mehr als Diagnosezwecke genutzt wird, weil Skripte sensible Daten enthalten können. Außerdem gilt: Das neuere PowerShell 7 hat eigene Einstellungen (Administrative Vorlagen \> PowerShell Core, Ereignisprotokoll `PowerShellCore/Operational`); die Richtlinie für Windows PowerShell 5.1 erfasst es nicht. Wer PowerShell 7 einsetzt, muss beide Einstellungen pflegen. Zusätzlich übergibt PowerShell ab Version 5.1 unter Windows 10 und höher alle Skriptblöcke an die Antischadsoftware-Schnittstelle AMSI, was dem Defender (Modul 02) die Prüfung ermöglicht.

Das Beispiel aktiviert die Einstellung, führt einen harmlosen Befehl aus und zeigt, wie man das Ereignis findet. Die Ausgabe zeigt, dass der Text des Skriptblocks im Ereignis steht. Wichtig ist, dass der Test auf einem Testrechner läuft, weil das Protokoll danach sensible Daten enthalten kann.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "AUDIT-PowerShell-ScriptBlock"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" `
    -ValueName EnableScriptBlockLogging -Type DWord -Value 1

# Am Testrechner nach gpupdate: Befehl ausfuehren und im Protokoll finden
gpupdate /force | Out-Null
powershell.exe -NoProfile -Command "Get-Date; 'Testmarke-4711'"
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-PowerShell/\allowbreak{}Operational'; Id=4104} -MaxEvents 20 |
    Where-Object { $_.Message -match 'Testmarke-4711' } |
    Select-Object TimeCreated, Id, @{n='Auszug'; e={ $_.Message.Substring(0, [Math]::Min(120, $_.Message.Length)) }}
```

Der erste Block setzt die Registry-Richtlinie. Der zweite startet eine neue PowerShell-Sitzung (nur neue Sitzungen protokollieren), führt zwei harmlose Befehle aus und sucht anschließend das Ereignis anhand einer eindeutigen Testmarke. Die Marke taucht im Nachrichtentext des Ereignisses auf. Zu beachten: Das Operational-Protokoll hat eine eigene, standardmäßig kleine Größe; sie sollte wie in Abschnitt 87 angehoben werden.

**Typische Fehler.** Falsch: die Protokollierung zu aktivieren und das Protokoll nicht zu vergrößern. Das „PowerShell/Operational“ läuft bei aktiver Protokollierung schnell voll. Richtig: Größe anpassen, Weiterleitung einrichten. Zweiter Fehler: Kennwörter in Skripten im Klartext zu führen; sie landen jetzt im Protokoll. Richtig: Anmeldeinformationen aus Tresoren laden. Dritter Fehler: zu glauben, ein Angreifer könne die Protokollierung nicht umgehen. Er kann es mit Administratorrechten (zum Beispiel durch Einsatz älterer PowerShell-Versionen oder durch Ändern der Einstellung); deshalb sind Weiterleitung und Überwachung der Richtlinienänderung (Abschnitt 85) wichtig.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Alarm meldet „PowerShell mit kodiertem Befehl“. Das Ereignis 4104 enthält den entschlüsselten Skriptinhalt und zeigt, dass das Skript die Adresse eines externen Servers abfragt. Der Rechner wird isoliert, das Skript im Wortlaut an das Sicherheitsteam übergeben.

## 89 PowerShell Module Logging

| **Feld**        | **Steckbrief**                                                                                |
|:----------------|:----------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows PowerShell |
| Einstellung     | Modulprotokollierung aktivieren                                                               |
| Empfehlung      | Aktiviert für kritische Module                                                                |
| Ziel / Zweck    | Erweitert Nachvollziehbarkeit                                                                 |
| Zielbereich     | Computer                                                                                      |
| Priorität       | 2                                                                                             |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.   |

Die *Modulprotokollierung* (*Module Logging*) ergänzt die Skriptblockprotokollierung. Während diese den *Programmtext* aufzeichnet, protokolliert die Modulprotokollierung die *Ausführung* der Pipeline: also welche Cmdlets eines bestimmten Moduls mit welchen Parametern und Ergebnissen gelaufen sind. Laut Microsoft-Dokumentation zeichnet PowerShell Pipeline-Ausführungsereignisse für die angegebenen Module im Windows-PowerShell-Protokoll auf. Wenn die Richtlinie deaktiviert ist, protokolliert PowerShell keine Modulereignisse; ist sie nicht konfiguriert, entscheidet die Eigenschaft `LogPipelineExecutionDetails` des jeweiligen Moduls, die standardmäßig `$false` ist.

Die Richtlinie braucht eine Modulliste. Als Eintrag ist der Stern erlaubt, der alle Module einschließt. Der Lehrplan empfiehlt „kritische Module“: Eine praxistaugliche Liste enthält zum Beispiel `Microsoft.PowerShell.*`, `Microsoft.WSMan.Management` sowie Module, die Konten oder Remotezugriff betreffen (ActiveDirectory, GroupPolicy). Wie hoch das Volumen ausfällt, hängt stark davon ab, wie viele Skripte laufen; der Stern kann in Umgebungen mit Automatisierung zu großen Datenmengen führen. Die Auswahl ist also eine Abwägung, die man im Pilot messen sollte. Die Microsoft-Q&A-Antwort zur Überflutung des Ereignisprotokolls beschreibt, dass genau diese beiden Einstellungen bei vielen Routineaufgaben große Mengen erzeugen können; die empfohlene Reduktion ist, die Modulliste zu verkleinern, nicht die Protokollierung insgesamt abzuschalten.

> **Merke**
>
> Skriptblockprotokollierung und Modulprotokollierung ergänzen sich, ersetzen sich aber nicht. Wenn nur eine der beiden machbar ist (Volumen, Speicherplatz), ist die Skriptblockprotokollierung in der Regel der wertvollere Teil, weil sie den ausgeführten Code selbst festhält. Die Modulprotokollierung liefert zusätzlich Parameterwerte und Ausgaben.

Das Beispiel richtet die Modulprotokollierung mit einer Modulliste ein. Die Registry-Struktur (Wert `EnableModuleLogging` im Schlüssel `ModuleLogging` und die Modulnamen als Werte im Unterschlüssel `ModuleNames`) bestätigt die Microsoft-Anleitung zum Zurücknehmen der Einstellung. Das Ereignis (nach meiner Kenntnis die ID 4103 im Protokoll „Microsoft-Windows-PowerShell/Operational“) ist im Pilot zu prüfen.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "AUDIT-PowerShell-Module"
$base = "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $base -ValueName EnableModuleLogging -Type DWord -Value 1
# Modulliste: Name des Moduls als Wertname, gleicher Text als Wert
foreach ($m in 'Microsoft.PowerShell.*','ActiveDirectory','GroupPolicy','Microsoft.WSMan.Management') {
    Set-GPRegistryValue -Name $gpo.DisplayName -Key "$base\ModuleNames" -ValueName $m -Type String -Value $m
}

# Am Testrechner: Ereignisse der Pipeline-Ausfuehrung ansehen
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-PowerShell/\allowbreak{}Operational'; Id=4103} -MaxEvents 5 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id
```

Der erste Block legt die GPO an, aktiviert die Modulprotokollierung und trägt vier Module in die Liste ein. Jede Modulbezeichnung ist Wertname und Wert zugleich; das Format entspricht dem, was der Gruppenrichtlinien-Editor in der Registry ablegt (nach meiner Kenntnis, im Pilot zu prüfen). Der zweite Block liest ein paar Ereignisse zur Kontrolle.

**Typische Fehler.** Falsch: den Stern einzutragen und sich dann über volle Protokolle zu wundern. Richtig: schrittweise starten. Zweiter Fehler: die Modulliste nach der Erstellung nicht zu pflegen; neue Module (zum Beispiel für Cloud-Verwaltung) fehlen. Dritter Fehler: die Einstellung für Windows PowerShell zu setzen und PowerShell 7 zu vergessen (siehe Abschnitt 88).

> **Praxisbeispiel**
>
> Beispielszenario: Ein Administrator behauptet, er habe einen Benutzer nie in die Gruppe der Domänen-Admins aufgenommen. Die Modulprotokollierung des ActiveDirectory-Moduls zeigt den Aufruf von `Add-ADGroupMember` mit Parametern, Zeit und Rechner. Damit ist der Fall geklärt, ohne Vorwürfe auf Vermutungen zu stützen.

## 90 Windows Event Forwarding vorbereiten

| **Feld**        | **Steckbrief**                                                                                   |
|:----------------|:-------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Ereignisweiterleitung |
| Einstellung     | Subscription Manager konfigurieren                                                               |
| Empfehlung      | SIEM/Collector-Vorgabe                                                                           |
| Ziel / Zweck    | Zentralisiert Sicherheitsereignisse                                                              |
| Zielbereich     | Computer                                                                                         |
| Priorität       | 2                                                                                                |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.      |

Alle bisherigen Einstellungen erzeugen Ereignisse, aber sie bleiben auf dem jeweiligen Rechner. Das hat zwei große Nachteile: Ein Angreifer mit Administratorrechten kann das lokale Protokoll löschen, und eine Auswertung über hundert Rechner hinweg ist mühsam. *Windows Event Forwarding* (WEF) löst beides, indem Clients ausgewählte Ereignisse an einen zentralen *Sammler* (englisch *Event Collector*) schicken. Microsofts Dokumentation beschreibt zwei Arten von Abonnements: Beim *quellinitiierten* Abonnement (*source-initiated*) definiert man das Abonnement auf dem Sammler, ohne die Quellrechner aufzuzählen; die Quellen melden sich selbst, gesteuert per Gruppenrichtlinie. Beim *sammlerinitiierten* Abonnement (*collector-initiated*) nennt der Sammler alle Quellen. Für große Umgebungen ist die quellinitiierte Variante üblich, weil sie ohne Aufzählung funktioniert.

Der Teil, der in die Gruppenrichtlinie gehört, ist klein: Die Einstellung „Configure target Subscription Manager“ (Administrative Vorlagen \> Windows-Komponenten \> Ereignisweiterleitung) trägt den Sammler ein. Microsofts Beispiel für Quellen in derselben Domäne lautet sinngemäß: `Server=http://<Sammler-FQDN>:5985/wsman/SubscriptionManager/WEC,Refresh=<Sekunden>`; für Quellen außerhalb der Domäne wird `HTTPS` auf Port 5986 mit der Angabe des ausstellenden Zertifikats (`IssuerCA`) verwendet. Der Registrypfad ist laut Microsoft `HKLM\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager`. Als Mindestvoraussetzungen nennt Microsoft für den Client: den Sammler eintragen, den WinRM-Dienst starten und das Konto „Netzwerkdienst“ (Network Service) in die Gruppe „Ereignisprotokollleser“ aufnehmen, damit auch das Sicherheitsprotokoll gelesen werden kann.

> **Ergänzung aus der Nachrecherche**
>
> Dimensionierung laut Microsoft: Standardmäßig hat ein Abonnement den Modus „Normal“ (Pull, fünf Ereignisse pro Stapel, Zeitlimit 15 Minuten); der Modus „Latenz minimieren“ liefert in 30 Sekunden Stapeln, „Bandbreite minimieren“ nur alle sechs Stunden. Die Standardeinstellung kann bei 2.000 bis 4.000 Clients je Sammler einen hohen Speicherbedarf verursachen. Man teilt Clients daher auf mehrere Sammler auf und verteilt sie mit GPOs, die über Sicherheitsfilter oder WMI-Filter zugewiesen werden. Microsoft empfiehlt außerdem, Abfragen zusammenzufassen, statt viele Abonnements zu betreiben. Eine Stolperfalle ist die Berechtigung der Dienste auf dem Sammler: Auf Windows Server 2016/2019 können die Dienste WinRM und Windows-Ereignissammler in getrennten Prozessen laufen, dann schlägt die Weiterleitung fehl, bis die URL-Berechtigungen angepasst wurden (Microsoft-Artikel „Events are not forwarded“).

Das Beispiel zeigt beide Seiten: die GPO für die Quellen und die Befehle für den Sammler. Der Wert in der Registry ist laut Microsoft-Dokumentation eine Liste, in der jede Zeile ein Sammler ist; als Wertname dient in der Praxis eine fortlaufende Nummer (nach meiner Kenntnis, im Pilot zu prüfen). Die Sammlerbefehle `winrm qc -q` und `wecutil qc /q` nennt die Microsoft-Anleitung wörtlich; die Datei `subscription.xml` muss man selbst erstellen.

```ps
# --- Quellen: GPO mit Sammleradresse ---
Import-Module GroupPolicy
$gpo = New-GPO -Name "AUDIT-WEF-Quellen"
$sm  = "Server=http://wec01.contoso.local:5985/wsman/\allowbreak{}SubscriptionManager/\allowbreak{}WEC,Refresh=60"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager" `
    -ValueName 1 -Type String -Value $sm

# Netzwerkdienst darf Ereignisse lesen (sonst fehlt das Sicherheitsprotokoll)
# In der Praxis ueber "Eingeschraenkte Gruppen"/Preferences; lokal zum Test:
Add-LocalGroupMember -Group "Event Log Readers" -Member "NT AUTHORITY\NETWORK SERVICE"

# --- Sammler (wec01), als Administrator ---
winrm qc -q
wecutil qc /q
wecutil cs C:\WEF\subscription.xml      # Abonnement aus XML anlegen
wecutil gr  MeinAbonnement              # Laufzeitstatus der Quellen
```

Der erste Abschnitt legt die GPO an und trägt die Sammleradresse mit einem Aktualisierungsintervall von 60 Sekunden ein. Der zweite nimmt das Konto „Netzwerkdienst“ in die Lesergruppe auf; für die Produktion setzt man dies über eine zentrale Konfiguration und nicht lokal. Der dritte Abschnitt konfiguriert den Sammler und legt ein Abonnement an; `wecutil gr` zeigt, welche Quellen sich verbunden haben. Auf der Quelle bestätigt laut Microsoft das Ereignis 104 im Protokoll „Eventlog-ForwardingPlugin/Operational“ den Verbindungsaufbau.

**Typische Fehler.** Falsch: alle Ereignisse aller Rechner weiterzuleiten. Der Sammler erstickt und der Wert sinkt. Richtig: wenige, gut gewählte Abfragen (Anmeldungen, Prozessstarts, Richtlinienänderungen, PowerShell, Protokolllöschung). Zweiter Fehler: die Quellen ohne Zeitsynchronisation (Domänenzeit) zu betreiben; Ereignisse lassen sich dann nicht zeitlich ordnen. Dritter Fehler: den Sammler selbst nicht zu schützen: Er enthält die gesammelten Sicherheitsereignisse der gesamten Umgebung und ist ein hochwertiges Ziel; Zugriff, Sicherung, Härtung (Modul 01 bis 04) sind Pflicht. Vierter Fehler: das Sammler-System zu vergessen, wenn sich die Firewallregel (Modul 04) ändert; Quellen brauchen ausgehenden Zugriff auf Port 5985 bzw. 5986.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Angreifer löscht auf dem übernommenen Rechner das Sicherheitsprotokoll. Die Ereignisse bis kurz davor liegen aber bereits auf dem Sammler. Der Löschvorgang selbst ist als Ereignis ebenfalls weitergeleitet worden, und das Team sieht Zeitpunkt und Konto.

## Übungsaufgaben zu Modul 09

**Aufgabe 1.** **(leicht)** Warum reicht es nicht, nur die Befehlszeile (Abschnitt 82) zu aktivieren? Welche Einstellung muss zusätzlich aktiv sein?

**Aufgabe 2.** **(leicht)** Welche Ereignis-ID gehört zur Prozesserstellung, und welche drei Angaben braucht man aus dem Ereignis für eine erste Bewertung?

**Aufgabe 3.** **(leicht)** Erklären Sie den Unterschied zwischen Basisüberwachung und Erweiterter Überwachungsrichtlinie und warum man sie nicht mischen sollte.

**Aufgabe 4.** **(mittel)** Das Sicherheitsprotokoll hat 20 MB, ein Rechner erzeugt 2 MB Ereignisse pro Stunde. Wie lange reicht das Protokoll? Welche Größe in KB ist für sieben Tage Historie nötig?

**Aufgabe 5.** **(mittel)** Wo entsteht die Sperrmeldung bei einer Kontosperre, und warum reicht die Clientüberwachung allein nicht?

**Aufgabe 6.** **(praktisch)** Schreiben Sie ein Skript, das für alle Anmeldefehler (4625) der letzten 24 Stunden die fünf häufigsten Kombinationen aus Konto und Quelladresse ausgibt.

**Aufgabe 7.** **(praktisch)** Schreiben Sie ein Skript, das mit `Set-GPRegistryValue` eine GPO erzeugt, die Skriptblockprotokollierung und Modulprotokollierung für die Module `ActiveDirectory` und `GroupPolicy` aktiviert.

**Aufgabe 8.** **(schwer)** Entwerfen Sie ein Protokollierungskonzept für 500 Clients und 20 Server: Welche Überwachungen setzen Sie, welche Größe, welche Weiterleitung, wer darf lesen, wie begründen Sie den Umfang gegenüber dem Datenschutz? (Hinweis: keine Rechtsberatung.)

## Lösungen zu Modul 09

**Lösung 1.** Die Befehlszeile ist nur eine Ergänzung des Ereignisses 4688. Ohne aktive Überwachung der Prozesserstellung (Abschnitt 81) entstehen keine Ereignisse, also bleibt das Feld ungenutzt. Beide Einstellungen sind nötig.

**Lösung 2.** Ereignis 4688. Für die Bewertung nützen der gestartete Prozess, der Elternprozess und die Befehlszeile (sowie Konto und Zeit).

**Lösung 3.** Die Basisüberwachung kennt neun grobe Kategorien, die erweiterte rund 60 Unterkategorien. Mischt man beide, kann die Basiseinstellung die Unterkategorien überschreiben oder umgekehrt. Mit der Sicherheitsoption zur Erzwingung der Unterkategorien setzt man die erweiterte Variante durch.

**Lösung 4.** 20 MB bei 2 MB je Stunde = 10 Stunden. Für sieben Tage: 7 mal 24 mal 2 MB = 336 MB = 344064 KB (bei 1 MB = 1024 KB). Praktisch: aufrunden und die Weiterleitung nutzen.

**Lösung 5.** Die Sperre entsteht auf dem Domänencontroller (Ereignis 4740). Der Client sieht nur Fehlversuche. Man muss daher auch die Domänencontroller überwachen.

```ps
# Loesung 6
$seit = (Get-Date).AddHours(-24)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$seit} -ErrorAction SilentlyContinue |
    ForEach-Object {
        $x = [xml]$_.ToXml(); $d = @{}
        $x.Event.EventData.Data | ForEach-Object { $d[$_.Name] = $_.'#text' }
        [pscustomobject]@{ Konto = $d['TargetUserName']; Quelle = $d['IpAddress'] }
    } |
    Group-Object Konto, Quelle | Sort-Object Count -Descending | Select-Object -First 5 Count, Name
```

```ps
# Loesung 7
Import-Module GroupPolicy
$gpo  = New-GPO -Name "AUDIT-PowerShell-Komplett"
$root = "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell"
Set-GPRegistryValue -Name $gpo.DisplayName -Key "$root\ScriptBlockLogging" -ValueName EnableScriptBlockLogging -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key "$root\ModuleLogging" -ValueName EnableModuleLogging -Type DWord -Value 1
foreach ($m in 'ActiveDirectory','GroupPolicy') {
    Set-GPRegistryValue -Name $gpo.DisplayName -Key "$root\ModuleLogging\ModuleNames" -ValueName $m -Type String -Value $m
}
```

**Lösung 8.** Beispiel: Erweiterte Überwachung mit Prozesserstellung (Erfolg), Befehlszeile, Anmelden (Erfolg und Fehler), Kontosperrung, Richtlinienänderung (Erfolg und Fehler), vertrauliche Rechteverwendung nur Fehler; Sicherheitsprotokoll mindestens 192 MB, Server größer; Skriptblockprotokollierung für alle, Modulprotokollierung für kritische Module; WEF mit zwei Sammlern, wenigen Abfragen, ausgehend 5985/5986 erlaubt; Lesezugriff nur für das Sicherheitsteam. Datenschutz: Zweckbindung (Sicherheit und Nachvollziehbarkeit), Verzeichnis der Verarbeitungstätigkeiten, Information der Mitarbeiter, Aufbewahrungsfrist, Abstimmung mit Betriebsrat und Datenschutzbeauftragten. Wichtig: Das ist keine Rechtsberatung; die rechtliche Bewertung ist mit den zuständigen Stellen zu klären.
