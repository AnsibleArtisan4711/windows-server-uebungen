# Modul 07 - Gruppenrichtlinien und zentrale Konfiguration

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Tabellen als Markdown-Tabellen, Übungsaufgaben und Lösungen als Absätze). Die Überschriften sind wie in der Quelle nach Modul und Lerneinheit nummeriert (7.1 bis 7.9; 7.10 Übungsaufgaben, 7.11 Lösungen). **Die PowerShell-Beispiele wurden für dieses Repository nicht ausgeführt**; sie setzen eine Windows-Server-Laborumgebung mit der fiktiven Domain `corp.contoso.com` voraus und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain. Übersicht zum Modul: [README](README.md).

|                                       |              |
|:--------------------------------------|:-------------|
| Dauer laut Modulübersicht             | 12 Stunden   |
| Summe der Lerneinheiten (Detailblatt) | 10,5 Stunden |
| Priorität                             | 1            |

| Nr. | Lerneinheit               | Dauer (h) | Prio |
|----:|:--------------------------|----------:|-----:|
| 7.1 | GPO Grundlagen            |         1 |    1 |
| 7.2 | GPO Verknüpfung           |         1 |    1 |
| 7.3 | Vererbung und Blockierung |       1,5 |    1 |
| 7.4 | Enforced GPOs             |         1 |    1 |
| 7.5 | Security Filtering        |         1 |    1 |
| 7.6 | WMI Filtering             |       1,5 |    1 |
| 7.7 | Administrative Templates  |         1 |    2 |
| 7.8 | Group Policy Preferences  |         1 |    2 |
| 7.9 | RSoP und gpresult         |       1,5 |    2 |
|     | **Summe**                 |  **10,5** |      |

> **Merke**
>
> Die Stundensumme der Lerneinheiten im Detailblatt (10,5 h) weicht von der Dauer in der Modulübersicht (12 h) ab. Dieses Skript behandelt alle Lerneinheiten des Detailblatts vollständig; die Abweichung ist im Lehrplan selbst zu klären.

Mit *Gruppenrichtlinien* (Group Policy) steuert man Einstellungen und Sicherheitsvorgaben für tausende Benutzer und Computer zentral. Wer sie beherrscht, kann Kennwortregeln, Firewall-Einstellungen, Laufwerkszuordnungen, Software-Verteilung und Hunderte weitere Optionen an einer Stelle festlegen, statt jeden Rechner einzeln einzurichten. Wer sie nicht beherrscht, erzeugt Konfigurationen, die niemand mehr versteht: Einstellungen, die sich überlagern, Richtlinien, die nicht ankommen, und Anmeldungen, die durch überladene Richtlinien Minuten dauern. Das Modul beginnt deshalb mit den Grundlagen und der Verarbeitungsreihenfolge, behandelt die Mittel zur Steuerung (Verknüpfung, Vererbung, Blockierung, Erzwingung, Filter) und schließt mit den Werkzeugen für die Fehlersuche.

Die Beispiele verwenden die OU-Struktur aus Modul 3 (`OU=Contoso` mit den Unter-OUs `Benutzer`, `Computer`, `Gruppen`, `Dienstkonten`). Für die Verwaltung wird das PowerShell-Modul `GroupPolicy` verwendet, das mit den Verwaltungswerkzeugen für Gruppenrichtlinien (GPMC) installiert wird.

## 7.1 GPO Grundlagen

Ein *Gruppenrichtlinienobjekt* (Group Policy Object, GPO) ist eine Sammlung von Einstellungen, die man an Benutzer oder Computer verteilt. Es besteht aus zwei Teilen, die an verschiedenen Orten liegen. Der *Gruppenrichtlinien-Container* (GPC) ist ein Objekt im Active Directory (im Container `CN=Policies,CN=System`); er enthält Verwaltungsdaten wie Name, Version und Status. Die *Gruppenrichtlinienvorlage* (Group Policy Template, GPT) ist ein Ordner in SYSVOL unter `Policies` und enthält die eigentlichen Einstellungen als Dateien (Registrierungseinträge, Skripte, Sicherheitsvorlagen). Die Microsoft-Dokumentation beschreibt, dass die beiden Teile durch zwei *voneinander unabhängige Mechanismen* repliziert werden: der AD-Teil durch die normale AD-Replikation (innerhalb einer Site meist in weniger als einer Minute) und der SYSVOL-Teil durch DFSR (innerhalb einer Site alle 15 Minuten, zwischen Sites nach Topologie und Zeitplan). Daher kann es nach einer Änderung kurzzeitig zu Inkonsistenzen kommen.

Jedes GPO hat zwei Konfigurationsteile: die *Computerkonfiguration*, die gilt, wenn der Computer startet, und die *Benutzerkonfiguration*, die gilt, wenn sich ein Benutzer anmeldet. Die Dokumentation fasst es zusammen: Richtlinien für Computer werden beim Start angewendet, die für Benutzer bei der Anmeldung (die *Vordergrundverarbeitung*); danach aktualisiert das System die Richtlinien regelmäßig im Hintergrund. Standardmäßig erfolgt die Aktualisierung alle 90 Minuten, zu denen eine zufällige Zeit von bis zu 30 Minuten hinzukommt; Domain Controller prüfen alle fünf Minuten. Nicht jede Erweiterung wird im Hintergrund verarbeitet: Ordnerumleitung greift zum Beispiel nur bei der Anmeldung, Skripte laufen nur beim Starten, Herunterfahren, Anmelden und Abmelden. Die gesamte Verarbeitung muss innerhalb von 60 Minuten abgeschlossen sein. Sofort aktualisieren lässt sich mit `gpupdate`, mit dem Cmdlet `Invoke-GPUpdate` oder im GPMC mit „Gruppenrichtlinienaktualisierung“ auf einer OU.

Zwei GPOs sind in jeder Domain vorhanden: die *Default Domain Policy*, die mit der Domain verknüpft ist und vor allem die Kennwort-, Sperr- und Kerberos-Richtlinien der Domain enthält, und die *Default Domain Controllers Policy*, die mit der OU „Domain Controllers“ verknüpft ist und die Sicherheitseinstellungen für Domain Controller enthält. Diese beiden GPOs sollte man nur für die Einstellungen ändern, für die sie gedacht sind (Kennwortrichtlinien beziehungsweise Rechte der Domain Controller). Für alles andere legt man *eigene* GPOs an. So bleiben die Standard-GPOs übersichtlich und lassen sich im Notfall mit dem Werkzeug `dcgpofix` auf den Auslieferungszustand zurücksetzen.

Für den professionellen Umgang gelten ein paar Grundregeln. Jedes GPO erhält einen *sprechenden Namen* nach einer Konvention, zum Beispiel `C-Sicherheit-Firewall` (C = Computer, B = Benutzer) und eine Beschreibung mit Zweck und Verantwortlichem. Man fasst Einstellungen *thematisch* zusammen (ein GPO für BitLocker, eins für Windows Update), statt ein riesiges GPO für alles zu bauen. Ist in einem GPO nur der Computer- oder nur der Benutzerteil gefüllt, deaktiviert man den leeren Teil, weil dann die Verarbeitung schneller geht. Änderungen werden vorher in einer Testumgebung geprüft, und vor jeder Änderung wird eine Sicherung angelegt. Das folgende Skript führt diese Schritte aus: Es erzeugt ein GPO, setzt eine Einstellung, deaktiviert den nicht benötigten Teil, erzeugt eine Sicherung und einen HTML-Bericht.

```powershell
Import-Module GroupPolicy

# 1) Neues GPO anlegen (noch nicht verknuepft) mit Beschreibung
$gpo = New-GPO -Name "C-Sicherheit-Bildschirmsperre" `
        -Comment "Bildschirmsperre nach 10 Minuten. Verantwortlich: IT-Sicherheit (M. Huber)"

# 2) Eine Registrierungseinstellung setzen (Richtlinienwert unter HKLM\SOFTWARE\Policies)
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "InactivityTimeoutSecs" -Type DWord -Value 600

# 3) Nicht benoetigten Benutzerteil deaktivieren (schnellere Verarbeitung)
$gpo.GpoStatus = "UserSettingsDisabled"

# 4) Sicherung anlegen und Bericht erzeugen
New-Item -ItemType Directory -Path "D:\GPO-Backup" -Force | Out-Null
Backup-GPO -Name $gpo.DisplayName -Path "D:\GPO-Backup" -Comment "Vor Aenderung"
Get-GPOReport -Name $gpo.DisplayName -ReportType Html -Path "D:\GPO-Backup\$($gpo.DisplayName).html"

# 5) Alle GPOs der Domain mit Status und Aenderungsdatum
Get-GPO -All | Select-Object DisplayName, GpoStatus, ModificationTime | Sort-Object ModificationTime -Descending
```

Schritt 1 legt das GPO an; der Parameter `-Comment` nimmt die Beschreibung auf. Schritt 2 setzt einen Registrierungswert in der Computerkonfiguration; eine Einstellung kann auch im Gruppenrichtlinien-Editor gesetzt werden, das Cmdlet ist aber für Skripte und reproduzierbare Konfigurationen praktisch. Der Wert `InactivityTimeoutSecs` (in Sekunden) steuert die Sperre des Bildschirms nach Inaktivität; 600 entspricht zehn Minuten. Schritt 3 deaktiviert den Benutzerteil. Schritt 4 sichert das GPO in einen Ordner und erstellt einen Bericht, der alle Einstellungen im Klartext auflistet. Schritt 5 gibt eine Übersicht über alle GPOs der Domain aus, geordnet nach Änderungsdatum; so erkennt man unbenutzte und zuletzt geänderte Objekte.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, Einstellungen in der *Default Domain Policy* zu sammeln, weil sie ohnehin überall gilt. Dort verliert man schnell die Übersicht, und eine fehlerhafte Änderung betrifft sofort die ganze Domain. Der zweite Fehler ist ein Sammel-GPO ohne Struktur („Neue Richtlinie 1“) mit hundert Einstellungen und ohne Beschreibung; niemand kann später sagen, warum eine Einstellung existiert. Ein dritter Fehler ist, GPOs im Produktionsbetrieb direkt zu ändern, ohne vorher zu sichern oder zu testen.

```powershell
# FALSCH: Neue Einstellung direkt in die Default Domain Policy, ohne Sicherung
Set-GPRegistryValue -Name "Default Domain Policy" -Key "HKLM\SOFTWARE\Policies\Contoso" -ValueName "Test" -Type DWord -Value 1

