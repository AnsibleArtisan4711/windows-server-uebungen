# Modul 06 - Anwendungssteuerung und Browser

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Gruppenrichtlinien für Windows 11 – 100 Richtlinien im Detail“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Steckbriefe als Tabellen, Übungsaufgaben und Lösungen als fortlaufend nummerierte Absätze). **Nummerierung:** Die Überschriften der Richtlinien tragen hier die laufende Nummer 1 bis 100 aus der Modultabelle; die Verweise im Text („Abschnitt 43“) meinen diese Nummer. (Im LaTeX-Satz zählen die Überschriften je Modul neu, etwa 5.3.) **Die Beispiele (PowerShell, INF) wurden für dieses Repository nicht ausgeführt**; sie verändern Gruppenrichtlinien, Registry und Sicherheitseinstellungen und gehören nur in eine Testumgebung (Pilot-OU, Testdomäne). Übersicht zum Modul: [README](README.md).

**Dauer:** 10 Unterrichtsstunden (Annahme: 1 Stunde je Richtlinie)  
**Priorität:** 1 und 2 (fünf Richtlinien je Stufe)

| Nr. | Lerneinheit (Richtlinie)            | Prio | Stunden |
|----:|:------------------------------------|:----:|:-------:|
|  51 | SmartScreen aktivieren              |  1   |    1    |
|  52 | Edge SmartScreen aktivieren         |  1   |    1    |
|  53 | Edge Passwortmanager steuern        |  2   |    1    |
|  54 | Edge Erweiterungen kontrollieren    |  1   |    1    |
|  55 | IE-Modus nur für definierte Sites   |  2   |    1    |
|  56 | Microsoft Store Zugriff steuern     |  2   |    1    |
|  57 | App Installer einschränken          |  1   |    1    |
|  58 | App Control for Business auditieren |  2   |    1    |
|  59 | Makros aus Internet blockieren      |  1   |    1    |
|  60 | Windows Script Host einschränken    |  2   |    1    |
|     | **Summe**                           |      | **10**  |

**Worum es in diesem Modul geht.** Fast jeder Angriff beginnt damit, dass der Benutzer etwas ausführt: eine heruntergeladene Datei, eine Browsererweiterung, ein Office-Dokument mit Makro, ein Skript. Dieses Modul zeigt, wie man das auf drei Ebenen einschränkt. Die erste Ebene ist die *Reputationsprüfung* beim Download (SmartScreen, Abschnitte 51 und 52). Die zweite ist die *Kontrolle der Software-Zufuhr*: welche Erweiterungen, welche Store-Apps, welche Installer erlaubt sind (53 bis 57). Die dritte ist die *Kontrolle der Ausführung* selbst: Allowlisting mit App Control, Makroblockade und Skript-Host (58 bis 60). Die Edge-Richtlinien setzen voraus, dass die ADMX-Vorlagen von Microsoft Edge (`msedge.admx`) im zentralen Richtlinienspeicher liegen; die Vorlagen sind getrennt von Windows erhältlich. Die Edge-Registrywerte liegen unter `HKLM\SOFTWARE\Policies\Microsoft\Edge`.

## 51 SmartScreen aktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Datei-Explorer   |
| Einstellung     | Windows Defender SmartScreen konfigurieren                                                  |
| Empfehlung      | Warnen und Ausführung verhindern                                                            |
| Ziel / Zweck    | Schützt vor unbekannten Downloads                                                           |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

*SmartScreen* ist ein Reputationsdienst von Microsoft. Beim Start einer heruntergeladenen Datei fragt Windows (anhand von Hashwert und Signatur) bei Microsoft nach, ob die Datei bekannt und unbedenklich ist. Eine Datei, die niemand sonst kennt oder die als schädlich gemeldet wurde, löst eine Warnung aus. Technisch stützt sich das auf das *Mark of the Web*: Windows versieht Dateien aus dem Internet auf NTFS-Laufwerken mit einer Zusatzinformation (`Zone.Identifier`), die die Herkunftszone enthält. Laut Microsoft ist dies nur für Dateien auf NTFS, nicht auf FAT32-Medien, wirksam; wichtig, weil Angreifer gern Container (ISO-Dateien, ZIP-Archive) nutzen, um die Markierung zu umgehen.

Die Richtlinie im Datei-Explorer-Zweig hat zwei Stufen: „Warnen“ (der Benutzer kann trotzdem ausführen) und „Warnen und Umgehen verhindern“ (der Benutzer kann nicht auf „Trotzdem ausführen“ klicken). Der Lehrplan verlangt die zweite Stufe. Das ist deutlich strenger, denn unbekannte Dateien (auch eigene Tools, interne Installer) werden dann blockiert, bis sie ein Administrator freigibt. Nach meiner Kenntnis (nicht abgerufen) schreibt die Richtlinie die Werte `EnableSmartScreen` und `ShellSmartScreenLevel` in den Schlüssel `HKLM\SOFTWARE\Policies\Microsoft\Windows\System`.

> **Ergänzung aus der Nachrecherche**
>
> Die Reputationsprüfung benötigt Internetzugang zu den SmartScreen-Diensten von Microsoft. Ohne Verbindung kann Windows die Datei nicht bewerten. Interne Software sollte daher signiert werden: Eine gültige Codesignatur eines bekannten Herausgebers verbessert die Reputation. Für Dateien auf internen Freigaben hängt die Markierung von der Zone ab (Intranet-Zone: keine Markierung, siehe auch Abschnitt 59).

Das Beispiel setzt die strenge Stufe und zeigt, wie man eine Testdatei als „aus dem Internet“ markiert und die Markierung ausliest. Das Anlegen der Markierung mit `Set-Content -Stream` ist Standard-PowerShell auf NTFS. Die Registrywerte sind aus meiner Kenntnis und im Pilot zu prüfen.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "SEC-SmartScreen-Explorer"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\System"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName EnableSmartScreen     -Type DWord  -Value 1
# Warn = nur warnen, Block = warnen und Umgehen verhindern
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName ShellSmartScreenLevel -Type String -Value "Block"

