# Modul 12 - Hybrid Identity, Migration und Governance

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Tabellen als Markdown-Tabellen, Übungsaufgaben und Lösungen als Absätze). Die Überschriften sind wie in der Quelle nach Modul und Lerneinheit nummeriert (12.1 bis 12.9; 12.10 Übungsaufgaben, 12.11 Lösungen). **Die PowerShell-Beispiele wurden für dieses Repository nicht ausgeführt**; sie setzen eine Windows-Server-Laborumgebung mit der fiktiven Domain `corp.contoso.com` voraus und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain. Übersicht zum Modul: [README](README.md).

|                                       |              |
|:--------------------------------------|:-------------|
| Dauer laut Modulübersicht             | 10 Stunden   |
| Summe der Lerneinheiten (Detailblatt) | 10,5 Stunden |
| Priorität                             | 2            |

|  Nr. | Lerneinheit                  | Dauer (h) | Prio |
|-----:|:-----------------------------|----------:|-----:|
| 12.1 | Hybrid Identity              |         1 |    2 |
| 12.2 | Microsoft Entra Connect      |         1 |    2 |
| 12.3 | Password Hash Sync           |       1,5 |    2 |
| 12.4 | Pass-through Authentication  |         1 |    2 |
| 12.5 | Hybrid Join                  |         1 |    2 |
| 12.6 | Cloud Sync                   |       1,5 |    2 |
| 12.7 | Migration und Konsolidierung |         1 |    3 |
| 12.8 | Governance                   |         1 |    3 |
| 12.9 | Betriebsroadmap              |       1,5 |    3 |
|      | **Summe**                    |  **10,5** |      |

> **Merke**
>
> Die Stundensumme der Lerneinheiten im Detailblatt (10,5 h) weicht von der Dauer in der Modulübersicht (10 h) ab. Dieses Skript behandelt alle Lerneinheiten des Detailblatts vollständig; die Abweichung ist im Lehrplan selbst zu klären.

Bis hierher stand das lokale Active Directory im Mittelpunkt: Domänen, Replikation, Gruppenrichtlinien, Sicherheit, Wiederherstellung und Betrieb. In den meisten Unternehmen endet die Identitätswelt aber nicht mehr am Rand des Rechenzentrums. E-Mail liegt in Exchange Online, Dokumente in SharePoint und OneDrive, Zusammenarbeit in Teams, und dazu kommen hunderte weiterer Cloud-Anwendungen, die sich über *Microsoft Entra ID* anmelden. Dieses Modul zeigt, wie das lokale Active Directory mit dieser Cloud-Identität verbunden wird, welche Sicherheitsfragen dabei entstehen und wie man die gesamte Umgebung über Jahre ordentlich betreibt: von der Synchronisierung über die Anmeldeverfahren und die Geräteanbindung bis zu Migrationen, Governance und einer Betriebsroadmap.

Die Sicherheitsgrundlagen (Modul 9), Sicherung und Wiederherstellung (Modul 10) sowie Überwachung und Fehlersuche (Modul 11) werden vorausgesetzt. Kerberos und NTLM (Modul 8) sind wichtig, weil Hybrid Identity genau an dieser Stelle neue Wege der Anmeldung eröffnet. Als Laborumgebung dient weiterhin `corp.contoso.com` mit `DC01` (10.10.0.11) und `DC02` (10.10.0.12). Für dieses Modul kommt ein zusätzlicher Mitgliedsserver `SRV02` hinzu, der die Synchronisierungssoftware trägt, sowie ein fiktiver Entra-Mandant mit der verifizierten Domäne `contoso.com`. Alle Beispiele zur Cloud sind so gehalten, dass man sie in einem Testmandanten nachvollziehen kann; Änderungen an einem echten Produktivmandanten gehören immer zuerst in eine Pilotgruppe.

## 12.1 Hybrid Identity

Unter *Identität* versteht man in der IT die Gesamtheit der Daten, mit denen sich eine Person oder ein Dienst gegenüber Systemen ausweist und mit denen Systeme entscheiden, was diese Person darf: Name, Anmeldename, Kennwort oder anderes Anmeldeverfahren, Gruppenzugehörigkeiten und weitere Attribute. Im lokalen Active Directory liegt diese Identität in der Datenbank der Domänencontroller. *Microsoft Entra ID* (bis 2023 unter dem Namen Azure Active Directory bekannt) ist der Verzeichnisdienst der Microsoft-Cloud. Er speichert Benutzer, Gruppen, Geräte und Anwendungsregistrierungen eines *Mandanten* (englisch Tenant), also der abgegrenzten Instanz, die einer Organisation gehört. Anders als das lokale AD spricht Entra ID nicht Kerberos und LDAP, sondern webbasierte Protokolle wie OpenID Connect, OAuth 2.0 und SAML. Beide Welten sind technisch verschieden, sollen aber für die Anwenderin als *eine* Identität wirken: ein Benutzername, ein Kennwort, einmal anmelden und überall hineinkommen.

Genau das meint der Begriff *Hybrid Identity*. Nach der Definition von Microsoft entsteht sie durch Bereitstellung (Provisioning) und Synchronisierung: Objekte werden unter bestimmten Bedingungen in der Cloud angelegt, aktuell gehalten und wieder gelöscht, sobald die Bedingungen nicht mehr gelten. Das lokale Active Directory bleibt dabei in der Regel die führende Quelle, die *Source of Authority*. Benutzer werden weiterhin im AD angelegt, deaktiviert und gelöscht; die Cloud erhält eine Kopie der relevanten Attribute. Daneben muss entschieden werden, wie die Anmeldung gegenüber der Cloud geprüft wird. Dafür gibt es drei Verfahren, die in den folgenden Abschnitten im Detail erscheinen: die Synchronisierung des Kennwort-Hashs (Password Hash Sync, Abschnitt 12.3), die Durchreichung an einen lokalen Agenten (Pass-through Authentication, Abschnitt 12.4) und die Föderation mit einem lokalen Identitätsanbieter wie AD FS. Dazu kommt die Frage, wie die Arbeitsplätze selbst im Mandanten bekannt gemacht werden (Hybrid Join, Abschnitt 12.5).

Wozu der Aufwand? Ohne Hybrid Identity müsste man jedes Konto zweimal pflegen, und Anwender müssten sich zwei Kennwörter merken. Mit Hybrid Identity gilt eine Kennwortrichtlinie, ein Eintritts- und Austrittsprozess, und Cloud-Funktionen wie mehrstufige Anmeldung, bedingter Zugriff und Anmeldeanalysen stehen auch für die lokalen Konten bereit. Der Preis ist eine neue Angriffsfläche: Wer das lokale AD übernimmt, kann sich über die Synchronisierung auch in der Cloud festsetzen, und wer die Synchronisierungsserver übernimmt, kann im Extremfall Identitäten in beiden Welten verändern. Die Dokumentation von Microsoft verlangt deshalb ausdrücklich, die Server der Synchronisierung als Tier-0-Systeme zu behandeln, also auf derselben Schutzstufe wie die Domänencontroller (siehe Tiering in Modul 9). Auch die Sicherheitsgrenze muss bewusst gezogen werden: Hoch privilegierte lokale Konten gehören nicht in die Cloud-Synchronisierung, und Cloud-Administratoren sollten reine Cloud-Konten sein, die nicht aus dem lokalen AD abgeleitet werden.

Bevor irgendetwas synchronisiert wird, muss das lokale Verzeichnis geeignet sein. Das wichtigste Thema ist der *Benutzerprinzipalname* (UPN). Er hat die Form `anna.beispiel@contoso.com` und ist der Anmeldename in der Cloud. Im Labor heißt die Domäne `corp.contoso.com`; die Standard-UPN von Anna wäre also `anna.beispiel@corp.contoso.com`. Dieser Name ist im Internet nicht bei einer Registrierungsstelle verifiziert, und Microsoft 365 würde dafür keine Anmeldung zulassen. Man fügt deshalb dem Forest ein zusätzliches UPN-Suffix hinzu, das mit der verifizierten Domäne übereinstimmt, und stellt die Benutzer darauf um. Das folgende Skript führt zuerst eine rein lesende Prüfung durch und ändert anschließend zur Probe (mit `-WhatIf`) die UPNs der Benutzer in der Organisationseinheit `Contoso`.

```powershell
# Bereitschaftspruefung fuer Hybrid Identity (zuerst nur lesend)
Import-Module ActiveDirectory
$ou = "OU=Contoso,DC=corp,DC=contoso,DC=com"
$oeffentlich = "contoso.com"

# 1. Welche UPN-Suffixe kennt der Forest?
(Get-ADForest).UPNSuffixes

# 2. Welche Benutzer haben kein oeffentlich verifiziertes Suffix?
Get-ADUser -Filter * -SearchBase $ou -Properties UserPrincipalName |
    Where-Object { $_.UserPrincipalName -notlike "*@$oeffentlich" } |
    Select-Object SamAccountName, UserPrincipalName

# 3. Gibt es doppelte UPNs? (muessen eindeutig sein)
Get-ADUser -Filter * -Properties UserPrincipalName |
    Group-Object UserPrincipalName |
    Where-Object Count -gt 1

# 4. Suffix hinzufuegen und Umstellung zur Probe ausfuehren
Set-ADForest -Identity corp.contoso.com -UPNSuffixes @{Add = $oeffentlich}
Get-ADUser -Filter * -SearchBase $ou | ForEach-Object {
    Set-ADUser $_ -UserPrincipalName ($_.SamAccountName + "@" + $oeffentlich) -WhatIf
}
```

Der Block beginnt mit zwei Variablen für die Suchbasis und das öffentliche Suffix. Schritt 1 gibt die im Forest registrierten alternativen Suffixe aus; ist die Liste leer, existiert nur das Standardsuffix. Schritt 2 sucht alle Benutzer, deren UPN nicht auf das öffentliche Suffix endet; diese Konten würden sich in der Cloud mit einem nicht verifizierbaren Namen anmelden und blieben deshalb ungenutzt oder landen im Standarddomänennamen `onmicrosoft.com`. Schritt 3 gruppiert nach UPN und zeigt nur Namen, die mehrfach vorkommen; solche Doppelungen führen bei der Synchronisierung zu Fehlern. In Schritt 4 fügt `Set-ADForest` das Suffix hinzu, die Schleife zeigt dank `-WhatIf` lediglich an, was geändert würde. Erst wenn die Ausgabe plausibel ist, lässt man `-WhatIf` weg. Beachten Sie, dass die Umstellung der UPN den Anmeldenamen der Anwender ändert und deshalb angekündigt werden muss.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist der Versuch, mit einer *nicht routingfähigen* Domäne wie `corp.local` in die Cloud zu gehen. Für solche Domänen lässt sich keine Domäne in Entra ID verifizieren. Ebenso verbreitet ist die Annahme, die Synchronisierung könne fehlerhafte Daten reparieren: Sie überträgt, was im AD steht, auch Leerzeichen, doppelte Werte und ungültige Zeichen in den Attributen `proxyAddresses`, `mail` und `userPrincipalName`. Die Bereinigung gehört vor die Einführung, nicht danach. Das Beispiel zeigt die Gegenüberstellung:

```powershell
# FALSCH: UPN-Suffix nicht oeffentlich, Konten erscheinen nicht nutzbar
anna.beispiel@corp.local
anna.beispiel@corp.contoso.com   # Domain ist nicht verifiziert

# RICHTIG: Suffix entspricht der verifizierten Domaene des Mandanten
anna.beispiel@contoso.com
```

Die Gegenüberstellung macht deutlich, dass es nicht auf die lokale Domänenstruktur ankommt, sondern ausschließlich auf eine Domäne, die dem Unternehmen gehört und in Entra ID bestätigt wurde. Die interne AD-Domäne `corp.contoso.com` kann bestehen bleiben; nur der Anmeldename wird umgestellt.

> **Ergänzung aus der Nachrecherche**
>
> Die Definition von Hybrid Identity über Provisioning und Synchronisierung, die drei Anmeldeverfahren und die Einordnung der Synchronisierungsserver als Tier-0-Systeme stützen sich auf die abgerufenen Seiten „What is hybrid identity with Microsoft Entra ID?“, „What is Microsoft Entra Connect?“ und „Security operations for infrastructure“ (Microsoft Learn, Suchauszüge). Das Entfernen privilegierter Konten aus der Synchronisierung und die Trennung der Cloud-Administratoren stammen aus der allgemeinen Fachpraxis. Der Begriff Microsoft Entra ID ersetzt den früheren Namen Azure Active Directory; ältere Dokumentation und Skripte verwenden noch den alten Namen. *Datenschutz (keine Rechtsberatung):* Mit der Synchronisierung gelangen personenbezogene Daten (Name, E-Mail-Adresse, Abteilung und weitere Attribute) in einen Cloud-Dienst. Welche Attribute übertragen werden, auf welcher Rechtsgrundlage und mit welchem Speicherort, gehört vor der Einführung geprüft und dokumentiert, zum Beispiel im Verzeichnis der Verarbeitungstätigkeiten. Die abgerufene Seite zur bevorzugten Datenposition („preferred data location“) zeigt, dass der Speicherort für Microsoft-365-Dienste pro Benutzer über ein Attribut gesteuert werden kann. Die rechtliche Bewertung ist Sache der Datenschutzbeauftragten bzw. einer Rechtsberatung.

### Praxisbezug

