# Modul 09 - AD Security, Hardening und Tiering

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Tabellen als Markdown-Tabellen, Übungsaufgaben und Lösungen als Absätze). Die Überschriften sind wie in der Quelle nach Modul und Lerneinheit nummeriert (9.1 bis 9.9; 9.10 Übungsaufgaben, 9.11 Lösungen). **Die PowerShell-Beispiele wurden für dieses Repository nicht ausgeführt**; sie setzen eine Windows-Server-Laborumgebung mit der fiktiven Domain `corp.contoso.com` voraus und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain. Übersicht zum Modul: [README](README.md).

|                                       |              |
|:--------------------------------------|:-------------|
| Dauer laut Modulübersicht             | 12 Stunden   |
| Summe der Lerneinheiten (Detailblatt) | 10,5 Stunden |
| Priorität                             | 1            |

| Nr. | Lerneinheit        | Dauer (h) | Prio |
|----:|:-------------------|----------:|-----:|
| 9.1 | Least Privilege    |         1 |    1 |
| 9.2 | Tier Model         |         1 |    1 |
| 9.3 | Privileged Groups  |       1,5 |    1 |
| 9.4 | Admin Workstations |         1 |    1 |
| 9.5 | Windows LAPS       |         1 |    1 |
| 9.6 | Audit Policy       |       1,5 |    1 |
| 9.7 | Angriffspfade      |         1 |    2 |
| 9.8 | Protected Users    |         1 |    2 |
| 9.9 | Security Review    |       1,5 |    2 |
|     | **Summe**          |  **10,5** |      |

> **Merke**
>
> Die Stundensumme der Lerneinheiten im Detailblatt (10,5 h) weicht von der Dauer in der Modulübersicht (12 h) ab. Dieses Skript behandelt alle Lerneinheiten des Detailblatts vollständig; die Abweichung ist im Lehrplan selbst zu klären.

Active Directory ist für Angreifer das attraktivste Ziel in einem Unternehmensnetz, weil wer die Domain beherrscht, praktisch jedes Konto, jeden Server und jede Arbeitsstation beherrscht. Ein typischer Angriff beginnt deshalb selten bei Active Directory selbst, sondern bei einem einzelnen Arbeitsplatz, einer gestohlenen Anmeldung oder einem schlecht geschützten Server und arbeitet sich dann Schritt für Schritt zu den privilegierten Konten vor. Dieses Modul behandelt die Gegenmittel: weniger Rechte, klare Trennung von Verwaltungsebenen, geschützte Verwaltungsarbeitsplätze, eindeutige lokale Administratorkennwörter, Protokollierung und eine regelmäßige Überprüfung. Der Gedanke dahinter ist immer derselbe: Man kann nicht verhindern, dass irgendwo ein Rechner kompromittiert wird, aber man kann dafür sorgen, dass der Schaden an dieser Stelle endet.

Die Anmeldung und Autorisierung selbst (Kerberos, NTLM, ACLs, Delegierung, Kennwortrichtlinien) wurde in Modul 8 behandelt; hier wird darauf aufgebaut. Zur Wiederherstellung nach einem erfolgreichen Angriff siehe Modul 10, zur laufenden Überwachung Modul 11. Die Beispiele verwenden die Laborumgebung `corp.contoso.com` mit der OU-Struktur aus Modul 3.

## 9.1 Least Privilege

Das *Prinzip der geringsten Rechte* (Least Privilege) besagt: Jedes Konto bekommt genau die Rechte, die es für seine Aufgabe braucht, und nur so lange, wie es sie braucht. Es klingt selbstverständlich, wird in der Praxis aber ständig verletzt, weil es bequemer ist, ein Konto zum Domain Admin zu machen, als eine passende Delegierung zu bauen. Das Ergebnis sind Dutzende Mitglieder in den mächtigsten Gruppen, Dienstkonten mit Domänenadministrator-Rechten „weil sonst etwas nicht läuft“ und Administratoren, die den ganzen Tag mit ihrem privilegierten Konto im Posteingang arbeiten. Jedes dieser Konten ist ein Weg, über den ein Angreifer mit einem einzigen Treffer die ganze Domain übernehmen kann.

Die Dokumentation zum Tier-Modell nennt dazu konkrete Grundsätze. Auch innerhalb der obersten Ebene braucht nicht jedes Konto die Rechte eines Domain Admins: Man verteilt die Berechtigungen auf das nötige Maß je Rolle. Und sie nennt als Orientierungswert, dass weniger als fünf Personen Domain-Admin-gleichwertigen Zugriff haben sollten und dass es keine Dienstkonten mit Domain-Admin-Rechten geben sollte. Praktisch heißt Least Privilege vier Dinge. Erstens trennt man *Rollen*: Wer Server verwaltet, braucht kein Recht auf Benutzerkonten, und wer Kennwörter zurücksetzt, braucht kein Recht auf Gruppenrichtlinien. Zweitens verwendet man *getrennte Konten*: Eine Person hat ein normales Konto für E-Mail und Web und ein eigenes Administrationskonto für die Verwaltung, das keine Mailbox und keinen Internetzugang hat. Drittens vergibt man Rechte *zeitlich begrenzt* (Just-in-Time): Statt dauerhaft Mitglied in einer mächtigen Gruppe zu sein, wird man für die Dauer einer Aufgabe aufgenommen. Viertens *prüft* man regelmäßig, ob Rechte noch gebraucht werden.

Das Active Directory bietet für das zeitlich begrenzte Mitglied eine eingebaute Technik an, die *zeitlich begrenzte Gruppenmitgliedschaft* (Time-Based Group Membership). Sie setzt die Gesamtstruktur-Funktionsebene Windows Server 2016 und das Aktivieren des optionalen Features „Privileged Access Management“ voraus; danach kann man jemanden mit einer Lebensdauer in eine Gruppe aufnehmen, und die Mitgliedschaft verfällt automatisch. Das folgende Skript zeigt drei Dinge: den Bestand der Mitglieder in den mächtigsten Gruppen, die temporäre Aufnahme und die Suche nach Dienstkonten, die in privilegierten Gruppen stehen.

```powershell
Import-Module ActiveDirectory

# 1) Bestand: Mitglieder der besonders maechtigen Gruppen (rekursiv)
$gruppen = "Enterprise Admins","Schema Admins","Domain Admins","Administrators"
foreach ($g in $gruppen) {
    $m = Get-ADGroupMember -Identity $g -Recursive -ErrorAction SilentlyContinue
    "{0}: {1} Mitglieder" -f $g, @($m).Count
    $m | Select-Object -ExpandProperty SamAccountName | Sort-Object | ForEach-Object { "   - $_" }
}

# 2) Optionales Feature "Privileged Access Management" einmalig aktivieren (Forest-weit, nicht rueckgaengig!)
Enable-ADOptionalFeature -Identity "Privileged Access Management Feature" `
    -Scope ForestOrConfigurationSet -Target "corp.contoso.com"

# 3) Temporaere Mitgliedschaft: 2 Stunden in einer Verwaltungsgruppe
Add-ADGroupMember -Identity "G-Server-Admins" -Members "adm.mmeier" `
    -MemberTimeToLive (New-TimeSpan -Hours 2)
Get-ADGroup "G-Server-Admins" -Properties member -ShowMemberTimeToLive |
    Select-Object -ExpandProperty member

# 4) Dienstkonten in privilegierten Gruppen finden (Hinweis auf Fehlkonfiguration)
$priv = Get-ADGroupMember -Identity "Domain Admins" -Recursive | Where-Object objectClass -eq "user"
foreach ($u in $priv) {
    $acc = Get-ADUser $u -Properties servicePrincipalName, PasswordNeverExpires, LastLogonDate
    if ($acc.servicePrincipalName -or $acc.PasswordNeverExpires) {
        [pscustomobject]@{ Konto=$acc.SamAccountName; HatSPN=[bool]$acc.servicePrincipalName
                           KennwortLaeuftNieAb=$acc.PasswordNeverExpires; LetzteAnmeldung=$acc.LastLogonDate }
    }
}
```

Schritt 1 zählt die Mitglieder der vier mächtigsten Gruppen, auch wenn sie nur über verschachtelte Gruppen enthalten sind (`-Recursive`); verschachtelte Mitgliedschaften sind ein häufig übersehener Weg zu Rechten. Schritt 2 aktiviert das Feature für die ganze Gesamtstruktur; das ist eine einmalige Aktion, die sich nicht rückgängig machen lässt und deshalb vorher geplant und im Labor getestet wird. Schritt 3 nimmt ein Administratorkonto für zwei Stunden in eine Gruppe auf (`-MemberTimeToLive`) und zeigt mit `-ShowMemberTimeToLive` die verbleibende Zeit; nach Ablauf entfernt das Verzeichnis die Mitgliedschaft selbst. Schritt 4 findet Konten in der Gruppe der Domain Admins, die einen SPN besitzen (also ein Dienstkonto sind und dann für Kerberoasting-Angriffe anfällig, siehe Lerneinheit 9.7) oder deren Kennwort nie abläuft.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, ein Problem mit Berechtigungen durch „mach den Benutzer zum Administrator“ zu lösen. Der zweite ist die Vermischung von Alltags- und Administrationskonto: Wer mit seinem Domain-Admin-Konto E-Mails liest, gibt dem Angreifer mit jedem geöffneten Anhang das Schlüsselbund. Der dritte ist, Mitgliedschaften nie wieder zu entfernen; über Jahre sammeln sich Konten ehemaliger Projektmitarbeiter und Dienstleister in mächtigen Gruppen.

```powershell
# FALSCH: Dauerhafte Mitgliedschaft fuer eine einmalige Aufgabe, im Alltagskonto
Add-ADGroupMember -Identity "Domain Admins" -Members "mmeier"

# RICHTIG: Eigenes Administrationskonto, nur in der noetigen Rollengruppe, zeitlich begrenzt
Add-ADGroupMember -Identity "G-Server-Admins" -Members "adm.mmeier" -MemberTimeToLive (New-TimeSpan -Hours 4)
```

> **Ergänzung aus der Nachrecherche**
>
> Die Grundsätze zur kleinen Tier-0-Gruppe (weniger als fünf Personen mit Domain-Admin-gleichwertigem Zugriff, keine Dienstkonten mit Domain-Admin-Rechten, Least Privilege auch innerhalb von Tier 0) belegt die abgerufene Seite „Tier model for Active Directory Domain Services“ (Microsoft Learn). Die Voraussetzungen und Cmdlet-Parameter der zeitlich begrenzten Gruppenmitgliedschaft (Funktionsebene 2016, Feature „Privileged Access Management“, `-MemberTimeToLive`) stammen aus dem Fachwissen und sind nicht abgerufen; bitte vor dem Einsatz im Labor prüfen.

### Praxisbezug

> **Praxisbeispiel**
>
> Bei der Inventur stellt ein Unternehmen fest, dass 23 Personen Mitglied der Domain Admins sind, darunter drei Auszubildende, ein früherer Dienstleister und zwei Dienstkonten. Nach einer Überprüfung bleiben fünf Personen übrig; für alles andere werden Rollengruppen mit Delegierung (Modul 8) geschaffen. Die Wartungsarbeiten, für die früher ein Domain-Admin-Konto genutzt wurde, laufen jetzt mit zeitlich begrenzter Mitgliedschaft. Der Schadensbereich eines gestohlenen Kontos schrumpft damit von „die ganze Domain“ auf „eine Aufgabe für ein paar Stunden“.

## 9.2 Tier Model

