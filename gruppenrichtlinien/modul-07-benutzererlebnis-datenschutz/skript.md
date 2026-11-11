# Modul 07 - Benutzererlebnis und Datenschutz

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Gruppenrichtlinien für Windows 11 – 100 Richtlinien im Detail“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Steckbriefe als Tabellen, Übungsaufgaben und Lösungen als fortlaufend nummerierte Absätze). **Nummerierung:** Die Überschriften der Richtlinien tragen hier die laufende Nummer 1 bis 100 aus der Modultabelle; die Verweise im Text („Abschnitt 43“) meinen diese Nummer. (Im LaTeX-Satz zählen die Überschriften je Modul neu, etwa 5.3.) **Die Beispiele (PowerShell, INF) wurden für dieses Repository nicht ausgeführt**; sie verändern Gruppenrichtlinien, Registry und Sicherheitseinstellungen und gehören nur in eine Testumgebung (Pilot-OU, Testdomäne). Übersicht zum Modul: [README](README.md).

**Dauer:** 10 Unterrichtsstunden (Annahme: 1 Stunde je Richtlinie)  
**Priorität:** 1 bis 3 (zwei Richtlinien mit Priorität 1, vier mit Priorität 2, vier mit Priorität 3)

| Nr. | Lerneinheit (Richtlinie)                | Prio | Stunden |
|----:|:----------------------------------------|:----:|:-------:|
|  61 | Diagnosedaten minimieren                |  1   |    1    |
|  62 | Consumer Experiences deaktivieren       |  2   |    1    |
|  63 | Werbe-ID deaktivieren                   |  2   |    1    |
|  64 | Feedbackbenachrichtigungen deaktivieren |  3   |    1    |
|  65 | Clipboard History steuern               |  2   |    1    |
|  66 | Cloud Clipboard deaktivieren            |  1   |    1    |
|  67 | Widgets steuern                         |  3   |    1    |
|  68 | Startmenü Pins konfigurieren            |  3   |    1    |
|  69 | Taskleistenanpassungen steuern          |  3   |    1    |
|  70 | Sperrbildschirm Apps deaktivieren       |  2   |    1    |
|     | **Summe**                               |      | **10**  |

**Worum es in diesem Modul geht.** Windows 11 ist für Privatpersonen entworfen und für Unternehmen anpassbar. Es sendet Diagnosedaten, blendet Empfehlungen und Werbung ein, synchronisiert die Zwischenablage über Geräte hinweg und zeigt Nachrichten in Widgets. In einem Unternehmen ist vieles davon unerwünscht: aus Datenschutzgründen, aus Sicherheitsgründen oder einfach, weil Mitarbeiter arbeiten sollen und nicht von Vorschlägen abgelenkt werden. Dieses Modul zeigt die Richtlinien, mit denen man das steuert (Abschnitte 61 bis 66, 70), und die Richtlinien, mit denen man die Oberfläche für alle Benutzer gleich gestaltet (67 bis 69). Beachten Sie, dass Datenschutz ein Rechtsgebiet ist: Welche Einstellung rechtlich zulässig oder geboten ist, hängt von Ihrer Organisation, Ihrer Datenschutzfolgenabschätzung und gegebenenfalls einer Betriebsvereinbarung ab. Das Modul liefert die Technik, aber keine Rechtsberatung.

## 61 Diagnosedaten minimieren

| **Feld**        | **Steckbrief**                                                                                              |
|:----------------|:------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Datensammlung und Vorabversionen |
| Einstellung     | Diagnosedaten zulassen                                                                                      |
| Empfehlung      | Erforderliche Diagnosedaten                                                                                 |
| Ziel / Zweck    | Minimiert Telemetrie nach Datenschutzvorgabe                                                                |
| Zielbereich     | Computer                                                                                                    |
| Priorität       | 1                                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                 |

Windows sendet Diagnosedaten an Microsoft: Informationen zu Gerät, Betriebssystem, Abstürzen und Nutzung, die helfen sollen, Fehler zu finden und Windows sicher und aktuell zu halten. Die Menge steuert man mit der Richtlinie „Allow diagnostic data“ (auf Windows 10 Version 1809 und älter „Allow telemetry“). Laut Microsoft gibt es vier Werte: 0 (Diagnosedaten aus), 1 (erforderlich, früher „Basic“), 2 (erweitert) und 3 (optional, früher „Full“). Die Stufe „erweitert“ gibt es unter Windows 11 nicht mehr; sie wurde durch Richtlinien ersetzt, die die Menge optionaler Daten steuern. Der Lehrplan empfiehlt „erforderliche Diagnosedaten“, also den Wert 1.

Die Stufe 0 (aus) ist laut Microsoft nur in den Editionen Enterprise, Education und Server unterstützt und wird nicht empfohlen. Die Stufe „erforderlich“ ist, so die Dokumentation, das Minimum, das nötig ist, damit Windows sicher, aktuell und funktionsfähig bleibt; sie schaltet in den Einstellungen die Option „optionale Diagnosedaten“ ab. Wichtig: Sind sowohl die Computer- als auch die Benutzerrichtlinie gesetzt, gilt die restriktivere. Die Richtlinie schränkt zudem ein, dass der Benutzer in den Einstellungen die Menge erhöht; ohne die Richtlinie „Configure diagnostic data opt-in settings user interface“ kann er sie aber weiter auf einen *restriktiveren* Wert senken.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation weist darauf hin, dass diese Einstellungen nur für Komponenten gelten, die zu Windows gehören. Andere Microsoft-Anwendungen (zum Beispiel Microsoft 365 Apps) und Drittanwendungen erheben Daten nach eigenen Einstellungen. Zusätzlich gibt es zwei Richtlinien für Windows 11: „Limit dump collection“ (nur Kernel-Minidumps und Triage-Dumps senden) und „Limit diagnostic log collection“. Für Organisationen mit Entra-Mandant im EWR gilt laut Microsoft die Konfiguration der Windows-Diagnosedaten als Auftragsverarbeitung; für andere Regionen ist die Anmeldung bei Diensten nötig, die auf Diagnosedaten beruhen (zum Beispiel Windows-Update-Berichte oder Autopatch). Die datenschutzrechtliche Würdigung ist keine Rechtsberatung und Sache Ihrer Verantwortlichen.

Ein Zielkonflikt verdient Erwähnung: Wer Diagnosedaten auf „erforderlich“ stellt oder ganz abschaltet, nimmt sich unter Umständen Funktionen. So melden Windows-Update-Berichte oder Autopatch ohne Diagnosedaten nichts, und für Insider-Builds sind optionale Diagnosedaten Voraussetzung. Der Registrywert `AllowTelemetry` liegt, wenn er per Richtlinie gesetzt wird, unter `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection`; er hat Vorrang gegenüber dem Wert, den die Oberfläche unter `...\CurrentVersion\Policies\DataCollection` anlegt.