# RICHTIG: Eigenes, benanntes GPO; vorher sichern; zuerst an einer Test-OU verknuepfen
Backup-GPO -Name "C-Sicherheit-Bildschirmsperre" -Path "D:\GPO-Backup"
New-GPLink -Name "C-Sicherheit-Bildschirmsperre" -Target "OU=Test,OU=Computer,OU=Contoso,DC=corp,DC=contoso,DC=com"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen mit 800 Arbeitsplätzen übernimmt eine IT-Abteilung, in der zuvor 70 GPOs ohne Namenskonvention entstanden waren. Das Team erzeugt mit `Get-GPOReport` für alle GPOs einen Bericht, gruppiert die Einstellungen nach Thema, ersetzt sie durch 12 klar benannte GPOs und sichert den alten Stand. Die Anmeldezeit sinkt von über 90 auf etwa 30 Sekunden, weil überflüssige und leere GPOs nicht mehr verarbeitet werden.

## 7.2 GPO Verknüpfung

Ein GPO tut nichts, solange es nicht *verknüpft* ist. Die Verknüpfung (Link) legt fest, *wo* im Active Directory das GPO wirkt: an einem *Standort* (Site), an der *Domain* oder an einer *Organisationseinheit* (OU). Dieselbe GPO kann an mehreren Stellen verknüpft sein, und an derselben Stelle können mehrere GPOs verknüpft sein. Wichtig ist: Das GPO gilt für alle *Benutzer- und Computerobjekte, die in dem Container (oder in dessen Unter-Containern) liegen*. Die Einstellung der Computerkonfiguration wirkt auf die Computerkonten, die der Benutzerkonfiguration auf die Benutzerkonten, und zwar aufgrund des *Ortes des Kontos im Verzeichnis*, nicht aufgrund des Orts, an dem der Benutzer arbeitet. Ein Benutzer in der OU „Vertrieb“ erhält die Benutzereinstellungen der OU „Vertrieb“, egal an welchem Computer er sich anmeldet (außer es gilt der Schleifenrückverarbeitungsmodus, siehe Lerneinheit 7.3).

Eine Verknüpfung hat drei Eigenschaften, die man kennen muss. Die *Reihenfolge* (Link Order) bestimmt bei mehreren GPOs am selben Container, welches Vorrang hat: Die Dokumentation hält fest, dass das GPO mit der *niedrigsten* Nummer (Position 1) Vorrang hat. Die Eigenschaft *Verknüpfung aktiviert* (Link Enabled) schaltet die Wirkung der Verknüpfung ab, ohne sie zu löschen; das ist die bevorzugte Methode, ein GPO vorübergehend außer Kraft zu setzen. Und die Eigenschaft *Erzwungen* (Enforced, Lerneinheit 7.4) macht die Einstellungen unabhängig von Blockierungen und Vorrang in tieferen Ebenen wirksam.

Eine häufig diskutierte Frage ist, *wo* man verknüpfen soll. Als Regel gilt: so *tief* wie möglich, so *hoch* wie nötig. Verknüpfungen an der Domain sind für wirklich allgemeine Einstellungen gedacht (zum Beispiel Kennwortrichtlinie, Zeitquelle). Einstellungen für Server, Arbeitsplätze oder Abteilungen gehören an die jeweiligen OUs. Verknüpfungen an Sites sind selten und nur sinnvoll, wenn Einstellungen vom Standort abhängen (zum Beispiel Proxy-Einstellungen); sie sind außerdem fehleranfällig, weil Sites unabhängig von der OU-Struktur sind und die Wirkung deshalb schwer zu sehen ist. Gruppenrichtlinien funktionieren *nicht* für beliebige Sicherheitsgruppen: Man kann sie weder an Gruppen noch an den Standardcontainern „Users“ und „Computers“ verknüpfen. Dies ist ein Grund, die OU-Struktur sorgfältig zu planen (Modul 3).

Das folgende Skript verknüpft zwei GPOs an einer OU, setzt die Reihenfolge, deaktiviert eine Verknüpfung vorübergehend und zeigt alle Verknüpfungen eines Containers. Außerdem findet es GPOs, die *nirgends verknüpft* sind.

```powershell
Import-Module GroupPolicy
$ou = "OU=Arbeitsplaetze,OU=Computer,OU=Contoso,DC=corp,DC=contoso,DC=com"

# 1) Zwei GPOs an die OU verknuepfen; Reihenfolge 1 = hoechste Prioritaet
New-GPLink -Name "C-Sicherheit-Bildschirmsperre" -Target $ou -LinkEnabled Yes -Order 1
New-GPLink -Name "C-Basis-Windows-Einstellungen" -Target $ou -LinkEnabled Yes -Order 2

# 2) Reihenfolge nachtraeglich aendern
Set-GPLink -Name "C-Basis-Windows-Einstellungen" -Target $ou -Order 1

# 3) Verknuepfung vorubergehend ausschalten (GPO bleibt erhalten)
Set-GPLink -Name "C-Sicherheit-Bildschirmsperre" -Target $ou -LinkEnabled No

# 4) Alle Verknuepfungen dieser OU mit Reihenfolge und Status
(Get-GPInheritance -Target $ou).GpoLinks |
    Select-Object Order, DisplayName, Enabled, Enforced

# 5) GPOs, die nirgendwo verknuepft sind (Kandidaten zum Aufraeumen)
Get-GPO -All | Where-Object {
    ([xml](Get-GPOReport -Guid $_.Id -ReportType Xml)).GPO.LinksTo -eq $null
} | Select-Object DisplayName, CreationTime, ModificationTime
```

Schritt 1 erzeugt zwei Verknüpfungen mit fester Reihenfolge, Schritt 2 vertauscht sie. Schritt 3 schaltet die Wirkung einer Verknüpfung ab; das GPO selbst bleibt unberührt und kann jederzeit wieder aktiviert werden. Schritt 4 gibt die Verknüpfungen aus; `Get-GPInheritance` liefert nicht nur die an der OU selbst gesetzten, sondern auch die geerbten. Schritt 5 ist eine Bestandsaufnahme: Das Skript ruft für jedes GPO den XML-Bericht ab und prüft, ob das Element `LinksTo` fehlt; der Aufruf ist bei vielen GPOs langsam, deshalb führt man ihn nur gelegentlich aus.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die Annahme, ein GPO an einer OU wirke auf den Benutzer *an jedem Computer*: Wenn die Computerkonfiguration verwendet wird, entscheidet die OU des *Computers*, wenn die Benutzerkonfiguration verwendet wird, die OU des *Benutzers*. Wer Benutzereinstellungen an eine Computer-OU verknüpft, wundert sich, dass sie nicht wirken. Der zweite Fehler ist, dass man ein GPO löscht, ohne vorher die Verknüpfungen zu prüfen: Ein GPO, das an mehreren Stellen verknüpft ist, verschwindet dann überall. Der dritte Fehler ist es, ein GPO einfach zu „löschen“, um es vorübergehend abzuschalten: besser ist es, die Verknüpfung zu deaktivieren.

```powershell
# FALSCH: Benutzereinstellungen an eine Computer-OU verknuepfen, die nur Computerkonten enthaelt
New-GPLink -Name "B-Desktop-Einstellungen" -Target "OU=Arbeitsplaetze,OU=Computer,OU=Contoso,DC=corp,DC=contoso,DC=com"

# RICHTIG: Benutzer-GPO an die OU mit den Benutzerkonten
New-GPLink -Name "B-Desktop-Einstellungen" -Target "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Nach einem Rechnerumzug in eine neue OU zeigen die Arbeitsplätze plötzlich den alten Hintergrund und lassen USB-Sticks wieder zu. Ursache: Die Sicherheits-GPOs waren an die alte OU verknüpft und wurden beim Verschieben der Computer nicht mit umgezogen. Das Team erstellt eine Liste aller OUs mit den verknüpften GPOs (aus `Get-GPInheritance`) und dokumentiert als Regel: Wird ein Konto in eine andere OU verschoben, wird die Wirkung der GPOs der Ziel-OU geprüft.

## 7.3 Vererbung und Blockierung

Gruppenrichtlinien werden *vererbt*. Die Microsoft-Dokumentation beschreibt die Verarbeitungsreihenfolge so: Zuerst wird die lokale Richtlinie des Computers angewendet, dann die GPOs, die mit dem *Standort* verknüpft sind, dann die an der *Domain*, und schließlich die an den *Organisationseinheiten* (zuerst die der übergeordneten, dann die der untergeordneten OU). Für diese Reihenfolge verwendet man die Abkürzung *LSDOU* (Local, Site, Domain, OU). Weil jede spätere Anwendung frühere Einstellungen überschreiben kann, gilt: *Das Letzte gewinnt.* Eine Einstellung in der OU, die dem Konto am nächsten liegt, setzt sich also gegenüber derselben Einstellung auf Domain-Ebene durch. Einstellungen, die nicht in Konflikt stehen, *addieren* sich (die Vererbung ist kumulativ). Die Dokumentation ergänzt, dass bei Konflikten zwischen Computer- und Benutzereinstellungen die Computereinstellungen Vorrang haben.

Zwei Mechanismen verändern dieses Verhalten. Die *Blockierung der Vererbung* (Block Inheritance) wird an einer Domain oder OU gesetzt und verhindert, dass GPOs von höheren Containern (Standort, Domain, übergeordnete OUs) auf diese OU wirken. Sie ist nützlich, wenn ein Bereich bewusst eigene Regeln haben soll (zum Beispiel eine OU für Testsysteme). Ihr Nachteil ist, dass sie sich schwer sehen lässt: Wer in der OU nachsieht, findet scheinbar alles in Ordnung, die erwarteten Richtlinien kommen aber nicht an. Die Blockierung gilt für den *Container* und betrifft alle nicht erzwungenen GPOs von oben. Die Dokumentation betont außerdem, dass sie keine Wirkung auf *erzwungene* GPOs hat (Lerneinheit 7.4).

Der zweite Mechanismus ist die *Schleifenrückverarbeitung* (Loopback Processing). Normalerweise bestimmen die GPOs der Benutzer-OU die Benutzereinstellungen, gleichgültig, an welchem Computer sie sich anmelden. Für Computer mit besonderen Anforderungen (Terminalserver, öffentliche Kioske, Schulungsräume) will man dagegen, dass die Benutzereinstellungen vom *Computer* abhängen. Dazu aktiviert man in einem GPO an der Computer-OU die Richtlinie „Schleifenrückverarbeitungsmodus für Benutzergruppenrichtlinien konfigurieren“. Im Modus *Ersetzen* gelten nur noch die Benutzereinstellungen der Computer-OU, im Modus *Zusammenführen* werden sie zusätzlich zu denen der Benutzer-OU angewendet, wobei die Einstellungen der Computer-OU Vorrang haben.

Das folgende Skript zeigt, wie man die Vererbung auswertet und verändert. Es listet die wirksamen GPOs einer OU in der Reihenfolge ihrer Verarbeitung auf, blockiert die Vererbung für eine Test-OU und setzt den Schleifenrückverarbeitungsmodus.

```powershell
Import-Module GroupPolicy
$test = "OU=Test,OU=Computer,OU=Contoso,DC=corp,DC=contoso,DC=com"
$kiosk = "OU=Kiosk,OU=Computer,OU=Contoso,DC=corp,DC=contoso,DC=com"