# Testdatei als "aus dem Internet" markieren (ZoneId 3) und Markierung lesen
$f = "$env:TEMP\test.txt"
"Testinhalt" | Set-Content $f
Set-Content -Path $f -Stream Zone.Identifier -Value "[ZoneTransfer]`r`nZoneId=3"
Get-Content -Path $f -Stream Zone.Identifier
Unblock-File $f        # entfernt die Markierung wieder
```

Die ersten Zeilen schalten SmartScreen ein und wählen die Stufe „Block“. Der zweite Teil erzeugt eine Testdatei, schreibt in den Alternativen Datenstrom `Zone.Identifier` die Zone 3 (Internet; Werte 0 bis 4 laut Microsoft: 0 Arbeitsplatz, 1 Intranet, 2 vertrauenswürdige Sites, 3 Internet, 4 eingeschränkte Sites) und liest ihn aus. `Unblock-File` entfernt die Markierung wieder, genau wie das Kontrollkästchen „Zulassen“ in den Dateieigenschaften.

**Typische Fehler.** Falsch: die Stufe „Warnen und Umgehen verhindern“ ohne Ausnahmeprozess auszurollen. Interne Tools werden blockiert, und die Benutzer weichen auf Umwege aus. Richtig: eigene Software signieren, einen Freigabeprozess (Administrator entfernt die Markierung nach Prüfung) festlegen. Zweiter Fehler: sich auf SmartScreen als einzigen Schutz zu verlassen; Reputationsprüfung erkennt neue, gezielte Schadsoftware oft nicht. Dritter Fehler: zu vergessen, dass Archive, die selbst markiert sind, ihre Markierung nicht immer auf den Inhalt vererben.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Mitarbeiter lädt ein angebliches PDF-Werkzeug aus dem Internet. SmartScreen kennt die Datei nicht und blockiert den Start; die Umgehung ist per Richtlinie deaktiviert. Der Mitarbeiter meldet sich beim Helpdesk, der die Datei als unerwünscht einstuft.

## 52 Edge SmartScreen aktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Edge \> SmartScreen           |
| Einstellung     | Microsoft Defender SmartScreen konfigurieren                                                |
| Empfehlung      | Aktiviert                                                                                   |
| Ziel / Zweck    | Schützt Browserzugriffe                                                                     |
| Zielbereich     | Computer/User                                                                               |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Die SmartScreen-Funktion im Browser prüft zwei Dinge: ob eine aufgerufene *Webseite* als Phishing- oder Malware-Seite bekannt ist und ob eine *heruntergeladene Datei* Reputation hat. Das ist nicht dasselbe wie die Prüfung im Datei-Explorer (Abschnitt 51): Der Browser prüft früher, schon beim Seitenaufruf und Download, der Explorer beim Start der Datei. Beide Schichten ergänzen sich. Die Edge-Richtlinie „Configure Microsoft Defender SmartScreen“ (`SmartScreenEnabled`) schaltet die Seitenprüfung ein; mit `PreventSmartScreenPromptOverride` verhindert man, dass Benutzer Warnungen zu Seiten übergehen, und mit `PreventSmartScreenPromptOverrideForFiles` dasselbe für Downloads.

Die Edge-Richtlinien kommen aus einer eigenen ADMX-Datei (`msedge.admx`), die man separat herunterladen und in den zentralen Richtlinienspeicher legen muss. Die Richtlinien haben zwei Ablageorte: den Pfad „Microsoft Edge“ (verbindlich) und den Pfad „Microsoft Edge - Default Settings (users can override)“ (empfohlen), wie die Microsoft-Dokumentation beim Beispiel `PasswordManagerEnabled` zeigt: Die verbindliche Variante liegt im Registryschlüssel `SOFTWARE\Policies\Microsoft\Edge`, die empfohlene unter `...\Edge\Recommended`. Für Sicherheitsfunktionen setzt man grundsätzlich die verbindliche Variante.

> **Merke**
>
> Edge-Richtlinien können *verbindlich* (Benutzer kann nicht ändern) oder *empfohlen* (Benutzer kann abweichen) gesetzt werden. Nicht jede Richtlinie bietet beide Varianten; die Dokumentation führt dies unter „Can be mandatory / Can be recommended“ je Richtlinie auf.

Das Beispiel setzt die drei Richtlinien. Die Registrywerte (Namen wie in der Edge-Richtliniendokumentation) liegen im Schlüssel `SOFTWARE\Policies\Microsoft\Edge`, wie die Microsoft-Dokumentation es am Beispiel zeigt; die Namen der drei SmartScreen-Werte sind aus meiner Kenntnis und im Pilot gegen die Edge-Vorlage zu prüfen.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "EDGE-SmartScreen"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Edge"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName SmartScreenEnabled                      -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName PreventSmartScreenPromptOverride        -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName PreventSmartScreenPromptOverrideForFiles -Type DWord -Value 1

# Am Client: im Browser edge://policy aufrufen; hier die Registry kontrollieren
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" |
    Select-Object SmartScreenEnabled, PreventSmartScreenPromptOverride, PreventSmartScreenPromptOverrideForFiles
```

Alle drei Werte stehen auf 1. Wichtig für die Kontrolle ist die Seite `edge://policy` im Browser: Sie zeigt alle gesetzten Richtlinien, ihre Quelle und etwaige Konflikte. Die Registryabfrage ist nur die technische Gegenprobe.

**Typische Fehler.** Falsch: die Edge-Richtlinien zu erstellen, ohne dass die ADMX-Datei im zentralen Speicher liegt; im Editor erscheint der Zweig dann nicht. Richtig: Vorlagen von Microsoft herunterladen und in den Central Store kopieren. Zweiter Fehler: Richtlinien in der Computer- und der Benutzerkonfiguration gegensätzlich zu setzen; bei Konflikten gilt nach meiner Kenntnis die Computerseite, im Zweifel `edge://policy` prüfen. Dritter Fehler: andere Browser zu vergessen; Chrome oder Firefox haben eigene Richtlinien, oder man verhindert ihre Installation.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Mitarbeiter folgt einem Phishing-Link zu einer gefälschten Anmeldeseite. SmartScreen blockiert die Seite, und der Benutzer kann die Warnung nicht überspringen. Das Ereignis wird im Defender-Portal sichtbar.

## 53 Edge Passwortmanager steuern

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Edge \> Passwort-Manager      |
| Einstellung     | Speichern von Kennwörtern anbieten                                                          |
| Empfehlung      | Nach Passwortstrategie                                                                      |
| Ziel / Zweck    | Verhindert unsichere lokale Kennwortspeicherung                                             |
| Zielbereich     | Computer/User                                                                               |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Ein Browser-Passwortmanager speichert Kennwörter und füllt sie automatisch ein. Das ist bequem und hilft gegen schwache, wiederverwendete Kennwörter; es ist aber auch ein Ziel für Angreifer, zum Beispiel für bösartige Erweiterungen. Die Microsoft-Dokumentation sagt dazu: Eine Erweiterung mit der Berechtigung, mit einer Seite zu interagieren, kann alles lesen, was auf der Seite steht, auch ein automatisch ausgefülltes Kennwort. Deshalb nennt Microsoft eine Liste von Richtlinien zur Erweiterungssteuerung (Abschnitt 54) als nötig, um Unternehmensdaten zu schützen. Die Entscheidung „Passwortmanager ja oder nein“ ist also eine Strategiefrage, die mit der Erweiterungskontrolle zusammenhängt.

Die zentrale Richtlinie ist `PasswordManagerEnabled` („Enable saving passwords to the password manager“). Laut Microsoft gilt: Ist sie aktiviert oder nicht konfiguriert, können Benutzer Kennwörter speichern. Ist sie *deaktiviert*, können Benutzer keine neuen Kennwörter speichern oder hinzufügen, *aber bereits gespeicherte Kennwörter weiterhin verwenden*. Das ist eine wichtige Einschränkung: Die Richtlinie räumt vorhandene Kennwörter nicht auf. Weitere Richtlinien in derselben Gruppe sind unter anderem `PasswordExportEnabled` (Export gespeicherter Kennwörter), `PasswordManagerBlocklist` (Domänenliste, für die die Speichern/Ausfüllen-Oberfläche abgeschaltet wird), `PasswordMonitorAllowed` (Warnung bei kompromittierten Kennwörtern) und `PasswordProtectionLoginURLs`, womit Edge Hashes von Unternehmenskennwörtern erkennen kann, wenn sie auf fremden Seiten eingegeben werden.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft-Dokumentation liegen die Richtlinien im ADMX-Pfad „Administrative Templates/Microsoft Edge/Password manager and protection“. Der Wert `PasswordManagerEnabled` ist vom Typ REG_DWORD, unterstützt ab Edge 77, und kann verbindlich oder empfohlen gesetzt werden. Ob man den Passwortmanager erlaubt, hängt von der Strategie ab: Wer einen zentralen Unternehmens-Passwortmanager einsetzt, schaltet den Browserspeicher ab; wer keinen hat, fährt mit gesichertem Browserspeicher (Gerätebestätigung, Exportsperre) oft besser als mit Kennwortlisten in Tabellen.