Das Beispiel setzt die Stufe 1 und sperrt zusätzlich die Oberfläche, damit der Benutzer nicht wieder erhöhen kann. Der Wert `AllowTelemetry` entspricht der Microsoft-Dokumentation; die Werte `LimitDiagnosticLogCollection`, `LimitDumpCollection` und `DisableTelemetryOptInSettingsUx` stammen aus meiner Kenntnis der ADMX-Vorlage und sind im Pilot zu prüfen.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "PRIV-Diagnosedaten"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName AllowTelemetry                 -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DisableTelemetryOptInSettingsUx -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName LimitDumpCollection             -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName LimitDiagnosticLogCollection    -Type DWord -Value 1

# Am Client: welcher Wert gilt tatsaechlich? (Policy hat Vorrang vor dem UI-Wert)
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ErrorAction SilentlyContinue |
    Select-Object AllowTelemetry
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -ErrorAction SilentlyContinue |
    Select-Object AllowTelemetry
```

Die ersten vier Werte setzen die Stufe „erforderlich“, blenden die Auswahl in den Einstellungen aus und begrenzen Dumps und Logs. Die beiden Abfragen zeigen den Policy-Wert und den Oberflächen-Wert. Wichtig ist der erste: Fehlt er, ist keine Richtlinie wirksam.

**Typische Fehler.** Falsch: Wert 0 (aus) auf Pro-Geräten setzen zu wollen. Laut Microsoft wird 0 nur auf Enterprise, Education und Server unterstützt, und auf anderen Editionen wird er wie die niedrigste unterstützte Stufe behandelt (nach meiner Kenntnis; im Pilot zu prüfen). Richtig: die Stufe 1 und die Editionen prüfen. Zweiter Fehler: Diagnosedaten abzuschalten und dann Berichte (Windows-Update-Berichte, Autopatch) zu erwarten. Dritter Fehler: anzunehmen, damit sei „alles Tracking“ abgestellt; Diagnosedaten sind nur ein Teil der Verbindungen von Windows zu Microsoft-Diensten. Für die übrigen verweist Microsoft auf die Seite „Manage connections from Windows operating system components to Microsoft services“.

> **Praxisbeispiel**
>
> Beispielszenario: Der Datenschutzbeauftragte verlangt eine Begründung für die Übermittlung von Diagnosedaten. Die IT stellt auf „erforderlich“, dokumentiert, warum Windows-Update-Berichte trotzdem funktionieren, und verwendet den Diagnosedaten-Viewer, um stichprobenartig zu zeigen, was gesendet wird.

## 62 Consumer Experiences deaktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Cloudinhalt      |
| Einstellung     | Microsoft Consumer Experiences deaktivieren                                                 |
| Empfehlung      | Aktiviert                                                                                   |
| Ziel / Zweck    | Reduziert unerwünschte Consumer-Inhalte                                                     |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Unter dem Begriff *Microsoft Consumer Experiences* fasst Windows Funktionen zusammen, die auf Privatnutzer zielen: Vorschläge im Startmenü, Benachrichtigungen zu Abonnements, vorinstallierte Spiele und Apps nach der ersten Anmeldung („Post-OOBE“) und Kacheln, die auf Angebote verweisen. In einem Unternehmen sind solche Inhalte störend, bringen Lizenz- und Sicherheitsfragen mit sich und lenken ab. Die Richtlinie „Turn off Microsoft consumer experiences“ schaltet sie ab. Wieder der Hinweis auf die Doppelverneinung: Die Richtlinie *deaktiviert* die Erfahrungen, „Aktiviert“ bedeutet also, dass sie abgeschaltet sind.

Ein entscheidender Punkt, den der Lehrplan nicht nennt, steht in der Microsoft-Dokumentation zur Richtlinie (Policy CSP Experience, `AllowWindowsConsumerFeatures`): Die Einstellung wirkt laut Tabelle nur auf den Editionen *Enterprise*, *Education* und IoT Enterprise, nicht auf Pro. Sie gilt auf Geräteebene (ab Windows 10 Version 1803 nicht mehr benutzerbezogen). Der Registrywert heißt `DisableWindowsConsumerFeatures` im Schlüssel `Software\Policies\Microsoft\Windows\CloudContent`. Eine zweite Richtlinie derselben Gruppe, „Turn off cloud consumer account state content“ (`DisableConsumerAccountStateContent`), schaltet Inhalte ab, die vom Zustand eines Verbraucherkontos abhängen; sie ist laut Microsoft ab Windows 11 21H2 verfügbar, ebenfalls nicht für Pro.

> **Merke**
>
> Die Wirkung hängt von der Edition ab. Auf Windows 11 Pro ignoriert Windows die Consumer-Experiences-Richtlinie. Wer Pro einsetzt und Empfehlungen im Startmenü loswerden will, nutzt stattdessen die gesonderten Startmenü-Richtlinien (Abschnitt 68) und die Spotlight-Richtlinien.

Das Beispiel setzt beide Richtlinien. Die Registrynamen entsprechen den Zuordnungen in der Policy-CSP-Dokumentation. Am Client wird zusätzlich ausgegeben, welche Edition vorliegt, damit man erkennt, ob die Einstellung dort überhaupt greift.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "PRIV-ConsumerExperiences-aus"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DisableWindowsConsumerFeatures      -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DisableConsumerAccountStateContent  -Type DWord -Value 1

# Am Client: Edition pruefen (Enterprise/Education: wirksam; Pro: ignoriert)
(Get-CimInstance Win32_OperatingSystem).Caption
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
```

Die beiden Registrywerte schalten die Funktionen ab. Die Abfrage der Edition (`EditionID`, zum Beispiel `Enterprise` oder `Professional`) ist die Voraussetzung, um das Ergebnis zu verstehen: Auf `Professional` bleibt die Wirkung aus.

**Typische Fehler.** Falsch: die Richtlinie auf Pro-Geräten zu setzen und sich zu wundern, dass nichts passiert. Richtig: die Editionsmatrix prüfen und für Pro andere Maßnahmen wählen. Zweiter Fehler: die Richtlinie auf „Deaktiviert“ zu stellen in der Annahme, das schalte die Inhalte ab. Dritter Fehler: die Maßnahme erst nach der ersten Anmeldung zu verteilen; die Post-OOBE-Installationen laufen dann schon. Richtig: Richtlinie vor dem ersten Benutzer-Logon, zum Beispiel im Image oder per Autopilot.

> **Praxisbeispiel**
>
> Beispielszenario: Nach der Neuinstallation eines Rechners erscheinen Spiele und Streaming-Apps im Startmenü. Mit der Richtlinie im Image tauchen sie auf Enterprise-Rechnern gar nicht mehr auf; auf den wenigen Pro-Geräten räumt ein Skript beim ersten Start auf.

