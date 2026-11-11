# Modul 08 - Konten, LAPS und Rechte

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Gruppenrichtlinien für Windows 11 – 100 Richtlinien im Detail“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Steckbriefe als Tabellen, Übungsaufgaben und Lösungen als fortlaufend nummerierte Absätze). **Nummerierung:** Die Überschriften der Richtlinien tragen hier die laufende Nummer 1 bis 100 aus der Modultabelle; die Verweise im Text („Abschnitt 43“) meinen diese Nummer. (Im LaTeX-Satz zählen die Überschriften je Modul neu, etwa 5.3.) **Die Beispiele (PowerShell, INF) wurden für dieses Repository nicht ausgeführt**; sie verändern Gruppenrichtlinien, Registry und Sicherheitseinstellungen und gehören nur in eine Testumgebung (Pilot-OU, Testdomäne). Übersicht zum Modul: [README](README.md).

**Dauer:** 10 Unterrichtsstunden (Annahme: 1 Stunde je Richtlinie)  
**Priorität:** 1 und 2 (sieben Richtlinien mit Priorität 1, drei mit Priorität 2)

| Nr. | Lerneinheit (Richtlinie)                  | Prio | Stunden |
|----:|:------------------------------------------|:----:|:-------:|
|  71 | Windows LAPS aktivieren                   |  1   |    1    |
|  72 | LAPS Passwortalter setzen                 |  1   |    1    |
|  73 | Lokale Administratorgruppe begrenzen      |  1   |    1    |
|  74 | Deny log on locally für Servicekonten     |  2   |    1    |
|  75 | Deny RDP für Standardbenutzer             |  1   |    1    |
|  76 | Benutzerrecht Debug Programs einschränken |  1   |    1    |
|  77 | Impersonate Client einschränken           |  1   |    1    |
|  78 | Lokale Anmeldung für Gäste verweigern     |  1   |    1    |
|  79 | Microsoft-Konten blockieren               |  2   |    1    |
|  80 | Cached Logons begrenzen                   |  2   |    1    |
|     | **Summe**                                 |      | **10**  |

**Worum es in diesem Modul geht.** Angriffe im Unternehmensnetz folgen oft demselben Muster: Ein Angreifer übernimmt einen Rechner, findet dort ein lokales Administratorkennwort, das auf hundert anderen Rechnern identisch ist, und bewegt sich seitlich weiter (*lateral movement*). Dieses Modul bricht das Muster an mehreren Stellen. Es sorgt für einmalige, regelmäßig wechselnde lokale Administratorkennwörter (Abschnitte 71 und 72), begrenzt, wer überhaupt lokaler Administrator ist (73), und schränkt die *Benutzerrechte* (englisch *user rights*) ein, mit denen Konten Dinge tun dürfen: sich anmelden, Prozesse debuggen, andere Benutzer imitieren (74 bis 78). Zum Schluss kommen zwei Einstellungen zur Kontenhygiene (79 und 80). Alle Einstellungen außer LAPS stehen unter Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen.

> **Merke**
>
> Zwei Besonderheiten gelten für alle Benutzerrechte in diesem Modul. Erstens *ersetzt* eine Richtlinie die vorhandene Zuweisung, sie ergänzt sie nicht: Wer ein Recht in einer GPO konfiguriert, überschreibt die Standardzuweisung des Systems. Zweitens werden Zuweisungen aus mehreren GPOs nicht zusammengeführt; es gewinnt die GPO mit der höchsten Priorität. Wer dasselbe Recht in zwei GPOs pflegt, verliert Einträge. Deshalb gehören Abschnitt 74 und 78 (beide „Lokal anmelden verweigern“) in *eine* GPO.

## 71 Windows LAPS aktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> LAPS                          |
| Einstellung     | Lokales Administratorkennwort verwalten                                                     |
| Empfehlung      | Aktiviert                                                                                   |
| Ziel / Zweck    | Sichert lokale Admin-Konten mit Rotation                                                    |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Jeder Windows-Rechner hat ein eingebautes lokales Administratorkonto. Wenn es mit demselben Kennwort auf allen Rechnern eingerichtet wurde (etwa durch ein gemeinsames Installationsimage), öffnet ein einziges erbeutetes Kennwort alle Türen. Die Lösung heißt *Windows LAPS* (Local Administrator Password Solution): Jeder Rechner erzeugt für sein lokales Administratorkonto selbst ein zufälliges Kennwort, ändert es automatisch nach einer festgelegten Zeit und speichert es zentral im Verzeichnis, wo nur berechtigte Administratoren es abrufen können. Laut Microsoft erzeugt das Gerät beim Ablauf des Kennworts ein neues, zufälliges Kennwort, das der aktuellen Richtlinie in Länge und Komplexität entspricht, speichert es nach erfolgreicher Prüfung im Verzeichnis und berechnet die neue Ablaufzeit.

Welche Gruppenrichtlinie braucht man mindestens? Laut der Microsoft-Dokumentation genügt als Minimum die Einstellung `BackupDirectory`: Wert 2 sichert die Kennwörter in das lokale Active Directory, Wert 1 in Microsoft Entra ID, Wert 0 (Standard) schaltet LAPS aus, und dann werden alle anderen Einstellungen ignoriert. Wird `AdministratorAccountName` nicht gesetzt, verwaltet LAPS das eingebaute Administratorkonto, das es zuverlässig über seine bekannte Relative-ID erkennt, und nicht über den Namen, der je nach Sprache variiert. Wer ein eigenes Konto verwalten will, muss dieses selbst anlegen; LAPS erzeugt keine Konten (die Funktion `AutomaticAccountManagement` kann das ab neueren Versionen übernehmen).

> **Ergänzung aus der Nachrecherche**
>
> Vorbereitung laut Microsoft für Active Directory: Die ADMX/ADML-Vorlagen von Windows LAPS gehören in den zentralen Richtlinienspeicher (Central Store), falls dieser genutzt wird, und die Berechtigungen für das Lesen und das Zurücksetzen von Kennwörtern sind zu planen. Für die Kennwortverschlüsselung muss die Domänenfunktionsebene mindestens 2016 sein; darunter werden Kennwörter nur im Klartext gespeichert, geschützt durch AD-Berechtigungen. Domänencontroller (DSRM-Konto) lassen sich nur bei entsprechender Ebene und Serverversion verwalten. Wird mindestens eine LAPS-Einstellung per CSP (Intune) gesetzt, ignoriert Windows die per Gruppenrichtlinie gesetzten LAPS-Einstellungen. Bei reinen Entra-Geräten ist Intune der bevorzugte Weg; die Schemaerweiterung in AD entfällt, wenn man nur in Entra sichert.

Das Beispiel führt die AD-Vorbereitung und die Richtlinie vor. Die Cmdlets `Update-LapsADSchema`, `Set-LapsADComputerSelfPermission`, `Get-LapsADPassword` und `Reset-LapsPassword` gehören zum PowerShell-Modul `LAPS`, das mit aktuellen Windows-Versionen kommt; die Namen und Zwecke stammen aus meiner Kenntnis der Windows-LAPS-Dokumentation, die Abfolge ist im Pilot zu prüfen. Die Registrypfade der LAPS-Gruppenrichtlinie (`Software\Policies\Microsoft\Windows\LAPS`) sind ebenfalls aus meiner Kenntnis. Die Schemaerweiterung ist ein einmaliger, nicht umkehrbarer Eingriff in Active Directory und gehört mit dem AD-Team abgestimmt.

```ps
# 1) Einmalig: Schema erweitern (als Schema-Admin, nicht umkehrbar!)
Update-LapsADSchema

# 2) Computer duerfen ihr eigenes Kennwort in der Ziel-OU speichern
Set-LapsADComputerSelfPermission -Identity "OU=Clients,DC=contoso,DC=local"

# 3) Richtlinie: Sicherung in Active Directory (2), Standardkonto
Import-Module GroupPolicy
$gpo = New-GPO -Name "LAPS-Clients"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\LAPS"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName BackupDirectory -Type DWord -Value 2

# 4) Am Client nach gpupdate: Verarbeitung pruefen und Rotation anstossen
Get-WinEvent -LogName 'Microsoft-Windows-LAPS/Operational' -MaxEvents 5 | Select-Object TimeCreated, Id, Message
Reset-LapsPassword

# 5) Als berechtigter Admin: Kennwort abrufen
Get-LapsADPassword -Identity "PC001" -AsPlainText
```

