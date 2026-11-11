# Modul 05 - Update und Servicing

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Gruppenrichtlinien für Windows 11 – 100 Richtlinien im Detail“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Steckbriefe als Tabellen, Übungsaufgaben und Lösungen als fortlaufend nummerierte Absätze). **Nummerierung:** Die Überschriften der Richtlinien tragen hier die laufende Nummer 1 bis 100 aus der Modultabelle; die Verweise im Text („Abschnitt 43“) meinen diese Nummer. (Im LaTeX-Satz zählen die Überschriften je Modul neu, etwa 5.3.) **Die Beispiele (PowerShell, INF) wurden für dieses Repository nicht ausgeführt**; sie verändern Gruppenrichtlinien, Registry und Sicherheitseinstellungen und gehören nur in eine Testumgebung (Pilot-OU, Testdomäne). Übersicht zum Modul: [README](README.md).

**Dauer:** 10 Unterrichtsstunden (Annahme: 1 Stunde je Richtlinie)  
**Priorität:** 1 bis 3 (fünf Richtlinien mit Priorität 1, vier mit Priorität 2, eine mit Priorität 3)

| Nr. | Lerneinheit (Richtlinie)                      | Prio | Stunden |
|----:|:----------------------------------------------|:----:|:-------:|
|  41 | Windows Update for Business aktivieren        |  1   |    1    |
|  42 | Feature Update Zielversion setzen             |  1   |    1    |
|  43 | Quality Update Deadline setzen                |  1   |    1    |
|  44 | Automatische Neustarts außerhalb Nutzungszeit |  2   |    1    |
|  45 | Treiber nicht automatisch über Windows Update |  2   |    1    |
|  46 | Update Pausen begrenzen                       |  1   |    1    |
|  47 | Delivery Optimization aktivieren              |  2   |    1    |
|  48 | Dual Scan vermeiden                           |  2   |    1    |
|  49 | Update Benachrichtigungen steuern             |  3   |    1    |
|  50 | Safeguard Holds respektieren                  |  1   |    1    |
|     | **Summe**                                     |      | **10**  |

**Worum es in diesem Modul geht.** Ungepatchte Rechner sind der häufigste Einstiegspunkt für Angreifer. Updates dürfen aber auch nicht ungeplant über die Belegschaft hereinbrechen. Dieses Modul zeigt, wie man mit Richtlinien einen *kontrollierten Rhythmus* schafft: Wann bekommt welche Gruppe welches Update (Abschnitte 41 bis 43 und 46), wie wird der Benutzer möglichst wenig gestört (44 und 49), woher kommen Updates und Treiber (45, 47, 48), und wie vermeidet man bekannte Fehlerzustände (50). Die Richtlinien liegen unter Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows Update. Ein Grundwort vorab: *Feature Updates* sind die jährlichen Funktionsupdates (zum Beispiel von 24H2 auf 25H2), *Quality Updates* sind die monatlichen Sicherheits- und Fehlerkorrekturen.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation ist „Windows Update for Business“ der frühere Markenname für die *Windows-Update-Clientrichtlinien*, die in einigen Seiten noch so heißt. Die Richtlinien sind keine eigene Software, sondern eine Sammlung von Einstellungen, die steuern, was der Windows-Update-Client direkt beim Windows-Update-Dienst anfordert. Sie funktionieren per Gruppenrichtlinie und per Intune.

## 41 Windows Update for Business aktivieren

| **Feld**        | **Steckbrief**                                                                                                           |
|:----------------|:-------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows Update \> Windows Update for Business |
| Einstellung     | Update-Richtlinien                                                                                                       |
| Empfehlung      | Nach Ringkonzept                                                                                                         |
| Ziel / Zweck    | Steuert Feature- und Quality-Updates kontrolliert                                                                        |
| Zielbereich     | Computer                                                                                                                 |
| Priorität       | 1                                                                                                                        |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                              |

Der Lehrplan nennt das Ziel „nach Ringkonzept“. Ein *Ring* ist eine Gruppe von Geräten, die Updates zum selben Zeitpunkt erhält. Typisch sind drei Ringe: ein *Pilotring* (IT-Geräte, bekommt Updates sofort), ein *Breitenring* (erste Fachabteilungen, einige Tage später) und ein *Produktionsring* (alle übrigen, nach weiteren Tagen). Der Zeitversatz heißt *Zurückstellung* (englisch *deferral*). Die Microsoft-Dokumentation beschreibt ein Beispiel mit drei Ringen für Qualitätsupdates: Pilot mit 0 Tagen, ein schneller Ring mit 5 Tagen und ein langsamer Ring mit 10 Tagen Zurückstellung. Entdeckt man im Pilotring ein Problem, kann man weitere Ringe anhalten.

Wie viel man zurückstellen kann, legt Microsoft fest: Funktionsupdates bis zu 365 Tage, Qualitätsupdates bis zu 30 Tage. Die Zurückstellung zählt ab dem Freigabedatum des Updates (Angebotsdatum gleich Veröffentlichungsdatum plus Zurückstellung). Zusätzlich kann man Updates *anhalten* (englisch *pause*); eine Pause gilt höchstens 35 Tage ab einem angegebenen Startdatum. Nach dem Ende der Pause wird das *nächste* Qualitätsupdate angeboten. Die zugehörigen Richtlinien heißen „Select when Preview Builds and Feature Updates are Received“ und „Select when Quality Updates are Received“.

> **Merke**
>
> Ringe werden durch Gruppenrichtlinien-Zuordnung gebildet: je Ring eine GPO mit unterschiedlicher Zurückstellung, verknüpft mit einer OU oder per Sicherheitsgruppenfilter. Es gibt kein eigenes „Ring“-Objekt. Wer eine Gruppe von Geräten schneller oder langsamer versorgen will, verschiebt sie in einen anderen Ring.

Das Beispiel erzeugt drei GPOs für die drei Ringe. Die Registrywerte (`DeferQualityUpdates`, `DeferQualityUpdatesPeriodInDays` unter `Software\Policies\Microsoft\Windows\WindowsUpdate`) entsprechen dem Gruppenrichtlinien-Mapping in der Policy-CSP-Dokumentation von Microsoft. Die Schleife läuft nur über die Namen und die Tage; die Verknüpfung mit OUs erfolgt separat.

```ps
Import-Module GroupPolicy
$ringe = @(
    @{ Name = "WU-Ring0-Pilot";      Tage = 0  },
    @{ Name = "WU-Ring1-Breite";     Tage = 5  },
    @{ Name = "WU-Ring2-Produktion"; Tage = 10 }
)
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
foreach ($r in $ringe) {
    $gpo = New-GPO -Name $r.Name
    Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DeferQualityUpdates             -Type DWord -Value 1
    Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DeferQualityUpdatesPeriodInDays -Type DWord -Value $r.Tage
}

# Am Client: welche Werte sind wirksam angekommen?
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" |
    Select-Object DeferQualityUpdates, DeferQualityUpdatesPeriodInDays
```