## 63 Werbe-ID deaktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> Benutzerprofile               |
| Einstellung     | Werbe-ID deaktivieren                                                                       |
| Empfehlung      | Aktiviert                                                                                   |
| Ziel / Zweck    | Reduziert Tracking                                                                          |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Die *Werbe-ID* (englisch *advertising ID*) ist eine pro Benutzer erzeugte Kennung, mit der Apps Werbung personalisieren und Nutzungsverhalten über Apps hinweg wiedererkennen können. Sie ist ein klassisches Tracking-Instrument. Die Richtlinie „Turn off the advertising ID“ im Bereich Benutzerprofile (also unter „System \> Benutzerprofile“) schaltet sie ab: Apps können dann die ID nicht mehr verwenden, und Apps, die eine ID anfordern, erhalten keine. Auch hier ist „Aktiviert“ der Zustand, in dem die Funktion *abgeschaltet* ist.

Nach meiner Kenntnis (nicht abgerufen) schreibt die Richtlinie den Wert `DisabledByGroupPolicy` = 1 in den Schlüssel `HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo`. Verwandt ist die Benutzerrichtlinie „Do not use diagnostic data for tailored experiences“ (`DisableTailoredExperiencesWithDiagnosticData`) unter „Windows-Komponenten \> Cloudinhalt“, die laut Microsoft verhindert, dass Windows Diagnosedaten nutzt, um Inhalte auf dem Sperrbildschirm, Windows-Tipps und Consumer-Funktionen zu personalisieren. Benutzer sehen weiterhin Empfehlungen, Tipps und Angebote, aber sie sind weniger zielgerichtet. Diese zweite Richtlinie wirkt pro Benutzer.

> **Ergänzung aus der Nachrecherche**
>
> Die Datenschutzwirkung der Werbe-ID ist begrenzt, weil im Unternehmensumfeld ohnehin kaum Apps mit Werbung laufen. Der Wert der Richtlinie liegt in der Konsistenz: Sie dokumentiert gegenüber Datenschutzbeauftragten, dass personalisierte Werbung auf Unternehmensgeräten technisch abgestellt ist. Die Rechtsbewertung (zum Beispiel Einwilligung, Transparenz) ist nicht Gegenstand dieses Skripts und keine Rechtsberatung.

Das Beispiel setzt beide Richtlinien: die Computerrichtlinie für die Werbe-ID und die Benutzerrichtlinie für zugeschnittene Erfahrungen. Der Registrywert der zweiten stammt aus der Policy-CSP-Dokumentation (`DisableTailoredExperiencesWithDiagnosticData` im Schlüssel `Software\Policies\Microsoft\Windows\CloudContent`); der der ersten ist aus meiner Kenntnis.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "PRIV-Werbe-ID-aus"

# Computer: Werbe-ID aus
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" `
    -ValueName DisabledByGroupPolicy -Type DWord -Value 1

# Benutzer: keine Personalisierung mit Diagnosedaten
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKCU\Software\Policies\Microsoft\Windows\CloudContent" `
    -ValueName DisableTailoredExperiencesWithDiagnosticData -Type DWord -Value 1

# Am Client: Einstellung der aktuellen Benutzersicht
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -ErrorAction SilentlyContinue |
    Select-Object Enabled
```

Der erste Wert gehört zur Computerkonfiguration, der zweite zur Benutzerkonfiguration; deshalb enthält die GPO beide Hälften, und sie muss so verknüpft werden, dass beide wirken (Benutzer-OU und Computer-OU, oder Loopback). Die Abfrage zeigt die Einstellung `Enabled` der Werbe-ID für den angemeldeten Benutzer; der Wert 0 bedeutet nach meiner Kenntnis „aus“.

**Typische Fehler.** Falsch: die GPO mit nur einer OU-Art zu verknüpfen, sodass entweder die Computer- oder die Benutzerhälfte nicht greift. Richtig: Verknüpfung und Verarbeitungsmodus prüfen. Zweiter Fehler: zu glauben, damit sei Tracking durch Apps beendet; Apps können andere Kennungen nutzen. Dritter Fehler: in den Bereichen Spotlight und Vorschläge weitere Funktionen zu übersehen, die separat (zum Beispiel „Allow Windows Spotlight“) konfiguriert werden.

> **Praxisbeispiel**
>
> Beispielszenario: Eine Bildungseinrichtung muss gegenüber der Aufsicht belegen, dass auf Schülergeräten keine personalisierte Werbung ausgespielt wird. Die GPO und die Dokumentation der Einstellungen liefern den technischen Nachweis.

## 64 Feedbackbenachrichtigungen deaktivieren

| **Feld**        | **Steckbrief**                                                                                              |
|:----------------|:------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Datensammlung und Vorabversionen |
| Einstellung     | Feedbackbenachrichtigungen nicht anzeigen                                                                   |
| Empfehlung      | Aktiviert                                                                                                   |
| Ziel / Zweck    | Reduziert Störungen und Datenabfluss                                                                        |
| Zielbereich     | Computer                                                                                                    |
| Priorität       | 3                                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                 |

Windows fragt Benutzer gelegentlich nach Feedback: kurze Umfragen zu Funktionen, die über die Feedback-App laufen. Für die Arbeit im Unternehmen sind sie nur Unterbrechungen, und sie transportieren Antworten an Microsoft, deren Inhalt die IT nicht kennt. Die Richtlinie „Do not show feedback notifications“ („Feedbackbenachrichtigungen nicht anzeigen“) unterdrückt diese Fragen. Laut Microsoft-Dokumentation handelt es sich um eine reine Computerrichtlinie, sie funktioniert ab Windows 10 Version 1607 und auf den Editionen Pro, Enterprise, Education und IoT Enterprise.

Die Dokumentation beschreibt die Wirkung genau: Ist die Richtlinie aktiviert, sehen Benutzer keine Feedbackbenachrichtigungen über die Windows-Feedback-App mehr. Ist sie deaktiviert oder nicht konfiguriert, *können* Benachrichtigungen erscheinen, und die Benutzer steuern, wie oft sie Fragen bekommen. Der Standardwert ist 0; der Wert 1 schaltet die Meldungen ab. Die Richtlinie liegt in der ADMX-Datei `FeedbackNotifications.admx` und schreibt `DoNotShowFeedbackNotifications` in den Schlüssel `Software\Policies\Microsoft\Windows\DataCollection`. Das ist derselbe Schlüssel wie bei den Diagnosedaten (Abschnitt 61), und die zwei Richtlinien lassen sich in einer GPO bündeln.

> **Merke**
>
> Priorität 3 bedeutet hier: Die Maßnahme verbessert die Arbeitsumgebung, verringert aber das Sicherheitsrisiko kaum. Man bündelt sie mit anderen Datenschutz-Richtlinien in einer GPO und rollt sie ohne eigenen Pilot mit.

Das Beispiel ergänzt die Datenschutz-GPO aus Abschnitt 61 um diese Einstellung und prüft den Zustand am Client. Registrywert und Schlüssel entsprechen der Zuordnung in der Microsoft-Dokumentation; die Prüfung liest nur.

```ps
Import-Module GroupPolicy
# In die bereits vorhandene Datenschutz-GPO schreiben
Set-GPRegistryValue -Name "PRIV-Diagnosedaten" `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
    -ValueName DoNotShowFeedbackNotifications -Type DWord -Value 1

# Am Client
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" |
    Select-Object AllowTelemetry, DoNotShowFeedbackNotifications
```