# 1) Welche GPOs wirken auf die OU (inkl. geerbter), und ist die Vererbung blockiert?
$inh = Get-GPInheritance -Target $test
"Vererbung blockiert: " + $inh.GpoInheritanceBlocked
$inh.InheritedGpoLinks | Select-Object Target, DisplayName, Order, Enforced | Format-Table -AutoSize

# 2) Vererbung fuer die Test-OU blockieren (erzwungene GPOs bleiben wirksam)
Set-GPInheritance -Target $test -IsBlocked Yes

# 3) Schleifenrueckverarbeitung in einem GPO fuer die Kiosk-OU aktivieren (Modus Ersetzen = 1, Zusammenfuehren = 2)
New-GPO -Name "C-Kiosk-Loopback" | Out-Null
Set-GPRegistryValue -Name "C-Kiosk-Loopback" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" `
    -ValueName "UserPolicyMode" -Type DWord -Value 1
New-GPLink -Name "C-Kiosk-Loopback" -Target $kiosk

# 4) Vererbung wieder zulassen
Set-GPInheritance -Target $test -IsBlocked No
```

Schritt 1 liefert die Liste der wirksamen GPOs (`InheritedGpoLinks`) und zeigt, ob die Vererbung blockiert ist; dies ist die erste Anlaufstelle, wenn eine Richtlinie „nicht ankommt“. Schritt 2 setzt die Blockierung. Schritt 3 schreibt den Registrierungswert `UserPolicyMode`, der dem Gruppenrichtlinien-Eintrag „Schleifenrückverarbeitung“ entspricht (1 = Ersetzen, 2 = Zusammenführen), und verknüpft das GPO mit der Kiosk-OU. Schritt 4 hebt die Blockierung wieder auf.

> **Ergänzung aus der Nachrecherche**
>
> Die Verarbeitungsreihenfolge (lokal, Standort, Domain, OU), das Prinzip „der Container näher am Objekt überschreibt“, die Rangfolge der Verknüpfungsreihenfolge und das Verhältnis von Blockierung und Erzwingung entsprechen der abgerufenen Seite „Group Policy processing“ (Microsoft Learn). Der Registrierungswert `UserPolicyMode` für die Schleifenrückverarbeitung stammt aus dem Fachwissen und sollte im Zweifel in der Gruppenrichtlinien-Einstellung über den Editor gesetzt und im Bericht geprüft werden.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die *Blockierung als Standardwerkzeug*: Wer in jeder zweiten OU die Vererbung blockiert, verliert die Kontrolle über zentrale Vorgaben (zum Beispiel Sicherheits-Baselines), und zentrale Änderungen kommen nicht mehr überall an. Der zweite Fehler ist ein Missverständnis zur Reihenfolge: „Die GPO an der Domain ist die wichtigste“ stimmt nicht, sondern das Gegenteil gilt, wenn nichts erzwungen ist. Der dritte Fehler ist die Schleifenrückverarbeitung ohne Plan: Im Modus *Ersetzen* fehlen plötzlich alle Einstellungen der Benutzer-OU (Laufwerke, Drucker), weil sie nicht mehr gelten.

```powershell
# FALSCH: Vererbung an jeder Abteilungs-OU blockieren, "damit nichts stoert"
Get-ADOrganizationalUnit -Filter * -SearchBase "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" |
    ForEach-Object { Set-GPInheritance -Target $_.DistinguishedName -IsBlocked Yes }

# RICHTIG: Nur bewusst und dokumentiert blockieren; zentrale Pflicht-GPOs als "erzwungen" verknuepfen
Set-GPInheritance -Target "OU=Test,OU=Computer,OU=Contoso,DC=corp,DC=contoso,DC=com" -IsBlocked Yes
Set-GPLink -Name "C-Sicherheit-Baseline" -Target "DC=corp,DC=contoso,DC=com" -Enforced Yes
```

### Praxisbezug

> **Praxisbeispiel**
>
> In einer Schule sollen die PCs der Computerräume unabhängig von der Person, die sich anmeldet, einen eingeschränkten Desktop zeigen. Für Lehrkräfte sind in der Benutzer-OU Laufwerke und Drucker definiert, die in den Computerräumen stören. Das Team aktiviert die Schleifenrückverarbeitung im Modus „Ersetzen“ für die OU „Computerräume“; dort gelten dann nur noch die Benutzereinstellungen, die an diese OU gebunden sind. Eine Kontrolle mit `gpresult` bestätigt das Verhalten.

## 7.4 Enforced GPOs

Ein *erzwungenes GPO* (Enforced) ist ein GPO, dessen Verknüpfung als „Erzwungen“ markiert ist. Die Microsoft-Dokumentation beschreibt das so: Durch diese Option verhindert man, dass GPOs in tieferen Active-Directory-Containern die Einstellungen des höher verknüpften GPOs überschreiben. Wenn man zum Beispiel ein GPO an der Domain erzwingt, gelten seine Richtlinien für alle OUs darunter, und GPOs, die an tieferen OUs verknüpft sind, können sie nicht überschreiben. Sind mehrere erzwungene GPOs in einer Kette verknüpft, setzt sich das *am höchsten* verknüpfte durch. Außerdem sagt die Dokumentation klar: *Erzwingen ist eine Eigenschaft der Verknüpfung, Blockieren eine Eigenschaft des Containers; erzwungene Verknüpfungen haben Vorrang vor der Blockierung der Vererbung.* Eine erzwungene Richtlinie lässt sich daher auch durch Blockierung in einer OU nicht abschalten.

Wann verwendet man das? Erzwungene GPOs sind für Einstellungen gedacht, die die Organisation *ausnahmslos* durchsetzen muss: Sicherheits-Baselines (zum Beispiel Vorgaben zur Anmeldeprotokollierung oder zum Blockieren unsicherer Protokolle), Pflicht-Einstellungen aus Compliance-Gründen oder Einstellungen zur Netzwerksicherheit. Das Gegenstück sind die Einstellungen, die lokale Administratoren in ihrem Bereich bewusst ändern dürfen. Wer alles erzwingt, macht die Delegation von Verantwortung nutzlos und erschwert die Fehlersuche, weil Ausnahmen praktisch unmöglich sind. Deshalb sollte man Erzwingung *sparsam* und *dokumentiert* verwenden. Eine Alternative für Ausnahmen ist, die Wirkung mit einem Sicherheitsfilter oder einem WMI-Filter einzuschränken (Lerneinheiten 7.5 und 7.6); die Dokumentation zu Azure Local nennt dieses Vorgehen ausdrücklich als Weg, erzwungene GPOs von bestimmten Computern fernzuhalten, wenn die Blockierung allein nicht wirkt.

Das folgende Skript zeigt, wie man ein Pflicht-GPO erzwingt, alle erzwungenen Verknüpfungen der Domain findet und den Effekt prüft. Die Suche ist besonders wertvoll bei der Fehlersuche, wenn Einstellungen „nicht wegzubekommen“ sind.

```powershell
Import-Module GroupPolicy
$domainDn = (Get-ADDomain).DistinguishedName

# 1) Pflicht-GPO an der Domain erzwingen
New-GPLink -Name "C-Sicherheit-Baseline" -Target $domainDn -Enforced Yes -LinkEnabled Yes

# 2) Alle erzwungenen Verknuepfungen im gesamten Verzeichnis finden (Domain und OUs)
$ziele = @($domainDn) + (Get-ADOrganizationalUnit -Filter * | Select-Object -ExpandProperty DistinguishedName)
foreach ($ziel in $ziele) {
    (Get-GPInheritance -Target $ziel).GpoLinks | Where-Object Enforced |
        Select-Object @{n="Ziel";e={$ziel}}, DisplayName, Order
}

# 3) Wirkung an einer tiefen OU pruefen: erzwungene GPOs erscheinen auch bei blockierter Vererbung
(Get-GPInheritance -Target "OU=Test,OU=Computer,OU=Contoso,$domainDn").InheritedGpoLinks |
    Where-Object Enforced | Select-Object DisplayName, Target

