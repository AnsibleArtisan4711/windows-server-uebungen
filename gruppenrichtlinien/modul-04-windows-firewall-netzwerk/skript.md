# Modul 04 - Windows Firewall und Netzwerk

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Gruppenrichtlinien für Windows 11 – 100 Richtlinien im Detail“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Steckbriefe als Tabellen, Übungsaufgaben und Lösungen als fortlaufend nummerierte Absätze). **Nummerierung:** Die Überschriften der Richtlinien tragen hier die laufende Nummer 1 bis 100 aus der Modultabelle; die Verweise im Text („Abschnitt 43“) meinen diese Nummer. (Im LaTeX-Satz zählen die Überschriften je Modul neu, etwa 5.3.) **Die Beispiele (PowerShell, INF) wurden für dieses Repository nicht ausgeführt**; sie verändern Gruppenrichtlinien, Registry und Sicherheitseinstellungen und gehören nur in eine Testumgebung (Pilot-OU, Testdomäne). Übersicht zum Modul: [README](README.md).

**Dauer:** 10 Unterrichtsstunden (Annahme: 1 Stunde je Richtlinie)  
**Priorität:** überwiegend 1 (drei Richtlinien mit Priorität 2)

| Nr. | Lerneinheit (Richtlinie)                         | Prio | Stunden |
|----:|:-------------------------------------------------|:----:|:-------:|
|  31 | Defender Firewall Domänenprofil aktivieren       |  1   |    1    |
|  32 | Defender Firewall Privatprofil aktivieren        |  1   |    1    |
|  33 | Defender Firewall Öffentliches Profil aktivieren |  1   |    1    |
|  34 | Eingehende Verbindungen standardmäßig blockieren |  1   |    1    |
|  35 | Firewall Logging aktivieren                      |  2   |    1    |
|  36 | NetBIOS Namensauflösung deaktivieren             |  2   |    1    |
|  37 | LLMNR deaktivieren                               |  1   |    1    |
|  38 | Unsichere Gastanmeldungen SMB blockieren         |  1   |    1    |
|  39 | NTLM Nutzung auditieren                          |  2   |    1    |
|  40 | Remote Desktop nur mit NLA                       |  1   |    1    |
|     | **Summe**                                        |      | **10**  |

**Worum es in diesem Modul geht.** Ein Client ist im Netzwerk ständig Angriffen ausgesetzt: Andere Rechner sprechen ihn an, Namensauflösungs-Protokolle aus den 1990er-Jahren verraten Anmeldedaten, und Fernwartungsdienste öffnen Türen. Dieses Modul behandelt die drei Schichten, mit denen man das beherrscht: die Host-Firewall (Abschnitte 31 bis 35), die Abschaltung unsicherer Legacy-Protokolle (36 bis 38) und die Absicherung der Authentifizierung (39 und 40). Als Vorwissen genügt, dass Rechner über IP-Adressen und Ports kommunizieren; alles Weitere wird erklärt.

## 31 Defender Firewall Domänenprofil aktivieren

| **Feld**        | **Steckbrief**                                                                                                                     |
|:----------------|:-----------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Windows Defender Firewall mit erweiterter Sicherheit |
| Einstellung     | Windows Defender Firewall: Domänenprofil                                                                                           |
| Empfehlung      | Aktiviert                                                                                                                          |
| Ziel / Zweck    | Schützt Clients im Unternehmensnetz                                                                                                |
| Zielbereich     | Computer                                                                                                                           |
| Priorität       | 1                                                                                                                                  |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                        |

Eine *Host-Firewall* ist ein Paketfilter, der direkt auf dem Rechner läuft und entscheidet, welche Netzwerkverbindungen er annimmt oder aufbaut. Sie ist die letzte Verteidigungslinie, wenn ein Angreifer bereits im selben Netz sitzt und die Firewall am Netzrand also nichts mehr nützt. Die Windows Defender Firewall arbeitet mit *Profilen*: Windows erkennt anhand des Netzwerks, in dem sich der Rechner befindet, welches Profil gilt, und wendet dafür jeweils eigene Einstellungen an. Das *Domänenprofil* gilt, wenn der Rechner einen Domänencontroller seiner Domäne erreicht, also im Unternehmensnetz oder über VPN.

Die Einstellung „Firewallstatus“ je Profil steht in der Richtlinie unter „Windows Defender Firewall mit erweiterter Sicherheit \> Windows Defender Firewall-Eigenschaften“. Aktiviert man sie, filtert Windows nach den Regeln und dem Standardverhalten des Profils. Ohne Aktivierung entscheidet die lokale Einstellung, die ein Administrator oder eine Software jederzeit ändern kann. Das Setzen per Gruppenrichtlinie macht die Aktivierung verbindlich: Lokale Änderungen werden beim nächsten Richtlinienzyklus zurückgesetzt, und die Oberfläche der Windows-Sicherheit zeigt, dass die Einstellung von der Organisation verwaltet wird.

> **Ergänzung aus der Nachrecherche**
>
> Die Windows-Firewall-Richtlinien haben zwei Orte: die Sicherheitseinstellungen (GPMC, Pfad oben) und, bei Intune, den Firewall-CSP. Der Firewall-Dienst (`mpssvc`) darf laut Microsoft nicht beendet werden; das Abschalten des Dienstes ist kein unterstützter Weg, die Firewall zu deaktivieren. Zu verwenden ist stets die Einstellung „Firewallstatus“.

Das Beispiel legt eine GPO an, die in allen drei Profilen die Firewall einschaltet; die GPO wird in diesem Abschnitt für das Domänenprofil erklärt und in den Abschnitten 32 und 33 für die übrigen Profile wieder verwendet. Es nutzt `Set-NetFirewallProfile` mit der Option `-PolicyStore`, die in eine GPO schreibt, statt den lokalen Rechner zu verändern. Der Syntax der Option (`Domäne\GPO-Name`) ist von Microsoft dokumentiert; die GPO muss vorher existieren.

```ps
Import-Module GroupPolicy
New-GPO -Name "FW-Profile" | Out-Null

# In die GPO (nicht in den lokalen Rechner) schreiben
$store = "contoso.local\FW-Profile"
$session = Open-NetGPO -PolicyStore $store

Set-NetFirewallProfile -Profile Domain -Enabled True -GPOSession $session
Save-NetGPO -GPOSession $session

# Kontrolle am Client
Get-NetFirewallProfile -Profile Domain | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
```

`Open-NetGPO` öffnet die GPO in einer Sitzung, `Set-NetFirewallProfile` ändert darin das Domänenprofil, und `Save-NetGPO` schreibt die Änderung zurück. Die Domäne `contoso.local` ist ein Platzhalter. Auf dem Client zeigt `Get-NetFirewallProfile` den wirksamen Zustand; nach einem `gpupdate /force` muss `Enabled` den Wert `True` haben.