Der Befehl erweitert eine vorhandene GPO um den neuen Wert, statt eine weitere GPO anzulegen. Das hält die Zahl der Richtlinienobjekte klein. Die Abfrage zeigt am Client beide Werte nebeneinander; erscheinen beide, wurde die gebündelte GPO angewendet.

**Typische Fehler.** Falsch: für jede Einzeleinstellung eine eigene GPO anzulegen. Bei hundert Richtlinien führt das zu einem unübersichtlichen Bestand und längeren Verarbeitungszeiten. Richtig: thematisch gruppieren (zum Beispiel „PRIV-Basis“) und die Gruppierung dokumentieren. Zweiter Fehler: die Richtlinie für ein Problem zu halten, das sie nicht löst; sie betrifft nur Feedbackfragen, nicht die Feedback-App an sich. Dritter Fehler: die Richtlinie mit Änderungen in der Feedback-Häufigkeit auf Benutzerebene zu verwechseln.

> **Praxisbeispiel**
>
> Beispielszenario: Mitarbeiter in einem Callcenter werden mitten im Telefonat von einer Feedback-Frage gestört. Die Richtlinie beseitigt das Problem, ohne dass die Mitarbeiter etwas einstellen müssen.

## 65 Clipboard History steuern

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> Betriebssystemrichtlinien     |
| Einstellung     | Zwischenablageverlauf zulassen                                                              |
| Empfehlung      | Deaktiviert oder nach Bedarf                                                                |
| Ziel / Zweck    | Schützt sensible Inhalte                                                                    |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Die *Zwischenablage* ist der Speicher, in den `Strg+C` etwas kopiert und aus dem `Strg+V` es einfügt. Normalerweise hält sie nur das letzte Element. Der *Zwischenablageverlauf* (Taste `Win+V`) merkt sich mehrere Einträge. Das ist bequem, aber ein Datenschutzproblem: Kennwörter, die man aus einem Passwortmanager kopiert hat, Kundendaten oder Bankdaten bleiben im Speicher liegen und sind per `Win+V` einsehbar. Die Richtlinie „Allow Clipboard History“ (`AllowClipboardHistory`) legt fest, ob der Verlauf überhaupt gespeichert werden darf.

Laut Microsoft-Dokumentation gilt: Ist die Richtlinie aktiviert, darf der Verlauf gespeichert werden; ist sie *deaktiviert*, wird er nicht gespeichert. Der Standard ist erlaubt (Wert 1). Die Änderung wirkt sofort. Als Test beschreibt Microsoft: Wert auf 0 setzen, in Notepad Text kopieren, `Win+V` drücken, und es darf kein Eintrag erscheinen; die Einstellung unter „Einstellungen \> System \> Zwischenablage“ ist dann ausgegraut mit einem Richtlinienhinweis. Die Richtlinie liegt im Pfad „System \> Betriebssystemrichtlinien“, in der Datei `OSPolicy.admx`, und schreibt `AllowClipboardHistory` in den Schlüssel `Software\Policies\Microsoft\Windows\System`.

> **Ergänzung aus der Nachrecherche**
>
> Der Lehrplan sagt „Deaktiviert oder nach Bedarf“. Eine Abwägung: In Umgebungen mit sensiblen Daten (Gesundheit, Finanzen, Personalwesen) ist der Verlauf zu deaktivieren. In Entwickler- und Büroumgebungen steigert der Verlauf die Produktivität; dort kann man ihn erlauben, aber die Synchronisation über Geräte (Abschnitt 66) abschalten. Der Verlauf liegt im Arbeitsspeicher; Microsoft nennt ihn „in memory“.

Das folgende Beispiel schaltet den Verlauf für Hochsicherheitsgeräte ab und prüft, wie die Einstellung am Client ankommt. Die Registrynamen stammen aus der Policy-CSP-Dokumentation. Die Kontrolle im Browser des Benutzers (Test mit `Win+V`) ersetzt der Befehl nicht, ergänzt ihn aber.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "PRIV-Zwischenablage"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\System"
# 0 = Verlauf nicht erlaubt, 1 = erlaubt
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName AllowClipboardHistory -Type DWord -Value 0

# Am Client: Wert und lokale Benutzereinstellung
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -ErrorAction SilentlyContinue |
    Select-Object AllowClipboardHistory
Get-ItemProperty "HKCU:\Software\Microsoft\Clipboard" -ErrorAction SilentlyContinue |
    Select-Object EnableClipboardHistory
```

Der erste Block setzt die Richtlinie. Die zweite Abfrage zeigt den Policy-Wert; die dritte die lokale Benutzereinstellung (`EnableClipboardHistory` nach meiner Kenntnis), die die Richtlinie übersteuert. Beide zu betrachten erklärt, warum der Benutzer den Schalter nicht mehr bedienen kann.

**Typische Fehler.** Falsch: zu glauben, die Richtlinie lösche vorhandene Einträge. Sie verhindert das Speichern; zuvor gespeicherte Einträge verschwinden nach meiner Kenntnis mit dem Neustart oder durch Leeren des Verlaufs. Richtig: im Pilot das Verhalten bestätigen. Zweiter Fehler: Verlauf und Synchronisation (Abschnitt 66) zu verwechseln; sie sind zwei Richtlinien mit zwei Wirkungen. Dritter Fehler: die Richtlinie als Schutz vor Schadsoftware zu sehen; Programme können die Zwischenablage auch ohne Verlauf lesen.

> **Praxisbeispiel**
>
> Beispielszenario: In der Personalabteilung kopieren Mitarbeiter häufig Gehaltsdaten zwischen Anwendungen. Der Verlauf wird abgeschaltet, damit die Daten nicht über `Win+V` auch an Kollegen sichtbar werden, die kurz an dem Rechner arbeiten.

## 66 Cloud Clipboard deaktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> Betriebssystemrichtlinien     |
| Einstellung     | Synchronisierung der Zwischenablage zwischen Geräten zulassen                               |
| Empfehlung      | Deaktiviert                                                                                 |
| Ziel / Zweck    | Verhindert unkontrollierte Datenübertragung                                                 |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Die *Cloud-Zwischenablage* geht einen Schritt weiter als der Verlauf: Sie synchronisiert kopierte Inhalte über die Cloud auf andere Geräte, die mit demselben Konto angemeldet sind. Wer auf dem Laptop etwas kopiert, kann es auf dem privaten Tablet einfügen. Für Unternehmensdaten ist das ein Abflussweg: Dienstliche Daten wandern in die Cloud und auf Geräte, die die Organisation nicht kontrolliert. Darum hat der Lehrplan hier Priorität 1. Die Richtlinie „Allow Clipboard synchronization across devices“ (`AllowCrossDeviceClipboard`) steuert das.

Laut der Policy-CSP-Dokumentation lässt sich bei aktivierter Richtlinie die Zwischenablage zwischen Geräten synchronisieren, die mit demselben Microsoft- oder Entra-Konto angemeldet sind. Bei *deaktivierter* Richtlinie ist das nicht möglich. Der restriktivste Wert ist 0, der Standard ist 1, und die Änderung wirkt sofort. Die Richtlinie liegt im selben Pfad wie die vorige („System \> Betriebssystemrichtlinien“, `OSPolicy.admx`), im Schlüssel `Software\Policies\Microsoft\Windows\System`, mit dem Wert `AllowCrossDeviceClipboard`. Damit sind beide Zwischenablage-Richtlinien in einer GPO bündelbar.

> **Merke**
>
> Zwei Richtlinien, zwei Fragen: Abschnitt 65 fragt „Wird auf *diesem* Gerät ein Verlauf gespeichert?“, Abschnitt 66 fragt „Verlässt der Inhalt dieses Gerät in die Cloud?“. Aus Sicht der Datenabflusskontrolle ist die zweite die wichtigere.

Das Beispiel ergänzt die GPO aus Abschnitt 65. Es zeigt außerdem ein kleines Prüfskript, das zwei Richtlinien in einem Zug auswertet. Die Werte stammen aus der Policy-CSP-Dokumentation; das Skript liest nur.

```ps
Import-Module GroupPolicy
Set-GPRegistryValue -Name "PRIV-Zwischenablage" `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" `
    -ValueName AllowCrossDeviceClipboard -Type DWord -Value 0