Schritt 1 und 2 bereiten das Verzeichnis vor: Das Schema bekommt die LAPS-Attribute, und die Computerkonten der Ziel-OU erhalten das Recht, ihr eigenes Kennwort zu schreiben. Schritt 3 legt die Richtlinie an, mit dem Minimum `BackupDirectory = 2`. Auf dem Client zeigt das LAPS-Ereignisprotokoll, ob die Verarbeitung gelungen ist; `Reset-LapsPassword` (laut Microsoft zum sofortigen Rotieren vorgesehen) erzwingt eine neue Kennwortvergabe. Mit `Get-LapsADPassword` liest ein berechtigter Administrator das Kennwort; die Nutzung sollte in einem Verfahren stehen (Begründung, Protokollierung).

**Typische Fehler.** Falsch: die Richtlinie zu aktivieren, ohne die Berechtigungen der Computer in der OU gesetzt zu haben. Die Sicherung scheitert, und in der Folge ist das lokale Administratorkennwort unbekannt oder noch das alte. Richtig: erst Berechtigung, dann Richtlinie, dann Kontrolle im Ereignisprotokoll. Zweiter Fehler: das alte Legacy-LAPS (das MSI-Produkt) und Windows LAPS gleichzeitig auf einem Gerät zu betreiben; die Dokumentation behandelt das als eigenen Migrationsfall. Dritter Fehler: den Abruf des Kennworts allen Helpdesk-Mitarbeitern zu erlauben. Richtig: eine eigene Gruppe für die Leseberechtigung je OU, mit Protokollierung.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Techniker muss an einem Rechner im Außenstandort lokal arbeiten, der keinen Domänencontroller erreicht. Er ruft das aktuelle Kennwort im Büro ab, meldet sich an und löst nach der Arbeit mit `Reset-LapsPassword` eine Rotation aus (oder nutzt die automatische Rotation nach Anmeldung). Das alte Kennwort ist damit wertlos.

## 72 LAPS Passwortalter setzen

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> LAPS                          |
| Einstellung     | Kennwortalter                                                                               |
| Empfehlung      | 30 Tage oder Vorgabe                                                                        |
| Ziel / Zweck    | Reduziert Risiko dauerhafter lokaler Admin-Kennwörter                                       |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Das *Kennwortalter* legt fest, wie lange ein von LAPS erzeugtes Kennwort gültig bleibt, bevor der Rechner ein neues vergibt. Je kürzer, desto kleiner das Zeitfenster, in dem ein erbeutetes Kennwort nützt. Laut Microsoft liegt der erlaubte Bereich bei einem bis 365 Tagen, bei Sicherung in Entra ID mindestens bei sieben Tagen, und der Standardwert ist 30 Tage. Der Lehrplan empfiehlt „30 Tage oder Vorgabe“; das entspricht dem Standard. Strengere Umgebungen wählen 7 bis 14 Tage, gelegentlich auch 1 Tag für Hochsicherheitsbereiche.

Dazu gehören zwei Einstellungen, die man gemeinsam entscheidet. Die *Länge* liegt laut Microsoft zwischen 8 und 64 Zeichen, Standard 14. Die *Komplexität* (`PasswordComplexity`) hat den Standardwert 4; neuere Versionen kennen zusätzlich Passphrasen (Wert 6 für lange Wörter bei Windows 11 24H2). Wichtig ist eine Warnung der Dokumentation: Konfiguriert man einen Wert, den ein älteres Betriebssystem nicht kennt (zum Beispiel Komplexität 6), nutzt dieses stattdessen den Standardwert 4. Man legt dann besser zwei getrennte Richtlinien für ältere und neuere Systeme an. Eine zweite Feinheit: Änderungen am Kennwortalter wirken nicht auf das aktuelle Kennwort; die Ablaufzeit des vorhandenen Kennworts bleibt, und es wird keine Rotation ausgelöst. Neue Werte gelten erst ab dem nächsten Wechsel.

> **Ergänzung aus der Nachrecherche**
>
> Zwei weitere Einstellungen der Gruppe sind für die Sicherheit relevant: `PostAuthenticationResetDelay` (Standard 24 Stunden) und `PostAuthenticationActions` (Standard 3 = Kennwort zurücksetzen und abmelden). Sie sorgen dafür, dass ein abgerufenes und benutztes Kennwort nach einer festgelegten Zeit ungültig wird. Dies ist laut Microsoft-Tabelle auch im Entra-Modus anwendbar. Die Voreinstellung (24 Stunden, Zurücksetzen und Abmelden) ist für die meisten Umgebungen sinnvoll.

Das Beispiel ergänzt die GPO aus Abschnitt 71 und prüft am Client, wann das aktuelle Kennwort abläuft. Die Registrynamen stehen im Schlüssel `Software\Policies\Microsoft\Windows\LAPS` (nach meiner Kenntnis, im Pilot zu prüfen); die Einstellungsnamen und Wertebereiche stammen aus der Microsoft-Dokumentation.

```ps
Import-Module GroupPolicy
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\LAPS"
Set-GPRegistryValue -Name "LAPS-Clients" -Key $key -ValueName PasswordAgeDays   -Type DWord -Value 14
Set-GPRegistryValue -Name "LAPS-Clients" -Key $key -ValueName PasswordLength     -Type DWord -Value 20
Set-GPRegistryValue -Name "LAPS-Clients" -Key $key -ValueName PasswordComplexity -Type DWord -Value 4
Set-GPRegistryValue -Name "LAPS-Clients" -Key $key -ValueName PostAuthenticationResetDelay -Type DWord -Value 8
Set-GPRegistryValue -Name "LAPS-Clients" -Key $key -ValueName PostAuthenticationActions    -Type DWord -Value 3

# Wann laeuft das Kennwort eines Rechners ab?
Get-LapsADPassword -Identity "PC001" | Select-Object ComputerName, PasswordUpdateTime, ExpirationTimestamp
```

Die ersten Zeilen setzen Alter (14 Tage), Länge (20), Komplexität (4) sowie Nachbearbeitung (nach 8 Stunden zurücksetzen und abmelden). Die Abfrage mit `Get-LapsADPassword` ohne `-AsPlainText` zeigt nur Zeitstempel, kein Kennwort, und eignet sich daher für Berichte.

**Typische Fehler.** Falsch: Kennwortalter auf 1 Tag zu setzen, ohne Replikation und Domänencontroller-Last zu beachten; jede Rotation ist ein AD-Schreibvorgang pro Rechner. Richtig: ein Wert, den das Verzeichnis ohne Mühe trägt, und gestaffelte Einführung. Zweiter Fehler: nach Änderung des Alters zu erwarten, dass sofort alle Kennwörter wechseln. Richtig: wenn nötig gezielt `Reset-LapsPassword` auf den Geräten oder die Ablaufzeit im Verzeichnis setzen. Dritter Fehler: Passphrasen auf älteren Clients zu konfigurieren (siehe oben).

> **Praxisbeispiel**
>
> Beispielszenario: Nach einem Sicherheitsvorfall verlangt die Geschäftsführung, dass alle lokalen Administratorkennwörter sofort gewechselt werden. Dank LAPS genügt ein Skript, das über die Ablaufzeit im Verzeichnis oder eine Fernausführung die Rotation auslöst. Ohne LAPS wäre das ein mehrwöchiges Projekt.

## 73 Lokale Administratorgruppe begrenzen

| **Feld**        | **Steckbrief**                                                                                       |
|:----------------|:-----------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Eingeschränkte Gruppen |
| Einstellung     | Administrators                                                                                       |
| Empfehlung      | Nur autorisierte Gruppen                                                                             |
| Ziel / Zweck    | Verhindert Rechteausweitung                                                                          |
| Zielbereich     | Computer                                                                                             |
| Priorität       | 1                                                                                                    |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.          |

