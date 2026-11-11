# Modul 02 - Defender und ASR

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Gruppenrichtlinien für Windows 11 – 100 Richtlinien im Detail“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Steckbriefe als Tabellen, Übungsaufgaben und Lösungen als fortlaufend nummerierte Absätze). **Nummerierung:** Die Überschriften der Richtlinien tragen hier die laufende Nummer 1 bis 100 aus der Modultabelle; die Verweise im Text („Abschnitt 43“) meinen diese Nummer. (Im LaTeX-Satz zählen die Überschriften je Modul neu, etwa 5.3.) **Die Beispiele (PowerShell, INF) wurden für dieses Repository nicht ausgeführt**; sie verändern Gruppenrichtlinien, Registry und Sicherheitseinstellungen und gehören nur in eine Testumgebung (Pilot-OU, Testdomäne). Übersicht zum Modul: [README](README.md).

**Dauer:** 10 Unterrichtsstunden (Annahme: 1 Stunde je Richtlinie)  
**Priorität:** überwiegend 1 (zwei Richtlinien mit Priorität 2)

| Nr. | Lerneinheit (Richtlinie)                            | Prio | Stunden |
|----:|:----------------------------------------------------|:----:|:-------:|
|  11 | Microsoft Defender Echtzeitschutz aktivieren        |  1   |    1    |
|  12 | Cloudbasierter Schutz aktivieren                    |  1   |    1    |
|  13 | Automatische Beispielübermittlung konfigurieren     |  2   |    1    |
|  14 | PUA-Schutz aktivieren                               |  1   |    1    |
|  15 | Manipulationsschutz organisatorisch erzwingen       |  1   |    1    |
|  16 | ASR Office Kindprozesse blockieren                  |  1   |    1    |
|  17 | ASR ausführbare Inhalte aus Mail/Webmail blockieren |  1   |    1    |
|  18 | ASR PSExec/WMI Prozessstarts auditieren             |  2   |    1    |
|  19 | Defender Signaturen häufig aktualisieren            |  1   |    1    |
|  20 | Defender Ausschlüsse nur zentral verwalten          |  1   |    1    |
|     | **Summe**                                           |      | **10**  |

**Worum es in diesem Modul geht.** Microsoft Defender Antivirus ist der in Windows 11 eingebaute Virenschutz. Er besteht aus mehreren Schichten: dem Echtzeitschutz, der jede Datei beim Zugriff prüft, dem Cloudschutz, der unbekannte Dateien in Sekunden gegen Microsofts Analysedienst abgleicht, den Schutzfunktionen gegen unerwünschte Programme und den *Attack Surface Reduction*-Regeln (ASR), die gezielt Verhaltensweisen blockieren, die Schadsoftware typischerweise nutzt. Gruppenrichtlinien steuern diese Schichten zentral. Die meisten Einstellungen finden sich unter Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Microsoft Defender Antivirus. Eine Vorbemerkung gilt für das ganze Modul: Laut Microsoft empfiehlt die Dokumentation für die Verwaltung der Defender-Einstellungen Microsoft Intune; Gruppenrichtlinien funktionieren weiterhin, sind aber nur eine von mehreren Möglichkeiten. Wo der Manipulationsschutz aktiv ist, werden Gruppenrichtlinienänderungen an geschützten Einstellungen ignoriert (Abschnitt 15).

## 11 Microsoft Defender Echtzeitschutz aktivieren

| **Feld**        | **Steckbrief**                                                                                     |
|:----------------|:---------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Defender Antivirus \> Echtzeitschutz |
| Einstellung     | Echtzeitschutz deaktivieren                                                                        |
| Empfehlung      | Deaktiviert                                                                                        |
| Ziel / Zweck    | Stellt kontinuierliche Malware-Erkennung sicher                                                    |
| Zielbereich     | Computer                                                                                           |
| Priorität       | 1                                                                                                  |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.        |

Der *Echtzeitschutz* (englisch *real-time protection*) ist die Kernfunktion eines Virenschutzes: Er prüft Dateien in dem Moment, in dem sie gelesen, geschrieben oder gestartet werden, und blockiert Schadsoftware, bevor sie ausgeführt wird. Ohne Echtzeitschutz erkennt Defender Schadsoftware erst beim nächsten geplanten Scan, also unter Umständen Stunden oder Tage zu spät. Die Richtlinie heißt missverständlich „Echtzeitschutz *deaktivieren*“ (englisch *Turn off real-time protection*). Wer sie auf „Deaktiviert“ setzt, schaltet also die Abschaltung aus, der Echtzeitschutz bleibt eingeschaltet. Diese doppelte Verneinung ist eine häufige Quelle für Fehler (siehe unten).

Zum Echtzeitschutz gehören weitere Teilfunktionen, die Microsoft in der Defender-Evaluierung per Gruppenrichtlinie als Satz empfiehlt: das Überwachen von ein- und ausgehender Datei- und Programmaktivität (bidirektionale Überwachung), die Verhaltensüberwachung (*Behavior Monitoring*), die Überwachung von Datei- und Programmaktivität auf dem Computer sowie das Prüfen aller heruntergeladenen Dateien und Anhänge. Alle diese Einstellungen liegen im selben Ordner „Echtzeitschutz“. In der Microsoft-Baseline wird zusätzlich „Scan all downloaded files and attachments“ mit dem Wert Aktiviert (Registrywert `DisableIOAVProtection` gleich 0) empfohlen.

> **Merke**
>
> „Echtzeitschutz deaktivieren = Deaktiviert“ bedeutet: Der Schutz ist *an*. Der Registrywert `DisableRealtimeMonitoring` muss auf 0 stehen. Ein Wert 1 schaltet den Echtzeitschutz aus.

Das folgende Beispiel legt eine GPO an, setzt die Echtzeitschutz-Werte und prüft sie auf einem Client mit Defender-eigenen Cmdlets. Es erzeugt eine neue GPO und verknüpft sie mit einer Pilot-OU (Platzhalter). Der Registrypfad entspricht der Gruppenrichtlinie; ich habe ihn aus meiner Kenntnis der ADMX-Dateien abgeleitet und nicht gesondert recherchiert, deshalb sollte er im Pilot mit dem Gruppenrichtlinien-Editor verglichen werden.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEF-Echtzeitschutz"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"

# 0 = Echtzeitschutz NICHT deaktivieren (also aktiv)
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DisableRealtimeMonitoring -Type DWord -Value 0
# Verhaltensueberwachung an
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DisableBehaviorMonitoring -Type DWord -Value 0
# Downloads und Anhaenge pruefen
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DisableIOAVProtection -Type DWord -Value 0

New-GPLink -Name $gpo.DisplayName -Target "OU=Pilot-Clients,DC=firma,DC=local"