# Pruefskript fuer den Client
$p = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -ErrorAction SilentlyContinue
[pscustomobject]@{
    Computer         = $env:COMPUTERNAME
    VerlaufErlaubt   = if ($null -eq $p.AllowClipboardHistory)     { 'nicht konfiguriert' } else { [bool]$p.AllowClipboardHistory }
    CloudSyncErlaubt = if ($null -eq $p.AllowCrossDeviceClipboard) { 'nicht konfiguriert' } else { [bool]$p.AllowCrossDeviceClipboard }
}
```

Die erste Anweisung schaltet die Synchronisation ab. Das Prüfskript unterscheidet zwischen „nicht konfiguriert“ und einem gesetzten Wert, was beim Auswerten von Richtlinien wichtig ist: „Nicht konfiguriert“ bedeutet nicht „verboten“, sondern „Standard gilt“, und der Standard ist erlaubt.

**Typische Fehler.** Falsch: nur den Verlauf zu deaktivieren und die Synchronisation zu vergessen. Richtig: beide gemeinsam betrachten. Zweiter Fehler: bei gemischter Nutzung mit privaten Geräten (BYOD) keine Regel zu haben, die auch dort wirkt; die Richtlinie wirkt nur auf verwalteten Geräten. Dritter Fehler: davon auszugehen, dass das Kopieren in Remote-Sitzungen (RDP) ebenfalls betroffen sei; das ist eine eigene Einstellung der Remotedesktopdienste (Umleitung der Zwischenablage).

> **Praxisbeispiel**
>
> Beispielszenario: Ein Mitarbeiter kopiert eine Kundenliste und fügt sie am Abend zu Hause auf seinem privaten Laptop ein, weil beide Geräte denselben Microsoft-Kontonamen nutzen. Mit der Richtlinie ist dieser Weg verschlossen.

## 67 Widgets steuern

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Widgets          |
| Einstellung     | Widgets zulassen                                                                            |
| Empfehlung      | Nach Unternehmensvorgabe                                                                    |
| Ziel / Zweck    | Reduziert Ablenkung und externe Inhalte                                                     |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 3                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

*Widgets* sind das Panel am linken Rand der Taskleiste in Windows 11, das Wetter, Nachrichten, Börsenkurse und Empfehlungen anzeigt. Die Inhalte kommen aus externen Quellen und werden bei Bedarf geladen. In einer Büroumgebung sind sie meist unerwünscht: Sie lenken ab, erzeugen Netzwerkverkehr zu fremden Diensten und zeigen Inhalte, die das Unternehmen nicht kontrolliert. In anderen Umgebungen (Infoterminals, Empfang) kann ein Wetter-Widget aber erwünscht sein. Das erklärt die Formulierung „nach Unternehmensvorgabe“.

Laut der Microsoft-Dokumentation zu den Taskleisten-Richtlinien ist „Allow widgets“ die zuständige Einstellung: Sie legt fest, ob die Widgets-Funktion auf dem Gerät erlaubt ist. Standardmäßig sind Widgets eingeschaltet. Ist die Richtlinie aktiviert, werden Widgets automatisch eingeschaltet, sofern der Benutzer sie nicht in den Einstellungen abschaltet; deaktiviert man sie, ist die Funktion nicht verfügbar. Die GPO-Position ist „Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Widgets \> Allow widgets“; das Pendant im Policy CSP heißt `NewsAndInterests/AllowNewsAndInterests`.

> **Ergänzung aus der Nachrecherche**
>
> Nach meiner Kenntnis (nicht abgerufen) schreibt die Richtlinie den Wert `AllowNewsAndInterests` in den Schlüssel `HKLM\SOFTWARE\Policies\Microsoft\Dsh`. Ob die Richtlinie auf der aktuellen Windows-Version ohne Einschränkungen funktioniert (Widgets sind eine Komponente des Windows-Web-Experience-Pakets und wurden in den vergangenen Versionen mehrfach überarbeitet), sollte im Pilot geprüft werden.

Das Beispiel deaktiviert die Widgets und zeigt, wie man im Bestand erkennt, ob die zugehörige Komponente läuft. Der Registrywert ist aus meiner Kenntnis, die Prozessabfrage ist Standard.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "UX-Widgets-aus"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Dsh" `
    -ValueName AllowNewsAndInterests -Type DWord -Value 0

# Am Client: laufen Widget-Prozesse noch?
Get-Process -Name Widgets, WidgetService -ErrorAction SilentlyContinue |
    Select-Object Name, Id, StartTime