> **Praxisbeispiel**
>
> Fast jedes Projekt zur Einführung von Microsoft 365 beginnt mit genau dieser Bestandsaufnahme: Wie sehen die UPNs aus, welche Konten sind veraltet, welche Gruppen sollen in die Cloud, und wer verantwortet die Synchronisierungsserver? Wer die Bereinigung vorab durchführt, spart sich Wochen an Fehlersuche im Importprotokoll. In der Praxis legt man außerdem schriftlich fest, welche Quelle für welches Attribut maßgeblich ist, damit nicht später zwei Teams widersprüchliche Werte pflegen.

## 12.2 Microsoft Entra Connect

*Microsoft Entra Connect* (früher Azure AD Connect) ist die klassische Anwendung, die ein lokales Active Directory mit Entra ID verbindet. Sie wird auf einem Windows-Server im Netzwerk installiert und enthält mehrere Funktionen: die Synchronisierungs-Engine, die Konfiguration der Anmeldeverfahren (Password Hash Sync, Pass-through Authentication, Föderation) und einen Agenten für die Überwachung (Connect Health). Die Version 1 des Produkts ist seit dem 31. August 2022 außer Betrieb gesetzt; heute zählen nur noch Versionen der Reihe 2. Ältere Installationen funktionieren nicht mehr zuverlässig und müssen aktualisiert werden.

Zum Verständnis der Synchronisierungs-Engine helfen einige Begriffe. Ein *Connector* verbindet die Engine mit einem Verzeichnis, also je einer mit dem lokalen AD und einer mit Entra ID. Jeder Connector hat einen *Connector Space*, eine lokale Zwischenablage mit den importierten Objekten. Das *Metaverse* ist die vereinte Sicht: Objekte aus den Connector Spaces werden anhand eines gemeinsamen Schlüssels zu einem Metaverse-Objekt zusammengeführt (Join). Dieser Schlüssel heißt *Source Anchor* und muss pro Objekt unveränderlich sein; moderne Installationen verwenden dafür das Attribut `mS-DS-ConsistencyGuid`, das beim ersten Lauf aus der `objectGUID` befüllt wird. Aus dem Metaverse werden die Daten über *Synchronisierungsregeln* an den jeweils anderen Connector weitergegeben. Ein vollständiger Durchlauf besteht aus drei Schritten: Import (Daten aus dem Verzeichnis in den Connector Space lesen), Synchronisierung (Regeln anwenden, Metaverse aktualisieren) und Export (Änderungen in das Zielverzeichnis schreiben). Die Engine ist eine Zwischenstation ohne eigene Wahrheit; ihre Datenbank lässt sich aus AD und Entra ID jederzeit neu aufbauen, solange die Source Anchor stimmt.

Der Planer des Durchlaufs ist der *Scheduler*. Er startet standardmäßig alle 30 Minuten einen Delta-Zyklus, der nur Änderungen seit dem letzten Lauf verarbeitet. Ein *Initial*-Zyklus macht vollständigen Import und vollständige Synchronisierung und ist nötig, wenn Regeln oder Filter geändert wurden. Welche Schritte nach einer Änderung nötig sind, richtet sich nach der Art der Änderung: Ändert man Domänen- oder OU-Filter, braucht man einen vollständigen Import, gefolgt von einer Delta-Synchronisierung; ändert man Attributfilter oder Regeln, genügt eine vollständige Synchronisierung. Im Zweifel führt man einen Initial-Zyklus aus, am besten auf einem Server im Staging Mode.

Der Umfang der Synchronisierung wird durch *Filterung* festgelegt. Die Standardkonfiguration übernimmt Objekte aller Domänen des Forests, was meist empfohlen wird, damit die globale Adressliste vollständig ist. Möchte man den Umfang einschränken, stehen vier Filterarten zur Verfügung: nach Domäne, nach Organisationseinheit, nach Attributwert und (nur bei der Installation) nach einer einzelnen Gruppe. Mehrere Filter werden mit logischem UND verknüpft. Domänen- und OU-Filter sind die bevorzugten Mittel, weil sie die Last am stärksten senken; die Dokumentation zur Leistung nennt die Größe des importierten Verzeichnisses als wichtigsten Einflussfaktor. Konten mit gesetztem Attribut `isCriticalSystemObject`, etwa der eingebaute Administrator und die Gruppen „Domain Admins“ und „Enterprise Admins“, werden standardmäßig nicht synchronisiert; Benutzer, die man in solche Gruppen aufnimmt, aber sehr wohl.

Im Labor wird die Struktur genutzt, die in den früheren Modulen angelegt wurde: Synchronisiert wird die Organisationseinheit `Contoso` mit ihren Unter-OUs Benutzer, Computer und Gruppen, nicht aber die OU `Dienstkonten`. Die Dienstkonten sind lokale technische Konten, die in der Cloud nichts verloren haben. Zum Testen und Dokumentieren der Konfiguration dient das PowerShell-Modul `ADSync`, das mit der Anwendung installiert wird.

```powershell
# Zustand der Synchronisierung auf SRV02 pruefen
Import-Module ADSync
Get-ADSyncScheduler |
    Select-Object SyncCycleEnabled, StagingModeEnabled,
                  CurrentlyEffectiveSyncCycleInterval,
                  NextSyncCycleStartTimeInUTC

# Schutz vor versehentlichen Massenloeschungen
Get-ADSyncExportDeletionThreshold

# Aenderung vorbereiten: Scheduler anhalten und warten, bis nichts laeuft
Set-ADSyncScheduler -SyncCycleEnabled $false
# ... Filter oder Regeln aendern ...

# Nach der Aenderung: alles neu einlesen, auf dem Staging-Server pruefen
Start-ADSyncSyncCycle -PolicyType Initial

# Betrieb wieder aufnehmen
Set-ADSyncScheduler -SyncCycleEnabled $true
Start-ADSyncSyncCycle -PolicyType Delta
```

Der erste Befehl zeigt die wichtigsten Eigenschaften des Schedulers: ob er läuft, ob der Server im Staging Mode ist, welches Intervall tatsächlich gilt und wann der nächste Zyklus startet. `Get-ADSyncExportDeletionThreshold` liefert den Schwellwert der Löschsperre: Standardmäßig bricht der Export ab, wenn mehr als 500 Löschungen auf einmal anstehen. Diese Sperre schützt vor den typischen Unfällen, bei denen eine ganze OU aus dem Filter fällt, verschoben oder umbenannt wird. Wer Änderungen vorbereitet, hält den Scheduler an, damit nicht zwischendurch ein halb fertiger Zustand exportiert wird. Der Initial-Zyklus liest und verarbeitet alles neu, und erst danach schaltet man den Scheduler wieder ein und startet einen Delta-Lauf.

Ein besonders wichtiges Werkzeug ist der *Staging Mode*. Ein Server im Staging Mode importiert und synchronisiert, exportiert aber nichts. Damit gibt es zwei Verwendungen: Als Ersatzserver steht er bereit und übernimmt im Notfall in Minuten statt Stunden; als Testserver erlaubt er, Konfigurationsänderungen mit echten Daten zu prüfen, ohne dass die Cloud verändert wird. Die Prüfung der anstehenden Exporte erfolgt mit den Programmen `csexport` und `CSExportAnalyzer` aus dem Programmverzeichnis; sie erzeugen eine Datei `export.csv`, in der jede geplante Änderung als Zeile mit Objekttyp (Add, Update, Delete) steht. Es gilt: Es darf immer nur *ein* Server aktiv exportieren; ein Aktiv-Aktiv-Betrieb wird nicht unterstützt. Soll der Ersatzserver die Rolle übernehmen, schaltet man zuerst den bisher aktiven Server in den Staging Mode und erst dann den anderen in den Normalbetrieb. Bei einem sehr lange im Staging Mode betriebenen Server hat der Kennwortabgleich einen Rückstand, den er nach der Umschaltung erst abarbeiten muss; während dieser Zeit wirken neu geänderte Kennwörter in der Cloud verzögert. Der Server sollte währenddessen nicht neu gestartet werden.

Der Betrieb umfasst drei weitere Aufgaben. Erstens die Aktualisierung: Die automatische Aktualisierung ist bei Express-Installationen standardmäßig aktiv; bei angepassten Installationen und mehreren Servern plant man die Updates selbst, am besten als sogenannte *Swing Migration*, bei der man den Ersatzserver mit der neuen Version aufbaut, ihn aktiv schaltet und danach den alten aktualisiert. Zweitens die Dokumentation der Konfiguration: Eigene Synchronisierungsregeln, Filter und Sonderfälle müssen schriftlich oder über die Exportfunktion für die Konfiguration gesichert werden, denn sie sind das Einzige, was bei einem Neuaufbau nicht aus den Verzeichnissen zurückkommt. Drittens die Überwachung: *Connect Health* meldet Synchronisierungsfehler, Verzögerungen und den Zustand der Agenten im Entra-Portal; lokal liefert das Anwendungsprotokoll des Servers die Details (siehe Modul 11).

### Typische Fehler und Stolperfallen

Der teuerste Fehler ist das Umbenennen oder Verschieben einer synchronisierten OU. Beim OU-Filter speichert die Software den *Distinguished Name* der OU. Wird sie umbenannt, kennt der Filter sie nicht mehr; beim nächsten vollständigen Import fallen alle ihre Objekte aus dem Umfang und werden in der Cloud gelöscht. Die Löschsperre fängt das ab, wenn mehr als der Schwellwert betroffen ist, bei kleineren Umgebungen aber unter Umständen nicht. Ein zweiter klassischer Fehler: Änderungen an den mitgelieferten Standardregeln. Microsoft empfiehlt, Standardregeln zu kopieren und die Kopie zu ändern, weil sonst Updates die eigenen Änderungen zurücksetzen oder den Support erschweren.

```powershell
# FALSCH: OU umbenennen und die Synchronisierung nicht anpassen
Rename-ADObject "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" -NewName "Mitarbeiter"
# Beim naechsten Full Import fallen alle Benutzer aus dem Filter -> Loeschung in der Cloud

# RICHTIG: Umbenennung planen, Assistent starten, OU im Filter neu auswaehlen,
# vorher auf dem Staging-Server die Auswirkung pruefen (csexport / CSExportAnalyzer)
Rename-ADObject "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" -NewName "Mitarbeiter"
# Danach: Assistent -> Domain-/OU-Filterung -> OU wieder auswaehlen
```

Das Beispiel zeigt, dass der Eingriff in der Struktur des AD und der Eingriff in die Synchronisierung *eine* gemeinsame Änderung sind. Im Änderungsantrag steht deshalb immer beides; Verantwortliche für das Active Directory und für die Cloud-Identität sprechen sich vorher ab.

> **Ergänzung aus der Nachrecherche**
>
> Die Rolle der Komponenten, die Filterarten, die Reihenfolge der Schritte nach Änderungen, das Verhalten von Staging Mode und Löschsperre (Standard 500) sowie das Umbenennen einer gefilterten OU stützen sich auf die abgerufenen Seiten „Microsoft Entra Connect Sync: Configure filtering“, „Staging server and disaster recovery“, „Prevent accidental deletes“, „Scheduler“ und „Upgrade from a previous version“ (Microsoft Learn, Suchauszüge). *Zum Zeitpunkt der Recherche* nennt die Versionshistorie eine verpflichtende Aktualisierung auf Version 2.6.84.0 oder höher und die Einrichtung der anwendungsbasierten Authentifizierung bis zum 7. April 2027; danach würde die Synchronisierung ohne diese Schritte aufhören. Außerdem kennzeichnet dieselbe Seite alle Versionen der Reihe 1 als nicht funktionsfähig. Aktuelle Fristen und Mindestversionen gehören vor jeder Planung auf der Versionsseite nachgeprüft. Die Cmdlets `Get-ADSyncExportDeletionThreshold` und das Ausgabeformat der Scheduler-Eigenschaften stammen aus dem Fachwissen und sind in der eigenen Version zu prüfen.

### Praxisbezug

> **Praxisbeispiel**
>
> Im Alltag begegnen Ihnen drei typische Anlässe: Ein neues Attribut soll in die Cloud (etwa Abteilung oder Telefonnummer), eine neue OU soll synchronisiert werden, oder ein Benutzer „erscheint nicht in Microsoft 365“. Für den dritten Fall prüft man in dieser Reihenfolge: Liegt das Objekt im synchronisierten Bereich? Ist das UPN-Suffix verifiziert? Gibt es Fehler im Import- oder Exportprotokoll? Hat der letzte Zyklus überhaupt stattgefunden? Mit einem dokumentierten Ersatzserver im Staging Mode verkürzt sich außerdem die Wiederherstellung nach einem Serverausfall von Stunden auf Minuten.

## 12.3 Password Hash Sync

*Password Hash Synchronization* (PHS) ist eines der drei Anmeldeverfahren für Hybrid Identity und das mit Abstand am häufigsten genutzte. Das Prinzip: Von jedem synchronisierten Benutzer wird eine Ableitung des Kennworts in die Cloud kopiert, sodass Entra ID die Anmeldung *selbst* prüfen kann, ohne dass ein lokaler Server erreichbar sein muss. Dabei wird nie das Klartextkennwort übertragen, nicht einmal der im AD gespeicherte Hash, sondern ein weiterer Hash davon.

