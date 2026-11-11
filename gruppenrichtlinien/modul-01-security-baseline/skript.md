# Modul 01 - Security Baseline

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Gruppenrichtlinien für Windows 11 – 100 Richtlinien im Detail“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Steckbriefe als Tabellen, Übungsaufgaben und Lösungen als fortlaufend nummerierte Absätze). **Nummerierung:** Die Überschriften der Richtlinien tragen hier die laufende Nummer 1 bis 100 aus der Modultabelle; die Verweise im Text („Abschnitt 43“) meinen diese Nummer. (Im LaTeX-Satz zählen die Überschriften je Modul neu, etwa 5.3.) **Die Beispiele (PowerShell, INF) wurden für dieses Repository nicht ausgeführt**; sie verändern Gruppenrichtlinien, Registry und Sicherheitseinstellungen und gehören nur in eine Testumgebung (Pilot-OU, Testdomäne). Übersicht zum Modul: [README](README.md).

**Dauer:** 10 Unterrichtsstunden (Annahme: 1 Stunde je Richtlinie, siehe Einleitung)  
**Priorität:** überwiegend 1 (zwei Richtlinien mit Priorität 2)

| Nr. | Lerneinheit (Richtlinie)                | Prio | Stunden |
|----:|:----------------------------------------|:----:|:-------:|
|   1 | Kontosperrungsschwelle setzen           |  1   |    1    |
|   2 | Kontosperrdauer setzen                  |  1   |    1    |
|   3 | Kennwortlänge erhöhen                   |  1   |    1    |
|   4 | Kennwortverlauf erzwingen               |  2   |    1    |
|   5 | Gastkonto deaktivieren                  |  1   |    1    |
|   6 | Lokales Administratorkonto umbenennen   |  2   |    1    |
|   7 | UAC für Administratoren aktivieren      |  1   |    1    |
|   8 | UAC sichere Desktopaufforderung         |  1   |    1    |
|   9 | Anonyme SID-Auflösung verhindern        |  1   |    1    |
|  10 | LAN Manager Hash Speicherung verhindern |  1   |    1    |
|     | **Summe**                               |      | **10**  |

**Worum es in diesem Modul geht.** Die zehn Richtlinien dieses Moduls bilden das Fundament jeder Windows-Absicherung: Sie regeln, wie Anmeldeversuche begrenzt werden, wie lang Kennwörter sein müssen, welche Standardkonten existieren und wie Windows mit erhöhten Rechten und veralteten Protokollen umgeht. Fast alle Einstellungen liegen im Bereich „Sicherheitseinstellungen“ des Gruppenrichtlinien-Editors und werden von den meisten Sicherheitsprüfungen (Audits) als Erstes kontrolliert. Zwei Vorbemerkungen gelten für das ganze Modul. Erstens gehören die Einstellungen 1 bis 4 zu den *Kontorichtlinien*, die sich für Domänenkonten anders verhalten als alle anderen Richtlinien. Zweitens sind die Einstellungen 5 bis 10 „normale“ Computerrichtlinien, die auf jedem Client in der jeweiligen OU wirken.

## 1 Kontosperrungsschwelle setzen

| **Feld**        | **Steckbrief**                                                                                                              |
|:----------------|:----------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Kontorichtlinien \> Kontosperrungsrichtlinien |
| Einstellung     | Kontosperrungsschwelle                                                                                                      |
| Empfehlung      | 10 ungültige Anmeldeversuche                                                                                                |
| Ziel / Zweck    | Brute-Force-Schutz für lokale und Domänenkonten                                                                             |
| Zielbereich     | Computer                                                                                                                    |
| Priorität       | 1                                                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                 |

Wer sich an Windows anmeldet, beweist seine Identität durch ein Kennwort. Ein Angreifer, der dieses Kennwort nicht kennt, kann es erraten: entweder viele Kennwörter für ein Konto durchprobieren (*Brute Force*) oder ein einziges häufiges Kennwort bei vielen Konten testen (*Password Spraying*). Die *Kontosperrungsschwelle* (englisch *Account lockout threshold*) begrenzt solche Versuche. Sie legt fest, nach wie vielen fehlgeschlagenen Anmeldungen ein Konto gesperrt wird. Ist der Wert 0, wird nie gesperrt, und ein Angreifer darf unbegrenzt raten. Intern führt der Domänencontroller für jedes Konto den Zähler `badPwdCount`; überschreitet er die Schwelle, setzt der Domänencontroller das Konto in den gesperrten Zustand, und jede weitere Anmeldung scheitert, auch mit richtigem Kennwort.

Der Lehrplan empfiehlt 10 ungültige Versuche. Das entspricht dem Wert, den die Microsoft-Dokumentation als Empfehlung der Security Baselines nennt („n = 10“). Die Wahl der Zahl ist ein Kompromiss: Eine sehr niedrige Schwelle schützt besser vor Raten, führt aber dazu, dass Benutzer sich häufig selbst aussperren, was viele Helpdesk-Anrufe erzeugt. Microsoft weist darauf hin, dass gesperrte Konten in vielen Organisationen die häufigste Ursache für Helpdesk-Anfragen sind. Eine zu hohe Schwelle lässt dem Angreifer mehr Versuche. Außerdem kann eine Sperrung selbst missbraucht werden: Wer systematisch falsche Anmeldungen für viele Konten erzeugt, sperrt alle aus (*Denial of Service*). Deshalb gehört zur Schwelle immer eine moderate Sperrdauer (nächster Abschnitt).

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation nennt für die Schwelle zwei vertretbare Strategien: entweder 0 (nie sperren, nur zulässig mit komplexen Kennwörtern und einer Überwachung fehlgeschlagener Anmeldungen) oder ein ausreichend hoher Wert. Das Azure-Policy-Baseline-Dokument nennt als Zielwert hingegen „5 oder weniger, aber nicht 0“ (Anlehnung an die CIS-Benchmarks), und für neue Windows-11-Installationen ist laut Microsoft standardmäßig 10 Versuche mit 10 Minuten Sperrdauer voreingestellt. Der Lehrplanwert 10 liegt also im Rahmen, ist aber nicht die einzige veröffentlichte Empfehlung. Die Entscheidung sollte dokumentiert werden.

Eine entscheidende Eigenheit betrifft den *Wirkungsbereich*. Der Lehrplan nennt als Zielbereich „Computer“, und die Einstellung liegt unter Computerkonfiguration. Für Domänenkonten wirken Kontorichtlinien jedoch nur, wenn sie in einer Gruppenrichtlinie stehen, die an die *Domäne* verknüpft ist, praktisch in der Default Domain Policy. Wird dieselbe Einstellung in einer GPO gesetzt, die an eine OU mit Clientrechnern verknüpft ist, gilt sie nur für die *lokalen* Konten dieser Rechner. Das bestätigt die Microsoft-Baseline-Dokumentation ausdrücklich. Für abweichende Regeln einzelner Benutzergruppen verwendet man *Fine-Grained Password Policies* (Kennwortrichtlinien auf Basis von Password Settings Objects, kurz PSO), die unabhängig von Gruppenrichtlinien funktionieren. Daraus folgt für den im Lehrplan genannten Pilotansatz: Eine Pilot-OU hilft hier nicht, wohl aber eine PSO, die zunächst nur eine Testgruppe betrifft.

Das folgende Beispiel zeigt beide Wege. Es setzt zuerst die Schwelle in der Domänenrichtlinie und legt dann zum Testen eine PSO für eine Pilotgruppe an. Voraussetzung sind das Active-Directory-PowerShell-Modul (RSAT) und ein Konto mit Domänenadministratorrechten. Das Skript ändert produktive Einstellungen und sollte nur in einer Testdomäne ausgeführt werden.

```ps
Import-Module ActiveDirectory

# 1) Aktuellen Stand lesen
Get-ADDefaultDomainPasswordPolicy |
    Select-Object LockoutThreshold, LockoutDuration, LockoutObservationWindow

# 2) Domaenenweit: 10 Fehlversuche, Sperre 15 Minuten, Zaehler nach 15 Minuten zurueck
Set-ADDefaultDomainPasswordPolicy -Identity (Get-ADDomain).DNSRoot `
    -LockoutThreshold 10 `
    -LockoutDuration 00:15:00 `
    -LockoutObservationWindow 00:15:00