# Pruefung am Client
Get-MpComputerStatus | Select-Object RealTimeProtectionEnabled, BehaviorMonitorEnabled, IoavProtectionEnabled
```

Die GPO bekommt drei Werte, die alle den Wert 0 haben, weil jeder Wert eine „Deaktivieren“-Einstellung ist und 0 bedeutet, dass nichts deaktiviert wird. `Get-MpComputerStatus` liest den tatsächlichen Zustand von Defender; die drei Eigenschaften müssen `True` sein. Der Unterschied zwischen Richtlinienwert und tatsächlichem Zustand ist wichtig: Ein Drittanbieter-Virenschutz kann Defender in den passiven Modus versetzen, dann steht der Echtzeitschutz trotz richtiger Richtlinie auf `False`.

**Typische Fehler.** Falsch: die Richtlinie „Echtzeitschutz deaktivieren“ auf „Aktiviert“ zu stellen, in der Absicht, den Echtzeitschutz zu aktivieren. Das schaltet ihn ab. Richtig: „Deaktiviert“ oder „Nicht konfiguriert“. Ein zweiter Fehler ist, bei Leistungsproblemen den Echtzeitschutz abzuschalten statt gezielte Ausschlüsse (Abschnitt 20) zu setzen. Ein dritter: bei parallel installierten Drittanbieterprodukten nicht zu prüfen, welches Produkt aktiv ist; zwei Echtzeitscanner gleichzeitig verlangsamen Rechner stark, deshalb schaltet Windows Defender dann in den passiven Modus.

> **Praxisbeispiel**
>
> Beispielszenario: Nach einem Vorfall zeigt die Untersuchung, dass auf einem Entwicklerrechner der Echtzeitschutz seit Monaten aus war, weil ein Build-Werkzeug langsam lief und ein Administrator ihn lokal abgeschaltet hatte. Mit der Richtlinie und dem Manipulationsschutz (Abschnitt 15) ist diese lokale Abschaltung nicht mehr möglich; für das Build-Werkzeug wird stattdessen ein gezielter Prozessausschluss gesetzt.

## 12 Cloudbasierter Schutz aktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Defender Antivirus \> MAPS    |
| Einstellung     | Microsoft MAPS beitreten                                                                    |
| Empfehlung      | Erweitertes MAPS                                                                            |
| Ziel / Zweck    | Verbessert Erkennung aktueller Bedrohungen                                                  |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Klassischer Virenschutz arbeitet mit Signaturen, die auf dem Rechner liegen und mehrmals täglich aktualisiert werden. Zwischen dem ersten Auftreten einer neuen Schadsoftware und der fertigen Signatur vergehen jedoch Stunden. Der *Cloudschutz* (cloud-delivered protection) schließt diese Lücke: Wenn Defender eine verdächtige oder unbekannte Datei sieht, sendet er Metadaten an den Cloud-Dienst, der innerhalb von Sekunden ein Urteil liefert. Microsoft beschreibt den Unterschied so, dass Standardupdates Stunden brauchen können, der Cloudschutz dieselbe Abdeckung aber in Sekunden bietet. Der Dienst heißt *Microsoft Active Protection Service*, kurz *MAPS*; die zugehörige Richtlinie „Join Microsoft MAPS“ (deutsch: Microsoft MAPS beitreten) legt fest, wie viele Informationen übermittelt werden.

Es gibt zwei Mitgliedschaftsstufen. Bei *Basic MAPS* sendet Defender Grundinformationen über erkannte Schadsoftware, zum Beispiel Herkunft (URL, Teilpfad), ergriffene Maßnahmen und deren Erfolg. Bei *Advanced MAPS*, der Lehrplanempfehlung, kommen laut Microsoft detaillierte Informationen hinzu: der vollständige Pfad der Software und Details darüber, wie sie das Gerät beeinflusst hat. Das verbessert die Erkennung, bedeutet aber, dass mehr Daten zu Microsoft gehen. Das ist datenschutzrelevant, weil Pfade Benutzernamen enthalten können. Die Entscheidung gehört daher dokumentiert und gegebenenfalls mit dem Datenschutzbeauftragten abgestimmt.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft ist der Cloudschutz standardmäßig aktiviert, und Microsoft empfiehlt, ihn aktiviert zu lassen. Zusätzlich gibt es die Einstellung „Select cloud protection level“ (MpEngine) mit den Stufen Default, High, High plus und Zero tolerance sowie die Funktion „Block at First Sight“, die unbekannte Dateien blockiert, bis die Cloud antwortet. Microsofts Evaluierungsanleitung für Gruppenrichtlinien verwendet Advanced MAPS, Block at First Sight aktiviert, das Senden aller Dateiproben, die Stufe „High blocking level“ und eine erweiterte Cloudprüfung von 50 Sekunden. Diese Werte sind für Tests gedacht; für den Betrieb muss man ihre Nebenwirkungen abwägen (zum Beispiel mehr Fehlalarme bei hohen Stufen).

Das folgende Beispiel zeigt die PowerShell-Variante, die Microsoft für den Einzelrechner dokumentiert, und die GPO-Variante mit Registrywerten für „Advanced MAPS“. Auf einem Einzelrechner ändert `Set-MpPreference` die lokale Einstellung; auf einem domänenverbundenen Rechner überschreibt eine Gruppenrichtlinie sie später wieder. Der Registrywert `SpynetReporting` mit 2 für Advanced und der Pfad `Spynet` entsprechen meiner Kenntnis der ADMX-Vorlage, der Schlüsselname `Spynet` für die Probenübermittlung ist in der Policy-CSP-Dokumentation belegt.

```ps
# Einzelrechner (Testgeraet): Cloudschutz Advanced, sichere Proben, Block at First Sight
Set-MpPreference -MAPSReporting Advanced -SubmitSamplesConsent SendSafeSamples -DisableBlockAtFirstSeen $false

# Kontrolle
Get-MpPreference | Select-Object MAPSReporting, SubmitSamplesConsent, DisableBlockAtFirstSeen, CloudBlockLevel

# Per GPO (Registry): Advanced MAPS = 2
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEF-Cloudschutz"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" `
    -ValueName SpynetReporting -Type DWord -Value 2
```

Der erste Befehl aktiviert die Cloudfunktion mit den Parametern, die Microsoft für Block at First Sight nennt: `-MAPSReporting Advanced`, `-SubmitSamplesConsent SendSafeSamples` und `-DisableBlockAtFirstSeen $false`. Die Kontrolle zeigt die Werte; laut Microsoft ist `MAPSReporting = 2` gleichbedeutend mit Advanced. Der GPO-Teil legt eine neue Richtlinie an und schreibt denselben Wert in die Policy-Registry. Für die Pilotierung verknüpft man die GPO danach mit `New-GPLink`.

**Typische Fehler.** Der Cloudschutz funktioniert nur, wenn der Client die Cloud erreichen kann. Falsch: den Proxy so zu konfigurieren, dass Defender-Verbindungen blockiert oder SSL-inspiziert werden; dann fällt der Schutz stillschweigend auf lokale Signaturen zurück. Richtig: die von Microsoft dokumentierten Defender-Endpunkte für Proxy und Firewall freigeben und die Verbindung mit `MpCmdRun.exe -ValidateMapsConnection` prüfen. Ein weiterer Fehler: Die Richtlinie „Configure local setting override for reporting to Microsoft MAPS“ unbeachtet zu lassen; ist sie aktiviert, können lokale Administratoren den Cloudschutz abweichend einstellen.

> **Praxisbeispiel**
>
> Beispielszenario: In einem Unternehmen mit strikter Firewall bleibt Defender trotz richtiger Richtlinie bei Standardschutz, weil der Proxy die Cloudadressen sperrt. Der Befehl `MpCmdRun.exe -ValidateMapsConnection` meldet den Fehler sofort, und die Netzwerkabteilung gibt die Adressen frei. Danach erkennt Defender neue Phishing-Anhänge in Sekunden statt erst mit dem nächsten Signaturupdate.

## 13 Automatische Beispielübermittlung konfigurieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Defender Antivirus \> MAPS    |
| Einstellung     | Dateibeispiele senden                                                                       |
| Empfehlung      | Sichere Beispiele automatisch senden                                                        |
| Ziel / Zweck    | Unterstützt schnelle Cloudanalyse                                                           |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Hält Defender eine Datei für verdächtig, kann er die Datei selbst, nicht nur Metadaten, zur Analyse an Microsoft senden. Diese *Probenübermittlung* (sample submission) ist die Voraussetzung dafür, dass die Cloud neue, noch unbekannte Schadsoftware analysieren kann. Die Richtlinie „Send file samples when further analysis is required“ regelt, wie das geschieht. Laut Policy-CSP-Dokumentation sind vier Werte möglich: immer nachfragen (0), sichere Proben automatisch senden (1, Standardwert), nie senden (2) und alle Proben automatisch senden (3). Mit „sicheren Proben“ sind Dateien gemeint, die voraussichtlich keine persönlichen Daten enthalten; bei Dateien, die persönliche Informationen enthalten könnten, wird der Benutzer um Bestätigung gebeten.