**Typische Fehler.** Falsch: die Firewall zu aktivieren, ohne vorher die Regeln für Verwaltung (WinRM, RPC, Remoteverwaltung, Ping für Monitoring) zu definieren. Die Server-Verwaltung bricht dann ab, weil die eingehenden Verbindungen blockiert werden. Richtig: erst Regeln per GPO bereitstellen (Abschnitt 34), dann die Standardaktion setzen. Zweiter Fehler: Software-Firewalls Dritter parallel zu betreiben, ohne dass diese die Windows-Firewall korrekt registrieren; das führt zu doppelter Filterung und schwer auffindbaren Blockaden. Dritter Fehler: den Dienst `mpssvc` zu deaktivieren, um die Firewall zu „abzuschalten“; das stört auch IPsec und andere Funktionen.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Notebook, auf dem ein Entwickler testweise die Firewall abgeschaltet hatte, wird nach dem Einführen der Richtlinie beim nächsten Gruppenrichtlinienzyklus automatisch wieder geschützt. Das Audit zeigt, dass vier Rechner zuvor ohne aktive Firewall im Netz hingen.

## 32 Defender Firewall Privatprofil aktivieren

| **Feld**        | **Steckbrief**                                                                                                                     |
|:----------------|:-----------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Windows Defender Firewall mit erweiterter Sicherheit |
| Einstellung     | Windows Defender Firewall: Privates Profil                                                                                         |
| Empfehlung      | Aktiviert                                                                                                                          |
| Ziel / Zweck    | Schützt Clients in privaten Netzen                                                                                                 |
| Zielbereich     | Computer                                                                                                                           |
| Priorität       | 1                                                                                                                                  |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                        |

Das *private Profil* gilt in Netzen, die der Benutzer oder Administrator ausdrücklich als privat einstuft, typischerweise das Heimnetz. Es ist das Profil mit den lockersten Standardregeln, weil man davon ausgeht, dass Geräte im Heimnetz vertrauenswürdig sind. Für einen Unternehmenslaptop im Homeoffice ist diese Annahme trotzdem nur bedingt richtig: Im Heimnetz hängen Smart-TVs, Spielkonsolen und IoT-Geräte, die ein Unternehmen nicht kontrolliert. Darum aktiviert man die Firewall auch hier verbindlich.

Wie Windows ein Profil wählt, ist wichtig, um Fehlkonfigurationen zu vermeiden. Laut Microsoft gilt das Domänenprofil, wenn der Rechner sich bei einem Domänencontroller authentifizieren konnte; das öffentliche Profil ist der Standard für alle anderen Netzwerke, und das private Profil gilt nur für Netze, die ein Benutzer oder Administrator ausdrücklich als privat markiert. Die Einordnung kann ein Standardbenutzer in der Regel nicht ändern, wenn man es per Richtlinie unterbindet (Netzwerklisten-Manager-Richtlinien). Wichtig: Ein Rechner kann nur ein Profil gleichzeitig haben; bei mehreren Netzwerkkarten gilt für den Verkehr jeder Karte das passende Profil.

> **Merke**
>
> Die Profile unterscheiden sich in den *Regeln*, nicht in der Technik. Eine Regel wird einem oder mehreren Profilen zugeordnet. Wer den Status je Profil setzt, bestimmt nur, ob die Firewall dort überhaupt filtert; wer die Regeln pflegt, bestimmt, was durchkommt.

Das Beispiel ergänzt die GPO aus Abschnitt 31 um das private Profil und liest auf dem Client die aktuellen Profile der Netzwerkkarten aus. Mit dem Netzwerkprofil lässt sich nachvollziehen, welche Regeln gerade greifen. Das Skript ändert auf dem Client nichts.

```ps
$store = "contoso.local\FW-Profile"
$session = Open-NetGPO -PolicyStore $store
Set-NetFirewallProfile -Profile Private -Enabled True -GPOSession $session
Save-NetGPO -GPOSession $session

# Welches Profil gilt gerade auf welcher Verbindung?
Get-NetConnectionProfile | Select-Object Name, InterfaceAlias, NetworkCategory
```

Die erste Hälfte aktiviert das private Profil in derselben GPO. Die Abfrage `Get-NetConnectionProfile` zeigt pro Verbindung die Kategorie (`DomainAuthenticated`, `Private` oder `Public`). So erkennt man, dass ein Notebook im Heimnetz tatsächlich das private und nicht das Domänenprofil nutzt.

**Typische Fehler.** Falsch: im privaten Profil großzügigere Freigaben zu lassen, „weil es ja nur das Heimnetz ist“. Ein Rechner mit offener Dateifreigabe im Heimnetz ist über ein Gäste-WLAN leicht erreichbar. Richtig: die Regeln so zu pflegen, dass private und öffentliche Profile gleichwertig streng sind. Zweiter Fehler: Benutzern zu erlauben, das Netzwerkprofil selbst auf „privat“ zu stellen, um eine Blockade zu umgehen. Dritter Fehler: zu vergessen, dass Rechner im VPN je nach Lösung entweder Domänen- oder öffentliches Profil erhalten; die Regeln sollten für beide getestet sein.

> **Praxisbeispiel**
>
> Beispielszenario: Eine Mitarbeiterin schaltet im Homeoffice ihr privates WLAN in den „privaten“ Modus. Weil die Firewall auch dort aktiv ist und keine Dateifreigabe zulässt, kann der Smart-TV im selben Netz nicht auf den Rechner zugreifen, obwohl er im Netz sichtbar ist.

## 33 Defender Firewall Öffentliches Profil aktivieren

| **Feld**        | **Steckbrief**                                                                                                                     |
|:----------------|:-----------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Windows Defender Firewall mit erweiterter Sicherheit |
| Einstellung     | Windows Defender Firewall: Öffentliches Profil                                                                                     |
| Empfehlung      | Aktiviert                                                                                                                          |
| Ziel / Zweck    | Schützt mobile Clients in fremden Netzen                                                                                           |
| Zielbereich     | Computer                                                                                                                           |
| Priorität       | 1                                                                                                                                  |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                        |

Das *öffentliche Profil* ist das wichtigste für mobile Geräte: Es greift im Hotel-WLAN, im Zug, im Café und in jedem Netz, das Windows nicht als Domäne oder als privat erkennt. Dort gibt es keinen Grund, anderen Teilnehmern zu vertrauen, und genau dort sitzen Angreifer, die einen offenen Port suchen. Das Profil ist deshalb von Haus aus am restriktivsten: Eingehende Verbindungen werden blockiert, sofern keine Regel sie ausdrücklich zulässt.