# 3) Nur fuer eine Pilotgruppe: PSO mit gleichen Sperrwerten
New-ADFineGrainedPasswordPolicy -Name "PSO-Pilot-Sperre" -Precedence 10 `
    -LockoutThreshold 10 -LockoutDuration 00:15:00 -LockoutObservationWindow 00:15:00 `
    -MinPasswordLength 14 -PasswordHistoryCount 24 `
    -ComplexityEnabled $true -ReversibleEncryptionEnabled $false `
    -MinPasswordAge 1.00:00:00 -MaxPasswordAge 365.00:00:00
Add-ADFineGrainedPasswordPolicySubject -Identity "PSO-Pilot-Sperre" -Subjects "GG-Pilot-Anwender"
```

Zeile 1 lädt das Modul. Der Aufruf in den Zeilen 4 und 5 liest die aktuelle Domänenrichtlinie und zeigt nur die drei Sperrwerte; das ist immer der erste Schritt, damit man den Ausgangszustand dokumentiert. Zeile 8 bis 11 setzt die Domänenwerte: `-Identity` bestimmt die Domäne, `-LockoutThreshold` ist die Schwelle, `-LockoutDuration` die Dauer der Sperre und `-LockoutObservationWindow` das Zeitfenster, nach dem der Fehlversuchszähler zurückgesetzt wird. Das Fenster darf nie größer als die Dauer sein. Die PSO ab Zeile 14 verlangt, dass alle Pflichtparameter angegeben werden (Komplexität, umkehrbare Verschlüsselung, Alter), weshalb die Zeile länger ist; `-Precedence` entscheidet bei mehreren PSOs, welche gewinnt (niedrigere Zahl gewinnt). Die Gruppe `GG-Pilot-Anwender` ist ein Platzhalter und muss in der Testdomäne existieren.

**Typische Fehler.** Der häufigste Fehler ist, die Schwelle in einer GPO an eine Client-OU zu binden und sich zu wundern, dass Domänenbenutzer weiterhin unbegrenzt raten dürfen. Falsch ist: „GPO `Sicherheit-Clients` an `OU=Clients` verknüpfen und Schwelle 10 setzen.“ Richtig ist: die Werte in der Default Domain Policy oder per PSO setzen und das Ergebnis mit `Get-ADDefaultDomainPasswordPolicy` beziehungsweise `Get-ADUserResultantPasswordPolicy` prüfen. Der zweite Fehler ist, die Schwelle sehr niedrig (zum Beispiel 3) zu setzen, ohne zu bedenken, dass Dienste und gespeicherte Anmeldeinformationen mit altem Kennwort weiterlaufen und das Konto nach einer Kennwortänderung innerhalb kürzester Zeit sperren (typisch: Smartphone mit E-Mail-Konto). Der dritte Fehler: in Hybridumgebungen Microsoft Entra Smart Lockout und die lokale Schwelle nicht aufeinander abzustimmen. Laut Microsoft sollte bei Pass-through-Authentifizierung die Entra-Schwelle niedriger sein als die AD-Schwelle (mindestens das Zwei- bis Dreifache), damit Angriffe auf Cloud-Konten die lokalen Konten nicht sperren.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Unternehmen berichtet, dass jeden Montag früh Dutzende Konten gesperrt sind. Die Ursache ist fast immer ein Gerät mit gespeichertem altem Kennwort (Smartphone, Drucker mit Scan-to-Mail, Dienstkonto), das mehrfach pro Minute versucht, sich anzumelden. Mit den Sicherheitsereignissen 4740 (Konto gesperrt) auf dem Domänencontroller findet man den auslösenden Rechner im Feld „Caller Computer Name“. Die Schwelle zu erhöhen löst das Problem nicht; die Quelle muss behoben werden.

## 2 Kontosperrdauer setzen

| **Feld**        | **Steckbrief**                                                                                                              |
|:----------------|:----------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Kontorichtlinien \> Kontosperrungsrichtlinien |
| Einstellung     | Kontosperrdauer                                                                                                             |
| Empfehlung      | 15 Minuten                                                                                                                  |
| Ziel / Zweck    | Reduziert Rate automatisierter Anmeldeversuche                                                                              |
| Zielbereich     | Computer                                                                                                                    |
| Priorität       | 1                                                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                 |

Die *Kontosperrdauer* (englisch *Account lockout duration*) bestimmt, wie viele Minuten ein gesperrtes Konto gesperrt bleibt, bevor es sich automatisch entsperrt. Zusammen mit der Schwelle ergibt sich daraus die maximale Rate, mit der ein Angreifer raten kann: Bei Schwelle 10 und 15 Minuten Sperrdauer sind es höchstens zehn Versuche pro Viertelstunde, also etwa 960 Versuche pro Tag und Konto. Das ist für Wörterbuchangriffe auf starke Kennwörter praktisch wirkungslos. Ohne Sperrdauer (Wert 0) bleibt das Konto dagegen gesperrt, bis ein Administrator es entsperrt. Das klingt sicherer, ist aber gefährlich: Ein Angreifer könnte alle Konten gezielt sperren und die Organisation lahmlegen.

Microsoft beschreibt in der Baseline-Dokumentation, dass hohe Werte die Zahl der Helpdesk-Anrufe erhöhen, und empfiehlt „15 oder mehr Minuten“. Der Lehrplanwert 15 liegt damit am unteren Ende der empfohlenen Spanne. Eine zweite Einstellung gehört dazu, die der Lehrplan nicht eigens aufführt: das Zurücksetzen des Zählers nach einer bestimmten Zeit (*Reset account lockout counter after*, Beobachtungsfenster). Es gilt die Regel, dass dieses Fenster kleiner oder gleich der Sperrdauer sein muss. Auch hier nennt die Baseline mindestens 15 Minuten. Ist das Fenster zu kurz, kann ein Angreifer „langsam“ raten, ohne je die Schwelle zu erreichen (zum Beispiel neun Versuche, 16 Minuten Pause, neun Versuche, …). Ist es sehr lang, sammeln sich versehentliche Tippfehler eines Benutzers über Stunden an.

> **Merke**
>
> Drei Werte gehören immer zusammen: Schwelle (wie viele Fehlversuche), Dauer (wie lange gesperrt) und Beobachtungsfenster (wie lange Fehlversuche zählen). Das Fenster darf nicht größer sein als die Dauer. Ändert man nur einen der drei Werte, bleibt die Richtlinie unvollständig oder inkonsistent.

Zur Kontrolle und zum Betrieb braucht man zwei Werkzeuge: das Lesen der Richtlinie und das Auffinden beziehungsweise Entsperren gesperrter Konten. Das folgende Beispiel zeigt beides. Es liest die wirksamen Werte, listet gesperrte Konten und entsperrt gezielt ein einzelnes Konto. Es ändert nur ein Konto und ist auch in einer Produktivumgebung unkritisch, sofern der Benutzer wirklich entsperrt werden soll.

```ps
# Wirksame Domaenenwerte anzeigen
Get-ADDefaultDomainPasswordPolicy |
    Select-Object LockoutThreshold, LockoutDuration, LockoutObservationWindow

# Alle aktuell gesperrten Benutzerkonten auflisten
Search-ADAccount -LockedOut -UsersOnly |
    Select-Object SamAccountName, LockedOut, LastLogonDate

# Ein Konto entsperren
Unlock-ADAccount -Identity "mmueller"