Die lokale Gruppe *Administratoren* entscheidet, wer auf einem Rechner alles darf. Im Lauf der Jahre sammeln sich dort Mitglieder an: der Benutzer, dem man „mal schnell“ Rechte gab, Installationskonten, ehemalige Mitarbeiter. Mit der Funktion *Eingeschränkte Gruppen* (englisch *Restricted Groups*) legt die Gruppenrichtlinie die Mitgliedschaft verbindlich fest. Bei jeder Richtlinienverarbeitung wird die lokale Gruppe auf die Liste der Richtlinie gesetzt, und alles, was dort nicht steht, wird entfernt.

Die Funktion kennt zwei Felder. „Mitglieder dieser Gruppe“ (*Members*) legt die vollständige Mitgliederliste fest; die Zuweisung ist *autoritativ*, alles andere fliegt raus. „Diese Gruppe ist Mitglied von“ (*Member of*) fügt die Gruppe zu anderen Gruppen hinzu, ohne vorhandene Mitglieder zu entfernen. Für eine Härtung nutzt man das erste Feld. Als Mitglieder sollten mindestens eingetragen werden: das lokale Administratorkonto (damit LAPS und Notfallzugang funktionieren), die Domänengruppe der Domänenadministratoren und eine Gruppe für Arbeitsplatzadministratoren (etwa `GG-Workstation-Admins`), die der Helpdesk nutzt. Welche Gruppen das sind, entscheidet das Berechtigungskonzept (Tier-Modell), nicht diese Richtlinie.

> **Ergänzung aus der Nachrecherche**
>
> Neben den Eingeschränkten Gruppen gibt es in den Einstellungen (Preferences) die Funktion „Lokale Benutzer und Gruppen“. Sie kann Mitglieder gezielt hinzufügen oder entfernen und lässt sich auf Zielebene (Item-Level Targeting) feinsteuern; sie ersetzt die Mitgliedschaft nur, wenn man ausdrücklich „Alle Mitglieder löschen“ wählt. Die Microsoft-Dokumentation zu LAPS empfiehlt für das Erstellen eines eigenen Verwaltungskontos den RestrictedGroups-CSP, was auf denselben Mechanismus verweist.

Das Beispiel erzeugt die Sicherheitsvorlage für die Gruppe. Das Format der INF-Datei (Abschnitt `[Group Membership]`, Schlüssel `*S-1-5-32-544__Members`) stammt aus meiner Kenntnis des Sicherheitsvorlagenformats; `S-1-5-32-544` ist die bekannte SID der Gruppe Administratoren und `-500` die Relative-ID des eingebauten Administratorkontos. Die Domänen-SID wird abgefragt. Das Anwenden mit `secedit /configure` auf einem Testrechner verändert die lokale Gruppe sofort; es gehört nicht in die Produktion.

```ps
Import-Module ActiveDirectory
$domSid  = (Get-ADDomain).DomainSID.Value
$wsAdmin = (Get-ADGroup "GG-Workstation-Admins").SID.Value

$inf = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Group Membership]
*S-1-5-32-544__Memberof =
*S-1-5-32-544__Members = *$domSid-500,*$domSid-512,*$wsAdmin
"@
# Hinweis: -500 = lokaler Administrator? Nein: ohne Rechnername mit Domaenen-SID waere es der
# Domaenen-Administrator. Das lokale Konto traegt man als Name "Administrator" ein.
Set-Content -Path "$env:TEMP\admins.inf" -Value $inf -Encoding Unicode

# NUR auf einem Testrechner, als Admin: Vorlage anwenden
secedit /configure /db "$env:TEMP\admins.sdb" /cfg "$env:TEMP\admins.inf" /areas GROUP_MGMT

# Ergebnis pruefen
Get-LocalGroupMember -Group "Administrators" | Select-Object Name, PrincipalSource
```

Die Vorlage legt fest, wer Mitglied der Administratorengruppe sein soll: die Domänen-Administrator-Konten (RID 500 der Domäne) und Domänen-Admins (RID 512) sowie die Arbeitsplatz-Admin-Gruppe. Der Kommentar im Code weist auf eine häufige Verwechslung hin: Die SID `...-500` mit Domänen-SID ist das Konto „Administrator“ *der Domäne*, nicht das lokale. Das lokale Konto schreibt man in der GPO-Oberfläche einfach als `Administrator` ein. Für die Produktion wird die Datei nicht manuell angewendet, sondern über den Editor der Gruppenrichtlinie (Eingeschränkte Gruppen) bereitgestellt.

**Typische Fehler.** Falsch: die Gruppe „Administratoren“ festzulegen und dabei das lokale Administratorkonto oder die Domänen-Admins zu vergessen; der Rechner ist dann für die Verwaltung unzugänglich. Richtig: im Pilot mit einem Testrechner prüfen und eine Notfallzugangs-Variante haben (LAPS-Kennwort). Zweiter Fehler: Software-Verteilungskonten (Konfigurationsmanager, Antivirus-Verwaltung) nicht einzutragen, die auf den Clients lokale Adminrechte brauchen; deren Dienste fallen aus. Dritter Fehler: die Richtlinie auf Server oder Domänencontroller zu verknüpfen; Domänencontroller haben keine lokale Administratorengruppe.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Audit findet auf 40 Prozent der Clients Benutzer in der lokalen Administratorengruppe. Nach Einführung der Eingeschränkten Gruppe sind nur noch die Arbeitsplatz-Admins und die Domänen-Admins eingetragen; die Ausnahmen für Entwickler laufen über eine zusätzliche, dokumentierte Gruppe.

## 74 Deny log on locally für Servicekonten

| **Feld**        | **Steckbrief**                                                                                                                   |
|:----------------|:---------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Zuweisen von Benutzerrechten |
| Einstellung     | Lokal anmelden verweigern                                                                                                        |
| Empfehlung      | Servicekonten/technische Konten                                                                                                  |
| Ziel / Zweck    | Reduziert Missbrauch technischer Konten                                                                                          |
| Zielbereich     | Computer                                                                                                                         |
| Priorität       | 2                                                                                                                                |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                      |

Ein *Servicekonto* ist ein Konto, unter dem ein Dienst oder eine Aufgabe läuft: Datensicherung, Monitoring, Datenbankzugriff. Niemand muss sich mit diesem Konto am Bildschirm anmelden. Trotzdem haben solche Konten oft weitreichende Rechte und Kennwörter, die nie wechseln, und sie sind daher beliebte Ziele. Wenn ein Angreifer ein Servicekonto-Kennwort erbeutet, will man ihm wenigstens verbieten, sich damit interaktiv an einem Rechner anzumelden. Das Benutzerrecht dafür heißt „Lokal anmelden verweigern“ (*Deny log on locally*, technisch `SeDenyInteractiveLogonRight`).

Das Prinzip stammt aus den Microsoft-Empfehlungen zum Minimalprivilegien-Modell für Active Directory: Dort wird beschrieben, dass man Administratorkonten in einer Reihe von Verweigern-Rechten einträgt (Netzwerkzugriff, Anmeldung als Batchauftrag, als Dienst, über Remotedesktop), damit sie nicht auf anderen Rechnern verwendet werden können. Für Servicekonten kehrt sich das um: Sie *brauchen* gerade „Als Dienst anmelden“ oder „Als Batchauftrag anmelden“, dürfen aber *nicht* interaktiv, also lokal oder per Remotedesktop. Wichtig ist die Vorrangregel: Ein Verweigern-Recht schlägt jede Erlaubnis. Wer eine Gruppe mit echten Benutzern in das Verweigern-Recht aufnimmt, sperrt diese Benutzer aus.

> **Merke**
>
> Servicekonten sollten wenn möglich als *verwaltete Dienstkonten* (gMSA, group Managed Service Account) laufen: Das Kennwort wird automatisch verwaltet und wechselt ohne Zutun. Ein gMSA kann sich nicht interaktiv anmelden; die Verweigerung ist dann eine zusätzliche Absicherung, keine Notwendigkeit. Für klassische Konten ist sie die einzige technische Bremse.

Das Beispiel baut die Zuweisung als Sicherheitsvorlage und zeigt, wie man einen Test auf dem Client durchführt. Der Abschnitt `[Privilege Rights]` mit `SeDenyInteractiveLogonRight` ist das Standardformat; die Gruppe `GG-Servicekonten` ist ein Platzhalter und muss alle Servicekonten enthalten. Wegen der Hinweise im Merkkasten wird die Zeile später um die Gäste (Abschnitt 78) ergänzt. Die Datei dient hier als Muster; die Produktion nutzt die GPO-Oberfläche.