Zusätzlich lässt sich im öffentlichen Profil steuern, ob *lokale* Regeln zusammengeführt werden. In den Eigenschaften je Profil gibt es die Optionen „Lokale Firewallregeln anwenden“ und „Lokale Verbindungssicherheitsregeln anwenden“. Setzt man beide auf „Nein“, gelten nur die Regeln aus der Gruppenrichtlinie. Das verhindert, dass Installationsprogramme oder Benutzer lokal Ausnahmen anlegen, die im Café dann plötzlich offen sind. Der Preis: Alles, was Software braucht, muss zentral als Regel bereitgestellt werden.

> **Ergänzung aus der Nachrecherche**
>
> Microsoft beschreibt in der Dokumentation zur Firewall, dass die Richtlinien nach der Verarbeitung im *Richtlinienspeicher* (policy store) liegen und sich mit lokalen Regeln zusammenführen, sofern das Profil dies erlaubt. Der effektive Satz lässt sich mit `Get-NetFirewallRule -PolicyStore ActiveStore` ansehen. Dieser Befehl ist hilfreich, um nachzuvollziehen, warum eine Verbindung blockiert wird.

Das folgende Beispiel schaltet das öffentliche Profil ein und deaktiviert die Zusammenführung lokaler Regeln. Dazu dienen die Parameter `-AllowLocalFirewallRules` und `-AllowLocalIPsecRules` von `Set-NetFirewallProfile`. Die Wirkung betrifft Rechner im Pilot; lokale Regeln, die Anwendungen benötigen, funktionieren danach nicht mehr, daher unbedingt zuerst testen.

```ps
$store = "contoso.local\FW-Profile"
$session = Open-NetGPO -PolicyStore $store
Set-NetFirewallProfile -Profile Public -Enabled True `
    -AllowLocalFirewallRules False -AllowLocalIPsecRules False `
    -GPOSession $session
Save-NetGPO -GPOSession $session

# Am Client: welche Regeln gelten wirklich?
Get-NetFirewallRule -PolicyStore ActiveStore -Direction Inbound -Enabled True |
    Where-Object Profile -match 'Public|Any' |
    Select-Object DisplayName, Action, Profile -First 20
```

Die Schalter `-AllowLocalFirewallRules False` und `-AllowLocalIPsecRules False` sorgen dafür, dass nur zentral definierte Regeln gelten. Die Abfrage am Client listet die aktiven eingehenden Regeln für das öffentliche Profil; so sieht man, ob unerwartete Freigaben bestehen.

**Typische Fehler.** Falsch: lokale Regeln im öffentlichen Profil sofort zu sperren und anschließend Teams, VPN-Client oder Kollaborationstools nicht mehr zu erreichen. Richtig: im Pilot mit dem tatsächlichen Softwareumfang testen und notwendige Regeln zentral nachliefern. Zweiter Fehler: das öffentliche Profil zu deaktivieren, „weil der VPN-Client sonst nicht startet“; die richtige Lösung ist eine Regel für den Client. Dritter Fehler: sich auf das Profil zu verlassen, wenn der Benutzer das WLAN-Netz als privat markieren kann (siehe Abschnitt 32).

> **Praxisbeispiel**
>
> Beispielszenario: Ein Berater arbeitet im Hotel-WLAN. Ein anderer Gast scannt das Netz nach offenen SMB-Ports. Weil das öffentliche Profil eingehende Verbindungen blockiert und keine lokalen Ausnahmen erlaubt sind, bleibt der Scan ergebnislos.

## 34 Eingehende Verbindungen standardmäßig blockieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows Defender Firewall mit erweiterter Sicherheit               |
| Einstellung     | Eingehende Verbindungen                                                                     |
| Empfehlung      | Blockieren                                                                                  |
| Ziel / Zweck    | Minimiert Angriffsoberfläche                                                                |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Eine Firewall verfolgt eine von zwei Grundstrategien: *Alles erlauben, was nicht verboten ist* oder *alles verbieten, was nicht erlaubt ist*. Die zweite Strategie ist die sichere, und genau das bedeutet „eingehende Verbindungen standardmäßig blockieren“: Das Standardverhalten für eingehenden Verkehr ist „Blockieren“, und nur Verkehr, den eine ausdrückliche Zulassungsregel erlaubt, kommt durch. Laut Microsoft ist das schon die Voreinstellung der Windows-Firewall (eingehend blockieren, ausgehend zulassen). Die Gruppenrichtlinie legt sie verbindlich fest und schützt vor Abweichungen.

Nützlich ist die Unterscheidung zwischen der *Standardaktion* und den *Regeln*. Jede Regel hat eine Richtung, ein Programm oder einen Port, ein Protokoll, Adressbereiche, Profile und eine Aktion. Der Auswertungsablauf ist: Blockregeln haben Vorrang vor Zulassungsregeln, und trifft keine Regel zu, gilt die Standardaktion. Wenn also die Standardaktion „Blockieren“ ist, wird jeder nicht erwartete Zugriff abgewiesen, und das Abschalten eines Dienstes ist nicht nötig, damit sein Port geschlossen bleibt.

Es empfiehlt sich, die eingehende Blockade *mit Regeln für die Verwaltung* zu kombinieren. Das typische Regelset für einen verwalteten Client besteht aus Remoteverwaltung (WinRM), Datei- und Druckerfreigabe nur aus dem Verwaltungsnetz, ICMP-Echo für Monitoring sowie Regeln für Fernwartung. Es gibt zwei Quellen: vorinstallierte Regelgruppen, die man aktiviert, und eigene Regeln, die man per Gruppenrichtlinie neu anlegt.

```ps
$store = "contoso.local\FW-Profile"
$session = Open-NetGPO -PolicyStore $store

# Standardaktion: eingehend blockieren, ausgehend zulassen (alle Profile)
Set-NetFirewallProfile -Profile Domain,Private,Public `
    -DefaultInboundAction Block -DefaultOutboundAction Allow `
    -GPOSession $session

# Beispielregel: WinRM nur aus dem Verwaltungsnetz erlauben
New-NetFirewallRule -DisplayName "Verwaltung WinRM (Mgmt-Netz)" `
    -Direction Inbound -Protocol TCP -LocalPort 5985,5986 `
    -RemoteAddress 10.10.0.0/24 -Action Allow -Profile Domain `
    -GPOSession $session