Die Technik lässt sich in wenigen Schritten beschreiben. Das Active Directory speichert Kennwörter als Hash, also als Ergebnis einer Einwegfunktion, aus der sich das Kennwort nicht zurückrechnen lässt; bei NTLM-Hashes ist das ein MD4-Wert im Attribut `unicodePwd`. Etwa alle zwei Minuten fragt der Agent der Synchronisierung auf dem Entra-Connect-Server bei einem Domänencontroller die geänderten Kennwort-Hashs ab, und zwar über dasselbe Replikationsprotokoll (MS-DRSR), das auch die Domänencontroller untereinander benutzen. Dafür braucht das Konto des AD-Connectors die Rechte „Replicate Directory Changes“ und „Replicate Directory Changes All“, die bei der Installation vergeben werden. Auf dem Weg vom Domänencontroller zum Agenten wird der Hash verschlüsselt. Der Agent wandelt ihn danach um: Er hängt einen zufälligen Salt von zehn Byte pro Benutzer an und wendet die Funktion PBKDF2 mit 1000 Runden HMAC-SHA256 an. Das Ergebnis, ein SHA256-Wert, wird über TLS an Entra ID geschickt. Bei der Anmeldung in der Cloud wird das eingegebene Kennwort derselben Rechnung unterzogen; stimmt das Ergebnis, ist die Anmeldung erfolgreich. Die Konsequenz: Der Wert in der Cloud ist *kein* Hash, den man in einem lokalen Pass-the-Hash-Angriff (siehe Modul 8) verwenden könnte. Der Hash wird laut Dokumentation nie in der SQL-Datenbank des Servers gespeichert, sondern nur im Arbeitsspeicher verarbeitet.

Für die Praxis wichtig ist, wie sich die Richtlinien beider Welten zueinander verhalten. Die Komplexitätsanforderungen des lokalen AD gelten für synchronisierte Benutzer; ein Kennwort, das im AD gültig ist, funktioniert auch in der Cloud. Das Kennwortablaufdatum wird dagegen *nicht* übernommen: Standardmäßig steht das Cloud-Kennwort synchronisierter Benutzer auf „läuft nie ab“. Läuft das lokale Kennwort ab, funktioniert das alte weiterhin in der Cloud, bis es lokal geändert wird. Ebenso wird das Attribut `accountExpires` nicht synchronisiert; ein lokal abgelaufenes Konto bleibt in der Cloud aktiv. Die Dokumentation empfiehlt deshalb ein geplantes Skript, das abgelaufene lokale Konten deaktiviert, denn das Deaktivieren wird synchronisiert. Für Benutzer, die mit Smartcard anmelden (Option „Smartcard ist für interaktive Anmeldung erforderlich“), wird das lokale Kennwort zufällig gesetzt und dessen Hash ebenfalls synchronisiert; neuere Versionen stellen sicher, dass das alte Kennwort nach Aktivierung der Smartcard-Pflicht unbrauchbar wird.

Auch temporäre Kennwörter verlangen Aufmerksamkeit. Setzt die Hotline ein Kennwort zurück und aktiviert „Benutzer muss Kennwort bei der nächsten Anmeldung ändern“, gilt dieses Kennwort in der Cloud nur, wenn das Merkmal `UserForcePasswordChangeOnLogonEnabled` aktiviert ist; dann wird der Anwender auch dort zur Änderung aufgefordert. Die Dokumentation weist darauf hin, dass man dies nur nutzen soll, wenn Self-Service-Kennwortzurücksetzung und das Zurückschreiben des Kennworts (Password Writeback) im Mandanten aktiv sind, damit eine in der Cloud geänderte Eingabe auch ins AD gelangt. Zum Überblick gehört noch ein Sicherheitsgewinn: Mit aktivierter PHS kann Microsoft Zugangsdaten, die in öffentlich bekannten Listen auftauchen, mit den Konten des Mandanten abgleichen und ein betroffenes Konto als Hochrisiko einstufen. Die Funktion arbeitet nur mit neu gefundenen Daten nach der Aktivierung.

Und wofür dient PHS noch? Es lässt sich zusätzlich zu einer Föderation als Rückfallebene einrichten, falls AD FS ausfällt. Es ist die einfachste Lösung, weil keine zusätzlichen hochverfügbaren Server nötig sind. Es hat die geringste Abhängigkeit vom lokalen Netz: Fällt das Rechenzentrum aus, können Cloud-Anwendungen weiter genutzt werden. Und es lässt sich mit dem *Staged Rollout* schrittweise einführen, bei dem man einzelne Gruppen auf Cloud-Authentifizierung umstellt, bevor man die ganze Domäne umschaltet.

Das folgende Skript zeigt die Überwachung und ein Beispiel für die oben beschriebene Pflegeaufgabe. Zuerst wird auf dem Synchronisierungsserver geprüft, ob die Kennwortsynchronisierung konfiguriert ist und ob Ereignisse mit Fehlern vorliegen. Danach werden abgelaufene lokale Konten gesucht und zur Probe deaktiviert.

```powershell
# 1. Auf SRV02: Zustand der Kennwortsynchronisierung
Import-Module ADSync
$ad = Get-ADSyncConnector | Where-Object { $_.Type -eq "AD" }
Get-ADSyncAADPasswordSyncConfiguration -SourceConnector $ad.Name

# 2. Ereignisse der Synchronisierung: Fehler (611) und Erfolge (657) der letzten 24 Stunden
$seit = (Get-Date).AddHours(-24)
Get-WinEvent -FilterHashtable @{
    LogName      = "Application"
    ProviderName = "Directory Synchronization"
    Id           = 611, 657
    StartTime    = $seit
} -ErrorAction SilentlyContinue |
    Group-Object Id | Select-Object Name, Count

# 3. Auf DC01: lokal abgelaufene Konten finden und (zur Probe) deaktivieren
Search-ADAccount -AccountExpired -UsersOnly |
    Where-Object { $_.Enabled } |
    Disable-ADAccount -WhatIf
```

Schritt 1 ermittelt den AD-Connector und fragt dessen Einstellung für die Kennwortsynchronisierung ab; erwartet wird, dass sie aktiviert ist. In Schritt 2 liest `Get-WinEvent` über einen Hashtabellen-Filter nur die Ereignisse der letzten 24 Stunden aus dem Anwendungsprotokoll. Die Ereignis-ID 611 steht laut Dokumentation für einen Fehler bei der Kennwortsynchronisierung, die ID 657 meldet den Abgleich einzelner Kennwörter. Das Zählen nach ID liefert eine schnelle Übersicht. Mit `-ErrorAction SilentlyContinue` verhindert man eine Fehlermeldung, wenn gar keine Ereignisse vorliegen. In Schritt 3 findet `Search-ADAccount` alle abgelaufenen Benutzerkonten; wegen der Tatsache, dass `accountExpires` nicht synchronisiert wird, sorgt das Deaktivieren dafür, dass die Sperre auch in der Cloud ankommt. Mit `-WhatIf` wird nichts verändert, sondern nur gezeigt, was geschehen würde.

### Typische Fehler und Stolperfallen

Ein häufiger Irrtum betrifft die Frage, wo das Kennwort zurückgesetzt wird. Ändert eine Administratorin das Kennwort direkt in Entra ID per PowerShell, überschreibt es das synchronisierte Kennwort; die nächste lokale Änderung überschreibt es wieder. Ohne Passwort-Rückschreibung entstehen so zwei Kennwörter für dasselbe Konto. Ein zweiter Fehler: Ein Dienstkonto mit Kennwort, das nie abläuft, soll in der Cloud ebenfalls nicht ablaufen, doch ein vollständiger Neuabgleich kann die Einstellung zurücksetzen.

```powershell
# FALSCH: Kennwort nur in der Cloud zuruecksetzen und annehmen, es gelte auch lokal
# Ergebnis: lokal gilt weiter das alte Kennwort, die naechste lokale Aenderung ueberschreibt die Cloud

# RICHTIG: Kennwort dort aendern, wo das Konto fuehrend ist (lokales AD)
Set-ADAccountPassword -Identity anna.beispiel -Reset `
    -NewPassword (Read-Host -AsSecureString "Neues Kennwort")
Set-ADUser -Identity anna.beispiel -ChangePasswordAtLogon $true
# Nach etwa zwei Minuten ist das Kennwort in der Cloud wirksam
```

Die Gegenüberstellung folgt dem Grundsatz, dass die führende Quelle der Ort der Änderung ist. Wer auch Cloud-seitige Änderungen zulassen will, aktiviert Self-Service-Kennwortzurücksetzung mit Rückschreibung und dokumentiert das als bewusste Entscheidung.

> **Ergänzung aus der Nachrecherche**
>
> Die Abläufe von PHS (Zwei-Minuten-Zyklus, benötigte Replikationsrechte, Salt und PBKDF2 mit 1000 Runden HMAC-SHA256), das Verhalten bei Komplexität und Ablauf, `accountExpires`, Smartcard-Pflicht, temporäre Kennwörter und die Erkennung bekannter Zugangsdaten stützen sich auf die abgerufene Seite „Implement password hash synchronization with Microsoft Entra Connect Sync“ und „What is password hash synchronization“ (Microsoft Learn, Suchauszüge). Die Ereignis-IDs 611 und 657 werden dort bzw. auf der Seite zum Staging Mode erwähnt. Der Provider-Name „Directory Synchronization“ und das Cmdlet `Get-ADSyncAADPasswordSyncConfiguration` stammen aus dem Fachwissen. Nach der Dokumentation unterstützt die Funktion nur Objekte vom Typ User, nicht iNetOrgPerson. Die abgerufene PHS-Seite nennt unter den Voraussetzungen auch die Installation des Agenten von Cloud Sync; das Verfahren ist also nicht an Entra Connect gebunden (Abschnitt 12.6).

### Praxisbezug

> **Praxisbeispiel**
>
> Bei der Einführung ist der wichtigste Schritt eine Kommunikationsregel: Welches Kennwort gilt wo, wie lange dauert die Übernahme einer Änderung (etwa zwei Minuten), und was geschieht, wenn jemand sein Kennwort in der Cloud vergisst? Die Hotline schult man darauf, Kennwörter im AD zurückzusetzen. In Sicherheitsberichten taucht PHS außerdem als Quelle der Meldung „Benutzer mit bekannten Zugangsdaten“ auf, was ein sofortiges Zurücksetzen und eine Prüfung der Anmeldungen auslösen sollte.

## 12.4 Pass-through Authentication

Bei der *Pass-through Authentication* (PTA) liegt kein Kennwort-Hash in der Cloud. Stattdessen reicht Entra ID das bei der Anmeldung eingegebene Kennwort, verschlüsselt, an einen kleinen *Authentifizierungs-Agenten* im lokalen Netz weiter, der es gegen das Active Directory prüft und das Ergebnis zurückmeldet. Die Anmeldung wird also weiterhin von den Domänencontrollern entschieden, und es gelten ohne Umweg die lokalen Richtlinien zu Kennwortablauf, Sperrung und Anmeldezeiten.

Der Ablauf ist so beschrieben: Die Anwenderin gibt Name und Kennwort auf der Anmeldeseite von Entra ID ein. Entra ID verschlüsselt das Kennwort mit den öffentlichen Schlüsseln aller beim Mandanten registrierten Agenten und legt die Anfrage in eine mandantenspezifische Warteschlange. Ein Agent holt die Anfrage über eine bereits bestehende ausgehende Verbindung ab, entschlüsselt das Kennwort mit seinem privaten Schlüssel und prüft es mit der Windows-Funktion `LogonUser` (Anmeldetyp Netzwerk) gegen einen Domänencontroller. Das ist dieselbe Funktion, die auch AD FS benutzt. Der Domänencontroller antwortet mit Erfolg, falsches Kennwort, abgelaufenes Kennwort oder gesperrt, und der Agent gibt das Ergebnis an Entra ID zurück, das die Anmeldung fortsetzt, beispielsweise mit einer Aufforderung zur mehrstufigen Anmeldung.

Die Sicherheitsarchitektur hat einige Eigenschaften, die man für Planung und Prüfung kennen sollte. Die Agenten bauen nur *ausgehende* Verbindungen auf, über Port 443 (alle Funktionen) und Port 80 (Sperrlisten für Zertifikate); es sind keine eingehenden Ports und keine Platzierung im Randnetz nötig. Jeder Agent erhält bei der Registrierung ein Zertifikat von Entra ID und erneuert es rechtzeitig vor Ablauf selbst; läuft das Zertifikat ab, wird der Agent aus der Liste entfernt und muss neu installiert werden. Die Agenten sprechen nur mit der Cloud, nicht untereinander: Fällt ein Agent mitten in einer Anmeldung aus, wird diese Anfrage abgebrochen und nicht an einen anderen Agenten übergeben, die nächste funktioniert dann wieder. Für Ausfallsicherheit installiert man deshalb mehrere Agenten auf verschiedenen Servern. Schließlich sind die Agentenserver nach der Dokumentation wie Domänencontroller zu behandeln: Sie sehen Kennwörter im Klartext, gehören also in Tier 0 (Modul 9) und werden entsprechend gehärtet. PTA arbeitet zusammen mit bedingtem Zugriff, mehrstufiger Authentifizierung, dem Blockieren veralteter Anmeldeprotokolle und der intelligenten Kontosperre (Smart Lockout) der Cloud.

Der Vergleich mit PHS ergibt sich aus diesen Merkmalen. Bei PTA bleibt die Entscheidung lokal; wer aus regulatorischen oder internen Gründen keine Kennwortableitungen in der Cloud ablegen will, wählt PTA. Dafür hängt die Anmeldung an Cloud-Diensten vom lokalen Netz ab: Sind alle Agenten oder alle Domänencontroller nicht erreichbar, scheitern Anmeldungen. PHS ist robuster, einfacher und ermöglicht die Erkennung bekannter Zugangsdaten, die die Dokumentation als Vorteil von PHS nennt. In der Praxis wird PTA häufig zusammen mit PHS als Rückfallebene eingerichtet, wobei der Wechsel zwischen den Verfahren nicht automatisch erfolgt, sondern eine Änderung der Konfiguration erfordert. PTA setzt voraus, dass die Benutzer per Entra Connect synchronisiert wurden; für reine Cloud-Konten gilt das Verfahren nicht.

Zur Kontrolle prüft man auf dem Agentenserver den Dienst, die Erreichbarkeit der Microsoft-Endpunkte und die Verbindung zu einem Domänencontroller. Das folgende Skript fasst diese drei Prüfungen zusammen.

```powershell
# Auf dem Server mit dem Authentifizierungs-Agenten (z. B. SRV02)
# 1. Laeuft der Agent-Dienst?
Get-Service -DisplayName "*Authentication Agent*" |
    Select-Object Status, Name, DisplayName