# Ereignis 4740 (Konto gesperrt) der letzten 24 Stunden auf einem DC lesen
Get-WinEvent -ComputerName DC01 -FilterHashtable @{
    LogName='Security'; Id=4740; StartTime=(Get-Date).AddDays(-1)
} | Select-Object TimeCreated, Message -First 5
```

Die ersten beiden Zeilen lesen die Richtlinie; die Werte werden als Zeitspannen (zum Beispiel `00:15:00`) ausgegeben. `Search-ADAccount -LockedOut` fragt Active Directory nach allen Benutzern, die gerade gesperrt sind, und `-UsersOnly` schließt Computerkonten aus. `Unlock-ADAccount` setzt das Konto zurück; Voraussetzung ist die delegierte Berechtigung „Konten entsperren“. Der `Get-WinEvent`-Aufruf liest auf dem Domänencontroller `DC01` (Platzhalter) das Sicherheitsprotokoll und filtert auf die Ereignis-ID 4740; der `FilterHashtable` ist deutlich schneller als ein nachträgliches `Where-Object`. Beachten Sie, dass das Ereignis auf demjenigen Domänencontroller steht, der das Konto gesperrt hat (in der Regel der PDC-Emulator), nicht auf allen.

**Typische Fehler.** Falsch ist, die Sperrdauer auf 0 zu setzen, „damit der Helpdesk die Kontrolle behält“: Ein einziger Skriptlauf mit absichtlich falschen Kennwörtern sperrt dann die gesamte Belegschaft bis zum manuellen Eingriff. Richtig sind 15 Minuten oder eine ähnlich kurze Zeit. Ebenfalls falsch ist ein Beobachtungsfenster, das größer als die Dauer ist, zum Beispiel Dauer 15 und Fenster 60 Minuten; Diese Kombination ist unzulässig und sollte nie konfiguriert werden. Ein dritter Stolperstein: Administratorkonten wurden früher von der Sperre ausgenommen. Laut Microsoft ist die Einstellung „Administratorkonto sperren erlauben“ in neuen Windows-11-Installationen standardmäßig aktiv; das sollte man prüfen und nicht deaktivieren.

> **Praxisbeispiel**
>
> Beispielszenario: Im Penetrationstest einer Behörde fällt auf, dass das Sperren-Konzept zwar eingerichtet ist, die Sperrdauer aber 0 beträgt. Ein simulierter Angreifer sperrt in zehn Minuten 400 Konten, die Behörde kann montags nicht arbeiten. Nach der Umstellung auf 15 Minuten war der gleiche Angriff nur noch eine kurze Störung. Dieses Szenario zeigt, warum die Sperrdauer eine Verfügbarkeitsmaßnahme ist und nicht nur ein Sicherheitsmerkmal.

## 3 Kennwortlänge erhöhen

| **Feld**        | **Steckbrief**                                                                                                        |
|:----------------|:----------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Kontorichtlinien \> Kennwortrichtlinien |
| Einstellung     | Minimale Kennwortlänge                                                                                                |
| Empfehlung      | 14 Zeichen oder organisationsspezifisch höher                                                                         |
| Ziel / Zweck    | Verbessert Widerstand gegen Kennwortangriffe                                                                          |
| Zielbereich     | Computer                                                                                                              |
| Priorität       | 1                                                                                                                     |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                           |

Die Stärke eines Kennworts hängt vor allem von seiner Länge ab. Jedes zusätzliche Zeichen vervielfacht die Zahl der möglichen Kombinationen. Die Microsoft-Baseline-Dokumentation rechnet das anschaulich vor: Ein siebenstelliges Kennwort aus Kleinbuchstaben hat etwa 8 Milliarden Kombinationen und ist bei einer Million Versuchen pro Sekunde in rund 133 Minuten durchprobiert; ein achtstelliges Kennwort braucht bei derselben Rate rund 59 Stunden. Diese Rechnung gilt für *Offline-Angriffe*, bei denen ein Angreifer eine erbeutete Hash-Datei lokal mit Grafikkarten durchprobiert und weder durch Sperren noch durch Netzwerkgeschwindigkeit gebremst wird. Die Kontosperrung (Abschnitte 1 und 2) schützt nur vor *Online-Angriffen*; gegen Offline-Angriffe hilft nur ein langes Kennwort.

Der Lehrplan nennt 14 Zeichen „oder organisationsspezifisch höher“. 14 Zeichen sind auch die Empfehlung der Microsoft-Baseline („14 oder mehr Zeichen“), und Microsoft rät zum Denken in *Passphrasen*: ein Satz mit Leerzeichen ist leichter zu merken und trotzdem stärker als ein kurzes Kennwort mit Sonderzeichen. Die Einstellung „Kennwort muss Komplexitätsanforderungen entsprechen“ (mindestens drei von vier Zeichengruppen) bleibt dennoch sinnvoll, denn sie wird in der Baseline weiterhin mit „Enabled“ empfohlen.

> **Ergänzung aus der Nachrecherche**
>
> Laut Policy-CSP-Dokumentation galt historisch eine Obergrenze von 14 für die Einstellung. Seit Windows 11 ab 22H2 (mit dem Update KB5053657) und 24H2 kann die Länge bis 128 gesetzt werden, aber nur, wenn zusätzlich die Richtlinie „Relax minimum password length limits“ aktiviert ist. Microsoft empfiehlt, Werte über 14 zuerst mit der Einstellung „Minimum password length audit“ zu testen, weil Clients, Dienste und Anwendungen damit Probleme haben können. Der Standardwert für Domänencontroller ist 7, für eigenständige Server 0.

Auch hier gilt der Wirkungsbereich aus Abschnitt 1: Für Domänenkonten zählt die Richtlinie nur in der Default Domain Policy oder in einer PSO. Das folgende Beispiel zeigt die Domänenvariante mit Kontrolle, einen Test mit dem Auditwert und die Prüfung auf einem Einzelrechner mit `net accounts`. Es ändert produktive Einstellungen; vor der Ausführung sollte der Helpdesk informiert werden, weil Benutzer beim nächsten Kennwortwechsel eine längere Eingabe verlangt wird.

```ps
# Aktueller Stand (Domaene)
Get-ADDefaultDomainPasswordPolicy | Select-Object MinPasswordLength, ComplexityEnabled

# Mindestlaenge 14 und Komplexitaet in der Domaenenrichtlinie
Set-ADDefaultDomainPasswordPolicy -Identity (Get-ADDomain).DNSRoot `
    -MinPasswordLength 14 -ComplexityEnabled $true

# Wirksame Richtlinie eines einzelnen Benutzers (beruecksichtigt PSOs)
Get-ADUserResultantPasswordPolicy -Identity "mmueller"

# Lokale Sicht auf einem Client oder Server
net accounts
```

Die erste Abfrage dokumentiert den Ausgangszustand. Das Cmdlet `Set-ADDefaultDomainPasswordPolicy` schreibt die neue Mindestlänge; Konten, deren Kennwort bereits kürzer ist, bleiben gültig, bis sie ihr Kennwort das nächste Mal ändern müssen oder es zurückgesetzt wird. Genau deshalb darf man nach der Umstellung nicht erwarten, dass sofort alle Kennwörter 14 Zeichen haben. `Get-ADUserResultantPasswordPolicy` liefert die tatsächlich wirksame PSO für einen Benutzer; ist keine PSO zugewiesen, bleibt die Ausgabe leer. Der Befehl `net accounts` zeigt die Sicht des lokalen Rechners, auf einem Domänenmitglied also die Werte der Domäne.

**Typische Fehler.** Falsch ist, die Länge zu erhöhen, aber die Komplexität abzuschalten, „weil lange Kennwörter ohnehin sicher sind“: Das mag für zufällige Passphrasen stimmen, aber nicht für `aaaaaaaaaaaaaa`. Richtig ist, die Komplexität zu belassen oder eine Kennwortsperrliste (Entra Password Protection) zu ergänzen. Ein zweiter Fehler ist, den Wert über 14 zu setzen, ohne die Relax-Richtlinie zu aktivieren; die Einstellung wird dann abgelehnt oder bleibt wirkungslos. Ein dritter Fehler ist die fehlende Kommunikation: Wenn Benutzer plötzlich beim Kennwortwechsel scheitern, melden sie sich am Helpdesk, ohne dass jemand die Ursache kennt. Dokumentieren Sie daher die Anforderung in einer verständlichen Fehlermeldung (Hinweistext) und im Intranet.

> **Praxisbeispiel**
>
> Eine Schule stellt von 8 auf 14 Zeichen um. Statt eines Stichtags legt sie eine PSO für die Lehrkräfte an und erhöht die Länge dort zuerst; die Schülerkonten bleiben vorerst bei 8. Nach zwei Wochen ohne größere Probleme wird die Domänenrichtlinie angepasst. Die Technik hinter diesem Vorgehen ist die PSO aus Abschnitt 1.

## 4 Kennwortverlauf erzwingen

| **Feld**        | **Steckbrief**                                                                                                        |
|:----------------|:----------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Kontorichtlinien \> Kennwortrichtlinien |
| Einstellung     | Kennwortchronik erzwingen                                                                                             |
| Empfehlung      | 24 gespeicherte Kennwörter                                                                                            |
| Ziel / Zweck    | Verhindert schnelle Wiederverwendung alter Kennwörter                                                                 |
| Zielbereich     | Computer                                                                                                              |
| Priorität       | 2                                                                                                                     |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                           |

Die *Kennwortchronik* (englisch *Enforce password history*) legt fest, wie viele frühere Kennwörter eines Kontos Windows speichert und beim Ändern ablehnt. Der Hintergrund ist einfach: Wenn ein Kennwort einmal bekannt geworden ist (etwa durch einen Datenabfluss), soll es nicht später wieder als „neues“ Kennwort gelten. Der Wert reicht von 0 bis 24. Laut Microsoft-Baseline ist 24 der empfohlene Wert und gleichzeitig die Standardeinstellung in einer Domäne. Der Lehrplan folgt dieser Empfehlung.