```ps
Import-Module ActiveDirectory
$svcSid = (Get-ADGroup "GG-Servicekonten").SID.Value

$inf = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeDenyInteractiveLogonRight = *$svcSid
"@
Set-Content -Path "$env:TEMP\deny-svc.inf" -Value $inf -Encoding Unicode

# Gegenprobe: Gruppe sauber? Keine echten Benutzer/Admins darin?
Get-ADGroupMember "GG-Servicekonten" -Recursive | Select-Object SamAccountName, objectClass

# Am Client: wer hat das Recht aktuell? (Export der lokalen Sicherheitsrichtlinie)
secedit /export /cfg "$env:TEMP\aktuell.inf" /areas USER_RIGHTS | Out-Null
Select-String -Path "$env:TEMP\aktuell.inf" -Pattern 'SeDenyInteractiveLogonRight'
```

Die Vorlage trägt die Gruppe der Servicekonten in das Verweigern-Recht ein. Die Gegenprobe listet die Mitglieder der Gruppe (rekursiv) und deckt versehentlich eingetragene Benutzer auf. Der Export am Client macht sichtbar, wie das Recht lokal tatsächlich gesetzt ist, und zeigt SIDs, die man bei Bedarf auflöst.

**Typische Fehler.** Falsch: ein Servicekonto zu sperren, das in Wirklichkeit auch ein Mensch zum Testen benutzt. Der Fehler zeigt sich erst bei der nächsten Störung. Richtig: für Menschen eigene Admin-Konten, für Dienste eigene Konten, strikt getrennt. Zweiter Fehler: das Recht „Anmelden als Dienst“ (`SeServiceLogonRight`) mit zu verweigern; dann starten die Dienste nicht mehr. Dritter Fehler: die Verweigerung nur für die Anmeldung am Bildschirm zu setzen und die Remotedesktop-Anmeldung zu übersehen (Abschnitt 75).

> **Praxisbeispiel**
>
> Beispielszenario: Ein Datensicherungskonto hat Leserechte auf alle Server. Sein Kennwort steht in einer alten Dokumentation. Ein Angreifer findet es, kann sich aber an keinem Rechner mit diesem Konto interaktiv anmelden, weil das Recht verweigert ist, und muss andere Wege suchen.

## 75 Deny RDP für Standardbenutzer

| **Feld**        | **Steckbrief**                                                                                                                   |
|:----------------|:---------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Zuweisen von Benutzerrechten |
| Einstellung     | Anmelden über Remotedesktopdienste verweigern                                                                                    |
| Empfehlung      | Nicht berechtigte Gruppen                                                                                                        |
| Ziel / Zweck    | Schützt Remotezugriff                                                                                                            |
| Zielbereich     | Computer                                                                                                                         |
| Priorität       | 1                                                                                                                                |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                      |

Der Zugriff per Remotedesktop (RDP) wird durch zwei gegensätzliche Benutzerrechte geregelt: „Anmelden über Remotedesktopdienste zulassen“ (*Allow log on through Remote Desktop Services*, `SeRemoteInteractiveLogonRight`) und „Anmelden über Remotedesktopdienste verweigern“ (*Deny ...*, `SeDenyRemoteInteractiveLogonRight`). Die Microsoft-Dokumentation zur Fehlersuche beschreibt den Normalfall: Wer sich per RDP verbinden will, muss in einer Gruppe sein, die das Zulassen-Recht hat; gesetzt wird es im Gruppenrichtlinien-Editor unter „Benutzerrechte-Zuweisung“. Dazu der wichtige Hinweis: Gruppenrichtlinien überschreiben die lokale Sicherheitsrichtlinie.

Der Lehrplan verlangt „Deny RDP für nicht berechtigte Gruppen“. Dabei gilt es, die Reihenfolge zu verstehen. Ein Verweigern-Recht hat immer Vorrang vor einem Zulassen-Recht. Deshalb sollte man die Hauptarbeit mit dem Zulassen-Recht erledigen: Nur die Gruppen, die RDP brauchen (zum Beispiel Arbeitsplatzadministratoren), werden aufgeführt; alle anderen sind automatisch ausgeschlossen, weil sie in der Zulassen-Liste fehlen. Das Verweigern-Recht ergänzt dies für Ausnahmen, die sicher ausgeschlossen sein müssen. Typische Kandidaten laut Microsoft-Baseline sind die Gruppe „Gäste“ und „Lokales Konto“ (*Local account*, die SID `S-1-5-113`), damit sich lokale Konten nicht über das Netz per RDP anmelden können, sobald der Rechner Mitglied einer Domäne ist. Für die Baseline-Empfehlung steht als Servertyp ausdrücklich der Arbeitsgruppen-Mitgliedsserver; auf Domänenmitgliedern wird sie ebenso empfohlen, hängt aber vom Konzept ab, und bei eigenständigen Geräten kann sie nach Warnung der Dokumentation die Fernverwaltung unmöglich machen.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft empfiehlt das Minimalprivilegien-Modell zusätzlich, das *lokale* Administratorkonto in vier Verweigern-Rechten einzutragen (Netzwerkzugriff, Batch, Dienst, Remotedesktop), damit das Konto nicht auf anderen Rechnern verwendet werden kann, selbst wenn es versehentlich aktiviert wurde. Dabei ist zu unterscheiden, ob das lokale oder das Domänenkonto gemeint ist: Man schreibt `Administrator` für das lokale und `DOMÄNE\Administrator` für das Domänenkonto. Die lokale Anmeldung des lokalen Administrators lässt sich laut Microsoft nicht vollständig sperren und sollte es nicht, weil das Konto für Notfälle gedacht ist.

Das Beispiel zeigt die Vorlage für beide Rechte und prüft mit dem Export, was am Client wirklich gilt. `S-1-5-32-546` ist die bekannte SID der Gruppe Gäste, `S-1-5-113` die des Pseudo-Kontos „Lokales Konto“; beides stammt aus meiner Kenntnis der bekannten SIDs. Die Beispielgruppe `GG-Workstation-Admins` ist ein Platzhalter.

```ps
Import-Module ActiveDirectory
$wsAdmin = (Get-ADGroup "GG-Workstation-Admins").SID.Value

$inf = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
; Zulassen: nur Arbeitsplatzadmins und lokale Administratoren
SeRemoteInteractiveLogonRight = *S-1-5-32-544,*$wsAdmin
; Verweigern: Gaeste und lokale Konten
SeDenyRemoteInteractiveLogonRight = *S-1-5-32-546,*S-1-5-113
"@
Set-Content -Path "$env:TEMP\rdp.inf" -Value $inf -Encoding Unicode

# Am Client nach gpupdate: wirksame Rechte pruefen
gpupdate /force /target:computer
secedit /export /cfg "$env:TEMP\aktuell.inf" /areas USER_RIGHTS | Out-Null
Select-String -Path "$env:TEMP\aktuell.inf" -Pattern 'RemoteInteractiveLogonRight'
```

Die erste Zeile unter `[Privilege Rights]` bestimmt, wer sich per RDP anmelden darf: die lokale Administratorengruppe und die Arbeitsplatzadmins. Die zweite verweigert Gästen und lokalen Konten den Zugang. Wie Microsoft empfiehlt, wird die Gruppenrichtlinie danach mit `gpupdate /force /target:computer` aktualisiert; der Export mit `secedit /export` zeigt das Ergebnis.

**Typische Fehler.** Falsch: die Gruppe „Domänen-Benutzer“ in das Verweigern-Recht zu setzen. Dann sind auch Administratoren, die ebenfalls Domänen-Benutzer sind, ausgesperrt, denn Verweigern schlägt Zulassen. Richtig: Zulassen-Liste pflegen und das Verweigern-Recht nur für klar abgegrenzte Gruppen nutzen. Zweiter Fehler: Zulassen-Recht zu ändern und die Gruppe „Remotedesktopbenutzer“ zu vergessen, die auf manchen Systemen als Standard dient. Dritter Fehler: die Zulassen-Liste leer zu lassen; dann dürfen nur Administratoren, was oft gewollt ist, aber bewusst entschieden sein sollte.