Save-NetGPO -GPOSession $session
```

Der erste Teil setzt für alle Profile die Standardaktionen. Die Regel `New-NetFirewallRule` legt eine Zulassungsregel für WinRM an, beschränkt auf das Verwaltungsnetz 10.10.0.0/24 (ein Beispielwert) und nur im Domänenprofil. Dass sie mit `-GPOSession` erzeugt wird, schreibt sie in die GPO. Ohne diesen Parameter würde sie lokal auf dem Verwaltungsrechner entstehen.

**Typische Fehler.** Falsch: die Standardaktion auf „Blockieren“ zu stellen und danach über die Verwaltung auszusperren. Richtig: zuerst Regeln definieren und testen. Zweiter Fehler: Regeln mit „Beliebiger Adresse“ anzulegen, weil es bequem ist; die Regel gilt dann für das ganze Internet. Richtig: immer eine Remoteadresse oder ein Netz angeben. Dritter Fehler: auch ausgehende Verbindungen standardmäßig zu blockieren, ohne den dafür nötigen Aufwand einzuplanen; das ist möglich, aber eine eigene Projektgröße.

> **Praxisbeispiel**
>
> Beispielszenario: Ein neuer Dienst startet auf einem Client und öffnet einen Port. Weil die Standardaktion blockiert, ist er von außen nicht erreichbar. Erst wenn die Fachabteilung ihn ausdrücklich beantragt, entsteht eine Regel mit klar definiertem Quellnetz.

## 35 Firewall Logging aktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows Defender Firewall mit erweiterter Sicherheit               |
| Einstellung     | Protokollierung                                                                             |
| Empfehlung      | Dropped packets und successful connections nach Bedarf                                      |
| Ziel / Zweck    | Verbessert Incident Analyse                                                                 |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Eine Firewall, die blockiert, aber nichts aufschreibt, taugt nicht für die Ursachenanalyse. Die Windows-Firewall kann in eine Textdatei protokollieren, standardmäßig `%systemroot%\system32\LogFiles\Firewall\pfirewall.log`. Pro Profil lassen sich getrennt festlegen, ob *verworfene Pakete* (dropped packets), *erfolgreiche Verbindungen* (successful connections) oder beides protokolliert werden, wie groß die Datei werden darf und wo sie liegt. Der Lehrplan formuliert „nach Bedarf“: Verworfene Pakete sind für die Fehlersuche und Angriffserkennung interessant, erfolgreiche Verbindungen erzeugen sehr große Datenmengen.

Die Größe ist ein praktisches Problem. Die Datei ist begrenzt (Standard 4 096 KB nach meiner Kenntnis), und bei Erreichen der Grenze wird sie überschrieben; für Analysen ist daher eine größere Datei, etwa 16 MB oder mehr, üblich. Das Verfahren ist reine Dateiprotokollierung, es entstehen keine Einträge im Windows-Ereignisprotokoll. Wer Firewall-Ereignisse im Eventlog haben will, nutzt die erweiterte Überwachung (Audit Filtering Platform, siehe Modul 09) und bezahlt mit einer deutlich höheren Ereignismenge.

> **Merke**
>
> Das Firewall-Protokoll ist eine Textdatei im W3C-Format mit Spalten wie Datum, Aktion (`DROP` oder `ALLOW`), Protokoll, Quell- und Ziel-IP, Ports und Richtung. Protokollierung erfolgt je Profil; wer im Domänenprofil nichts einstellt, hat dort kein Protokoll.

Das Beispiel richtet die Protokollierung für alle Profile ein und wertet danach die Datei am Client aus. Die Parameter von `Set-NetFirewallProfile` (`-LogBlocked`, `-LogAllowed`, `-LogFileName`, `-LogMaxSizeKilobytes`) sind in der Microsoft-Dokumentation beschrieben. Die Auswertung liest nur und ist unkritisch.

```ps
$store = "contoso.local\FW-Profile"
$session = Open-NetGPO -PolicyStore $store
Set-NetFirewallProfile -Profile Domain,Private,Public `
    -LogBlocked True -LogAllowed False `
    -LogFileName "%systemroot%\system32\LogFiles\Firewall\pfirewall.log" `
    -LogMaxSizeKilobytes 16384 -GPOSession $session
Save-NetGPO -GPOSession $session

# Auswertung am Client: die haeufigsten blockierten Zielports
Get-Content "$env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log" |
    Where-Object { $_ -match ' DROP ' } |
    ForEach-Object { ($_ -split ' ')[6] } |
    Group-Object | Sort-Object Count -Descending | Select-Object -First 10 Count, Name
```

Der erste Block protokolliert blockierte Verbindungen, aber nicht die erfolgreichen, und vergrößert die Datei auf 16 MB. Die Auswertung filtert Zeilen mit `DROP`, nimmt die siebte Spalte (Zielport, nach meiner Kenntnis des Logformats; vorher an einer Beispielzeile prüfen) und zählt, welche Ports am häufigsten angefragt wurden. Auffällige Ports deuten auf Scans oder fehlkonfigurierte Anwendungen hin.

**Typische Fehler.** Falsch: „successful connections“ dauerhaft auf allen Rechnern zu aktivieren; die Datei rotiert nach kurzer Zeit, und die Analyse ist unmöglich. Richtig: gezielt und befristet für Untersuchungen. Zweiter Fehler: das Protokoll nicht zentral zu sammeln; auf einem kompromittierten Rechner kann es gelöscht werden. Dritter Fehler: die Zugriffsrechte des Protokollordners nicht zu prüfen. Der Pfad enthält Systeminformationen; er sollte nur Administratoren und dem Firewalldienst zugänglich sein.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Server meldet wiederholte Verbindungsversuche von einem Client auf Port 445. Das Firewall-Protokoll des Clients belegt, dass dort ein Skript hunderte Freigaben abfragt. Der Fall wird als Fehlkonfiguration eingestuft und das Skript korrigiert.

## 36 NetBIOS Namensauflösung deaktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Netzwerk \> DNS-Client                  |
| Einstellung     | NetBIOS-Einstellungen konfigurieren                                                         |
| Empfehlung      | NetBIOS-Namensauflösung deaktivieren                                                        |
| Ziel / Zweck    | Reduziert Legacy-Protokollrisiken                                                           |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

*NetBIOS over TCP/IP* (NBT) ist ein Protokoll aus der Frühzeit von Windows-Netzen, mit dem Rechner sich per Broadcast im lokalen Netz finden: Ein Rechner ruft „Wer ist FILESERVER?“, und wer so heißt, antwortet. Das funktioniert ohne DNS, aber es hat einen gravierenden Nachteil: Jeder im Netz kann antworten. Ein Angreifer antwortet einfach „Das bin ich“, und der Client schickt ihm seine Anmeldedaten (als NTLM-Hash), die der Angreifer offline knacken oder weitergeben kann. Moderne Netze lösen Namen über DNS auf, NetBIOS ist praktisch überflüssig.

Die DNS-Client-Richtlinie „Configure NetBIOS settings“ (Einstellung `EnableNetbios`) steuert das Verhalten pro Netzwerkprofil. Es gibt vier Stufen: Verhalten aus der Adapterkonfiguration oder DHCP, NetBIOS überall aktivieren, NetBIOS auf öffentlichen Netzen deaktivieren, oder überall deaktivieren. Der Lehrplan verlangt die Deaktivierung; ob man „nur öffentlich“ oder „überall“ wählt, ist die Frage nach dem Risiko im Unternehmensnetz. Ältere Anwendungen und Geräte (alte NAS, Messgeräte, Scanner) arbeiten mitunter noch mit NetBIOS-Namen.