# 2. Ausgehende Verbindungen zur Cloud (Port 443, Port 80 fuer Sperrlisten)
foreach ($port in 443, 80) {
    Test-NetConnection -ComputerName login.microsoftonline.com -Port $port |
        Select-Object ComputerName, RemotePort, TcpTestSucceeded
}

# 3. Findet der Server einen Domaenencontroller?
nltest /dsgetdc:corp.contoso.com

# 4. Aktuelle Agent-Meldungen im Ereignisprotokoll
Get-WinEvent -LogName "Microsoft-AzureADPassthroughAuthentication/Admin" -MaxEvents 10 |
    Select-Object TimeCreated, Id, LevelDisplayName, Message
```

Schritt 1 zeigt den Zustand des Agentendienstes; der genaue Dienstname unterscheidet sich je nach Version, deshalb die Suche über den Anzeigenamen mit Platzhaltern. In Schritt 2 testet `Test-NetConnection` die beiden Ports zum Anmeldedienst; `TcpTestSucceeded` sollte `True` sein. Für die Anmeldung zählt, dass der Test im Kontext des Dienstes funktioniert; wird ein Proxy verwendet, ist die Prüfung als Benutzer nur ein Hinweis. Schritt 3 benutzt das aus Modul 11 bekannte `nltest`, um zu sehen, welchen Domänencontroller der Server findet, denn der Agent ist auf dessen Erreichbarkeit angewiesen. Schritt 4 liest die letzten zehn Ereignisse des Agentenprotokolls, wo Registrierungs- und Verbindungsfehler stehen.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist ein einziger Agent: Dann führt jeder Neustart zum Ausfall der Cloud-Anmeldung. Dazu kommt, dass Agenten gern auf einem Domänencontroller mit installiert werden. Das ist möglich, bündelt aber zu viele Funktionen auf einem Tier-0-System und macht bei Wartungen beide Dienste gleichzeitig unverfügbar. Ein weiterer Fehler betrifft Proxys und Firewalls: Wer ausgehenden Datenverkehr über einen Proxy erzwingt, muss den Systemkontext des Servers zulassen, sonst scheitert die Registrierung oder die Verbindung.

```powershell
# FALSCH: genau ein Agent, auf DC01 mitinstalliert
#   -> Neustart von DC01 = keine Anmeldung an Cloud-Diensten

# RICHTIG: mindestens zwei Agenten auf getrennten, geharteten Servern
#   SRV02 (Agent 1), SRV03 (Agent 2); beide wie Domaenencontroller behandelt (Tier 0)
#   Ausgehend nur Port 443 und 80, keine eingehenden Freigaben
```

Die Planung richtet sich nach dem Ausfall, den man verkraften will: Fällt ein Agent aus, übernimmt der andere; bei der Wartung nimmt man immer nur einen Server zur Zeit aus dem Betrieb.

> **Ergänzung aus der Nachrecherche**
>
> Den Ablauf der Anmeldung, die Verwendung von `LogonUser`, die ausgehenden Ports 443 und 80, die Zertifikatserneuerung, die Behandlung als Tier-0-System sowie die Hochverfügbarkeit durch mehrere Agenten stützen sich auf die abgerufenen Seiten „Microsoft Entra pass-through authentication: Technical deep dive“, „Security deep dive“ und „Frequently asked questions“ (Microsoft Learn, Suchauszüge). Die FAQ-Seite nennt für ältere Versionen weitere Ports (zum Beispiel 5671, 8080, 9090); ein aktueller Stand ist der Quickstart-Seite zu entnehmen. Der Name des Ereignisprotokolls und des Dienstes stammen aus dem Fachwissen. Aus dem Entscheidungsleitfaden der Cloud-Synchronisierung geht hervor, dass die Konfiguration von PTA dort getrennt von der Synchronisierung verwaltet wird.

### Praxisbezug

> **Praxisbeispiel**
>
> Wer eine Umgebung übernimmt, sollte als Erstes klären, welches Verfahren produktiv ist; im Entra-Portal steht es unter den Einstellungen zu Entra Connect. PTA findet man oft in Umgebungen, in denen man Kennwörter nicht in der Cloud ablegen wollte oder in denen Abläufe wie Kontosperre und Anmeldezeiten strikt lokal bestimmt werden. In Störungsfällen sind die Agentenserver ein beliebter Prüfpunkt: Windows-Updates, abgelaufene Zertifikate oder eine geänderte Proxy-Konfiguration erzeugen Meldungen der Anwender wie „Mein Kennwort wird nicht akzeptiert“, obwohl es im AD stimmt.

## 12.5 Hybrid Join

Bisher ging es um Benutzer. Auch *Geräte* haben eine Identität. In Entra ID gibt es dafür drei Zustände. Ein *registriertes* Gerät (Entra registered) ist ein privates Gerät, auf dem sich eine Person mit dem Geschäftskonto für bestimmte Apps anmeldet. Ein *Entra-joined* Gerät gehört der Organisation und ist nur in der Cloud bekannt, ohne Domänenmitgliedschaft. Ein *hybrid-joined* Gerät ist *gleichzeitig* Mitglied der lokalen AD-Domäne und in Entra ID als Gerät eingetragen. Der dritte Weg ist der natürliche Zwischenschritt für Unternehmen mit vielen Domänen-Arbeitsplätzen, die man weiter über Gruppenrichtlinien und gegebenenfalls Configuration Manager verwaltet, aber auch für Cloud-Funktionen nutzen will: bedingter Zugriff, der nur verwaltete Geräte zulässt, Single Sign-On an Cloud-Diensten ohne erneute Eingabe und Anbindung an eine Geräteverwaltung wie Intune.

Der Kern des Verfahrens ist die Geräteregistrierung. Ein Windows-Gerät, das in der Domäne ist und Zugriff auf ein Domänencontroller-Netz hat, versucht automatisch, sich bei Entra ID anzumelden. Zuerst liest es aus der lokalen Registrierung unter `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\AAD` die Mandanteninformationen; ist dort nichts hinterlegt, fragt es im Active Directory nach einem *Service Connection Point* (SCP). Der SCP ist ein Objekt in der Konfigurationspartition des Forests, das die Mandanten-ID und den Mandantennamen enthält. Der Assistent von Entra Connect legt ihn an; in großen Umgebungen kann man stattdessen die Werte per Richtlinie direkt auf den Geräten hinterlegen, was zum Beispiel eine gezielte, stufenweise Einführung oder den Fall mehrerer Mandanten in einem Forest erlaubt. Anschließend kontaktiert das Gerät den Registrierungsdienst von Entra ID, authentifiziert sich und erhält ein Gerätezertifikat. Damit das Gerät in der Cloud auch als Objekt existiert, müssen die Computerobjekte durch Entra Connect (oder Cloud Sync) synchronisiert werden; solange das nicht geschehen ist, endet der Versuch im Zustand „ausstehend“ und wird später wiederholt (Sync-Join). Danach kann sich der Benutzer anmelden, und das Gerät erhält ein *Primary Refresh Token* (PRT), das Single Sign-On für Cloud-Anwendungen ermöglicht.

Einige Voraussetzungen und Einschränkungen sind zu beachten. Das Gerät braucht regelmäßig Sichtverbindung zu einem Domänencontroller; ohne sie werden unter anderem Änderungen des Gerätekennworts, Kennwortänderungen mit zwischengespeicherten Anmeldeinformationen und ein Zurücksetzen des TPM-Moduls zum Problem. Unterstützt werden Windows 10 und Windows 11 sowie Windows Server 2016, 2019 und 2022 (jeweils als Mitgliedsserver). Nicht unterstützt sind Server mit der Domänencontroller-Rolle und Server Core. Bei verwalteten Domänen (PHS oder PTA mit nahtlosem Single Sign-On) muss das UPN-Suffix routingfähig sein; nicht routingfähige UPNs werden nur in föderierten Umgebungen unterstützt. Wer Arbeitsplätze aus Images oder Snapshots erstellt, darf nicht von einem Gerät ausgehen, das bereits hybrid-joined ist, sonst entstehen doppelte Identitäten. Technologien, die beim Neustart Änderungen auf der Festplatte verwerfen (Unified Write Filter), werden erst *nach* dem Hybrid Join aktiviert.

Zur Diagnose dient das Werkzeug `dsregcmd /status`. Es zeigt in drei Abschnitten den Gerätezustand (zum Beispiel `DomainJoined` und `AzureAdJoined`), den Zustand des Benutzers (Anmeldedaten, `AzureAdPrt`) und, falls die Registrierung scheitert, ein Diagnoseprotokoll vor der Anmeldung. Dieses prüft in Etappen die Verbindung zum Domänencontroller, die Lesbarkeit des SCP, den Zugriff auf die Registrierungsendpunkte und die Beschaffung eines Tokens. Ergänzend gibt das Ereignisprotokoll „User Device Registration“ unter Anwendungs- und Dienstprotokolle, Microsoft, Windows den Fehlercode samt Phase aus. Das folgende Skript liest die wichtigsten Felder aus und prüft den SCP im Active Directory.

```powershell
# 1. Auf PC01 (als Administrator): wichtige Felder von dsregcmd auslesen
$status = dsregcmd /status
$felder = "DomainJoined", "AzureAdJoined", "AzureAdPrt", "TenantName", "DeviceId"
foreach ($feld in $felder) {
    $zeile = $status | Select-String -Pattern ("^\s*" + $feld + "\s*:")
    if ($zeile) { $zeile.Line.Trim() } else { $feld + " : nicht gefunden" }
}

# 2. Auf DC01: Service Connection Point im Forest pruefen
$konfig = "CN=Configuration," + (Get-ADRootDSE).rootDomainNamingContext
$scp = "CN=62a0ff2e-97b9-4513-943f-0d221bd30080,CN=Device Registration Configuration," +
       "CN=Services," + $konfig
Get-ADObject -Identity $scp -Properties keywords | Select-Object -ExpandProperty keywords

# 3. Registrierung neu anstossen (nur auf dem betroffenen Geraet, als Administrator)
dsregcmd /leave
Restart-Computer
# Nach dem Neustart versucht das Geraet den Beitritt automatisch erneut
```

In Schritt 1 wird die Ausgabe von `dsregcmd` zeilenweise nach den gesuchten Feldnamen durchsucht; `Select-String` nimmt ein reguläres Muster, das am Zeilenanfang optionale Leerzeichen, den Namen und einen Doppelpunkt erwartet. Ein Gerät, das hybrid-joined ist, zeigt bei `DomainJoined` und `AzureAdJoined` jeweils `YES`; `AzureAdPrt` auf `YES` bedeutet, dass das Single-Sign-On-Token vorliegt. Schritt 2 liest den SCP: Das Objekt liegt in der Konfigurationspartition, und das Attribut `keywords` enthält die Mandanten-ID und den Mandantennamen. Fehlt das Objekt oder zeigt es auf einen falschen Mandanten, endet die Registrierung in der Entdeckungsphase mit dem Fehler `0x801c001d`. Schritt 3 ist das letzte Mittel: `dsregcmd /leave` entfernt den lokalen Registrierungszustand, nach dem Neustart wird der Beitritt erneut versucht. Das darf nur auf dem einzelnen betroffenen Gerät geschehen, nie flächendeckend.

### Typische Fehler und Stolperfallen

Die häufigste Ursache für scheiternde Geräte ist fehlende Erreichbarkeit der Endpunkte *im Systemkontext*: Die Registrierung läuft als Systemkonto, nicht als angemeldeter Benutzer. Ein Proxy, der nur Benutzer anmeldet, blockiert deshalb den Beitritt. Zwei weitere Klassiker sind ein fehlender oder falscher SCP und Geräte außerhalb des Synchronisierungsumfangs, also Computerobjekte in einer OU, die der OU-Filter nicht einschließt. Auch ein Gerät, das sich zuerst als „registriert“ bei Entra ID eingetragen hat, kann in einen Doppelzustand geraten, den neuere Windows-Versionen beim nächsten Anmelden bereinigen; ältere Versionen erfordern manuelle Handarbeit.

```powershell
# FALSCH: Computerkonten der Arbeitsplaetze liegen in OU=Arbeitsplaetze,OU=Computer
# und sind im Filter von Entra Connect nicht enthalten
#   -> Geraet bleibt dauerhaft "Pending", Fehler: Geraeteobjekt nicht gefunden