Die Tabelle `$ringe` beschreibt die drei Ringe. Die Schleife legt je Ring eine GPO an und setzt zwei Werte: den Schalter für die Zurückstellung und die Anzahl der Tage. Auf dem Client zeigt der letzte Befehl, ob der Wert angekommen ist; er liest nur. Die GPOs werden anschließend mit der OU des jeweiligen Rings verknüpft (zum Beispiel mit `New-GPLink`).

**Typische Fehler.** Falsch: alle Geräte in einen Ring zu stecken und die Zurückstellung auf 30 Tage zu setzen, „um sicher zu gehen“. Dann sind alle Geräte einen Monat lang ungepatcht, und ein Problem würde trotzdem alle gleichzeitig treffen. Richtig: ein kleiner Pilotring mit 0 Tagen, der Probleme früh findet. Zweiter Fehler: Zurückstellung zu setzen und zugleich eine Zielversion (Abschnitt 42); laut Microsoft sind Zurückstellungen für Funktionsupdates nicht wirksam, wenn die Zielversion gesetzt ist. Dritter Fehler: Ringe nach Abteilungen statt nach Risiko zu bilden; ein Pilotring ohne repräsentative Hardware und Software findet die Probleme nicht.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Qualitätsupdate stört im Pilotring einen Druckertreiber. Die IT hält den Breitenring und den Produktionsring per Pause an. Erst das nächste Qualitätsupdate, das den Fehler behebt, wird ausgerollt. Ohne Ringe hätten alle 1 200 Rechner das Problem gehabt.

## 42 Feature Update Zielversion setzen

| **Feld**        | **Steckbrief**                                                                                                           |
|:----------------|:-------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows Update \> Windows Update for Business |
| Einstellung     | Zielversion für Funktionsupdates auswählen                                                                               |
| Empfehlung      | Windows 11 25H2 oder Organisationsstandard                                                                               |
| Ziel / Zweck    | Verhindert ungeplante Versionssprünge                                                                                    |
| Zielbereich     | Computer                                                                                                                 |
| Priorität       | 1                                                                                                                        |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                              |

Windows 11 erscheint einmal im Jahr in einer neuen Version, benannt nach Jahr und Halbjahr (etwa 24H2, 25H2). Jede Version wird für eine begrenzte Zeit mit Sicherheitsupdates versorgt (*Lebenszyklus*), danach nicht mehr. Ohne Steuerung bietet Windows Update irgendwann die jeweils neueste Version an. Die Richtlinie „Select the target Feature Update version“ (Zielversion für Funktionsupdates auswählen) legt dagegen fest, bei welcher Version ein Gerät *bleibt*, bis die IT den Wert ändert. Sie schützt damit vor ungeplanten Sprüngen, etwa wenn eine Fachanwendung noch nicht für die neue Version freigegeben ist.

Die Richtlinie hat nach der Microsoft-Dokumentation zwei Eingaben: das Produkt (zum Beispiel „Windows 11“) und die Version (zum Beispiel „25H2“). Registry-seitig heißt der Wert `TargetReleaseVersion` mit den zugehörigen Werten `TargetReleaseVersionInfo` und `ProductVersion` im Schlüssel `Software\Policies\Microsoft\Windows\WindowsUpdate`. Wichtig sind die Randfälle aus der Dokumentation: Gibt man eine Version an, die älter als die aktuelle ist oder ungültig, erhält das Gerät *keine* Funktionsupdates, bis die Richtlinie korrigiert wird. Wird die Zielversion nicht rechtzeitig angehoben und erreicht das Gerät das Ende des Supports, wird es 60 Tage nach Support-Ende automatisch aktualisiert.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft gilt: Wenn die Zielversion-Richtlinie gesetzt ist, sind Zurückstellungen für Funktionsupdates nicht in Kraft. Die Richtlinie dient auch dazu, eine Version zu überspringen. Welche Versionen aktuell erhältlich sind und wann ihr Support endet, ändert sich laufend; der Lehrplan nennt „25H2 oder Organisationsstandard“. Prüfen Sie den Stand vor dem Rollout auf der Microsoft-Seite zur Lebenszyklus-Information der Windows-Versionen (nicht im Rahmen dieser Recherche abgerufen).

Das Beispiel setzt die Zielversion für die Produktionsgruppe. Die Werte entsprechen dem von Microsoft beschriebenen Mapping; die Zeichenfolgen `Windows 11` und `25H2` sind Beispielwerte und anzupassen.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "WU-Zielversion"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName TargetReleaseVersion     -Type DWord  -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName ProductVersion           -Type String -Value "Windows 11"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName TargetReleaseVersionInfo -Type String -Value "25H2"