> **Ergänzung aus der Nachrecherche**
>
> Aus meiner Kenntnis (nicht aus den abgerufenen Seiten belegt): Die Einstellung steht im DNS-Client-Bereich der ADMX-Vorlage (`DnsClient.admx`) und existiert ab Windows 10 Version 1809 beziehungsweise Windows Server 2019. Der Registrywert `EnableNetbios` liegt unter `HKLM\Software\Policies\Microsoft\Windows NT\DNSClient`. Vor dem Rollout im Gruppenrichtlinien-Editor die genauen Optionen prüfen.

Das Beispiel setzt die Richtlinie und zeigt, wie man am Client prüft, wo NetBIOS noch aktiv ist. Der Wert 2 steht nach meiner Kenntnis für „NetBIOS-Namensauflösung deaktiviert“ (Wertetabelle im Pilot prüfen). Die Prüfung nutzt WMI und ändert nichts.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "NET-NetBIOS-aus"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" `
    -ValueName EnableNetbios -Type DWord -Value 2

# Am Client: Wo ist NetBIOS ueber TCP/IP noch aktiv?
# TcpipNetbiosOptions: 0 = DHCP/Standard, 1 = aktiv, 2 = deaktiviert
Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=TRUE" |
    Select-Object Description, TcpipNetbiosOptions

# Zusaetzlich im Netz suchen: antwortet noch jemand auf NBNS (UDP 137)?
Get-NetUDPEndpoint -LocalPort 137 -ErrorAction SilentlyContinue
```

Der Registrywert legt die Richtlinie fest. Die Abfrage von `Win32_NetworkAdapterConfiguration` zeigt pro Adapter die Einstellung `TcpipNetbiosOptions`. Das Ergebnis erlaubt ein Inventar: Welche Adapter fragen noch per NetBIOS? Der Port UDP 137 ist der NetBIOS-Namensdienst; ein offener Endpunkt zeigt, dass er noch läuft.

**Typische Fehler.** Falsch: NetBIOS zu deaktivieren, ohne vorher zu prüfen, ob Geräte oder Anwendungen NetBIOS-Namen verwenden. Die Folge sind unerklärliche Verbindungsfehler zu alten Freigaben. Richtig: vorab im Firewall- oder Netzwerkprotokoll prüfen, ob UDP 137 und 138 sowie TCP 139 im Betrieb genutzt werden. Zweiter Fehler: DNS nicht sauber zu pflegen; ohne vollständige DNS-Einträge (und DNS-Suffixlisten) fällt die Namensauflösung auf Broadcast-Verfahren zurück. Dritter Fehler: WINS-Server weiter zu betreiben, ohne sie aktiv zu überwachen.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Penetrationstest in der Firma gewinnt innerhalb von Minuten Hashes über gefälschte NetBIOS-Antworten. Nach Deaktivierung von NetBIOS und LLMNR (Abschnitt 37) liefert derselbe Test keine Anmeldedaten mehr.

## 37 LLMNR deaktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Netzwerk \> DNS-Client                  |
| Einstellung     | Multicastnamensauflösung deaktivieren                                                       |
| Empfehlung      | Aktiviert                                                                                   |
| Ziel / Zweck    | Reduziert Spoofing- und Credential-Risiken                                                  |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

*LLMNR* steht für *Link-Local Multicast Name Resolution*. Es ist ein zweites Verfahren, mit dem Windows Namen im lokalen Netz auflöst, wenn DNS keine Antwort liefert: Der Rechner schickt eine Multicast-Anfrage an alle Nachbarn und nimmt die erste Antwort. Genau wie bei NetBIOS kann ein Angreifer im Netz diese Anfrage beantworten und den Client auf einen eigenen Rechner umleiten (*Spoofing*). Dort wird ein Anmeldeversuch mitgeschnitten, und der Angreifer erhält einen NTLM-Hash.

Die Richtlinie heißt „Turn off multicast name resolution“ (deutsch: Multicastnamensauflösung deaktivieren). Wird sie auf „Aktiviert“ gestellt, ist LLMNR ausgeschaltet. Das ist wieder die Doppelverneinung, auf die man bei Lehrplänen achten muss: „Aktiviert“ bei einer Richtlinie, die etwas abschaltet. Laut Microsoft-Dokumentation gilt die Einstellung für Windows-Clients, und der Registrywert ist `EnableMulticast = 0` unter `HKLM\Software\Policies\Microsoft\Windows NT\DNSClient`. Eine Voraussetzung ist ein funktionierendes DNS: Wer LLMNR abschaltet und keine vollständigen DNS-Einträge hat, merkt es sofort an Namensauflösungsproblemen.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zum DNS-Client-Policy-CSP beschreibt die Einstellung `TurnOffMulticast`. Eine verwandte Einstellung steuert mDNS (Multicast DNS), das ebenfalls abgeschaltet werden kann; auch hier gelten die gleichen Überlegungen. In Netzen mit Druckern und Medienstreaming kann mDNS durchaus genutzt werden.

Das Beispiel setzt die Richtlinie per Registry-Wert und prüft per Netzwerkaufzeichnung am Client, ob noch LLMNR-Pakete (UDP 5355) entstehen. Der Wert ist in der Microsoft-Dokumentation für die Richtlinie dokumentiert; die Prüfung auf dem Client dient der Verifikation. Die Abfrage mit `Get-NetUDPEndpoint` zeigt, ob der Dienst auf Port 5355 lauscht.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "NET-LLMNR-aus"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" `
    -ValueName EnableMulticast -Type DWord -Value 0

# Am Client nach gpupdate: Wert pruefen
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name EnableMulticast