# RICHTIG: Computer-OU in die Synchronisierung aufnehmen, Initial-Zyklus ausfuehren,
# danach auf dem Geraet:
dsregcmd /status
# Erwartet: AzureAdJoined : YES   und    AzureAdPrt : YES
```

Die Lösung zeigt die Reihenfolge, die man bei Pilotprojekten einhält: zuerst das Objekt in die Cloud, dann der Beitritt. Als Pilot genügt eine Handvoll Geräte unterschiedlicher Benutzergruppen; das gezielte Ausrollen über SCP auf dem Gerät oder per Richtlinie erlaubt, Probleme zu erkennen, bevor die ganze Organisation betroffen ist.

> **Ergänzung aus der Nachrecherche**
>
> Zustände, Voraussetzungen, unterstützte Systeme, Einschränkungen (keine Domänencontroller und kein Server Core, Hinweise zu Images, Snapshots und Unified Write Filter), die Rolle des SCP und die UPN-Regeln stützen sich auf die abgerufenen Seiten „Plan your Microsoft Entra hybrid join implementation“, „Troubleshoot devices by using the dsregcmd command“ und „Troubleshoot Microsoft Entra hybrid joined devices“ (Microsoft Learn, Suchauszüge). Die dort genannten Fehlerbilder (zum Beispiel `0x801c001d` bei nicht lesbarem SCP) und Endpunkte (`enterpriseregistration.windows.net`, `login.microsoftonline.com`) sind in der Doku aufgeführt. Die GUID des SCP-Objekts, die Gruppenrichtlinie zur automatischen Geräteregistrierung und die Formulierung des Skripts stammen aus dem Fachwissen und sind in der eigenen Umgebung zu prüfen. Die Seite zur Cloud-Synchronisierung beschreibt, dass auch dort eine Gerätesynchronisierung für den Hybrid Join aktiviert werden kann (Abschnitt 12.6).

### Praxisbezug

> **Praxisbeispiel**
>
> Wenn Fachabteilungen „Zugriff nur von verwalteten Geräten“ verlangen, ist Hybrid Join meist der erste Baustein: bedingter Zugriff prüft, ob das Gerät in Entra ID als hybrid-joined bekannt ist, und lässt Anmeldungen von privaten Geräten nicht oder nur eingeschränkt zu. Im Support gilt `dsregcmd /status` als erste Frage an Anwender mit Anmeldeproblemen an Cloud-Diensten; das Ergebnis lässt sich schnell am Telefon vorlesen. Planen Sie außerdem ein, dass Arbeitsplätze im Homeoffice ohne VPN keine Sichtverbindung zum Domänencontroller haben und bestimmte Vorgänge erst nach dem Verbinden gelingen.

## 12.6 Cloud Sync

*Microsoft Entra Cloud Sync* ist der zweite Weg, ein lokales Active Directory mit Entra ID zu verbinden. Er löst ein Problem, das viele Verwalter mit Entra Connect kennen: Die vollständige Synchronisierungs-Engine mit ihrer Datenbank, ihren Regeln und ihren Updates läuft auf einem eigenen Server, den man bauen, sichern, aktualisieren und überwachen muss. Bei Cloud Sync wandert die Engine in die Cloud. Lokal läuft nur ein schlanker *Provisioning-Agent*, der als sichere Brücke zwischen dem AD und dem Dienst in Entra ID dient. Die gesamte Konfiguration liegt im Mandanten und wird im Entra-Portal gepflegt, von überall und ohne Zugriff auf einen Server. Die Agenten werden von Microsoft automatisch aktualisiert; eine unterstützte Möglichkeit, das abzuschalten, gibt es nicht.

Daraus ergeben sich die Stärken. Man kann mehrere Agenten gleichzeitig betreiben, die sich gegenseitig vertreten, ohne einen Ersatzserver im Staging Mode vorzuhalten. Man kann mehrere, auch voneinander getrennte Forests an einen Mandanten anbinden, was bei Firmenübernahmen den Zeitgewinn bringt, den man sonst durch eine Forest-Konsolidierung erkaufen müsste. Die Agenten dürfen auf Domänencontrollern oder auf eigenen Servern laufen und benötigen wenig Ressourcen. Zusätzlich bietet Cloud Sync die Bereitstellung *von* der Cloud *ins* AD für Gruppen, etwa um lokale Anwendungen mit in der Cloud gepflegten Gruppen zu steuern. Auch die Synchronisierung von Geräten für den Hybrid Join lässt sich aktivieren, getrennt von den übrigen Einstellungen. Microsoft bezeichnet Cloud Sync als die strategische Richtung: Neue Funktionen entstehen vor allem dort, und Entra Connect Sync soll nach Erreichen voller Funktionsgleichheit eingestellt werden.

Cloud Sync ist aber nicht einfach „Connect, nur besser“. Die Dokumentation von Microsoft listet Unterschiede auf, die für die Entscheidung zählen. Die folgende Tabelle fasst die wichtigsten zusammen.

| Merkmal                                                | Entra Connect Sync                    | Cloud Sync                    |
|:-------------------------------------------------------|:--------------------------------------|:------------------------------|
| Ort der Engine                                         | lokaler Server mit Datenbank          | Cloud-Dienst, lokal nur Agent |
| Konfiguration                                          | lokal auf dem Server                  | im Entra-Portal               |
| Hochverfügbarkeit                                      | Server im Staging Mode (aktiv/passiv) | mehrere aktive Agenten        |
| Getrennte Forests                                      | nicht unterstützt                     | unterstützt                   |
| Größenlimit je Domäne                                  | unbegrenzt                            | derzeit bis 150 000 Objekte   |
| Mitglieder je Gruppe                                   | bis 250 000                           | bis 50 000                    |
| Erweiterte Synchronisierungsregeln, Attributfilter     | ja                                    | begrenzt (Ausdrucks-Editor)   |
| Gerätezurückschreiben (Device Writeback)               | ja                                    | nein                          |
| Verbundeinrichtung (AD FS)                             | ja                                    | nein                          |
| Einrichtung von Pass-through Authentication            | ja                                    | nein (getrennt verwaltet)     |
| Kennwort-Hash-Synchronisierung, Passwort-Rückschreiben | ja                                    | ja                            |
| Gruppen vom Cloud ins AD                               | nein                                  | ja                            |

Die Tabelle gibt den Stand der Dokumentation zum Zeitpunkt der Recherche wieder; Zahlen und Funktionen ändern sich. Sie zeigt, wann Cloud Sync die bessere Wahl ist: bei mehreren oder getrennten Forests, bei dem Wunsch nach weniger lokaler Infrastruktur und bei Standardanforderungen an Filter und Attribute. Entra Connect bleibt dort nötig, wo große Gruppen, sehr große Verzeichnisse, komplexe Regeln, das Zusammenführen von Attributen aus mehreren Domänen oder Föderation gefragt sind. In einer einfachen Umgebung mit einem Forest, in der Connect alle Anforderungen erfüllt, bringt ein Wechsel allein wenig Gewinn.

Der Takt unterscheidet sich ebenfalls. Die Kennwortsynchronisierung läuft laut der FAQ alle zwei bis fünf Minuten, die Bereitstellung von Benutzern und Gruppen etwa alle zehn bis zwanzig Minuten, abhängig von der Menge an Änderungen. Für eine neue Mitarbeiterin dauert es also einige Minuten, bis das Konto in der Cloud erscheint. Das Source-Anchor-Attribut ist standardmäßig `mS-DS-ConsistencyGuid` mit Rückfall auf die `objectGUID`; es lässt sich nicht ändern. Auch die Verweise zwischen Objekten (zum Beispiel Manager) müssen innerhalb derselben Domäne liegen, wenn mehrere Forests angebunden sind.

Die Umstellung von Entra Connect auf Cloud Sync folgt einer festen Reihenfolge, die Microsoft beschreibt. Zuerst prüft man mit dem Entscheidungsleitfaden, ob Cloud Sync alle Anforderungen unterstützt. Danach nutzt man, wenn die Voraussetzungen erfüllt sind, das *geführte Migrationswerkzeug*. Ist die Umgebung dafür nicht geeignet, bleibt der dokumentierte manuelle Weg mit einer Pilotgruppe oder man bleibt bei Connect. Wichtig ist die Regel der Koexistenz: Beide Werkzeuge dürfen *nicht* gleichzeitig dieselben Attribute desselben Objekts normal exportieren. Im manuellen Verfahren verhindern zwei Regeln (`cloudNoFlow` und `JoinNoFlow`), dass Connect für die Pilotobjekte Änderungen schreibt, während sie in Connect im Umfang bleiben, damit die Verweise erhalten bleiben. Ein Objekt darf erst aus dem Umfang von Connect entfernt werden, wenn Cloud Sync alle betroffenen Objekte bereitstellt; sonst löscht Connect Verweise wie Gruppenmitgliedschaften in der Cloud.

Zur Vorbereitung hilft ein Skript, das die größten Hürden vorab misst: die Zahl der Objekte, die größten Gruppen und den Zustand des Source-Anchor-Attributs.

```powershell
# Eignungspruefung fuer Cloud Sync (nur lesend, auf DC01)
Import-Module ActiveDirectory
$ou = "OU=Contoso,DC=corp,DC=contoso,DC=com"

# 1. Anzahl der Objekte im Synchronisierungsumfang (Grenzwert je Domaene: 150000)
$filter = "(|(objectClass=user)(objectClass=group)(objectClass=contact))"
$anzahl = (Get-ADObject -SearchBase $ou -LDAPFilter $filter | Measure-Object).Count
"Objekte im Umfang: $anzahl"

# 2. Die fuenf groessten Gruppen (Grenzwert je Gruppe: 50000 Mitglieder)
Get-ADGroup -SearchBase $ou -Filter * -Properties Member |
    Select-Object Name, @{n = "Mitglieder"; e = { $_.Member.Count }} |
    Sort-Object Mitglieder -Descending |
    Select-Object -First 5

# 3. Wie viele Benutzer haben schon einen ConsistencyGuid?
$benutzer = Get-ADUser -SearchBase $ou -Filter * -Properties "mS-DS-ConsistencyGuid"
$mit = ($benutzer | Where-Object { $_."mS-DS-ConsistencyGuid" }).Count
"Benutzer gesamt: $($benutzer.Count), davon mit ConsistencyGuid: $mit"
```

Der erste Teil zählt Benutzer, Gruppen und Kontakte mit einer LDAP-Filterabfrage. Beachten Sie, dass die Klasse `user` auch Computerobjekte enthält; die Zahl ist deshalb eine obere Abschätzung, die für die Abgrenzung gegen 150 000 genügt. Der zweite Teil liest die Mitgliedschaft der Gruppen und sortiert nach Größe; bei sehr großen Gruppen ist zu beachten, dass die Active-Directory-Webdienste die Zahl der zurückgegebenen Mitglieder standardmäßig begrenzen. Der dritte Teil prüft das Source-Anchor-Attribut. Ist es leer, nimmt Cloud Sync die `objectGUID`; war in der Umgebung bisher ein anderes Attribut als Source Anchor verwendet worden, muss man sicherstellen, dass beide Werkzeuge dieselben Objekte miteinander verbinden. Das Skript verändert nichts und kann beliebig oft laufen.

### Typische Fehler und Stolperfallen

Der gefährlichste Fehler ist die gleichzeitige Verwaltung derselben Objekte durch beide Werkzeuge ohne die dokumentierten Schutzregeln. Dann überschreiben sich Connect und Cloud Sync gegenseitig, und im schlimmsten Fall verschwinden Gruppenmitgliedschaften. Ebenso gefährlich ist das vorzeitige Entfernen eines Objekts aus dem Umfang von Connect: Connect löscht dessen Datensätze und exportiert Verweislöschungen. Der zweite verbreitete Fehler ist, das Größenlimit zu übersehen und erst nach der Umstellung festzustellen, dass eine große Verteilerliste nicht vollständig übertragen wird.

```powershell
# FALSCH: Pilotgruppe in Cloud Sync aufnehmen und gleichzeitig in Connect lassen,
# ohne die Schutzregeln (cloudNoFlow / JoinNoFlow) einzurichten
#   -> beide Werkzeuge exportieren dieselben Attribute