Der Lehrplan empfiehlt „sichere Beispiele automatisch senden“, also den Wert 1. Das ist ein Kompromiss zwischen Schutz und Datenschutz. Microsoft weist in der Dokumentation darauf hin, dass „Immer nachfragen“ und „Nie senden“ den Schutzzustand des Geräts verringern, und dass „Nie senden“ zusätzlich Block at First Sight deaktiviert. Dagegen nennt die Microsoft-Dokumentation zu Cloudschutz die Option „alle Proben automatisch senden“ als sicherer, weil Phishing häufig der erste Angriffsschritt ist. Für Unternehmen mit vertraulichen Dokumenten kann das Senden aller Proben aber ein Datenschutzproblem sein. Die Wahl ist deshalb eine organisatorische Entscheidung.

> **Merke**
>
> Vier Stufen: 0 nachfragen, 1 sichere Proben automatisch (Standard), 2 nie senden, 3 alle Proben automatisch. Stufe 2 schwächt den Schutz und schaltet Block at First Sight ab. Die Entscheidung zwischen 1 und 3 ist eine Datenschutzabwägung.

Das folgende Beispiel zeigt Einstellung und Prüfung. Es verwendet ausschließlich den in der Policy-CSP-Dokumentation genannten Registrypfad `Spynet` und den Wert `SubmitSamplesConsent`. Das Beispiel legt eine neue GPO an und verändert dadurch noch keinen Rechner, solange sie nicht verknüpft ist.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEF-Proben"

# 1 = sichere Proben automatisch senden, 3 = alle Proben automatisch senden
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" `
    -ValueName SubmitSamplesConsent -Type DWord -Value 1

# Am Client pruefen
(Get-MpPreference).SubmitSamplesConsent
```

Der Wert 1 entspricht „Send safe samples“. Ändert man ihn auf 3, werden alle Proben automatisch gesendet. Die Ausgabe von `Get-MpPreference` zeigt dieselbe Zahl.

**Typische Fehler.** Falsch ist die Annahme, „nie senden“ sei die datenschutzfreundliche Standardwahl ohne Nachteile. Richtig ist, die Folgen zu kennen: Block at First Sight wird abgeschaltet, und die Schutzwirkung sinkt. Ein anderer Fehler ist, die Einstellung ohne Abstimmung mit dem Betriebsrat oder Datenschutzbeauftragten zu setzen. Rechtliche Fragen (etwa DSGVO) sind hier nicht abschließend geklärt; dies ist keine Rechtsberatung, die Entscheidung gehört in die Zuständigkeit der Datenschutzverantwortlichen.

> **Praxisbeispiel**
>
> Beispielszenario: Eine Kanzlei lehnt das automatische Senden ab, weil Mandantendokumente betroffen sein könnten. Nach Abstimmung wird „sichere Proben“ aktiviert und ergänzend eine Ausschlussregel für den Ordner mit den Mandantendokumenten dokumentiert. So bleibt der Schutz bestehen, und die Kanzlei kann belegen, dass sie die Frage bewusst entschieden hat.

## 14 PUA-Schutz aktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Defender Antivirus            |
| Einstellung     | Erkennung potenziell unerwünschter Anwendungen konfigurieren                                |
| Empfehlung      | Aktiviert: Blockieren                                                                       |
| Ziel / Zweck    | Blockiert unerwünschte Software und Adware                                                  |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

*Potenziell unerwünschte Anwendungen* (englisch *potentially unwanted applications*, PUA) sind Programme, die nicht im strengen Sinn Schadsoftware sind, aber unerwünschte Wirkungen haben: Installer mit gebündelter Fremdsoftware, Programme mit Werbeeinblendung (Adware), manche Browser-Symbolleisten oder Werkzeuge, die Systemoptimierung versprechen und stattdessen nerven. Laut Microsoft zählen dazu Installer von Drittanbietern, Apps mit Anzeigeneinblendung und bestimmte Symbolleisten. Für Unternehmen sind PUAs ein Risiko, weil sie die Angriffsfläche vergrößern, Leistung kosten und Lizenz- und Supportprobleme verursachen.

Die Richtlinie „Configure detection for potentially unwanted applications“ hat zwei Betriebsarten: *Block* (blockieren) und *Audit Mode* (nur protokollieren). Die Microsoft-Baseline empfiehlt „Enabled: Block“; der Lehrplan folgt dem. Microsoft rät allerdings, zuerst den Audit-Modus zu verwenden, bei dem Treffer nur in das Ereignisprotokoll geschrieben werden. Das ist besonders wichtig für Firmen mit eigener Software, die zufällig als PUA eingestuft wird.

> **Ergänzung aus der Nachrecherche**
>
> Laut Policy-CSP gelten die Werte 0 (aus), 1 (Block) und 2 (Audit). Laut Microsoft-Dokumentation ist bei Geräten, die nicht in Defender for Endpoint eingebunden sind, die PUA-Voreinstellung vom Stand der Sicherheitsintelligenz abhängig: Ältere Versionen haben 0, ab Version 1.329.495.0 den Audit-Modus (2). PUA-Ereignisse erscheinen in der Windows-Ereignisanzeige, nicht in Configuration Manager oder Intune. Die Einstellung steht in den Administrativen Vorlagen ab Windows 10 Version 1809; fehlt sie im Editor, muss der zentrale Speicher (*Central Store*) für die ADMX-Dateien aktualisiert werden.

Die Umsetzung per PowerShell und per Registry zeigt das folgende Beispiel. Es beginnt im Audit-Modus, wertet die Ereignisse aus und schaltet dann auf Blockieren um. Es ändert nur den lokalen Rechner beziehungsweise legt eine GPO an. Ereignis-ID 1116 ist die allgemeine Erkennungsmeldung von Defender; PUA-Funde tragen den Präfix `PUA:` im Namen.

```ps
# 1) Testphase: nur protokollieren
Set-MpPreference -PUAProtection AuditMode

# 2) Funde der letzten 7 Tage ansehen
Get-WinEvent -FilterHashtable @{
    LogName='Microsoft-Windows-Windows Defender/Operational'
    Id=1116; StartTime=(Get-Date).AddDays(-7)
} | Where-Object { $_.Message -match "PUA:" } |
    Select-Object TimeCreated, Message -First 10

# 3) Nach der Pilotphase: blockieren
Set-MpPreference -PUAProtection Enabled

# GPO-Variante (Registry): 1 = Block, 2 = Audit
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEF-PUA"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" `
    -ValueName PUAProtection -Type DWord -Value 1
```

Schritt 1 setzt den Audit-Modus, Schritt 2 liest aus dem Defender-Protokoll die Ereignisse mit der ID 1116 der letzten sieben Tage und filtert auf Meldungen mit `PUA:`. Findet man dort eigene Software, kann man sie ausschließen oder beim Hersteller klären. Schritt 3 schaltet auf Blockieren. Die GPO-Variante schreibt den Wert 1 in den Schlüssel `Software\Policies\Microsoft\Windows Defender`, den auch die Policy-CSP-Dokumentation für diese Einstellung nennt.