> **Praxisbeispiel**
>
> Beispielszenario: Eine Mitarbeiterin versucht, sich mit ihrem Domänenkonto per RDP auf dem Rechner einer Kollegin anzumelden. Sie steht nicht in der Zulassen-Liste, die Verbindung scheitert mit der Meldung „Zum Anmelden über Remotedesktop ... erforderlich“. Genau das ist gewollt.

## 76 Benutzerrecht Debug Programs einschränken

| **Feld**        | **Steckbrief**                                                                                                                   |
|:----------------|:---------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Zuweisen von Benutzerrechten |
| Einstellung     | Debuggen von Programmen                                                                                                          |
| Empfehlung      | Nur notwendige Admins                                                                                                            |
| Ziel / Zweck    | Verhindert Credential Dumping                                                                                                    |
| Zielbereich     | Computer                                                                                                                         |
| Priorität       | 1                                                                                                                                |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                      |

Das Recht „Debuggen von Programmen“ (*Debug programs*, `SeDebugPrivilege`) erlaubt einem Konto, jeden Prozess des Systems zu untersuchen und zu verändern, auch Prozesse des Betriebssystems und anderer Benutzer. Entwickler brauchen das, um Programme zu debuggen. Angreifer brauchen es auch: Gängige Werkzeuge zum Auslesen von Anmeldeinformationen aus dem Arbeitsspeicher von LSASS (*Credential Dumping*) benötigen dieses Recht, um den Prozess zu öffnen. Der Lehrplan sieht deshalb „nur notwendige Admins“ vor. Standardmäßig hat die lokale Gruppe der Administratoren das Recht.

Eine realistische Einschätzung ist wichtig: Das Recht einzuschränken ist eine Schicht der Tiefenverteidigung, kein Allheilmittel. Wer bereits SYSTEM-Rechte hat oder Administrator auf einem Rechner ist, hat meist weitere Wege (nach meiner Kenntnis, nicht aus den abgerufenen Seiten). Der Nutzen liegt darin, dass man weniger Konten mit dem Recht ausstattet, Standardwerkzeuge der Angreifer erschwert und auffälliges Verhalten sichtbar macht (siehe Modul 09: Ereignis 4672/4673 bei Verwendung sensibler Rechte, nach meiner Kenntnis). Zusammen mit LSA-Schutz und Credential Guard (Modul 03) bildet das Recht eine Kette von Hürden.

> **Merke**
>
> Wie bei allen Benutzerrechten gilt: Die Richtlinie ersetzt die Standardzuweisung. Trägt man eine leere Liste ein, besitzt niemand mehr das Recht; das ist möglich, wirkt aber auf Entwicklerarbeitsplätze, bestimmte Installationsprogramme und Diagnosewerkzeuge. Für Entwickler und Administratoren, die debuggen müssen, legt man eine eigene Gruppe an, die das Recht auf eigenen Geräten bekommt.

Das Beispiel setzt das Recht für die normale Büroflotte auf eine kleine Gruppe und zeigt, wie man den Zustand inventarisiert. Der Schlüssel `SeDebugPrivilege` im Abschnitt `[Privilege Rights]` entspricht dem Standardformat. Die Abfrage mit `whoami /priv` zeigt die Rechte des aktuell angemeldeten Kontos; sie lässt sich auch aus einer Administratorsitzung zur Kontrolle verwenden.

```ps
Import-Module ActiveDirectory
$dbg = (Get-ADGroup "GG-Debug-Berechtigt").SID.Value   # z. B. Entwickler und 2nd-Level

$inf = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeDebugPrivilege = *$dbg
"@
Set-Content -Path "$env:TEMP\debug.inf" -Value $inf -Encoding Unicode

# Inventur am Client: Wer hat das Recht, wer nutzt es?
secedit /export /cfg "$env:TEMP\aktuell.inf" /areas USER_RIGHTS | Out-Null
Select-String -Path "$env:TEMP\aktuell.inf" -Pattern 'SeDebugPrivilege'
whoami /priv | Select-String 'SeDebugPrivilege'
```

Der Vorlagenteil schreibt das Recht auf die Gruppe `GG-Debug-Berechtigt`; wichtig ist, dass die Gruppe existiert und die richtigen Personen enthält, sonst verliert auch der Administrator das Recht. Die Inventur zeigt vor dem Rollout, wer es hat. Ein Treffer in der Ausgabe von `whoami /priv` heißt, dass das Recht im aktuellen Token vorhanden ist (es kann dort deaktiviert, aber vorhanden sein).

**Typische Fehler.** Falsch: das Recht flächendeckend zu entziehen, ohne die Software zu testen. Einige Installationsprogramme, Überwachungs- und Sicherheitswerkzeuge sowie Entwicklungsumgebungen funktionieren nach meiner Kenntnis nicht mehr (im Pilot zu prüfen). Richtig: eine Ausnahmegruppe, Pilot mit typischer Software. Zweiter Fehler: zu glauben, der Entzug mache Credential Dumping unmöglich. Richtig: als eine Schicht von mehreren betrachten. Dritter Fehler: das Recht an „Authentifizierte Benutzer“ zu vergeben, um ein Problem zu lösen.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Penetrationstest liefert auf einem Rechner mit entzogenem Recht den üblichen Speicherauszug nicht mehr ohne Zusatzschritte. Der Tester muss das Recht zuerst anderweitig erlangen; dabei entstehen Ereignisse, die die Überwachung auswerten kann.

## 77 Impersonate Client einschränken

| **Feld**        | **Steckbrief**                                                                                                                   |
|:----------------|:---------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Zuweisen von Benutzerrechten |
| Einstellung     | Client nach Authentifizierung imitieren                                                                                          |
| Empfehlung      | Nur erforderliche Dienste                                                                                                        |
| Ziel / Zweck    | Reduziert Tokenmissbrauch                                                                                                        |
| Zielbereich     | Computer                                                                                                                         |
| Priorität       | 1                                                                                                                                |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                      |

*Impersonation* (englisch für Imitation) bedeutet, dass ein Programm vorübergehend im Namen eines anderen Benutzers handelt. Ein Dateiserver tut das zum Beispiel, wenn er mit den Rechten des anfragenden Clients auf eine Datei zugreift. Das Recht „Client nach der Authentifizierung imitieren“ (*Impersonate a client after authentication*, `SeImpersonatePrivilege`) erlaubt es Prozessen, die diesem Konto gehören, solche Tokens zu übernehmen. Die Microsoft-Dokumentation erklärt den Zweck: Das Recht verhindert, dass ein unberechtigter Benutzer einen Client dazu bringt, sich (etwa per RPC oder Named Pipe) mit einem von ihm erstellten Dienst zu verbinden, um dann den Client zu imitieren und die eigenen Rechte auf Administrator- oder Systemebene zu erhöhen.

Standardmäßig bekommen Dienste dieses Recht über die eingebaute Gruppe „Dienst“ (*Service*), die jedem vom Dienststeuerungs-Manager gestarteten Dienst ins Token gelegt wird. Normale Benutzer brauchen es laut Microsoft in der Regel nicht. Die empfohlene Konfiguration laut Baseline lautet: Administratoren, LOCAL SERVICE, NETWORK SERVICE und SERVICE. Eine Besonderheit: Ein Microsoft-SQL-Server mit der Komponente Integration Services braucht zusätzliche Einträge, was die Baseline als Ausnahme nennt. Weil dieses Recht als sensibles Recht gilt, wird seine Verwendung bei entsprechender Überwachung protokolliert (siehe Modul 09).

> **Ergänzung aus der Nachrecherche**
>
> Wichtige Warnung aus der Microsoft-Dokumentation zum Richtlinien-CSP `UserRights/ImpersonateClient`: Wer das Recht konfiguriert, ersetzt die vorhandenen Zuweisungen. Das System verlangt, dass *Local Service* (SID `S-1-5-19`) und *Network Service* (SID `S-1-5-20`) das Recht immer besitzen; man muss sie also zusätzlich zu allen anderen Konten stets angeben. Und: Programme, die das Recht früher hatten, können es verlieren und dann nicht mehr laufen.