# RICHTIG: dokumentierte Migrationsschritte einhalten
#   1. Eignung pruefen (Entscheidungsleitfaden, Skript oben)
#   2. Geführtes Werkzeug verwenden, wenn die Voraussetzungen passen
#   3. Sonst: Pilotgruppe, Schutzregeln, Verweise pruefen, Umfang erst danach reduzieren
#   4. Kontrolle: Gruppenmitgliedschaften und Manager in der Cloud vergleichen
```

Die Abfolge zeigt, dass Migration kein einzelner Schalter ist, sondern ein geplantes Projekt mit Pilotphase und Rückweg: Bei Problemen deaktiviert man in der Cloud die Konfiguration von Cloud Sync und die selbst angelegten Regeln in Connect, was dort einen vollständigen Abgleich auslöst.

> **Ergänzung aus der Nachrecherche**
>
> Architektur, Fähigkeiten, Vergleichstabelle, Größenlimits (150 000 Objekte je Domäne, 50 000 Mitglieder je Gruppe, 250 000 bei Connect), Takt der Synchronisierung, Source Anchor, automatische Agent-Updates sowie die Regeln der Koexistenz und des Entfernens aus dem Umfang stützen sich auf die abgerufenen Seiten „What is Microsoft Entra Cloud Sync?“, „Migrate from Connect Sync to Cloud Sync: decision guide“, „Cloud Sync FAQ“, „Migrate to Cloud Sync FAQ“ und „Tutorial: Migrate to Microsoft Entra Cloud Sync for a synced Active Directory forest“ (Microsoft Learn, Suchauszüge). Zahlen und Funktionsumfang ändern sich häufig und sind vor der Entscheidung auf diesen Seiten zu prüfen. Der Hinweis zum Limit der AD-Webdienste bei sehr großen Gruppen stammt aus dem Fachwissen.

### Praxisbezug

> **Praxisbeispiel**
>
> Typische Einsatzfälle sind die Anbindung eines zugekauften Unternehmens mit eigenem Forest, ohne sofort zu konsolidieren, und kleine Umgebungen, die keinen weiteren Server betreiben wollen. Entscheidend ist ein ehrlicher Abgleich der Anforderungen mit der aktuellen Funktionsliste, bevor man das Projekt beginnt. Bewährt hat sich, mit einer Pilotgruppe zu starten, die alle Objekttypen und die kritischen Sonderfälle enthält, und die Ergebnisse als Protokoll festzuhalten.

## 12.7 Migration und Konsolidierung

Active-Directory-Umgebungen wachsen historisch: Firmen werden gekauft und verkauft, Standorte haben eigene Domänen, ein altes Betriebssystem muss abgelöst werden, oder die Struktur ist so gewachsen, dass ein Neuanfang einfacher ist als die Reparatur. Für solche Fälle gibt es zwei Arten von Vorhaben. Das *Upgrade* bleibt im selben Forest: Man fügt Domänencontroller mit neuerem Betriebssystem hinzu, überträgt die FSMO-Rollen (Modul 6), entfernt die alten Domänencontroller und hebt anschließend das funktionale Niveau an. Die Migration bewegt Konten und Ressourcen in einen *anderen* Forest oder eine andere Domäne. Dieses Vorgehen ist aufwendiger und verlangt besondere Sorgfalt, ist aber der Weg bei Fusionen, bei der Bereinigung eines belasteten Forests oder beim Wechsel in eine neue, sauber gestaltete Struktur.

Die Dokumentation unterscheidet zwei Spielarten. Bei der Umstrukturierung *innerhalb* eines Forests (Intra-Forest) werden Objekte in eine andere Domäne verschoben, sie existieren danach in der Quelldomäne nicht mehr; ein Rückweg ist daher schwierig. Bei der Umstrukturierung *zwischen* Forests (Inter-Forest) bleiben Quelle und Ziel parallel bestehen, und man kann während der Migration jederzeit zur Quelle zurückkehren. Deshalb wählt man für riskante Vorhaben bevorzugt die Variante, bei der die Quelle unverändert bleibt.

Zentral ist das Thema *SID-History*. Jedes Objekt hat eine eindeutige Sicherheits-ID (SID), die ihre Domäne enthält. Zieht ein Konto in eine andere Domäne, bekommt es dort eine neue SID. Alle Berechtigungen, die auf Freigaben, Dateien oder in Anwendungen mit der alten SID eingetragen sind, würden ins Leere laufen. Damit der Zugriff erhalten bleibt, wird die alte SID im Attribut `sIDHistory` des neuen Kontos abgelegt, und beim Anmelden erscheint sie im Zugriffstoken. So kann man Konten zuerst migrieren und die Ressourcen später umstellen. Die Methode hat Kosten: Jede alte SID vergrößert das Token, und die Dokumentation von Microsoft warnt vor *Token Bloat*, dem Überschreiten des Platzes im Token. Ihr Rat für belastete Umgebungen lautet sogar, Benutzer ohne SID-History zu migrieren und die neuen Konten stattdessen in die Ressourcengruppen der alten Umgebung aufzunehmen. Das Recht, SID-History zu übertragen, wird über ein eigenes erweitertes Recht gesteuert, und der Vorgang verlangt Administratorrechte in beiden Domänen. Bei Vertrauensstellungen zwischen Forests prüft die *SID-Filterung*, ob ein Token fremde SIDs enthält; sie ist ein Schutz gegen Rechteausweitung und muss für Migrationen bewusst und befristet angepasst werden.

Das klassische Werkzeug war das *Active Directory Migration Tool* (ADMT). Es migriert Benutzer, Gruppen, Computer, Profile und Kennwörter und kann SID-History schreiben. Die Dokumentation von Microsoft stellt jedoch klar: Der Code von ADMT 3.2 ist veraltet, es gibt keine Sicherheits- oder Fehlerkorrekturen mehr, und das Werkzeug ist nicht auf aktuelle Windows-Versionen (ab Windows Server 2012 R2 und Windows 8.1 aufwärts) ausgelegt. Es ist nicht mit den sicheren Standardeinstellungen moderner Systeme kompatibel, und der Support erfolgt nach bestem Bemühen. Heute setzt man deshalb entweder auf ältere, bewusst isolierte Migrationsumgebungen, auf Werkzeuge von Drittanbietern oder auf eine Migration über Metaverzeichnis-Anwendungen, die Konten in der neuen Umgebung anlegen und mit den alten abgleichen.

Unabhängig vom Werkzeug folgt eine saubere Migration einer festen Folge. Man beginnt mit der *Bestandsaufnahme*: welche Vertrauensstellungen bestehen, welche Konten haben bereits SID-History, welche Anwendungen verwenden SIDs, Konten oder Gruppen fest eingetragen, welche Dienstkonten laufen wo. Danach folgt der *Entwurf* der Zielstruktur mit Namensregeln und Rechtekonzept (Modul 4 und Abschnitt 12.8). Dann wird die Vertrauensstellung eingerichtet, getestet und die Namensauflösung zwischen beiden Umgebungen sichergestellt (Modul 6). In einem *Pilot* migriert man eine kleine Gruppe, prüft Anmeldung, Zugriff und Profile und legt den Rückweg fest. Die eigentliche Migration geht in *Wellen*: zuerst Gruppen, dann Benutzer, dann Computer und Server und zuletzt Ressourcen. Nach der Umstellung der Ressourcen entfernt man die SID-History, entzieht die Vertrauensstellung und stilllegt die alte Umgebung kontrolliert.

Ein Skript für die Bestandsaufnahme zeigt, welche Daten man als Erstes erhebt. Es liest Vertrauensstellungen mit ihrer SID-Filterung, Objekte mit vorhandener SID-History und schätzt die Tokengröße für ein Konto ab.

```powershell
# Bestandsaufnahme vor einer Migration (nur lesend)
Import-Module ActiveDirectory

# 1. Vertrauensstellungen mit SID-Filterung
Get-ADTrust -Filter * |
    Select-Object Name, Direction, TrustType, SIDFilteringQuarantined, SIDFilteringForestAware

# 2. Objekte, die bereits eine SID-History tragen
Get-ADObject -LDAPFilter "(sIDHistory=*)" -Properties sIDHistory |
    Select-Object Name, ObjectClass, @{n = "Anzahl"; e = { $_.sIDHistory.Count }}

# 3. Obere Abschaetzung der Tokengroesse eines Kontos
$u = Get-ADUser "anna.beispiel" -Properties tokenGroups, sIDHistory
$n = $u.tokenGroups.Count + $u.sIDHistory.Count
$max = 1200 + 40 * $n
"Gruppen- und History-SIDs: $n, Token hoechstens ca. $max Byte"
```

Schritt 1 listet alle Vertrauensstellungen mit Richtung und Typ (Forest, extern, Shortcut) und zeigt, ob die SID-Filterung aktiv ist. Schritt 2 findet alle Objekte, deren Attribut `sIDHistory` gefüllt ist; sie sind Hinweise auf frühere Migrationen und auf mögliche Altlasten. Schritt 3 liest das berechnete Attribut `tokenGroups`, das alle Gruppen-SIDs des Kontos enthält (auch verschachtelte), zählt die SID-History hinzu und schätzt die Tokengröße mit der von Microsoft veröffentlichten Faustformel nach oben ab: Grundwert 1200 Byte plus 40 Byte je Gruppe. Das ist bewusst pessimistisch, weil globale Gruppen der eigenen Domäne nur 8 Byte benötigen. Liegt der Wert in der Nähe der konfigurierten Höchstgröße, sollte man Gruppenmitgliedschaften aufräumen, bevor weitere SIDs hinzukommen.

### Typische Fehler und Stolperfallen

Der erste typische Fehler ist, die Migration an Konten und Computern zu orientieren und die Anwendungen zu vergessen. Anwendungen speichern Berechtigungen in eigenen Datenbanken, tragen Dienstkonten in Konfigurationsdateien ein oder prüfen Gruppen anhand des Namens. Sie funktionieren nach der Migration nicht, auch wenn die Anmeldung gelingt. Der zweite Fehler ist der Verzicht auf den Rückweg. Der dritte ist eine dauerhaft offene Vertrauensstellung mit abgeschalteter SID-Filterung.

```powershell
# FALSCH: Alle Benutzer an einem Wochenende migrieren, alte Domaene sofort abschalten
#   -> Anwendungen und Dienstkonten fallen aus, es gibt keinen Rueckweg

# RICHTIG: In Wellen migrieren, Rueckweg fest einplanen, Altumgebung erst nach
#   einer Haltefrist (z. B. 90 Tage) stilllegen, SID-Filterung nur befristet lockern
#   Inventar: Anwendungen, Dienstkonten, Gruppenverwendung, Freigaben, Skripte
```

Dieser Ablauf nimmt das Risiko in kleine Schritte auseinander: Jede Welle kann zurückgenommen oder korrigiert werden. Die Haltefrist gibt der Organisation Zeit, vergessene Abhängigkeiten zu entdecken.

> **Ergänzung aus der Nachrecherche**
>
> Die Unterscheidung von Upgrade und Migration, Intra- und Inter-Forest-Umstrukturierung, die Eigenschaften des Attributs `sIDHistory`, die Warnung vor Token Bloat und die Empfehlung, Benutzer ohne SID-History zu migrieren, stützen sich auf die abgerufenen Seiten „Active Directory Domain Services migration“ (Microsoft Learn Training), „AD DS Deployment Requirements“, „Planning for Compromise“ und „SID-History attribute“ (Microsoft Learn, Suchauszüge). Der Status von ADMT (Code veraltet, keine Korrekturen, nicht für aktuelle Windows-Versionen ausgelegt) ist der abgerufenen Seite „Support policy and known issues for Active Directory Migration Tool“ entnommen. Die Faustformel für die Tokengröße, die Wirkungsweise der SID-Filterung und die Wellenplanung stammen aus dem Fachwissen und sind für das eigene Vorhaben zu prüfen.

### Praxisbezug

> **Praxisbeispiel**
>
> Migrationen begegnen Ihnen bei Übernahmen und bei Konsolidierungen nach Jahren des Wachstums. Der wichtigste Erfolgsfaktor ist das Inventar der Abhängigkeiten, nicht das Werkzeug. Praktisch bewährt sich eine Tabelle, in der jede Anwendung einen Verantwortlichen, einen Testtermin und einen Rückweg hat. Auch Sicherungen (Modul 10) gehören in den Plan: Vor jeder Welle wird der Zustand der Quelle und des Ziels gesichert.

## 12.8 Governance

*Governance* bezeichnet die Regeln und Abläufe, mit denen eine Organisation sicherstellt, dass ihr Verzeichnis dauerhaft in gutem Zustand bleibt. Technisch kann ein Active Directory jahrelang laufen, ohne dass jemand es pflegt; inhaltlich verwildert es dann: Konten ehemaliger Mitarbeiter bleiben aktiv, Gruppen sammeln Mitglieder, ohne dass jemand weiß, wofür sie da sind, Administratoren behalten Rechte aus früheren Aufgaben, und Gruppenrichtlinien widersprechen sich. Governance beantwortet fünf Fragen: Wer darf was entscheiden, nach welchem Standard wird benannt und aufgebaut, wie läuft der Lebenszyklus von Konten, wie wird das überprüft, und was geschieht bei Ausnahmen?

Der erste Baustein sind *Namensstandards*. Konsistente Namen machen Objekte auffindbar und Automatisierung möglich: Benutzer nach dem Muster Vorname.Nachname, Gruppen mit Präfix für ihren Zweck (zum Beispiel `G-` für Rollengruppen, wie im Labor `G-Helpdesk`), Computer nach Standort und Funktion, Dienstkonten mit erkennbarem Präfix und Verantwortlichem. Zum Standard gehören auch die Struktur der Organisationseinheiten und die Regel, welche Objekte wohin gehören. Der zweite Baustein ist das *Rechtekonzept*: Berechtigungen werden an Gruppen vergeben, nicht an Personen (Modul 4); administrative Rechte folgen dem Prinzip der geringsten Rechte und dem Tiering-Modell (Modul 9); Delegationen sind schriftlich festgehalten. Der dritte Baustein sind *Gruppenrichtlinien*: Es gibt einen Eigentümer je Richtlinie, eine Namenskonvention, ein Änderungsverfahren mit Test und Rückweg und eine regelmäßige Bereinigung nicht verknüpfter Richtlinien (Modul 7).

Der vierte Baustein ist der *Lebenszyklus*, in der Praxis nach den Ereignissen Eintritt, Wechsel und Austritt gegliedert (englisch Joiner, Mover, Leaver). Beim Eintritt wird das Konto aus einer führenden Quelle (meist dem Personalsystem) angelegt, in die richtigen Gruppen eingetragen und mit einem Anfangskennwort versehen. Beim Wechsel der Abteilung werden alte Rechte entzogen und neue vergeben; hier entstehen am meisten Altlasten, weil das Entziehen vergessen wird. Beim Austritt wird das Konto zum vereinbarten Zeitpunkt gesperrt, später deaktiviert, nach einer Frist gelöscht (der Papierkorb aus Modul 10 sichert die Wiederherstellung) und aus der Cloud entfernt. Das Attribut `employeeLeaveDateTime` kann aus dem AD in die Cloud synchronisiert werden, um dort Lebenszyklus-Abläufe zu steuern; es wurde mit Entra Connect in Version 2.1.19.0 eingeführt.

Der fünfte Baustein sind *Reviews und Audits*. Regelmäßig, am besten vierteljährlich, werden privilegierte Gruppen, ruhende Konten, Konten mit nie ablaufendem Kennwort, Dienstkonten, leere und verwaiste Gruppen sowie Delegationen geprüft; Ergebnisse und Maßnahmen werden dokumentiert. Dazu kommt ein *Ausnahmeprozess*: Wer vom Standard abweichen muss, beantragt das schriftlich mit Begründung, Verantwortlichem, Kompensation und Ablaufdatum, und die Ausnahme wird zum Ablauf erneut geprüft. Ausnahmen ohne Ablaufdatum sind in Wahrheit neue Standards, die niemand beschlossen hat.

Das folgende Skript erzeugt aus den Daten des Active Directory einen kleinen Governance-Bericht: ruhende Konten, privilegierte Gruppenmitglieder, Konten mit nie ablaufendem Kennwort und Gruppen, deren Namen vom Standard abweichen. Es liest nur und schreibt die Ergebnisse in Dateien.

```powershell
# Governance-Bericht (nur lesend), Ausgabe als CSV im Berichtsordner
Import-Module ActiveDirectory
$ziel = "C:\Berichte\Governance"
New-Item -ItemType Directory -Path $ziel -Force | Out-Null
$datum = Get-Date -Format "yyyy-MM-dd"
$ou = "OU=Contoso,DC=corp,DC=contoso,DC=com"