Die Chronik allein ist leicht zu umgehen. Wer sein Kennwort bei Erreichen der Chronik einfach 24-mal hintereinander ändert, kommt wieder bei seinem Lieblingskennwort an. Deshalb ist die Einstellung „Minimales Kennwortalter“ (englisch *Minimum password age*) wichtig: Sie legt fest, wie viele Tage ein Kennwort mindestens verwendet werden muss, bevor es geändert werden darf. Microsoft empfiehlt dafür mindestens einen Tag und weist ausdrücklich darauf hin, dass diese Einstellung nötig ist, damit die Chronik wirksam bleibt. Der Lehrplan führt das minimale Kennwortalter nicht auf. Bei der Planung dieses Moduls sollte es daher mitgedacht werden.

> **Merke**
>
> Kennwortchronik und minimales Kennwortalter gehören zusammen. Die Chronik verhindert die Wiederverwendung, das Mindestalter verhindert, dass man sie durch schnelles Mehrfachändern umgeht. Ein Mindestalter von 0 Tagen macht die Chronik weitgehend nutzlos.

Das folgende Beispiel setzt beide Werte, prüft sie und zeigt, wie man die Chronik für Konten ausnimmt, die ein Administrator zurücksetzt. Es ändert die Domänenrichtlinie und ist wie die vorigen Beispiele nur in einer Testumgebung zu verwenden. Das Mindestalter von einem Tag wird im Format Tage.Stunden:Minuten:Sekunden angegeben.

```ps
# Chronik 24, Mindestalter 1 Tag
Set-ADDefaultDomainPasswordPolicy -Identity (Get-ADDomain).DNSRoot `
    -PasswordHistoryCount 24 `
    -MinPasswordAge 1.00:00:00

# Kontrolle
Get-ADDefaultDomainPasswordPolicy |
    Select-Object PasswordHistoryCount, MinPasswordAge, MaxPasswordAge

# Als Administrator zuruecksetzen (Mindestalter wird dabei nicht beachtet)
Set-ADAccountPassword -Identity "mmueller" -Reset `
    -NewPassword (Read-Host "Neues Kennwort" -AsSecureString)
Set-ADUser -Identity "mmueller" -ChangePasswordAtLogon $true
```

In den ersten Zeilen setzt `-PasswordHistoryCount` die Anzahl gemerkter Kennwörter und `-MinPasswordAge` das Mindestalter. Die Kontrolle zeigt zusätzlich das maximale Kennwortalter, das hier nicht verändert wird. Das Zurücksetzen eines Kennworts durch einen Administrator (`Set-ADAccountPassword -Reset`) ist von der Chronik und vom Mindestalter nicht betroffen; deshalb setzt die letzte Zeile die Option „Benutzer muss Kennwort bei der nächsten Anmeldung ändern“, damit der Benutzer sofort ein eigenes Kennwort wählt. `Read-Host -AsSecureString` verhindert, dass das Kennwort in der Befehlshistorie oder auf dem Bildschirm sichtbar ist.

**Typische Fehler.** Falsch: Chronik 24 setzen und das Mindestalter bei 0 belassen. Dann kann ein Benutzer das Kennwort 25-mal hintereinander ändern und das alte wieder setzen. Richtig: Mindestalter mindestens 1 Tag. Der Gegenfehler ist ein sehr hohes Mindestalter, etwa 30 Tage: Wenn ein Kennwort kompromittiert ist, kann der Benutzer es dann nicht selbst ändern, sondern muss den Helpdesk anrufen. Bei Zweifeln hilft eine kleine Zahl wie 1 bis 2 Tage. Ein weiterer Stolperstein: Die Chronik gilt nur für Änderungen durch den Benutzer, nicht für administrative Zurücksetzungen und auch nicht für Kennwörter, die Dienste selbst rotieren (zum Beispiel Windows LAPS in Modul 8).

> **Praxisbeispiel**
>
> In einem Auditbericht steht oft die Zeile „Kennwortchronik \< 24“. Prüfen Sie nicht nur die Domänenrichtlinie, sondern auch bestehende PSOs: Eine PSO mit Chronik 5 für „Servicekonten“ überschreibt die Domänenwerte für diese Konten und ist ein häufiger Grund, warum ein Audit trotz richtiger Default Domain Policy Abweichungen meldet.

## 5 Gastkonto deaktivieren

| **Feld**        | **Steckbrief**                                                                                                          |
|:----------------|:------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Sicherheitsoptionen |
| Einstellung     | Konten: Gastkontostatus                                                                                                 |
| Empfehlung      | Deaktiviert                                                                                                             |
| Ziel / Zweck    | Verhindert unkontrollierten anonymen Zugriff                                                                            |
| Zielbereich     | Computer                                                                                                                |
| Priorität       | 1                                                                                                                       |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                             |

Windows enthält ein eingebautes lokales Konto namens *Gast* (englisch *Guest*). Es wurde für Situationen entworfen, in denen jemand ohne eigenes Konto kurz einen Rechner nutzen soll, und besitzt kein Kennwort. Aus Sicherheitssicht ist das ein Risiko: Ist das Konto aktiv, kann sich jeder ohne Anmeldeinformationen anmelden oder, wichtiger, auf Freigaben zugreifen, deren Berechtigungen versehentlich für die Gruppe „Jeder“ offen sind. Moderne Windows-Versionen liefern das Konto im Normalfall bereits deaktiviert aus, aber ein Rechner, der mit einem alten Abbild installiert oder von einem Benutzer verändert wurde, kann einen anderen Zustand haben. Die Richtlinie „Konten: Gastkontostatus“ erzwingt deshalb bei jedem Gruppenrichtlinien-Update den gewünschten Zustand „Deaktiviert“ und verhindert, dass er unbemerkt abweicht.

Der Zusammenhang mit zwei weiteren Richtlinien des Lehrplans ist wichtig. Abschnitt 78 (Modul 8, „Lokale Anmeldung für Gäste verweigern“) verbietet die Anmeldung der Gruppe „Guests“ am Gerät zusätzlich. Abschnitt 38 (Modul 4, unsichere SMB-Gastanmeldungen) verhindert, dass Clients bei SMB-Verbindungen automatisch auf Gastzugriff zurückfallen. Zusammen bilden die drei Einstellungen eine mehrschichtige Absicherung (*Defense in Depth*): Das Konto ist deaktiviert, die Anmeldung ist verboten, und das Netzwerk nutzt kein Gastfallback.

Die Umsetzung ist als Sicherheitsvorlage (INF-Datei) besonders anschaulich, denn genau dieses Format verwendet der Gruppenrichtlinien-Editor intern für den Bereich „Sicherheitseinstellungen“. Das folgende Beispiel zeigt eine kleine Vorlage, die den Gastkontostatus auf deaktiviert setzt, und wie man sie auf einem Testrechner anwendet und prüft. Es verändert nur den lokalen Rechner und ist unkritisch; auf einem domänenverbundenen Rechner überschreibt die Gruppenrichtlinie beim nächsten Update den lokalen Wert wieder, was für diesen Test genau gewollt sein kann.

```inf
; Datei: gast.inf
[Unicode]
Unicode=yes
[Version]
signature="$CHICAGO$"
Revision=1
[System Access]
EnableGuestAccount = 0
```

```ps
# Vorlage anwenden und Ergebnis pruefen (als Administrator)
secedit /configure /db "$env:TEMP\gast.sdb" /cfg "C:\Test\gast.inf" /areas SECURITYPOLICY
Get-LocalUser -Name Guest | Select-Object Name, Enabled
```

In der INF-Datei markiert `[Unicode]` das Dateiformat; `[Version]` mit der Signatur `$CHICAGO$` ist für Sicherheitsvorlagen vorgeschrieben. Der eigentliche Inhalt steht im Abschnitt `[System Access]`: `EnableGuestAccount = 0` bedeutet „deaktiviert“. `secedit /configure` wendet die Vorlage an, wobei `/db` eine temporäre Datenbank benennt und `/areas SECURITYPOLICY` die Anwendung auf die Sicherheitsrichtlinie beschränkt. `Get-LocalUser` zeigt anschließend, ob `Enabled` auf `False` steht. In einer echten GPO importiert man dieselbe Vorlage im Gruppenrichtlinien-Editor unter „Sicherheitseinstellungen \> Richtlinie importieren“ oder setzt den Wert direkt in der Oberfläche.

**Typische Fehler.** Falsch ist die Annahme, das Konto sei „gelöscht“: Das Gastkonto kann nicht gelöscht, nur deaktiviert werden. Ebenso falsch ist, das Konto statt zu deaktivieren umzubenennen und für sicher zu halten. Richtig ist: deaktivieren (Richtlinie) und zusätzlich die Anmeldung verweigern (Abschnitt 78). Ein weiterer Fehler: Die Richtlinie in einer GPO anzulegen, die nur für Benutzerkonfiguration gilt; sie wirkt dann nicht, denn sie gehört unter Computerkonfiguration.

> **Praxisbeispiel**
>
> Bei Inventurprüfungen für ISO-27001-Audits wird häufig mit einem Skript über alle Clients geprüft, ob `Guest` deaktiviert ist. Findet das Skript abweichende Geräte, zeigt das meist Rechner außerhalb der Domäne oder in der falschen OU. Die Richtlinie ist damit nicht nur Schutzmaßnahme, sondern auch ein Test, ob die Zuordnung der Computer zur richtigen OU funktioniert.

## 6 Lokales Administratorkonto umbenennen

| **Feld**        | **Steckbrief**                                                                                                          |
|:----------------|:------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Sicherheitsoptionen |
| Einstellung     | Konten: Administratorkonto umbenennen                                                                                   |
| Empfehlung      | Organisationsspezifischer Name                                                                                          |
| Ziel / Zweck    | Erschwert automatisierte Angriffe auf Standardkonten                                                                    |
| Zielbereich     | Computer                                                                                                                |
| Priorität       | 2                                                                                                                       |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                             |

Jeder Windows-Rechner besitzt ein eingebautes lokales Administratorkonto mit dem bekannten Namen `Administrator`. Weil dieser Name auf allen Rechnern gleich ist, genügt es einem Angreifer, ein Kennwort zu erraten, um es auf allen Geräten zu versuchen. Die Richtlinie benennt das Konto zentral um, zum Beispiel in einen unauffälligen firmenspezifischen Namen. Das erschwert Skripte, die automatisch den Standardnamen verwenden, und erzeugt in den Sicherheitsprotokollen deutlichere Spuren: Anmeldeversuche für das Konto „Administrator“, das es gar nicht mehr gibt, fallen sofort auf.

Wichtig ist, die Wirkung realistisch einzuschätzen. Das Umbenennen ist *Security through Obscurity*, also Sicherheit durch Verborgenheit. Das Konto behält seine *Security Identifier* (SID), die immer mit der festen relativen ID 500 endet. Ein Angreifer, der Namen über SIDs auflösen kann (siehe Abschnitt 9), findet das umbenannte Konto trotzdem. Die eigentliche Schutzmaßnahme für das lokale Administratorkonto ist daher nicht der Name, sondern ein einzigartiges, regelmäßig rotiertes Kennwort pro Gerät, wie es Windows LAPS bereitstellt (Modul 8, Abschnitte 71 und 72). Das Umbenennen ist eine ergänzende Maßnahme mit niedriger Priorität, was auch die Priorität 2 im Lehrplan widerspiegelt.

> **Merke**
>
> Umbenennen erschwert Automatisierung, ersetzt aber keinen Kennwortschutz. Die SID mit der Endung 500 verrät das Konto weiterhin. Wirklicher Schutz entsteht durch Windows LAPS und durch die Deaktivierung des Kontos, wo es nicht gebraucht wird.

Die Einstellung lässt sich ebenfalls in einer Sicherheitsvorlage ausdrücken. Das folgende Beispiel benennt das Konto auf einem Testrechner um und prüft das Ergebnis über die SID, nicht über den Namen, denn der Name ist ja genau das, was sich geändert hat. Das Beispiel ändert den lokalen Rechner; nach dem Test sollte der ursprüngliche Name wieder gesetzt werden, falls der Rechner anderweitig genutzt wird. Der Name `LokAdm-Beispiel` ist ein Platzhalter.

```inf
; Datei: admin-umbenennen.inf
[Unicode]
Unicode=yes
[Version]
signature="$CHICAGO$"
Revision=1
[System Access]
NewAdministratorName = "LokAdm-Beispiel"
```

```ps
secedit /configure /db "$env:TEMP\adm.sdb" /cfg "C:\Test\admin-umbenennen.inf" /areas SECURITYPOLICY