# 4) Erzwingung zuruecknehmen (z. B. nach Abschluss eines Projekts)
Set-GPLink -Name "C-Sicherheit-Baseline" -Target $domainDn -Enforced No
```

In Schritt 1 erzeugt `New-GPLink` mit `-Enforced Yes` die erzwungene Verknüpfung an der Domain. Schritt 2 durchsucht Domain und alle OUs nach erzwungenen Verknüpfungen und liefert damit eine vollständige Liste; gibt es einen Fehler wie „diese Einstellung lässt sich nicht ändern“, findet man hier die Ursache. Schritt 3 zeigt, dass erzwungene GPOs auch auf eine OU mit blockierter Vererbung wirken. Schritt 4 nimmt die Erzwingung wieder zurück.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, alles zu erzwingen, „damit es sicher ist“. Danach lassen sich Ausnahmen nur noch mit Filtern oder durch Verschieben der Konten lösen. Der zweite Fehler ist die Annahme, die Blockierung könne ein erzwungenes GPO abschalten; das tut sie nicht. Der dritte Fehler ist, sich nicht zu merken, *welche* Verknüpfungen erzwungen sind: Dann sucht jeder, der später einen Konflikt untersucht, an den falschen Stellen.

```powershell
# FALSCH: Alle GPOs der Domain als erzwungen markieren
Get-GPO -All | ForEach-Object { Set-GPLink -Name $_.DisplayName -Target "DC=corp,DC=contoso,DC=com" -Enforced Yes }

# RICHTIG: Nur die wenigen Pflicht-GPOs erzwingen, und zwar dokumentiert
Set-GPLink -Name "C-Sicherheit-Baseline" -Target "DC=corp,DC=contoso,DC=com" -Enforced Yes
```

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Entwicklungsabteilung beschwert sich, ein Sicherheits-GPO verbiete ihr den Zugriff auf USB-Speicher, obwohl ihre OU die Vererbung blockiert. Die Analyse zeigt, dass das Sicherheits-GPO an der Domain erzwungen ist. Das Team entscheidet, die Ausnahme über einen Sicherheitsfilter zu lösen: Die Geräte der Abteilung stehen in einer Gruppe, die vom GPO ausgenommen ist. Die Erzwingung bleibt bestehen, die Ausnahme ist sichtbar, begründet und befristet.

## 7.5 Security Filtering

Normalerweise gilt ein verknüpftes GPO für *alle* Benutzer und Computer im Container. Mit der *Sicherheitsfilterung* (Security Filtering) kann man die Wirkung auf bestimmte Konten oder Gruppen begrenzen. Das Prinzip beruht auf Berechtigungen: Ein GPO ist ein Objekt mit einer Zugriffssteuerungsliste. Um angewendet zu werden, braucht das Konto (oder die Gruppe, in der es Mitglied ist) die beiden Rechte *Lesen* und *Gruppenrichtlinie übernehmen* (Apply Group Policy). Die Dokumentation formuliert es so: Das Gruppenrichtliniendienst prüft jedes GPO, ob die nötigen Berechtigungen vorhanden sind; ist das der Fall, wird das GPO in die Liste der anwendbaren GPOs aufgenommen. Standardmäßig erhält die Gruppe *Authenticated Users* beide Rechte, deshalb gilt ein neues GPO für alle.

Um die Wirkung zu beschränken, entfernt man *Authenticated Users* aus der Sicherheitsfilterung und trägt die gewünschte Gruppe ein, zum Beispiel `G-Vertrieb`. Dann wirkt das GPO nur auf die Konten dieser Gruppe. Man kann auch das Gegenteil umsetzen (alle *außer* einer Gruppe), indem man der auszunehmenden Gruppe das Recht *Übernehmen* ausdrücklich *verweigert* (Deny); das ist aber nur in Ausnahmefällen empfehlenswert, weil Verweigerungen die Berechtigungen schwerer lesbar machen. Wichtig ist: Die Sicherheitsfilterung wirkt auf *Benutzer- und Computerkonfiguration gemeinsam*: Filtert man auf eine Benutzergruppe, erhalten Computer die Computereinstellungen nicht (weil sie nicht in der Gruppe sind). Ein GPO, das beide Teile enthält, filtert man daher nur, wenn die Gruppe beide Kontoarten enthält, oder man trennt das GPO in einen Computer- und einen Benutzerteil.

Seit dem Sicherheitsupdate *MS16-072* gibt es eine wichtige Besonderheit, die die Microsoft-Dokumentation ausführlich beschreibt. Seit diesem Update holen Windows-Clients die Benutzerrichtlinien im Sicherheitskontext des *Computers* ab. Deshalb braucht das *Computerkonto* das Recht *Lesen* auf alle GPOs, die für den angemeldeten Benutzer gelten. Entfernt man *Authenticated Users* aus der Sicherheitsfilterung, verliert man damit auch das Leserecht der Computer, und die Benutzerrichtlinien werden nicht mehr angewendet. Die Lösung besteht darin, auf der Registerkarte *Delegierung* der GPO der Gruppe *Authenticated Users* (oder *Domain Computers*) wieder das Recht *Lesen* zu geben, ohne *Übernehmen*. Die Dokumentation weist zusätzlich darauf hin, dass man prüfen soll, dass keine Verweigerung gesetzt ist, denn Verweigerungen überstimmen Erlaubnis.

Das folgende Skript setzt die Filterung korrekt um: Es beschränkt ein GPO auf eine Gruppe, gewährt *Authenticated Users* nur das Leserecht und prüft die Berechtigungen.

```powershell
Import-Module GroupPolicy
$gpo = "B-Vertrieb-Laufwerke"

# 1) Gruppe mit Lesen UND Uebernehmen eintragen (Sicherheitsfilterung)
Set-GPPermission -Name $gpo -TargetName "G-Vertrieb" -TargetType Group -PermissionLevel GpoApply

# 2) Authenticated Users: nur Lesen (ohne Uebernehmen) - wegen MS16-072 unbedingt erforderlich
Set-GPPermission -Name $gpo -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoRead -Replace

# 3) Berechtigungen kontrollieren
Get-GPPermission -Name $gpo -All | Select-Object Trustee, Permission, Denied

# 4) Alle GPOs finden, bei denen weder Authenticated Users noch Domain Computers Lesen haben (MS16-072-Fehlerquelle)
Get-GPO -All | ForEach-Object {
    $p = Get-GPPermission -Guid $_.Id -All
    $hatLesen = $p | Where-Object { $_.Trustee.Name -in "Authenticated Users","Domain Computers" -and $_.Permission -in "GpoRead","GpoApply","GpoEditDeleteModifySecurity","GpoEdit" }
    if (-not $hatLesen) { $_.DisplayName }
}
```

Schritt 1 trägt die Gruppe ein und gibt ihr „GpoApply“, das Lesen und Übernehmen umfasst. Schritt 2 ersetzt die Berechtigung von *Authenticated Users* durch „GpoRead“; die Gruppe hat dann das Leserecht (wichtig für die Computerkonten), aber nicht das Recht zum Übernehmen, sodass das GPO nur für `G-Vertrieb` wirkt. Schritt 3 zeigt das Ergebnis. Schritt 4 sucht GPOs, bei denen niemand mehr das nötige Leserecht hat. Dieses Skript ist ein guter Bestandteil jeder Prüfung nach Änderungen an der Delegierung.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, *Authenticated Users* zu entfernen und nur die Zielgruppe einzutragen, ohne das Leserecht für Computer zu erhalten. Das Ergebnis: Benutzer-GPOs verschwinden, obwohl alles richtig aussieht. Der zweite Fehler ist die Filterung auf eine Gruppe, deren Mitglieder die falsche Kontoart sind (Benutzergruppe für ein GPO mit Computereinstellungen). Der dritte Fehler ist die Verwendung von *Deny*: Sie überstimmt alle anderen Rechte, auch die von Administratoren, und führt zu schwer erklärbaren Ergebnissen.

```powershell
# FALSCH: Authenticated Users entfernt, nur Zielgruppe -> Benutzer-GPO wirkt nicht mehr (MS16-072)
Set-GPPermission -Name "B-Vertrieb-Laufwerke" -TargetName "Authenticated Users" -TargetType Group -PermissionLevel None -Replace

# RICHTIG: Authenticated Users behalten nur Lesen, Zielgruppe bekommt Uebernehmen
Set-GPPermission -Name "B-Vertrieb-Laufwerke" -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoRead -Replace
Set-GPPermission -Name "B-Vertrieb-Laufwerke" -TargetName "G-Vertrieb" -TargetType Group -PermissionLevel GpoApply
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Team richtet ein GPO für Laufwerkszuordnungen ein, das nur die Gruppe „Buchhaltung“ erhalten soll. Am nächsten Tag meldet die Buchhaltung, dass keine Laufwerke erscheinen. Die Prüfung mit `gpresult` zeigt, dass das GPO als „nicht angewendet (Sicherheitsfilter)“ geführt wird, weil die Computerkonten kein Leserecht hatten. Nach dem Eintragen von *Authenticated Users* mit dem Recht „Lesen“ (ohne „Übernehmen“) funktioniert die Zuordnung. Seitdem prüft das Team nach jeder Filteränderung mit dem Skript aus Schritt 4.

## 7.6 WMI Filtering

Neben der Sicherheitsfilterung gibt es eine zweite Möglichkeit, die Wirkung eines GPOs einzuschränken: den *WMI-Filter*. *WMI* (Windows Management Instrumentation) ist die Verwaltungsschnittstelle von Windows, mit der man Eigenschaften eines Computers abfragen kann, zum Beispiel Betriebssystemversion, Hersteller, Speicher oder freien Plattenplatz. Ein WMI-Filter besteht aus einer oder mehreren Abfragen in der Sprache *WQL* (WMI Query Language), die auf dem Client ausgewertet werden. Die Dokumentation beschreibt das Prinzip: Jede Abfrage liefert ein wahr/falsch-Ergebnis, und wenn sie wahr ist, bleibt das GPO in der Liste der anzuwendenden GPOs, andernfalls wird es entfernt. Ein GPO kann genau *einen* WMI-Filter haben; ein Filter kann aus mehreren Abfragen bestehen, die alle wahr sein müssen. Mehrere GPOs dürfen denselben Filter verwenden.