# 1. Aktive Konten ohne Anmeldung seit 90 Tagen
Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -UsersOnly -SearchBase $ou |
    Where-Object { $_.Enabled } |
    Select-Object SamAccountName, LastLogonDate |
    Export-Csv "$ziel\ruhende-konten-$datum.csv" -NoTypeInformation -Encoding UTF8

# 2. Mitglieder privilegierter Gruppen
$privilegiert = "Domain Admins", "Enterprise Admins", "Schema Admins", "Administrators"
foreach ($g in $privilegiert) {
    Get-ADGroupMember $g -Recursive |
        Select-Object @{n = "Gruppe"; e = { $g }}, SamAccountName, objectClass
} | Export-Csv "$ziel\privilegierte-$datum.csv" -NoTypeInformation -Encoding UTF8

# 3. Konten mit nie ablaufendem Kennwort
Search-ADAccount -PasswordNeverExpires -UsersOnly -SearchBase $ou |
    Select-Object SamAccountName, Enabled |
    Export-Csv "$ziel\kennwort-ohne-ablauf-$datum.csv" -NoTypeInformation -Encoding UTF8

# 4. Gruppen, die den Namensstandard (Praefix G-) nicht einhalten
Get-ADGroup -SearchBase $ou -Filter * |
    Where-Object { $_.Name -notmatch '^G-[A-Za-z0-9-]+$' } |
    Select-Object Name, GroupCategory |
    Export-Csv "$ziel\namensabweichung-$datum.csv" -NoTypeInformation -Encoding UTF8
```

Die Variablen legen Berichtsordner, Datum und Suchbasis fest. Bericht 1 nutzt `Search-ADAccount` mit einer Zeitspanne von 90 Tagen; die Anmeldezeit im Attribut `lastLogonTimestamp` wird nur etwa alle 14 Tage aktualisiert und ist daher für Zeiträume von Wochen, nicht Tagen, geeignet. Bericht 2 durchläuft eine Liste der kritischen Gruppen und löst verschachtelte Mitglieder mit `-Recursive` auf; die Ausgabe der Schleife wird gesammelt in die Datei geschrieben. In Bericht 3 liefert `-PasswordNeverExpires` alle Konten mit dieser Eigenschaft; jedes dieser Konten braucht eine dokumentierte Begründung, etwa als Dienstkonto. Bericht 4 prüft mit einem regulären Ausdruck, ob der Gruppenname dem Standard entspricht. Die Dateien dienen als Grundlage für das Review, bei dem die Verantwortlichen jede Zeile bestätigen oder eine Maßnahme festlegen.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist ein Regelwerk, das nur auf dem Papier existiert. Standards, die nicht überprüft werden, verfallen innerhalb eines Jahres. Zweiter Fehler: Prüfungen ohne Konsequenz. Wird ein Bericht erstellt und nichts unternommen, wächst die Liste Quartal für Quartal. Dritter Fehler: Ausnahmen ohne Verfallsdatum.

```powershell
# FALSCH: Ausnahme ohne Frist im Beschreibungsfeld
Set-ADUser svc-alt -Description "Kennwort laeuft nicht ab (Ausnahme, bitte nicht aendern)"

# RICHTIG: Ausnahme mit Verantwortlichem und Ablaufdatum, zentral dokumentiert
Set-ADUser svc-alt -Description "AUSNAHME PasswordNeverExpires bis 2027-03-31, Verantw.: IT-Betrieb, Ticket 4711"
# Im Review: alle Beschreibungen mit AUSNAHME auflisten und Ablaufdaten pruefen
Get-ADUser -Filter 'Description -like "AUSNAHME*"' -Properties Description |
    Select-Object SamAccountName, Description
```

Die Beschreibung ist nur eine einfache Ablage; sie ersetzt keine zentrale Liste, macht aber die Ausnahme am Objekt sichtbar und im Review auffindbar. Wichtig ist, dass Zweck, Verantwortlicher und Frist zusammen erfasst sind.

> **Ergänzung aus der Nachrecherche**
>
> Die Bausteine der Governance (Namensstandards, Rechtekonzept, Gruppenrichtlinien-Verwaltung, Lebenszyklus, Reviews, Ausnahmen) beruhen auf der allgemeinen Fachpraxis und den Grundlagen der früheren Module; hierfür gibt es keine einzelne Quelle, und Details sind an die Organisation anzupassen. Das Attribut `employeeLeaveDateTime` und seine Einführung mit Entra Connect Version 2.1.19.0 sind der abgerufenen Seite „Microsoft Entra Connect: Version release history“ entnommen. Die Aktualisierung von `lastLogonTimestamp` etwa alle 14 Tage ist Fachwissen. *Datenschutz (keine Rechtsberatung):* Berichte über Anmeldungen und Gruppenmitgliedschaften sind Auswertungen personenbezogener Daten; Zweck, Zugriff und Aufbewahrung sind mit dem Datenschutz und gegebenenfalls dem Betriebsrat abzustimmen.

### Praxisbezug

> **Praxisbeispiel**
>
> In Audits und Zertifizierungen fragt die Prüferin als Erstes nach dem Vorgehen, nicht nach der Technik: Wer genehmigt Administratorrechte, wann wurde zuletzt geprüft, was geschieht bei einem Austritt? Ein einfacher Quartalsbericht mit abgezeichneten Maßnahmen beantwortet diese Fragen besser als jede nachträglich geschriebene Richtlinie. In kleineren Teams genügt ein gemeinsames Dokument mit festen Terminen im Betriebskalender.

## 12.9 Betriebsroadmap

Eine *Betriebsroadmap* legt fest, was in welchem Rhythmus getan wird, damit die Identitätsumgebung nicht vom Zufall abhängt. Sie verbindet die Inhalte der letzten Module zu einem Plan: Sicherheit (Modul 9), Sicherung und Wiederherstellung (Modul 10), Überwachung (Modul 11) und die Hybrid-Komponenten dieses Moduls. Ziel ist, dass jede Aufgabe einen Takt, einen Verantwortlichen und ein Ergebnis hat, und dass Erneuerungen, die man Jahre im Voraus kennt (Betriebssystem, Zertifikate, Softwarestände), rechtzeitig angestoßen werden.

Die Roadmap besteht aus zwei Teilen. Der erste ist der *laufende Betrieb* in festen Takten. Täglich prüft man die automatische Zustandsprüfung (Modul 11): Replikation, Dienste, Ereignisse, Sicherung. Wöchentlich schaut man auf die Warnmeldungen des Synchronisierungsdienstes (Connect Health oder die Meldungen im Entra-Portal), auf Konten mit Sperrungen und auf offene Änderungen. Monatlich werden Updates der Domänencontroller und der Server der Synchronisierung eingespielt, die Basislinie der Leistung wird mit den aktuellen Werten verglichen, und die Verfügbarkeit der Sicherungen wird anhand einer Stichprobe der Wiederherstellung belegt. Vierteljährlich folgt das Governance-Review (Abschnitt 12.8), die Prüfung privilegierter Gruppen und die Kontrolle der Zertifikate. Jährlich übt man die Wiederherstellung und die Notfallpläne aus Modul 10, überprüft die Dokumentation und die Konzepte und aktualisiert die Planung.

Der zweite Teil ist der *Veränderungsplan*, der die großen Themen zeitlich ordnet. Dazu gehören die Betriebssystemversionen der Domänencontroller (rechtzeitig vor Ende des Supports durch neue Domänencontroller ersetzen und danach das funktionale Niveau anheben), die Versionen von Entra Connect und der Agenten (Fristen beachten, siehe unten), die Weiterentwicklung der Anmeldeverfahren (Abschnitt 12.3 bis 12.6), die Ablösung veralteter Protokolle wie NTLM und unsignierter LDAP-Bindungen (Modul 8 und 9) und größere Umbauten wie Migrationen. Dabei sind Abhängigkeiten zu beachten: Man prüft vor dem Ersetzen eines Domänencontrollers, ob Dienste wie die Synchronisierung oder Anwendungen ihn fest eingetragen haben, und man ändert keine UPN-Struktur während einer Migration.

Wie wichtig der Blick auf Versionsstände ist, zeigt Entra Connect selbst. Version 1 ist abgeschaltet, und die Versionsseite von Microsoft nennt zum Zeitpunkt der Recherche eine verpflichtende Aktualisierung bis April 2027. Eine Roadmap enthält deshalb für jede Komponente den aktuellen Stand, den Stichtag für Supportende oder Pflicht-Update und den geplanten Termin der Umstellung. Auch die Zukunft von Cloud Sync gehört hinein: Wer heute Entra Connect betreibt, plant einen Prüftermin, an dem erneut verglichen wird, ob die eigenen Anforderungen von Cloud Sync erfüllt werden.

Zur Absicherung der Roadmap gehört ein kleiner, automatisierter Tagesbericht. Er verbindet die Prüfungen aus Modul 11 mit dem Zustand der Synchronisierung und liefert eine Zeile je Prüfpunkt mit Ampelfarbe.

```powershell
# Tagesbericht: Zustand der Identitaetsumgebung (ausfuehren auf DC01, Remote auf SRV02)
Import-Module ActiveDirectory
$ergebnis = @()

function Pruefpunkt($name, $ok, $detail) {
    [pscustomobject]@{ Pruefung = $name; Status = $(if ($ok) { "OK" } else { "FEHLER" }); Detail = $detail }
}

# 1. Domaenencontroller erreichbar und Dienste laufen
foreach ($dc in (Get-ADDomainController -Filter *)) {
    $dienste = Get-Service -ComputerName $dc.HostName -Name NTDS, Netlogon, DNS -ErrorAction SilentlyContinue
    $laeuft = ($dienste | Where-Object Status -ne "Running").Count -eq 0 -and $dienste.Count -eq 3
    $ergebnis += Pruefpunkt ("Dienste " + $dc.Name) $laeuft ($dienste.Status -join ",")
}

# 2. Replikation: Anzahl der Fehler
$fehler = (Get-ADReplicationFailure -Target corp.contoso.com -Scope Domain -ErrorAction SilentlyContinue | Measure-Object).Count
$ergebnis += Pruefpunkt "Replikationsfehler" ($fehler -eq 0) "$fehler Fehler"

# 3. Synchronisierung auf SRV02: Scheduler aktiv, naechster Lauf geplant
$sync = Invoke-Command -ComputerName SRV02 -ScriptBlock { Import-Module ADSync; Get-ADSyncScheduler }
$ergebnis += Pruefpunkt "Sync-Scheduler" ($sync.SyncCycleEnabled -and -not $sync.StagingModeEnabled) "naechster Lauf: $($sync.NextSyncCycleStartTimeInUTC)"

$ergebnis | Format-Table -AutoSize
```

Die Funktion `Pruefpunkt` erzeugt je Prüfung ein Objekt mit Name, Status und Detail; damit entsteht am Ende eine einheitliche Tabelle. Der erste Block ruft für jeden Domänencontroller drei Dienste ab und bewertet ihn nur dann als in Ordnung, wenn alle drei laufen. Der zweite Block zählt mit `Get-ADReplicationFailure` die gemeldeten Replikationsfehler; ohne Fehler ist die Anzahl null. Der dritte Block fragt mit `Invoke-Command` den Scheduler auf dem Synchronisierungsserver ab und erwartet, dass der Zyklus aktiv und der Server *nicht* im Staging Mode ist (auf einem Ersatzserver wäre es umgekehrt). `Format-Table` gibt die Tabelle aus; in der Praxis würde man das Ergebnis per Aufgabenplanung täglich erzeugen und bei Fehlern eine Meldung auslösen.

### Typische Fehler und Stolperfallen

Roadmaps scheitern selten an der Technik, sondern an der Verbindlichkeit. Typische Fehler sind Aufgaben ohne Verantwortliche, Termine ohne Erinnerung und Änderungen, die nur im Kopf einer Person existieren. Ein weiterer häufiger Fehler ist das Aufschieben von Pflichtwartungen, bis ein Stichtag zum Notfall wird: Wer erst nach dem Ausfall merkt, dass die Synchronisierung auf einem nicht mehr unterstützten Stand läuft, hat keine Zeit mehr zum Testen.

```powershell
# FALSCH: "Updates machen wir bei Gelegenheit"
#   -> unbekannter Stand, Pflichtfristen werden verpasst