Das *Tier-Modell* teilt die Verwaltungswelt in Ebenen (Tiers), damit Anmeldedaten einer höheren Ebene nie in einer niedrigeren Ebene eingegeben werden. Die Microsoft-Dokumentation beschreibt es als Sicherheitsarchitektur, die administrative Identitäten, Arbeitsplätze und verwaltete Systeme in Vertrauensstufen trennt, damit ein Angreifer, der einen Endgeräte-Arbeitsplatz übernimmt, nicht höher privilegierte Anmeldedaten stehlen und sich bis zur Identitätsverwaltung hocharbeiten kann. Die Trennung beruht auf Berechtigungen und Identitäten, nicht auf der Netzwerkaufteilung, auch wenn sich beides ergänzt.

Es gibt drei Ebenen. *Tier 0* ist die Identitätskontrollebene: Domain Controller, AD FS, AD CS (die Zertifizierungsstellen), Microsoft Entra Connect sowie die Konten und Gruppen, die diese verwalten. Wer Tier 0 beherrscht, beherrscht alles. *Tier 1* umfasst Mitgliedsserver und Unternehmensanwendungen wie Exchange, SharePoint, SQL Server und Fachanwendungen sowie deren Administratoren. *Tier 2* umfasst Endgeräte und Benutzerkonten sowie den Helpdesk und die Rollen für Geräteverwaltung. Die Dokumentation fügt hinzu, dass das Modell Teil des breiteren *Enterprise Access Model* (EAM) ist, das Zugriffe auf lokale Systeme, mehrere Clouds und Anwendungszugriffe umfasst; dort wird Tier 0 zur „Kontrollebene“ (Control Plane) erweitert, und Tier 1 und Tier 2 werden weiter aufgeteilt.

Die zentrale Regel lautet: Ein Konto und ein Dienstkonto gehören zu *einer* Ebene, und Anmeldedaten einer höheren Ebene dürfen nie auf einem System einer niedrigeren Ebene verwendet werden. Der Grund ist technisch. Meldet sich ein Domain Admin an einem Arbeitsplatz oder Server an, bleiben seine Anmeldedaten (Kennwort-Hash, Kerberos-Tickets) im Speicher des Rechners, und ein Angreifer mit Rechten auf diesem Rechner kann sie auslesen und wiederverwenden (Pass-the-Hash, Pass-the-Ticket). Damit *fällt die Trennung*: Die Dokumentation sagt dazu deutlich, dass das Eingeben höherer Anmeldedaten auf einem niedriger vertrauenswürdigen Rechner diese sofort dessen Umgebung aussetzt. Die Rechte werden deshalb nicht nur vergeben, sondern aktiv *begrenzt*: Konten höherer Ebenen werden an Rechnern niedrigerer Ebenen mit den Benutzerrechten „Lokale Anmeldung verweigern“, „Anmelden über Remotedesktopdienste verweigern“ und „Anmelden als Stapelverarbeitungsauftrag verweigern“ ausgeschlossen. Die ältere Microsoft-Anleitung zum Privilegierten Zugriff beschreibt genau so ein Gruppenrichtlinienobjekt „Restrict Workstation Logon“, das an der obersten OU der Arbeitsplätze verknüpft ist und die Tier-0- und Tier-1-Gruppen aussperrt.

Das folgende Skript baut diese Sperre. Es legt die Gruppen für die Ebenen an, erzeugt ein GPO mit den Benutzerrechten und verknüpft es mit der OU der Arbeitsplätze. Danach prüft es, wo sich privilegierte Konten tatsächlich angemeldet haben.

```powershell
Import-Module ActiveDirectory, GroupPolicy
$base = "OU=Contoso,DC=corp,DC=contoso,DC=com"

# 1) Gruppen je Ebene (Verwaltungskonten kommen hier hinein)
foreach ($n in "G-Tier0-Admins","G-Tier1-Admins","G-Tier2-Admins") {
    if (-not (Get-ADGroup -Filter "Name -eq '$n'")) {
        New-ADGroup -Name $n -GroupScope Global -GroupCategory Security -Path "OU=Gruppen,$base"
    }
}

# 2) GPO anlegen und mit der OU der Arbeitsplaetze verknuepfen
$gpo = New-GPO -Name "C-Sicherheit-Tier-Anmeldung-Arbeitsplaetze" `
    -Comment "Tier-0/1-Konten duerfen sich nicht an Arbeitsplaetzen anmelden"
New-GPLink -Name $gpo.DisplayName -Target "OU=Arbeitsplaetze,OU=Computer,$base" -LinkEnabled Yes

# 3) Die Benutzerrechte "Anmelden verweigern" werden im GPO-Editor gesetzt (Zuweisung von Benutzerrechten):
#    Computerkonfiguration > Windows-Einstellungen > Sicherheitseinstellungen > Lokale Richtlinien >
#    Zuweisen von Benutzerrechten:
#      Lokal anmelden verweigern, Anmelden ueber Remotedesktopdienste verweigern,
#      Anmelden als Stapelverarbeitungsauftrag verweigern, Anmelden als Dienst verweigern
#    Eintraege: G-Tier0-Admins, G-Tier1-Admins, Domain Admins, Enterprise Admins, Schema Admins