Das folgende Beispiel zeigt die restriktive Variante (Speichern aus, Export aus, Kennwortwarnungen an). Die drei Richtlinien stammen aus der Edge-Richtlinienliste; die Werte werden im Schlüssel `HKLM\SOFTWARE\Policies\Microsoft\Edge` gesetzt, wie die Dokumentation zu `PasswordManagerEnabled` es beschreibt.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "EDGE-Passwoerter"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Edge"
# Neue Kennwoerter nicht mehr speichern (vorhandene bleiben nutzbar!)
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName PasswordManagerEnabled -Type DWord -Value 0
# Export gespeicherter Kennwoerter verbieten
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName PasswordExportEnabled  -Type DWord -Value 0
# Warnung bei kompromittierten Kennwoertern erlauben
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName PasswordMonitorAllowed -Type DWord -Value 1
```

Die erste Zeile verhindert neue Einträge, die zweite den Export, die dritte lässt die Überwachung auf bekannte Datenlecks zu. Bereits vorhandene Kennwörter bleiben nach der Dokumentation nutzbar; wer sie entfernen will, braucht einen eigenen Schritt (Profilbereinigung oder Anleitung an die Benutzer).

**Typische Fehler.** Falsch: zu glauben, `PasswordManagerEnabled = 0` lösche bestehende Kennwörter. Die Daten bleiben und sind weiter verwendbar. Richtig: den Bestand mit Benutzerkommunikation und gegebenenfalls Profilbereinigung behandeln. Zweiter Fehler: den Browserspeicher zu sperren, ohne eine Alternative anzubieten; die Benutzer schreiben dann Kennwörter auf oder wiederholen sie. Dritter Fehler: die Richtlinie einzusetzen und bösartige Erweiterungen nicht zu kontrollieren; ohne Abschnitt 54 bleibt das Risiko bestehen.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Unternehmen führt einen zentralen Passwortmanager ein. Der Browserspeicher wird per Richtlinie für neue Einträge gesperrt, und die Mitarbeiter bekommen eine Anleitung zum Import der vorhandenen Kennwörter in den neuen Tresor.

## 54 Edge Erweiterungen kontrollieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Edge \> Erweiterungen         |
| Einstellung     | Erweiterungsinstallation blockieren/zulassen                                                |
| Empfehlung      | Allowlist für genehmigte Erweiterungen                                                      |
| Ziel / Zweck    | Reduziert Browser-Angriffsoberfläche                                                        |
| Zielbereich     | Computer/User                                                                               |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Browsererweiterungen sind kleine Programme, die im Browser laufen und weitreichende Rechte haben können: Seiteninhalte lesen, Formulare verändern, Netzwerkverkehr einsehen. Eine bösartige oder übernommene Erweiterung ist daher ein starker Angriffsweg. Das Sicherheitsprinzip ist die *Allowlist*: Alles ist verboten, nur ausdrücklich genehmigte Erweiterungen sind erlaubt. Genau das beschreibt die Microsoft-Dokumentation: Man trägt in der Richtlinie „Control which extensions cannot be installed“ (`ExtensionInstallBlocklist`) den Platzhalter `*` ein, wodurch alle Erweiterungen blockiert werden, und erlaubt mit „Allow specific extensions to be installed“ (`ExtensionInstallAllowlist`) einzelne Erweiterungen anhand ihrer ID.

Die Details sind wichtig. Laut Microsoft werden bereits installierte Erweiterungen, die auf die Blockliste kommen, *deaktiviert, nicht deinstalliert*, und der Benutzer kann sie nicht wieder aktivieren; nach dem Entfernen von der Liste werden sie automatisch wieder aktiviert. Bei `*` gilt: ausdrücklich erlaubte Erweiterungen sind zulässig, wenn sie signiert (gepackt) sind, *alle ungepackten Erweiterungen* (Entwicklermodus) sind blockiert. Die Erweiterungs-ID findet man am Ende der Adresse in der Edge-Add-ons-Seite. Für größere Umgebungen gibt es die mächtigere Richtlinie `ExtensionSettings` (ein JSON-Text): Sie *ersetzt* laut Microsoft andere Erweiterungs-Richtlinien und ermöglicht zum Beispiel, alle Erweiterungen eines Fremdstores zu blockieren. Wer `ExtensionSettings` verwendet, sollte die anderen Richtlinien nicht mehr parallel pflegen.

> **Ergänzung aus der Nachrecherche**
>
> Aus der Dokumentation zu den Edge-Richtlinien: `BlockExternalExtensions` verhindert externe Installationen (zum Beispiel durch Fremdsoftware), `ExtensionAllowedTypes` beschränkt die Art, `ExtensionInstallForcelist` installiert Erweiterungen still und erzwungen, `ExtensionInstallSources` legt fest, woher Erweiterungen kommen dürfen. Die Registrypfade der Listen sind `SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallBlocklist` mit den Werten `1, 2, 3, ...` vom Typ REG_SZ. Die Richtlinie `ExtensionInstallBlocklist` kann nur verbindlich, nicht empfohlen gesetzt werden.

Das Beispiel richtet die Allowlist-Strategie ein: alles blockieren, zwei Erweiterungen erlauben. Die Listenstruktur (nummerierte Werte unter dem Listenschlüssel) entspricht der Beschreibung in der Edge-Dokumentation. Die beiden IDs sind Platzhalter und müssen durch die geprüften IDs der genehmigten Erweiterungen ersetzt werden.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "EDGE-Erweiterungen-Allowlist"
$base = "HKLM\SOFTWARE\Policies\Microsoft\Edge"

# Alles blockieren
Set-GPRegistryValue -Name $gpo.DisplayName -Key "$base\ExtensionInstallBlocklist" `
    -ValueName 1 -Type String -Value "*"