# Konto ueber die SID finden (endet immer auf -500)
Get-LocalUser | Where-Object { $_.SID.Value -like "*-500" } |
    Select-Object Name, Enabled, SID
```

Die INF-Datei hat denselben Aufbau wie im vorigen Abschnitt; die Zeile `NewAdministratorName` nennt den neuen Namen in Anführungszeichen. Die PowerShell-Abfrage filtert alle lokalen Benutzer auf diejenigen, deren SID mit `-500` endet, und gibt Namen, Status und SID aus. So findet man das Konto unabhängig vom Namen, und genau diesen Trick nutzen Angreifer und Auditwerkzeuge gleichermaßen.

**Typische Fehler.** Falsch ist, den Namen in der GPO zu ändern und danach Skripte, geplante Aufgaben oder Fernwartungswerkzeuge nicht anzupassen, die das Konto mit seinem alten Namen ansprechen. Richtig ist, vorher per Suche in Skriptsammlung, Softwareverteilung und LAPS-Konfiguration alle Verwendungen des Namens `Administrator` zu finden. Wichtig ist insbesondere, dass Windows LAPS den neuen Namen kennen muss, wenn man es für das benannte Konto einrichtet (Einstellung „Administratorkontoname“ der LAPS-Richtlinie). Ein zweiter Fehler: auf Domänencontrollern dieselbe GPO anzuwenden. Dort gibt es kein lokales Administratorkonto im bisherigen Sinn, sondern das Domänenadministratorkonto, dessen Umbenennung gesondert zu planen ist.

> **Praxisbeispiel**
>
> Ein Dienstleister rollt Rechner mit einem Standard-Image und dem unveränderten Administratorkonto aus. Nach einem Vorfall ist das Kennwort in Umlauf, aber mit einer GPO, die den Namen ändert, und mit LAPS ist der Schaden begrenzt. Im Ereignisprotokoll fällt später auf, dass jemand das Konto „Administrator“ anzumelden versucht; diese Anmeldeversuche ins Leere sind ein sehr zuverlässiger Alarmauslöser.

## 7 UAC für Administratoren aktivieren

| **Feld**        | **Steckbrief**                                                                                                          |
|:----------------|:------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Sicherheitsoptionen |
| Einstellung     | Benutzerkontensteuerung: Administratorgenehmigungsmodus                                                                 |
| Empfehlung      | Aktiviert                                                                                                               |
| Ziel / Zweck    | Reduziert Risiko durch dauerhaft erhöhte Rechte                                                                         |
| Zielbereich     | Computer                                                                                                                |
| Priorität       | 1                                                                                                                       |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                             |

Die *Benutzerkontensteuerung* (englisch *User Account Control*, UAC) ist der Mechanismus, der verhindert, dass ein Administrator ständig mit vollen Rechten arbeitet. Meldet sich ein Administrator an, bekommt er zwei Zugriffstoken: ein gefiltertes Standardbenutzer-Token für den Alltag und ein vollständiges Administrator-Token, das nur nach Bestätigung verwendet wird. Dieses Verhalten heißt *Administratorgenehmigungsmodus* (englisch *Admin Approval Mode*). Programme starten also zunächst mit eingeschränkten Rechten; erst wenn ein Vorgang Administratorrechte braucht (erkennbar am Schild-Symbol), erscheint die Abfrage, und erst nach der Zustimmung wird das vollständige Token verwendet. Der Gewinn ist groß: Schadsoftware, die im Namen eines Administrators läuft, kann nicht mehr unbemerkt das System verändern, sondern löst eine sichtbare Abfrage aus.

Hinter dem Lehrplantitel stehen in Wahrheit zwei Gruppenrichtlinien-Einstellungen, die man unterscheiden muss. Die Einstellung „Alle Administratoren im Administratorgenehmigungsmodus ausführen“ (Registrywert `EnableLUA`) schaltet UAC insgesamt ein. Sie ist laut Microsoft standardmäßig aktiv; wird sie deaktiviert, sind der Administratorgenehmigungsmodus und alle zugehörigen UAC-Einstellungen aus, und Windows meldet in der Windows-Sicherheit, dass der Schutz reduziert ist. Die zweite Einstellung „Administratorgenehmigungsmodus für das integrierte Administratorkonto“ (`FilterAdministratorToken`) betrifft nur das eingebaute Konto aus Abschnitt 6. Laut Microsoft ist sie standardmäßig deaktiviert, das heißt, das integrierte Administratorkonto führt alle Programme mit vollen Rechten ohne Abfrage aus. Der Lehrplan meint mit „Administratorgenehmigungsmodus“ die zweite Einstellung, die in Sicherheitsbaselines üblicherweise auf „Aktiviert“ gesetzt wird; die erste sollte man nur prüfen und auf Aktiviert lassen.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft-Dokumentation zur UAC-Konfiguration gilt: „Run all administrators in Admin Approval Mode“ ist standardmäßig aktiviert, „Admin Approval Mode for the built-in Administrator account“ ist standardmäßig deaktiviert. Wer UAC vollständig ausschalten will, muss die erste Einstellung deaktivieren; der Schieberegler für die UAC-Benachrichtigung schaltet UAC dagegen nie vollständig ab. Das Ausschalten von UAC wird nicht empfohlen.

Das folgende Beispiel setzt beide Einstellungen über eine Gruppenrichtlinie mit PowerShell. Es erzeugt eine neue GPO, schreibt die Registrywerte, die diesen Einstellungen entsprechen, und verknüpft die GPO mit einer Pilot-OU. Es braucht das Modul GroupPolicy (RSAT) und ändert die Domäne; verwenden Sie in der Testdomäne eine Pilot-OU, deren Name hier ein Platzhalter ist. Vor dem produktiven Einsatz sollte man den Registrywert mit der Oberflächenbezeichnung vergleichen.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "SEC-UAC-Baseline"

$key = "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System"

# UAC insgesamt an (Standard, hier erzwungen)
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName EnableLUA `
    -Type DWord -Value 1