**Typische Fehler.** Falsch: direkt blockieren, ohne den Audit-Modus zu nutzen; dann wird zum Beispiel ein Netzwerkscanner oder ein altes Fernwartungswerkzeug gelöscht, ohne dass jemand die Ursache sofort kennt. Richtig: zuerst Audit, dann Block. Ein weiterer Fehler ist, zu übersehen, dass der Browser eigene PUA-Funktionen hat: Microsoft Edge blockiert PUA-Downloads über SmartScreen, wenn die Option „Block potentially unwanted apps“ aktiv ist; sie ist laut Microsoft standardmäßig aus und lässt sich per Richtlinie `SmartScreenPuaEnabled` setzen (siehe Modul 6).

> **Praxisbeispiel**
>
> Beispielszenario: Ein Kundenserviceteam installiert regelmäßig ein „Optimierungswerkzeug“ mit mitgelieferter Browser-Erweiterung. Der Audit-Modus zeigt wöchentlich Dutzende Treffer. Nach der Umstellung auf Blockieren verschwindet das Problem, und die Helpdesk-Tickets wegen veränderter Startseiten gehen zurück.

## 15 Manipulationsschutz organisatorisch erzwingen

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Intune/Security Baseline oder Defender for Endpoint                                         |
| Einstellung     | Tamper Protection                                                                           |
| Empfehlung      | Aktiviert                                                                                   |
| Ziel / Zweck    | Verhindert Deaktivierung von Defender-Schutzfunktionen                                      |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Der *Manipulationsschutz* (englisch *tamper protection*) verhindert, dass wichtige Defender-Einstellungen von Schadsoftware, von Skripten oder von lokalen Administratoren verändert werden. Schadsoftware versucht oft als Erstes, den Virenschutz abzuschalten; mit Manipulationsschutz scheitert das. Dieser Abschnitt weicht von den übrigen Richtlinien des Moduls ab, und der Lehrplan sagt das mit der Pfadangabe „Intune/Security Baseline oder Defender for Endpoint“ selbst: Der Manipulationsschutz ist *keine* Einstellung, die man per klassischer Gruppenrichtlinie setzt. Die Microsoft-Dokumentation sagt ausdrücklich, dass man den Manipulationsschutz nicht per Gruppenrichtlinie ausschalten kann, und dass Gruppenrichtlinienänderungen an geschützten Einstellungen ignoriert werden. Verwaltet wird er in Intune (Endpoint-Security-Richtlinie Antivirus, Profil „Windows Security Experience“ mit der Einstellung „Tamper protection (device)“ auf „On“), im Microsoft-Defender-Portal oder über Configuration Manager im Tenant-Attach-Szenario.

Wichtig für den Betrieb: Der Schutz benötigt, dass Geräte bei Microsoft Defender for Endpoint (Plan 1 oder 2) angebunden sind. Nicht angebundene Geräte zeigen den Manipulationsschutz laut Microsoft als „Not applicable“. Wenn ein Intune-Richtlinienwert existiert, hat er Vorrang vor der Einstellung im Defender-Portal. Laut Dokumentation ist der Manipulationsschutz in neuen Bereitstellungen als Teil des integrierten Schutzes standardmäßig aktiv.

> **Ergänzung aus der Nachrecherche**
>
> Wenn Manipulationsschutz eine nötige Änderung blockiert, soll man laut Microsoft den *Fehlerbehebungsmodus* (troubleshooting mode) nutzen: Er erlaubt vorübergehend Änderungen, danach werden die konfigurierten Werte wiederhergestellt. Dauerhafte Änderungen erfolgen über die Richtlinie oder durch Ausnahme von Geräten in Intune. Blockierte Änderungen erzeugen in Defender das Ereignis 5013. Ausschlüsse (Abschnitt 20) sind nur unter besonderen Bedingungen manipulationsgeschützt: Plattformversion 4.18.2211.5 oder neuer, `DisableLocalAdminMerge` aktiv, Verwaltung nur durch Intune oder nur durch Configuration Manager und zentrale Verwaltung der Ausschlüsse.

Eine Gruppenrichtlinie kann den Manipulationsschutz also nicht setzen, aber man kann seinen Zustand prüfen und auswerten. Das folgende Beispiel liest den Zustand auf einem Client aus und sucht im Ereignisprotokoll nach blockierten Änderungsversuchen. Es ist rein lesend und für jede Umgebung unkritisch.

```ps
# Zustand pruefen
Get-MpComputerStatus | Select-Object IsTamperProtected, TamperProtectionSource, RealTimeProtectionEnabled

# Blockierte Aenderungsversuche (Ereignis 5013) der letzten 30 Tage
Get-WinEvent -FilterHashtable @{
    LogName='Microsoft-Windows-Windows Defender/Operational'
    Id=5013; StartTime=(Get-Date).AddDays(-30)
} -ErrorAction SilentlyContinue | Select-Object TimeCreated, Message -First 10
```

`IsTamperProtected` zeigt, ob der Schutz aktiv ist, und `TamperProtectionSource` (sofern vom Betriebssystem geliefert) zeigt die Quelle der Verwaltung. Der zweite Befehl sucht das Ereignis 5013; `-ErrorAction SilentlyContinue` verhindert eine Fehlermeldung, wenn kein Ereignis existiert. Die Eigenschaftsnamen kenne ich aus der Defender-Cmdlet-Praxis und sie sollten im Pilot geprüft werden.

**Typische Fehler.** Falsch ist, eine GPO zu erstellen, die „den Manipulationsschutz erzwingt“: Eine solche Einstellung gibt es nicht, und Gruppenrichtlinien, die geschützte Einstellungen ändern, laufen ins Leere, ohne dass es auffällt. Richtig ist, die Verwaltung auf Intune oder das Defender-Portal zu legen und die Gruppenrichtlinie für die übrigen Einstellungen beizubehalten. Ein zweiter Fehler: Konflikte zwischen Gruppenrichtlinien und Intune führen zu nicht vorhersehbaren Zuständen. Microsoft beschreibt dafür in der Vorschau die *Controlled Configuration*, die Intune zur alleinigen Quelle der Defender-Einstellungen macht.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Administrator wundert sich, dass eine GPO den Echtzeitschutz auf einigen Rechnern nicht abschalten kann, als er einen Test machen will. Die Ursache ist der Manipulationsschutz; für den Test nutzt er den Fehlerbehebungsmodus statt die Richtlinie zu ändern.

## 16 ASR Office Kindprozesse blockieren

| **Feld**        | **Steckbrief**                                                                                                                                   |
|:----------------|:-------------------------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Defender Antivirus \> Microsoft Defender Exploit Guard \> Attack Surface Reduction |
| Einstellung     | ASR-Regeln konfigurieren                                                                                                                         |
| Empfehlung      | Block: Office darf keine Kindprozesse erstellen                                                                                                  |
| Ziel / Zweck    | Reduziert Makro- und Office-basierte Angriffe                                                                                                    |
| Zielbereich     | Computer                                                                                                                                         |
| Priorität       | 1                                                                                                                                                |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                                      |

*Attack Surface Reduction*, auf Deutsch Reduzierung der Angriffsfläche, ist eine Familie von Regeln, die gezielt Verhalten blockieren, das Schadsoftware typischerweise zeigt, auch wenn die konkrete Datei unbekannt ist. Jede Regel hat eine feste Kennung (GUID) und drei wichtige Zustände: *Block* (blockieren, Wert 1), *Audit* (nur protokollieren, Wert 2) und *Warn* (Benutzer kann überspringen, Wert 6). Die Regel „Block all Office applications from creating child processes“ (GUID `d4f940ab-401b-4efc-aadc-ad5f3c50688a`) verhindert, dass Word, Excel, PowerPoint, OneNote und Access andere Programme starten. Die Begründung nennt Microsoft: Das Erzeugen schädlicher Kindprozesse ist eine übliche Malware-Strategie; Schadsoftware, die Office missbraucht, führt oft VBA-Makros und Exploit-Code aus, um weitere Nutzlasten zu laden und zu starten.