# Genehmigte Erweiterungen (IDs sind Platzhalter, 32 Zeichen a-p)
$erlaubt = @("aaaabbbbccccddddeeeeffffgggghhhh", "iiiijjjjkkkkllllmmmmnnnnoooopppp")
$i = 1
foreach ($id in $erlaubt) {
    Set-GPRegistryValue -Name $gpo.DisplayName -Key "$base\ExtensionInstallAllowlist" `
        -ValueName $i -Type String -Value $id
    $i++
}
```

Der erste Befehl trägt `*` als Eintrag 1 der Blockliste ein. Die Schleife nummeriert die erlaubten IDs fortlaufend in der Allowlist. Auf dem Client zeigt `edge://policy`, ob die Listen angekommen sind, und `edge://extensions` zeigt deaktivierte Erweiterungen.

**Typische Fehler.** Falsch: die Allowlist zu aktivieren, ohne den Bestand zu kennen. Alle bisher genutzten Erweiterungen werden deaktiviert, und die Benutzer rufen an. Richtig: zuerst per Inventur ermitteln, welche Erweiterungen im Einsatz sind, bewerten und die nötigen vorab in die Allowlist aufnehmen. Zweiter Fehler: Erweiterungs-IDs falsch abzuschreiben; ein Zeichen daneben, und die Erweiterung bleibt blockiert. Dritter Fehler: `ExtensionSettings` und die Einzelrichtlinien zu mischen, ohne zu wissen, dass die erste die anderen überschreibt.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Mitarbeiter installiert eine kostenlose „PDF-Konverter“-Erweiterung, die heimlich Seiteninhalte an einen fremden Server sendet. Mit der Allowlist wäre die Installation gar nicht möglich gewesen. Die Anfrage nach der Erweiterung geht stattdessen an die IT, die sie prüft.

## 55 IE-Modus nur für definierte Sites

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Microsoft Edge                          |
| Einstellung     | Enterprise Mode Site List                                                                   |
| Empfehlung      | Nur definierte Legacy-Sites                                                                 |
| Ziel / Zweck    | Kontrolliert Legacy-Webkompatibilität                                                       |
| Zielbereich     | Computer/User                                                                               |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Manche Firmen betreiben noch interne Webanwendungen, die nur im alten Internet Explorer laufen (ActiveX-Steuerelemente, spezielle Dokumentmodi). Der Internet Explorer 11 als eigenständige Anwendung ist abgekündigt. Edge bietet aber den *Internet-Explorer-Modus* (IE-Modus): Einzelne Seiten werden innerhalb von Edge mit der alten Engine dargestellt. Das Ziel der Richtlinie ist, dass dieser Modus nur für eine *festgelegte Liste* alter Seiten gilt, nicht für beliebige. Der Grund: Die alte Engine hat viel mehr Angriffsfläche, und jede Seite darin ist ein Risiko. Der IE-Modus soll also eine Brückentechnik mit Verfallsdatum bleiben, kein Dauerzustand.

Zwei Richtlinien greifen ineinander. Die Richtlinie „Configure Internet Explorer integration“ (`InternetExplorerIntegrationLevel`) aktiviert die Integration im Modus „Internet Explorer mode“. Die Richtlinie „Configure the Enterprise Mode Site List“ (`InternetExplorerIntegrationSiteList`) verweist auf eine XML-Datei, die die Seiten auflistet, die im IE-Modus geöffnet werden sollen. Beide Namen stammen aus meiner Kenntnis der Edge-ADMX-Vorlage und sind im Pilot gegen den Editor zu prüfen. Die Liste liegt typischerweise auf einer internen Webadresse oder Freigabe, die nur Administratoren ändern dürfen.

> **Ergänzung aus der Nachrecherche**
>
> Nach meiner Kenntnis (nicht in dieser Recherche abgerufen) hat Microsoft zugesagt, den IE-Modus in Edge mindestens bis 2029 zu unterstützen, mit Vorankündigung vor einer Abkündigung. Der aktuelle Stand sollte vor einer Langzeitplanung auf der Microsoft-Seite zum IE-Modus geprüft werden. Unabhängig davon gilt: Jede Seite auf der Liste braucht einen Verantwortlichen und ein Datum, bis zu dem sie modernisiert oder abgeschaltet wird.

Das Beispiel zeigt eine kleine Site-Liste im XML-Format und die Richtlinien dazu. Das Format der Liste (Elemente `site-list`, `site`, `open-in`) stammt aus meiner Kenntnis; für die Erstellung größerer Listen gibt es von Microsoft ein Werkzeug (Enterprise Site List Manager). Die Adresse und der Pfad sind Platzhalter.

```ps
# 1) Site-Liste als XML erzeugen (auf interner Freigabe ablegen, schreibgeschuetzt)
$xml = @'
<site-list version="1">
  <created-by><tool>Handarbeit</tool><version>1</version><date-created>2026-01-01</date-created></created-by>
  <site url="altes-crm.intranet.example">
    <compat-mode>IE8Enterprise</compat-mode>
    <open-in>IE11</open-in>
  </site>
</site-list>
'@
Set-Content -Path "\\fileserver\it$\ie-liste.xml" -Value $xml -Encoding UTF8

# 2) Richtlinien setzen
Import-Module GroupPolicy
$gpo = New-GPO -Name "EDGE-IE-Modus"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Edge"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName InternetExplorerIntegrationLevel    -Type DWord  -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName InternetExplorerIntegrationSiteList -Type String -Value "https://intranet.example/ie-liste.xml"
```

Der erste Teil beschreibt die einzige Seite, die im IE-Modus laufen darf (`altes-crm.intranet.example`, Platzhalter). Der zweite Teil aktiviert die Integration und verweist auf die Liste über eine Webadresse. Der Wert `1` bei `InternetExplorerIntegrationLevel` steht nach meiner Kenntnis für den IE-Modus. Prüfen lässt sich das Ergebnis mit `edge://compat/enterprise` im Browser.

**Typische Fehler.** Falsch: die Liste auf einer schreibbaren Freigabe abzulegen; wer sie ändern kann, kann Seiten in den unsicheren Modus schalten. Richtig: Schreibrechte nur für Administratoren, Leserechte für Computerkonten. Zweiter Fehler: Platzhalter für ganze Domänen in die Liste zu schreiben („alles im Intranet“). Richtig: einzelne Anwendungen, wenn möglich mit Pfad. Dritter Fehler: die Liste nie zu bereinigen; Ablaufdaten fehlen, und der Notbehelf wird dauerhaft.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Hersteller betreibt eine alte Verwaltungsoberfläche für Maschinen, die nur im IE funktioniert. Die Seite steht als einzige auf der Liste. Ein Projekt zur Ablösung ist mit Datum hinterlegt; bis dahin ist die Gefahr auf diese eine Seite begrenzt.

## 56 Microsoft Store Zugriff steuern

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Store            |
| Einstellung     | Store-Anwendung deaktivieren oder einschränken                                              |
| Empfehlung      | Nach App-Strategie                                                                          |
| Ziel / Zweck    | Verhindert unkontrollierte App-Installation                                                 |
| Zielbereich     | Computer/User                                                                               |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Der Microsoft Store ist der offizielle Weg, moderne Windows-Apps (Paketformat MSIX/AppX) zu installieren. Für Privatpersonen ist er praktisch, für Firmen ein Risiko: Mitarbeiter installieren Spiele, Messenger oder zweifelhafte Werkzeuge, die niemand lizenziert oder geprüft hat. Der Lehrplan lässt die Wahl offen („nach App-Strategie“), und es gibt auch mehrere Stufen. Die erste ist, den Store komplett zu sperren (Richtlinie „Turn off the Store application“). Die zweite ist, den Store zu erlauben, aber nur den *privaten Store* der Organisation anzuzeigen (Richtlinie „Only display the private store within the Microsoft Store app“), in dem die IT ausgewählte Apps freigibt. Die dritte ist, Apps gezielt über Verteilungswerkzeuge (Intune, Konfigurationsmanager) auszurollen.

Ein Hinweis zur Einordnung, der aus meiner Kenntnis stammt: Die Store-Funktionalität hat sich in den letzten Jahren stark verändert (Microsoft Store for Business wurde eingestellt, das Winget-basierte Verteilen ist hinzugekommen). Daher ist die Einstellung in jedem Fall zusammen mit dem Verteilkonzept zu betrachten, und die Verfügbarkeit des privaten Stores ist vor der Planung zu prüfen. Das Sperren des Stores verhindert nicht automatisch, dass Apps mit anderen Mitteln installiert werden (zum Beispiel über Winget oder App Installer, Abschnitt 57).

> **Merke**
>
> Das Sperren des Stores ist eine Maßnahme gegen *ungeplante* Installationen, aber kein Ersatz für Anwendungssteuerung. Wer verhindern will, dass Software ausgeführt wird, braucht Allowlisting (Abschnitt 58). Der Store ist nur einer von mehreren Installationswegen.

Das Beispiel zeigt beide Stufen und prüft, welche Store-Apps auf einem Client vorhanden sind. Die Werte `RemoveWindowsStore` und `RequirePrivateStoreOnly` im Schlüssel `SOFTWARE\Policies\Microsoft\WindowsStore` stammen aus meiner Kenntnis der ADMX-Vorlage und sind im Pilot zu prüfen; `Get-AppxPackage` ist ein Standardbefehl.

```ps
Import-Module GroupPolicy
$key = "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore"

# Variante A: Store komplett sperren
$a = New-GPO -Name "STORE-gesperrt"
Set-GPRegistryValue -Name $a.DisplayName -Key $key -ValueName RemoveWindowsStore -Type DWord -Value 1

# Variante B: Store nur mit privatem Katalog
$b = New-GPO -Name "STORE-nur-privat"
Set-GPRegistryValue -Name $b.DisplayName -Key $key -ValueName RequirePrivateStoreOnly -Type DWord -Value 1

# Inventur am Client: welche Store-Apps haben die Benutzer installiert?
Get-AppxPackage -AllUsers |
    Where-Object { $_.SignatureKind -eq 'Store' -and -not $_.IsFramework } |
    Select-Object -First 25 Name, Publisher, Version
```

Variante A sperrt den Store, Variante B beschränkt ihn auf den privaten Katalog; man verknüpft nur eine der beiden mit einer OU. Die Inventurabfrage zeigt, welche Store-Apps im Bestand vorkommen, und bildet die Grundlage für die Entscheidung, welche Apps die IT bewusst bereitstellen will.

**Typische Fehler.** Falsch: den Store zu sperren, obwohl Windows-Komponenten (Terminal, Photos, Windows-Update für Store-Apps) über ihn aktualisiert werden. Fehlt die Updatemöglichkeit, bleiben sie veraltet. Richtig: Updates für Store-Apps auf anderem Weg sicherstellen oder den Store nicht komplett sperren. Zweiter Fehler: nur den Store zu sperren und Winget unberührt zu lassen. Dritter Fehler: keine Regel, wie Mitarbeiter Apps beantragen; ohne Prozess entsteht Schatten-IT.

> **Praxisbeispiel**
>
> Beispielszenario: Eine Schule sperrt den Store auf Schülergeräten und stellt die benötigten Lern-Apps über die Verwaltung bereit. Lehrkräfte beantragen neue Apps über ein Formular; die IT prüft Datenschutz und Lizenz.

## 57 App Installer einschränken

| **Feld**        | **Steckbrief**                                                                                    |
|:----------------|:--------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> App Package Deployment |
| Einstellung     | App Installer Richtlinien                                                                         |
| Empfehlung      | Nur vertrauenswürdige Quellen                                                                     |
| Ziel / Zweck    | Reduziert Sideloading-Risiken                                                                     |
| Zielbereich     | Computer                                                                                          |
| Priorität       | 1                                                                                                 |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.       |

*Sideloading* bedeutet, eine App am Store vorbei zu installieren, etwa durch Doppelklick auf eine `.msix`-Datei oder über einen Webverweis. Das Werkzeug dahinter heißt *App Installer* (auch Windows Package Manager, `winget`). Es ist praktisch, weil es Apps aus beliebigen Quellen installieren kann, und genau deshalb ein Risiko: Angreifer haben den App-Installer-Mechanismus genutzt, um Schadsoftware zu verbreiten, die wie eine normale Installation wirkt. Die Richtlinien in diesem Bereich erlauben es, die Funktionen gezielt einzuschränken.

Nach meiner Kenntnis (nicht in dieser Recherche abgerufen) umfassen die Richtlinien in der ADMX-Vorlage `DesktopAppInstaller.admx` unter anderem: „Enable App Installer“ (Funktion insgesamt), „Enable App Installer Experimental Features“, „Enable App Installer Hash Override“ (Umgehung einer Hashprüfung, sollte aus bleiben) und „Enable App Installer ms-appinstaller protocol“ (Installation über Weblinks). Das letzte Protokoll ist nach meiner Kenntnis seit Ende 2023 standardmäßig abgeschaltet, nachdem es für Angriffe missbraucht wurde. Außerdem gibt es im Bereich „App Package Deployment“ die Richtlinie „Allow all trusted apps to install“ (`AllowAllTrustedApps`), die regelt, ob signierte Apps von nicht-Store-Quellen installiert werden dürfen. Die genauen Namen und Standardwerte sollten im Pilot gegen die aktuelle Vorlage geprüft werden.

> **Ergänzung aus der Nachrecherche**
>
> Weil sich die App-Installer-Richtlinien mit den Winget-Versionen ändern, ist die Vorlagendatei aktuell zu halten und die Microsoft-Dokumentation zu „Windows Package Manager group policy“ zu Rate zu ziehen. Ergänzend können Quellen („Sources“) für Winget eingeschränkt werden, etwa auf ein internes Repository. Diese Detailfunktionen wurden in dieser Recherche nicht abgerufen.

Das Beispiel zeigt eine restriktive Konfiguration: App Installer nur für Administratoren nutzbar machen ist nicht Teil der Richtlinie; stattdessen werden Hash-Override und Protokoll abgeschaltet. Die Registrywerte (Schlüssel `SOFTWARE\Policies\Microsoft\Windows\AppInstaller`) sind aus meiner Kenntnis und im Pilot zu prüfen. Das Skript prüft zusätzlich auf dem Client, welche Winget-Quellen eingerichtet sind.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "APP-Installer-restriktiv"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppInstaller"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName EnableHashOverride          -Type DWord -Value 0
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName EnableMSAppInstallerProtocol -Type DWord -Value 0

# Nur signierte Apps ausserhalb des Stores zulassen? (App Package Deployment)
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx" `
    -ValueName AllowAllTrustedApps -Type DWord -Value 0

# Am Client: welche Winget-Quellen sind aktiv?
winget source list
```

Die ersten beiden Werte schalten die Hash-Umgehung und das Webprotokoll ab. Der dritte Wert verbietet laut meiner Kenntnis die Installation von Apps außerhalb des Stores, sofern sie nicht anderweitig erlaubt sind; die Wirkung ist besonders sorgfältig zu testen, weil Branchen-Apps betroffen sein können. `winget source list` zeigt, aus welchen Quellen Winget installieren darf.

**Typische Fehler.** Falsch: `AllowAllTrustedApps = 0` auszurollen, ohne die eigene MSIX-Verteilung zu testen. Branchen-Apps lassen sich dann nicht mehr installieren. Richtig: Pilot mit allen Verteilwegen. Zweiter Fehler: Winget zu sperren und zugleich die Installation von Hand per Doppelklick zuzulassen; die Einschränkung ist dann wirkungslos. Dritter Fehler: auf einem Standardbenutzer-Gerät keine Rechte-Trennung zu haben; wer Administrator ist, kann viele dieser Richtlinien umgehen (siehe Modul 08).

> **Praxisbeispiel**
>
> Beispielszenario: Ein Link in einer Phishing-Mail öffnet den App Installer mit einem scheinbar harmlosen Dokumentenbetrachter. Da das Protokoll per Richtlinie abgeschaltet ist, passiert nichts; der Link führt zu einer Fehlermeldung.

## 58 App Control for Business auditieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> Device Guard                  |
| Einstellung     | App Control Policies                                                                        |
| Empfehlung      | Audit zuerst, danach Enforcement                                                            |
| Ziel / Zweck    | Bereitet kontrolliertes Allowlisting vor                                                    |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

*Allowlisting* ist das konsequenteste Konzept der Anwendungssteuerung: Statt zu versuchen, schlechte Programme zu erkennen (wie ein Virenscanner), erlaubt man nur bekannte gute und blockiert den Rest. *App Control for Business* (früher *Windows Defender Application Control*, WDAC) ist die Windows-Funktion dafür. Sie arbeitet mit *Richtlinien*, die festlegen, welche Programme, Bibliotheken und Treiber ausgeführt werden dürfen, etwa nach Herausgeber (Signatur), Dateihash oder Pfad. Die zwei Betriebsarten nennt die Microsoft-Dokumentation: Im *Auditmodus* darf auch nicht vertrauenswürdiger Code laufen, und es werden nur Ereignisse aufgezeichnet; im *Erzwingungsmodus* wird nicht vertrauenswürdiger Code blockiert.

Das Vorgehen „erst Audit, dann Enforcement“ ist unverzichtbar, weil eine falsche Richtlinie ganze Arbeitsplätze unbrauchbar macht. Im Auditmodus erzeugt Windows im Protokoll „Anwendungs- und Dienstprotokolle \> Microsoft \> Windows \> CodeIntegrity \> Operational“ die Ereignis-ID **3076**, wenn eine Datei *blockiert worden wäre*, im Erzwingungsmodus die ID **3077** für tatsächlich blockierte Dateien. Zusätzlich liefert Ereignis 3089 die Signaturinformationen zur jeweiligen Datei. Aus den 3076-Ereignissen der Pilotphase baut man die Ausnahmen (Herausgeberregeln, Hash-Regeln) und verfeinert die Richtlinie, bis keine unerwarteten Ereignisse mehr auftreten.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft lässt sich die Auswertung zentralisieren: Mit dem Azure Monitor Workbook für App Control (aus der Doku zu OSConfig) und über Advanced Hunting im Defender-Portal werden die Ereignisse gesammelt; die Aktionstypen heißen dort `AppControlCodeIntegrityPolicyAudited` (3076) und `AppControlCodeIntegrityPolicyBlocked` (3077). Beachten Sie, dass die Verteilung per klassischer Gruppenrichtlinie nach meiner Kenntnis nur das ältere Einzelrichtlinien-Format unterstützt; für das neuere Mehrfachrichtlinien-Format sind `citool.exe`, Intune oder Konfigurationsmanager vorgesehen.

Das Beispiel erzeugt aus der von Windows mitgelieferten Beispielrichtlinie eine Auditrichtlinie, wandelt sie in das Binärformat um und lädt sie mit `citool`. Die Beispielrichtlinie `DefaultWindows_Audit.xml` liegt nach meiner Kenntnis im Ordner `C:\Windows\schemas\CodeIntegrity\ExamplePolicies`. Die Cmdlets `Set-RuleOption` und `ConvertFrom-CIPolicy` gehören zum Modul ConfigCI; die Option 3 steht für den Auditmodus. Die Schritte sind auf einem Testgerät auszuführen.

```ps
# Auf einem Testgeraet (Admin-PowerShell)
$src = "$env:windir\schemas\CodeIntegrity\ExamplePolicies\DefaultWindows_Audit.xml"
$xml = "$env:TEMP\AC-Audit.xml"
$bin = "$env:TEMP\AC-Audit.cip"
Copy-Item $src $xml

# Option 3 = Audit Mode (sicherstellen, dass er aktiv ist)
Set-RuleOption -FilePath $xml -Option 3
ConvertFrom-CIPolicy -XmlFilePath $xml -BinaryFilePath $bin

# Richtlinie laden (neues Mehrfachrichtlinien-Format)
citool.exe --update-policy $bin

# Nach einigen Tagen Betrieb: Auditereignisse auswerten
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-CodeIntegrity/Operational'; Id=3076} `
    -MaxEvents 500 -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Properties[1].Value } |
    Group-Object | Sort-Object Count -Descending | Select-Object -First 15 Count, Name