```

Der Wert 0 deaktiviert die Funktion. Die Prozessabfrage zeigt, ob `Widgets` oder `WidgetService` noch laufen; nach dem Anmelden mit angewendeter Richtlinie sollte die Liste leer sein. Die Namen der Prozesse sind nach meiner Kenntnis und können sich zwischen Windows-Versionen ändern.

**Typische Fehler.** Falsch: die Taskleistenschaltfläche mit anderen Mitteln (Registry-Hack, Skript) auszublenden, statt die Richtlinie zu verwenden. Solche Eingriffe sind nicht unterstützt und können bei Updates verschwinden. Richtig: die dokumentierte Richtlinie. Zweiter Fehler: Widgets zu deaktivieren und dann keine Alternative für Wetter oder Nachrichten anzubieten, wo sie gebraucht werden. Dritter Fehler: nach Updates nicht zu prüfen, ob die Richtlinie noch wirkt.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Hersteller blendet auf Produktionsrechnern alle Ablenkungen aus. Die Widgets werden zentral deaktiviert; am Empfang bleiben sie für das Wetter-Widget auf einem Anzeigegerät erhalten, mit einer eigenen OU.

## 68 Startmenü Pins konfigurieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Benutzerkonfiguration \> Administrative Vorlagen \> Startmenü und Taskleiste                |
| Einstellung     | Start Pins konfigurieren                                                                    |
| Empfehlung      | Standardlayout für Rollen                                                                   |
| Ziel / Zweck    | Standardisiert Benutzererlebnis                                                             |
| Zielbereich     | User                                                                                        |
| Priorität       | 3                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Das Startmenü von Windows 11 zeigt oben die *angehefteten Apps* (Pins). Standardmäßig sind das Microsoft-Vorschläge, die mit dem Unternehmen wenig zu tun haben. Die Richtlinie „Configure Start Pins“ erlaubt, eine eigene Liste vorzugeben. Das ist besonders in Schulungsräumen und für Neueinsteiger hilfreich: Jeder findet Outlook, Teams und die Fachanwendung an derselben Stelle. Der Lehrplan formuliert das mit „Standardlayout für Rollen“: Verschiedene Rollen (Buchhaltung, Vertrieb, Technik) bekommen unterschiedliche Listen.

Die Microsoft-Dokumentation beschreibt, wie das technisch funktioniert: Das Layout ist eine JSON-Datei mit dem Namen `LayoutModification.json`, die die angehefteten Elemente und ihre Reihenfolge aufzählt. Die Richtlinie `ConfigureStartPins` nimmt den Inhalt dieser Datei als Zeichenfolge und steht in der Computer- und der Benutzerkonfiguration. Der Registrywert heißt `ConfigureStartPins` im Schlüssel `Software\Policies\Microsoft\Windows\Explorer`. Wichtig ist ein Hinweis der Dokumentation: Mit der Richtlinie wird das *gesamte Layout überschrieben*. Benutzer können Pins neu ordnen, anheften und lösen, aber bei der nächsten Anmeldung wird das vorgegebene Layout wieder hergestellt, ohne dass Änderungen erhalten bleiben. Seit Windows 11 24H2 mit dem Update KB5062660 kann man laut Microsoft das Layout auch so konfigurieren, dass es nur *einmal* angewendet wird; dann können Benutzer danach anpassen. Ebenfalls seit diesem Stand lässt sich die JSON-Datei sowohl per CSP als auch per Gruppenrichtlinie anwenden, in früheren Windows-11-Versionen nur per CSP.

> **Ergänzung aus der Nachrecherche**
>
> Die Gruppenrichtlinie für Start-Pins ist damit an eine Mindestversion gebunden. Auf älteren Windows-11-Ständen greift die GPO nicht; dort bleibt nur der Weg über MDM oder Provisioning-Pakete. Das Werkzeug `Import-StartLayout` ist laut Microsoft für Windows 11 nicht mehr unterstützt (bezogen auf die Taskleiste). Bei der Planung sollte man daher die Windows-Version im Bestand prüfen.

Das Beispiel erzeugt eine JSON-Datei mit drei Pins und legt sie als Richtlinienwert in der GPO ab. Die Struktur der Datei (`pinnedList` mit `desktopAppId`, `packagedAppId`, `desktopAppLink`) stammt aus meiner Kenntnis des Formats; die genauen Schlüssel sind in der Microsoft-Dokumentation „Customize the Start layout“ nachzulesen und im Pilot zu prüfen. Die Programmverknüpfung zeigt auf eine Datei, die auf dem Client existieren muss.

```ps
Import-Module GroupPolicy
$json = @'
{
  "pinnedList": [
    { "desktopAppId": "MSEdge" },
    { "packagedAppId": "Microsoft.WindowsCalculator_8wekyb3d8bbwe!App" },
    { "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Outlook.lnk" }
  ]
}
'@
# JSON pruefen, bevor es in die GPO geht
$null = $json | ConvertFrom-Json

$gpo = New-GPO -Name "UX-Start-Pins-Standard"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKCU\Software\Policies\Microsoft\Windows\Explorer" `
    -ValueName ConfigureStartPins -Type String -Value ($json -replace '\s*\r?\n\s*', ' ')
```

Der JSON-Text beschreibt Edge, den Rechner und Outlook als Pins. `ConvertFrom-Json` dient nur als Syntaxprüfung; ein Komma zu viel würde die gesamte Konfiguration unwirksam machen. Das Ersetzen der Zeilenumbrüche macht aus der Datei eine einzelne Zeile, wie Microsoft es für Wertfelder verlangt. Der Wert wird in die Benutzerhälfte (`HKCU`) geschrieben; die GPO ist an eine Benutzer-OU zu binden.

**Typische Fehler.** Falsch: zu erwarten, dass Benutzer ihre Änderungen behalten, obwohl die Richtlinie bei jeder Anmeldung das Layout wiederherstellt. Richtig: wenn gewünscht, die Variante „nur einmal anwenden“ nutzen (24H2 mit passendem Update). Zweiter Fehler: Pins auf Programme zu setzen, die auf dem Rechner nicht installiert sind; der Pin bleibt leer oder wird ignoriert. Dritter Fehler: für jede Abteilung eine GPO mit eigener JSON zu pflegen, ohne Schema; besser sind wenige Rollenlayouts, ausgewählt über Sicherheitsgruppenfilter.

> **Praxisbeispiel**
>
> Beispielszenario: In einer Schule bekommen Schüler ein Startmenü mit Browser, Textverarbeitung und Lernplattform, Lehrkräfte zusätzlich Notenverwaltung und Klassenbuch. Zwei GPOs mit je einer JSON-Datei, gesteuert über Gruppen, genügen.

## 69 Taskleistenanpassungen steuern

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Benutzerkonfiguration \> Administrative Vorlagen \> Startmenü und Taskleiste                |
| Einstellung     | Taskleistenrichtlinien                                                                      |
| Empfehlung      | Nach UX-Standard                                                                            |
| Ziel / Zweck    | Erhöht Einheitlichkeit in Schulungs-/Betriebsumgebungen                                     |
| Zielbereich     | User                                                                                        |
| Priorität       | 3                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Auch die Taskleiste lässt sich vorgeben. Die Microsoft-Dokumentation zeigt eine Liste von Taskleisten-Richtlinien mit unterschiedlicher Unterstützung durch CSP und Gruppenrichtlinie. Gruppenrichtlinie und CSP gleichermaßen verfügbar sind unter anderem das Ausblenden der Suche oder Konfigurieren ihrer Darstellung („Configure search on the taskbar“ mit den Modi verborgen, nur Symbol, Symbol mit Beschriftung, Suchfeld), das Verbergen der Aufgabenansicht-Schaltfläche, das Entfernen von Schnelleinstellungen, die „Start layout“-Richtlinie für angeheftete Taskleisten-Apps und die Option, Jumplists zuletzt benutzter Dokumente auszublenden. Nur per Gruppenrichtlinie verfügbar sind unter anderem „Remove pinned programs from the Taskbar“, „Remove Clock from the system notification area“ und „Remove Notifications and Action Center“.

Für die angehefteten Apps verlangt die Richtlinie „Start layout“ eine XML-Datei. Das Verhalten beschreibt die Dokumentation genau: Nach dem Anwenden müssen sich Benutzer ab- und wieder anmelden, um das Layout zu sehen. Ohne weitere Einschränkung können Benutzer Pins hinzufügen, entfernen und umordnen. Standardmäßig werden über Richtlinien bereitgestellte Pins bei der nächsten Aktualisierung wiederhergestellt, auch wenn der Benutzer sie gelöst hat; Pins mit dem Attribut `PinGeneration` können dagegen gelöst werden und werden nicht erneut angeheftet. Bei einer Gruppenrichtlinie wird die Konfiguration erneut angewendet, wenn sich die Richtlinie ändert; bei CSP etwa alle acht Stunden. Das Cmdlet `Import-StartLayout` wird laut Microsoft für Windows 11 nicht mehr unterstützt.

> **Merke**
>
> Je mehr die Taskleiste fest vorgegeben wird, desto geringer der Spielraum der Benutzer, aber desto größer der Pflegeaufwand und die Zahl der Beschwerden. Für Schulungsräume und Terminals ist Festlegen sinnvoll; im Büroalltag genügt meist ein Startlayout mit wenigen Pins.

Das Beispiel erzeugt eine Taskleisten-XML mit zwei Apps, legt sie auf einer Freigabe ab und setzt die Richtlinie. Das XML-Schema (Namensräume `TaskbarLayout`, Element `TaskbarPinList`) stammt aus meiner Kenntnis des Formats; die Microsoft-Seite „Configure the applications pinned to the taskbar“ enthält ein vollständiges Beispiel und ist maßgeblich. Der Name des Registrywerts (`StartLayoutFile`) und der Pfad sind aus meiner Kenntnis und im Pilot zu prüfen.

```ps
$xml = @'
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">
  <CustomTaskbarLayoutCollection PinListPlacement="Replace">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>
        <taskbar:DesktopApp DesktopApplicationID="MSEdge" />
        <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Outlook.lnk" />
      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