Typische Einsatzfälle sind Einstellungen, die nur für bestimmte Betriebssystemversionen gelten, oder für bestimmte Rechnerklassen (Notebooks, virtuelle Maschinen, Server mit einer bestimmten Rolle). Ein häufiges Beispiel ist die Filterung auf den PDC Emulator: Die Zeitkonfiguration aus Lerneinheit 6.9 soll nur auf diesem einen Domain Controller wirken; die Abfrage `select * from Win32_ComputerSystem where DomainRole = 5` trifft genau auf ihn zu. Für Betriebssysteme verwendet man die Eigenschaften `Version` und `ProductType` der Klasse `Win32_OperatingSystem`: Der Wert `ProductType` ist 1 für Arbeitsstationen, 2 für Domain Controller und 3 für Server.

Man sollte WMI-Filter aber nur einsetzen, wenn es *keine einfachere Lösung* gibt. Der Grund sind Komplexität und Leistung. WMI-Abfragen werden auf dem Client bei *jeder* Verarbeitung ausgeführt, nacheinander und synchron; jede langsame Abfrage verlängert Start und Anmeldung. Filter sind außerdem schwer zu überblicken, weil sie nicht an den GPO-Berechtigungen und nicht an der OU-Struktur erkennbar sind. Meist lässt sich dasselbe Ziel einfacher erreichen: durch eine eigene OU für die Rechnerklasse, durch Gruppen als Sicherheitsfilter oder durch Zielgruppenadressierung in Preferences (Lerneinheit 7.8). Und die Abfragen sollten eng und schnell sein; `select * from Win32_Product` ist zum Beispiel ein Klassiker, der den Windows Installer anwirft und Minuten dauern kann.

Das Anlegen eines Filters erfolgt im GPMC im Knoten *WMI-Filter* (Rechtsklick, „Neu“): Name, Beschreibung und die Abfrage (Namespace `root\CIMv2`) eintragen; anschließend ordnet man ihn auf der Registerkarte *Bereich* dem GPO zu. Im Verzeichnis liegen die Filter als Objekte im Container `CN=SOM,CN=WMIPolicy,CN=System`. Das folgende Skript testet WQL-Abfragen lokal (bevor man sie in einen Filter einträgt), liest vorhandene Filter aus dem Verzeichnis und zeigt, welche GPOs sie verwenden.

```powershell
Import-Module ActiveDirectory, GroupPolicy

# 1) WQL-Abfragen vor dem Einsatz lokal testen (liefert ein Objekt = wahr, nichts = falsch)
$abfragen = [ordered]@{
    "Windows 11 Arbeitsstation"    = "SELECT * FROM Win32_OperatingSystem WHERE Version LIKE '10.0.2%' AND ProductType = '1'"
    "Windows Server (nicht DC)"    = "SELECT * FROM Win32_OperatingSystem WHERE ProductType = '3'"
    "Domain Controller"            = "SELECT * FROM Win32_OperatingSystem WHERE ProductType = '2'"
    "PDC-Emulator"                 = "SELECT * FROM Win32_ComputerSystem WHERE DomainRole = 5"
}
foreach ($name in $abfragen.Keys) {
    $treffer = @(Get-CimInstance -Query $abfragen[$name]).Count -gt 0
    "{0,-28} -> {1}" -f $name, $treffer
}

# 2) Vorhandene WMI-Filter der Domain lesen
$som = "CN=SOM,CN=WMIPolicy,CN=System,$((Get-ADDomain).DistinguishedName)"
Get-ADObject -SearchBase $som -Filter 'objectClass -eq "msWMI-Som"' -Properties "msWMI-Name","msWMI-Parm1","msWMI-Parm2" |
    Select-Object "msWMI-Name", "msWMI-Parm1", "msWMI-Parm2" | Format-List

# 3) Welche GPOs verwenden einen WMI-Filter? (Attribut gPCWQLFilter)
$gpoContainer = "CN=Policies,CN=System,$((Get-ADDomain).DistinguishedName)"
Get-ADObject -SearchBase $gpoContainer -SearchScope OneLevel -Filter 'objectClass -eq "groupPolicyContainer"' -Properties displayName, gPCWQLFilter |
    Where-Object gPCWQLFilter | Select-Object displayName, gPCWQLFilter
```

Schritt 1 führt die Abfragen mit `Get-CimInstance` aus. Dieselbe Syntax verwendet der WMI-Filter; ein Treffer bedeutet „wahr“. Damit prüft man sowohl die Syntax als auch die Zielgenauigkeit, bevor sie im Produktivbetrieb Computer ausschließt. In Schritt 2 werden die gespeicherten Filter ausgelesen: Das Attribut `msWMI-Parm2` enthält die Abfrage in einem internen Format. Schritt 3 zeigt, welche GPOs einen Filter verwenden; der Eintrag in `gPCWQLFilter` verweist auf die Kennung des Filters.

> **Ergänzung aus der Nachrecherche**
>
> Die Aussage, dass WMI-Filter wahr/falsch-Ergebnisse liefern und gemeinsam mit der Sicherheitsfilterung die Liste der anwendbaren GPOs bestimmen, entspricht der abgerufenen Seite „Group Policy scope“ (Microsoft Learn). Die Hinweise zu Klassen und Werten (`DomainRole`, `ProductType`), zur Leistung der Abfragen und zur internen Struktur der Filterobjekte stammen aus dem Fachwissen; die internen Attribute sind nicht für das Schreiben per Skript dokumentiert, weshalb die Lerneinheit das Anlegen im GPMC beschreibt.

### Typische Fehler und Stolperfallen

Der erste Fehler ist ein WMI-Filter für etwas, das auch ein Sicherheitsfilter oder eine OU leisten würde: Man bezahlt dann dauerhaft Verarbeitungszeit für eine Unterscheidung, die man im Verzeichnis einmalig treffen könnte. Der zweite Fehler ist eine falsche Abfrage: Wer `Version LIKE '10.0%'` schreibt, trifft Windows 10, Windows 11 und alle aktuellen Server, weil sie alle mit 10.0 beginnen. Der dritte Fehler ist eine Abfrage auf eine Klasse oder Eigenschaft, die es auf manchen Rechnern nicht gibt: Der Filter ergibt dann „falsch“, und das GPO wird stillschweigend nicht angewendet. Der vierte Fehler ist ein langsamer Filter auf Domain-Ebene, der jeden Computer jedes Mal ausbremst.

```powershell
# FALSCH: Filter mit Win32_Product - langsam, loest eine Windows-Installer-Pruefung aus
#   SELECT * FROM Win32_Product WHERE Name LIKE 'Contoso%'

# RICHTIG: Schnelle Klassen wie Win32_OperatingSystem oder Win32_ComputerSystem verwenden,
#          oder die Rechnerklasse ueber eine OU/Gruppe loesen
Get-CimInstance -Query "SELECT * FROM Win32_OperatingSystem WHERE ProductType = '1'"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen betreibt gemischt Windows 10 und Windows 11 und möchte eine Einstellung nur für Windows 11 verteilen. Statt alle Rechner in zwei OUs aufzuteilen, legt das Team einen WMI-Filter für Windows 11-Arbeitsstationen an. Nach dem Rollout verlängert sich die Anmeldung auf einigen älteren Notebooks um zwölf Sekunden, weil dort die WMI-Dienste träge sind. Das Team ersetzt den Filter durch dynamisch gepflegte Gruppen (per Skript aus dem Attribut `operatingSystem`) und verwendet sie als Sicherheitsfilter; die Anmeldezeit sinkt wieder.

## 7.7 Administrative Templates

Die meisten Einstellungen in einem GPO stammen aus den *Administrativen Vorlagen* (Administrative Templates). Das sind Beschreibungen, die dem Gruppenrichtlinien-Editor sagen, welche Registrierungseinträge es gibt, wie sie heißen, welche Werte zulässig sind und wie der Text in der Oberfläche lautet. Die Vorlagen bestehen aus zwei Dateitypen. Die sprachneutrale *ADMX-Datei* beschreibt die Einstellung selbst (Registrierungspfad, Wertetyp, Kategorie); die *ADML-Datei* enthält die sprachabhängigen Texte und liegt in einem Unterordner pro Sprache (zum Beispiel `de-DE` oder `en-US`). Das Format löste das alte ADM-Format ab; die Dokumentation merkt an, dass Windows 10 und neuer keine ADM-Dateien mehr mitliefern.

Die Einstellungen aus Administrativen Vorlagen schreiben in aller Regel Werte unter den Registrierungsschlüsseln `Software\Policies` oder `Software\Microsoft\Windows\CurrentVersion\Policies`. Ein wichtiger Unterschied zu Preferences ist, dass solche *Richtlinien* nur gelten, solange das GPO gilt: Wird das GPO entfernt oder gilt es für das Konto nicht mehr, verschwinden die Werte beim nächsten Durchlauf (Windows löscht den Richtlinienschlüssel vor der Neuanwendung). Außerdem sind Richtlinieneinstellungen für den Benutzer meist ausgegraut und können nicht geändert werden.

Der Editor liest die Vorlagen entweder aus dem lokalen Ordner `C:\Windows\PolicyDefinitions` oder, wenn es ihn gibt, aus dem *zentralen Speicher* (Central Store) in SYSVOL. Die Dokumentation beschreibt dessen Anlage: Man erstellt auf einem Domain Controller den Ordner `PolicyDefinitions` unter `\\Domäne\SYSVOL\Domäne\Policies` und kopiert dorthin alle ADMX-Dateien samt ADML-Unterordnern von einem aktuellen Windows-10- oder Windows-11-Client. Weil der Ordner in SYSVOL liegt, wird er auf alle Domain Controller repliziert, und alle Administratoren sehen dieselben Einstellungen. Die Dokumentation empfiehlt, alte Stände aufzubewahren: Man legt die neue Version in einem Ordner mit sprechendem Namen ab (zum Beispiel `PolicyDefinitions-24H2`), benennt den bisherigen Ordner nach der Version um und gibt dem neuen den Produktionsnamen, damit man bei Problemen zurück kann. Fehlt zu einer gesetzten Einstellung die passende ADMX-Datei (etwa weil eine ältere Version im Speicher liegt), zeigt der Editor sie unter „Zusätzliche Registrierungseinstellungen“ (Extra Registry Settings) an, und sie lässt sich dort nicht mehr bearbeiten.

Das folgende Skript legt den zentralen Speicher an oder aktualisiert ihn, vergleicht die Anzahl der Dateien und prüft die Sprachordner. Es kopiert von einem Referenz-Client (hier der Ordner einer eingehängten Freigabe) und sichert vorher den bestehenden Speicher.

```powershell
$domain  = "corp.contoso.com"
$store   = "\\$domain\SYSVOL\$domain\Policies\PolicyDefinitions"
$quelle  = "\\PC01\C$\Windows\PolicyDefinitions"        # Referenz-Client mit aktuellem Windows 11
$version = "24H2"