```

Der erste Block bereitet die Richtlinie vor; der Auditmodus bleibt aktiv, sodass nichts blockiert wird. `citool` lädt sie. Die Auswertung liest die 3076-Ereignisse und zählt die betroffenen Dateien; welche Eigenschaft den Dateipfad enthält (hier Index 1, nach meiner Kenntnis), ist an einem Beispielereignis zu prüfen. So erkennt man, welche Programme das Allowlisting betreffen würde.

**Typische Fehler.** Falsch: direkt im Erzwingungsmodus zu starten. Fachanwendungen, Treiber und Skripte werden blockiert, im schlimmsten Fall startet Windows nicht mehr richtig. Richtig: mehrere Wochen Audit, Auswertung, Anpassung. Zweiter Fehler: die Auditphase zu kurz zu wählen; monatliche und jährliche Abläufe (Abschlüsse, Updates) tauchen erst später auf. Dritter Fehler: Ausnahmen großzügig über Pfadregeln zu bilden; benutzerbeschreibbare Pfade erlauben dann Angreifern, Programme dort abzulegen. Besser sind Herausgeber- oder Hashregeln.

> **Praxisbeispiel**
>
> Beispielszenario: Eine Produktionsfirma testet App Control zwei Monate lang im Audit. Die Ereignisse zeigen mehrere vergessene Hilfsprogramme und zwei alte Treiber. Nach deren Bereinigung wird die Richtlinie zuerst in einer Pilotgruppe erzwungen.

## 59 Makros aus Internet blockieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Benutzerkonfiguration \> Administrative Vorlagen \> Microsoft Office \> Sicherheit          |
| Einstellung     | VBA-Makros aus Internet blockieren                                                          |
| Empfehlung      | Aktiviert                                                                                   |
| Ziel / Zweck    | Reduziert Phishing- und Makro-Malware                                                       |
| Zielbereich     | User                                                                                        |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Ein *Makro* ist ein kleines Programm (in der Sprache VBA) in einem Office-Dokument. Es automatisiert Aufgaben, kann aber auch Dateien herunterladen und ausführen. Deshalb sind Makros in Phishing-Mails ein klassischer Weg für Schadsoftware. Microsoft hat darauf mit einer Standardänderung reagiert: Laut der Dokumentation werden Makros in Dateien aus dem Internet in Office-Anwendungen standardmäßig blockiert. Den Hintergrund liefert das *Mark of the Web* (Abschnitt 51): Windows markiert Downloads und Mailanhänge, und Office wertet diese Markierung aus.

Trotz des Standards empfiehlt Microsoft, die Richtlinie „Block macros from running in Office files from the Internet“ explizit zu setzen und als Teil der Sicherheits-Baseline für Microsoft 365 Apps für Unternehmen zu führen: Wer sie konfiguriert, ist von künftigen Änderungen des Standards nicht betroffen. Es gibt eine Richtlinie je Anwendung (Access, Excel, PowerPoint, Project, Publisher, Visio, Word) unter Benutzerkonfiguration \> Administrative Vorlagen \> (Anwendung) \> Sicherheit \> Trust Center. Richtlinien stehen laut Microsoft nur für Microsoft 365 Apps for enterprise zur Verfügung, nicht für Apps for business. Die Alternative, wenn die Blockade nicht passt, ist die Richtlinie „VBA Macro Notification Settings“.

> **Ergänzung aus der Nachrecherche**
>
> Ausnahmen laut Microsoft (Auswahl): Dateien an einem *vertrauenswürdigen Speicherort* (Trusted Location) werden ohne Prüfung der Markierung geöffnet; Makros mit gültiger Signatur eines vertrauenswürdigen Herausgebers laufen; für Dateien auf OneDrive/SharePoint hilft „In Desktop-App öffnen“, weil dann keine Markierung gesetzt wird. Das Zurücksetzen der Markierung per `Unblock-File` oder Dateieigenschaften entfernt die Blockade für die einzelne Datei. Die Zonen-ID 3 (Internet) wird blockiert, die ID 2 (vertrauenswürdige Sites) nicht. Außerdem betrifft die Blockade Dateien auf Netzwerkfreigaben, die nicht in der Intranetzone liegen, zum Beispiel beim Zugriff per IP-Adresse.

Das Beispiel setzt die Richtlinie für Word, Excel und PowerPoint in einer Benutzer-GPO. Die Registrywerte (`blockcontentexecutionfrominternet` unter `HKCU\Software\Policies\Microsoft\Office\16.0\<App>\Security`) stammen aus meiner Kenntnis der Office-ADMX-Vorlagen und sind im Pilot gegen den Editor zu prüfen. Der Pfad `16.0` gilt für Microsoft 365 Apps und Office 2016 bis 2021.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "OFFICE-Makros-Internet-blocken"
foreach ($app in 'word','excel','powerpoint','access','visio','project','publisher') {
    Set-GPRegistryValue -Name $gpo.DisplayName `
        -Key "HKCU\Software\Policies\Microsoft\Office\16.0\$app\security" `
        -ValueName blockcontentexecutionfrominternet -Type DWord -Value 1
}

# Test: Zonenkennung einer heruntergeladenen Datei anzeigen
Get-Content -Path "$env:USERPROFILE\Downloads\bericht.xlsm" -Stream Zone.Identifier -ErrorAction SilentlyContinue
```