# 4) Pruefen: Wo haben sich Konten der Tier-0-Gruppe angemeldet? (Ereignis 4624 auf den Computern)
$t0 = (Get-ADGroupMember "G-Tier0-Admins" -Recursive).SamAccountName
Get-WinEvent -ComputerName "PC01" -FilterHashtable @{LogName="Security";Id=4624;StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue |
  Where-Object { $t0 -contains ([xml]$_.ToXml()).Event.EventData.Data[5].'#text' } |
  Select-Object TimeCreated, @{n="Konto";e={([xml]$_.ToXml()).Event.EventData.Data[5].'#text'}}
```

Schritt 1 erzeugt je Ebene eine globale Sicherheitsgruppe, in die die Verwaltungskonten dieser Ebene aufgenommen werden. Schritt 2 erzeugt das GPO und verknüpft es mit der OU der Arbeitsplätze. Schritt 3 ist ein Kommentarblock, weil das Setzen der Benutzerrechte nicht über ein einfaches Cmdlet erfolgt, sondern über den Gruppenrichtlinien-Editor oder eine Sicherheitsvorlage; die Liste nennt die Rechte, die für die Tier-Sperre gesetzt werden. Schritt 4 liest die Anmeldeereignisse eines Rechners und zeigt, ob sich Tier-0-Konten trotz Sperre dort angemeldet haben; `Data[5]` ist das Feld mit dem Kontonamen im Ereignis 4624 und sollte beim eigenen Ereignis geprüft werden (Feldreihenfolge kann sich unterscheiden).

### Typische Fehler und Stolperfallen

Der erste häufige Fehler ist, das Modell nur als Namensschema umzusetzen (Konten „adm0“, „adm1“), ohne die Anmeldung technisch zu begrenzen; dann beweist das Namensschema nichts, und niemand merkt, wenn ein Tier-0-Konto an einem Arbeitsplatz arbeitet. Der zweite ist, Tier 0 „zu groß“ zu fassen: Wenn die Software-Verteilung, die Virenschutzkonsole oder die Backup-Software Domänencontroller verwalten kann, gehören diese Systeme und ihre Administratoren faktisch zu Tier 0. Der dritte ist, einen Sprungserver (Jump Server) zu verwenden, der ein Tier-1-System ist, aber für den Zugriff auf Tier-0-Systeme dient: Die Dokumentation hält fest, dass ein Zwischenschritt die Vertrauensstufe jeder Anmeldung übernimmt, die ihn berührt, und deshalb selbst zu Tier 0 gehört.

```powershell
# FALSCH: Domain-Admin-Konto auf einem Dateiserver (Tier 1) anmelden, "nur kurz"
mstsc /v:srv01.corp.contoso.com     # Anmeldung mit CORP\adm.mmeier (Domain Admin)

# RICHTIG: Fuer Tier 1 ein eigenes Konto, Tier-0-Konten per GPO fuer Tier-1-Server gesperrt
mstsc /v:srv01.corp.contoso.com     # Anmeldung mit CORP\adm1.mmeier (Mitglied von G-Tier1-Admins)
```

> **Ergänzung aus der Nachrecherche**
>
> Die Definition der drei Ebenen, die Einbettung ins Enterprise Access Model, die Regel „keine geteilten Anmeldedaten über Ebenen“, die Rolle der Sprungserver und das GPO „Restrict Workstation Logon“ mit den Benutzerrechten stammen aus den abgerufenen Seiten „Tier model for Active Directory Domain Services“, „Enterprise access model“ und „Legacy privileged access guidance“ (Microsoft Learn). Die Namen der Gruppen in diesem Skript sind Beispiele aus dem Labor. Das Benennungsschema „adm0/adm1“ ist eine verbreitete Praxis und keine Vorgabe von Microsoft.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein mittelständisches Unternehmen führt das Tier-Modell in drei Schritten ein. Erst werden die Systeme der Ebene 0 festgelegt (Domain Controller, Zertifizierungsstelle, Entra Connect) und die Konten der Administratoren getrennt. Dann folgt die technische Sperre per GPO an den Arbeitsplätzen und Servern. Zuletzt werden Verwaltungsarbeitsplätze eingeführt (Lerneinheit 9.4). Ein Monat nach der Einführung zeigen die Anmeldeprotokolle, dass sich ein Software-Verteilungsdienst mit einem Domain-Admin-Konto auf allen Arbeitsplätzen anmeldet; er wird auf ein eigenes eingeschränktes Konto umgestellt. Ohne die technische Sperre wäre das nie aufgefallen.

## 9.3 Privileged Groups

Die *privilegierten Gruppen* sind jene Gruppen, deren Mitglieder in der Domain oder der Gesamtstruktur umfassende Rechte besitzen. In Modul 8 wurde der Schutzmechanismus AdminSDHolder vorgestellt; die Microsoft-Dokumentation dazu nennt die geschützten Konten und Gruppen: Account Operators, Administrator, Administrators, Backup Operators, Domain Admins, Domain Controllers, Enterprise Admins, Enterprise Key Admins, Key Admins, Krbtgt, Print Operators, Read-only Domain Controllers, Replicator, Schema Admins und Server Operators. Davon sind drei die wichtigsten: *Enterprise Admins* (volle Rechte in der ganzen Gesamtstruktur, Mitglieder nur in der Stammdomain), *Domain Admins* (volle Rechte in einer Domain) und *Schema Admins* (dürfen das Schema ändern). Dazu kommt die lokale Gruppe *Administrators* auf den Domain Controllern, die faktisch dasselbe bedeutet wie die Domain Admins.

Die übrigen Gruppen werden oft unterschätzt. *Account Operators* dürfen Benutzer und Gruppen erstellen und ändern; *Server Operators* können sich an Domain Controllern anmelden und Dienste steuern; *Backup Operators* dürfen Daten sichern und wiederherstellen und können damit jede Datei lesen, auch die Active-Directory-Datenbank; *Print Operators* können sich ebenfalls an Domain Controllern anmelden. Wer in einer dieser Gruppen steht, kann mit etwas Aufwand Domain-Admin werden. Deshalb stehen sie in der älteren Microsoft-Anleitung zusammen mit den Domain Admins in der Liste der Tier-0-Gruppen, die auf niedrigeren Ebenen nicht anmelden dürfen. Als Faustregel gilt: In diesen Gruppen sollten im Normalbetrieb *keine* Mitglieder stehen, außer den Konten, die die Rolle unbedingt brauchen.

Das Ziel ist, Mitgliedschaften zu *minimieren* (so wenige wie möglich), zu *überwachen* (jede Änderung wird gemeldet) und *zeitlich zu begrenzen* (nur für die Dauer einer Aufgabe, Lerneinheit 9.1). Die Überwachung stützt sich auf die Ereignisse der Gruppenverwaltung: Hinzufügen zu einer Sicherheitsgruppe (Ereignis 4728 für globale, 4732 für lokale, 4756 für universelle Gruppen) und das Entfernen (4729, 4733, 4757). Das folgende Skript erstellt zuerst einen Bericht über alle geschützten Gruppen und prüft danach per Ereignisprotokoll, wer in den letzten sieben Tagen Mitglied geworden ist.

```powershell
Import-Module ActiveDirectory
$geschuetzt = "Enterprise Admins","Schema Admins","Domain Admins","Administrators",
              "Account Operators","Server Operators","Backup Operators","Print Operators",
              "Group Policy Creator Owners","DnsAdmins"

# 1) Bericht: Mitglieder aller geschuetzten Gruppen mit Typ und letzter Anmeldung
$bericht = foreach ($g in $geschuetzt) {
    $mitglieder = Get-ADGroupMember -Identity $g -Recursive -ErrorAction SilentlyContinue
    foreach ($m in $mitglieder) {
        $o = Get-ADObject $m.distinguishedName -Properties lastLogonTimestamp, whenCreated
        [pscustomobject]@{
            Gruppe = $g; Name = $m.SamAccountName; Typ = $m.objectClass
            LetzteAnmeldung = if ($o.lastLogonTimestamp) { [datetime]::FromFileTime($o.lastLogonTimestamp) } else { $null }
            Erstellt = $o.whenCreated
        }
    }
}
$bericht | Sort-Object Gruppe, Name | Export-Csv "D:\Berichte\PrivGruppen.csv" -NoTypeInformation -Encoding UTF8
$bericht | Group-Object Gruppe | Select-Object Name, Count

# 2) Aenderungen der letzten 7 Tage: Hinzufuegen zu Sicherheitsgruppen (4728, 4732, 4756) auf dem PDC-Emulator
$pdc = (Get-ADDomain).PDCEmulator
Get-WinEvent -ComputerName $pdc -FilterHashtable @{
    LogName="Security"; Id=4728,4732,4756; StartTime=(Get-Date).AddDays(-7) } |
  ForEach-Object {
    $x = [xml]$_.ToXml(); $d=@{}; foreach ($n in $x.Event.EventData.Data) { $d[$n.Name]=$n.'#text' }
    [pscustomobject]@{ Zeit=$_.TimeCreated; Gruppe=$d["TargetUserName"]; Mitglied=$d["MemberName"]; Durch=$d["SubjectUserName"] }
  } | Where-Object { $geschuetzt -contains $_.Gruppe } | Format-Table -AutoSize
```

Schritt 1 durchsucht jede geschützte Gruppe rekursiv und schreibt in einen Bericht, wer Mitglied ist, wann sich das Konto zuletzt angemeldet hat und wann es erstellt wurde; Konten, die seit Monaten nicht angemeldet waren, sind Kandidaten zum Entfernen. Der Wert `lastLogonTimestamp` wird nur etwa alle 14 Tage aktualisiert und ist deshalb für Aktivitätsprüfungen auf Wochen genau, nicht auf Tage. Schritt 2 liest auf dem PDC-Emulator die Ereignisse für das Hinzufügen von Mitgliedern und filtert sie auf die geschützten Gruppen; die Spalte „Durch“ nennt das Konto, das die Änderung vorgenommen hat. Der Bericht wird erst durch Übung wertvoll: Man vergleicht ihn jede Woche mit dem Soll und untersucht jede Abweichung.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, nur die drei bekannten Gruppen zu betrachten und die „Operators“ zu vergessen. Ein zweiter Fehler ist, verschachtelte Gruppen zu übersehen: Wenn die Gruppe „G-IT-Alle“ Mitglied der Domain Admins ist, sind alle ihre Mitglieder Administratoren, auch wenn sie in der Liste der Domain Admins nicht direkt auftauchen. Ein dritter Fehler ist, die Mitgliedschaft nur zu prüfen und nie zu entfernen: Der Bericht muss zu einer Entscheidung führen.

```powershell
# FALSCH: Nur die direkten Mitglieder ansehen
Get-ADGroupMember -Identity "Domain Admins"

# RICHTIG: Rekursiv, damit auch Mitglieder verschachtelter Gruppen sichtbar werden
Get-ADGroupMember -Identity "Domain Admins" -Recursive | Select-Object SamAccountName, objectClass
```

> **Ergänzung aus der Nachrecherche**
>
> Die Liste der geschützten Konten und Gruppen und die Erklärung von AdminSDHolder belegt die abgerufene Seite „Appendix C: Protected Accounts and Groups in Active Directory“ (Microsoft Learn); die Tier-0-Gruppenliste für das Sperren der Anmeldung steht in der abgerufenen „Legacy privileged access guidance“. Die Ereignis-IDs der Gruppenverwaltung (4728, 4732, 4756, 4729, 4733, 4757), die Einordnung der Operators-Gruppen und die Aktualisierung von `lastLogonTimestamp` etwa alle 14 Tage stammen aus dem Fachwissen und wurden nicht abgerufen.

### Praxisbezug

> **Praxisbeispiel**
>
> Jeden Montag erhält das Sicherheitsteam einen automatisch erzeugten Bericht über die Änderungen der Mitgliedschaften in den privilegierten Gruppen. Eines Montags steht dort ein unbekanntes Konto in der Gruppe „Backup Operators“ mit einer Anmeldung um 3 Uhr nachts. Die Untersuchung zeigt, dass ein Dienstleister sich ein Konto angelegt hatte, um Datensicherungen zu testen. Das Konto wird entfernt, die Zugriffsrichtlinie für Dienstleister überarbeitet. Der Bericht hat den Vorfall in sieben Tagen sichtbar gemacht; ohne ihn hätte er Monate unentdeckt bleiben können.

## 9.4 Admin Workstations

Eine *Privilegierte Administrationsworkstation* (Privileged Access Workstation, PAW) ist ein gehärteter Arbeitsplatzrechner, der ausschließlich für die administrative Arbeit verwendet wird. Der Grund steht in der Microsoft-Dokumentation zum Tier-Modell in einem Satz: Das Modell funktioniert nur, wenn man von einem vertrauenswürdigen Verwaltungsarbeitsplatz ausgeht, der zur Ebene des verwalteten Systems passt. Dort heißt es weiter, dass das Vertrauen an der ersten physischen Tastatur beginnt, mit der man sich anmeldet. Verwaltet ein Administrator Domain Controller von seinem normalen Büro-PC aus, auf dem er E-Mails liest und im Internet surft, bringt er seine mächtigen Anmeldedaten auf einen Rechner, der denselben Angriffen ausgesetzt ist wie jeder andere Arbeitsplatz. Dann ist das Tier-Modell wertlos, egal wie gut die Gruppen und Richtlinien sind.

Die Dokumentation nennt die Eigenschaften der „sauberen, vertrauenswürdigen physischen Tastatur“: Der Rechner ist gehärtet und für die Verwaltung einer bestimmten Ebene reserviert, er bleibt frei von Produktivlasten wie E-Mail, Webbrowser und nicht verwalteter Software, er entspricht der Ebene des Zielsystems, seine Lieferkette und sein physischer Schutz sind überprüft, und er wird ausschließlich für Verwaltungsaufgaben benutzt. Die Dokumentation beschreibt sechs Zugriffswege von einer PAW zu einem Tier-0-Server, darunter direkt, über einen Tier-0-Sprungserver, über eine Tier-0-Tresorlösung (Vault) mit Genehmigungsablauf und Just-in-Time-Zugriff sowie drei Varianten für eine Cloud-PAW. Für die Praxis bedeutet das: Zwischenschritte (Sprungserver, Bastion, Verwaltungsgateways) gehören zur gleichen Ebene wie das Ziel.

Zu den Härtungsmaßnahmen gehören eine aktuelle, nicht veraltete Windows-Version, ein eingeschränkter ausgehender Netzwerkverkehr (laut der Legacy-Anleitung soll der Zugriff nur auf autorisierte Dienste möglich sein und *kein offener Internetzugang* bestehen), Anwendungskontrolle (nur freigegebene Programme), Geräteverschlüsselung mit BitLocker, Schutz der Anmeldedaten (Credential Guard) und der Verzicht auf lokale Administratoren für die täglichen Arbeiten. Die Legacy-Anleitung führt auch die Rollen auf, für die eine PAW vorgesehen ist: Active-Directory-Administratoren (Tier 0), Administratoren der Virtualisierung (wenn Domain Controller darauf laufen, sind sie auch Tier 0), Serveradministratoren (Tier 1) und Helpdesk und Gerätesupport (Tier 2).

Eine einfache technische Absicherung lässt sich mit Windows-Firewall-Regeln und einer Anmeldebeschränkung erreichen. Das folgende Skript zeigt eine Grundkonfiguration für einen Verwaltungsarbeitsplatz: Es setzt ausgehende Blockierung als Standard, erlaubt nur die Verbindungen zu den Verwaltungszielen und zu den Domain Controllern, und prüft, ob BitLocker und Credential Guard aktiv sind. Es ist als Lernbeispiel gedacht; produktiv setzt man solche Einstellungen über Gruppenrichtlinien.

```powershell
# Lernbeispiel fuer einen Verwaltungsarbeitsplatz (Administrator-PowerShell)

# 1) Standard: ausgehenden Verkehr blockieren, eingehenden blockieren
Set-NetFirewallProfile -Profile Domain,Private,Public -DefaultOutboundAction Block -DefaultInboundAction Block

# 2) Erlauben: Verbindungen zu den Domain Controllern und Verwaltungszielen (Beispiel-Adressen)
$ziele = "10.10.0.11","10.10.0.12","10.10.0.21"
New-NetFirewallRule -DisplayName "PAW-Ausgehend-Verwaltung" -Direction Outbound -Action Allow `
    -RemoteAddress $ziele -Protocol TCP -RemotePort 53,88,135,389,445,636,3389,5985,5986,49152-65535
New-NetFirewallRule -DisplayName "PAW-Ausgehend-DNS-UDP" -Direction Outbound -Action Allow `
    -RemoteAddress $ziele -Protocol UDP -RemotePort 53,88,123

# 3) Zustand pruefen: BitLocker und Credential Guard
Get-BitLockerVolume -MountPoint "C:" | Select-Object MountPoint, ProtectionStatus, EncryptionPercentage
Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard |
    Select-Object SecurityServicesRunning, SecurityServicesConfigured

# 4) Pruefen: Wer ist lokal angemeldet, wer ist lokaler Administrator?
Get-LocalGroupMember -Group "Administratoren" | Select-Object Name, ObjectClass
quser
```

Schritt 1 stellt auf „alles blockieren“ um; das ist das Grundprinzip eines Verwaltungsarbeitsplatzes. Schritt 2 gibt gezielt die Verbindungen zu den Domain Controllern und zu den Verwaltungszielen frei: DNS (53), Kerberos (88), RPC (135), LDAP (389 und 636), SMB (445), Remotedesktop (3389), Remoteverwaltung per WinRM (5985 und 5986) und den dynamischen RPC-Bereich; die UDP-Regel erlaubt DNS, Kerberos und Zeitdienst. Die Zieladressen sind Beispiele aus dem Labor. Schritt 3 prüft, ob die Systemplatte mit BitLocker geschützt ist und ob Dienste der virtualisierungsbasierten Sicherheit (zu der Credential Guard gehört) laufen. Schritt 4 zeigt, wer lokaler Administrator ist und wer angemeldet ist; bei einem Verwaltungsarbeitsplatz sollten beide Listen kurz sein. Der Gruppenname „Administratoren“ gilt für deutsche Windows-Versionen; auf englischen heißt er „Administrators“.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die „PAW“ als virtuelle Maschine auf dem normalen Arbeitsplatz zu betreiben: Dann steht sie unter der Kontrolle des Gastgebers, der selbst eine Tier-2-Umgebung ist. Der zweite ist, im Verwaltungsarbeitsplatz doch einen Browser für die Recherche zuzulassen „nur für die Microsoft-Dokumentation“; ein einziger Aufruf einer manipulierten Seite genügt. Der dritte Fehler ist, für alle Ebenen dieselbe PAW zu verwenden: Anmeldedaten von Tier 0 und Tier 1 liegen dann gemeinsam im Speicher.

```powershell
# FALSCH: Tier-0-Verwaltung vom taeglichen Buero-PC aus
mstsc /v:dc01.corp.contoso.com     # vom Notebook, auf dem auch E-Mails gelesen werden

# RICHTIG: Von der eigenen Tier-0-PAW (keine E-Mail, kein freier Internetzugang)
mstsc /v:dc01.corp.contoso.com     # von PAW-T0-01, ausschliesslich fuer Verwaltung genutzt
```

> **Ergänzung aus der Nachrecherche**
>
> Die Eigenschaften der „sauberen, vertrauenswürdigen physischen Tastatur“, die Notwendigkeit eines zur Ebene passenden Arbeitsplatzes, die sechs Zugriffswege zu Tier-0-Systemen, die Zuordnung von Rollen zu PAWs und die Einschränkung des Internetzugangs belegen die abgerufenen Seiten „Tier model for Active Directory Domain Services“ und „Legacy privileged access guidance“ (Microsoft Learn). Die konkrete Portliste und die Befehle der Firewall-Regeln sind ein Lernbeispiel und stammen aus dem Fachwissen; sie müssen auf die eigene Umgebung angepasst werden.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen stellt für die vier Mitglieder des AD-Teams je ein gehärtetes Notebook bereit, das keine E-Mail-Software, keinen Webbrowser und keinen Internetzugang außer zu den Verwaltungszielen hat. Für die Dokumentation und E-Mail steht daneben der normale Arbeitsplatz. Die Administratoren beschweren sich anfangs über den Umweg, nach einigen Wochen gehört er zur Routine. Bei einem späteren Phishing-Vorfall auf einem Büro-PC eines Administrators sind seine Administrationskonten nicht betroffen, weil sie dort nie angemeldet waren.

## 9.5 Windows LAPS

In vielen Unternehmen besitzen alle Arbeitsplätze und Server dasselbe Kennwort für das lokale Administratorkonto, weil es bei der Installation so eingerichtet wurde. Das ist ein klassischer Weg für die *laterale Bewegung* im Netz: Wer auf einem Rechner das lokale Administratorkennwort (oder dessen Hash) erlangt, kann sich damit an allen anderen Rechnern anmelden. Die Microsoft-Dokumentation beschreibt *Windows LAPS* (Local Administrator Password Solution) als die Lösung: Das Feature verwaltet das Kennwort eines lokalen Administratorkontos automatisch, ändert es regelmäßig, speichert es sicher und lässt berechtigte Administratoren es abrufen, wenn sie sich anmelden oder ein Gerät wiederherstellen müssen. Jeder Rechner hat damit ein eigenes, zufälliges Kennwort.

Windows LAPS ist seit den Windows-Updates vom 11. April 2023 Teil von Windows, ist auf Windows Server 2019 und neuer sowie auf unterstützten Windows-10- und Windows-11-Clients verfügbar und kostet laut Dokumentation keine zusätzliche Lizenz, wenn die Kennwörter im lokalen Active Directory gespeichert werden. Die Sicherung nach Microsoft Entra ID erfordert mindestens die Lizenz Entra ID Free. Windows LAPS kann auch das Kennwort des Wiederherstellungskontos der Domain Controller (Directory Services Restore Mode, DSRM) verwalten, was für die Wiederherstellung (Modul 10) sehr nützlich ist. Das ältere „Microsoft LAPS“ (das herunterladbare Produkt) ist ab Windows 11 23H2 veraltet; Windows LAPS bietet einen Emulationsmodus für die Migration.

Wo wird das Kennwort gespeichert? Bei Active Directory auf dem Computerobjekt. Die Dokumentation beschreibt zwei Schutzschichten. Die erste sind *ACLs*: Wer die Kennwortattribute lesen darf, wird mit dem Cmdlet `Set-LapsADReadPasswordPermission` an einer OU festgelegt; wer das Ablaufdatum lesen und setzen darf (und damit eine Rotation auslösen kann), mit `Set-LapsADResetPasswordPermission`. Die zweite Schicht ist die *Verschlüsselung*: Das Kennwort wird noch auf dem verwalteten Gerät so verschlüsselt, dass nur ein bestimmter Sicherheitsprinzipal (Gruppe oder Benutzer) es entschlüsseln kann. Das setzt die Domänenfunktionsebene Windows Server 2016 oder höher voraus, und Microsoft empfiehlt ausdrücklich, die Verschlüsselung zu aktivieren. Der Standardwert der Richtlinie `ADPasswordEncryptionPrincipal` ist die Gruppe der Domain Admins; das Leserecht auf das Attribut bedeutet nicht automatisch das Recht zum Entschlüsseln.

Die Einrichtung folgt einer festen Reihenfolge, die das folgende Skript zeigt. Zuerst wird das Schema erweitert (einmalig für die Gesamtstruktur), dann werden die Berechtigungen an der OU gesetzt, danach wird die Richtlinie per GPO verteilt, und zuletzt wird das Kennwort abgerufen.

```powershell
Import-Module LAPS, ActiveDirectory
$ou = "OU=Arbeitsplaetze,OU=Computer,OU=Contoso,DC=corp,DC=contoso,DC=com"

# 1) Schema erweitern - einmalig fuer die gesamte Gesamtstruktur (Schema-Admin noetig)
Update-LapsADSchema -Verbose

# 2) Computer duerfen ihr Kennwort selbst aktualisieren (vererbbar an der OU)
Set-LapsADComputerSelfPermission -Identity "OU=Arbeitsplaetze,OU=Computer,OU=Contoso,DC=corp,DC=contoso,DC=com"

# 3) Wer darf das Kennwort lesen bzw. das Ablaufdatum zuruecksetzen?
Set-LapsADReadPasswordPermission  -Identity $ou -AllowedPrincipals "CORP\G-LAPS-Leser"
Set-LapsADResetPasswordPermission -Identity $ou -AllowedPrincipals "CORP\G-LAPS-Rotation"

# 4) Pruefen: Welche Identitaeten haben erweiterte Rechte auf der OU?
Find-LapsADExtendedRights -Identity $ou | Format-Table -AutoSize

# 5) Auditing der Kennwortabrufe einrichten (Lesezugriffe werden protokolliert)
Set-LapsADAuditing -Identity $ou -AuditedPrincipals "Authenticated Users" -AuditType Success

# 6) Richtlinie per GPO verteilen (Computerkonfiguration > Administrative Vorlagen > System > LAPS):
#    Kennwortquelle: Active Directory | Kennwortalter 30 Tage | Laenge 20 | Komplexitaet: gross, klein, Ziffern, Sonderzeichen
#    Verschluesselung aktivieren; Entschluesselungsgruppe: CORP\G-LAPS-Leser

# 7) Kennwort abrufen (nur mit Leserecht und Entschluesselungsrecht)
Get-LapsADPassword -Identity "PC01" -AsPlainText

# 8) Sofortige Rotation nach einem Vorfall oder Einsatz
Set-LapsADPasswordExpirationTime -Identity "PC01"       # Ablaufdatum auf jetzt setzen
Invoke-LapsPolicyProcessing                              # auf dem Client: Richtlinie sofort verarbeiten
Reset-LapsPassword                                       # auf dem Client: sofort rotieren
```

Schritt 1 erweitert das Schema; die Dokumentation nennt es einen einmaligen Vorgang für die gesamte Gesamtstruktur, der auf einem Domain Controller (Windows Server 2019 oder höher) oder auf einem anderen Rechner mit dem LAPS-Modul ausgeführt werden kann. Schritt 2 gibt den Computerkonten das Recht, ihr eigenes Kennwort zu schreiben; ohne dieses Recht scheitert die Sicherung. Die Rechte werden an der OU gesetzt und vererben sich auf die Computerobjekte. Schritt 3 trennt zwei Rollen: Wer das Kennwort liest, und wer die Rotation auslösen darf (das ist laut Dokumentation eine heikle, aber nicht zerstörerische Berechtigung, weil ein Angreifer damit nur häufigere Kennwortwechsel erzwingen kann). Schritt 4 zeigt, wer tatsächlich erweiterte Rechte hat; das ist die Kontrollliste für die Revision. Schritt 5 richtet die Überwachung ein, sodass jeder Abruf eines Kennworts protokolliert wird. Schritt 6 beschreibt die Gruppenrichtlinie (die Werte sind Beispiele). Schritt 7 ruft das Kennwort ab, Schritt 8 löst die Rotation aus: Die Dokumentation beschreibt, dass das Ablaufdatum im AD gesetzt wird und der Client beim nächsten Verarbeitungszyklus rotiert, oder mit `Invoke-LapsPolicyProcessing` und `Reset-LapsPassword` sofort.

### Typische Fehler und Stolperfallen

Der erste häufige Fehler ist, die Berechtigungen zu großzügig zu vergeben: Wer das LAPS-Kennwort lesen darf, ist lokaler Administrator an allen Rechnern in der OU. Der Leserecht-Kreis gehört in die Revision wie Domain Admins. Der zweite ist, die Verschlüsselung nicht zu aktivieren, obwohl die Domänenfunktionsebene sie erlaubt. Der dritte ist, *nach* dem Abruf nicht zu rotieren: Hat ein Techniker das Kennwort an einem Rechner benutzt, ist es danach in seinem Kopf, auf einem Zettel oder im Bildschirmmitschnitt. Ein vierter Fehler ist die Vermengung mit dem Konto „Administrator“: Wer das Standardkonto durch ein eigenes ersetzt, muss in der Richtlinie den Kontonamen angeben.

```powershell
# FALSCH: Alle Arbeitsplaetze haben dasselbe lokale Administratorkennwort,
#         gesetzt per Skript bei der Installation
net user Administrator "Sommer2024!"

# RICHTIG: Pro Rechner zufaelliges Kennwort, automatisch rotiert, in AD gespeichert und verschluesselt
Get-LapsADPassword -Identity "PC01" -AsPlainText
# Nach der Verwendung: Rotation ausloesen
Set-LapsADPasswordExpirationTime -Identity "PC01"
```

> **Ergänzung aus der Nachrecherche**
>
> Zweck, Plattformen, Lizenz, Speicherung auf dem Computerobjekt, ACL- und Verschlüsselungsschutz, Funktionsebene 2016 für die Verschlüsselung, den Standardwert der Entschlüsselungsgruppe, die Reihenfolge der Einrichtung, die Cmdlets (`Update-LapsADSchema`, `Set-LapsADComputerSelfPermission`, `Set-LapsADReadPasswordPermission`, `Set-LapsADResetPasswordPermission`, `Find-LapsADExtendedRights`, `Set-LapsADAuditing`, `Get-LapsADPassword`, `Set-LapsADPasswordExpirationTime`, `Invoke-LapsPolicyProcessing`, `Reset-LapsPassword`) und die Ablösung des alten Microsoft LAPS belegen die abgerufenen Seiten „What is Windows LAPS?“, „Key concepts in Windows LAPS“, „Get started with Windows LAPS and Windows Server Active Directory“ und „Overview of Windows LAPS PowerShell Cmdlets“ (Microsoft Learn). Die genauen Parameter von `Set-LapsADAuditing` und die Richtlinienwerte im Beispiel (Länge 20, Alter 30 Tage) stammen aus dem Fachwissen und wurden nicht abgerufen.

### Praxisbezug

> **Praxisbeispiel**
>
> Bei einem Penetrationstest übernimmt der Prüfer einen Arbeitsplatz und liest das lokale Administratorkennwort aus. In der alten Umgebung hätte er damit alle 600 Rechner erreicht. Nach der Einführung von Windows LAPS gilt das Kennwort nur für diesen einen Rechner, und es wird nach dem festgelegten Zeitraum geändert. Die Servicetechniker rufen es bei Bedarf über die Gruppe „G-LAPS-Leser“ ab; die Abrufe werden protokolliert. Zusätzlich wird das DSRM-Kennwort der Domain Controller über LAPS verwaltet, sodass es für die Wiederherstellung immer aktuell vorliegt.

## 9.6 Audit Policy

Schutzmaßnahmen allein genügen nicht, denn kein Schutz ist lückenlos. Deshalb braucht jede Umgebung eine *Protokollierung*, die festhält, wer wann was getan hat. Windows nennt diese Protokollierung *Überwachung* (Auditing). Sie ist in zwei Teile gegliedert: Zum einen legt man fest, *welche Kategorien* von Ereignissen im Sicherheitsprotokoll (Security-Log) aufgezeichnet werden; zum anderen legt man bei Objekten wie Dateien oder Active-Directory-Objekten über eine *SACL* (System Access Control List) fest, *welche Zugriffe* protokolliert werden. Die ACL entscheidet über den Zugriff, die SACL entscheidet über die Aufzeichnung (siehe Modul 8).

Windows kennt zwei Richtliniensysteme für Überwachung. Die älteren „Überwachungsrichtlinien“ bestehen aus nur neun groben Kategorien. Die *erweiterte Überwachungsrichtlinie* (Advanced Audit Policy Configuration) unterteilt diese Kategorien in Dutzende Unterkategorien, sodass man sehr gezielt protokollieren kann. Die Microsoft-Dokumentation zur Überwachung von Active Directory empfiehlt, die erweiterten Richtlinien zu verwenden, und weist darauf hin, dass beide Systeme nicht gemischt werden sollten: Wird die Einstellung „Überwachungsrichtlinie: Einstellungen für Überwachungsrichtlinien-Unterkategorien erzwingen“ (Force audit policy subcategory settings) aktiviert, haben die erweiterten Unterkategorien Vorrang vor den groben Kategorien. Ohne diese Einstellung kann die ältere Kategorie die neuen Werte überschreiben.

Für Domain Controller sind vor allem diese Unterkategorien wichtig: Kontoanmeldung (Kerberos-Authentifizierung und Kerberos-Dienstticketvorgänge), Anmelden/Abmelden (Anmelden, Abmelden, Sonderanmeldung, Kontosperrung), Kontoverwaltung (Benutzerkontenverwaltung, Sicherheitsgruppenverwaltung), Verzeichnisdienstzugriff (Änderungen an Verzeichnisdienstobjekten, Verzeichnisdienstreplikation), Richtlinienänderung (Überwachungsrichtlinie, Authentifizierungsrichtlinie) und Systemereignisse. Zu jeder gehört eine Ereignis-ID, die man kennen sollte: 4624 und 4625 für erfolgreiche und fehlgeschlagene Anmeldungen, 4672 für Anmeldungen mit besonderen Rechten, 4720 für das Anlegen eines Benutzerkontos, 4724 für einen Kennwortreset, 4728/4732/4756 für Gruppenänderungen, 4740 für eine Kontosperrung, 4768/4769/4771 für Kerberos-Tickets und 5136 für die Änderung eines Verzeichnisobjekts. Welche Ereignisse auf Domain Controllern besonders beobachtet werden sollten, listet Microsoft im Anhang „Events to Monitor“ auf.

Das folgende Beispiel setzt die erweiterte Überwachung für Domain Controller über `auditpol`, erhöht die Größe des Sicherheitsprotokolls, damit Ereignisse nicht nach Stunden überschrieben werden, und liest anschließend gezielt Ereignisse aus. In einer Produktivumgebung verteilt man dieselben Einstellungen per GPO an die OU „Domain Controllers“.

```powershell
# 1) Erweiterte Unterkategorien erzwingen (Registry-Aequivalent der GPO-Einstellung)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v SCENoApplyLegacyAuditPolicy /t REG_DWORD /d 1 /f

# 2) Wichtige Unterkategorien aktivieren (Erfolg und Fehler)
auditpol /set /subcategory:"Kerberos Authentication Service"     /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Service Ticket Operations"  /success:enable /failure:enable
auditpol /set /subcategory:"User Account Management"             /success:enable /failure:enable
auditpol /set /subcategory:"Security Group Management"           /success:enable /failure:enable
auditpol /set /subcategory:"Directory Service Changes"           /success:enable
auditpol /set /subcategory:"Logon"                               /success:enable /failure:enable
auditpol /set /subcategory:"Account Lockout"                     /failure:enable
auditpol /set /subcategory:"Special Logon"                       /success:enable
auditpol /get /category:*

# 3) Sicherheitsprotokoll vergroessern (hier 1 GB) und nicht ueberschreiben, sondern archivieren
wevtutil sl Security /ms:1073741824
wevtutil gl Security | Select-String "maxSize|retention"

# 4) Auswertung: Anmelde-Fehlschlaege der letzten Stunde, gruppiert nach Konto und Quelle
Get-WinEvent -FilterHashtable @{LogName="Security";Id=4625;StartTime=(Get-Date).AddHours(-1)} -ErrorAction SilentlyContinue |
  ForEach-Object {
    $d=@{}; foreach ($n in ([xml]$_.ToXml()).Event.EventData.Data) { $d[$n.Name]=$n.'#text' }
    [pscustomobject]@{ Konto=$d["TargetUserName"]; Quelle=$d["IpAddress"]; Typ=$d["LogonType"] }
  } | Group-Object Konto, Quelle | Sort-Object Count -Descending | Select-Object -First 10 Count, Name
```

Schritt 1 setzt den Registrywert, der die erweiterten Unterkategorien gegenüber den groben Kategorien durchsetzt; per GPO findet man dieselbe Option unter den lokalen Richtlinien (Sicherheitsoptionen). Schritt 2 aktiviert die Unterkategorien; die englischen Namen funktionieren mit `auditpol` unabhängig von der Sprache des Betriebssystems. Mit `auditpol /get /category:*` prüft man das Ergebnis. Schritt 3 vergrößert das Sicherheitsprotokoll; der Standardwert ist für einen Domain Controller viel zu klein, weil ein einziger belebter Tag das Protokoll füllen kann. Schritt 4 liest die fehlgeschlagenen Anmeldungen der letzten Stunde, wandelt jedes Ereignis in ein Objekt um und gruppiert nach Konto und Quelladresse. Viele Fehlschläge desselben Kontos von einer Adresse deuten auf ein falsch konfiguriertes Programm hin, viele Konten von einer Adresse auf einen Kennwort-Sprühangriff (Password Spraying).

### Typische Fehler und Stolperfallen

Der erste Fehler ist, *zu wenig* zu protokollieren: Wer ohne Kerberos- und Gruppenereignisse arbeitet, kann nach einem Vorfall nicht rekonstruieren, was passiert ist. Der zweite Fehler ist, *alles* zu protokollieren: Dann füllt sich das Protokoll in Minuten, und die wichtigen Ereignisse gehen im Rauschen unter. Der dritte Fehler ist, die Protokolle nur lokal auf dem Domain Controller zu lassen; ein Angreifer mit Administratorrechten löscht das Protokoll (Ereignis 1102), und die Spuren sind weg. Protokolle gehören deshalb zusätzlich an einen zentralen Ort (Event-Weiterleitung, SIEM, siehe Modul 11).

```powershell
# FALSCH: Nur die groben Kategorien nutzen und das Protokoll bei 20 MB belassen
auditpol /set /category:"Account Logon" /success:enable

# RICHTIG: Gezielte Unterkategorien, grosses Protokoll, Ereignisse zentral sammeln
auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable /failure:enable
wevtutil sl Security /ms:1073741824
```

> **Ergänzung aus der Nachrecherche**
>
> Die Empfehlung, die erweiterte Überwachungsrichtlinie zu verwenden, die Wechselwirkung mit den groben Kategorien und die Liste der auf Domain Controllern zu beobachtenden Ereignisse stützen sich auf die abgerufenen Seiten „Advanced Audit Policy Configuration“, „Monitoring Active Directory for Signs of Compromise“ und „Appendix L: Events to Monitor“ (Microsoft Learn). Die Ereignis-IDs im Fließtext, der Registrywert `SCENoApplyLegacyAuditPolicy` und die Protokollgröße im Beispiel stammen aus dem Fachwissen und wurden nicht einzeln abgerufen; die Protokollgröße ist ein Beispielwert und hängt vom Ereignisaufkommen ab.

### Praxisbezug

> **Praxisbeispiel**
>
> Nach einem Sicherheitsvorfall fragt die Geschäftsführung: „Wer hat das Konto angelegt, und wann?“ Dank der Unterkategorie Benutzerkontenverwaltung liegt das Ereignis 4720 vor, mit dem Namen des Erstellers, der Uhrzeit und dem Arbeitsplatz. Ohne Überwachung bliebe nur die Aussage „das Konto existiert“. Die Revision nutzt dieselben Protokolle später, um nachzuweisen, dass Änderungen an privilegierten Gruppen nachvollziehbar sind.

## 9.7 Angriffspfade

Angreifer gehen selten direkt zum Ziel, sondern folgen einem *Angriffspfad*: einer Kette aus kleinen Schwächen, die zusammen zur Übernahme der Domain führen. Man kann das als Graph sehen. Die Knoten sind Konten, Gruppen und Rechner, die Kanten sind Beziehungen wie „ist Mitglied von“, „hat eine Sitzung auf“, „darf Kennwort zurücksetzen für“ oder „ist lokaler Administrator auf“. Findet ein Angreifer einen Weg vom ersten übernommenen Arbeitsplatz zu den Domain Admins, hat er gewonnen. Für Verteidiger ist derselbe Gedanke nützlich: Wer die Pfade kennt, kann sie trennen.

Die häufigsten Techniken, die Microsoft in seinen Sicherheitsleitfäden beschreibt, sind diese. Beim *Auslesen von Anmeldedaten* (Credential Theft) holt sich der Angreifer Kennwort-Hashes oder Kerberos-Tickets aus dem Speicher eines Rechners, auf dem sich ein privilegiertes Konto angemeldet hat. Beim *Pass-the-Hash* wird der gestohlene Hash direkt zur Authentifizierung verwendet (NTLM, siehe Modul 8), ohne das Klartextkennwort zu kennen; beim *Pass-the-Ticket* ein gestohlenes Kerberos-Ticket. Beim *Kerberoasting* fordert ein normaler Domänenbenutzer Diensttickets für Konten mit einem SPN an und knackt die Verschlüsselung offline; das Ziel sind Dienstkonten mit schwachen Kennwörtern. Beim *Kennwort-Sprühen* (Password Spraying) probiert man wenige gängige Kennwörter bei vielen Konten durch, um Kontosperrungen zu umgehen. Bei *DCSync* gibt sich ein Konto mit Replikationsrechten als Domain Controller aus und fordert Kennwort-Hashes aller Konten an; die Rechte dafür sind „Replicating Directory Changes“ und „Replicating Directory Changes All“. Beim *Golden Ticket* fälscht ein Angreifer, der den Hash des Kontos `krbtgt` besitzt, beliebige Kerberos-Tickets. Beim Missbrauch von *Berechtigungen* (ACL-Missbrauch) nutzt er zu großzügige Rechte auf Objekte, etwa „GenericAll“ auf einer Gruppe, um sich selbst aufzunehmen.

Die Gegenmaßnahmen folgen aus den vorherigen Lerneinheiten: Tier-Modell und Anmeldebeschränkungen gegen den Diebstahl hochwertiger Anmeldedaten, Windows LAPS gegen die Wiederverwendung lokaler Kennwörter, gMSA (Modul 4) mit langen, automatisch gewechselten Kennwörtern gegen Kerberoasting, Protected Users (Lerneinheit 9.8) gegen NTLM- und Delegierungsmissbrauch, Überwachung der Replikationsrechte gegen DCSync und das zweimalige Zurücksetzen des `krbtgt`-Kontos nach einem Vorfall (Modul 10).

Das folgende Skript sucht im eigenen Verzeichnis nach den Voraussetzungen solcher Pfade, also nach dem, was ein Angreifer ausnutzen würde. Es prüft Konten mit SPN und schwacher Verschlüsselung, Konten ohne Kerberos-Vorauthentifizierung, uneingeschränkte Delegierung und Konten mit Replikationsrechten.

```powershell
Import-Module ActiveDirectory
$dom = (Get-ADDomain).DistinguishedName

# 1) Benutzerkonten mit SPN (Kerberoasting-Ziele), mit Kennwortalter und Gruppenmitgliedschaft
Get-ADUser -Filter 'servicePrincipalName -like "*"' -Properties servicePrincipalName, PasswordLastSet, AdminCount, 'msDS-SupportedEncryptionTypes' |
  Select-Object SamAccountName, PasswordLastSet, AdminCount, 'msDS-SupportedEncryptionTypes',
                @{n="SPNs";e={$_.servicePrincipalName -join "; "}}

# 2) Konten ohne Kerberos-Vorauthentifizierung (AS-REP-Roasting)
Get-ADUser -Filter 'DoesNotRequirePreAuth -eq $true' | Select-Object SamAccountName, Enabled

# 3) Uneingeschraenkte Delegierung (ausser Domain Controller)
Get-ADComputer -Filter 'TrustedForDelegation -eq $true' | Where-Object { $_.Name -notmatch '^DC' } | Select-Object Name
Get-ADUser -Filter 'TrustedForDelegation -eq $true' | Select-Object SamAccountName

# 4) Wer hat Replikationsrechte (DCSync-faehig)? Rechte auf dem Domaenenkopf pruefen
$acl = Get-Acl "AD:\$dom"
$repl = @("1131f6aa-9c07-11d1-f79f-00c04fc2dcd2","1131f6ad-9c07-11d1-f79f-00c04fc2dcd2")   # GUIDs der beiden Replikationsrechte
$acl.Access | Where-Object { $repl -contains $_.ObjectType.Guid -and $_.AccessControlType -eq "Allow" } |
  Select-Object IdentityReference, ActiveDirectoryRights | Sort-Object IdentityReference -Unique

# 5) Konten mit AdminCount=1, die kein Mitglied einer geschuetzten Gruppe mehr sind (verwaiste Rechte)
Get-ADUser -Filter 'AdminCount -eq 1' -Properties AdminCount, MemberOf | Where-Object { -not $_.MemberOf } |
  Select-Object SamAccountName
```

Schritt 1 listet die Benutzerkonten mit SPN. Für jedes dieser Konten kann jeder Domänenbenutzer ein Ticket anfordern; entscheidend ist, wie stark das Kennwort ist. Ein Konto mit `AdminCount` gleich 1 und SPN ist besonders gefährlich. Schritt 2 sucht Konten, für die keine Vorauthentifizierung nötig ist; ihre Antworten lassen sich ohne Anmeldung anfordern und offline angreifen. Schritt 3 findet Rechner und Konten mit uneingeschränkter Delegierung: Wer sich an einem solchen Rechner anmeldet, hinterlässt dort ein weiterleitbares Ticket (Modul 8). Schritt 4 liest die ACL des Domänenkopfs und filtert auf die zwei GUIDs der Replikationsrechte; erwartet werden hier nur Domain Controller und die Gruppen „Domain Admins“, „Enterprise Admins“ und „Administrators“. Schritt 5 findet Konten, die früher geschützt waren, bei denen das Attribut `AdminCount` aber stehen geblieben ist und die dadurch eine eingeschränkte Vererbung ihrer ACL behalten.

### Typische Fehler und Stolperfallen

Ein häufiger Fehler ist, nur nach Sicherheitslücken *in Software* zu suchen und die Konfigurationslücken zu übersehen: Die meisten erfolgreichen Domänenübernahmen nutzen keine Schwachstelle, sondern zu großzügige Rechte und alte Kennwörter. Ein zweiter Fehler ist, Dienstkonten mit schwachen Kennwörtern zu betreiben, „weil sich das Kennwort nie ändern darf“. Ein dritter ist, Prüfwerkzeuge nur einmal laufen zu lassen. Die Struktur ändert sich täglich, und mit ihr die Pfade.

```powershell
# FALSCH: Dienstkonto als normales Benutzerkonto, Kennwort "nie ablaufend", Mitglied der Domain Admins
New-ADUser -Name "svc-backup" -AccountPassword (ConvertTo-SecureString "Backup2020!" -AsPlainText -Force) -PasswordNeverExpires $true -Enabled $true

# RICHTIG: gMSA mit automatischem 240-Zeichen-Kennwort (Modul 4), nur die noetigen Rechte
New-ADServiceAccount -Name "gmsa-backup" -DNSHostName "gmsa-backup.corp.contoso.com" `
    -PrincipalsAllowedToRetrieveManagedPassword "G-Backup-Server"
```

> **Ergänzung aus der Nachrecherche**
>
> Die Techniken und ihre Gegenmaßnahmen sind in den abgerufenen Seiten „Best Practices for Securing Active Directory“ und „Monitoring Active Directory for Signs of Compromise“ (Microsoft Learn) beschrieben, soweit sie dort in den ausgewerteten Auszügen vorkamen. Die genauen Rechte-GUIDs der Replikationsrechte, die Eigenschaften der Konten im Skript (`DoesNotRequirePreAuth`, `TrustedForDelegation`) und die Beschreibung der Angriffsabläufe stammen aus dem Fachwissen und sind nicht einzeln abgerufen worden. Das Skript ist ein Prüfwerkzeug für die *eigene* Umgebung; es darf nur mit Erlaubnis des Verantwortlichen eingesetzt werden.

### Praxisbezug

> **Praxisbeispiel**
>
> Das Sicherheitsteam führt vierteljährlich eine „Pfadanalyse“ durch. Dafür werden Gruppen, Sitzungen und lokale Administratoren erfasst und als Graph ausgewertet. Beim ersten Durchlauf zeigt sich, dass die Gruppe „G-Helpdesk“ über eine Verschachtelung lokaler Administrator auf einem Server ist, auf dem ein Domain-Admin-Konto angemeldet ist. Der Pfad „Helpdesk → Server → Domain Admin“ wird getrennt, indem die Verschachtelung entfernt wird. Es war kein Angriff nötig, um die Schwäche zu finden, nur die systematische Suche.

## 9.8 Protected Users

Die Gruppe *Protected Users* ist eine eingebaute globale Sicherheitsgruppe, die Mitglieder automatisch gegen eine Reihe von Anmeldedaten-Angriffen härtet. Sie ist ab Windows Server 2012 R2 verfügbar und wirkt erst, wenn die Domänenfunktionsebene mindestens Windows Server 2012 R2 beträgt; für einen Teil der Schutzwirkung auf der Clientseite muss der Rechner Windows 8.1 oder Windows Server 2012 R2 oder neuer sein. Es genügt, ein Konto in die Gruppe aufzunehmen; es sind keine weiteren Einstellungen nötig.

Die Wirkung der Gruppe ist klar umrissen. Auf Geräten (Windows 8.1 / Server 2012 R2 und neuer) wird für Mitglieder kein Klartextkennwort mehr im Zwischenspeicher gehalten (Credential Delegation, CredSSP und WDigest speichern keine Klartextanmeldedaten), NTLM-Hashes werden nicht mehr zwischengespeichert, und auch Kerberos erzeugt keine langfristigen Schlüssel aus DES oder RC4 mehr. Außerdem gibt es für Mitglieder auf der Domänencontroller-Seite keine Anmeldung mit NTLM, keine DES- oder RC4-Verschlüsselung in der Kerberos-Vorauthentifizierung, keine uneingeschränkte oder eingeschränkte Delegierung, und die Lebensdauer des TGT ist auf vier Stunden beschränkt (danach muss man sich neu authentifizieren). Das erschwert Pass-the-Hash, offline angreifbare Schlüsselformate und die Weiterleitung von Anmeldedaten erheblich.

Die Schutzgruppe hat Nebenwirkungen, die man vorher kennen muss. Weil NTLM nicht funktioniert, funktionieren Anwendungen nicht, die sich nur mit NTLM anmelden können, und Anmeldungen an Rechnern über die IP-Adresse (die auf NTLM zurückfällt) schlagen fehl; Mitglieder müssen Server mit dem Namen ansprechen, damit Kerberos verwendet wird. Weil Anmeldedaten nicht zwischengespeichert werden, ist die Anmeldung an einem Notebook ohne Verbindung zum Domain Controller nicht möglich. Die Microsoft-Dokumentation rät deshalb ausdrücklich, *keine Dienstkonten und keine Computerkonten* in die Gruppe aufzunehmen, weil deren Kennwörter und Schlüssel nicht durch diese Technik geschützt werden können und die Dienste ausfallen würden. Außerdem sollte man die Gruppe nicht vorschnell für alle Administratoren aktivieren, ohne einen Test mit einem einzelnen Konto zu machen. Notfallkonten (Break-Glass-Konten) gehören nicht hinein.

Wer noch mehr Kontrolle braucht, nutzt *Authentifizierungsrichtlinien und Silos*: Mit ihnen lässt sich für bestimmte Konten festlegen, an welchen Rechnern sie sich anmelden dürfen und wie lange das TGT gültig ist (Windows Server 2012 R2 und neuer, Domänenfunktionsebene entsprechend). Ein Silo fasst Benutzer-, Computer- und Dienstkonten zusammen, für die dieselbe Richtlinie gilt. Das ist die technische Umsetzung der Anmeldebeschränkung aus dem Tier-Modell, nur auf der Seite des Domain Controllers statt per Benutzerrecht auf dem einzelnen Rechner.

Das folgende Beispiel nimmt ein einzelnes Testkonto in die Gruppe auf, legt eine Authentifizierungsrichtlinie an, die ein Konto auf die Anmeldung an Tier-0-Rechnern beschränkt, und zeigt, wie man das Verhalten im Ereignisprotokoll prüft.

```powershell
Import-Module ActiveDirectory

# 1) Domaenenfunktionsebene pruefen (mindestens Windows2012R2Domain)
(Get-ADDomain).DomainMode

# 2) Ein Testkonto aufnehmen - NICHT gleich alle Administratoren
Add-ADGroupMember -Identity "Protected Users" -Members "adm.test"
Get-ADGroupMember -Identity "Protected Users" | Select-Object SamAccountName, objectClass

# 3) Authentifizierungsrichtlinie: TGT-Lebensdauer 240 Minuten, Anmeldung nur von Tier-0-Rechnern
#    (SDDL-Bedingung mit der Gruppe der Tier-0-Rechner, hier mit Platzhalter-SID)
New-ADAuthenticationPolicy -Name "AP-Tier0-Admins" `
    -UserTGTLifetimeMins 240 `
    -UserAllowedToAuthenticateFrom "O:SYG:SYD:(XA;OICI;CR;;;WD;(@USER.ad://ext/AuthenticationSilo == `"AS-Tier0`"))" `
    -Enforce:$false     # zuerst nur auditieren (Testmodus)