# Admin Approval Mode auch fuer das integrierte Administratorkonto
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName FilterAdministratorToken `
    -Type DWord -Value 1

New-GPLink -Name $gpo.DisplayName -Target "OU=Pilot-Clients,DC=firma,DC=local"

# Auf einem Pilotclient pruefen (nach gpupdate /force und Neustart)
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" |
    Select-Object EnableLUA, FilterAdministratorToken
```

Die Variable `$gpo` hält das neue Gruppenrichtlinienobjekt. `Set-GPRegistryValue` schreibt Registrywerte in die GPO, wobei `-Key` den Pfad, `-ValueName` den Namen und `-Type DWord` den Datentyp angibt. `New-GPLink` verknüpft die GPO mit der Pilot-OU. Der letzte Befehl liest auf einem Client die beiden Werte aus der Registry. Wichtig: Änderungen an `EnableLUA` werden erst nach einem Neustart wirksam.

**Typische Fehler.** Falsch ist, UAC global auszuschalten, weil eine alte Fachanwendung Abfragen erzeugt. Richtig ist, die Anwendung mit einem Manifest oder einer Kompatibilitätseinstellung zu korrigieren oder in einer Ausnahmegruppe zu betreiben. Ein weiterer Fehler: das eingebaute Administratorkonto im Administratorgenehmigungsmodus zu betreiben und es danach zur Anmeldung per Netzwerk zu nutzen. Bei aktivem Modus gilt für lokale Konten per Fernzugriff das gefilterte Token, sodass die Anmeldung zwar gelingt, administrative Aktionen aber scheitern. Dienstleister, die Software per Fernzugriff mit diesem Konto verteilen, melden dann rätselhafte Zugriffsfehler. Prüfen Sie daher Softwareverteilung und Fernwartung im Pilot.

> **Praxisbeispiel**
>
> In einer Fertigungsumgebung läuft eine ältere Maschinensteuerung, die beim Start Schreibrechte in ihrem Programmverzeichnis braucht. Statt UAC zu deaktivieren, legte das Team die Ausnahme per Manifest und Dateisystemrechten an. So blieb die Baseline für alle übrigen 400 Rechner unverändert.

## 8 UAC sichere Desktopaufforderung

| **Feld**        | **Steckbrief**                                                                                                          |
|:----------------|:------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Sicherheitsoptionen |
| Einstellung     | Benutzerkontensteuerung: Bei Erhöhung zum sicheren Desktop wechseln                                                     |
| Empfehlung      | Aktiviert                                                                                                               |
| Ziel / Zweck    | Schützt UAC-Prompts vor Manipulation                                                                                    |
| Zielbereich     | Computer                                                                                                                |
| Priorität       | 1                                                                                                                       |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                             |

Die UAC-Abfrage hat nur dann Sicherheitswert, wenn Schadsoftware sie nicht manipulieren kann. Der *sichere Desktop* (englisch *secure desktop*) löst dieses Problem: Wenn ein Programm Erhöhung verlangt, wechselt Windows von der normalen Benutzeroberfläche, dem *interaktiven Desktop*, auf einen getrennten Desktop, auf dem nur Windows-eigene Prozesse laufen. Der Bildschirm wird abgedunkelt, die Abfrage erscheint dort, und erst nach der Antwort kehrt Windows zum normalen Desktop zurück. Andere Programme können auf dem sicheren Desktop weder Klicks simulieren noch Tastatureingaben mitlesen, und sie sehen auch keine Fensterinhalte. Damit kann Schadsoftware die Abfrage nicht automatisch bestätigen und den Dialog nicht verdecken oder fälschen.

Die Microsoft-Dokumentation stellt klar, was der sichere Desktop nicht leistet: Schadsoftware kann eine gefälschte Abfrage anzeigen, aber wenn die Abfrage nur „Zustimmen“ verlangt, erhält die Fälschung dadurch keine erhöhten Rechte. Fragt die Abfrage dagegen nach Anmeldeinformationen, könnte eine Fälschung das Kennwort erfassen, ohne damit erhöhte Rechte zu erhalten. Der sichere Desktop ist also eine Schutzschicht, kein Allheilmittel. Die Einstellung ist standardmäßig aktiviert; laut Policy-CSP-Dokumentation lautet der Standardwert 1. Wenn der sichere Desktop aktiv ist, gehen alle Erhöhungsabfragen dorthin, unabhängig davon, wie das Verhalten der Abfrage für Administratoren und Standardbenutzer konfiguriert ist.

> **Merke**
>
> Sicherer Desktop an: Alle Erhöhungsabfragen erscheinen auf dem abgedunkelten, isolierten Desktop. Sicherer Desktop aus: Die Abfrage erscheint auf dem normalen Desktop und kann von anderen Programmen beeinflusst werden. Der Standardwert ist „an“.

Die Umsetzung ist wieder ein Registrywert, der sich per Gruppenrichtlinie erzwingen lässt. Das folgende Beispiel zeigt die Einstellung in der Sicherheitsvorlage und eine Kontrolle mit PowerShell. Die Vorlage setzt nur diesen einen Wert; der Syntax-Teil `4,1` bedeutet, dass der Wert vom Typ DWORD ist und 1 lautet. Es ändert nur den lokalen Rechner; ein Neustart ist nicht nötig, aber ein erneutes Anmelden empfehlenswert.

```inf
; Datei: uac-secure-desktop.inf
[Unicode]
Unicode=yes
[Version]
signature="$CHICAGO$"
Revision=1
[Registry Values]
MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\PromptOnSecureDesktop=4,1
```

```ps
secedit /configure /db "$env:TEMP\uac.sdb" /cfg "C:\Test\uac-secure-desktop.inf" /areas SECURITYPOLICY
(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System").PromptOnSecureDesktop
```

Im Abschnitt `[Registry Values]` steht ein vollständiger Registrypfad, gefolgt von Typ und Wert. `MACHINE` ist die Kurzform für `HKEY_LOCAL_MACHINE`. Die PowerShell-Zeile gibt den aktuellen Wert aus, der nach dem Anwenden `1` sein muss. Probieren Sie anschließend einen Vorgang aus, der Administratorrechte braucht (zum Beispiel die Installation eines Programms): Der Bildschirm sollte sich abdunkeln.