# Lauscht noch jemand auf UDP 5355 (LLMNR)?
Get-NetUDPEndpoint -LocalPort 5355 -ErrorAction SilentlyContinue
```

Der erste Block legt die GPO an und setzt `EnableMulticast` auf 0. Der zweite liest den Wert am Client, der dritte zeigt, ob LLMNR noch Verbindungen entgegennimmt. Nach erfolgreicher Anwendung sollte kein Endpunkt auf Port 5355 mehr gelistet sein.

**Typische Fehler.** Falsch: die Richtlinie anzuwenden, ohne zu klären, ob der DNS-Suffix korrekt verteilt ist; kurze Namen wie `fileserver` lassen sich dann nicht mehr auflösen. Richtig: eine DNS-Suffixsuchliste per Gruppenrichtlinie verteilen. Zweiter Fehler: nur LLMNR abzuschalten, aber NetBIOS (Abschnitt 36) zu belassen; Angreifer weichen dann auf NBNS aus. Dritter Fehler: die Doppelverneinung zu übersehen und die Richtlinie auf „Deaktiviert“ zu setzen, was LLMNR aktiv lässt.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Benutzer tippt einen Freigabenamen falsch. Früher sendete der Rechner die Anfrage per Multicast, ein Angreifer antwortete, und der Hash wurde abgefangen. Nach der Richtlinie scheitert die Anfrage einfach mit einer Fehlermeldung.

## 38 Unsichere Gastanmeldungen SMB blockieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Netzwerk \> Lanman-Arbeitsstation       |
| Einstellung     | Unsichere Gastanmeldungen aktivieren                                                        |
| Empfehlung      | Deaktiviert                                                                                 |
| Ziel / Zweck    | Verhindert unsichere SMB-Gastzugriffe                                                       |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

*SMB* (Server Message Block) ist das Protokoll hinter Windows-Dateifreigaben. Bei einer *Gastanmeldung* verbindet sich ein Client ohne Benutzername und Kennwort mit einer Freigabe. Das ist an sich noch nicht problematisch, aber *unsicher* wird es, wenn der Server dafür weder Signierung noch Verschlüsselung anbietet: Ein Angreifer im Netz kann den Datenverkehr verändern, und der Client merkt es nicht. Deshalb blockieren moderne Windows-Versionen solche Gastanmeldungen standardmäßig (mit Ausnahme bestimmter Editionen) und lehnen die Verbindung mit einer Fehlermeldung ab.

Die Richtlinie „Enable insecure guest logons“ im Bereich Lanman-Arbeitsstation steuert, ob der Client diese unsicheren Gastanmeldungen zulässt. Der Lehrplan empfiehlt „Deaktiviert“: Der Client lehnt sie ab. Sie ist damit keine Doppelverneinung, sondern verbietet, was ihr Name aktiviert. Die Einstellung betrifft den Client (die Arbeitsstation), nicht den Server. Ältere NAS-Geräte, einfache Medienserver oder Messgeräte erlauben häufig nur Gastzugriff ohne Signierung; mit dieser Richtlinie sind sie nicht mehr erreichbar. Das ist beabsichtigt, aber es erzeugt Rückfragen.

> **Ergänzung aus der Nachrecherche**
>
> Aus meiner Kenntnis (nicht abgerufen): Die zugehörige Registry-Einstellung heißt `AllowInsecureGuestAuth` unter `HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation`. In neueren Windows-Versionen kann man zusätzlich über SMB-Client-Einstellungen verlangen, dass Signierung oder Verschlüsselung genutzt werden. Details bitte in der Microsoft-Dokumentation zu SMB-Sicherheit nachlesen.

Das Beispiel stellt die Richtlinie auf „Deaktiviert“ und liest am Client die SMB-Konfiguration. `Get-SmbClientConfiguration` ist ein Standard-Cmdlet; der Registrywert stammt aus meiner Kenntnis. Mit dem Skript lässt sich zudem testen, welche Verbindungen ein Client aktuell aufgebaut hat.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "NET-SMB-Gast-aus"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" `
    -ValueName AllowInsecureGuestAuth -Type DWord -Value 0

# Am Client: aktuelle SMB-Konfiguration und bestehende Verbindungen
Get-SmbClientConfiguration | Select-Object EnableInsecureGuestLogons, RequireSecuritySignature
Get-SmbConnection | Select-Object ServerName, ShareName, Dialect, Signed, Encrypted
```

Der Registrywert 0 verbietet unsichere Gastanmeldungen. Die Konfigurationsabfrage zeigt, ob der Client sie derzeit zulässt und ob er Signierung verlangt. `Get-SmbConnection` listet bestehende Verbindungen mit Dialekt, Signierung und Verschlüsselung und eignet sich für das Inventar: Welche Server nutzen noch SMB 1 oder arbeiten ohne Signierung?

**Typische Fehler.** Falsch: die Richtlinie flächendeckend zu setzen, ohne die Liste der Gastfreigaben im Haus zu kennen. Richtig: vorab per Befehl oder Netzwerkprotokoll ermitteln, welche Geräte Gastzugriff verlangen, und sie auf authentifizierten Zugriff umstellen. Zweiter Fehler: die Lösung „Richtlinie wieder lockern“ dauerhaft zu belassen; richtig ist, die Geräte zu ersetzen oder zu konfigurieren. Dritter Fehler: Server und Client zu verwechseln; diese Richtlinie betrifft ausgehende Verbindungen des Clients.

> **Praxisbeispiel**
>
> Beispielszenario: Ein älterer Netzwerkspeicher in der Buchhaltung erlaubt nur Gastzugriff. Nach der Richtlinie können Mitarbeiter nicht mehr darauf zugreifen. Die IT stellt das Gerät auf Konten mit Kennwort um und aktiviert die SMB-Signierung; der Zugriff funktioniert wieder, und die Daten sind besser geschützt.

## 39 NTLM Nutzung auditieren

| **Feld**        | **Steckbrief**                                                                                                          |
|:----------------|:------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Windows-Einstellungen \> Sicherheitseinstellungen \> Lokale Richtlinien \> Sicherheitsoptionen |
| Einstellung     | Netzwerksicherheit: NTLM überwachen                                                                                     |
| Empfehlung      | Audit nach Einführungsplan                                                                                              |
| Ziel / Zweck    | Ermöglicht NTLM-Reduktionsprojekt                                                                                       |
| Zielbereich     | Computer                                                                                                                |
| Priorität       | 2                                                                                                                       |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                             |

*NTLM* (NT LAN Manager) ist das alte Anmeldeverfahren von Windows, das noch immer als Rückfall dient, wenn Kerberos nicht möglich ist, zum Beispiel beim Zugriff per IP-Adresse statt Name. Es hat bekannte Schwächen (Pass-the-Hash, Relay-Angriffe), und Microsoft rät, es zu verringern. Abschalten lässt es sich aber nicht einfach: Viele Anwendungen verwenden NTLM, ohne dass jemand es weiß. Wer es einfach blockiert, bricht Anmeldungen. Deshalb gehört vor jede Blockade ein *Audit*: Man protokolliert, wer NTLM wo nutzt, und plant damit die Abschaltung.

Die Auditierung ist über die Sicherheitsoptionen im Bereich „Netzwerksicherheit: NTLM einschränken“ konfigurierbar. Dort stehen drei Einstellungen: für ausgehenden NTLM-Verkehr zu Remoteservern („Outgoing NTLM traffic to remote servers“), für eingehenden Verkehr („Incoming NTLM traffic“) und auf Domänencontrollern für die Authentifizierung in der Domäne. Für das Audit wählt man jeweils „Alle überwachen“ beziehungsweise „Audit all“. Die Ereignisse landen im Protokoll „Anwendungs- und Dienstprotokolle \> Microsoft \> Windows \> NTLM \> Operational“. Erst wenn die Auswertung zeigt, dass ein Verfahren nirgends mehr genutzt wird, beschränkt man es.

> **Merke**
>
> Audit zuerst, Blockade später: Die Reihenfolge ist *überwachen*, *auswerten*, *Ausnahmen dokumentieren und Anwendungen umstellen*, *blockieren*. Zwischen Audit und Blockade liegen je nach Umgebung Wochen oder Monate.

Das Beispiel setzt die Audit-Einstellung für ausgehenden Verkehr und liest die Ereignisse am Client. Die Registrywerte (`AuditNTLMInDomain`, `RestrictSendingNTLMTraffic` unter `MSV1_0`) stammen aus meiner Kenntnis; für `RestrictSendingNTLMTraffic` bedeutet 1 nach meiner Kenntnis „Alle überwachen“, 2 „Alle blockieren“. Das ist vor dem Einsatz an der Wertetabelle im Gruppenrichtlinien-Editor zu prüfen. Das Skript blockiert nichts.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "SEC-NTLM-Audit"
# Ausgehenden NTLM-Verkehr nur ueberwachen (1 = Alle ueberwachen)
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" `
    -ValueName RestrictSendingNTLMTraffic -Type DWord -Value 1