# 4) Silo anlegen und das Konto zuordnen
New-ADAuthenticationPolicySilo -Name "AS-Tier0" -UserAuthenticationPolicy "AP-Tier0-Admins" -Enforce:$false
Grant-ADAuthenticationPolicySiloAccess -Identity "AS-Tier0" -Account "adm.test"
Set-ADUser "adm.test" -AuthenticationPolicySilo "AS-Tier0"

# 5) Pruefen: Ereignisse zu Authentifizierungsrichtlinien (Kerberos-Operational-Log auf dem DC)
Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Authentication/AuthenticationPolicyFailures-DomainController"} -MaxEvents 20 -ErrorAction SilentlyContinue |
  Select-Object TimeCreated, Id, Message
```

Schritt 1 prüft die Voraussetzung. Schritt 2 nimmt ein Konto auf; das Testkonto zeigt, ob Anwendungen und Anmeldewege noch funktionieren, bevor man echte Administratorkonten hinzufügt. Schritt 3 legt die Richtlinie im Testmodus an (`-Enforce:$false`), das heißt, Verstöße werden protokolliert, aber nicht blockiert. Die SDDL-Bedingung im Beispiel ist ein Platzhalter und muss mit den realen Rechnergruppen formuliert werden; dafür wird in der Praxis meist der Bedingungseditor in der Verwaltungskonsole verwendet. Schritt 4 erzeugt das Silo und ordnet das Konto zu. Schritt 5 liest das Protokoll, in dem Verstöße gegen die Richtlinie stehen. Erst wenn die Auditphase keine Fehler zeigt, schaltet man auf „Erzwingen“.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, die Gruppe bei allen Administratoren auf einmal zu aktivieren und dann festzustellen, dass die Verbindung zu einem älteren Server nicht mehr geht, der nur NTLM kann. Der zweite ist, Dienst- oder Computerkonten aufzunehmen. Der dritte ist, den Namen eines Servers durch seine IP-Adresse zu ersetzen: Das erzwingt NTLM, und die Anmeldung scheitert.

```powershell
# FALSCH: Verbindung per IP-Adresse (erzwingt NTLM, scheitert fuer Protected Users)
mstsc /v:10.10.0.11