# 1) Bestehenden Speicher sichern (umbenennen), neuen anlegen
if (Test-Path $store) {
    Rename-Item $store "PolicyDefinitions-alt-$(Get-Date -Format yyyyMMdd)"
}
New-Item -ItemType Directory -Path $store | Out-Null

# 2) ADMX-Dateien und die deutschen/englischen Sprachordner kopieren
Copy-Item "$quelle\*.admx" $store
foreach ($sprache in "de-DE","en-US") {
    if (Test-Path "$quelle\$sprache") { Copy-Item "$quelle\$sprache" "$store\$sprache" -Recurse }
}

# 3) Kontrolle: Anzahl der Dateien und vorhandene Sprachordner
"ADMX-Dateien: " + (Get-ChildItem $store -Filter *.admx).Count
Get-ChildItem $store -Directory | Select-Object Name, @{n="ADML";e={ (Get-ChildItem $_.FullName -Filter *.adml).Count }}

# 4) Pruefen, ob ein Rechner den lokalen Speicher statt des zentralen verwendet
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Group Policy" -Name EnableLocalStoreOverride -ErrorAction SilentlyContinue
```

Schritt 1 sichert den alten Speicher durch Umbenennen und legt einen neuen Ordner an; so kann man bei Problemen den alten Stand zurückbenennen. Schritt 2 kopiert die ADMX-Dateien und die Sprachordner. Schritt 3 gibt die Anzahl der Dateien und die vorhandenen Sprachordner aus; die Zahl der ADML-Dateien sollte der der ADMX-Dateien entsprechen. In Schritt 4 prüft das Skript die Registrierungseinstellung `EnableLocalStoreOverride`, mit der ein Rechner trotz zentralem Speicher den lokalen Ordner verwendet (Wert 1); die Dokumentation nennt sie als Lösung, wenn man mit einem anderen Stand testen oder ältere Richtlinien bearbeiten will.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, den zentralen Speicher gar nicht anzulegen: Jeder Administrator sieht dann je nach Windows-Version seines Arbeitsplatzes unterschiedliche Einstellungen, und Änderungen an GPOs vom falschen Arbeitsplatz aus zeigen Einstellungen plötzlich als „Zusätzliche Registrierungseinstellungen“. Der zweite Fehler ist, einen vorhandenen Speicher zu überschreiben, ohne zu sichern; nach dem Kopieren der neuen Windows-Vorlagen tritt gelegentlich die Fehlermeldung auf, dass ein Namensraum doppelt definiert ist, wenn alte und neue Dateien gemischt werden. Der dritte Fehler ist das Mischen von Sprachen: Fehlt der deutsche Ordner `de-DE`, sieht ein deutschsprachiger Administrator englische Texte oder gar keine Vorlagen.

```powershell
# FALSCH: Neue ADMX-Dateien einfach ueber den alten Speicher kopieren (Mischstand)
Copy-Item "\\PC01\C$\Windows\PolicyDefinitions\*" "\\corp.contoso.com\SYSVOL\corp.contoso.com\Policies\PolicyDefinitions" -Recurse -Force

# RICHTIG: Alten Speicher umbenennen, neuen sauber aufbauen (siehe Skript oben)
Rename-Item "\\corp.contoso.com\SYSVOL\corp.contoso.com\Policies\PolicyDefinitions" "PolicyDefinitions-alt-20260101"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Nach dem Upgrade der Arbeitsplätze auf Windows 11 fehlen in der Verwaltungskonsole die neuen Einstellungen für Windows 11, weil der zentrale Speicher noch den Stand von Windows 10 hat. Das Team baut den Speicher wie oben mit den ADMX-Dateien eines aktuellen Windows 11-Clients neu auf, ergänzt die ADMX-Dateien für Microsoft Edge und Office aus den jeweiligen Downloads und führt einen Plan ein, nach dem der Speicher nach jedem Funktionsupdate geprüft wird.

## 7.8 Group Policy Preferences

*Group Policy Preferences* (GPP, auf Deutsch „Gruppenrichtlinien-Einstellungen“) ergänzen die klassischen Richtlinien um über 20 Erweiterungen, wie es in der Microsoft-Dokumentation zur Sicherheitsmitteilung MS14-025 heißt. Sie finden sich im Editor unter dem Knoten *Einstellungen* (Preferences) und decken Konfigurationen ab, für die es keine Richtlinie gibt: Laufwerkszuordnungen, Drucker, Ordner, Dateien, Registrierungswerte beliebiger Schlüssel, Umgebungsvariablen, geplante Aufgaben, Dienste, Verknüpfungen und lokale Benutzer und Gruppen.

Der wesentliche Unterschied zu Richtlinien: Preferences werden *angewendet, aber nicht erzwungen*. Der Benutzer kann ein Laufwerk, das per Preference eingerichtet wurde, nachträglich ändern oder trennen, und mit der nächsten Verarbeitung wird es wieder hergestellt (außer man wählt die Option, die Einstellung nur einmal anzuwenden). Die Dokumentation beschreibt zwei Optionen: „Beim nächsten Mal nicht mehr anwenden“ (*Apply once and do not reapply*) wendet das Element nur ein einziges Mal an, danach darf der Benutzer die Einstellung ändern. „Dieses Element entfernen, wenn es nicht mehr angewendet wird“ (*Remove this item when it is no longer applied*) macht die Einstellung rückgängig, wenn sie aus dem Geltungsbereich fällt (der Standard ist, Preferences nicht zurückzunehmen); diese Option setzt die Aktion auf *Ersetzen*. Jedes Preference-Element hat außerdem eine *Aktion*: Erstellen (C), Ersetzen (R), Aktualisieren (U) oder Löschen (D).

Das zweite große Merkmal ist die *Zielgruppenadressierung* (Item-Level Targeting). Jedes einzelne Element kann an Bedingungen geknüpft werden: Zugehörigkeit zu einer Sicherheitsgruppe, Name des Computers, Betriebssystem, IP-Adressbereich, Site, Akkustatus, Existenz einer Datei oder eines Registrierungswerts und viele mehr, auch kombiniert mit UND/ODER. Dadurch braucht man für Varianten kein eigenes GPO und keinen WMI-Filter; ein einziges GPO kann „Laufwerk S: für die Gruppe Vertrieb, Laufwerk T: für die Gruppe Technik“ enthalten. Wegen der Wartbarkeit und der Leistung ist das meist besser als WMI.

*Sicherheitswarnung:* Früher konnte man in Preferences *Kennwörter* hinterlegen (für Laufwerke, geplante Aufgaben, Dienste, lokale Benutzer und Datenquellen). Sie wurden in der Datei in SYSVOL mit einem Schlüssel verschlüsselt, der öffentlich bekannt ist. Das Microsoft-Sicherheitsbulletin MS14-025 beschreibt, dass jeder authentifizierte Benutzer dieses Kennwort entschlüsseln und damit Rechte ausweiten kann; das Update entfernt die Möglichkeit, solche Kennwörter zu konfigurieren, *entfernt aber vorhandene GPOs nicht*. Microsoft Defender for Identity prüft deshalb auf solche Altlasten und empfiehlt, die Preference-Einträge samt Kennwörtern zu entfernen und die betroffenen Kennwörter zu ändern, weil die entfernten Kennwörter nicht ungültig werden, wenn sie bereits gelesen wurden.

Das folgende Skript zeigt zwei praktische Dinge: das Setzen eines Registrierungswerts per Preference mit PowerShell (Cmdlet `Set-GPPrefRegistryValue`) und die Suche nach alten Kennwörtern (*cpassword*) in SYSVOL.

```powershell
Import-Module GroupPolicy

# 1) Preference: Registrierungswert fuer alle Computer, der von Benutzern aenderbar bleibt (Aktion Update)
New-GPO -Name "C-Preferences-Basis" | Out-Null
Set-GPPrefRegistryValue -Name "C-Preferences-Basis" -Context Computer -Action Update `
    -Key "HKLM\SOFTWARE\Contoso\Intranet" -ValueName "Startseite" -Type String -Value "https://intranet.corp.contoso.com"

# 2) Gleiche Preference wieder auslesen
Get-GPPrefRegistryValue -Name "C-Preferences-Basis" -Context Computer -Key "HKLM\SOFTWARE\Contoso\Intranet" -ValueName "Startseite"