Das Beispiel setzt die empfohlene Zuweisung (Administratoren, Local Service, Network Service, Dienst) und listet, welche Dienste auf dem Gerät mit welchem Konto laufen, um Sonderfälle vor dem Rollout zu finden. Die SIDs `S-1-5-32-544` (Administratoren), `S-1-5-19`, `S-1-5-20` und `S-1-5-6` (Dienst) sind die bekannten SIDs.

```ps
$inf = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeImpersonatePrivilege = *S-1-5-32-544,*S-1-5-19,*S-1-5-20,*S-1-5-6
"@
Set-Content -Path "$env:TEMP\imp.inf" -Value $inf -Encoding Unicode

# Inventur: Dienste, die NICHT unter den Standardkonten laufen (Sonderfaelle)
Get-CimInstance Win32_Service |
    Where-Object { $_.StartName -and $_.StartName -notmatch '^(LocalSystem|NT AUTHORITY\\(LocalService|NetworkService|System))$' } |
    Select-Object Name, StartName, State |
    Sort-Object StartName
```

Die Vorlage nennt die vier Konten laut Baseline. Die Inventur listet alle Dienste, die unter einem anderen Konto laufen, zum Beispiel Datenbank- und Anwendungsdienste mit Dienstkonten. Diese Konten bekommen das Recht automatisch über die Gruppe „Dienst“, wenn sie vom Dienststeuerungs-Manager gestartet werden; Sonderfälle sind etwa Programme, die nicht als Dienst laufen, aber Tokens imitieren (zum Beispiel manche Webserver-Arbeitsprozesse nach meiner Kenntnis). Im Pilot ist zu prüfen, ob solche Anwendungen weiter funktionieren.

**Typische Fehler.** Falsch: die Liste ohne Local Service und Network Service zu setzen. Das System verlangt diese zwei Konten, und die Folgen sind schwer vorhersagbar (Dienste starten nicht). Richtig: immer mit angeben. Zweiter Fehler: Benutzergruppen aufzunehmen, „damit es funktioniert“. Das Recht ist ein bekanntes Sprungbrett zur Rechteausweitung (nach meiner Kenntnis eine Voraussetzung vieler „Potato“-Angriffe); es gehört nur Diensten. Dritter Fehler: SQL-Server-Dienstkonten nicht zu berücksichtigen, die Microsoft ausdrücklich als Ausnahme nennt.

> **Praxisbeispiel**
>
> Beispielszenario: Nach dem Einführen der Richtlinie auf einem Anwendungsserver startet ein Dienst nicht mehr. Die Inventur zeigt, dass der Dienst unter einem eigenen Konto läuft und nach der Vorgabe der Anwendung das Recht explizit braucht. Das Konto wird nach Dokumentation der Begründung der Liste hinzugefügt.

## 78 Lokale Anmeldung für Gäste verweigern

| **Feld**        | **Steckbrief**                                                                                                                   |
|:----------------|:---------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Zuweisen von Benutzerrechten |
| Einstellung     | Lokal anmelden verweigern                                                                                                        |
| Empfehlung      | Guests                                                                                                                           |
| Ziel / Zweck    | Verhindert Gastzugriff                                                                                                           |
| Zielbereich     | Computer                                                                                                                         |
| Priorität       | 1                                                                                                                                |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                      |

Windows kennt ein eingebautes Konto „Gast“ (*Guest*), das ohne Kennwort Zugriff bieten kann, und eine Gruppe „Gäste“. Das Gastkonto ist standardmäßig deaktiviert. Laut der Microsoft-Baseline ist die Einstellung „Accounts: Guest account status“ auf „Deaktiviert“ zu setzen und gilt als kritisch (Wert 0 in der Richtlinie): Das Gastkonto erlaubt nicht authentifizierten Netzwerkbenutzern den Zugang zum System. Der Lehrplan geht einen Schritt weiter und verlangt, die lokale Anmeldung für die Gruppe „Gäste“ ausdrücklich zu verweigern. Das ist ein Zusatzgurt: Selbst wenn jemand das Gastkonto versehentlich aktiviert oder ein anderes Konto in die Gruppe Gäste legt, ist die interaktive Anmeldung gesperrt.

Technisch ist es dasselbe Recht wie in Abschnitt 74 (`SeDenyInteractiveLogonRight`). Das hat eine direkte Folge, die in der Praxis oft übersehen wird: Die Zuweisung eines Benutzerrechts in zwei verschiedenen GPOs wird nicht zusammengeführt, sondern die GPO mit höherer Priorität gewinnt, und die Einträge der anderen gehen verloren. Wer also Servicekonten in einer GPO sperrt und die Gäste in einer zweiten, hat im besten Fall nur die Hälfte wirksam und im Wiederholungsfall wechselnde Zustände. Die einzige saubere Lösung ist eine gemeinsame GPO für beide Einträge (und eventuelle weitere, wie das lokale Administratorkonto auf Servern).

> **Ergänzung aus der Nachrecherche**
>
> Die Baseline nennt für die Einstellung des Gastkontos die Position „Computerkonfiguration \> Richtlinien \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Sicherheitsoptionen \> Accounts: Guest account status“ mit dem Schlüssel `EnableGuestAccount` in der Sicherheitsvorlage. Beachten: Die Einstellung hat keine Wirkung auf Domänencontrollern, da diese keine lokale Kontendatenbank haben; sie kann dort auf Domänenebene gesetzt werden, ähnlich wie Kontensperr- und Kennwortrichtlinien.

Das Beispiel führt die Einträge aus Abschnitt 74 und 78 in einer Vorlage zusammen und deaktiviert zusätzlich das Gastkonto. Die Form (`EnableGuestAccount = 0` im Abschnitt `[System Access]`) entspricht der Baseline-Angabe; `S-1-5-32-546` ist die bekannte SID der Gruppe Gäste. Die Zeile mit `SeDenyInteractiveLogonRight` enthält beide Quellen.

```ps
Import-Module ActiveDirectory
$svcSid = (Get-ADGroup "GG-Servicekonten").SID.Value

$inf = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[System Access]
EnableGuestAccount = 0
[Privilege Rights]
SeDenyInteractiveLogonRight = *S-1-5-32-546,*$svcSid
"@
Set-Content -Path "$env:TEMP\deny-local.inf" -Value $inf -Encoding Unicode

# Am Client: Gastkonto-Status und Recht pruefen
Get-LocalUser -Name Guest | Select-Object Name, Enabled
secedit /export /cfg "$env:TEMP\aktuell.inf" /areas USER_RIGHTS | Out-Null
Select-String -Path "$env:TEMP\aktuell.inf" -Pattern 'SeDenyInteractiveLogonRight'
```

Der Abschnitt `[System Access]` deaktiviert das Gastkonto, der Abschnitt `[Privilege Rights]` verweigert die lokale Anmeldung für Gäste und Servicekonten in einer Zeile. Auf dem Client zeigt `Get-LocalUser`, ob das Konto `Guest` aktiviert ist; in der Ausgabe sollte `Enabled` gleich `False` sein. Der Export zeigt die tatsächlich gesetzten SIDs.

**Typische Fehler.** Falsch: zwei GPOs mit demselben Benutzerrecht zu betreiben und sich über „verschwundene“ Einträge zu wundern. Richtig: eine GPO je Recht, dokumentiert. Zweiter Fehler: statt der Gruppe Gäste die Gruppe „Jeder“ oder „Benutzer“ einzutragen; das sperrt alle. Dritter Fehler: sich auf das deaktivierte Gastkonto zu verlassen und die Gruppe Gäste nie zu prüfen; in alten Domänen finden sich dort manchmal echte Benutzer.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Audit stellt fest, dass auf einem Messerechner das Gastkonto aktiviert ist, damit Besucher ohne Anmeldung eine Präsentation zeigen können. Die Richtlinie deaktiviert das Konto und verweigert die Anmeldung; für Besucher gibt es ein eigenes Gastnetz und ein eigenes Gerät.

## 79 Microsoft-Konten blockieren