# RICHTIG: Verbindung per Namen (Kerberos)
mstsc /v:dc01.corp.contoso.com

# Fehlersuche: Welche Tickets hat die Sitzung? (Kerberos aktiv?)
klist
```

> **Ergänzung aus der Nachrecherche**
>
> Die Schutzwirkungen der Gruppe, die Voraussetzungen (Funktionsebene, Clientversionen), die Empfehlung, keine Dienst- und Computerkonten aufzunehmen, sowie die Erklärung der Authentifizierungsrichtlinien und Silos belegen die abgerufenen Seiten „Protected Users Security Group“ und „Authentication Policies and Authentication Policy Silos“ (Microsoft Learn); der Fehler 0x8009030e bei Kerberos im Zusammenhang mit der Gruppe wird in der abgerufenen Fehlerbehebungsseite zu `klist` beschrieben. Die Details der Cmdlet-Parameter, insbesondere die SDDL-Bedingung für `-UserAllowedToAuthenticateFrom`, stammen aus dem Fachwissen und müssen im Labor geprüft werden.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen nimmt zunächst die zwei Mitglieder des AD-Teams in „Protected Users“ auf und beobachtet zwei Wochen lang die Fehlermeldungen. Dabei stellt sich heraus, dass eine alte Verwaltungsoberfläche für das Backup nur per IP-Adresse erreichbar ist. Sie wird auf einen DNS-Namen umgestellt. Danach kommen alle Administratoren hinzu; die Notfallkonten bleiben bewusst draußen und sind in einem versiegelten Umschlag dokumentiert, mit alarmierter Anmeldung.

## 9.9 Security Review

Eine *Sicherheitsüberprüfung* (Security Review) ist die regelmäßige, strukturierte Kontrolle, ob die Maßnahmen dieses Moduls noch wirken. Sie ist nötig, weil Active Directory sich ständig verändert: Konten kommen und gehen, Gruppen wachsen, Ausnahmen werden „nur kurz“ eingerichtet und nie zurückgenommen. Eine Überprüfung ist erst dann nützlich, wenn sie ein festes Ergebnis liefert: einen Bericht mit Befunden, Verantwortlichen und Terminen.

Eine gute Überprüfung gliedert sich in Prüfbereiche, und die Bereiche dieses Moduls ergeben die Gliederung. Erstens die privilegierten Konten und Gruppen: Wer ist drin, wer sollte nicht drin sein, welche Konten sind verwaist. Zweitens die Anmeldebeschränkungen des Tier-Modells: Melden sich privilegierte Konten nur dort an, wo sie dürfen. Drittens die lokalen Administratorkennwörter: Ist Windows LAPS flächendeckend aktiv und sind Lese- und Rotationsrechte korrekt. Viertens die Konten mit besonderen Eigenschaften: Dienstkonten mit SPN, Konten ohne Vorauthentifizierung, nie ablaufende Kennwörter, uneingeschränkte Delegierung. Fünftens die Protokollierung: Sind die Audit-Kategorien aktiv, ist das Protokoll groß genug, kommen die Ereignisse zentral an. Sechstens die Richtlinien: Kennwortrichtlinien, Kontosperrung und der Zustand der GPOs. Siebtens die Domain Controller selbst: Betriebssystemstand, Patchstand und Zustand der Replikation (Modul 5 und 11).

Microsoft stellt für solche Prüfungen Referenzen bereit: die Leitfäden zur Absicherung von Active Directory und die Sicherheits-Baselines, die man mit dem *Security Compliance Toolkit* herunterladen und mit der eigenen Konfiguration vergleichen kann. Daneben gibt es Werkzeuge von Drittanbietern, die Fehlkonfigurationen automatisch finden. Entscheidend ist weniger das Werkzeug als die Gewohnheit: Wer jeden Monat dieselben zehn Prüfungen ausführt, erkennt Abweichungen, bevor ein Angreifer sie findet.

Das folgende Skript automatisiert einen Teil der Überprüfung und erzeugt einen HTML-Bericht mit den wichtigsten Kennzahlen. Es ist bewusst einfach gehalten, damit es sich leicht erweitern lässt.

```powershell
Import-Module ActiveDirectory
$heute = Get-Date
$ergebnis = [System.Collections.Generic.List[object]]::new()
function Befund($Bereich, $Pruefung, $Anzahl, $Soll) {
    $ergebnis.Add([pscustomobject]@{ Bereich=$Bereich; Pruefung=$Pruefung; Anzahl=$Anzahl; Soll=$Soll
                                     Status = if ($Anzahl -le $Soll) { "OK" } else { "PRUEFEN" } })
}