# 3) Sicherheitspruefung: Kennwoerter in Preferences (cpassword) in SYSVOL finden
$pfad = "\\corp.contoso.com\SYSVOL\corp.contoso.com\Policies"
Get-ChildItem $pfad -Recurse -Include *.xml -ErrorAction SilentlyContinue |
    Select-String -Pattern "cpassword" -List |
    Select-Object Path | ForEach-Object { $_.Path }
```

Schritt 1 legt ein GPO an und setzt einen Registrierungswert als Preference; die Aktion `Update` überschreibt den Wert, wenn er existiert, und legt ihn sonst an. Im Gegensatz zur Richtlinie bleibt der Wert erhalten, wenn das GPO später nicht mehr gilt. Schritt 2 liest die Preference zurück. Schritt 3 durchsucht alle XML-Dateien in SYSVOL nach dem Schlüsselwort `cpassword`; jeder Treffer ist ein Fund, der nach der Anleitung der Dokumentation bereinigt werden muss. Führt man diese Suche erstmals durch, überrascht oft die Zahl der Treffer in alten Umgebungen.

### Typische Fehler und Stolperfallen

Der gravierendste Fehler ist der Einsatz von Kennwörtern in Preferences, auch in alten GPOs, die niemand mehr kennt; die Wirkung ist ein für jeden Benutzer lesbares Kennwort. Der zweite Fehler ist, Preferences und Richtlinien zu verwechseln: Wer ein Sicherheitsmerkmal als Preference verteilt, kann sich nicht darauf verlassen, dass es dauerhaft besteht (Benutzer oder Administratoren können es ändern). Der dritte Fehler ist das Löschen von Preference-Elementen aus einem GPO mit dem Ziel, die Wirkung rückgängig zu machen: Die Einstellung bleibt auf den Clients bestehen. Dafür muss man erst die Aktion „Löschen“ oder die Option zum Entfernen verwenden und den Effekt abwarten.

```powershell
# FALSCH: Preference loeschen und annehmen, die Einstellung verschwinde auf den Clients
Remove-GPPrefRegistryValue -Name "C-Preferences-Basis" -Context Computer -Key "HKLM\SOFTWARE\Contoso\Intranet" -ValueName "Startseite"

# RICHTIG: Aktion "Delete" setzen, Wirkung abwarten, erst danach das Element entfernen
Set-GPPrefRegistryValue -Name "C-Preferences-Basis" -Context Computer -Action Delete `
    -Key "HKLM\SOFTWARE\Contoso\Intranet" -ValueName "Startseite"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Bei einem Sicherheits-Audit findet ein Prüfer in einem GPO von 2012 ein Preference-Element, das das Kennwort des lokalen Administrators auf allen Servern setzt. Das Kennwort steht verschlüsselt in einer XML-Datei in SYSVOL und kann mit einem öffentlichen Schlüssel gelesen werden. Das Team entfernt das Element, ändert alle Kennwörter, und ersetzt den Mechanismus durch Windows LAPS (Verwaltung der lokalen Administratorkennwörter pro Computer). Anschließend prüft es mit dem Skript regelmäßig, dass keine `cpassword`-Einträge mehr auftauchen.

## 7.9 RSoP und gpresult

Wenn eine Einstellung nicht wirkt oder unerwartet wirkt, will man wissen, *welche Richtlinien tatsächlich angewendet wurden* und warum andere nicht. Dafür gibt es den *Richtlinienergebnissatz* (Resultant Set of Policy, RSoP). Es gibt zwei grundverschiedene Arten, ihn zu ermitteln. Bei der *Auswertung* (Group Policy Results im GPMC, das Kommandozeilenwerkzeug `gpresult` und das Cmdlet `Get-GPResultantSetOfPolicy`) wird ermittelt, was auf einem bestimmten Computer und für einen bestimmten Benutzer *tatsächlich passiert ist*: welche GPOs angewendet und welche aus welchem Grund abgelehnt wurden. Bei der *Modellierung* (Group Policy Modeling) wird dagegen *simuliert*, was passieren *würde*, wenn ein Konto in eine andere OU verschoben oder ein Filter geändert würde; sie läuft auf einem Domain Controller und berücksichtigt nicht den tatsächlichen Zustand des Clients.

Das wichtigste Werkzeug im Alltag ist `gpresult`. Mit `gpresult /r` erhält man eine Textübersicht, aufgeteilt in *Computereinstellungen* und *Benutzereinstellungen*, mit der Liste der angewendeten GPOs, der Gruppen, in denen der Benutzer ist, und dem Standort. Mit `/scope computer` oder `/scope user` beschränkt man die Ausgabe. Die Auswertung der Computereinstellungen verlangt eine Eingabeaufforderung mit Administratorrechten. Mit `/h bericht.html /f` erzeugt man einen ausführlichen HTML-Bericht, der für jede einzelne Einstellung angibt, *welches GPO sie gesetzt hat*. Und mit `/x bericht.xml` erhält man dieselben Daten als XML zur automatischen Auswertung. In der Liste der „abgelehnten GPOs“ (Denied GPOs) steht der Grund: „Sicherheitsfilterung“ (Zugriff verweigert), „WMI-Filter“ oder „leer“ (GPO ohne Einstellungen).

Zur systematischen Fehlersuche empfiehlt sich eine feste Reihenfolge. *Erstens* die Grundlagen: Findet der Client einen Domain Controller (`nltest /dsgetdc`)? Ist SYSVOL erreichbar (`dir \\corp.contoso.com\SYSVOL`)? Gibt es DNS-Probleme? *Zweitens* der Bereich: Liegt das Konto in der richtigen OU, und ist das GPO dort verknüpft und aktiviert (Lerneinheit 7.2)? *Drittens* die Vererbung und die Reihenfolge: Blockiert eine OU die Vererbung, überschreibt ein näheres GPO die Einstellung (7.3, 7.4)? *Viertens* die Filter: Sicherheitsfilter und Leserecht (7.5), WMI-Filter (7.6). *Fünftens* die Konsistenz: Stimmen die Versionen von GPC und GPT überein (Lerneinheit 6.8)? *Sechstens* die Erweiterung selbst: Zeigt das Ereignisprotokoll *Anwendung und Dienste, Microsoft, Windows, GroupPolicy, Betriebsbereit* Fehler, und gibt es Hinweise der einzelnen Clientseitigen Erweiterungen?

Das folgende Skript automatisiert den ersten Blick: Es erzeugt einen XML-Bericht mit `gpresult`, wertet ihn aus, zeigt für Computer und Benutzer die angewendeten und abgelehnten GPOs samt Grund und stößt anschließend mit dem Cmdlet einen HTML-Bericht an.

```powershell
# Als Administrator auf dem betroffenen Computer ausfuehren
$xmlPfad = Join-Path $env:TEMP "gpresult.xml"
gpresult /x $xmlPfad /f | Out-Null
[xml]$doc = Get-Content $xmlPfad -Encoding UTF8

foreach ($bereich in "ComputerResults","UserResults") {
    "=== $bereich ==="
    $knoten = $doc.Rsop.$bereich
    if (-not $knoten) { "  (kein Ergebnis - Benutzer nicht angemeldet oder keine Berechtigung)"; continue }
    foreach ($gpo in @($knoten.GPO)) {
        $status = if ($gpo.Enabled -eq "false") { "deaktiviert" }
                  elseif ($gpo.AccessDenied -eq "true") { "ABGELEHNT (Berechtigung/Sicherheitsfilter)" }
                  elseif ($gpo.FilterAllowed -eq "false") { "ABGELEHNT (WMI-Filter)" }
                  else { "angewendet" }
        "  {0,-45} {1}" -f $gpo.Name, $status
    }
}

# Ausfuehrlicher HTML-Bericht zur Weitergabe
gpresult /h "$env:TEMP\gpresult.html" /f
Get-GPResultantSetOfPolicy -Computer $env:COMPUTERNAME -ReportType Html -Path "$env:TEMP\rsop-cmdlet.html" -ErrorAction SilentlyContinue

# Auf Verdacht: Richtlinienaktualisierung erzwingen und erneut messen
gpupdate /force
```

Das Skript fordert zuerst ein XML mit `gpresult /x` an und liest es als XML-Objekt. Für Computer- und Benutzerteil durchläuft es die enthaltenen GPOs und bewertet die Eigenschaften: `AccessDenied` steht für fehlende Berechtigung (Sicherheitsfilterung), `FilterAllowed` für das Ergebnis des WMI-Filters. Die Ausgabe zeigt auf einen Blick, welches GPO aus welchem Grund nicht gewirkt hat. Anschließend entstehen zwei HTML-Berichte, die man an Kollegen weitergeben kann, und `gpupdate /force` wiederholt die Verarbeitung vollständig.

> **Ergänzung aus der Nachrecherche**
>
> Die Befehle `gpresult`, `gpupdate` und die Cmdlets `Invoke-GPUpdate` sowie `Get-GPResultantSetOfPolicy` sind in der abgerufenen Seite „Group Policy processing“ (Microsoft Learn) für das Auslösen der Richtlinienaktualisierung beschrieben. Die Struktur der XML-Ausgabe von `gpresult` (Elemente `GPO`, `AccessDenied`, `FilterAllowed`) und die Hinweise zum Ereignisprotokoll stammen aus dem Fachwissen und sollten im Labor an einer eigenen Ausgabe überprüft werden, weil sich Details je nach Windows-Version unterscheiden können.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, `gpresult` ohne Administratorrechte auszuführen und sich zu wundern, dass der Computerteil fehlt oder eine Fehlermeldung zur Berechtigung erscheint. Der zweite Fehler ist, die Modellierung mit der Auswertung zu verwechseln: Die Modellierung sagt, was *theoretisch* passieren sollte, nicht was auf dem Client passiert ist. Der dritte Fehler ist, den Bericht auf dem falschen Konto zu erzeugen: Die Benutzereinstellungen gelten für den Benutzer, der „angemeldet“ ist; verwendet man eine administrative Sitzung mit einem anderen Konto, zeigt der Bericht dessen Ergebnisse. Der vierte Fehler ist das „Reparieren“ durch `gpupdate /force` ohne Analyse: Dadurch verschwindet das Symptom möglicherweise einmalig, die Ursache bleibt.

```powershell
# FALSCH: gpresult ohne Administratorrechte; der Computerteil fehlt
gpresult /r /scope computer