**Typische Fehler.** Der klassische Fehler: die Einstellung auf „Deaktiviert“ zu setzen, weil Fernwartungstools die Abfrage nicht anzeigen. Wer per Fernzugriff arbeitet, sieht auf dem sicheren Desktop oft nur einen schwarzen Bildschirm oder gar nichts, weil das Fernwartungsprogramm im interaktiven Desktop läuft. Die Microsoft-Dokumentation nennt für diesen Fall die gesonderte Einstellung „Allow UIAccess applications to prompt for elevation without using the secure desktop“: Sie erlaubt es Programmen mit UIAccess, zum Beispiel der Windows-Remoteunterstützung, die Abfrage ohne sicheren Desktop anzuzeigen, und ist standardmäßig aus. Richtig ist, nur diese gezielte Ausnahme zu verwenden oder das Fernwartungsprodukt zu wechseln, nicht aber den sicheren Desktop global zu deaktivieren. Ein zweiter Fehler: Benutzer gewöhnen sich an Abfragen und klicken sie blind weg. Der sichere Desktop schützt nicht vor einem Benutzer, der immer „Ja“ klickt; hier hilft Schulung und das Vermeiden unnötiger Abfragen.

> **Praxisbeispiel**
>
> Der Helpdesk eines Dienstleisters meldet, dass er auf Kundenrechnern per Fernzugriff keine Installationen mehr durchführen kann, seit die Baseline aktiv ist. Statt die Baseline abzuschwächen, wechselt der Dienstleister auf ein Fernwartungsprodukt, das den sicheren Desktop unterstützt, und nutzt für Altfälle die UIAccess-Ausnahme in einer eng begrenzten Pilotgruppe.

## 9 Anonyme SID-Auflösung verhindern

| **Feld**        | **Steckbrief**                                                                                                          |
|:----------------|:------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Sicherheitsoptionen |
| Einstellung     | Netzwerkzugriff: Anonyme SID-/Namensübersetzung zulassen                                                                |
| Empfehlung      | Deaktiviert                                                                                                             |
| Ziel / Zweck    | Reduziert Informationsabfluss über Konten                                                                               |
| Zielbereich     | Computer                                                                                                                |
| Priorität       | 1                                                                                                                       |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                             |

Jedes Konto in Windows hat zwei Bezeichner: den lesbaren Namen und die *SID* (Security Identifier), eine eindeutige Zeichenfolge wie `S-1-5-21-...-500`. Windows übersetzt zwischen beiden Formen mit Funktionen der *Local Security Authority*, kurz LSA (`LookupAccountSid`, `LookupAccountName`). Die Richtlinie bestimmt, ob diese Übersetzung auch für *anonyme* Aufrufer möglich ist, also für Verbindungen, die sich nicht authentifiziert haben (*Null Session*). Ist das erlaubt, kann ein Angreifer ohne Anmeldung die SID einer Domäne ermitteln, SIDs durchzählen und so Kontonamen ausspähen, darunter das umbenannte Administratorkonto aus Abschnitt 6, denn dessen SID endet weiterhin auf 500.

Der Lehrplan setzt die Einstellung auf „Deaktiviert“. Das bedeutet: Ein nicht angemeldeter Aufrufer erhält keine Auflösung von SIDs in Namen. Authentifizierte Benutzer sind nicht betroffen. In aktuellen Windows-Versionen ist diese Einstellung nach meiner Kenntnis bereits standardmäßig deaktiviert; das sollte man aber im Pilot mit `secedit /export` prüfen und nicht voraussetzen, weil ältere Abbilder, Migrationen oder frühere Gruppenrichtlinien abweichende Werte hinterlassen können. Das Erzwingen per Richtlinie sorgt dafür, dass der Zustand dauerhaft gilt.

Die Einstellung ist wie die vorigen Sicherheitsoptionen in der Vorlage im Abschnitt `[System Access]` abgelegt. Das folgende Beispiel exportiert zuerst den aktuellen Stand, wendet dann den gewünschten Wert an und zeigt, wie man das Ergebnis liest. Die Befehle ändern nur den lokalen Rechner und sind für einen Testrechner unkritisch.

```inf
; Datei: sid-aufloesung.inf
[Unicode]
Unicode=yes
[Version]
signature="$CHICAGO$"
Revision=1
[System Access]
LSAAnonymousNameLookup = 0
```

```ps
# Ist-Zustand exportieren und suchen
secedit /export /cfg "$env:TEMP\ist.inf" /areas SECURITYPOLICY
Select-String -Path "$env:TEMP\ist.inf" -Pattern "LSAAnonymousNameLookup"

# Sollwert anwenden
secedit /configure /db "$env:TEMP\sid.sdb" /cfg "C:\Test\sid-aufloesung.inf" /areas SECURITYPOLICY
```

`secedit /export` schreibt die aktuelle Sicherheitsrichtlinie in eine Textdatei, in der `Select-String` nach dem Schlüssel sucht; steht dort `0`, ist die anonyme Auflösung aus. Der Schlüssel `LSAAnonymousNameLookup = 0` in der Vorlage entspricht dem Wert „Deaktiviert“. Der Konfigurationsaufruf ist derselbe wie in den vorigen Abschnitten.

**Typische Fehler.** Falsch ist, diese Einstellung mit anderen „anonymen“ Einstellungen zu verwechseln (zum Beispiel dem Aufzählen von SAM-Konten oder Freigaben); sie sind eigene Richtlinien in derselben Gruppe und müssen einzeln beurteilt werden. Richtig ist, jede der Einstellungen bewusst zu setzen und zu dokumentieren. Ein praktischer Stolperstein: Sehr alte Anwendungen oder Domänenvertrauensstellungen zu Windows-NT-Domänen können Anonymität voraussetzen. Heute ist das selten, aber in Altumgebungen von Behörden und Industrie nicht ausgeschlossen. Wenn nach der Umstellung Berechtigungsdialoge in Freigaben Namen nicht mehr auflösen, liegt das meist an Authentifizierungsproblemen und nicht an dieser Richtlinie; prüfen Sie zuerst die Verbindung.

> **Praxisbeispiel**
>
> Ein Sicherheitsscanner meldet „Null-Session-Enumeration möglich“. Häufig liegt die Ursache bei einem Server-Altsystem oder einem Gerät, das nicht von der GPO erfasst wird, nicht bei den Clients. Nutzen Sie die Scannerliste, um fehlende Geräte in die OU-Struktur zu holen.

## 10 LAN Manager Hash Speicherung verhindern

| **Feld**        | **Steckbrief**                                                                                                          |
|:----------------|:------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Sicherheitsoptionen |
| Einstellung     | Netzwerksicherheit: Keine LAN Manager-Hashwerte speichern                                                               |
| Empfehlung      | Aktiviert                                                                                                               |
| Ziel / Zweck    | Verhindert veraltete unsichere Hashspeicherung                                                                          |
| Zielbereich     | Computer                                                                                                                |
| Priorität       | 1                                                                                                                       |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                             |

Windows speichert Kennwörter nicht im Klartext, sondern als *Hash*, eine Einwegfunktion, aus der sich das Kennwort nicht direkt zurückrechnen lässt. Historisch wurden zwei Hashes pro Konto abgelegt: der moderne *NT-Hash* und der alte *LM-Hash* (*LAN Manager*). Der LM-Hash stammt aus einer Zeit, in der Kennwörter höchstens 14 Zeichen lang waren: Er unterscheidet nicht zwischen Groß- und Kleinschreibung und teilt das Kennwort in zwei unabhängige Hälften zu je sieben Zeichen, die einzeln berechnet werden. Dadurch lässt sich ein LM-Hash mit modernen Mitteln sehr schnell knacken. Microsoft nennt ihn ausdrücklich „relativ schwach und anfällig für Angriffe“ im Vergleich zum NT-Hash.

Die Richtlinie „Netzwerksicherheit: Keine LAN Manager-Hashwerte beim nächsten Kennwortwechsel speichern“ (Registrywert `NoLMHash`) verhindert, dass der LM-Hash überhaupt erzeugt wird. Wichtig ist der Wirkungszeitpunkt: Die Einstellung wirkt erst *beim nächsten Kennwortwechsel*. Vorhandene LM-Hashes bleiben bis dahin gespeichert. Microsoft weist darauf hin, dass man das Kennwort aller Konten ändern muss, um den vollen Nutzen zu erzielen, und dass man das fehlende Sofortverhalten nicht sofort bemerkt, weil mögliche Kompatibilitätsprobleme erst später auftreten. Ein Kennwort mit mindestens 15 Zeichen erzeugt ohnehin keinen verwendbaren LM-Hash, weil das Verfahren nur bis 14 Zeichen funktioniert; auch das ist ein weiterer Grund für die Kennwortlänge aus Abschnitt 3.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Policy-CSP-Dokumentation ist die Einstellung ab Windows Vista standardmäßig aktiviert (unter Windows XP war sie deaktiviert), und die entsprechende CSP-Richtlinie ist als veraltet („deprecated“) gekennzeichnet. Die Gruppenrichtlinie ist trotzdem sinnvoll, weil sie Abweichungen durch alte Konfigurationen verhindert und von Audits geprüft wird. Kompatibilitätsprobleme sind laut Microsoft nur zu erwarten, wenn Windows-95- oder Windows-98-Clients (ohne Directory Services Client) oder alte Macintosh-Outlook-2001-Clients im Netz sind.