Dieselbe Dokumentation nennt die Kehrseite: Einige legitime Fachanwendungen erzeugen aus guten Gründen Kindprozesse, zum Beispiel eine Eingabeaufforderung oder PowerShell, um Registrywerte zu setzen. Deshalb ist der Weg über den Audit-Modus Pflicht. Außerdem gilt die Regel laut Microsoft nur, wenn Office in den Standardverzeichnissen unter `Program Files` installiert ist. Die Microsoft-Security-Baseline 24H2 für Intune setzt diese Regel auf „Block“.

> **Merke**
>
> Regelwerte: 0 deaktiviert, 1 Block, 2 Audit, 6 Warn. Immer zuerst Audit, Ereignisse auswerten, Ausnahmen dokumentieren, dann Block. Es gibt weitere Office-Regeln (zum Beispiel „Block Office applications from creating executable content“ und „Block Office applications from injecting code into other processes“), die in Baselines ebenfalls auf Block stehen.

In der Gruppenrichtlinie wird die Regel unter „Configure Attack Surface Reduction rules“ mit GUID und Wert eingetragen. Das folgende Beispiel legt dasselbe per PowerShell an. `Add-MpPreference` stammt aus der Microsoft-Dokumentation zur ASR-Demonstration; für die GPO-Variante lege ich die Registrywerte an, die der Editor erzeugt. Das Beispiel startet bewusst im Audit-Modus.

```ps
# Einzelrechner: Regel im AUDIT-Modus aktivieren
Add-MpPreference -AttackSurfaceReductionRules_Ids d4f940ab-401b-4efc-aadc-ad5f3c50688a `
                 -AttackSurfaceReductionRules_Actions AuditMode

# Gesetzte Regeln ansehen
$p = Get-MpPreference
$p.AttackSurfaceReductionRules_Ids
$p.AttackSurfaceReductionRules_Actions

# Treffer im Audit-Modus (Ereignis 1122) lesen
Get-WinEvent -FilterHashtable @{
    LogName='Microsoft-Windows-Windows Defender/Operational'; Id=1122
} -MaxEvents 20 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Message

# Spaeter auf Block umstellen
Set-MpPreference -AttackSurfaceReductionRules_Ids d4f940ab-401b-4efc-aadc-ad5f3c50688a `
                 -AttackSurfaceReductionRules_Actions Enabled
```

Der erste Befehl trägt die GUID der Regel mit der Aktion `AuditMode` ein. Die beiden Zeilen danach geben die konfigurierten GUIDs und die zugehörigen Aktionen aus. Die Microsoft-Dokumentation verwendet in ihrem Demonstrationsbeispiel den Wert `Enabled` für Block; `AuditMode` ist der Audit-Modus. Ereignis 1122 steht laut Defender-Dokumentation für einen Audit-Treffer und 1121 für einen Blockiervorgang; diese Zuordnung kenne ich aus der Praxis, sie ist nicht in den recherchierten Ausschnitten enthalten. Der letzte Befehl stellt auf Blockieren um. Beachten Sie, dass `Set-MpPreference` die Liste ersetzt, während `Add-MpPreference` anhängt; sonst gehen andere Regeln verloren.

**Typische Fehler.** Falsch: `Set-MpPreference` mit nur einer GUID verwenden und dadurch alle anderen gesetzten ASR-Regeln überschreiben. Richtig: `Add-MpPreference` für zusätzliche Regeln. Zweiter Fehler: Regeln ohne Auswertung des Audit-Modus aktivieren; Makro-Lösungen, die per Skript Berichte erzeugen, brechen dann unbemerkt. Dritter Fehler: Annahme, Kindprozesse seien immer verdächtig. Legitime Add-ins (zum Beispiel PDF-Erzeuger) starten Hilfsprogramme; hier hilft eine Ausnahme für den Pfad statt Abschalten der Regel.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Finanzteam nutzt eine Excel-Mappe, die über ein Kommandozeilenprogramm Daten abruft. Im Audit-Modus erscheint die Mappe sofort als Treffer. Statt die Regel abzuschalten, wird die Mappe durch eine signierte Anwendung ersetzt, und die Regel geht für alle auf Block.

## 17 ASR ausführbare Inhalte aus Mail/Webmail blockieren

| **Feld**        | **Steckbrief**                                                                                                                                   |
|:----------------|:-------------------------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Defender Antivirus \> Microsoft Defender Exploit Guard \> Attack Surface Reduction |
| Einstellung     | ASR-Regeln konfigurieren                                                                                                                         |
| Empfehlung      | Block: ausführbare Inhalte aus E-Mail/Webmail                                                                                                    |
| Ziel / Zweck    | Reduziert Erstinfektionsrisiko                                                                                                                   |
| Zielbereich     | Computer                                                                                                                                         |
| Priorität       | 1                                                                                                                                                |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                                      |

Phishing-Mails mit gefährlichem Anhang sind weiterhin einer der häufigsten Wege, auf dem Schadsoftware ein Unternehmen erreicht. Die ASR-Regel „Block executable content from email client and webmail“ (GUID `be9ba2d9-53ea-4cdc-84e5-9b1eeee46550`) hindert Dateien, die über Microsoft Outlook, Outlook.com und andere bekannte Webmail-Anbieter ankommen, daran, bestimmte Dateitypen zu verbreiten. Laut Microsoft sind das ausführbare Dateien (zum Beispiel `.exe`, `.dll`, `.scr`), Skriptdateien (zum Beispiel `.ps1`, `.vbs`, `.js`) und Archive (zum Beispiel `.zip`). Die Regel greift also an der Stelle, an der Dateien aus dem Postfach in das Dateisystem oder in Programme gelangen.

Wer die ASR-Regeln per Gruppenrichtlinie setzt, trägt in der Einstellung „Configure Attack Surface Reduction rules“ für jede Regel die GUID als Wertname und die Aktion als Wert ein. Microsoft zeigt das in der Evaluierungsanleitung für Gruppenrichtlinien: Die Regel steht dort mit dem Wert 1 (Block). Diese Einstellung befindet sich unter Microsoft Defender Exploit Guard \> Attack Surface Reduction. Die Wirkung hängt davon ab, dass der Echtzeitschutz (Abschnitt 11) aktiv ist, denn ASR ist von Microsoft Defender Antivirus abhängig.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft-Referenz erzeugen Warn- und Blockmeldungen nur bei bestimmten Cloudschutzstufen Benachrichtigungen (Benutzer-Pop-ups ab „High“, EDR-Alarme ab „High plus“). Die Regel ist in den Microsoft-Security-Baselines für Windows 11 (24H2) in der Liste der empfohlenen ASR-Regeln enthalten; Microsoft schlägt dort für die meisten Regeln „Block“ und nur für die PSExec-/WMI-Regel „Audit“ vor. Die Regelliste kann sich ändern; maßgeblich ist die aktuelle Referenz bei Microsoft.

Das folgende Beispiel erstellt eine GPO mit der Regel im Audit-Modus und zeigt, wie der Registryaufbau aussieht, den der Gruppenrichtlinien-Editor erzeugt. Die Pfade `Windows Defender Exploit Guard\ASR` und `Rules` kenne ich aus der Praxis der ADMX-Vorlage und sie sollten mit dem Editor verglichen werden.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEF-ASR-Mail"
$asr = "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR"

# Regeln aktivieren (Hauptschalter)
Set-GPRegistryValue -Name $gpo.DisplayName -Key $asr -ValueName ExploitGuard_ASR_Rules -Type DWord -Value 1

# Regel be9ba2d9-... : 2 = Audit, 1 = Block
Set-GPRegistryValue -Name $gpo.DisplayName -Key "$asr\Rules" `
    -ValueName "be9ba2d9-53ea-4cdc-84e5-9b1eeee46550" -Type String -Value "2"

# Am Client: wirksame Regeln
(Get-MpPreference).AttackSurfaceReductionRules_Ids
```