# RICHTIG: In einer erhoehten Eingabeaufforderung/PowerShell, mit Bericht fuer einen bestimmten Benutzer
gpresult /r /scope computer
gpresult /user CORP\a.muster /h C:\Temp\gpo-amuster.html /f
```

### Praxisbezug

> **Praxisbeispiel**
>
> Die Buchhaltung meldet, ein Netzlaufwerk fehle seit Montag. Die Hotline führt `gpresult /h` auf dem Rechner durch und sieht, dass das GPO „B-Buchhaltung-Laufwerke“ unter „abgelehnten GPOs“ mit dem Grund „Sicherheitsfilterung“ steht. Am Freitag hatte ein Kollege die Gruppe „Authenticated Users“ aus der Filterung entfernt (Lerneinheit 7.5). Nach Wiederherstellung des Leserechts erscheint das Laufwerk beim nächsten Update. Die Analyse dauert zehn Minuten statt eines Nachmittags, weil der Bericht die Ursache direkt nennt.

## 7.10 Übungsaufgaben zu Modul 07

Die Aufgaben 1 bis 3 prüfen das Verständnis, die Aufgaben 4 bis 8 sind praktische Skriptaufgaben für die Laborumgebung.

**Aufgabe 7.1** **Reihenfolge.** Auf Domain-Ebene setzt GPO A die Bildschirmsperre auf 5 Minuten, an der OU „Vertrieb“ setzt GPO B sie auf 15 Minuten. Welcher Wert gilt für einen Computer in der OU „Vertrieb“? Wie ändert sich das Ergebnis, wenn GPO A erzwungen ist, wie, wenn die OU die Vererbung blockiert?

**Aufgabe 7.2** **Filterart wählen.** Eine Einstellung soll nur für Notebooks gelten. Nennen Sie drei Wege, das zu erreichen (OU, Gruppe, WMI-Filter, Preference-Zielgruppenadressierung), und bewerten Sie sie nach Aufwand und Leistung.

**Aufgabe 7.3** **Fehler erklären.** Ein GPO mit Benutzereinstellungen wurde mit dem Sicherheitsfilter „G-Vertrieb“ versehen, „Authenticated Users“ wurde entfernt. Seitdem wirkt die Einstellung nicht mehr. Erklären Sie die Ursache und die Lösung.

**Aufgabe 7.4** **GPO anlegen und sichern.** Legen Sie ein GPO `C-Sicherheit-Bildschirmsperre` mit einem Registrierungswert an, verknüpfen Sie es mit einer Test-OU und erstellen Sie eine Sicherung und einen HTML-Bericht.

**Aufgabe 7.5** **Vererbung auswerten.** Schreiben Sie ein Skript, das für eine übergebene OU alle wirksamen GPOs mit Reihenfolge und Erzwingung ausgibt und anzeigt, ob die Vererbung blockiert ist.

**Aufgabe 7.6** **Sicherheitsfilter.** Beschränken Sie ein GPO auf eine Gruppe und stellen Sie sicher, dass die Computer weiterhin das Leserecht haben. Prüfen Sie mit `Get-GPPermission`. Schreiben Sie dann ein Skript, das alle GPOs ohne Leserecht für *Authenticated Users* oder *Domain Computers* findet.

**Aufgabe 7.7** **Zentraler Speicher.** Legen Sie in der Laborumgebung einen zentralen Speicher für Administrative Vorlagen an, kontrollieren Sie die Anzahl der ADMX- und ADML-Dateien und öffnen Sie danach ein GPO im Editor, um zu prüfen, dass die Vorlagen aus dem zentralen Speicher kommen.

**Aufgabe 7.8** **Fehlersuche.** Verknüpfen Sie ein GPO absichtlich so, dass es auf einem Test-Client nicht wirkt (Sicherheitsfilter ohne Leserecht oder falscher WMI-Filter). Finden Sie die Ursache mit `gpresult`, dokumentieren Sie die Schritte und beheben Sie den Fehler.

## 7.11 Lösungen zu den Übungsaufgaben

**Lösung 7.1.** Ohne Besonderheiten werden die GPOs in der Reihenfolge Domain, dann OU verarbeitet, das spätere überschreibt das frühere: Es gilt *15 Minuten* (GPO B). Ist GPO A an der Domain erzwungen, kann das untergeordnete GPO B es nicht überschreiben; dann gilt *5 Minuten*. Blockiert die OU die Vererbung, wird GPO A nicht angewendet (wenn es nicht erzwungen ist); dann gilt *15 Minuten*. Ist GPO A erzwungen *und* blockiert die OU, gewinnt die Erzwingung: Es gilt *5 Minuten*.

**Lösung 7.2.** (a) *Eigene OU* für Notebooks: Aufwand bei der Einrichtung hoch (Konten müssen richtig einsortiert werden), danach kein Laufzeitaufwand und gut sichtbar. (b) *Sicherheitsfilter mit Gruppe* (dynamisch gepflegt oder per Namenskonvention): geringer Aufwand, gut sichtbar, schnell, aber die Gruppenpflege muss stimmen. (c) *WMI-Filter* (etwa auf `Win32_SystemEnclosure`): zunächst einfach, aber langsamer bei jeder Verarbeitung und schwerer zu überblicken. (d) *Preference mit Zielgruppenadressierung* (Akku vorhanden): nur für Preferences möglich, sehr flexibel, aber nicht für Richtlinien. Empfehlung: OU oder Gruppe; WMI nur, wenn nichts anderes geht.

**Lösung 7.3.** Seit dem Update MS16-072 werden Benutzerrichtlinien im Sicherheitskontext des *Computers* abgerufen. Das Computerkonto braucht deshalb das Leserecht auf das GPO. Mit dem Entfernen von *Authenticated Users* wurde das Leserecht auch für die Computer entfernt. Lösung: Auf der Registerkarte *Delegierung* den Gruppen *Authenticated Users* oder *Domain Computers* das Recht *Lesen* (ohne *Übernehmen*) geben; keine Verweigerung setzen.

**Lösung 7.4.**

```powershell
$gpo = New-GPO -Name "C-Sicherheit-Bildschirmsperre" -Comment "Bildschirmsperre 10 Minuten"
Set-GPRegistryValue -Name $gpo.DisplayName -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "InactivityTimeoutSecs" -Type DWord -Value 600
New-GPLink -Name $gpo.DisplayName -Target "OU=Test,OU=Computer,OU=Contoso,DC=corp,DC=contoso,DC=com"
New-Item -ItemType Directory D:\GPO-Backup -Force | Out-Null
Backup-GPO -Name $gpo.DisplayName -Path D:\GPO-Backup
Get-GPOReport -Name $gpo.DisplayName -ReportType Html -Path "D:\GPO-Backup\bericht.html"
```

Die Verknüpfung erfolgt erst nach der Einstellung und an der Test-OU, nicht an der Domain. Die Sicherung ermöglicht jederzeit die Rückkehr zum vorherigen Stand mit `Restore-GPO`.

**Lösung 7.5.**

```powershell
param([Parameter(Mandatory)][string]$Ou)
$inh = Get-GPInheritance -Target $Ou
"Vererbung blockiert: " + $inh.GpoInheritanceBlocked
$inh.InheritedGpoLinks | Sort-Object Order |
    Select-Object @{n="Quelle";e={$_.Target}}, Order, DisplayName, Enabled, Enforced | Format-Table -AutoSize
```

Die Eigenschaft `InheritedGpoLinks` enthält alle wirksamen Verknüpfungen, geordnet nach Container und Reihenfolge. Die Spalte `Quelle` zeigt, an welchem Container die Verknüpfung liegt; so erkennt man, welche Einstellung von wo stammt.

**Lösung 7.6.** Die Befehle entsprechen Lerneinheit 7.5. Zum Prüfen dient `Get-GPPermission -Name ...{} -All`; in der Ausgabe muss *Authenticated Users* die Berechtigung `GpoRead` und die Zielgruppe `GpoApply` haben. Das Skript aus Schritt 4 der Lerneinheit liefert die Namen aller GPOs, bei denen weder *Authenticated Users* noch *Domain Computers* das Leserecht haben. Bei diesen GPOs fehlt das Leserecht der Computerkonten, weshalb Benutzereinstellungen nicht wirken.

**Lösung 7.7.** Das Skript aus Lerneinheit 7.7 baut den Speicher auf. Nach dem Kopieren sollte jede ADMX-Datei eine zugehörige ADML-Datei in `de-DE` oder `en-US` haben (Dateinamen ohne Endung gleich). Beim Öffnen des Editors zeigt der Knoten *Administrative Vorlagen* im Titel den Hinweis auf den zentralen Speicher („Richtliniendefinitionen (ADMX-Dateien), abgerufen von der zentralen Richtlinie“). Wird das nicht angezeigt, prüfen Sie `EnableLocalStoreOverride` und die Berechtigungen auf dem Ordner.

**Lösung 7.8.** Beispielvorgehen: Das GPO wird mit dem Sicherheitsfilter auf eine Gruppe, in der der Test-Computer *nicht* Mitglied ist, versehen. `gpresult /r /scope computer` listet das GPO unter „Abgelehnte GPOs“ mit dem Grund „Sicherheitsfilterung“. Die Behebung besteht darin, den Test-Computer in die Gruppe aufzunehmen (und den Computer neu zu starten, damit das Token die neue Gruppe enthält) oder die Filterung zu korrigieren. Dokumentiert werden die Befunde mit Datum und die verwendeten Befehle; das gesamte Vorgehen entspricht der sechsstufigen Reihenfolge aus Lerneinheit 7.9.