Die Schleife setzt in jeder der sieben Anwendungen den Wert 1. Weil die Einstellung in der Benutzerkonfiguration liegt, muss die GPO mit einer *Benutzer-OU* verknüpft sein (oder der Schleifenverarbeitung einer Computer-OU, siehe unten). Die Testabfrage zeigt die Zone der Datei `bericht.xlsm` (ein Beispielname); fehlt der Datenstrom, hat die Datei keine Markierung.

**Typische Fehler.** Falsch: die GPO mit einer Computer-OU zu verknüpfen und sich zu wundern, dass nichts ankommt. Benutzerkonfigurationen wirken nur bei Verknüpfung mit der OU der Benutzer (oder mit Loopback-Verarbeitung). Richtig: Verknüpfung prüfen oder „Benutzergruppenrichtlinie-Loopbackverarbeitung“ nutzen. Zweiter Fehler: Makros ganz zu verbieten, obwohl die Buchhaltung firmeninterne, signierte Makros braucht. Richtig: Signierung und vertrauenswürdige Herausgeber verwalten. Dritter Fehler: Netzwerkfreigaben per IP-Adresse anzusprechen; Office stuft sie dann als Internet ein und blockiert die Makros.

> **Praxisbeispiel**
>
> Beispielszenario: Eine Phishing-Mail enthält eine Excel-Rechnung mit Makro. Der Benutzer öffnet sie, sieht aber nur die rote Warnleiste „Sicherheitsrisiko“ ohne die Option, Inhalte zu aktivieren. Der Angriff endet dort; die Meldung geht an die IT.