# 1) Privilegierte Gruppen: Mitglieder zaehlen
$da = @(Get-ADGroupMember "Domain Admins" -Recursive).Count
Befund "Privilegiert" "Mitglieder Domain Admins" $da 5
$ea = @(Get-ADGroupMember "Enterprise Admins" -Recursive).Count
Befund "Privilegiert" "Mitglieder Enterprise Admins" $ea 1
$sa = @(Get-ADGroupMember "Schema Admins" -Recursive).Count
Befund "Privilegiert" "Mitglieder Schema Admins (Soll: leer ausser bei Schemaaenderung)" $sa 0

# 2) Konten mit Kennwort "laeuft nie ab" (aktive Benutzer)
$nie = @(Get-ADUser -Filter 'PasswordNeverExpires -eq $true -and Enabled -eq $true').Count
Befund "Konten" "Kennwort laeuft nie ab" $nie 5

# 3) Aktive Benutzer ohne Anmeldung seit 90 Tagen
$grenze = $heute.AddDays(-90)
$alt = @(Get-ADUser -Filter 'Enabled -eq $true' -Properties lastLogonDate | Where-Object { $_.lastLogonDate -and $_.lastLogonDate -lt $grenze }).Count
Befund "Konten" "Aktiv, aber seit 90 Tagen keine Anmeldung" $alt 10