Die erste Registryzeile schaltet die Verarbeitung von ASR-Regeln ein, die zweite trägt die Regel mit Wert 2 (Audit) als Zeichenfolge ein. Der Hauptschalter und die Regelwerte sind zwei getrennte Dinge: Ohne den Hauptschalter bleiben die einzelnen Regeln wirkungslos. Die letzte Zeile zeigt am Client, welche GUIDs wirksam sind. Nach der Pilotphase wird der Wert auf `1` geändert.

**Typische Fehler.** Falsch: Regeln eintragen und den Hauptschalter vergessen oder Defender-Echtzeitschutz abschalten; die Regel bleibt dann unwirksam, ohne dass ein Fehler erscheint. Richtig: nach jeder Änderung `Get-MpPreference` auswerten. Zweiter Fehler: Archive pauschal zu blockieren, obwohl Geschäftspartner ZIP-Dateien mit Skripten schicken (zum Beispiel Software-Updates). Hier braucht es einen organisatorischen Weg, etwa Austausch über freigegebene Ablagen. Dritter Fehler: davon auszugehen, dass die Regel alle Mail-Clients abdeckt; sie gilt für Outlook und bekannte Webmail-Anbieter, nicht für jeden beliebigen Client.

> **Praxisbeispiel**
>
> Beispielszenario: Eine Personalabteilung erhält täglich Bewerbungen als ZIP-Dateien mit Lebenslauf-PDFs. Der Audit-Modus zeigt, dass einzelne ZIPs Skriptdateien enthalten; die Regel wird zu Block, und die Personalabteilung bekommt eine Alternative über ein Bewerberportal.

## 18 ASR PSExec/WMI Prozessstarts auditieren

| **Feld**        | **Steckbrief**                                                                                                                                   |
|:----------------|:-------------------------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Defender Antivirus \> Microsoft Defender Exploit Guard \> Attack Surface Reduction |
| Einstellung     | ASR-Regeln konfigurieren                                                                                                                         |
| Empfehlung      | Audit: Block process creations originating from PSExec and WMI                                                                                   |
| Ziel / Zweck    | Erhöht Sichtbarkeit für laterale Bewegung                                                                                                        |
| Zielbereich     | Computer                                                                                                                                         |
| Priorität       | 2                                                                                                                                                |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                                      |

Wenn ein Angreifer in einem Netzwerk ein erstes Gerät übernommen hat, bewegt er sich meist weiter zu anderen Rechnern. Diese *laterale Bewegung* nutzt gern legitime Administrationswerkzeuge: `PsExec` von Sysinternals startet Prozesse auf entfernten Rechnern, und WMI (*Windows Management Instrumentation*) ermöglicht dasselbe über die Verwaltungsschnittstelle. Die ASR-Regel „Block process creations originating from PSExec and WMI commands“ (GUID `d1e49aac-8f56-4280-b9ba-993a6d77406c`) blockiert Prozessstarts, die auf diesem Weg ausgelöst werden.

Der Lehrplan setzt die Regel auf „Audit“, nicht auf Block, und das ist begründet: Viele legitime Verwaltungswerkzeuge verwenden dieselben Mechanismen. Microsoft weist in der Evaluierungsanleitung ausdrücklich darauf hin, dass man bei Verwendung von Microsoft Configuration Manager oder anderer Verwaltungswerkzeuge, die WMI nutzen, den Wert 2 (Audit) setzen soll, weil der Configuration-Manager-Client stark auf WMI angewiesen ist. Die Microsoft-Security-Baseline 24H2 setzt diese Regel als einzige in der Aufzählung ebenfalls auf „Audit“. Auditieren heißt: Die Regel blockiert nichts, aber jeder Treffer wird im Ereignisprotokoll festgehalten. So gewinnt man Sichtbarkeit über Fernstarts, ohne den Betrieb zu stören.

> **Merke**
>
> Audit ist keine halbe Lösung, sondern ein bewusster Dauerzustand für Regeln, deren Block-Modus Verwaltungswerkzeuge brechen würde. Der Nutzen entsteht erst, wenn die Ereignisse regelmäßig ausgewertet oder an ein SIEM weitergeleitet werden (Modul 9, Abschnitt 90).

Das folgende Beispiel aktiviert die Regel im Audit-Modus und wertet die Treffer so aus, dass man erkennt, welche Programme betroffen sind. Es ändert nur die lokale Defender-Konfiguration und ist unkritisch. Die Ereignis-ID 1122 für Audit-Treffer stammt aus meiner Praxiskenntnis und ist nicht aus den recherchierten Ausschnitten belegt.

```ps
# Regel im Audit-Modus
Add-MpPreference -AttackSurfaceReductionRules_Ids d1e49aac-8f56-4280-b9ba-993a6d77406c `
                 -AttackSurfaceReductionRules_Actions AuditMode

# Auswertung: welche Programme loesen die Regel aus (haeufigste zuerst)
Get-WinEvent -FilterHashtable @{
    LogName='Microsoft-Windows-Windows Defender/Operational'; Id=1122
} -ErrorAction SilentlyContinue |
    ForEach-Object { ([xml]$_.ToXml()).Event.EventData.Data |
        Where-Object Name -eq 'Path' | Select-Object -ExpandProperty '#text' } |
    Group-Object | Sort-Object Count -Descending | Select-Object -First 10 Count, Name