# RICHTIG: Komponentenliste mit Stand, Stichtag und Termin (hier als Skizze)
$komponenten = @(
    [pscustomobject]@{ Name = "Entra Connect (SRV02)"; Stand = "pruefen"; Stichtag = "laut Versionsseite"; Termin = "2027-Q1" },
    [pscustomobject]@{ Name = "DC01 Betriebssystem";   Stand = "pruefen"; Stichtag = "Supportende";       Termin = "nach Plan" }
)
$komponenten | Export-Csv "C:\Berichte\Roadmap.csv" -NoTypeInformation -Encoding UTF8
```

Die Skizze zeigt nur das Prinzip: Jede Komponente hat einen aktuellen Stand, einen Stichtag und einen Termin. In der Praxis liegt diese Liste in einem Ticketsystem oder einer Tabelle mit Verantwortlichen und Erinnerungen.

> **Ergänzung aus der Nachrecherche**
>
> Die Angaben zu Fristen und Versionen von Entra Connect (Version 1 abgeschaltet, verpflichtende Aktualisierung bis April 2027, automatische Aktualisierung bei Express-Installationen) stützen sich auf die abgerufenen Seiten „Microsoft Entra Connect: Version release history“ und „Installation roadmap“ (Microsoft Learn, Suchauszüge); Termine ändern sich und sind vor Verwendung zu prüfen. Die Takte und Aufgabenlisten der Roadmap sowie die Funktion `Get-ADReplicationFailure` im Skript stammen aus der Fachpraxis bzw. dem Fachwissen. Empfehlungen zum Betrieb von Synchronisierungsservern als Tier-0-Systeme und zur Überwachung ihrer Protokolle stehen auf der abgerufenen Seite „Security operations for infrastructure“.

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Betriebsroadmap ist das Dokument, das Sie bei der Übernahme einer Umgebung zuerst suchen und bei der Übergabe an Nachfolger zuletzt aktualisieren. Sie macht Kosten und Personalbedarf planbar, weil sie zeigt, wann welcher Aufwand entsteht. In Gesprächen mit der Geschäftsleitung ist sie das Mittel, Investitionen zu begründen: Ein Server, der in zwölf Monaten das Supportende erreicht, ist kein Wunsch der IT, sondern ein Termin.

## 12.10 Übungsaufgaben zu Modul 12

**Aufgabe 12.1** Erklären Sie in eigenen Worten den Begriff Hybrid Identity. Was bedeuten „Source of Authority“ und „Provisioning“, und warum behandelt man die Synchronisierungsserver wie Domänencontroller?

**Aufgabe 12.2** Ein Unternehmen betreibt die Domäne `firma.local`. Es möchte Microsoft 365 einführen. Welches Problem tritt auf, und welche Schritte sind nötig, damit sich die Benutzer in der Cloud anmelden können?

**Aufgabe 12.3** Beschreiben Sie die Bestandteile der Synchronisierungs-Engine von Entra Connect (Connector, Connector Space, Metaverse, Source Anchor) und die drei Schritte eines Synchronisierungslaufs. Welche Schritte sind nach einer Änderung des OU-Filters nötig, welche nach einer Änderung einer Regel?

**Aufgabe 12.4** Vergleichen Sie Password Hash Sync und Pass-through Authentication anhand von vier Merkmalen (Ort der Prüfung, Abhängigkeit vom lokalen Netz, Verhalten bei Kennwortablauf, zusätzliche Server). Wann würden Sie welches Verfahren empfehlen?

**Aufgabe 12.5** Ein Arbeitsplatz ist Mitglied der Domäne, erscheint aber in Entra ID nicht als hybrid-joined. Nennen Sie fünf mögliche Ursachen und beschreiben Sie, wie Sie die Diagnose mit `dsregcmd /status` beginnen.

**Aufgabe 12.6** Ein Unternehmen mit zwei getrennten AD-Forests, die nicht verbunden werden können, soll an einen Mandanten angeschlossen werden. Welches Verfahren eignet sich, und welche Grenzen und Voraussetzungen müssen Sie prüfen? Wie gehen Sie bei der Umstellung von Entra Connect vor, damit sich beide Werkzeuge nicht gegenseitig stören?

**Aufgabe 12.7** **Praxis:** Schreiben Sie ein PowerShell-Skript, das in der OU `Contoso` alle Benutzer findet, deren UPN nicht auf `@contoso.com` endet, sie mit `-WhatIf` auf `Vorname.Nachname@contoso.com` (aus den Attributen `GivenName` und `Surname`) umstellt und Benutzer ohne Vor- oder Nachnamen in einer Datei `upn-ausnahmen.csv` ausgibt.

**Aufgabe 12.8** **Praxis:** Schreiben Sie ein Skript für eine Migrationsvorbereitung. Es listet für alle Benutzer mit gefüllter `sIDHistory` den Namen und die Anzahl der Einträge, schätzt für jeden dieser Benutzer die Tokengröße nach der Formel 1200 + 40 mal Anzahl der Gruppen-SIDs (einschließlich der History) und markiert Konten über 12000 Byte.

## 12.11 Lösungen zu den Übungsaufgaben

**Lösung 12.1.** Hybrid Identity bezeichnet eine gemeinsame Benutzeridentität für lokale und Cloud-Ressourcen, die durch Provisioning und Synchronisierung entsteht. Provisioning heißt, Objekte unter bestimmten Bedingungen in der Cloud anzulegen, aktuell zu halten und zu entfernen, wenn die Bedingungen entfallen. Die Source of Authority ist die Quelle, die für ein Objekt maßgeblich ist, meist das lokale AD. Die Synchronisierungsserver bündeln die Rechte, um Identitäten in beiden Welten zu lesen und zu verändern (Replikationsrechte im AD, Administratorrechte im Mandanten) und bei PTA sehen die Agenten sogar Kennwörter im Klartext. Wer sie übernimmt, kann Konten manipulieren; deshalb gehören sie in Tier 0 (Modul 9).

**Lösung 12.2.** Die Domäne `firma.local` ist nicht routingfähig, daher kann sie im Mandanten nicht verifiziert werden. Anmeldenamen mit diesem Suffix sind in Microsoft 365 nicht verwendbar. Schritte: eine eigene Internetdomäne (zum Beispiel `firma.at`) im Mandanten verifizieren, im Forest als alternatives UPN-Suffix hinzufügen (`Set-ADForest -UPNSuffixes`), die Benutzer auf das neue Suffix umstellen (vorher ankündigen, zur Probe mit `-WhatIf`), doppelte UPNs und fehlerhafte Attribute (`proxyAddresses`, `mail`) bereinigen und erst danach die Synchronisierung einrichten.

**Lösung 12.3.** Ein Connector verbindet die Engine mit einem Verzeichnis (AD oder Entra ID). Der Connector Space ist die lokale Zwischenablage der importierten Objekte. Das Metaverse ist die vereinte Sicht; Objekte aus beiden Connector Spaces werden über den Source Anchor, den unveränderlichen Schlüssel (meist `mS-DS-ConsistencyGuid`), zusammengeführt. Ein Lauf besteht aus Import, Synchronisierung (Regeln anwenden) und Export. Nach einer Änderung des OU-Filters ist ein vollständiger Import (Full Import) mit anschließender Delta-Synchronisierung nötig; nach einer Änderung von Regeln oder Attributfiltern genügt eine vollständige Synchronisierung (Full Sync). Im Zweifel führt man auf dem Staging-Server einen Initial-Zyklus aus und prüft die anstehenden Exporte.

**Lösung 12.4.** Bei PHS prüft die Cloud selbst (Ableitung des Hashs liegt dort), bei PTA prüft ein lokaler Agent gegen den Domänencontroller. PHS ist unabhängig vom lokalen Netz, PTA braucht erreichbare Agenten und Domänencontroller. Bei PHS werden Kennwortablauf und Kontoablauf lokal nicht übernommen (Cloud-Kennwort läuft standardmäßig nie ab), bei PTA gelten die lokalen Regeln unmittelbar, weil jede Anmeldung lokal geprüft wird. PHS braucht keinen zusätzlichen Server, PTA mindestens zwei Agenten auf Tier-0-gehärteten Servern. Empfehlung: PHS als Regelfall (einfach, robust, Erkennung bekannter Zugangsdaten), PTA, wenn Kennwortableitungen nicht in die Cloud sollen oder lokale Regeln unmittelbar gelten müssen; häufig mit PHS als zusätzliche Option.

**Lösung 12.5.** Mögliche Ursachen: keine Sichtverbindung zum Domänencontroller; Service Connection Point fehlt oder zeigt auf den falschen Mandanten; Computerobjekt nicht im Synchronisierungsumfang (OU-Filter) oder noch nicht synchronisiert; Registrierungsendpunkte (`enterpriseregistration.windows.net`, `login.microsoftonline.com`) im Systemkontext nicht erreichbar (Proxy, Firewall); nicht unterstütztes Betriebssystem oder Server Core; nicht routingfähiges UPN-Suffix in einer verwalteten Umgebung; Image oder Snapshot von einem bereits registrierten Gerät. Diagnose: `dsregcmd /status` in einer erhöhten Eingabeaufforderung starten, `DomainJoined` und `AzureAdJoined` prüfen, im Abschnitt der Diagnose vor dem Beitritt den fehlgeschlagenen Test und den Fehlercode lesen (zum Beispiel `0x801c001d` für den SCP) und ergänzend das Ereignisprotokoll „User Device Registration“ auswerten.

**Lösung 12.6.** Cloud Sync, weil es mehrere getrennte Forests ohne Konsolidierung unterstützt, während Connect dafür nicht ausgelegt ist. Zu prüfen sind die Grenzen (derzeit 150 000 Objekte je Domäne, 50 000 Mitglieder je Gruppe), benötigte Funktionen (keine erweiterten Synchronisierungsregeln, kein Gerätezurückschreiben, keine AD-FS-Einrichtung, Verweise wie Manager müssen innerhalb der Domäne liegen), die Anzahl und Platzierung der Agenten (mindestens zwei je Umgebung) und die Eignung für das geführte Migrationswerkzeug. Bei der Umstellung führt man eine Pilotgruppe, richtet die Schutzregeln (`cloudNoFlow`, `JoinNoFlow`) ein, damit Connect für die Pilotobjekte nichts exportiert, kontrolliert Gruppenmitgliedschaften und Verweise und reduziert den Umfang von Connect erst, wenn Cloud Sync alle Objekte bereitstellt.

**Lösung 12.7.** Eine mögliche Lösung:

```powershell
Import-Module ActiveDirectory
$ou = "OU=Contoso,DC=corp,DC=contoso,DC=com"
$suffix = "contoso.com"
$benutzer = Get-ADUser -Filter * -SearchBase $ou -Properties UserPrincipalName, GivenName, Surname |
    Where-Object { $_.UserPrincipalName -notlike "*@$suffix" }

$ausnahmen = @()
foreach ($b in $benutzer) {
    if ($b.GivenName -and $b.Surname) {
        $neu = ($b.GivenName + "." + $b.Surname + "@" + $suffix).Replace(" ", "")
        Set-ADUser $b -UserPrincipalName $neu -WhatIf
    } else {
        $ausnahmen += $b | Select-Object SamAccountName, UserPrincipalName
    }
}
$ausnahmen | Export-Csv "upn-ausnahmen.csv" -NoTypeInformation -Encoding UTF8
```

Das Skript filtert Benutzer mit abweichendem Suffix, bildet den neuen UPN aus Vor- und Nachname (Leerzeichen entfernt), zeigt die Umstellung dank `-WhatIf` nur an und schreibt Konten ohne vollständigen Namen in die CSV-Datei. Bevor man `-WhatIf` entfernt, sind doppelte neue Namen (zum Beispiel zwei Personen mit gleichem Namen) und Sonderzeichen zu prüfen; das Suffix muss vorher im Forest hinzugefügt sein.

**Lösung 12.8.** Eine mögliche Lösung:

```powershell
Import-Module ActiveDirectory
Get-ADUser -LDAPFilter "(sIDHistory=*)" -Properties sIDHistory, tokenGroups |
    ForEach-Object {
        $anzahl = $_.tokenGroups.Count + $_.sIDHistory.Count
        $token = 1200 + 40 * $anzahl
        [pscustomobject]@{
            Name        = $_.SamAccountName
            HistoryAnz  = $_.sIDHistory.Count
            SIDsGesamt  = $anzahl
            TokenMax    = $token
            Markiert    = $token -gt 12000
        }
    } | Sort-Object TokenMax -Descending | Format-Table -AutoSize
```

Der LDAP-Filter liefert alle Benutzer mit gefülltem `sIDHistory`. `tokenGroups` enthält alle Gruppen-SIDs des Kontos, die History wird hinzugezählt. Die Formel liefert eine pessimistische obere Abschätzung (40 Byte je SID); Werte über 12000 Byte werden markiert, damit man die Gruppenmitgliedschaften dieser Konten vor der Migration bereinigt.