# 4) Computer ohne LAPS-Kennwort (Attribut msLAPS-PasswordExpirationTime leer)
$ohneLaps = @(Get-ADComputer -Filter 'Enabled -eq $true' -Properties 'msLAPS-PasswordExpirationTime' |
   Where-Object { -not $_.'msLAPS-PasswordExpirationTime' -and $_.DistinguishedName -notmatch 'OU=Domain Controllers' }).Count
Befund "LAPS" "Computer ohne LAPS-Kennwort" $ohneLaps 0

# 5) Bericht als HTML speichern
$ergebnis | ConvertTo-Html -Title "AD Security Review $($heute.ToString('yyyy-MM-dd'))" |
   Out-File "D:\Berichte\SecurityReview-$($heute.ToString('yyyyMMdd')).html" -Encoding utf8
$ergebnis | Format-Table -AutoSize
```

Die Funktion `Befund` sammelt jede Prüfung als Zeile mit Bereich, Beschreibung, Istwert, Sollwert und Status. Die Prüfungen 1 bis 4 holen die Kennzahlen aus dem Verzeichnis; die Sollwerte sind Beispiele, die jedes Unternehmen selbst festlegen muss (der Wert fünf für die Domain Admins folgt dem Richtwert der Tier-Dokumentation). Prüfung 4 nutzt das Attribut `msLAPS-PasswordExpirationTime`, das Windows LAPS auf dem Computerobjekt setzt; ist es leer, hat der Rechner noch kein LAPS-Kennwort gespeichert. Die Domain Controller werden ausgenommen, weil ihr Kennwort anders verwaltet wird (DSRM). Schritt 5 schreibt das Ergebnis als HTML-Datei, die sich leicht archivieren und vergleichen lässt. Ein Bericht, der zum Vormonat verglichen wird, zeigt Entwicklung und nicht nur den Stand.

### Typische Fehler und Stolperfallen

Der erste Fehler ist ein Bericht ohne Folgen: Befunde werden gesammelt, aber niemand ist verantwortlich. Jeder Befund braucht einen Besitzer und einen Termin. Der zweite Fehler ist, die Sollwerte nie zu hinterfragen; ein Grenzwert von „höchstens 50 nie ablaufende Kennwörter“ ist kein Ziel, sondern ein Zugeständnis. Der dritte ist, nur das Verzeichnis zu prüfen und die Domain Controller selbst zu vergessen (Patchstand, installierte Software, Dienste).

```powershell
# FALSCH: Einmalige Pruefung vor dem Audit, Ergebnis nicht aufgehoben
Get-ADGroupMember "Domain Admins" | Format-Table

# RICHTIG: Regelmaessig, mit Datum im Dateinamen, Vergleich zum Vormonat moeglich
Get-ADGroupMember "Domain Admins" -Recursive | Select-Object SamAccountName |
    Export-Csv ("D:\Berichte\DomainAdmins-{0:yyyyMMdd}.csv" -f (Get-Date)) -NoTypeInformation -Encoding UTF8