| **Feld**        | **Steckbrief**                                                                                                          |
|:----------------|:------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Sicherheitsoptionen |
| Einstellung     | Konten: Microsoft-Konten blockieren                                                                                     |
| Empfehlung      | Nach Unternehmensvorgabe                                                                                                |
| Ziel / Zweck    | Erzwingt Unternehmensidentitäten                                                                                        |
| Zielbereich     | Computer                                                                                                                |
| Priorität       | 2                                                                                                                       |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                             |

Ein *Microsoft-Konto* ist ein privates Konto (zum Beispiel eine Outlook.com-Adresse), das ein Mitarbeiter mit seinem Windows-Benutzer verbinden kann. Damit könnte er Einstellungen, Dateien und Kennwörter mit seinem privaten Cloud-Konto synchronisieren und auf dem Dienstgerät Apps und Dienste mit privater Identität nutzen. Für ein Unternehmen ist das aus Kontrollgründen unerwünscht: Die Identität gehört nicht der Organisation, und Daten können dem Zugriff der IT entzogen werden. Die Sicherheitsoption „Accounts: Block Microsoft accounts“ steuert das.

Laut der Microsoft-Dokumentation (Policy CSP LocalPoliciesSecurityOptions) hat die Einstellung drei Werte: 0 (Standard, Microsoft-Konten dürfen verwendet werden), 1 (Benutzer können keine neuen Microsoft-Konten hinzufügen) und 3 (Benutzer können weder Microsoft-Konten hinzufügen noch sich damit anmelden). Der Unterschied ist entscheidend. Bei Wert 1 können bereits verbundene Konten weiterhin anmelden, aber neue Verbindungen und die Verknüpfung lokaler Konten mit Microsoft-Konten sind unterbunden; Microsoft nennt das die bevorzugte Option, wenn man die Verwendung einschränken will. Bei Wert 3 können bestehende Microsoft-Konto-Benutzer sich nicht mehr anmelden, und laut Dokumentation kann es dadurch unmöglich werden, dass ein vorhandener Administrator sich anmeldet und das System verwaltet. Die Azure-Baseline erwartet den Wert 3. Der Lehrplan sagt „nach Unternehmensvorgabe“: Die Wahl zwischen 1 und 3 ist eine Frage der Risikoabwägung und des Bestands.

> **Ergänzung aus der Nachrecherche**
>
> Ein zweites, ergänzendes Setting laut Microsoft: „Apps and services: Block Microsoft account user authentication“ (Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Microsoft-Konto). Es verhindert, dass Apps und Dienste ein Microsoft-Konto zur Authentifizierung nutzen. Es beeinflusst weder die Anmeldung an Windows mit einem Microsoft-Konto noch die Anmeldung im Browser bei webbasierten Apps. Bereits angemeldete Tokens bleiben bis zum Ablauf des Caches gültig; Microsoft empfiehlt, die Einstellung zu aktivieren, bevor sich ein Benutzer anmeldet.

Das Beispiel setzt den Wert 1 (milde Variante) und prüft den Bestand an verbundenen Microsoft-Konten, bevor man auf 3 geht. Der Registrywert `NoConnectedUser` im Schlüssel `Software\Microsoft\Windows\CurrentVersion\Policies\System` wird in der Baseline genannt (erwarteter Wert 3). Die Inventur über die Profilliste ist aus meiner Kenntnis; `MicrosoftAccount` als Quelle der Benutzerprinzipale ist ein Standardwert der lokalen Benutzerverwaltung.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "SEC-MS-Konten"
# 1 = keine neuen Microsoft-Konten, 3 = auch keine Anmeldung mit vorhandenen
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName NoConnectedUser -Type DWord -Value 1

# Inventur am Client: gibt es Benutzer mit Microsoft-Konto?
Get-LocalUser | Where-Object PrincipalSource -eq 'MicrosoftAccount' |
    Select-Object Name, Enabled, LastLogon

# Wer ist lokaler Administrator und von welcher Quelle?
Get-LocalGroupMember -Group Administrators | Select-Object Name, PrincipalSource
```

Der Wert 1 verhindert neue Verknüpfungen. Die erste Abfrage listet lokale Benutzer, die mit einem Microsoft-Konto verbunden sind; die zweite zeigt die Quellen der lokalen Administratoren. Gibt es dort Microsoft-Konten, ist der Wert 3 gefährlich, weil diese Administratoren sich danach nicht mehr anmelden könnten.

**Typische Fehler.** Falsch: gleich den Wert 3 auszurollen. Wenn der einzige Administrator eines Geräts ein Microsoft-Konto ist, verliert man die Verwaltung. Richtig: erst Inventur, dann Wert 1, später gegebenenfalls Wert 3. Zweiter Fehler: Microsoft-Konten zu blockieren und gleichzeitig Entra-ID-Anmeldung zu planen; Arbeits- und Schulkonten (Entra) sind etwas anderes als private Microsoft-Konten, und die Richtlinie betrifft nur Letztere. Dritter Fehler: die Richtlinie ohne Dokumentation einzuführen; Benutzer erleben „Zugriff verweigert“ und verstehen es nicht.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Mitarbeiter will auf seinem Dienstlaptop sein privates Microsoft-Konto verbinden, um Fotos zu synchronisieren. Das Fenster bietet die Option nicht mehr an. Die IT erklärt den Grund und verweist auf die private Hardware.

## 80 Cached Logons begrenzen

| **Feld**        | **Steckbrief**                                                                                                          |
|:----------------|:------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Sicherheitsoptionen |
| Einstellung     | Interaktive Anmeldung: Anzahl vorheriger Anmeldungen                                                                    |
| Empfehlung      | 1-2 oder nach Bedarf                                                                                                    |
| Ziel / Zweck    | Reduziert Risiko durch gecachte Credentials                                                                             |
| Zielbereich     | Computer                                                                                                                |
| Priorität       | 2                                                                                                                       |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                             |

Wenn sich ein Domänenbenutzer anmeldet, prüft Windows das Kennwort beim Domänencontroller. Ist keiner erreichbar (Notebook im Zug, Netzausfall), gäbe es ohne Hilfe keine Anmeldung. Deshalb speichert Windows eine *verschlüsselte Prüfsumme* der Anmeldedaten der letzten Anmeldungen lokal. Das sind die *Cached Logons*, englisch für zwischengespeicherte Anmeldungen. Die Sicherheitsoption „Interactive logon: Number of previous logons to cache“ legt fest, für wie viele verschiedene Benutzer das geschieht. Laut Microsoft liegt der Standard bei 10, der gültige Bereich bei 0 bis 50, und 0 schaltet das Caching ab. Der Registrywert heißt `CachedLogonsCount` im Schlüssel `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon` (Typ REG_SZ); Änderungen brauchen einen Neustart.

Das Risiko ist die Offline-Angreifbarkeit: Wer das Dateisystem eines Rechners lesen kann, findet die gecachten Prüfsummen und kann versuchen, daraus Kennwörter zu errechnen. Die Azure-Baseline empfiehlt deshalb vier oder weniger Anmeldungen; strengere Vorgaben sehen 1 oder 2 vor, wie der Lehrplan. Die Kehrseite: Ist der Wert zu klein, scheitert bei mehreren Benutzern am selben Gerät oder bei Vertretungen die Offline-Anmeldung. Laut der Microsoft-Fehlerbeschreibung führt es zur Meldung „Es sind momentan keine Anmeldeserver verfügbar“, wenn ein Benutzer nicht im Cache ist, und der älteste Eintrag wird verdrängt, wenn neue Benutzer sich anmelden. Eine weitere Feinheit der Dokumentation: Hat der Benutzer sein Kennwort in der Cloud oder am Domänencontroller geändert, kennt der Cache das neue Kennwort nicht; mit dem alten kann er sich weiter offline anmelden.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Beschreibung der Policy-CSP-Dokumentation ist die Einstellung als MDM-Richtlinie erst ab bestimmten Windows-11-Updates verfügbar (Windows 11 22H2 mit KB5053657 und 24H2 mit KB5052093); per Gruppenrichtlinie steht sie schon lange zur Verfügung. Für Microsoft-Entra-Geräte (nicht hybride) gilt nach der Microsoft-Entra-FAQ, auf die ein Beitrag in Microsoft Q&A verweist, dass sich zwischengespeicherte Anmeldungen nicht deaktivieren oder ablaufen lassen; diese Aussage habe ich nur aus zweiter Hand und nicht an der Originalseite geprüft. Für reine Entra-Umgebungen ist die Richtlinie also nicht das richtige Werkzeug.

Das Beispiel setzt den Wert 2 und liest am Client aus, wie viele Einträge aktuell erlaubt sind. Der Registrywert ist von Microsoft dokumentiert; in der GPO ist er Teil der Sicherheitsoptionen, die technisch in der Sicherheitsvorlage stehen. Mit `Set-GPPrefRegistryValue` lässt sich der Wert als Preference verteilen, wenn man die Sicherheitsoptionen nicht direkt bearbeiten will.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "SEC-CachedLogons"
Set-GPPrefRegistryValue -Name $gpo.DisplayName -Context Computer -Action Update `
    -Key "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" `
    -ValueName CachedLogonsCount -Type String -Value "2"

# Am Client: aktueller Wert (Standard 10, wenn nie gesetzt)
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").CachedLogonsCount

# Ereignis, wenn Eintraege verdraengt werden (LsaSrv 45058)
Get-WinEvent -FilterHashtable @{LogName='System'; Id=45058} -MaxEvents 5 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, ProviderName, Message
```