```

Der erste Befehl trägt die Regel ein. Die Auswertung liest die Ereignisse, wandelt jedes in XML um, entnimmt das Feld `Path` (den betroffenen Prozess), gruppiert nach Pfad und listet die zehn häufigsten. So erkennt man in einer Woche, welche Software die Regel auslösen würde, und kann Ausnahmen für legitime Verwaltungswerkzeuge vorbereiten, bevor man später auf Block umstellt. Das Feld heißt je nach Regel unterschiedlich; im Pilot an einem Beispielereignis prüfen.

**Typische Fehler.** Falsch: die Regel sofort auf Block zu setzen, weil sie „in der Baseline“ steht. In Umgebungen mit Configuration Manager oder Fernwartungs-Software führt das zu Ausfällen bei Softwareverteilung und Inventarisierung. Richtig: Audit, Auswertung über mindestens vier Wochen, dann entscheiden. Zweiter Fehler: auditieren, aber die Ereignisse nie lesen. Ohne Auswertung ist die Regel wirkungslos. Dritter Fehler: die Regel als Ersatz für Netzwerksegmentierung und eingeschränkte Administratorrechte zu betrachten.

> **Praxisbeispiel**
>
> Beispielszenario: Im Audit-Protokoll taucht eines Nachts ein PsExec-Start von einem Buchhaltungsrechner auf, der nie administrative Aufgaben erledigt. Das SIEM löst einen Alarm aus, und ein Angriff wird bemerkt, bevor er sich ausbreitet. Ohne Audit wäre der Vorgang unsichtbar geblieben.

## 19 Defender Signaturen häufig aktualisieren

| **Feld**        | **Steckbrief**                                                                                                    |
|:----------------|:------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Defender Antivirus \> Sicherheitsintelligenzupdates |
| Einstellung     | Intervall für Sicherheitsintelligenzupdates                                                                       |
| Empfehlung      | Alle 4 Stunden oder nach Vorgabe                                                                                  |
| Ziel / Zweck    | Sichert aktuelle Erkennung                                                                                        |
| Zielbereich     | Computer                                                                                                          |
| Priorität       | 1                                                                                                                 |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                       |

Defender erkennt Schadsoftware anhand von *Sicherheitsintelligenz* (englisch *security intelligence*, früher „Virensignaturen“ oder „Definitionen“). Sie wird mehrmals täglich von Microsoft veröffentlicht. Die Richtlinie „Specify the interval to check for security intelligence updates“ legt fest, wie oft ein Client nach neuen Signaturen sucht. Laut Microsoft erhalten Geräte Defender-Updates typischerweise einmal täglich über Windows Update, und man kann die Frequenz durch eine explizite Einstellung erhöhen, wenn Configuration Manager, Gruppenrichtlinie oder Intune die Updates verwalten. Der Lehrplan nennt alle 4 Stunden.

Die Aktualisierungsquelle ist eine zweite Entscheidung, die zur Richtlinie gehört: Clients können Updates von Windows Update, von einem internen WSUS oder Configuration Manager, von einer Dateifreigabe oder von Microsoft Update beziehen („Define the order of sources for downloading security intelligence updates“). Ein kürzeres Intervall bringt nur etwas, wenn die gewählte Quelle selbst aktuell ist. Wenn der WSUS Signaturen nur einmal täglich genehmigt, nützt ein Vierstundenintervall nichts. Die Einstellung „Check for the latest security intelligence updates before running a scan“ stellt zusätzlich sicher, dass vor einem geplanten Scan die neuesten Signaturen geladen werden.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft-PowerShell-Dokumentation kann man das Intervall mit `Set-MpPreference -SignatureUpdateInterval` und die Aktualisierung vor dem Scan mit `-CheckForSignaturesBeforeRunningScan 1` steuern. Das Intervall wird in Stunden angegeben; der Wert 0 bedeutet nach meiner Kenntnis, dass kein Intervall verwendet wird (nur die Standardaktualisierung). Der gesetzte Wert ist ein Mindestwunsch, kein Garant: Wenn der Rechner nicht erreichbar oder aus ist, wird nicht aktualisiert.

Das folgende Beispiel zeigt Einstellung und Kontrolle. Es verändert die lokale Defender-Konfiguration, hat keine Nebenwirkungen auf Dateien und ist für einen Pilotrechner unkritisch. Der Befehl `Update-MpSignature` stößt ein sofortiges Update an, `Get-MpComputerStatus` zeigt Alter und Version der Signaturen.

```ps
# Intervall 4 Stunden, vor Scan aktualisieren
Set-MpPreference -SignatureUpdateInterval 4 -CheckForSignaturesBeforeRunningScan 1

# Jetzt aktualisieren und Stand pruefen
Update-MpSignature
Get-MpComputerStatus |
    Select-Object AntivirusSignatureVersion, AntivirusSignatureLastUpdated, AntivirusSignatureAge

# GPO-Variante (Registry)
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEF-Signaturen"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" `
    -ValueName SignatureUpdateInterval -Type DWord -Value 4
```

Die erste Zeile setzt das Intervall auf vier Stunden. `Update-MpSignature` lädt sofort Signaturen, und `Get-MpComputerStatus` zeigt Version, Zeitpunkt der letzten Aktualisierung und das Alter in Tagen. In der Praxis überwacht man das Alter zentral: Rechner mit einem Signaturalter über zwei Tage sind auffällig. Die GPO-Variante schreibt den Wert in den Schlüssel `Signature Updates`; Pfad und Wertname entsprechen der ADMX-Vorlage nach meiner Kenntnis.

**Typische Fehler.** Falsch: das Intervall senken, aber WSUS oder die Dateifreigabe als einzige Quelle nicht aktualisieren; die Clients fragen häufiger, bekommen aber nichts Neues. Richtig: Quelle und Intervall gemeinsam planen und im Pilot das tatsächliche Signaturalter messen. Zweiter Fehler: ein zu kurzes Intervall (zum Beispiel stündlich) auf tausenden Clients hinter einer schmalen Leitung ohne Delivery Optimization; das erzeugt Netzlast. Dritter Fehler: nicht bedacht, dass Notebooks im Homeoffice per VPN oder ganz ohne Firmennetz die interne Quelle nicht erreichen; hier hilft die Rückfalloption Microsoft Update.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Monitoring-Skript wertet täglich `AntivirusSignatureAge` aus und meldet Rechner, die älter als zwei Tage sind. Meist sind es Geräte, die seit Wochen nicht im Büro waren und keinen Rückfallweg zu Microsoft Update haben. Die Richtlinie wird um eine Rückfallquelle ergänzt.

## 20 Defender Ausschlüsse nur zentral verwalten

| **Feld**        | **Steckbrief**                                                                                  |
|:----------------|:------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Defender Antivirus \> Ausschlüsse |
| Einstellung     | Lokale Ausschlüsse zusammenführen                                                               |
| Empfehlung      | Deaktiviert                                                                                     |
| Ziel / Zweck    | Verhindert lokale Umgehung durch Benutzer/Admins                                                |
| Zielbereich     | Computer                                                                                        |
| Priorität       | 1                                                                                               |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.     |

Ein *Ausschluss* (englisch *exclusion*) nimmt einen Ordner, eine Datei, eine Dateiendung oder einen Prozess vom Scan aus. Ausschlüsse sind manchmal nötig, zum Beispiel für Datenbankdateien oder Build-Verzeichnisse, die durch ständiges Scannen verlangsamt würden. Sie sind aber auch ein beliebter Weg für Angreifer: Wer einen Ordner ausschließen kann, legt dort seine Schadsoftware ab, ohne erkannt zu werden. Entscheidend ist deshalb, *wer* Ausschlüsse setzen darf. Standardmäßig gilt: Defender fasst die zentral per Richtlinie gesetzten Ausschlüsse und die lokal vom Administrator gesetzten Ausschlüsse zu einer gemeinsamen Liste zusammen (*Merge*). Dadurch kann ein lokaler Administrator, oder eine Schadsoftware mit Administratorrechten, die zentrale Absicherung umgehen.

Die Lehrplanempfehlung „Lokale Ausschlüsse zusammenführen = Deaktiviert“ entspricht der Einstellung „Configure local administrator merge behavior for lists“ beziehungsweise dem Konfigurationsparameter `DisableLocalAdminMerge`. Ist er aktiv, werden lokale Listen *nicht* mit den zentralen zusammengeführt; es gelten nur die zentral verwalteten Ausschlüsse. Genau diese Einstellung nennt Microsoft als eine der Voraussetzungen, damit Ausschlüsse manipulationsgeschützt sind.

> **Ergänzung aus der Nachrecherche**
>
> Voraussetzungen für den Schutz der Ausschlüsse durch den Manipulationsschutz laut Microsoft: Plattformversion 4.18.2211.5 (November 2022) oder neuer; `DisableLocalAdminMerge` aktiviert; Geräte werden nur durch Intune oder nur durch Configuration Manager verwaltet, und der Defender-for-Endpoint-Sensor ist aktiv; die Ausschlüsse werden in Intune oder Configuration Manager verwaltet. Ob der Schutz tatsächlich aktiv ist, lässt sich nach Microsoft über den Registrywert `TPExclusions` prüfen.

Das folgende Beispiel zeigt die Zusammenhänge: Es liest vorhandene Ausschlüsse eines Clients, um versteckte lokale Einträge zu finden, und legt per GPO die Einstellung für das Nicht-Zusammenführen an. Das Lesen ist unkritisch. Die Registrypfade sind nach meiner Kenntnis der ADMX-Vorlage angegeben und sollten im Pilot mit dem Editor verglichen werden.

```ps
# Vorhandene Ausschluesse anzeigen
$p = Get-MpPreference
"Pfade:     " + ($p.ExclusionPath -join "; ")
"Endungen:  " + ($p.ExclusionExtension -join "; ")
"Prozesse:  " + ($p.ExclusionProcess -join "; ")

# GPO: lokale Listen nicht mit zentralen zusammenfuehren
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEF-Ausschluesse-zentral"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" `
    -ValueName DisableLocalAdminMerge -Type DWord -Value 1