```

> **Ergänzung aus der Nachrecherche**
>
> Die Hinweise auf die Leitfäden zur Absicherung von Active Directory und auf die Prüfbereiche folgen den abgerufenen Seiten „Best Practices for Securing Active Directory“ und „Monitoring Active Directory for Signs of Compromise“ (Microsoft Learn). Das Security Compliance Toolkit wurde nicht abgerufen und ist als weiterführende Quelle aufgeführt. Die Sollwerte im Skript sind Beispielwerte; der Name des Attributs `msLAPS-PasswordExpirationTime` stammt aus dem Fachwissen und sollte in der eigenen Umgebung geprüft werden.

### Praxisbezug

> **Praxisbeispiel**
>
> Zu Beginn jedes Quartals erhält die IT-Leitung einen Zweiseiter: eine Tabelle mit den Kennzahlen aus dem Skript, den Veränderungen gegenüber dem Vorquartal und einer Liste der drei wichtigsten offenen Befunde mit Verantwortlichem. Bei der jährlichen Prüfung durch die Revision dient dieselbe Mappe als Nachweis, dass die Maßnahmen nicht nur eingeführt wurden, sondern laufend kontrolliert werden.

## 9.10 Übungsaufgaben zu Modul 9

**Aufgabe 9.1** Erklären Sie in eigenen Worten das Prinzip der geringsten Rechte und nennen Sie drei Beispiele aus dem Verwaltungsalltag, in denen es verletzt wird. Wie würde man jedes Beispiel korrigieren?

**Aufgabe 9.2** Nennen Sie die drei Ebenen des Tier-Modells und ordnen Sie folgende Systeme zu: Domain Controller, Dateiserver, Notebook eines Sachbearbeiters, Zertifizierungsstelle, Exchange-Server, Microsoft Entra Connect. Begründen Sie, warum ein Domain-Admin-Konto sich nie an einem Dateiserver anmelden sollte.

**Aufgabe 9.3** Welche Gruppen außer den Domain Admins gelten als privilegiert? Nennen Sie mindestens vier und erklären Sie, warum die Mitgliedschaft in einer davon einem Angreifer helfen kann.

**Aufgabe 9.4** Warum wird eine Privilegierte Administrationsworkstation (PAW) als virtuelle Maschine auf dem normalen Büro-PC nicht empfohlen? Nennen Sie vier Merkmale einer gut gestalteten PAW.

**Aufgabe 9.5** Beschreiben Sie, wie Windows LAPS das Problem „gleiches lokales Administratorkennwort auf allen Rechnern“ löst. In welcher Reihenfolge richtet man LAPS im Active Directory ein, und welche zwei Schutzschichten gibt es für das gespeicherte Kennwort?

**Aufgabe 9.6** **Praxis:** Schreiben Sie ein PowerShell-Skript, das alle Mitglieder der Gruppen Domain Admins, Enterprise Admins und Schema Admins rekursiv ausliest und in eine CSV-Datei mit den Spalten Gruppe, Konto, Typ und letzte Anmeldung schreibt. Das Skript soll Konten markieren, die seit mehr als 90 Tagen nicht angemeldet waren.

**Aufgabe 9.7** **Praxis:** Legen Sie mit `auditpol` die Überwachung für die Unterkategorien Benutzerkontenverwaltung, Sicherheitsgruppenverwaltung und Kerberos-Dienstticketvorgänge (Erfolg und Fehler) fest, vergrößern Sie das Sicherheitsprotokoll auf 512 MB und schreiben Sie eine Abfrage, die alle Änderungen an Mitgliedern von Sicherheitsgruppen der letzten 24 Stunden anzeigt.

**Aufgabe 9.8** **Praxis:** Erstellen Sie ein Prüfskript, das (a) alle Benutzerkonten mit SPN, (b) alle Konten ohne Kerberos-Vorauthentifizierung und (c) alle Computer mit uneingeschränkter Delegierung (außer Domain Controller) ausgibt. Beschreiben Sie zu jedem der drei Funde, welches Risiko er darstellt und wie man ihn beseitigt. Erklären Sie außerdem, welche Folgen es hätte, einen Administrator in „Protected Users“ aufzunehmen, der Server per IP-Adresse verwaltet.

## 9.11 Lösungen zu den Übungsaufgaben

**Lösung 9.1.** Das Prinzip verlangt, dass ein Konto nur die Rechte erhält, die es für seine Aufgabe braucht, und nur so lange. Typische Verletzungen sind erstens Benutzer, die Domain Admin sind, „weil sonst etwas nicht läuft“ (Korrektur: genaue Ursache suchen, delegieren oder eine Rollengruppe mit den nötigen Rechten bilden); zweitens Dienstkonten mit hohen Rechten und nie ablaufendem Kennwort (Korrektur: gMSA und nur die nötigen Rechte); drittens Administratoren, die mit demselben Konto E-Mails lesen und Server verwalten (Korrektur: getrennte Alltags- und Administrationskonten, Verwaltung nur von einer PAW). Ergänzend kann man zeitlich begrenzte Mitgliedschaften nutzen, damit Rechte von selbst verfallen.

**Lösung 9.2.** Tier 0: Domain Controller, Zertifizierungsstelle, Microsoft Entra Connect. Tier 1: Dateiserver, Exchange-Server. Tier 2: Notebook des Sachbearbeiters. Ein Domain-Admin-Konto gehört zu Tier 0. Meldet es sich an einem Dateiserver (Tier 1) an, bleiben Kennwort-Hash und Tickets im Speicher des Servers. Wer den Server kompromittiert, kann sie auslesen und wiederverwenden (Pass-the-Hash, Pass-the-Ticket) und gelangt so zu den Domain Controllern. Deshalb dürfen Anmeldedaten einer höheren Ebene nie auf einem System einer niedrigeren Ebene verwendet werden; technisch erzwingt man das mit den Benutzerrechten „Anmelden verweigern“ per GPO.

**Lösung 9.3.** Zum Beispiel Enterprise Admins, Schema Admins, Administrators, Account Operators, Server Operators, Backup Operators und Print Operators. Ein Mitglied der Backup Operators darf Daten sichern und wiederherstellen und kann damit jede Datei lesen, auch die Active-Directory-Datenbank mit allen Kennwort-Hashes. Server Operators und Print Operators dürfen sich an Domain Controllern anmelden, sodass ein Angreifer dort Programme ausführen kann. Account Operators können Konten und Gruppen ändern und sich so Wege zu mehr Rechten schaffen. Diese Gruppen sollten im Normalbetrieb leer sein, und alle Änderungen sollten überwacht werden.

**Lösung 9.4.** Eine PAW in einer VM auf dem Büro-PC steht unter der Kontrolle des Gastgebers; wird dieser (Tier 2) kompromittiert, kann der Angreifer Tastatureingaben, Speicher und Anmeldedaten der VM abgreifen. Damit entfällt die Vertrauenswürdigkeit der „sauberen Tastatur“. Merkmale einer guten PAW: gehärtetes, aktuelles Betriebssystem; ausschließlich Verwaltungsaufgaben ohne E-Mail und freien Webzugang; eingeschränkter ausgehender Netzwerkverkehr nur zu den Verwaltungszielen; Geräteverschlüsselung und Schutz der Anmeldedaten (zum Beispiel Credential Guard); pro Ebene eigene PAW; geprüfte Lieferkette und physischer Schutz.

**Lösung 9.5.** Jeder Rechner erhält ein eigenes, zufälliges Kennwort für das lokale Administratorkonto, das automatisch nach einem festgelegten Zeitraum erneuert und im Active Directory auf dem Computerobjekt gespeichert wird. Ein erbeutetes Kennwort gilt dadurch nur für einen Rechner und nur zeitlich begrenzt. Reihenfolge: (1) Schema erweitern mit `Update-LapsADSchema`; (2) Computerkonten das Recht geben, ihr Kennwort zu schreiben (`Set-LapsADComputerSelfPermission`); (3) Leserechte und Rotationsrechte an der OU festlegen (`Set-LapsADReadPasswordPermission`, `Set-LapsADResetPasswordPermission`); (4) Richtlinie per GPO verteilen; (5) Kennwort bei Bedarf mit `Get-LapsADPassword` abrufen. Schutzschichten: ACLs auf den Kennwortattributen und die Verschlüsselung des Kennworts auf dem Gerät, die nur ein bestimmter Sicherheitsprinzipal entschlüsseln kann.

**Lösung 9.6.** Ein mögliches Skript:

```powershell
Import-Module ActiveDirectory
$grenze = (Get-Date).AddDays(-90)
$zeilen = foreach ($g in "Domain Admins","Enterprise Admins","Schema Admins") {
    foreach ($m in Get-ADGroupMember -Identity $g -Recursive -ErrorAction SilentlyContinue) {
        $o = Get-ADObject $m.distinguishedName -Properties lastLogonTimestamp
        $zuletzt = if ($o.lastLogonTimestamp) { [datetime]::FromFileTime($o.lastLogonTimestamp) } else { $null }
        [pscustomobject]@{
            Gruppe = $g; Konto = $m.SamAccountName; Typ = $m.objectClass
            LetzteAnmeldung = $zuletzt
            Inaktiv = (-not $zuletzt) -or ($zuletzt -lt $grenze)
        }
    }
}
$zeilen | Export-Csv "D:\Berichte\Admins.csv" -NoTypeInformation -Encoding UTF8
$zeilen | Where-Object Inaktiv | Format-Table -AutoSize
```

Die rekursive Abfrage erfasst auch verschachtelte Gruppen. Die letzte Anmeldung wird aus `lastLogonTimestamp` gewonnen, der nur ungefähr alle 14 Tage aktualisiert wird; für eine Grenze von 90 Tagen reicht diese Genauigkeit. Fehlt der Wert, gilt das Konto als inaktiv. Wichtig ist, die markierten Konten tatsächlich zu prüfen und gegebenenfalls zu entfernen.

**Lösung 9.7.** Ein mögliches Vorgehen:

```powershell
auditpol /set /subcategory:"User Account Management"            /success:enable /failure:enable
auditpol /set /subcategory:"Security Group Management"          /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable /failure:enable
wevtutil sl Security /ms:536870912

Get-WinEvent -FilterHashtable @{LogName="Security";Id=4728,4729,4732,4733,4756,4757;StartTime=(Get-Date).AddHours(-24)} |
  ForEach-Object {
    $d=@{}; foreach ($n in ([xml]$_.ToXml()).Event.EventData.Data) { $d[$n.Name]=$n.'#text' }
    [pscustomobject]@{ Zeit=$_.TimeCreated; Id=$_.Id; Gruppe=$d["TargetUserName"]; Mitglied=$d["MemberName"]; Durch=$d["SubjectUserName"] }
  } | Format-Table -AutoSize
```

512 MB entsprechen 536870912 Byte. Die Ereignisse 4728, 4732 und 4756 stehen für das Hinzufügen zu globalen, lokalen und universellen Sicherheitsgruppen, 4729, 4733 und 4757 für das Entfernen. Die Abfrage muss auf dem Domain Controller ausgeführt werden (oder mit `-ComputerName`), auf dem die Änderung protokolliert wurde; in größeren Umgebungen fragt man den PDC-Emulator oder ein zentrales Sammelprotokoll ab.

**Lösung 9.8.** Ein mögliches Skript:

```powershell
Import-Module ActiveDirectory
"--- (a) Benutzerkonten mit SPN ---"
Get-ADUser -Filter 'servicePrincipalName -like "*"' -Properties servicePrincipalName, PasswordLastSet |
  Select-Object SamAccountName, PasswordLastSet
"--- (b) Ohne Kerberos-Vorauthentifizierung ---"
Get-ADUser -Filter 'DoesNotRequirePreAuth -eq $true' | Select-Object SamAccountName
"--- (c) Uneingeschraenkte Delegierung (ohne DC) ---"
Get-ADComputer -Filter 'TrustedForDelegation -eq $true' | Where-Object { $_.Name -notmatch '^DC' } | Select-Object Name
```

Zu (a): Jeder Domänenbenutzer kann Tickets für diese Konten anfordern und offline angreifen (Kerberoasting); Abhilfe sind gMSA oder sehr lange zufällige Kennwörter und möglichst geringe Rechte. Zu (b): Antworten sind ohne Anmeldung anforderbar und offline angreifbar (AS-REP-Roasting); Abhilfe ist, die Vorauthentifizierung zu aktivieren. Zu (c): Wer sich an einem solchen Rechner anmeldet, hinterlässt weiterleitbare Tickets, die ein Angreifer mit Rechten auf dem Rechner missbrauchen kann; Abhilfe ist, die uneingeschränkte Delegierung zu entfernen oder durch eingeschränkte beziehungsweise ressourcenbasierte Delegierung zu ersetzen, und sensible Konten als „Konto kann nicht delegiert werden“ zu kennzeichnen. Die Frage zur IP-Adresse: Bei einer Verbindung per IP-Adresse fällt Windows auf NTLM zurück. Für Mitglieder von „Protected Users“ ist NTLM gesperrt, die Anmeldung scheitert. Der Administrator muss Server mit dem Namen (FQDN) ansprechen, damit Kerberos verwendet wird; fehlende DNS-Namen oder SPNs sind in diesem Fall zu korrigieren.