Der Wert wird als Zeichenfolge geschrieben (Typ `String`), wie Microsoft es beschreibt. Die Abfrage liefert den aktuellen Zustand. Die Ereignisabfrage nutzt die ID 45058 aus der Microsoft-Fehlerbeschreibung: Sie zeigt an, dass ein Eintrag aus dem Cache nach dem Prinzip „der Älteste zuerst“ verdrängt wurde. Häufige Ereignisse deuten darauf hin, dass der Wert für die Nutzungsrealität zu klein ist.

**Typische Fehler.** Falsch: den Wert auf 0 zu setzen, ohne die mobile Nutzung zu bedenken. Notebooks lassen sich ohne Netz nicht mehr anmelden. Richtig: für Geräte, die nie das Büro verlassen, kann 0 oder 1 gelten; für mobile Geräte ein Wert, der die tatsächlichen Benutzer abdeckt, in der Baseline höchstens 4. Zweiter Fehler: gemeinsam genutzte Geräte (Schulungsräume, Schichtbetrieb) mit 1 oder 2 zu betreiben; mit jedem neuen Benutzer fällt ein anderer aus dem Cache. Dritter Fehler: zu glauben, die Zahl sei ein Schutz vor Kennwortdiebstahl durch Angreifer mit Adminrechten; sie begrenzt nur die Offline-Angriffsfläche.

> **Praxisbeispiel**
>
> Beispielszenario: Für Notebooks im Außendienst gilt Wert 2 (Besitzer plus ein Vertreter), für Büro-PCs Wert 1. Für Schulungsräume mit wechselnden Benutzern bleibt der Standardwert, die Geräte sind dafür dauerhaft im Netz.

## Übungsaufgaben zu Modul 08

**Aufgabe 1.** **(leicht)** Erklären Sie in zwei Sätzen, welches Problem Windows LAPS löst und welche Mindesteinstellung dafür nötig ist.

**Aufgabe 2.** **(leicht)** Welche Werte kann `BackupDirectory` annehmen, und was bedeuten sie?

**Aufgabe 3.** **(leicht)** Warum schlägt ein Verweigern-Recht ein Zulassen-Recht? Nennen Sie ein Beispiel für einen Konfigurationsfehler daraus.

**Aufgabe 4.** **(mittel)** Warum gehören die Abschnitte 74 und 78 in dieselbe GPO? Was passiert, wenn sie getrennt sind?

**Aufgabe 5.** **(mittel)** Vergleichen Sie die Werte 1 und 3 der Einstellung „Microsoft-Konten blockieren“ und nennen Sie das Risiko von Wert 3.

**Aufgabe 6.** **(praktisch)** Schreiben Sie ein Skript, das eine GPO mit `BackupDirectory = 2`, Kennwortalter 14 Tage und Länge 20 anlegt und die Berechtigung `GpoApply` für eine Pilotgruppe setzt.

**Aufgabe 7.** **(praktisch)** Schreiben Sie ein Skript, das auf einem Client die Mitglieder der lokalen Administratorengruppe, den Status des Gastkontos und den Wert von `CachedLogonsCount` als Objekt ausgibt.

**Aufgabe 8.** **(schwer)** Entwerfen Sie ein Rechtekonzept für 800 Clients: Wer ist lokaler Administrator, wer darf RDP, wer Debug, welche Konten sind Servicekonten, wie funktioniert der Notfallzugang? Nennen Sie Risiken des Rollouts und Gegenmaßnahmen.

## Lösungen zu Modul 08

**Lösung 1.** LAPS vergibt für das lokale Administratorkonto jedes Rechners ein zufälliges, regelmäßig wechselndes Kennwort und sichert es zentral. So öffnet ein erbeutetes Kennwort nicht mehr alle Rechner. Mindesteinstellung: `BackupDirectory` (2 für Active Directory, 1 für Entra ID).

**Lösung 2.** 0 = deaktiviert (Kennwort wird nicht gesichert, alle anderen Einstellungen werden ignoriert), 1 = nur Microsoft Entra ID, 2 = nur Windows-Server-Active-Directory.

**Lösung 3.** Weil Windows beim Zusammentreffen beider Rechte immer die Verweigerung auswertet. Fehler: Die Gruppe „Domänen-Benutzer“ im Verweigern-Recht sperrt auch die Administratoren aus, die ebenfalls Domänen-Benutzer sind.

**Lösung 4.** Beide setzen `SeDenyInteractiveLogonRight`. Zuweisungen aus mehreren GPOs werden nicht zusammengeführt; die GPO mit der höchsten Priorität ersetzt die anderen. Bei getrennten GPOs wäre nur eine der beiden Listen wirksam, und die Richtlinie wäre je nach Priorität unvollständig.

**Lösung 5.** Wert 1: keine neuen Microsoft-Konten, bestehende bleiben nutzbar. Wert 3: auch keine Anmeldung mit vorhandenen Microsoft-Konten. Risiko von 3: Ein Administrator, der ein Microsoft-Konto nutzt, kann sich nicht mehr anmelden, das System lässt sich eventuell nicht mehr verwalten.

```ps
# Loesung 6
Import-Module GroupPolicy
$gpo = New-GPO -Name "LAPS-Pilot"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\LAPS"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName BackupDirectory -Type DWord -Value 2
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName PasswordAgeDays -Type DWord -Value 14
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName PasswordLength  -Type DWord -Value 20
Set-GPPermission -Name $gpo.DisplayName -TargetName "GG-LAPS-Pilot" -TargetType Group -PermissionLevel GpoApply
Set-GPPermission -Name $gpo.DisplayName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoRead -Replace
```

```ps
# Loesung 7
$g  = Get-LocalUser -Name Guest -ErrorAction SilentlyContinue
$cl = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").CachedLogonsCount
[pscustomobject]@{
    Computer       = $env:COMPUTERNAME
    Administratoren = (Get-LocalGroupMember -Group Administrators | ForEach-Object Name) -join '; '
    GastAktiv      = if ($g) { $g.Enabled } else { 'nicht vorhanden' }
    CachedLogons   = $cl
}
```

**Lösung 8.** Beispiel: Lokale Administratoren per Eingeschränkter Gruppe: Domänen-Admins, Gruppe `GG-Workstation-Admins`, eingebautes Konto (durch LAPS verwaltet, 14 Tage). RDP: Zulassen nur Arbeitsplatzadmins; Verweigern für Gäste und lokale Konten. Debug: eigene Gruppe für Entwickler, auf Entwicklungs-OU, sonst nur Administratoren. Servicekonten: gMSA wo möglich, übrige in `GG-Servicekonten` mit Verweigern der interaktiven Anmeldung (in derselben GPO wie die Gäste). Notfallzugang: LAPS-Kennwort mit protokolliertem Abruf. Risiken: Aussperren (Pilot mit Testrechnern, Rückfall durch GPO-Verknüpfung entfernen), vergessene Verwaltungskonten, Servicekonten mit interaktivem Gebrauch. Gegenmaßnahmen: Inventur vorab, Pilotringe, Dokumentation, Helpdesk-Anleitung.