## 60 Windows Script Host einschränken

| **Feld**        | **Steckbrief**                                                                                 |
|:----------------|:-----------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows Script Host |
| Einstellung     | Windows Script Host deaktivieren                                                               |
| Empfehlung      | Nach Betriebsbedarf                                                                            |
| Ziel / Zweck    | Reduziert Skriptmissbrauch                                                                     |
| Zielbereich     | Computer/User                                                                                  |
| Priorität       | 2                                                                                              |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.    |

Der *Windows Script Host* (WSH) ist die Laufzeit hinter den Programmen `wscript.exe` und `cscript.exe`. Er führt Skripte in den Sprachen VBScript und JScript aus (Dateiendungen `.vbs`, `.js`, `.wsf`). Diese Technik stammt aus den 1990er-Jahren und wird kaum noch für legitime Zwecke genutzt, aber viel von Schadsoftware: Eine Phishing-Mail liefert eine `.js`-Datei, ein Doppelklick startet sie, und sie lädt weitere Schadprogramme nach. Wer WSH nicht braucht, schaltet ihn ab.

Nach meiner Kenntnis (nicht abgerufen) ist der Standardweg ein Registrywert: `Enabled = 0` unter `HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings` (für alle Benutzer) beziehungsweise unter `HKCU\...` (für den Benutzer). Ob es in den Administrativen Vorlagen eine Einstellung mit dem im Lehrplan genannten Namen gibt, konnte ich nicht bestätigen; im Zweifel setzt man den Wert über die Einstellungen der Gruppenrichtlinie (Preferences). Der Lehrplan formuliert „nach Betriebsbedarf“: Zuerst muss man herausfinden, ob Anmeldeskripte oder Altanwendungen `.vbs`- oder `.js`-Dateien einsetzen. Anmeldeskripte in VBScript sind in älteren Umgebungen noch häufig.

> **Merke**
>
> WSH-Abschaltung, ASR-Regeln (Modul 02) und App Control (Abschnitt 58) ergänzen sich: WSH-Abschaltung nimmt den Skriptinterpreter weg, die ASR-Regel verhindert das Nachladen aus Skripten, App Control erlaubt nur genehmigte Programme. Keine der Maßnahmen ersetzt die anderen vollständig.

Das Beispiel schaltet WSH per Preferences ab und zeigt, wie man vorab im Bestand nach Skripten sucht. Die Suche liest nur. Die Verwendung von `Set-GPPrefRegistryValue` ist von Microsoft dokumentiert (Cmdlet des Moduls GroupPolicy); der Registrypfad ist aus meiner Kenntnis.