'@
[xml]$null = $xml                      # Syntaxpruefung
Set-Content -Path "\\fileserver\netlogon$\Taskbar.xml" -Value $xml -Encoding UTF8

Import-Module GroupPolicy
$gpo = New-GPO -Name "UX-Taskleiste-Standard"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKCU\Software\Policies\Microsoft\Windows\Explorer" `
    -ValueName StartLayoutFile -Type ExpandString -Value "\\fileserver\netlogon$\Taskbar.xml"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKCU\Software\Policies\Microsoft\Windows\Explorer" `
    -ValueName LockedStartLayout -Type DWord -Value 0
```

Die XML beschreibt zwei Taskleisten-Pins und ersetzt den Standardbestand (`PinListPlacement="Replace"`). Der Cast auf `[xml]` prüft die Syntax. Die Freigabe muss lesbar sein für die Benutzer, aber nur für Administratoren schreibbar. Der Wert `LockedStartLayout = 0` lässt nach meiner Kenntnis Änderungen durch den Benutzer zu. Nach dem Anwenden müssen sich Benutzer laut Microsoft ab- und wieder anmelden.

**Typische Fehler.** Falsch: die XML auf eine Freigabe zu legen, die zum Zeitpunkt der Anmeldung nicht erreichbar ist (VPN, Heimarbeit). Richtig: die Datei lokal verteilen oder über CSP/Intune. Zweiter Fehler: „Remove pinned programs from the Taskbar“ zusammen mit einem Pin-Layout zu aktivieren; das Entfernen schließt das Anheften aus. Dritter Fehler: nach dem Rollout zu erwarten, dass bereits angemeldete Benutzer die Änderung sofort sehen.

> **Praxisbeispiel**
>
> Beispielszenario: In einem Prüfungsraum sollen alle Rechner dieselbe Taskleiste haben: Browser, Prüfungssoftware, nichts sonst. Die Richtlinie wird auf die Raum-OU gebunden; die Benutzer können Pins nicht hinzufügen.

## 70 Sperrbildschirm Apps deaktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Systemsteuerung \> Anpassung            |
| Einstellung     | Sperrbildschirm Appbenachrichtigungen                                                       |
| Empfehlung      | Deaktiviert                                                                                 |
| Ziel / Zweck    | Reduziert Informationsabfluss                                                               |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Der *Sperrbildschirm* erscheint, wenn der Rechner gesperrt ist. Er zeigt Uhrzeit, Hintergrund und, wenn man es zulässt, auch Benachrichtigungen und Statusinformationen von Apps: eingehende Mails, Kalendertermine, Chatnachrichten. Das Problem ist offensichtlich: Wer an einem gesperrten Rechner vorbeigeht, kann mitlesen, ohne sich anzumelden. In Großraumbüros, am Empfang und in Besprechungsräumen ist das ein echtes Risiko für Vertraulichkeit.

Der Lehrplan nennt als Pfad „Systemsteuerung \> Anpassung“. Die passende Richtlinie ist nach meiner Kenntnis (nicht abgerufen) „Turn off app notifications on the lock screen“ unter „Computerkonfiguration \> Administrative Vorlagen \> System \> Anmelden“ (Registrywert `DisableLockScreenAppNotifications` im Schlüssel `HKLM\SOFTWARE\Policies\Microsoft\Windows\System`). Aktiviert man sie, werden App-Benachrichtigungen auf dem Sperrbildschirm unterdrückt. Eine weitere Richtlinie mit ähnlichem Ziel ist „Turn off toast notifications on the lock screen“ in der Benutzerkonfiguration (Startmenü und Taskleiste \> Benachrichtigungen). Der Bereich „Systemsteuerung \> Anpassung“ enthält dagegen Richtlinien zum Aussehen, etwa „Do not display the lock screen“ oder „Prevent changing lock screen and logon image“. Die Verwechslung des Pfades ist im Lehrplan ein typischer Platzhalterfehler.

> **Ergänzung aus der Nachrecherche**
>
> Ob man einzelne Benutzerinnen entlasten möchte, die ihre Meldungen auch gesperrt sehen wollen (Benachrichtigungen von Messenger-Apps), ist eine Abwägung zwischen Komfort und Vertraulichkeit. Eine Alternative zu Verbot ist die Schulung, den Rechner beim Verlassen zu sperren, und die automatische Sperre nach kurzer Inaktivität (Richtlinie „Interactive logon: Machine inactivity limit“ aus Modul 01).

Das Beispiel schaltet die Benachrichtigungen ab und prüft am Client die Lage. Die Registrynamen sind aus meiner Kenntnis und im Pilot gegen die ADMX-Vorlage zu prüfen. Die Benutzerhälfte `NoToastApplicationNotificationOnLockScreen` ist ebenfalls aus meiner Kenntnis.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "PRIV-Sperrbildschirm"

# Computer: keine App-Benachrichtigungen auf dem Sperrbildschirm
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" `
    -ValueName DisableLockScreenAppNotifications -Type DWord -Value 1

# Benutzer: keine Toast-Benachrichtigungen auf dem Sperrbildschirm
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKCU\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" `
    -ValueName NoToastApplicationNotificationOnLockScreen -Type DWord -Value 1

# Am Client: Policy-Werte lesen
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -ErrorAction SilentlyContinue |
    Select-Object DisableLockScreenAppNotifications