```

Die ersten Zeilen geben alle Ausschlüsse aus, die auf dem Rechner wirksam sind. Auf einem Rechner mit Manipulationsschutz und zentraler Verwaltung sind sie dort teilweise ausgeblendet; ein leeres Ergebnis ist also kein Beweis, dass es keine gibt. Der Registrywert `DisableLocalAdminMerge = 1` aktiviert das Nicht-Zusammenführen. Aktuell wirksame Ausschlusslisten sollte man zusätzlich im Defender-Portal oder mit Inventarwerkzeugen prüfen.

**Typische Fehler.** Falsch: Ausschlüsse großzügig mit Platzhaltern setzen (zum Beispiel ganze Laufwerke oder `C:\Users`), weil dann „nichts mehr stört“. Richtig: möglichst enge Ausschlüsse nach Herstellerempfehlung, jeder mit Eigentümer, Begründung und Ablaufdatum dokumentiert. Zweiter Fehler: `DisableLocalAdminMerge` zu aktivieren, ohne vorhandene lokale Ausschlüsse inventarisiert zu haben; Anwendungen, die davon abhängen, verlangsamen sich schlagartig oder erzeugen Fehlalarme. Dritter Fehler: davon auszugehen, dass Gruppenrichtlinie und Intune parallel dieselben Ausschlüsse verwalten können; Microsoft verlangt für den Schutz die Verwaltung durch nur ein Werkzeug.

> **Praxisbeispiel**
>
> Beispielszenario: Bei einem Vorfall stellt sich heraus, dass die Schadsoftware ein Verzeichnis als Ausschluss eingetragen hatte, bevor sie ihre Dateien ablegte. Seit `DisableLocalAdminMerge` aktiv ist, wirkt dieser Eintrag nicht mehr. Im Quartalsreview werden alle zentralen Ausschlüsse mit Eigentümer und Begründung geprüft.

## Übungsaufgaben zu Modul 02

**Aufgabe 1.** **(leicht)** Die Richtlinie heißt „Echtzeitschutz deaktivieren“. Welcher Wert sorgt dafür, dass der Schutz aktiv ist, und welcher Registrywert gehört dazu?

**Aufgabe 2.** **(leicht)** Nennen Sie die Unterschiede zwischen Basic MAPS und Advanced MAPS.

**Aufgabe 3.** **(leicht)** Welche vier Werte kennt die Probenübermittlung, und welcher gilt standardmäßig?

**Aufgabe 4.** **(mittel)** Warum kann der Manipulationsschutz nicht per klassischer Gruppenrichtlinie erzwungen werden? Wo wird er stattdessen verwaltet?

**Aufgabe 5.** **(mittel)** Welche drei Zustände einer ASR-Regel gibt es, welche Zahlenwerte gehören dazu, und warum beginnt man mit dem Audit-Modus?

**Aufgabe 6.** **(praktisch)** Schreiben Sie ein PowerShell-Skript, das auf einem Testrechner PUA-Schutz im Audit-Modus aktiviert, nach einer Woche die PUA-Funde (Ereignis 1116) listet und danach auf Blockieren umstellt.

**Aufgabe 7.** **(praktisch)** Schreiben Sie ein Skript, das drei ASR-Regeln (Office-Kindprozesse, ausführbare Inhalte aus E-Mail, PSExec/WMI) hinzufügt, ohne bestehende Regeln zu überschreiben, die ersten beiden im Block-, die dritte im Audit-Modus.

**Aufgabe 8.** **(schwer)** Entwerfen Sie für ein Unternehmen mit 1 500 Clients, Configuration Manager und Intune einen Plan für Ausschlüsse: Wer darf sie setzen, wie werden sie dokumentiert, wie wird `DisableLocalAdminMerge` ausgerollt, und wie prüfen Sie, dass keine lokalen Altausschlüsse die Anwendungen beim Umstellen brechen?

## Lösungen zu Modul 02

**Lösung 1.** „Deaktiviert“ (oder nicht konfiguriert) lässt den Schutz an. Der Registrywert `DisableRealtimeMonitoring` muss 0 sein. Der Wert 1 würde den Echtzeitschutz abschalten. Der Doppelnegativ ist die häufigste Fehlerquelle.

**Lösung 2.** Basic sendet Grundinformationen über erkannte Schadsoftware (Herkunft, ergriffene Maßnahmen, Erfolg). Advanced sendet zusätzlich detaillierte Informationen, darunter den vollständigen Pfad der Software und wie sie das Gerät beeinflusst hat. Advanced verbessert die Erkennung, überträgt aber mehr Daten und ist datenschutzrelevant.

**Lösung 3.** 0 immer nachfragen, 1 sichere Proben automatisch senden (Standard), 2 nie senden, 3 alle Proben automatisch senden. Wert 2 senkt den Schutz und deaktiviert Block at First Sight.

**Lösung 4.** Der Manipulationsschutz soll verhindern, dass lokale Administratoren und Schadsoftware Defender-Einstellungen ändern; eine ändernde Gruppenrichtlinie wäre dasselbe Einfallstor. Deshalb ignoriert Defender Gruppenrichtlinienänderungen an geschützten Einstellungen. Er wird in Intune (Endpoint Security, Antivirus, Windows Security Experience), im Defender-Portal oder per Tenant Attach über Configuration Manager verwaltet und setzt die Anbindung an Defender for Endpoint voraus.

**Lösung 5.** Block (1), Audit (2), Warn (6), außerdem 0 für deaktiviert. Audit protokolliert nur und zeigt, welche legitime Software betroffen wäre; so entstehen Ausnahmen, bevor Anwender blockiert werden. Besonders wichtig bei Office-Kindprozessen und PSExec/WMI.

**Lösung 6.** Ablauf: `Set-MpPreference -PUAProtection AuditMode`; Auswertung mit `Get-WinEvent` auf die ID 1116 im Log `Microsoft-Windows-Windows Defender/Operational`, gefiltert auf `PUA:`; zuletzt `Set-MpPreference -PUAProtection Enabled`. Vorlage: Beispiel in Abschnitt 14.

**Lösung 7.** Die beiden Regeln werden zusammen als Block, die dritte separat im Auditmodus gesetzt (Code unten). Wichtig: `Add-` statt `Set-`, damit bestehende Regeln bleiben; die Reihenfolge von IDs und Aktionen muss übereinstimmen.

```ps
# Loesung 7
Add-MpPreference `
    -AttackSurfaceReductionRules_Ids d4f940ab-401b-4efc-aadc-ad5f3c50688a,be9ba2d9-53ea-4cdc-84e5-9b1eeee46550 `
    -AttackSurfaceReductionRules_Actions Enabled,Enabled
Add-MpPreference `
    -AttackSurfaceReductionRules_Ids d1e49aac-8f56-4280-b9ba-993a6d77406c `
    -AttackSurfaceReductionRules_Actions AuditMode
```

**Lösung 8.** Beispiellösung: Ausschlüsse nur über ein Antragsverfahren des Sicherheitsteams mit Eigentümer, Begründung und Ablaufdatum; Verwaltung ausschließlich im führenden Werkzeug (Intune oder Configuration Manager, nicht beide); vor dem Aktivieren von `DisableLocalAdminMerge` Inventur der Altausschlüsse mit `Get-MpPreference` (per Skript oder Inventarwerkzeug), Überführung berechtigter Einträge in die zentrale Richtlinie; Pilot mit einer Abteilung, Beobachtung der Leistungs- und Fehlalarm-Tickets; erst danach flächendeckend. Prüfung: Plattformversion, `TPExclusions`, Stichproben auf Clients.