# Am Client: wer nutzt NTLM? (Ereignis 8001 = ausgehender NTLM-Verkehr)
Get-WinEvent -LogName 'Microsoft-Windows-NTLM/Operational' -MaxEvents 200 -ErrorAction SilentlyContinue |
    Where-Object Id -eq 8001 |
    Group-Object { $_.Properties[1].Value } |
    Sort-Object Count -Descending | Select-Object -First 10 Count, Name
```

Der erste Block aktiviert die Überwachung für ausgehenden NTLM-Verkehr. Die Auswertung liest das NTLM-Protokoll, filtert auf Ereignis 8001 (nach meiner Kenntnis „NTLM client blocked audit“, die genaue Zuordnung der Ereignis-IDs und Eigenschaften ist im Pilot am Beispielereignis zu prüfen) und gruppiert nach Zielserver. So sieht man, welche Server noch per NTLM angesprochen werden.

**Typische Fehler.** Falsch: NTLM sofort zu blockieren, ohne das Audit ausgewertet zu haben. Typisch sind Zugriffe per IP-Adresse, ältere Anwendungen und Dienste mit Dienstkonten ohne Service Principal Name (SPN). Richtig: erst SPNs und Namensauflösung bereinigen, dann blockieren. Zweiter Fehler: das Audit nur auf Clients einzurichten und nicht auf Servern und Domänencontrollern; erst dort sieht man, wer eingehend NTLM sendet. Dritter Fehler: das Protokoll nicht zentral zu sammeln; auf einzelnen Rechnern ist die Datenmenge nicht auswertbar.

> **Praxisbeispiel**
>
> Beispielszenario: Nach drei Monaten Audit zeigt die Auswertung, dass nur noch zwei Fachanwendungen NTLM brauchen. Beide werden auf Kerberos umgestellt oder per Ausnahmeliste zugelassen; danach wird NTLM schrittweise eingeschränkt.

## 40 Remote Desktop nur mit NLA

| **Feld**        | **Steckbrief**                                                                                                                             |
|:----------------|:-------------------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Remotedesktopdienste \> Remotedesktopsitzungshost \> Sicherheit |
| Einstellung     | Benutzerauthentifizierung mit NLA erforderlich                                                                                             |
| Empfehlung      | Aktiviert                                                                                                                                  |
| Ziel / Zweck    | Reduziert RDP-Angriffsrisiken                                                                                                              |
| Zielbereich     | Computer                                                                                                                                   |
| Priorität       | 1                                                                                                                                          |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                                |

*RDP* (Remote Desktop Protocol) ist der Standardweg, einen Windows-Rechner aus der Ferne zu bedienen. *NLA* (Network Level Authentication) ändert die Reihenfolge: Der Benutzer muss sich authentifizieren, *bevor* die Sitzung aufgebaut wird. Ohne NLA erzeugt der Server zuerst eine Sitzung mit Anmeldebildschirm und verbraucht Ressourcen für jeden, der anklopft; Angreifer nutzen das für Brute-Force-Angriffe und Ressourcenerschöpfung. Mit NLA verwendet der Client das Sicherheitsprotokoll CredSSP und liefert die Zugangsdaten schon vorab. Laut der Microsoft-Dokumentation ist die Anmeldung dann ohne Bildschirm nicht möglich.

Die Gruppenrichtlinie „Require user authentication for remote connections by using Network Level Authentication“ (Benutzerauthentifizierung mit NLA für Remoteverbindungen erforderlich) setzt den Wert `UserAuthentication = 1` im Schlüssel `HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services`. Wichtig: NLA ersetzt keine Netzabsicherung. RDP sollte nie direkt am Internet hängen; Zugriff gehört hinter VPN oder ein Gateway, und die Firewall (Abschnitt 34) erlaubt Port 3389 nur aus definierten Netzen. NLA ist ein Baustein, kein Gesamtkonzept.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zur Kontosperrung weist darauf hin, dass Remotedesktop-Zugriffe von Brute-Force-Angriffen betroffen sind und die Kontosperrschwelle (Abschnitt 1) eine Schutzschicht ist. Zusammen mit NLA, einer Firewallregel mit eingeschränkter Quelladresse und Mehrfaktor-Authentifizierung am Gateway entsteht ein mehrschichtiger Schutz.

Das Beispiel setzt NLA per Gruppenrichtlinie und prüft den Zustand mit dem CIM-Objekt der Remotedesktop-Einstellungen. Der Registrywert ist standardisiert und seit Langem dokumentiert; die Abfrage von `Win32_TSGeneralSetting` liefert die Eigenschaft `UserAuthenticationRequired`. Die Firewall-Regel beschränkt RDP auf das Verwaltungsnetz (Beispieladresse).

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "RDP-NLA"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
    -ValueName UserAuthentication -Type DWord -Value 1

# RDP nur aus dem Verwaltungsnetz (in dieselbe GPO schreiben)
$session = Open-NetGPO -PolicyStore "contoso.local\RDP-NLA"
New-NetFirewallRule -DisplayName "RDP nur Mgmt-Netz" -Direction Inbound `
    -Protocol TCP -LocalPort 3389 -RemoteAddress 10.10.0.0/24 `
    -Action Allow -Profile Domain -GPOSession $session
Save-NetGPO -GPOSession $session

# Am Client: wird NLA verlangt?
Get-CimInstance -Namespace root\cimv2\TerminalServices -ClassName Win32_TSGeneralSetting |
    Select-Object TerminalName, UserAuthenticationRequired
```