```

Der erste Wert gilt für den Rechner, der zweite für den Benutzer; wieder müssen beide Hälften der GPO passend verknüpft sein. Die Abfrage prüft die Computerhälfte. Zum praktischen Test lässt man auf einem Testgerät eine Mail eintreffen, sperrt den Rechner mit `Win+L` und schaut, ob die Meldung auf dem Sperrbildschirm erscheint.

**Typische Fehler.** Falsch: nach dem Pfad aus dem Lehrplan im falschen Zweig zu suchen und die Richtlinie nicht zu finden. Richtig: im Gruppenrichtlinien-Editor die Suche nach dem englischen oder deutschen Namen nutzen. Zweiter Fehler: nur Benachrichtigungen zu unterdrücken und den Sperrbildschirm selbst (Spotlight-Bilder, Tipps) zu übersehen. Dritter Fehler: die Maßnahme als Ersatz für die automatische Sperre zu verstehen; ohne zuverlässige Sperre nützt sie wenig.

> **Praxisbeispiel**
>
> Beispielszenario: Am Empfang eines Anwaltsbüros erscheinen auf dem gesperrten Rechner sonst Betreffzeilen von Mandantenmails. Mit der Richtlinie bleibt der Sperrbildschirm neutral, und Besucher können nichts mitlesen.

## Übungsaufgaben zu Modul 07

**Aufgabe 1.** **(leicht)** Nennen Sie die Diagnosedaten-Stufen und ihre Werte unter Windows 11. Welche Stufe gibt es nicht mehr?

**Aufgabe 2.** **(leicht)** Warum ist „Aktiviert“ bei „Microsoft Consumer Experiences deaktivieren“ die Einstellung, die die Funktion abschaltet?

**Aufgabe 3.** **(leicht)** Was unterscheidet Zwischenablageverlauf und Cloud-Zwischenablage, und welche Richtlinie ist für Datenabfluss wichtiger?

**Aufgabe 4.** **(mittel)** Welche Einschränkung gilt für die Consumer-Experiences-Richtlinie bei Windows 11 Pro?

**Aufgabe 5.** **(mittel)** Wie verhält sich die Start-Pins-Richtlinie, wenn Benutzer das Layout ändern, und was ändert sich ab Windows 11 24H2 mit KB5062660?

**Aufgabe 6.** **(praktisch)** Schreiben Sie ein Skript, das eine GPO `PRIV-Basis` mit den Richtlinien Diagnosedaten (Stufe 1), Feedbackbenachrichtigungen aus, Zwischenablageverlauf aus und Cloud-Zwischenablage aus erstellt.

**Aufgabe 7.** **(praktisch)** Schreiben Sie ein Prüfskript, das für einen Client die wirksamen Werte dieser vier Richtlinien ausliest und eine Tabelle mit den Spalten Richtlinie, Wert, Status („konfiguriert“/„nicht konfiguriert“) ausgibt.

**Aufgabe 8.** **(schwer)** Erstellen Sie einen Entscheidungsvorschlag für den Datenschutzbeauftragten: Welche Richtlinien dieses Moduls setzen Sie, welche nicht, und welche Rücksprache mit Betriebsrat oder Datenschutz ist nötig? (Keine Rechtsberatung, sondern eine technische Entscheidungsvorlage.)

## Lösungen zu Modul 07

**Lösung 1.** 0 = aus (nur Enterprise, Education, Server), 1 = erforderlich, 2 = erweitert, 3 = optional. Die Stufe „erweitert“ gibt es unter Windows 11 nicht mehr; sie wurde durch Richtlinien für die Menge optionaler Daten ersetzt.

**Lösung 2.** Weil die Richtlinie heißt „Microsoft Consumer Experiences *deaktivieren*“: Der Zustand „Aktiviert“ der Richtlinie bedeutet, dass die Funktionen deaktiviert sind. Registrywert `DisableWindowsConsumerFeatures` = 1.

**Lösung 3.** Der Verlauf speichert mehrere Einträge lokal im Arbeitsspeicher (`Win+V`); die Cloud-Zwischenablage synchronisiert Inhalte auf andere Geräte desselben Kontos. Für Datenabfluss ist die Synchronisation wichtiger, weil Inhalte das Gerät verlassen.

**Lösung 4.** Laut der Policy-CSP-Dokumentation wirkt die Richtlinie nur auf Enterprise, Education und IoT Enterprise, nicht auf Pro.

**Lösung 5.** Das gesamte Layout wird überschrieben; Benutzer können ändern, aber bei der nächsten Anmeldung wird das vorgegebene Layout wieder hergestellt. Ab 24H2 mit KB5062660 kann das Layout nur einmal angewendet werden, und die JSON-Datei lässt sich auch per Gruppenrichtlinie anwenden (vorher nur CSP).

```ps
# Loesung 6
Import-Module GroupPolicy
$gpo = New-GPO -Name "PRIV-Basis"
$dc  = "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
$sys = "HKLM\SOFTWARE\Policies\Microsoft\Windows\System"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $dc  -ValueName AllowTelemetry                 -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $dc  -ValueName DoNotShowFeedbackNotifications -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $sys -ValueName AllowClipboardHistory          -Type DWord -Value 0
Set-GPRegistryValue -Name $gpo.DisplayName -Key $sys -ValueName AllowCrossDeviceClipboard      -Type DWord -Value 0
```

```ps
# Loesung 7
$soll = @(
  @{ N='Diagnosedaten';   K='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; V='AllowTelemetry' },
  @{ N='Feedback aus';    K='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; V='DoNotShowFeedbackNotifications' },
  @{ N='Verlauf';         K='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System';         V='AllowClipboardHistory' },
  @{ N='Cloud-Clipboard'; K='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System';         V='AllowCrossDeviceClipboard' }
)
$soll | ForEach-Object {
    $w = (Get-ItemProperty $_.K -Name $_.V -ErrorAction SilentlyContinue).($_.V)
    [pscustomobject]@{
        Richtlinie = $_.N
        Wert       = $w
        Status     = if ($null -eq $w) { 'nicht konfiguriert' } else { 'konfiguriert' }
    }
} | Format-Table -AutoSize
```

**Lösung 8.** Beispiel: Setzen: Cloud-Zwischenablage aus (Datenabfluss), Diagnosedaten auf „erforderlich“ (mit Hinweis auf Auswirkung auf Update-Berichte), Consumer Experiences aus (auf Enterprise/Education), Werbe-ID aus. Zur Diskussion stellen: Zwischenablageverlauf (je Abteilung), Widgets (je Standort), Sperrbildschirm-Benachrichtigungen (Großraumbüros). Rücksprache nötig: Datenschutzbeauftragter (Diagnosedaten, Verzeichnis der Verarbeitungstätigkeiten), Betriebsrat (wenn Einstellungen Verhaltens- oder Leistungskontrolle berühren könnten, zum Beispiel Diagnose- und Protokolleinstellungen), Fachabteilungen. Dies ist eine technische Vorlage und keine Rechtsberatung.