Das folgende Beispiel setzt die Einstellung über die Registry in einer GPO und zeigt, wie man auf einem Rechner prüft, ob sie aktiv ist. Es nutzt dasselbe Muster wie in Abschnitt 7. Es ändert die Domäne, wenn es auf eine Produktiv-GPO angewendet wird; deshalb wird hier eine neue Test-GPO angelegt und nur mit der Pilot-OU verknüpft. OU und Namen sind Platzhalter.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "SEC-NoLMHash"

Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" `
    -ValueName NoLMHash -Type DWord -Value 1

New-GPLink -Name $gpo.DisplayName -Target "OU=Pilot-Clients,DC=firma,DC=local"

# Pruefung am Client (nach gpupdate /force)
(Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa").NoLMHash
```

Die GPO wird angelegt, der Wert `NoLMHash` im Schlüssel `Lsa` auf 1 gesetzt (aktiviert) und die GPO an die Pilot-OU gebunden. Die letzte Zeile liest den Wert am Client aus; fehlt der Wert, gilt der Windows-Standard (aktiviert), laut Baseline ist „nicht vorhanden“ oder 1 konform. Für den Betrieb heißt das: Für den vollen Nutzen müssen Kennwörter anschließend wechseln, was bei einer Umstellung auf 14 Zeichen (Abschnitt 3) ohnehin geschieht.

**Typische Fehler.** Falsch ist die Annahme, mit dem Aktivieren der Richtlinie seien alle LM-Hashes gelöscht. Sie bleiben in der Datenbank, bis das Kennwort geändert wird. Richtig ist, die Richtlinie zu setzen und anschließend einen planmäßigen Kennwortwechsel (oder das Zurücksetzen von Servicekonten) einzuplanen. Ein weiterer Fehler ist, zu vergessen, dass LM-Authentifizierung (Protokollebene) und LM-Hash (Speicherung) verschiedene Dinge sind: Die Protokollebene steuert die Einstellung „LAN Manager-Authentifizierungsebene“ und gehört nicht zu dieser Richtlinie. Beides sollte in einer Baseline gesetzt sein, aber getrennt geprüft werden.

> **Praxisbeispiel**
>
> Bei einer Migration auf neue Domänencontroller entdeckt ein Team, dass auf einem alten NAS-Gerät Freigaben nur mit LM-kompatiblen Konten funktionieren. Die Konsequenz ist nicht, die Richtlinie abzuschalten, sondern das NAS zu aktualisieren oder zu ersetzen. Genau solche Befunde erzeugt der Pilot, und deshalb gehört er zum Lehrplan.

## Übungsaufgaben zu Modul 01

**Aufgabe 1.** **(leicht)** Erklären Sie in eigenen Worten den Unterschied zwischen Kontosperrungsschwelle, Kontosperrdauer und Beobachtungsfenster.

**Aufgabe 2.** **(leicht)** Warum wirkt die Kontosperrungsschwelle für Domänenkonten nicht, wenn sie in einer GPO steht, die an eine Client-OU verknüpft ist?

**Aufgabe 3.** **(leicht)** Nennen Sie zwei Gründe, warum das Umbenennen des Administratorkontos allein keinen ausreichenden Schutz bietet.

**Aufgabe 4.** **(mittel)** Welche Einstellung muss zusammen mit der Kennwortchronik gesetzt werden, damit sie nicht durch schnelles Mehrfachändern umgangen wird? Begründen Sie.

**Aufgabe 5.** **(mittel)** Ein Fernwartungsprodukt zeigt UAC-Abfragen nicht an. Welche gezielte Alternative gibt es zum globalen Deaktivieren des sicheren Desktops, und welche Einschränkung hat sie?

**Aufgabe 6.** **(praktisch)** Schreiben Sie ein PowerShell-Skript, das in der Testdomäne die Domänenwerte auf Schwelle 10, Dauer 15 Minuten, Beobachtungsfenster 15 Minuten, Länge 14, Chronik 24 und Mindestalter 1 Tag setzt und die Ergebnisse danach ausgibt.

**Aufgabe 7.** **(praktisch)** Schreiben Sie eine Sicherheitsvorlage (INF), die das Gastkonto deaktiviert und die anonyme Namensauflösung verbietet. Beschreiben Sie, wie Sie das Ergebnis mit `secedit /export` prüfen.

**Aufgabe 8.** **(schwer)** Entwerfen Sie einen Pilotplan für die Kennwortrichtlinie (Abschnitte 1 bis 4) in einer Domäne mit 800 Benutzern, bei der eine Pilot-OU nicht ausreicht. Welche Technik verwenden Sie, wie lange pilotieren Sie, und welche Kennzahlen beobachten Sie?

## Lösungen zu Modul 01

**Lösung 1.** Die Schwelle legt fest, *wie viele* Fehlversuche zur Sperre führen. Die Dauer legt fest, *wie lange* das Konto danach gesperrt bleibt. Das Beobachtungsfenster legt fest, *wie lange* ein Fehlversuch gezählt wird, bevor der Zähler auf null zurückfällt. Das Fenster darf nicht größer sein als die Dauer. Erst alle drei zusammen bestimmen die maximale Ratengeschwindigkeit eines Angreifers.

**Lösung 2.** Kontorichtlinien für Domänenkonten werden nur aus einer Richtlinie gelesen, die an die Domäne verknüpft ist (praktisch die Default Domain Policy); Richtlinien an OUs betreffen nur die lokalen Konten der Rechner in der OU. Für abweichende Gruppen dienen PSOs.

**Lösung 3.** Erstens bleibt die SID mit der Endung 500 erhalten, sodass das Konto über SID-Auflösung auffindbar ist. Zweitens schützt der Name nicht gegen Erraten oder Wiederverwenden des Kennworts; dafür braucht man eindeutige, rotierte Kennwörter (Windows LAPS).

**Lösung 4.** Das minimale Kennwortalter (mindestens 1 Tag). Ohne Mindestalter kann ein Benutzer das Kennwort so oft hintereinander ändern, bis das alte Kennwort wieder aus der Chronik fällt.

**Lösung 5.** Die Einstellung „Allow UIAccess applications to prompt for elevation without using the secure desktop“ erlaubt es UIAccess-Programmen (zum Beispiel Windows-Remoteunterstützung), die Abfrage außerhalb des sicheren Desktops anzuzeigen. Sie wirkt nur für Programme mit UIAccess und beeinflusst nicht das Verhalten der Abfrage für Administratoren; sie ist standardmäßig aus.

**Lösung 6.** Die Lösung entspricht den Beispielen aus den Abschnitten 1 bis 4: Ein einziger `Set-ADDefaultDomainPasswordPolicy`-Aufruf mit `-LockoutThreshold 10 -LockoutDuration 00:15:00 -LockoutObservationWindow 00:15:00 -MinPasswordLength 14 -PasswordHistoryCount 24 -MinPasswordAge 1.00:00:00`, danach `Get-ADDefaultDomainPasswordPolicy` zur Ausgabe. Wichtig ist, dass das Fenster nicht größer als die Dauer ist und die Domäne mit `-Identity` angegeben wird.

**Lösung 7.** Die Vorlage braucht die Köpfe `[Unicode]` und `[Version]` und im Abschnitt `[System Access]` die Zeilen `EnableGuestAccount = 0` und `LSAAnonymousNameLookup = 0`. Prüfen: `secedit /export /cfg ist.inf /areas SECURITYPOLICY` und danach mit `Select-String` nach beiden Schlüsseln suchen; beide müssen den Wert 0 haben.

**Lösung 8.** Eine Pilot-OU funktioniert für Domänenkonten nicht, daher PSO für eine Pilotgruppe (zum Beispiel 40 Benutzer aus IT, Fachbereichen und Helpdesk) mit höherer Priorität. Pilotdauer mindestens ein vollständiger Kennwortwechselzyklus beziehungsweise zwei bis vier Wochen. Kennzahlen: Helpdesk-Tickets zu Kennwort und Sperrungen, Ereignisse 4740, Fehlerquoten bei Diensten und Fachanwendungen, Benutzerfeedback. Anschließend Wechsel der Werte in die Default Domain Policy und Entfernen der PSO, falls sie identisch ist.