Der Registrywert 1 verlangt NLA. Die Firewallregel lässt RDP nur aus dem Verwaltungsnetz zu; sie gehört in dieselbe GPO wie die Einstellung, damit beides gemeinsam angewendet wird. Die CIM-Abfrage zeigt den Zustand am Client, wobei `UserAuthenticationRequired` den Wert 1 haben sollte.

**Typische Fehler.** Falsch: NLA zu erzwingen und danach festzustellen, dass alte RDP-Clients (zum Beispiel Thin Clients oder Linux-Clients mit alter Version) keine Verbindung mehr aufbauen. Richtig: Clients im Pilot testen oder austauschen. Zweiter Fehler: Rechner, die nicht in der Domäne sind, per RDP mit NLA erreichen zu wollen; hier sind Anmeldeinformationen und Vertrauensstellung nötig. Dritter Fehler: RDP zu aktivieren und den Port im Internet freizugeben, in der Annahme, NLA genüge; das Internet-Scanning nach offenen RDP-Ports ist Alltag.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Dienstleister braucht Zugriff auf einen Server. Statt eine RDP-Portfreigabe einzurichten, bekommt er VPN-Zugang und darf RDP nur zu diesem einen Server aufbauen. NLA verhindert, dass Anonyme überhaupt einen Anmeldebildschirm sehen.

## Übungsaufgaben zu Modul 04

**Aufgabe 1.** **(leicht)** Nennen Sie die drei Firewallprofile und erklären Sie, wann Windows welches wählt.

**Aufgabe 2.** **(leicht)** Warum ist „Aktiviert“ bei der Richtlinie „Multicastnamensauflösung deaktivieren“ die richtige Einstellung, um LLMNR abzuschalten?

**Aufgabe 3.** **(leicht)** Was ist der Unterschied zwischen der Standardaktion und einer Firewallregel? Was gewinnt bei einem Konflikt zwischen Blockier- und Zulassungsregel?

**Aufgabe 4.** **(mittel)** Beschreiben Sie, wie ein Angreifer ohne Schwachstelle im Betriebssystem über LLMNR oder NetBIOS an einen Hash gelangt, und welche Richtlinien das verhindern.

**Aufgabe 5.** **(mittel)** Warum auditiert man NTLM zuerst, bevor man es einschränkt? Beschreiben Sie vier Schritte eines NTLM-Reduktionsprojekts.

**Aufgabe 6.** **(praktisch)** Schreiben Sie ein Skript, das eine GPO mit Standardaktion „eingehend blockieren“, Firewall-Protokollierung blockierter Pakete (16 MB) und einer Regel für WinRM aus dem Netz 192.168.10.0/24 erstellt.

**Aufgabe 7.** **(praktisch)** Schreiben Sie ein Skript, das auf einem Client prüft, ob alle drei Firewallprofile aktiv sind, LLMNR deaktiviert ist und NLA verlangt wird, und das Ergebnis als Objekt ausgibt.

**Aufgabe 8.** **(schwer)** Planen Sie die Einführung einer restriktiven Firewall (eingehend blockiert, lokale Regeln aus) für 1 500 Clients: Regelinventur, Pilot, Fehlersuche per Protokoll, Rückfallplan.

## Lösungen zu Modul 04

**Lösung 1.** Domäne (Rechner erreicht einen Domänencontroller seiner Domäne), privat (Netz ausdrücklich als privat markiert), öffentlich (alle anderen Netze, Standard). Pro Verbindung gilt ein Profil.

**Lösung 2.** Die Richtlinie heißt „Multicastnamensauflösung *deaktivieren*“. Setzt man sie auf „Aktiviert“, ist die Maßnahme (Abschalten) aktiv, LLMNR läuft also nicht mehr. Der Registrywert `EnableMulticast` ist dabei 0.

**Lösung 3.** Die Standardaktion gilt, wenn keine Regel zutrifft. Regeln legen Ausnahmen fest. Blockierregeln haben Vorrang vor Zulassungsregeln.

**Lösung 4.** Der Client fragt per Broadcast oder Multicast nach einem Namen, den DNS nicht kennt. Der Angreifer antwortet als Erster; der Client authentifiziert sich beim Angreifer, der den NTLM-Hash erhält. Verhindert wird das durch Abschalten von LLMNR (37) und NetBIOS (36) sowie saubere DNS-Einträge.

**Lösung 5.** Weil NTLM oft unbemerkt genutzt wird. Schritte: Audit einschalten und zentral sammeln; Quellen und Ziele auswerten; SPNs, Namensauflösung und Anwendungen korrigieren; Ausnahmeliste führen, dann schrittweise einschränken und überwachen.

**Lösung 6.** Beispiel: `New-GPO`, `Open-NetGPO`, `Set-NetFirewallProfile -Profile Domain,Private,Public -DefaultInboundAction Block -LogBlocked True -LogMaxSizeKilobytes 16384`, `New-NetFirewallRule -Direction Inbound -Protocol TCP -LocalPort 5985,5986 -RemoteAddress 192.168.10.0/24 -Action Allow`, `Save-NetGPO`, jeweils mit `-GPOSession`.

```ps
# Loesung 7
$fw  = Get-NetFirewallProfile | Where-Object Enabled -ne True
$llm = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" `
        -Name EnableMulticast -ErrorAction SilentlyContinue).EnableMulticast
$nla = (Get-CimInstance -Namespace root\cimv2\TerminalServices `
        -ClassName Win32_TSGeneralSetting).UserAuthenticationRequired
[pscustomobject]@{
  Computer       = $env:COMPUTERNAME
  FirewallAlleAn = ($fw.Count -eq 0)
  LLMNRAus       = ($llm -eq 0)
  NLA            = ($nla -eq 1)
}
```

**Lösung 7.** Die Lösung steht oben (Aufgabe 7). Wichtig ist, dass jede Prüfung den Fall „nicht konfiguriert“ abfängt (`-ErrorAction SilentlyContinue`), sonst bricht das Skript ab.

**Lösung 8.** Beispiel: (1) Inventur der Regelgruppen, die Anwendungen brauchen, per Protokollierung im Audit-Modus (erlaubte Verbindungen protokollieren) in einer Pilot-OU; (2) Regeln zentral als GPO bereitstellen; (3) Pilot mit zwei Hardware- und zwei Softwareprofilen, dann Fachabteilungen; (4) Fehlersuche über `pfirewall.log` (Quelle, Ziel, Port) und `Get-NetFirewallRule -PolicyStore ActiveStore`; (5) Rückfall: GPO-Verknüpfung deaktivieren, lokale Regeln wieder zulassen; (6) Kommunikation an den Helpdesk.