# Am Client: aktuelle Version und gesetzte Zielversion
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
(Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate").TargetReleaseVersionInfo
```

Die drei Werte aktivieren die Zielversion, nennen das Produkt und die Version. Auf dem Client zeigt die erste Abfrage die installierte Version (`DisplayVersion`), die zweite die vorgegebene Zielversion. Stimmen sie nicht überein, bietet Windows Update das Funktionsupdate an, sobald es verfügbar ist.

**Typische Fehler.** Falsch: die Zielversion einmal zu setzen und zu vergessen. Das Gerät bleibt dann bis zum Supportende stehen, wird 60 Tage danach zwangsweise aktualisiert, und zwar ungeplant. Richtig: ein Kalendereintrag und eine Prüfung der Versionsverteilung vor jedem Supportende. Zweiter Fehler: Tippfehler in der Version (`25h2` oder `Win11`); ein ungültiger Wert blockiert alle Funktionsupdates. Dritter Fehler: Zielversion und Zurückstellung zu mischen und sich zu wundern, dass die Zurückstellung nicht wirkt.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Hersteller von CAD-Software gibt eine neue Windows-Version erst nach zwei Monaten frei. Die IT hält alle Geräte per Zielversion bei der freigegebenen Version und hebt den Wert nach der Herstellerfreigabe zuerst im Pilotring an.

## 43 Quality Update Deadline setzen

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows Update   |
| Einstellung     | Fristen für automatische Updates und Neustarts                                              |
| Empfehlung      | Nach Sicherheitsvorgabe                                                                     |
| Ziel / Zweck    | Sichert zeitnahe Patchinstallation                                                          |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Eine *Frist* (englisch *deadline*) legt fest, wie viele Tage nach dem Angebot eines Updates dieses spätestens installiert sein muss. Danach erzwingt Windows Installation und Neustart, auch während der Nutzungszeit. Die Microsoft-Dokumentation empfiehlt Fristen für Unternehmens- und Bildungsumgebungen ausdrücklich immer: Sie helfen bei der Einhaltung von Vorgaben und halten die Geräte sicher. Eine zweite Zahl, die *Nachfrist* (grace period), gibt dem Benutzer nach der Installation Zeit, den Neustart selbst zu planen, bevor Windows ihn erzwingt.

Seit Windows 11 22H2 ist die Richtlinie laut Microsoft in zwei getrennte Richtlinien aufgeteilt: eine für Qualitätsupdates und eine für Funktionsupdates, jeweils mit Frist (Tage) und Nachfrist (Tage). Den Lehrplan-Eintrag „nach Sicherheitsvorgabe“ muss man selbst mit Zahlen füllen. Eine übliche Vorgabe für Qualitätsupdates ist eine Frist von wenigen Tagen (zum Beispiel 3 bis 7) und eine Nachfrist von 2 Tagen; die Zahlen sind Beispiele aus der Praxis und keine Microsoft-Vorgabe, sie sollten aus der Patch-Policy der Organisation abgeleitet werden. Bei einer Frist von 0 Tagen wird das Update sofort bei Angebot installiert, was laut Microsoft nicht immer am selben Tag abgeschlossen ist.

> **Ergänzung aus der Nachrecherche**
>
> Die Frist wirkt zusammen mit der Zurückstellung (Abschnitt 41): Die Zurückstellung bestimmt, *wann* das Update angeboten wird, die Frist bestimmt, *wann es spätestens installiert sein muss* (gezählt ab dem Angebot). Microsoft weist darauf hin, dass Windows nach Ablauf der Frist Neustarts auch außerhalb der aktiven Stunden durchführt und der Benutzer sie nicht verschieben kann.

Das Beispiel setzt die Fristen für Qualitätsupdates. Die Werte `ConfigureDeadlineForQualityUpdates` und `ConfigureDeadlineGracePeriod` entsprechen den CSP-Namen aus der Microsoft-Dokumentation, die GPO-Registry-Namen sind nach meiner Kenntnis identisch und im Pilot gegen den Editor zu prüfen.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "WU-Fristen-Quality"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
# Frist 5 Tage, Nachfrist 2 Tage (Beispielwerte aus der Patch-Policy ableiten)
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName SetComplianceDeadline            -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName ConfigureDeadlineForQualityUpdates -Type DWord -Value 5
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName ConfigureDeadlineGracePeriod       -Type DWord -Value 2
```

Der erste Wert aktiviert die Fristenkonfiguration, die beiden weiteren setzen die Tage. Eine einmalige Fehlkonfiguration (zum Beispiel Frist 0 und Nachfrist 0) führt dazu, dass Geräte sofort neu starten; vor dem Rollout daher im Pilot testen und die Benutzerkommunikation vorbereiten.

**Typische Fehler.** Falsch: Frist und Nachfrist auf 0 zu stellen. Rechner starten dann mitten in einer Präsentation neu. Richtig: mindestens ein bis zwei Tage Nachfrist. Zweiter Fehler: Fristen zu setzen und Geräte, die tagelang ausgeschaltet sind (Urlaub), nicht zu bedenken; sie installieren beim ersten Einschalten sofort und starten neu. Dritter Fehler: die Fristen nur für Qualitätsupdates zu setzen und Funktionsupdates zu vergessen; für sie gibt es eine eigene Richtlinie.

> **Praxisbeispiel**
>
> Beispielszenario: Eine kritische Sicherheitslücke wird aktiv ausgenutzt. Dank Frist von fünf Tagen sind alle Geräte, die im Büro oder im VPN erreichbar sind, nach einer Woche gepatcht. Die Auswertung zeigt nur Geräte, die länger offline waren.

## 44 Automatische Neustarts außerhalb Nutzungszeit

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows Update   |
| Einstellung     | Automatische Neustarts während Nutzungszeit verhindern                                      |
| Empfehlung      | Aktiviert                                                                                   |
| Ziel / Zweck    | Reduziert Benutzerunterbrechung                                                             |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Nach der Installation vieler Updates ist ein Neustart nötig. Wann Windows ihn ausführt, hängt von den *aktiven Stunden* (englisch *active hours*) ab: Zeitfenster, in denen der Benutzer den Rechner nutzt und kein automatischer Neustart erfolgen soll. Die Richtlinie „Turn off auto-restart for updates during active hours“ bewirkt, dass Windows in diesem Fenster nicht automatisch neu startet. Der Lehrplan spricht von „Aktiviert“; auch hier gilt: Es ist eine Richtlinie, die etwas *abschaltet* (den Neustart während der Nutzung), „Aktiviert“ schaltet den Schutz also ein.

Die Microsoft-Dokumentation liefert dazu einen wichtigen Hinweis, der dem Lehrplan teilweise widerspricht: Man solle sich mit dem Setzen der aktiven Stunden zurückhalten, denn die Funktion ist standardmäßig aktiv (*intelligente aktive Stunden*), solange automatische Updates nicht deaktiviert sind, und bietet eine bessere Erfahrung, wenn Benutzer ihre aktiven Stunden selbst festlegen können. Es gibt außerdem die Richtlinie „Specify active hours range for auto restart“, die den maximalen Zeitraum begrenzt, den der Benutzer als aktive Zeit eintragen kann. Für die meisten Büroumgebungen ist daher die beste Wahl: die Standardlogik von Windows nicht zu stören und stattdessen sinnvolle Fristen (Abschnitt 43) zu setzen.

> **Merke**
>
> Aktive Stunden sind ein Komfort für den Benutzer, kein Sicherheitsmerkmal. Nach Ablauf einer Frist (Abschnitt 43) startet Windows auch während der aktiven Stunden neu. Wer hier zu strikt konfiguriert, verlängert nur die Zeit bis zum Patch.

Das Beispiel setzt die Richtlinie für ein Gerät mit festen Arbeitszeiten (Büro 7 bis 19 Uhr). Die Werte `SetActiveHours`, `ActiveHoursStart` und `ActiveHoursEnd` stammen aus meiner Kenntnis der ADMX-Vorlage und sind im Pilot zu prüfen. Für Geräte im Mehrschichtbetrieb sind feste Zeiten ungeeignet.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "WU-AktiveStunden"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName SetActiveHours   -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName ActiveHoursStart -Type DWord -Value 7
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName ActiveHoursEnd   -Type DWord -Value 19

# Am Client: werden Neustarts erwartet?
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue
```

Die ersten Werte aktivieren die Richtlinie und legen das Fenster fest (7 bis 19 Uhr). Der Schlüssel `RebootRequired` existiert, solange ein Neustart aussteht; die Abfrage ist ein einfacher Hinweis, kein offizielles Statusmittel.

**Typische Fehler.** Falsch: aktive Stunden auf 18 Stunden zu setzen, damit nie ein Neustart stört. Windows akzeptiert größere Bereiche nicht, und der Rechner startet dann trotzdem außerhalb. Richtig: realistische Zeiträume. Zweiter Fehler: Server oder 24/7-Geräte (Kioske, Produktionsrechner) mit denselben aktiven Stunden zu behandeln; sie brauchen eigene Wartungsfenster. Dritter Fehler: Neustarts ganz zu unterbinden (zum Beispiel „Kein automatischer Neustart bei angemeldeten Benutzern“) und zu übersehen, dass Updates dann unwirksam bleiben, bis jemand neu startet.

> **Praxisbeispiel**
>
> Beispielszenario: In einer Arztpraxis laufen Rechner den ganzen Tag. Weil Windows die Nutzungsmuster lernt, startet es nachts neu. Die IT setzt nur eine Frist von sieben Tagen; aktive Stunden werden nicht vorgegeben.

## 45 Treiber nicht automatisch über Windows Update

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows Update   |
| Einstellung     | Keine Treiber in Windows-Updates einschließen                                               |
| Empfehlung      | Nach Treiberstrategie                                                                       |
| Ziel / Zweck    | Verhindert ungeplante Treiberwechsel                                                        |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Neben Sicherheitsupdates liefert Windows Update auch *Treiber* für Hardware: Grafikkarten, Netzwerkadapter, Firmware. Das ist bequem für Privatgeräte, in Unternehmen aber ein Risiko, weil ein neuer Treiber das Verhalten ändern kann. Die Microsoft-Dokumentation sagt dazu: Treiberupdates sind standardmäßig aktiviert, weil sie dem System nützen; Microsoft empfiehlt, sie erlaubt zu lassen, bietet aber die Richtlinie „Do not include drivers with Windows Updates“ (Keine Treiber in Windows-Updates einschließen), falls man Treiber lieber manuell verwaltet. Das ist die Richtlinie dieses Abschnitts. Aktiviert man sie, kommen Treiber nicht mehr über Windows Update.

Der Lehrplan formuliert „nach Treiberstrategie“. Gemeint ist: Man entscheidet bewusst, wer die Treiber liefert. Mögliche Strategien sind: Windows Update liefert alles (einfach, aber weniger Kontrolle), die IT verteilt Treiber über Hersteller-Katalogwerkzeuge oder Softwareverteilung (viel Kontrolle, viel Aufwand), oder ein Mischmodell, bei dem nur kritische Gerätegruppen ausgenommen sind. Die Microsoft-Dokumentation zur Scan-Quelle erlaubt außerdem, Treiber gezielt aus Windows Update oder WSUS zu beziehen (Abschnitt 48).

> **Ergänzung aus der Nachrecherche**
>
> Der Registrywert der Richtlinie heißt nach der Microsoft-Dokumentation `ExcludeWUDriversInQualityUpdate` im Schlüssel `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`; er taucht in der Liste der Altwerte auf, die man bei Bereinigungen von Update-Konfigurationen prüft. Wer Treiber ausschließt, muss Firmware- und Treiberupdates für Sicherheitslücken trotzdem selbst im Blick behalten.

Das folgende Beispiel schaltet die Treiber aus und zeigt, wie man am Client prüft, welche Treiber installiert sind und von wem. `Get-CimInstance Win32_PnPSignedDriver` ist ein Standardbefehl; er liest nur.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "WU-Treiber-aus"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
    -ValueName ExcludeWUDriversInQualityUpdate -Type DWord -Value 1

# Inventur: Treiber mit Hersteller und Datum, aelteste zuerst
Get-CimInstance Win32_PnPSignedDriver |
    Where-Object DriverDate |
    Sort-Object DriverDate |
    Select-Object -First 15 DeviceName, Manufacturer, DriverVersion, DriverDate
```

Der Wert 1 schließt Treiber aus den Qualitätsupdates aus. Die Inventur listet die ältesten Treiber; so sieht man, wo ohne Windows Update Handlungsbedarf entsteht, etwa wenn ein Treiber seit Jahren nicht aktualisiert wurde.

**Typische Fehler.** Falsch: Treiber auszuschließen und danach nie wieder zu aktualisieren. Geräte bleiben dann dauerhaft mit alten, möglicherweise unsicheren Treibern. Richtig: einen festen Prozess (zum Beispiel vierteljährlich) für Treiber und Firmware. Zweiter Fehler: nur die Windows-Update-Seite zu beachten; Hersteller-Updatewerkzeuge (zum Beispiel von Notebookherstellern) können weiterhin Treiber installieren. Dritter Fehler: die Richtlinie auf Geräten zu setzen, die Treiber nur über Windows Update erhalten (etwa Kleingeräte ohne Herstellersoftware).

> **Praxisbeispiel**
>
> Beispielszenario: Ein Treiber für den WLAN-Adapter eines Notebook-Modells verursacht Verbindungsabbrüche. Dank der Richtlinie kommt er nicht automatisch auf die Flotte; die IT testet die neue Version zuerst im Pilotring und verteilt sie dann gezielt.

## 46 Update Pausen begrenzen

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows Update   |
| Einstellung     | Pausen für Updates begrenzen                                                                |
| Empfehlung      | Nach Governance                                                                             |
| Ziel / Zweck    | Verhindert dauerhaft ungepatchte Clients                                                    |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

In den Windows-Einstellungen kann ein Benutzer Updates mit einem Klick pausieren. Für Privatgeräte ist das sinnvoll, für Unternehmensgeräte ein Risiko: Wer die Pause immer wieder verlängert, bleibt ungepatcht. Die Richtlinie „Remove access to Pause updates feature“ (nach meiner Kenntnis `SetDisablePauseUXAccess`) entfernt die Schaltfläche. Davon zu unterscheiden ist die zentrale Pause, die ein Administrator über die Richtlinie „Select when Quality Updates are Received“ setzt: Sie gilt laut Microsoft höchstens 35 Tage ab dem Startdatum und eignet sich als Notbremse für alle Ringe, wenn ein Update Probleme macht.

Der Lehrplan formuliert „nach Governance“. Gemeint ist, dass die Organisation festlegen muss, wer pausieren darf und wie lange. Üblich ist: Benutzer dürfen nicht pausieren, die IT darf zentral anhalten, und eine Pause wird dokumentiert (Ticket, Grund, Ende). Bei langen Pausen empfiehlt sich eine Überwachung: Ein Bericht, der Geräte mit lange nicht installierten Updates zeigt, erlaubt es, Verstöße gegen die Governance früh zu erkennen. Nach Microsoft läuft eine zentral gesetzte Pause nach 35 Tagen oder beim Löschen des Eintrags ab.

> **Merke**
>
> Zwei Arten von Pause: Die *Benutzerpause* in der Oberfläche (per Richtlinie ausblendbar) und die *Administratorpause* in der Richtlinie (35 Tage, zentral). Wer Pausen begrenzen will, blendet die erste aus und nutzt die zweite nur mit Dokumentation.

Das Beispiel blendet die Benutzerpause aus und zeigt, wie man eine zentrale Pause für Qualitätsupdates mit Startdatum setzt. Die Werte `PauseQualityUpdatesStartTime` und `PauseQualityUpdates` stehen in der Liste der Altwerte der Microsoft-Dokumentation. Das Datumsformat (hier `yyyy-MM-dd`) ist nach meiner Kenntnis zu verwenden und im Pilot zu prüfen.

```ps
Import-Module GroupPolicy
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

# 1) Benutzerpause ausblenden
$g1 = New-GPO -Name "WU-KeinePauseUI"
Set-GPRegistryValue -Name $g1.DisplayName -Key $key -ValueName SetDisablePauseUXAccess -Type DWord -Value 1

# 2) Notbremse: zentrale Pause fuer Qualitaetsupdates ab heute (max. 35 Tage)
$g2 = New-GPO -Name "WU-NotbremseQuality"
Set-GPRegistryValue -Name $g2.DisplayName -Key $key -ValueName PauseQualityUpdates -Type DWord -Value 1
Set-GPRegistryValue -Name $g2.DisplayName -Key $key -ValueName PauseQualityUpdatesStartTime -Type String `
    -Value (Get-Date -Format "yyyy-MM-dd")
```

Die erste GPO blendet die Pause-Schaltfläche aus. Die zweite GPO ist die Notbremse; sie wird nur dann mit einem Ring verknüpft, wenn ein Update Probleme macht, und wieder entfernt, wenn der Fehler behoben ist. Trennt man die beiden GPOs, bleibt die Dauerkonfiguration (keine Benutzerpause) von der vorübergehenden (Notbremse) sauber getrennt.

**Typische Fehler.** Falsch: die Notbremse zu setzen und zu vergessen. Nach 35 Tagen läuft die Pause ab, und alle Geräte installieren plötzlich Updates für mehrere Wochen auf einmal. Richtig: Pause im Kalender mit Enddatum versehen. Zweiter Fehler: die Benutzerpause auszublenden und den Benutzern keine Alternative zu bieten (zum Beispiel Verschieben des Neustarts); Beschwerden und Umgehungen sind die Folge. Dritter Fehler: eine Pause einzurichten, um ein Problem zu beheben, das eigentlich ein Treiber- oder Anwendungsproblem ist, das gezielt gelöst werden sollte.

> **Praxisbeispiel**
>
> Beispielszenario: Während einer wichtigen Messewoche möchte der Vertrieb keine Neustarts. Statt jedem Benutzer die Pause zu erlauben, setzt die IT zentral eine Pause für den Vertriebsring und legt das Enddatum fest. Danach läuft alles planmäßig weiter.

## 47 Delivery Optimization aktivieren

| **Feld**        | **Steckbrief**                                                                                   |
|:----------------|:-------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Delivery Optimization |
| Einstellung     | Downloadmodus                                                                                    |
| Empfehlung      | LAN/Group nach Standortkonzept                                                                   |
| Ziel / Zweck    | Reduziert WAN-Last bei Updates                                                                   |
| Zielbereich     | Computer                                                                                         |
| Priorität       | 2                                                                                                |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.      |

Wenn tausend Rechner dasselbe Update von Microsoft herunterladen, geht dieselbe Datei tausendmal durch die Internetleitung. *Delivery Optimization* (DO) vermeidet das, indem Geräte Teile von Updates untereinander austauschen (*Peer-to-Peer*, P2P), sodass nur wenige Geräte aus dem Internet laden. Der Download kommt dabei aus mehreren Quellen: Microsoft-Server, Peers im Netz und gegebenenfalls ein *Microsoft Connected Cache*. Wichtig für die Sicherheit: Delivery Optimization prüft die Teile kryptografisch; Peers können Inhalte nicht manipulieren. Das ist meine Kenntnis aus der Architektur, in den abgerufenen Seiten steht dazu nichts Näheres.

Die zentrale Einstellung ist der *Downloadmodus*. Laut Microsoft-Dokumentation gibt es: HTTP only (0, kein Peering), LAN (1, Standard; Geräte hinter derselben öffentlichen IP-Adresse), Group (2, Peers innerhalb einer Gruppe, auch über Subnetze und Standorte hinweg), Internet (3) und 99 (einfacher HTTP-Download ohne weitere Prüfung). Der Gruppenmodus ist laut Microsoft für die meisten Organisationen die empfohlene Option, wenn die Bandbreitenoptimierung im Vordergrund steht. Die Gruppe ergibt sich standardmäßig aus dem AD-Standort, dann aus der SID der authentifizierten Domäne, dann aus der Entra-Mandanten-ID; man kann sie auch mit einer eigenen GUID (`DOGroupID`) festlegen. Bei einer Hub-and-Spoke-Struktur empfiehlt Microsoft, die Peerauswahl zusätzlich auf das Subnetz zu beschränken.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft liegt die Delivery-Optimization-Richtlinie unter Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Delivery Optimization. In Windows 11 beschränkt der Modus LAN (1) die Peers standardmäßig auf das lokale Subnetz; eine neue Option „Local Peer Discovery“ (DNS-SD/mDNS) steht in MDM und Gruppenrichtlinie zur Verfügung. Wer VPN-Peering vermeiden will, sollte die Dokumentation zu VPN-Einstellungen prüfen.

Das folgende Beispiel richtet den Gruppenmodus mit eigener Gruppen-ID ein und liest danach mit den von Microsoft dokumentierten Cmdlets den Status. `Get-DeliveryOptimizationStatus` zeigt, wie viel Prozent aus Peers kamen. Die Registrynamen (`DODownloadMode`, `DOGroupId`) entsprechen den MDM-Namen; im Schlüssel `Software\Policies\Microsoft\Windows\DeliveryOptimization` (nach meiner Kenntnis, im Pilot zu prüfen).

```ps
Import-Module GroupPolicy
$gpo  = New-GPO -Name "DO-Gruppenmodus"
$key  = "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
$guid = [guid]::NewGuid().ToString()          # eine GUID je Standort
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DODownloadMode -Type DWord  -Value 2
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DOGroupId      -Type String -Value $guid

# Am Client: was kam von Peers?
Get-DeliveryOptimizationStatus |
    Select-Object FileId, Status, PercentPeerCaching, BytesFromPeers, BytesFromHttp
Get-DeliveryOptimizationPerfSnapThisMonth
```

Die GUID wird je Standort erzeugt und in der GPO des Standorts eingetragen; alle Geräte mit derselben GUID bilden eine Peergruppe. Die Statusabfrage zeigt pro Datei, wie viele Bytes aus Peers beziehungsweise aus dem Internet kamen. Das Cmdlet `Get-DeliveryOptimizationPerfSnapThisMonth` fasst die Monatswerte zusammen.

**Typische Fehler.** Falsch: Gruppenmodus ohne passende Gruppen: Alle Geräte haben dieselbe GUID, auch über WAN-Strecken hinweg. Die Peers laden dann quer durch das Firmennetz. Richtig: eine Gruppe je Standort oder AD-Site. Zweiter Fehler: Delivery Optimization einzuschalten und die Firewall zu vergessen; die Peers brauchen Verbindungen untereinander (Port 7680, nach meiner Kenntnis; bei NAT zudem Teredo, laut Microsoft Port 3544). Dritter Fehler: P2P in Netzen mit Schutzbedarf einzusetzen, ohne das Sicherheitskonzept zu prüfen. Wer P2P ablehnt, wählt Modus 0.

> **Praxisbeispiel**
>
> Beispielszenario: Eine Filiale mit 40 Rechnern und einer dünnen Leitung. Mit dem Gruppenmodus lädt nur ein Bruchteil der Geräte aus dem Internet, die übrigen holen die Teile von den Nachbarn. Das Update ist früher fertig, und die Leitung bleibt für die Arbeit frei.

## 48 Dual Scan vermeiden

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows Update   |
| Einstellung     | Keine Verbindung mit Windows Update Internetadressen herstellen                             |
| Empfehlung      | Nur bei WSUS-only Konzept aktivieren                                                        |
| Ziel / Zweck    | Verhindert unkontrollierte Updatequellen                                                    |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

*WSUS* (Windows Server Update Services) ist der Update-Server im eigenen Netz: Die Organisation genehmigt Updates dort, und die Clients holen sie vom internen Server statt aus dem Internet. *Dual Scan* bezeichnet einen Zustand, in dem ein Client ungewollt *zwei* Quellen befragt: den WSUS und zusätzlich Windows Update im Internet. Es entsteht, wenn auf einem WSUS-verwalteten Gerät gleichzeitig Zurückstellungs- oder Pause-Richtlinien (Abschnitt 41, 46) gesetzt sind. Die Folge: Funktions- und Qualitätsupdates kommen aus dem Internet, an der Genehmigung vorbei. Laut Microsoft ist das das häufige Muster des „unbeabsichtigten Dual Scan“.

Der Lehrplan-Eintrag verlangt hier Sorgfalt, denn Name und Richtlinie passen nicht zusammen. Die Richtlinie „Do not connect to any Windows Update Internet locations“ (Keine Verbindung mit Windows Update Internetadressen herstellen) verbietet dem Client jeden Zugriff auf das Internet-Windows-Update, auch für Treiber oder optionale Funktionen. Sie gehört in ein striktes WSUS-only-Konzept, *nicht* aber zu „Dual Scan vermeiden“ im engeren Sinn. Die Richtlinie, die Microsoft Dual Scan nennt, heißt „Do not allow update deferral policies to cause scans against Windows Update“ (`DisableDualScan`). Laut Microsoft ist sie unter Windows 11 nicht mehr unterstützt, auf Windows 10 wurde sie durch die *Richtlinie für die Scan-Quelle* ersetzt und wird nicht empfohlen; setzt man auf Windows 10 beide, erhält man keine Updates von Windows Update.

> **Ergänzung aus der Nachrecherche**
>
> Die Scan-Quelle (ab Windows 10 Version 2004 und Windows 11) legt für vier Update-Arten fest, ob sie von WSUS oder von Windows Update kommen: Funktionsupdates, Qualitätsupdates, Treiber und Updates für andere Microsoft-Produkte. Microsoft nennt sie die einzig relevanten Einstellungen dafür, woher Updates kommen, zusammen mit der Frage, ob ein WSUS-Server konfiguriert ist. Ohne konfigurierte Richtlinien kommen alle Updates von Windows Update. Zu beachten ist: Auf WSUS-Geräten ohne Scan-Quelle kann der Benutzer über „Online nach Updates suchen“ die optionale Aktualisierung auf Windows 11 angeboten bekommen; Microsoft empfiehlt, die Scan-Quelle oder eine Angebotsrichtlinie zu konfigurieren.

Das Beispiel stellt zwei Dinge gegenüber: die strikte WSUS-only-Variante und die Prüfung auf Altlasten, die Microsoft zum Entfernen empfiehlt. Die Prüfung ist unkritisch; sie listet nur Werte, die aus der Microsoft-Liste der Altwerte stammen (Zurückstellung, Pause, `DisableDualScan`). Die Richtlinie `DoNotConnectToWindowsUpdateInternetLocations` ist aus meiner Kenntnis (WSUS-only), der Name im Pilot gegen den Editor zu prüfen.

```ps
# Variante A (nur bei striktem WSUS-Konzept): kein Zugriff auf Internet-Windows-Update
Import-Module GroupPolicy
$gpo = New-GPO -Name "WU-WSUS-only"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
    -ValueName DoNotConnectToWindowsUpdateInternetLocations -Type DWord -Value 1

# Variante B: Altlasten finden, die unbeabsichtigten Dual Scan verursachen
$wu = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$alt = 'DeferFeatureUpdates','DeferFeatureUpdatesPeriodInDays','DeferQualityUpdates',
       'DeferQualityUpdatesPeriodInDays','PauseFeatureUpdates','PauseFeatureUpdatesStartTime',
       'PauseQualityUpdates','PauseQualityUpdatesStartTime','DeferUpgrade','DisableDualScan'
$p = Get-ItemProperty $wu -ErrorAction SilentlyContinue
$alt | Where-Object { $p -and $null -ne $p.$_ } | ForEach-Object { "{0} = {1}" -f $_, $p.$_ }
```

Variante A schottet den Client vom Internet-Windows-Update ab. Variante B vergleicht die vorhandenen Werte mit der Liste der Altwerte aus der Microsoft-Dokumentation und gibt gefundene Einträge aus. Ein Treffer bei WSUS-Geräten ist ein Hinweis auf unbeabsichtigten Dual Scan.

**Typische Fehler.** Falsch: „Keine Verbindung mit Windows Update Internetadressen“ zu setzen und gleichzeitig zu erwarten, dass Features on Demand, Sprachpakete oder Treiber funktionieren; sie scheitern dann (laut Microsoft kommen sie aus Windows Update). Richtig: bewusst entscheiden, was aus dem Internet kommen darf, und die Scan-Quelle nutzen. Zweiter Fehler: auf Windows 11 `DisableDualScan` zu setzen und eine Wirkung zu erwarten; laut Microsoft ist der Schalter dort wirkungslos. Dritter Fehler: Zurückstellungen auf WSUS-Geräten zu setzen, ohne zu wissen, dass sie die Updatequelle verändern.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Betrieb nutzt WSUS mit Genehmigung. Ein Administrator setzt auf einer GPO versehentlich eine Zurückstellung für Qualitätsupdates. Von da an holen die Geräte Updates direkt von Microsoft, an der Genehmigung vorbei. Das Skript zur Altlastensuche deckt den Fehler auf.

## 49 Update Benachrichtigungen steuern

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows Update   |
| Einstellung     | Benachrichtigungsoptionen für Updates                                                       |
| Empfehlung      | Nach Benutzerkommunikation                                                                  |
| Ziel / Zweck    | Verbessert Akzeptanz und Planbarkeit                                                        |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 3                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Windows zeigt Meldungen, wenn Updates bereitstehen oder ein Neustart ansteht. Die Richtlinie „Display options for update notifications“ steuert, wie viele davon der Benutzer sieht. Laut Microsoft gibt es drei Werte: 0 (Standard, Windows-Standardbenachrichtigungen), 1 (alle Benachrichtigungen außer Neustartwarnungen ausschalten) und 2 (alle Benachrichtigungen einschließlich Neustartwarnungen ausschalten). Microsoft empfiehlt ausdrücklich, die Standardbenachrichtigungen zu verwenden, weil sie die beste Benutzererfahrung bieten und sich an die gesetzten Compliance-Richtlinien anpassen. Option 2 ist nur für Kioskgeräte empfohlen, bei denen automatische Neustarts deaktiviert sind.

Ab Windows 11 22H2 gibt es laut Microsoft zusätzlich die Option „Apply only during active hours“: Dann werden die Meldungen nur in den aktiven Stunden unterdrückt, und nach Erreichen einer Frist (Abschnitt 43) erscheint trotzdem eine Meldung. Die Richtlinie „Configure auto-restart reminder notifications for updates“ (Erinnerungszeitraum 2 bis 24 Stunden, Standard 4) ist laut Microsoft ein Altwert und für Windows 11 nicht anwendbar. Der Lehrplan verweist auf „Benutzerkommunikation“: Die technische Einstellung ist die kleinere Aufgabe; wichtig ist, dass Benutzer wissen, wann Updates kommen und was zu tun ist.

> **Merke**
>
> Weniger Meldungen sind nicht automatisch besser. Wer Meldungen unterdrückt, verlangt, dass Fristen, Pausen und Neustartzeiten gut kommuniziert sind. Sonst startet der Rechner scheinbar ohne Vorwarnung neu.

Das Beispiel setzt für Kioskgeräte die Unterdrückung aller Meldungen. Der Registrywert `SetUpdateNotificationLevel` mit `UpdateNotificationLevel` stammt aus meiner Kenntnis der ADMX-Vorlage; die Werte 0, 1 und 2 sind dokumentiert. Für normale Büro-PCs wird die Richtlinie nicht gesetzt.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "WU-Kiosk-Meldungen-aus"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName SetUpdateNotificationLevel -Type DWord -Value 1
# 0 = Standard, 1 = alle ausser Neustartwarnungen aus, 2 = alle aus (nur Kioske ohne Autoneustart)
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName UpdateNotificationLevel    -Type DWord -Value 2
```

Der erste Wert schaltet die Konfiguration ein, der zweite wählt die Stufe. Die Beispielkonfiguration entspricht dem Kiosk-Fall, den Microsoft nennt; sie sollte nur auf Geräten ohne Benutzer eingesetzt werden, deren Neustarts anderweitig geplant sind.

**Typische Fehler.** Falsch: alle Meldungen für Büro-PCs abzuschalten, „damit niemand gestört wird“. Die Benutzer werden dann von Neustarts überrascht und rufen den Helpdesk an. Richtig: Standard belassen und stattdessen Fristen und Kommunikation planen. Zweiter Fehler: Altrichtlinien zu verwenden, die laut Microsoft für Windows 11 nicht mehr gelten. Dritter Fehler: die technische Einstellung als Ersatz für die Kommunikation anzusehen; ein kurzer Hinweis im Intranet vor dem Patchtag wirkt besser als jede Richtlinie.

> **Praxisbeispiel**
>
> Beispielszenario: Vor dem monatlichen Patchtag verschickt die IT eine kurze Nachricht: „Speichern Sie Ihre Arbeit; Neustarts erfolgen nachts, spätestens nach fünf Tagen auch tagsüber.“ Die Richtlinie bleibt auf Standard; die Rückfragen sinken spürbar.

## 50 Safeguard Holds respektieren

| **Feld**        | **Steckbrief**                                                                                                           |
|:----------------|:-------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows Update \> Windows Update for Business |
| Einstellung     | Safeguards für Funktionsupdates deaktivieren                                                                             |
| Empfehlung      | Deaktiviert                                                                                                              |
| Ziel / Zweck    | Vermeidet bekannte Kompatibilitätsprobleme                                                                               |
| Zielbereich     | Computer                                                                                                                 |
| Priorität       | 1                                                                                                                        |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                              |

Ein *Safeguard Hold* (Schutzsperre) ist eine Sperre, die Microsoft für ein bestimmtes Gerät setzt, wenn bekannt ist, dass ein Funktionsupdate dort Probleme macht, etwa wegen eines inkompatiblen Treibers oder einer Anwendung. Das Gerät bekommt das Update dann nicht angeboten, bis das Problem behoben ist. Die Richtlinie „Disable safeguards for Feature Updates“ (Safeguards für Funktionsupdates deaktivieren) erlaubt, diese Sperren zu umgehen. Der Lehrplan empfiehlt „Deaktiviert“, also die Sperren zu *respektieren* (Standardverhalten): Eine gesperrte Maschine bleibt auf der bekannten, funktionierenden Version.

Warum existiert die Umgehung überhaupt? Für Testzwecke: Wer wissen will, ob ein Problem tatsächlich auftritt, oder wer ein Gerät in einer Laborumgebung bewusst auf die neue Version heben will, kann damit das Update erzwingen. Das gehört in einen Testring, nie in den Produktionsring. Wichtig ist auch der Zusammenhang mit der Zielversion (Abschnitt 42): Hat man die Zielversion gesetzt, bleibt ein Safeguard Hold trotzdem wirksam; ein Gerät, das gesperrt ist, kommt nicht auf die Zielversion, auch wenn die Richtlinie es verlangt. Diese Aussage beruht auf meiner Kenntnis des Verhaltens und sollte im Pilot bestätigt werden.

> **Ergänzung aus der Nachrecherche**
>
> Die Einstellung ist nach meiner Kenntnis unter Windows Update for Business zu finden; der Registrywert heißt `DisableWUfBSafeguards` unter `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`. Microsoft bietet für Berichte über Sperren unter anderem die Update-Compliance-Auswertungen (im Rahmen der Intune-/Autopatch-Berichte); der aktuelle Stand dieser Berichte wurde nicht abgerufen.

Das Beispiel stellt sicher, dass die Umgehung nicht gesetzt ist: Es schreibt „0“ in die GPO und prüft auf dem Client, ob ein früher gesetzter Wert vorhanden ist. Beides ist im Pilot gegen den Editor zu prüfen.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "WU-Safeguards-respektieren"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
    -ValueName DisableWUfBSafeguards -Type DWord -Value 0

# Am Client: wurde die Umgehung irgendwo gesetzt (GPO, Skript, Testring)?
$p = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction SilentlyContinue
if ($p -and $p.DisableWUfBSafeguards -eq 1) { "ACHTUNG: Safeguards deaktiviert" } else { "ok" }
```

Der Wert 0 in der GPO stellt das Standardverhalten sicher; die Prüfung am Client gibt eine Warnung aus, wenn irgendwo die Umgehung aktiv ist. Das ist wichtig, weil ein in einer Testumgebung gesetzter Wert unbemerkt in die Produktion übernommen werden kann.

**Typische Fehler.** Falsch: die Umgehung zu aktivieren, „weil das Update nicht kommt“. Das Update fehlt aus gutem Grund. Richtig: die Ursache (Treiber, Anwendung) beheben. Zweiter Fehler: die Umgehung im Produktionsring *und* den Pilotring in dieselbe GPO zu setzen. Dritter Fehler: nicht nachzuprüfen, warum Geräte eine Sperre haben; langfristig gehört eine Liste der gesperrten Geräte zum Monitoring.

> **Praxisbeispiel**
>
> Beispielszenario: Auf 30 Geräten wird die neue Version nicht angeboten. Die Analyse zeigt eine Schutzsperre wegen eines älteren Speichertreibers. Nach dem Treiberupdate hebt Microsoft die Sperre auf, und das Funktionsupdate wird planmäßig ausgerollt.

## Übungsaufgaben zu Modul 05

**Aufgabe 1.** **(leicht)** Erklären Sie den Unterschied zwischen Feature Updates und Quality Updates sowie zwischen Zurückstellung und Pause.

**Aufgabe 2.** **(leicht)** Was bewirkt die Richtlinie „Select the target Feature Update version“, und was passiert bei einer ungültigen Version?

**Aufgabe 3.** **(leicht)** Warum empfiehlt Microsoft, aktive Stunden nicht zu setzen, und welche Einstellung hat stattdessen Vorrang für die Sicherheit?

**Aufgabe 4.** **(mittel)** Erklären Sie den Zusammenhang zwischen Zurückstellung, Frist und Nachfrist an einem Zahlenbeispiel.

**Aufgabe 5.** **(mittel)** Was ist Dual Scan, wie entsteht er unbeabsichtigt, und warum ist `DisableDualScan` unter Windows 11 wirkungslos?

**Aufgabe 6.** **(praktisch)** Schreiben Sie ein Skript, das drei Update-Ringe mit Zurückstellungen von 0, 7 und 14 Tagen als GPOs erstellt und je eine Sicherheitsgruppe per `Set-GPPermission` als Filter einträgt.

**Aufgabe 7.** **(praktisch)** Schreiben Sie ein Skript, das auf einem Client alle Altwerte der Update-Konfiguration (Zurückstellung, Pause, `DisableDualScan`, `DisableWUfBSafeguards`) ausliest und als Tabelle ausgibt.

**Aufgabe 8.** **(schwer)** Entwerfen Sie ein Update-Konzept für 3 000 Geräte an fünf Standorten: Ringe, Fristen, Zielversion, Delivery-Optimization-Gruppen, Notbremse, Kommunikation.

## Lösungen zu Modul 05

**Lösung 1.** Feature Updates bringen eine neue Windows-Version (jährlich), Quality Updates sind monatliche Sicherheits- und Fehlerkorrekturen. Zurückstellung verschiebt das Angebot um eine feste Zahl von Tagen ab Veröffentlichung (Features bis 365, Quality bis 30 Tage); eine Pause hält Updates an, höchstens 35 Tage ab dem Startdatum.

**Lösung 2.** Das Gerät bleibt bei der angegebenen Version. Ist die Version älter als die aktuelle oder ungültig, erhält das Gerät keine Funktionsupdates, bis die Richtlinie korrigiert wird. Zurückstellungen für Funktionsupdates sind dann nicht wirksam. 60 Tage nach Supportende wird das Gerät automatisch aktualisiert.

**Lösung 3.** Die Standardlogik (intelligente aktive Stunden) ist besser als feste Zeiten, weil sie sich am Nutzungsverhalten orientiert. Für die Sicherheit entscheidet die Frist (Abschnitt 43): Nach ihrem Ablauf wird auch während der aktiven Stunden neu gestartet.

**Lösung 4.** Beispiel: Release am 1. des Monats, Zurückstellung 5 Tage, Frist 5 Tage, Nachfrist 2 Tage. Angebot am 6., spätestens Installation bis zum 11., der Neustart ist danach bis zum 13. frei planbar, dann wird er erzwungen. Für den Pilotring (0 Tage) gelten dieselben Fristen, beginnen aber am 1.

**Lösung 5.** Dual Scan: Ein WSUS-verwaltetes Gerät befragt zusätzlich Windows Update. Entsteht, wenn Zurückstellungs- oder Pause-Richtlinien (oder die Scan-Quelle mit „Windows Update“) gesetzt sind. Unter Windows 11 wird der Schalter `DisableDualScan` laut Microsoft nicht mehr ausgewertet; man muss die Zurückstellungen selbst entfernen und die Scan-Quelle nutzen.

```ps
# Loesung 6
Import-Module GroupPolicy
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$ringe = @(@{N="WU-R0";T=0;G="GG-WU-R0"},@{N="WU-R1";T=7;G="GG-WU-R1"},@{N="WU-R2";T=14;G="GG-WU-R2"})
foreach ($r in $ringe) {
    $g = New-GPO -Name $r.N
    Set-GPRegistryValue -Name $g.DisplayName -Key $key -ValueName DeferQualityUpdates -Type DWord -Value 1
    Set-GPRegistryValue -Name $g.DisplayName -Key $key -ValueName DeferQualityUpdatesPeriodInDays -Type DWord -Value $r.T
    Set-GPPermission -Name $g.DisplayName -TargetName $r.G -TargetType Group -PermissionLevel GpoApply
    Set-GPPermission -Name $g.DisplayName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoRead -Replace
}
```

```ps
# Loesung 7
$wu = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$namen = 'DeferFeatureUpdates','DeferFeatureUpdatesPeriodInDays','DeferQualityUpdates',
         'DeferQualityUpdatesPeriodInDays','PauseFeatureUpdates','PauseQualityUpdates',
         'DisableDualScan','DisableWUfBSafeguards','TargetReleaseVersionInfo'
$p = Get-ItemProperty $wu -ErrorAction SilentlyContinue
$namen | ForEach-Object { [pscustomobject]@{ Name = $_; Wert = if ($p) { $p.$_ } } } | Format-Table -AutoSize
```

**Lösung 8.** Beispiel: (1) Drei Ringe (IT-Pilot 0 Tage, zwei Standorte als Breitenring 5 Tage, übrige 10 Tage), Ringe per Sicherheitsgruppe statt nach Standort-OU; (2) Zielversion als Organisationsstandard, nach Pilotfreigabe pro Ring angehoben; (3) Frist 5 Tage, Nachfrist 2 Tage; (4) Delivery Optimization im Gruppenmodus mit je einer GUID pro Standort, Subnetz-Beschränkung bei Hub-and-Spoke; (5) Notbremse-GPO vorbereitet, aber nicht verknüpft, mit Verfahren und Enddatum; (6) Kommunikationsplan (Ankündigung, Hilfeseite, Helpdesk-Skript); (7) Monitoring: Geräte mit alter Version, ausstehenden Neustarts und Schutzsperren.