```ps
# Vorab: gibt es Skripte im Anmeldeskript-Ordner der Domaene? (auf dem DC / per UNC)
$netlogon = "\\$env:USERDNSDOMAIN\NETLOGON"
Get-ChildItem $netlogon -Recurse -Include *.vbs,*.js,*.wsf -ErrorAction SilentlyContinue |
    Select-Object FullName, LastWriteTime

# WSH abschalten (Computer-Einstellung als Preference)
Import-Module GroupPolicy
$gpo = New-GPO -Name "SEC-WSH-aus"
Set-GPPrefRegistryValue -Name $gpo.DisplayName -Context Computer -Action Update `
    -Key "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" `
    -ValueName Enabled -Type DWord -Value 0

# Am Client: Wirkung testen (sollte eine Fehlermeldung des Script Host liefern)
Set-Content "$env:TEMP\t.vbs" 'WScript.Echo "hallo"'
cscript.exe //nologo "$env:TEMP\t.vbs"
```

Die erste Suche listet VBScript- und JScript-Dateien im Anmeldeskriptordner der Domäne; findet man welche, ist die Abschaltung zuerst mit den Verantwortlichen abzustimmen. Der zweite Block setzt `Enabled = 0`, und der Test am Client führt eine Mini-Datei aus. Bei aktiver Abschaltung meldet der Script Host, dass er deaktiviert ist.

**Typische Fehler.** Falsch: WSH zu deaktivieren, ohne die Anmeldeskripte geprüft zu haben. Am nächsten Morgen funktionieren Laufwerkszuordnungen nicht mehr. Richtig: Skripte auf PowerShell oder Gruppenrichtlinien-Einstellungen migrieren (Laufwerkszuordnungen sind als Preference ohne Skript möglich). Zweiter Fehler: zu glauben, die Abschaltung stoppe alle Skripte; PowerShell, Batch und Office-Makros laufen weiter. Dritter Fehler: Dateizuordnungen von `.js` und `.vbs` nicht anzupassen; ein Doppelklick auf eine `.js`-Datei sollte stattdessen den Editor öffnen (diese Maßnahme ist in vielen Härtungsleitfäden üblich).

> **Praxisbeispiel**
>
> Beispielszenario: Im Posteingang landet ein ZIP mit einer Datei `Rechnung.js`. Ein Benutzer klickt doppelt darauf. Da WSH deaktiviert ist, erscheint eine Meldung statt der Ausführung. Das Antivirus-Protokoll zeigt den Versuch als verdächtigen Download.

## Übungsaufgaben zu Modul 06

**Aufgabe 1.** **(leicht)** Erklären Sie den Unterschied zwischen SmartScreen im Datei-Explorer und SmartScreen in Edge.

**Aufgabe 2.** **(leicht)** Was ist das Mark of the Web, wo wird es gespeichert, und auf welchen Dateisystemen funktioniert es?

**Aufgabe 3.** **(leicht)** Wie wirkt `PasswordManagerEnabled = 0` auf bereits gespeicherte Kennwörter?

**Aufgabe 4.** **(mittel)** Beschreiben Sie die Allowlist-Strategie für Edge-Erweiterungen und was mit bereits installierten Erweiterungen passiert.

**Aufgabe 5.** **(mittel)** Warum ist der Auditmodus bei App Control vor dem Erzwingen nötig, und welche Ereignis-IDs sind relevant?

**Aufgabe 6.** **(praktisch)** Schreiben Sie ein Skript, das eine GPO mit der Allowlist-Strategie für drei vorgegebene Erweiterungs-IDs erstellt und die Einträge fortlaufend nummeriert.

**Aufgabe 7.** **(praktisch)** Schreiben Sie ein Skript, das im Ordner `Downloads` des Benutzers alle Dateien mit der Zone-Identifier-Markierung auflistet und die Zonen-ID ausgibt.

**Aufgabe 8.** **(schwer)** Entwerfen Sie ein Konzept, das Phishing-Anhänge auf drei Ebenen abfängt (Browser/Download, Office, Skript/Ausführung), und benennen Sie für jede Ebene die Richtlinie und eine mögliche Ausnahme.

## Lösungen zu Modul 06

**Lösung 1.** Der Explorer prüft beim Start einer Datei (Reputation von Hash und Signatur anhand des Mark of the Web), Edge prüft schon beim Aufruf einer Seite und beim Download. Beide Schichten ergänzen sich.

**Lösung 2.** Eine Zusatzinformation im Alternativen Datenstrom `Zone.Identifier` mit der Zonen-ID (3 = Internet). Funktioniert nur auf NTFS, nicht auf FAT32.

**Lösung 3.** Gar nicht: Laut Microsoft können Benutzer keine neuen Kennwörter mehr speichern, bereits gespeicherte aber weiter verwenden.

**Lösung 4.** Blockliste mit `*` (alle Erweiterungen blockiert) und Allowlist mit den IDs genehmigter Erweiterungen. Bereits installierte, nicht erlaubte Erweiterungen werden deaktiviert (nicht deinstalliert); der Benutzer kann sie nicht wieder aktivieren. Ungepackte Erweiterungen sind blockiert.

**Lösung 5.** Weil eine falsche Richtlinie legitime Software blockiert. Im Audit werden Verstöße nur protokolliert: 3076 (hätte blockiert) bzw. 3077 (blockiert im Erzwingungsmodus), ergänzend 3089 für Signaturdetails.

```ps
# Loesung 6
Import-Module GroupPolicy
$gpo = New-GPO -Name "EDGE-Allowlist-Uebung"
$base = "HKLM\SOFTWARE\Policies\Microsoft\Edge"
Set-GPRegistryValue -Name $gpo.DisplayName -Key "$base\ExtensionInstallBlocklist" -ValueName 1 -Type String -Value "*"
$ids = @("aaaabbbbccccddddeeeeffffgggghhhh","bbbbccccddddeeeeffffgggghhhhiiii","ccccddddeeeeffffgggghhhhiiiijjjj")
for ($i = 0; $i -lt $ids.Count; $i++) {
    Set-GPRegistryValue -Name $gpo.DisplayName -Key "$base\ExtensionInstallAllowlist" -ValueName ($i+1) -Type String -Value $ids[$i]
}
```

```ps
# Loesung 7
Get-ChildItem "$env:USERPROFILE\Downloads" -File | ForEach-Object {
    $z = Get-Content $_.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue
    if ($z) {
        [pscustomobject]@{ Datei = $_.Name; ZoneId = ($z | Where-Object { $_ -like 'ZoneId=*' }) -replace 'ZoneId=' }
    }
}
```

**Lösung 8.** Beispiel: (1) Browser/Download: Edge-SmartScreen mit gesperrter Umgehung, Explorer-SmartScreen auf „Block“; Ausnahme: signierte interne Tools, Freigabe durch die IT. (2) Office: Makros aus dem Internet blockieren, vertrauenswürdige Speicherorte und signierte Makros für Fachabteilungen. (3) Ausführung: WSH abschalten und Dateizuordnung ändern, ASR-Regeln aktivieren (Modul 02), App Control im Audit pilotieren; Ausnahmen: Anmeldeskripte, die zuvor migriert werden. Dazu eine Meldestelle für verdächtige Mails.
