# Modul 08 - Authentifizierung, Autorisierung und Zugriffsschutz

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Tabellen als Markdown-Tabellen, Übungsaufgaben und Lösungen als Absätze). Die Überschriften sind wie in der Quelle nach Modul und Lerneinheit nummeriert (8.1 bis 8.9; 8.10 Übungsaufgaben, 8.11 Lösungen). **Die PowerShell-Beispiele wurden für dieses Repository nicht ausgeführt**; sie setzen eine Windows-Server-Laborumgebung mit der fiktiven Domain `corp.contoso.com` voraus und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain. Übersicht zum Modul: [README](README.md).

|                                       |              |
|:--------------------------------------|:-------------|
| Dauer laut Modulübersicht             | 12 Stunden   |
| Summe der Lerneinheiten (Detailblatt) | 10,5 Stunden |
| Priorität                             | 1            |

| Nr. | Lerneinheit                    | Dauer (h) | Prio |
|----:|:-------------------------------|----------:|-----:|
| 8.1 | Kerberos                       |         1 |    1 |
| 8.2 | NTLM                           |         1 |    1 |
| 8.3 | LDAP                           |       1,5 |    1 |
| 8.4 | LDAPS                          |         1 |    1 |
| 8.5 | ACLs                           |         1 |    1 |
| 8.6 | Delegation of Control          |       1,5 |    1 |
| 8.7 | Password Policies              |         1 |    2 |
| 8.8 | Fine-Grained Password Policies |         1 |    2 |
| 8.9 | Account Lockout                |       1,5 |    2 |
|     | **Summe**                      |  **10,5** |      |

> **Merke**
>
> Die Stundensumme der Lerneinheiten im Detailblatt (10,5 h) weicht von der Dauer in der Modulübersicht (12 h) ab. Dieses Skript behandelt alle Lerneinheiten des Detailblatts vollständig; die Abweichung ist im Lehrplan selbst zu klären.

In diesem Modul geht es um die Frage, die hinter jeder Anmeldung steht: *Wer bist du, und was darfst du?* Die erste Hälfte der Frage heißt *Authentifizierung* (Authentication): Ein Benutzer, ein Computer oder ein Dienst beweist seine Identität. Die zweite Hälfte heißt *Autorisierung* (Authorization): Auf Grundlage der bewiesenen Identität entscheidet das System, welche Zugriffe erlaubt sind. Beides wird in Active Directory von verschiedenen Mechanismen übernommen. Für die Authentifizierung kommen die Protokolle Kerberos, NTLM und LDAP zum Einsatz, für die Autorisierung die Zugriffssteuerungslisten (ACLs) an jedem Objekt. Ergänzt wird das durch Regeln, die den Zugriff schützen: Kennwortrichtlinien, differenzierte Kennwortrichtlinien und die Kontosperrung.

Das Modul folgt diesem Aufbau. Zunächst werden die drei Protokolle erklärt, weil man sie verstehen muss, um Anmeldeprobleme zu finden und Sicherheitslücken zu schließen. Danach geht es um ACLs und die Delegierung von Verwaltungsaufgaben, und zum Schluss um die Richtlinien, die Kennwörter und Sperrungen regeln. Die Beispiele verwenden die Laborumgebung der vorangegangenen Module (Domain `corp.contoso.com`, Domain Controller DC01 und DC02, Mitgliedsserver SRV01, Client PC01).

## 8.1 Kerberos

*Kerberos* ist das Standardprotokoll für die Anmeldung in einer Active-Directory-Domain. Die Microsoft-Dokumentation beschreibt drei Beteiligte: den Client, der für einen *Sicherheitsprinzipal* (Security Principal, also einen Benutzer, einen Computer oder einen Dienst) handelt, den Dienst, auf den er zugreifen will, und das *Key Distribution Center* (KDC), dem beide vertrauen. In Windows Server läuft das KDC auf *jedem Domain Controller* und verwendet die AD-Datenbank als Kontendatenbank. Das ist ein wichtiger Zusammenhang: Ohne erreichbaren Domain Controller (und damit ohne funktionierende Namensauflösung per DNS, siehe Modul 5) gibt es keine Kerberos-Anmeldung.

Der Ablauf besteht aus drei Schritten, die die Dokumentation als Subprotokolle bezeichnet. Im ersten Schritt, dem *AS-Austausch* (Authentication Service), weist der Client mit Kennwort oder privatem Schlüssel seine Identität nach und erhält ein *Ticket-Granting Ticket* (TGT). Das TGT ist eine Art Eintrittskarte: Es berechtigt dazu, weitere Tickets anzufordern, ohne das Kennwort erneut einzugeben. Der Client legt es im Ticket-Cache ab und verwendet es, bis es abläuft. Im zweiten Schritt, dem *TGS-Austausch* (Ticket-Granting Service), präsentiert der Client das TGT dem KDC und fordert ein *Dienstticket* (Service Ticket) für einen bestimmten Dienst an, zum Beispiel für die Dateifreigabe auf SRV01. Im dritten Schritt, dem *AP-Austausch* (Application), legt der Client das Dienstticket dem Dienst direkt vor. Da das Ticket alles enthält, was der Dienst zur Prüfung braucht, muss der Dienst nicht bei jeder Verbindung einen Domain Controller fragen. Das ist der Grund, warum Kerberos skaliert und warum Single Sign-On funktioniert: Das Kennwort wird einmal beim Anmelden verwendet, danach genügen Tickets.

Damit der Client weiß, *für welches Konto* er ein Dienstticket anfordern soll, braucht jeder Dienst einen eindeutigen Namen, den *Service Principal Name* (SPN). Ein SPN hat die Form `Dienstklasse/Hostname`, zum Beispiel `cifs/srv01.corp.contoso.com` für Dateifreigaben oder `HTTP/web01.corp.contoso.com` für Webseiten. Der SPN ist als Attribut am Konto registriert, unter dem der Dienst läuft, bei Diensten auf einem Server meist am Computerkonto, bei Diensten mit eigenem Dienstkonto an diesem Konto. Die Microsoft-Dokumentation zum Application Verifier erklärt die Folge fehlender Namen: Wird kein gültiger Zielname angegeben oder findet der Domain Controller den SPN nicht, fällt die Aushandlung (Negotiate) auf NTLM zurück. Ein SPN, der *fehlt oder doppelt vorhanden* ist, gehört deshalb zu den häufigsten Ursachen für Anmeldeprobleme und unerwünschten NTLM-Verkehr.

Zwei weitere Eigenschaften muss man kennen. Erstens ist Kerberos zeitabhängig. Die Dokumentation zur Fehlersuche hält fest, dass die Zeit zwischen Domain Controller und Client oder Zielserver um *weniger als fünf Minuten* abweichen darf; den Wert `SkewTime` mit Standard 5 Minuten beschreibt die Seite zu den Kerberos-Registrierungseinträgen als die maximal erlaubte Zeitdifferenz. Weicht die Uhr stärker ab, scheitert die Anmeldung mit dem Fehler `KRB_AP_ERR_SKEW`. Das ist ein Sicherheitsmerkmal gegen Replay-Angriffe, bei denen aufgezeichnete Nachrichten später erneut abgespielt werden. Deshalb ist der Zeitdienst (Lerneinheit 6.9) so wichtig. Zweitens haben Tickets eine begrenzte Lebensdauer. Das TGT ist laut der Beschreibung des Attributs `maxTicketAge` standardmäßig *10 Stunden* gültig, festgelegt in der Default Domain Policy; danach muss ein neues beantragt oder das alte erneuert werden.

Das folgende Skript zeigt die wichtigsten Werkzeuge. Zuerst listet es die Tickets der aktuellen Sitzung mit `klist` auf. Danach sucht es die SPNs eines Computers und eines Dienstkontos mit `setspn` und prüft über alle Konten, ob ein SPN doppelt registriert ist. Schließlich vergleicht es die Uhrzeit des Clients mit der eines Domain Controllers.

```powershell
# 1) Tickets der aktuellen Sitzung anzeigen (TGT und Dienstickets)
klist
klist tgt

# 2) Alle Tickets verwerfen und neu anmelden lassen (z. B. nach Gruppenaenderung)
klist purge

# 3) SPNs eines Computers bzw. eines Kontos anzeigen
setspn -L SRV01
setspn -L CORP\svc-sql

# 4) Doppelte SPNs in der Gesamtstruktur suchen (haeufige Fehlerursache)
setspn -X -F

# 5) Neuen SPN registrieren (nur wenn er nicht schon existiert)
setspn -S MSSQLSvc/sql01.corp.contoso.com:1433 CORP\svc-sql

# 6) Zeitabweichung zu einem Domain Controller pruefen
w32tm /stripchart /computer:DC01.corp.contoso.com /samples:3 /dataonly

# 7) Dieselbe Information per PowerShell: SPNs aller Konten mit einem SPN
Get-ADObject -LDAPFilter "(servicePrincipalName=*)" -Properties servicePrincipalName |
    Select-Object Name, @{n="SPN";e={$_.servicePrincipalName -join "; "}} |
    Sort-Object Name | Format-Table -AutoSize
```

Schritt 1 zeigt zuerst alle Tickets, dann nur das TGT. In der Ausgabe stehen der Server, für den das Ticket gilt, die Verschlüsselungsart sowie Start- und Endzeit; so sieht man, ob ein Ticket abgelaufen ist. Schritt 2 löscht den Cache. Der Client fordert danach automatisch neue Tickets an, die dann die aktuelle Gruppenmitgliedschaft enthalten; das ist der Grund, warum nach einer Gruppenänderung oft eine neue Anmeldung nötig ist. Schritt 3 zeigt die registrierten SPNs; `setspn -L` listet sie für das angegebene Konto auf. Schritt 4 sucht im ganzen Verzeichnis nach Duplikaten. Schritt 5 trägt einen SPN mit der Option `-S` ein, die zuerst auf Duplikate prüft (im Gegensatz zu `-A`, das blind hinzufügt). Schritt 6 vergleicht die Uhren: Die Ausgabe zeigt den Unterschied in Sekunden. Schritt 7 liest dieselben SPN-Daten über das Active-Directory-Modul aus und eignet sich für Berichte.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die Zeitabweichung. Ein Server in einer virtuellen Umgebung, dessen Uhr nach einer Pause oder einem Snapshot falsch geht, kann plötzlich keine Kerberos-Anmeldungen mehr annehmen; die Anwender sehen „Zugriff verweigert“ oder bekommen eine Anmeldeaufforderung, obwohl ihr Kennwort stimmt. Der zweite Fehler ist ein fehlender oder doppelter SPN, besonders nach dem Umzug eines Dienstes auf ein neues Dienstkonto. Der dritte Fehler ist, einen Dienst über die *IP-Adresse* oder einen DNS-Alias anzusprechen, für den kein SPN existiert: Dann kann der Client keinen passenden Zielnamen bilden, und die Verbindung fällt auf NTLM zurück oder scheitert.

```powershell
# FALSCH: Dienst per IP-Adresse ansprechen - es gibt keinen SPN fuer die IP,
#         der Client faellt auf NTLM zurueck
net use Z: \\10.10.0.21\Daten

# RICHTIG: Per Rechnername (FQDN) ansprechen - der SPN cifs/srv01.corp.contoso.com
#          ist am Computerkonto registriert, es wird Kerberos verwendet
net use Z: \\srv01.corp.contoso.com\Daten
klist | Select-String "srv01"      # das Dienstticket cifs/srv01... muss erscheinen
```

> **Ergänzung aus der Nachrecherche**
>
> Die Rolle des KDC auf jedem Domain Controller, den dreistufigen Ablauf (AS, TGS, AP), die Fünf-Minuten-Toleranz, den Fehler `KRB_AP_ERR_SKEW`, die TGT-Lebensdauer von 10 Stunden und den NTLM-Rückfall bei fehlendem SPN belegen die abgerufenen Seiten „Kerberos authentication overview“, „Kerberos authentication troubleshooting guidance“, „Kerberos protocol registry entries“ und „Max-Ticket-Age attribute“ sowie die Application-Verifier-Seiten (Microsoft Learn). Nicht abgerufen wurden Details wie die Erneuerungsfrist von 7 Tagen und die Ticketlebensdauer für Dienstickets; sie stammen aus dem Fachwissen und sind in der Default Domain Policy unter *Kerberos-Richtlinie* nachzulesen.

### Praxisbezug

> **Praxisbeispiel**
>
> Nach einer Wartung melden mehrere Benutzer, dass der Zugriff auf eine Freigabe plötzlich nach Anmeldedaten fragt. `klist` auf dem Client zeigt kein Ticket für den Dateiserver; `w32tm /stripchart` offenbart, dass der Server 11 Minuten vorgeht, weil der virtuelle Host nach dem Neustart eine falsche Zeit an die VM weitergab. Nach der Korrektur der Zeitquelle (Modul 6) funktioniert Kerberos wieder. Die Lehre: Bei Anmeldeproblemen zuerst Uhrzeit, DNS und SPN prüfen, erst dann Kennwörter und Rechte.

## 8.2 NTLM

*NTLM* (NT LAN Manager) ist die ältere Familie von Authentifizierungsprotokollen, die Windows seit den 1990er-Jahren verwendet. Die Microsoft-Dokumentation beschreibt sie als Protokolle nach dem Prinzip *Challenge-Response*: Der Server sendet dem Client eine Zufallszahl (die Challenge); der Client berechnet daraus mit dem Hash seines Kennworts eine Antwort (Response), die der Server oder der Domain Controller prüft. Das Kennwort selbst wird dabei nicht übertragen. Zur Familie gehören LAN Manager Version 1 und 2 sowie NTLM Version 1 und 2.

Obwohl Kerberos das bevorzugte Protokoll ist, ist NTLM nicht verschwunden. Die Dokumentation nennt die Fälle, in denen es noch zwingend verwendet wird: bei Systemen in einer Arbeitsgruppe (ohne Domain), bei der lokalen Anmeldung auf Nicht-Domain-Controllern und bei Anwendungen, die NTLM fest einprogrammiert haben. Außerdem greift der Rückfall: Das Sicherheitspaket *Negotiate* versucht zuerst Kerberos und wählt NTLM, wenn Kerberos nicht möglich ist, zum Beispiel weil kein gültiger Zielname übergeben wird oder der SPN nicht gefunden wird (Lerneinheit 8.1). Typische Auslöser sind Zugriffe über die IP-Adresse, über DNS-Aliasnamen ohne SPN oder von nicht domänenangehörigen Rechnern.

Aus Sicherheitssicht ist NTLM problematisch, weil es keine gegenseitige Authentifizierung kennt (der Client prüft nicht, ob der Server echt ist) und weil Angriffe wie das Weiterleiten (Relay) von Anmeldungen oder das Wiederverwenden von Hashes (Pass-the-Hash) möglich sind. Microsoft hat NTLM deshalb im Juni 2024 als veraltet (deprecated) eingestuft: Alle Versionen sind nicht mehr in aktiver Entwicklung, die Nutzung funktioniert aber weiter; NTLMv1 wurde ab Windows 11, Version 24H2, und Windows Server 2025 *entfernt*. Die Dokumentation empfiehlt, Aufrufe von NTLM durch Negotiate zu ersetzen, das Kerberos verwendet und nur im Notfall auf NTLM zurückfällt. Eine Frist, ab der NTLM abgeschaltet wird, ist nicht festgelegt; Microsoft weist darauf hin, dass NTLM funktioniert, bis die Organisation es per Richtlinie selbst abschaltet.

Der vernünftige Weg heißt deshalb: *erst sichtbar machen, dann reduzieren, dann sperren*. Dafür gibt es die Gruppenrichtlinien unter *Computerkonfiguration, Windows-Einstellungen, Sicherheitseinstellungen, Lokale Richtlinien, Sicherheitsoptionen* mit dem Präfix „Netzwerksicherheit: NTLM einschränken“ (*Network security: Restrict NTLM*). Mit den Einstellungen für Überwachung (*Audit*) zeichnet das System NTLM-Anmeldungen auf, ohne sie zu blockieren. Für ausgehenden Verkehr gibt es die Einstellung *Outgoing NTLM traffic to remote servers* mit den Werten Alle zulassen, Alle überwachen und Alle verweigern; Überwachungs- und Blockierereignisse stehen im Protokoll *Anwendungs- und Dienstprotokolle, Microsoft, Windows, NTLM, Operational*. Für NTLMv1 reicht auf einem Domain Controller auch das normale Anmeldeüberwachungsereignis 4624, das Informationen zur verwendeten NTLM-Version enthält.

Das folgende Skript richtet die Überwachung ein, wertet die Ereignisse aus und zählt, welche Konten und Computer NTLM verwenden.

```powershell
# 1) Anmeldeueberwachung auf dem Domain Controller einschalten (Erfolg)
auditpol /set /subcategory:"Logon" /success:enable

# 2) NTLM-Anmeldungen (Ereignis 4624) der letzten 24 Stunden auswerten
$start = (Get-Date).AddHours(-24)
$events = Get-WinEvent -FilterHashtable @{
    LogName = "Security"; Id = 4624; StartTime = $start } -ErrorAction SilentlyContinue

$ntlm = foreach ($e in $events) {
    $x = [xml]$e.ToXml()
    $d = @{}
    foreach ($n in $x.Event.EventData.Data) { $d[$n.Name] = $n.'#text' }
    if ($d["AuthenticationPackageName"] -eq "NTLM") {
        [pscustomobject]@{
            Zeit      = $e.TimeCreated
            Konto     = "$($d['TargetDomainName'])\$($d['TargetUserName'])"
            Quelle    = $d["WorkstationName"]
            Version   = $d["LmPackageName"]
        }
    }
}

# 3) Zusammenfassung: wer verwendet NTLM wie oft, mit welcher Version
$ntlm | Group-Object Konto, Quelle, Version |
    Sort-Object Count -Descending |
    Select-Object Count, Name | Format-Table -AutoSize

# 4) Eingang pruefen: NTLM-Betriebsprotokoll (bei aktivierter Ueberwachung per Richtlinie)
Get-WinEvent -LogName "Microsoft-Windows-NTLM/Operational" -MaxEvents 20 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, Message
```

Schritt 1 schaltet die Überwachung erfolgreicher Anmeldungen ein, sofern sie nicht schon über eine Richtlinie läuft. Schritt 2 liest das Sicherheitsprotokoll der letzten 24 Stunden und zerlegt jedes Ereignis in seine Felder; `AuthenticationPackageName` nennt das Anmeldepaket (NTLM oder Kerberos), `LmPackageName` die Version (NTLM V1 oder NTLM V2). Schritt 3 zählt die Anmeldungen je Konto, Quelle und Version und zeigt die häufigsten zuerst: Wer hier mit NTLM V1 auftaucht, ist der erste Kandidat zum Beheben. Schritt 4 liest das Betriebsprotokoll, in dem die Richtlinien für das Überwachen und Blockieren ihre Ereignisse ablegen.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, NTLM ohne Vorbereitung per Richtlinie zu sperren. Danach funktionieren alte Anwendungen, Multifunktionsgeräte mit „Scan to Folder“, Skripte mit IP-Adressen oder Zugriffe über Aliasnamen nicht mehr, und niemand weiß, warum. Ein zweiter Fehler ist, nur den Domain Controller zu überwachen, obwohl die Einstellungen für ausgehenden und eingehenden Verkehr auch auf Mitgliedsservern gelten und dort getrennt ausgewertet werden müssen. Ein dritter Fehler ist die Annahme, dass „NTLMv2 ist sicher genug“: NTLMv2 ist besser als Version 1, behält aber die Schwächen des Protokolls.

```powershell
# FALSCH: Sofort alle NTLM-Anmeldungen verweigern (per Richtlinie) - ohne Messung
#   Netzwerksicherheit: NTLM einschraenken: NTLM-Authentifizierung in dieser Domaene = Alle verweigern

# RICHTIG: Stufenweise vorgehen
#   1. Ueberwachung aktivieren (Audit all), 4 Wochen sammeln
#   2. Die Verursacher beheben (FQDN statt IP, SPN registrieren, Anwendung aktualisieren)
#   3. Ausnahmen fuer unvermeidbare Server festlegen
#   4. Dann erst verweigern, zunaechst in einer Test-OU
```

> **Ergänzung aus der Nachrecherche**
>
> Den Status von NTLM (veraltet seit Juni 2024, NTLMv1 in Windows 11 24H2 und Windows Server 2025 entfernt, Ersatz durch Negotiate, Überwachung als empfohlener Einstieg) und die Richtlinie für ausgehenden NTLM-Verkehr samt Protokoll belegen die abgerufenen Seiten „Deprecated features for Windows client“, „Resources for deprecated features“, „NTLM overview“, „Policy CSP - LocalPoliciesSecurityOptions“ und „Audit use of NTLMv1 on a Windows Server-based domain controller“ (Microsoft Learn). Die genauen Feldnamen im Ereignis 4624 (`LmPackageName`) und die Richtlinienwerte für die Domänenüberwachung stammen aus dem Fachwissen; bitte im Labor am eigenen Ereignis prüfen. Aktuelle Termine für die weitere Abschaltung nennt die von Microsoft verlinkte Seite „aka.ms/ntlm“ (nicht abgerufen).

### Praxisbezug

> **Praxisbeispiel**
>
> Bei einem Sicherheitsaudit wird bemängelt, dass in der Domain NTLMv1 noch möglich ist. Das Team aktiviert die Überwachung und sieht nach einer Woche, dass ein einziger alter Netzwerkdrucker und ein Skript auf einem Linux-Server NTLM verwenden. Der Drucker erhält eine Firmware-Aktualisierung, das Skript wird auf einen Rechnernamen statt auf die IP umgestellt. Danach kann die Richtlinie „NTLMv1 verweigern“ ohne Folgen aktiviert werden. Die Messung hat den Zeitplan bestimmt, nicht eine Vermutung.

## 8.3 LDAP

*LDAP* (Lightweight Directory Access Protocol) ist das Protokoll, mit dem man Verzeichnisdienste abfragt und ändert. Active Directory spricht LDAP: Wenn Sie in PowerShell `Get-ADUser` aufrufen, wenn eine Anwendung nach Benutzern sucht oder wenn ein Linux-System sich gegen das AD authentifiziert, wird im Hintergrund meist LDAP verwendet. Der Standardport ist TCP und UDP *389*; der Global Catalog (Lerneinheit 6.7) antwortet auf TCP *3268*. Die verschlüsselte Variante LDAPS verwendet 636 und 3269 (Lerneinheit 8.4).

Eine LDAP-Anfrage besteht aus der *Basis* (dem Ort im Verzeichnis, an dem die Suche beginnt, als Distinguished Name), dem *Suchbereich* (Scope: nur die Basis, eine Ebene darunter oder der gesamte Teilbaum), einem *Filter* und der Liste der gewünschten *Attribute*. Der Filter verwendet eine Präfixschreibweise: `(&(objectClass=user)(department=Vertrieb))` bedeutet „UND“, `(|(...)(...))` „ODER“ und `(!(...))` „NICHT“. Nach der Anfrage verbindet sich der Client (die sogenannte *Bindung*, Bind), und der Server prüft die Identität. Es gibt drei Bindungsarten: die *anonyme* Bindung, die *einfache* Bindung (Simple Bind) mit Benutzername und Kennwort im Klartext und die *SASL-Bindung* (zum Beispiel Kerberos über GSSAPI), bei der das Kennwort nicht übertragen wird. Die einfache Bindung über unverschlüsseltes LDAP ist ein Sicherheitsrisiko, weil das Kennwort im Netz mitlesbar ist; Lerneinheit 8.4 zeigt die Abhilfe.

Sicherheit lässt sich bei LDAP auf drei Ebenen herstellen. Die Microsoft-Dokumentation beschreibt *LDAP-Signierung* (LDAP signing), die jede Nachricht mit einer Signatur versieht, damit niemand sie unbemerkt verändern kann, und *Channel Binding*, das die Anmeldung an den verschlüsselten Kanal bindet und so Man-in-the-Middle-Angriffe auf LDAPS erschwert. Neue Domain Controller mit Windows Server 2025 verlangen standardmäßig die LDAP-Signierung; die Channel-Binding-Einstellung steht auf „Wenn unterstützt“ (*When supported*). Bei einem Upgrade bleiben die bisher gesetzten Richtlinien erhalten. Welche Clients noch ungesichert verbinden, zeigen die Ereignisse im Protokoll *Directory Service*: 2886 bis 2889 warnen vor ungesicherten Bindungen und 3039 bis 3041 sowie 3074 und 3075 betreffen das Channel Binding.

Das folgende Skript zeigt typische Abfragen mit PowerShell: eine LDAP-Suche mit Filter, eine Suche mit dem `DirectorySearcher`, der ohne das AD-Modul auskommt, und die Abfrage der wichtigen Informationen aus dem RootDSE, dem Einstiegsobjekt jedes LDAP-Servers.

```powershell
# 1) Einfache Abfrage mit LDAP-Filter ueber das AD-Modul
Get-ADUser -LDAPFilter "(&(objectClass=user)(department=Vertrieb)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" `
    -SearchBase "OU=Contoso,DC=corp,DC=contoso,DC=com" -SearchScope Subtree `
    -Properties department, mail | Select-Object Name, department, mail

# 2) Dieselbe Idee ohne AD-Modul: .NET DirectorySearcher (hilfreich auf Servern ohne RSAT)
$root = [ADSI]"LDAP://DC01.corp.contoso.com/DC=corp,DC=contoso,DC=com"
$s = New-Object System.DirectoryServices.DirectorySearcher($root)
$s.Filter = "(&(objectClass=computer)(operatingSystem=Windows Server*))"
$s.PageSize = 500
[void]$s.PropertiesToLoad.Add("name")
[void]$s.PropertiesToLoad.Add("operatingSystem")
$s.FindAll() | ForEach-Object {
    "{0}  {1}" -f $_.Properties["name"][0], $_.Properties["operatingsystem"][0]
}

# 3) RootDSE: wichtige Eigenschaften des Servers
$rootDse = [ADSI]"LDAP://DC01.corp.contoso.com/RootDSE"
$rootDse.defaultNamingContext
$rootDse.dnsHostName
$rootDse.supportedLDAPVersion
$rootDse.supportedSASLMechanisms
```

Schritt 1 sucht aktive Benutzer der Abteilung Vertrieb. Der Teil `userAccountControl:1.2.840.113556.1.4.803:=2` ist eine *bitweise Regel*: Er prüft, ob Bit 2 („Konto deaktiviert“) gesetzt ist; mit dem vorangestellten `!` werden nur aktive Konten geliefert. Schritt 2 baut dieselbe Art Suche ohne das AD-Modul; der Wert `PageSize` sorgt dafür, dass große Ergebnismengen seitenweise geliefert werden und nicht am Standardlimit von 1000 Einträgen pro Abfrage scheitern. Schritt 3 liest das RootDSE: Der `defaultNamingContext` nennt die Domain, `supportedSASLMechanisms` die unterstützten sicheren Bindungsarten.

### Typische Fehler und Stolperfallen

Der erste häufige Fehler ist ein zu breiter Filter ohne Einschränkung der Basis: Eine Suche über das ganze Verzeichnis nach `(cn=*Meier*)` ist langsam, belastet den Domain Controller und liefert Zufallstreffer. Der zweite Fehler ist, Anwendungen mit einer *Simple Bind* über Port 389 anzubinden, sodass Dienstkonto und Kennwort offen im Netz stehen. Der dritte Fehler ist, die Fehlermeldungen der Domain Controller zu ignorieren: Die Ereignisse 2886 bis 2889 sind eine Liste der Clients, die in Zukunft nicht mehr funktionieren, wenn man die Signierung verlangt.

```powershell
# FALSCH: Suche ueber die ganze Domain mit Filter auf ein nicht indiziertes Fragment
Get-ADUser -LDAPFilter "(description=*urlaub*)" -SearchBase "DC=corp,DC=contoso,DC=com"

# RICHTIG: Basis auf die zustaendige OU begrenzen, indizierte Attribute verwenden
Get-ADUser -LDAPFilter "(&(objectClass=user)(sAMAccountName=mmeier))" `
    -SearchBase "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" -SearchScope OneLevel
```

> **Ergänzung aus der Nachrecherche**
>
> Standardports, Signierung, Channel Binding, die Standardwerte unter Windows Server 2025 und die Ereignisse 2886 bis 2889 beziehungsweise 3039 bis 3041, 3074 und 3075 stammen aus den abgerufenen Seiten „LDAP signing for Active Directory Domain Services“, „LDAP channel binding“, „What’s new in Windows Server 2025“ und „Enable LDAP signing in Windows Server“ (Microsoft Learn). Der Hinweis auf das Standardlimit von 1000 Einträgen pro Seite stammt aus dem Fachwissen (Richtlinie `MaxPageSize`); der Wert kann abweichen.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen betreibt eine Wiki-Software, die sich über einfache LDAP-Bindung am AD anmeldet. Die Prüfung der Ereignisse 2889 auf den Domain Controllern zeigt die Wiki-Server als Verursacher. Bevor die Signierung erzwungen wird, stellt das Team die Anbindung auf LDAPS um (Lerneinheit 8.4) und prüft nochmals, bis die Ereignisse verschwunden sind. Erst dann setzt es die Richtlinie für alle Domain Controller.

## 8.4 LDAPS

*LDAPS* ist LDAP über eine mit SSL/TLS verschlüsselte Verbindung. Die Microsoft-Dokumentation beschreibt es so: LDAP-Verkehr ist standardmäßig unverschlüsselt und läuft über Port 389; LDAPS baut einen verschlüsselten Tunnel über Port 636 auf (für den Global Catalog Port 3269) und schützt damit Anmeldedaten und Abfragen vor dem Mitlesen. Für die Einrichtung gibt es keine Oberfläche und keine Einstellung: *Sobald auf einem Domain Controller ein passendes Zertifikat liegt, nimmt der LDAP-Dienst automatisch auch verschlüsselte Verbindungen an.* Das ist angenehm, birgt aber die Gefahr, dass ein falsches Zertifikat unbemerkt verwendet wird.

Das Zertifikat muss mehrere Bedingungen erfüllen, die die Dokumentation einzeln aufzählt. Es liegt im Zertifikatspeicher *Eigene Zertifikate* des lokalen Computers (gibt es ein Zertifikat im Speicher der NTDS-Dienste, verwendet der Domain Controller dieses). Der zugehörige private Schlüssel muss vorhanden sein, und der Schutz „starker privater Schlüssel“ darf nicht aktiv sein. Die erweiterte Schlüsselverwendung (Enhanced Key Usage) muss *Serverauthentifizierung* (OID 1.3.6.1.5.5.7.3.1) enthalten. Der vollständige DNS-Name des Domain Controllers, etwa `dc01.corp.contoso.com`, muss im Antragstellernamen (CN) oder als DNS-Eintrag im alternativen Antragstellernamen (SAN) stehen. Das Zertifikat muss von einer Zertifizierungsstelle (CA) stammen, der der Domain Controller und alle LDAPS-Clients vertrauen. Und der Schlüssel muss mit dem Schannel-Anbieter für kryptografische Dienste erzeugt sein.

In einer Domain mit Windows-Zertifikatdiensten (Active Directory Certificate Services, AD CS) fordert der Domain Controller sein Zertifikat per *Autoenrollment* automatisch an, wenn die Vorlage „Domain Controller Authentication“ oder „Kerberos Authentication“ (oder eine eigene Vorlage mit der passenden Verwendung) veröffentlicht ist. Dies ist die bevorzugte Variante, weil Zertifikate sich bei Ablauf selbst erneuern. Alternativ stellt eine externe CA das Zertifikat aus; der Ablauf besteht dann aus einer Zertifikatanforderung, der Ausstellung und der Annahme mit `certreq -accept`.

Danach prüft man die Verbindung mit dem Werkzeug `ldp.exe`. Im Menü *Connection, Connect* trägt man den Namen des Domain Controllers, Port 636 und das Häkchen *SSL* ein; erscheinen im rechten Fenster die RootDSE-Informationen, funktioniert LDAPS. Wichtig: Man verbindet sich per *DNS-Name*, nicht per IP-Adresse, weil das Zertifikat den Namen (und nicht die Adresse) enthält. Das folgende Skript führt dieselbe Prüfung automatisiert aus: Es testet die Ports, liest das Zertifikat, das der Domain Controller tatsächlich anbietet, und prüft Name, Gültigkeit und Verwendung.

```powershell
$dc = "DC01.corp.contoso.com"

# 1) Ports erreichbar?
foreach ($p in 389, 636, 3268, 3269) {
    $r = Test-NetConnection -ComputerName $dc -Port $p -WarningAction SilentlyContinue
    "{0,5}  {1}" -f $p, $(if ($r.TcpTestSucceeded) {"offen"} else {"GESPERRT"})
}

# 2) Zertifikat abrufen, das der LDAPS-Dienst tatsaechlich anbietet
$tcp = New-Object System.Net.Sockets.TcpClient($dc, 636)
$ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, ({$true}))
$ssl.AuthenticateAsClient($dc)
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($ssl.RemoteCertificate)
$tcp.Close()

# 3) Wichtige Eigenschaften pruefen
$eku = ($cert.Extensions | Where-Object { $_.Oid.Value -eq "2.5.29.37" }).Format($false)
[pscustomobject]@{
    Antragsteller = $cert.Subject
    Aussteller    = $cert.Issuer
    GueltigBis    = $cert.NotAfter
    NochTage      = [int]($cert.NotAfter - (Get-Date)).TotalDays
    Verwendung    = $eku
    NameImZertifikat = ($cert.DnsNameList.Unicode -contains $dc)
}

# 4) LDAP-Abfrage ueber den verschluesselten Kanal (Port 636)
$ldaps = [ADSI]"LDAP://DC01.corp.contoso.com:636/RootDSE"
$ldaps.defaultNamingContext
```

Schritt 1 prüft die vier relevanten Ports; ist 636 gesperrt, liegt das Problem bei der Firewall, nicht beim Zertifikat. Schritt 2 baut eine TLS-Verbindung auf Port 636 auf und holt das Zertifikat, das tatsächlich angeboten wird; so sieht man, welches der möglicherweise mehreren Zertifikate im Speicher gewählt wurde (die Troubleshooting-Seite weist darauf hin, dass Schannel das *erste gültige* Zertifikat nimmt). Der Rückruf `{$true}` akzeptiert hier jedes Zertifikat und eignet sich nur für die Diagnose. Schritt 3 gibt Antragsteller, Aussteller, Ablaufdatum, die Schlüsselverwendungen und eine Prüfung des Namens aus. Schritt 4 verbindet sich nach dem Test über den verschlüsselten Port mit dem RootDSE.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist ein Zertifikat ohne den Namen des Domain Controllers oder ohne die Serverauthentifizierung. Dann verbindet `ldp.exe` nicht, und die Meldung nennt nur einen allgemeinen Fehler. Der zweite Fehler ist ein abgelaufenes Zertifikat: Weil LDAPS ohne Konfigurationsoberfläche läuft, fällt der Ablauf erst auf, wenn eine Anwendung ausfällt. Der dritte Fehler ist, Clients per IP-Adresse zu verbinden; der Name im Zertifikat passt dann nicht.

```powershell
# FALSCH: Verbindung per IP-Adresse - Name im Zertifikat stimmt nicht ueberein
ldp.exe  ->  Server: 10.10.0.11   Port: 636   SSL: ja     (schlaegt fehl)

# RICHTIG: Verbindung per FQDN, der im Zertifikat steht
ldp.exe  ->  Server: dc01.corp.contoso.com   Port: 636   SSL: ja

# Zusaetzlich: Ablauf aller DC-Zertifikate regelmaessig pruefen (z. B. als geplante Aufgabe)
Get-ADDomainController -Filter * | ForEach-Object {
    $dcName = $_.HostName
    # hier den Skriptteil aus Schritt 2 aufrufen und NochTage < 30 melden
}
```

> **Ergänzung aus der Nachrecherche**
>
> Die Voraussetzungen an das Zertifikat (Speicher, privater Schlüssel, Serverauthentifizierung, DNS-Name im CN oder SAN, vertrauenswürdige CA, Schannel), die Ports 636 und 3269, die Tatsache, dass es keine Konfigurationsoberfläche gibt, die Prüfung mit `ldp.exe` und den Hinweis zu mehreren Zertifikaten belegen die abgerufenen Seiten „Configure certificates for LDAP over SSL in Active Directory Domain Services“, „Enable LDAP over SSL with a third-party certification authority“ und „Troubleshoot LDAP over SSL connection problems“ (Microsoft Learn). Die Namen der Zertifikatvorlagen für Autoenrollment und die Prüfung mit dem .NET-`SslStream` stammen aus dem Fachwissen.

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Software für die Mitarbeiterverwaltung soll Benutzer aus dem AD importieren und darf dafür kein Kennwort im Klartext senden. Das Team stellt für die beiden Domain Controller über Autoenrollment Zertifikate aus, importiert die Stammzertifizierungsstelle auf dem Anwendungsserver und trägt `ldaps://dc01.corp.contoso.com:636` ein. Als zweiten Domain Controller für den Ausfall trägt es `dc02` ein. Eine geplante Aufgabe meldet, wenn eines der Zertifikate in 30 Tagen abläuft.

## 8.5 ACLs

Jedes Objekt in Active Directory hat einen *Sicherheitsdeskriptor* (Security Descriptor), der festlegt, wem das Objekt gehört und wer was damit tun darf. Er besteht aus dem *Besitzer* (Owner), der *DACL* (Discretionary Access Control List), die Zugriffe erlaubt oder verweigert, und der *SACL* (System Access Control List), die festlegt, welche Zugriffe protokolliert werden. Die DACL ist eine Liste von Einträgen, den *ACEs* (Access Control Entries). Ein ACE nennt einen Sicherheitsprinzipal (Benutzer oder Gruppe), die Art (Erlauben oder Verweigern), die Berechtigung (zum Beispiel Lesen, Schreiben, Löschen, Kennwort zurücksetzen) und den Geltungsbereich (nur dieses Objekt, Unterobjekte oder bestimmte Objektklassen).

Zwei Besonderheiten unterscheiden die ACLs im Verzeichnis von denen im Dateisystem. Erstens lassen sich Berechtigungen auf einzelne *Attribute* oder *Attributgruppen* (Property Sets) und auf *erweiterte Rechte* (Extended Rights, etwa „Kennwort zurücksetzen“) beschränken; so kann man jemandem erlauben, nur die Telefonnummer eines Benutzers zu ändern. Zweitens werden ACEs wie im Dateisystem *vererbt*: Ein ACE an einer OU kann auf alle darunterliegenden Objekte oder auf bestimmte Typen wirken. Eine Verweigerung hat Vorrang vor einer Erlaubnis. Wer mehrere Rechte hat (direkt und über Gruppen), erhält die Summe aller Erlaubnisse, es sei denn, ein Eintrag verweigert.

Die Microsoft-Dokumentation beschreibt auch einen Schutzmechanismus für die mächtigsten Konten: Für die *geschützten Konten und Gruppen* (zum Beispiel Administrators, Domain Admins, Enterprise Admins, Schema Admins, Account Operators, Backup Operators, Server Operators, Print Operators und das Konto `krbtgt`) ist die ACL nicht frei konfigurierbar. Das Objekt *AdminSDHolder* im Container `CN=System` dient als Vorlage. Der Prozess *SDProp* läuft standardmäßig alle 60 Minuten auf dem Domain Controller mit der PDC-Emulator-Rolle und vergleicht die ACLs der geschützten Objekte mit der Vorlage; weichen sie ab, setzt SDProp sie zurück und schaltet die Vererbung ab. Dabei erhalten die Konten das Attribut `adminCount=1`. Entfernt man ein Konto später aus der geschützten Gruppe, bleibt `adminCount=1` stehen; das Konto erbt dann weiterhin keine Berechtigungen von seiner OU, sodass delegierte Rechte (etwa „Kennwort zurücksetzen“ für den Helpdesk) nicht mehr greifen.

Das folgende Skript zeigt den Umgang mit ACLs. Es liest die ACL einer OU, zählt die ACEs nach Prinzipal, listet Konten mit `adminCount=1` (die Kandidaten für verwaiste Einträge) und zeigt, wie man mit `dsacls` eine Berechtigung vergibt.

```powershell
Import-Module ActiveDirectory
$ouDn = "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com"

# 1) ACL einer OU lesen (das AD: Laufwerk steht nach dem Laden des Moduls zur Verfuegung)
$acl = Get-Acl -Path "AD:\$ouDn"
"Besitzer: " + $acl.Owner

# 2) ACEs lesbar auflisten
$acl.Access |
    Select-Object IdentityReference, AccessControlType, ActiveDirectoryRights,
                  InheritanceType, IsInherited |
    Sort-Object IdentityReference | Format-Table -AutoSize

# 3) Welche Prinzipale haben nicht vererbte (explizit gesetzte) Rechte?
$acl.Access | Where-Object { -not $_.IsInherited } |
    Group-Object IdentityReference | Select-Object Count, Name

# 4) Konten mit adminCount=1, die nicht mehr in einer geschuetzten Gruppe sind
$kandidaten = Get-ADUser -LDAPFilter "(adminCount=1)" -Properties adminCount, memberOf |
    Where-Object { $_.SamAccountName -notin @("Administrator","krbtgt") }
$kandidaten | Select-Object SamAccountName, @{n="Gruppen";e={$_.memberOf.Count}}

# 5) Recht mit dsacls vergeben: Gruppe darf in dieser OU Benutzer-Eigenschaften lesen
dsacls $ouDn /G "CORP\G-Helpdesk:GR" /I:T
dsacls $ouDn          # ACL anzeigen
```

Schritt 1 nutzt das Laufwerk `AD:`, das das Active-Directory-Modul bereitstellt; `Get-Acl` liefert dort denselben Sicherheitsdeskriptor, den man im Dialog „Erweiterte Sicherheitseinstellungen“ sieht (dafür muss in der Konsole „Active Directory-Benutzer und -Computer“ die Ansicht „Erweiterte Features“ eingeschaltet sein). Schritt 2 gibt jeden ACE aus: den Prinzipal, Erlauben oder Verweigern, die Rechte, die Art der Vererbung und ob der Eintrag geerbt wurde. Schritt 3 filtert die ACEs, die jemand ausdrücklich an dieser OU gesetzt hat. Das sind die Delegierungen, die man dokumentieren muss. Schritt 4 sucht Konten mit `adminCount=1`; in der Liste stehen die tatsächlichen Mitglieder geschützter Gruppen, aber auch ehemalige. Schritt 5 vergibt mit `dsacls` das generische Leserecht (`GR`) an eine Gruppe, wobei `/I:T` bedeutet, dass das Recht auf die OU und alle Unterobjekte vererbt wird.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, einzelnen *Benutzern* statt Gruppen Rechte zu geben. Wechselt die Person die Stelle, bleibt der ACE als verwaister Eintrag stehen. Der zweite Fehler sind Verweigerungs-ACEs (Deny), die den Überblick zerstören und schwer zu finden sind. Der dritte Fehler ist, ACLs an einzelnen Benutzerobjekten statt an der OU zu setzen; dann muss jedes Objekt einzeln gepflegt werden. Der vierte Fehler ist die Änderung der ACL eines geschützten Kontos: Der Eintrag ist nach spätestens einer Stunde wieder verschwunden, weil SDProp ihn zurücksetzt.

```powershell
# FALSCH: Recht direkt an einen Benutzer, am einzelnen Objekt
dsacls "CN=Max Mueller,OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" /G "CORP\jschmid:CA;Reset Password"

# RICHTIG: Rolle als Gruppe, an der OU, mit Vererbung - nachvollziehbar und leicht zu pruefen
dsacls "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" /I:S /G "CORP\G-Helpdesk:CA;Reset Password;user"
```

> **Ergänzung aus der Nachrecherche**
>
> Die Unterscheidung von Besitzer, DACL und SACL, die Verwendung der Gruppen statt Einzelpersonen und die Syntax von `dsacls` sind Fachwissen und nicht abgerufen. Die Schutzmechanismen AdminSDHolder und SDProp (60 Minuten, auf dem PDC-Emulator, Zurücksetzen der Berechtigungen, Abschalten der Vererbung, `adminCount`, Liste der geschützten Konten und Gruppen) belegen die abgerufenen Seiten „Appendix C: Protected Accounts and Groups in Active Directory“ und „Reducing the Active Directory Attack Surface“ (Microsoft Learn).

### Praxisbezug

> **Praxisbeispiel**
>
> Die Helpdesk-Gruppe soll Kennwörter zurücksetzen dürfen. Ein Mitarbeiter meldet, dass das bei einer Teamleiterin nicht funktioniert. Ursache: Die Teamleiterin war einmal Mitglied einer Administratorengruppe, ihr Konto hat deshalb noch `adminCount=1`, und die Vererbung ist abgeschaltet, sodass die delegierte Berechtigung nicht ankommt. Das Team setzt das Attribut zurück und aktiviert die Vererbung am Objekt wieder; seitdem funktioniert die Delegierung. Als Vorbeugung läuft ein Skript, das monatlich Konten mit `adminCount=1` ohne Mitgliedschaft in einer geschützten Gruppe meldet.

## 8.6 Delegation of Control

Ein Domain Admin kann alles, und genau deshalb sollte man dieses Recht so wenigen Personen wie möglich geben. Die Microsoft-Dokumentation beschreibt die *Delegierung der Verwaltung* (Delegation of Control) als das Mittel, Teilaufgaben an andere Benutzer und Gruppen zu übertragen: Einfache Aufgaben übernehmen Teams vor Ort, die domainweite und gesamtstrukturweite Verwaltung bleibt bei den Domain Admins und Enterprise Admins. Das verringert das Risiko, weil weniger Konten über weitreichende Rechte verfügen, und es entlastet die zentrale IT. Technisch ist die Delegierung nichts anderes als das Setzen von ACEs (Lerneinheit 8.5) an einer OU, und zwar so, dass genau die gewünschte Aufgabe ermöglicht wird und nicht mehr.

Für die häufigsten Aufgaben gibt es den *Assistenten zum Zuweisen der Objektverwaltung* (Delegation of Control Wizard). Man startet ihn in „Active Directory-Benutzer und -Computer“ über einen Rechtsklick auf die Domain oder OU und „Objektverwaltung zuweisen“. Die Dokumentation zählt als Standardaufgaben auf: Benutzerkonten erstellen, löschen und verwalten, Kennwörter zurücksetzen und die Änderung beim nächsten Anmelden erzwingen, alle Benutzerinformationen lesen, die Mitgliedschaft einer Gruppe ändern, einen Computer in die Domain aufnehmen, Gruppenrichtlinienverknüpfungen verwalten, Gruppenrichtlinien-Ergebnisse (RSoP) erzeugen sowie entsprechende Aufgaben für inetOrgPerson-Objekte. Daneben gibt es die Option „benutzerdefinierte Aufgabe“, mit der man den Objekttyp und die einzelnen Berechtigungen selbst festlegt.

Wichtig ist, was die Dokumentation betont: Der Assistent delegiert nicht nur für die OU selbst, sondern für *alle Objekte unter dem gewählten übergeordneten Container*. Die Standardaufgaben gelten für alle Objekte im Geltungsbereich des Containers. Deshalb gehört zur Delegierung immer eine saubere OU-Struktur (Modul 3): Man delegiert pro OU, also für den Vertrieb, die Buchhaltung oder einen Standort, und nicht an der Domain-Wurzel. Außerdem delegiert man *an Gruppen*, nicht an Personen, und dokumentiert, welche Gruppe welche Rechte an welcher OU erhält.

Der Assistent hat zwei Schwächen. Er kann nur hinzufügen, nicht zurücknehmen; zum Entfernen muss man die ACL direkt bearbeiten (Lerneinheit 8.5). Und er gibt keine Übersicht über bestehende Delegierungen. Beides lässt sich mit Skripten lösen. Das folgende Beispiel richtet die Delegierung „Helpdesk darf Kennwörter zurücksetzen und Konten entsperren“ mit `dsacls` ein, legt außerdem eine Delegierung „Team darf Mitglieder einer Gruppe ändern“ an und erstellt zuletzt einen Bericht über die ausdrücklich gesetzten Rechte einer OU.

```powershell
Import-Module ActiveDirectory
$ou  = "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com"
$grp = "CORP\G-Helpdesk"

# 1) Rolle als Gruppe anlegen (sofern noch nicht vorhanden)
if (-not (Get-ADGroup -Filter "Name -eq 'G-Helpdesk'")) {
    New-ADGroup -Name "G-Helpdesk" -GroupScope Global -GroupCategory Security `
        -Path "OU=Gruppen,OU=Contoso,DC=corp,DC=contoso,DC=com" `
        -Description "Helpdesk: Kennwort zuruecksetzen, Konten entsperren"
}

# 2) Kennwort zuruecksetzen (erweitertes Recht) fuer Benutzerobjekte in dieser OU und darunter
dsacls $ou /I:S /G "${grp}:CA;Reset Password;user"

# 3) Benutzer duerfen die Eigenschaften lockoutTime und pwdLastSet schreiben
#    (Konto entsperren und Aenderung beim naechsten Anmelden verlangen)
dsacls $ou /I:S /G "${grp}:WP;lockoutTime;user"
dsacls $ou /I:S /G "${grp}:WP;pwdLastSet;user"

# 4) Lesen aller Benutzerinformationen
dsacls $ou /I:S /G "${grp}:RP;;user"

# 5) Bericht: ausdruecklich gesetzte (nicht geerbte) Rechte der OU
(Get-Acl "AD:\$ou").Access |
    Where-Object { -not $_.IsInherited } |
    Select-Object IdentityReference, AccessControlType, ActiveDirectoryRights, InheritanceType |
    Format-Table -AutoSize

# 6) Delegierung wieder entfernen (Gruppe aus der ACL streichen)
dsacls $ou /R $grp
```

Schritt 1 legt die Rolle als globale Sicherheitsgruppe an, wenn sie noch fehlt. Schritt 2 vergibt das *erweiterte Recht* „Reset Password“; der Zusatz `CA` steht für *Control Access* (erweitertes Recht), `user` beschränkt es auf Objekte der Klasse Benutzer, und `/I:S` bedeutet, dass das Recht nur auf Unterobjekte der OU vererbt wird. Die Schritte 3 und 4 setzen Attributrechte: `WP` für Schreiben (Write Property) und `RP` für Lesen (Read Property) der genannten Eigenschaften. Das Schreiben von `lockoutTime` entspricht dem Entsperren, das von `pwdLastSet` dem Erzwingen der Kennwortänderung. Schritt 5 zeigt, was jemand ausdrücklich gesetzt hat, und Schritt 6 nimmt die Delegierung mit der Option `/R` zurück.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, den Assistenten an der Domain-Wurzel auszuführen. Dann gilt das Recht, Kennwörter zurückzusetzen, für *alle* Benutzer der Domain, einschließlich der Administratoren, wenn nicht die Schutzfunktion durch AdminSDHolder eingreift (Lerneinheit 8.5). Der zweite Fehler ist, eine Delegierung ohne Dokumentation zu vergeben; nach einem Jahr weiß niemand mehr, wer was darf. Der dritte Fehler ist, die Delegierung einer einzelnen Person zu geben statt einer Gruppe.

```powershell
# FALSCH: Helpdesk-Recht an der Domain-Wurzel, an eine Person
dsacls "DC=corp,DC=contoso,DC=com" /I:T /G "CORP\mmeier:CA;Reset Password;user"

# RICHTIG: Gruppe, begrenzte OU, nur Benutzerobjekte, dokumentiert
dsacls "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" /I:S /G "CORP\G-Helpdesk:CA;Reset Password;user"
# Dokumentation: Datum, Gruppe, OU, Recht, Antragsteller - z. B. in einer Tabelle im Wiki
```

> **Ergänzung aus der Nachrecherche**
>
> Die Beschreibung des Assistenten, die Liste der Standardaufgaben, die Wirkung auf alle Objekte unter dem Container und die Option der benutzerdefinierten Aufgabe belegt die abgerufene Seite „Delegation of control in Active Directory Domain Services“ (Microsoft Learn). Die Parameter von `dsacls` (`CA`, `WP`, `RP`, `/I:S`, `/R`) und die Zuordnung der Eigenschaften `lockoutTime` und `pwdLastSet` zu den genannten Aufgaben stammen aus dem Fachwissen; bitte im Labor mit Schritt 5 prüfen.

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Firma mit vier Standorten stellt pro Standort eine OU mit lokalen Benutzern bereit. Jeder Standort hat eine Gruppe „G-Helpdesk-Standortname“, die genau für ihre OU Kennwörter zurücksetzen, Konten entsperren und Gruppenmitglieder pflegen darf. Die zentrale IT muss nicht mehr eingreifen, und die Administratorgruppe bleibt auf drei Personen beschränkt. Beim vierteljährlichen Audit wird mit dem Bericht aus Schritt 5 pro OU kontrolliert, ob nur diese Gruppen Rechte haben.

## 8.7 Password Policies

Die *Kennwortrichtlinie* (Password Policy) legt fest, welche Anforderungen ein Kennwort erfüllen muss und wie lange es gilt. Die wichtigsten Einstellungen sind: die *Mindestlänge*, die *Komplexitätsanforderung* (Mischung aus Zeichenarten), das *maximale Kennwortalter* (nach wie vielen Tagen eine Änderung verlangt wird), das *minimale Kennwortalter* (wie lange ein Kennwort mindestens gelten muss, bevor es erneut geändert werden darf), und der *Kennwortverlauf* (wie viele frühere Kennwörter nicht wieder verwendet werden dürfen). In der Domain legt man sie unter *Computerkonfiguration, Richtlinien, Windows-Einstellungen, Sicherheitseinstellungen, Kontorichtlinien, Kennwortrichtlinien* fest.

Es gibt einen Punkt, der in der Praxis oft übersehen wird und von der Microsoft-Dokumentation zur Sicherheitsbasislinie ausdrücklich betont wird: Die Einstellungen der Kennwort- und Kontosperrrichtlinie müssen im GPO *Default Domain Policy* (oder einem GPO, das mit höherer Priorität an der Domain-Wurzel verknüpft ist) stehen, damit sie für *Domänenkonten* gelten. Werden sie in einem anderen GPO konfiguriert, etwa an einer OU, beeinflussen sie nur die *lokalen* Konten der Computer, die das GPO erhalten. Das ist die Folge einer Besonderheit: Für Domänenkonten gibt es genau eine Kennwortrichtlinie je Domain (Ausnahmen regeln die differenzierten Richtlinien, Lerneinheit 8.8). Aus diesem Grund ist die Default Domain Policy einer der wenigen Orte, an denen man Einstellungen ändert, obwohl man es sonst vermeidet (Lerneinheit 7.1).

Welche Werte sind vernünftig? Die als Basis veröffentlichten Empfehlungen von Microsoft nennen für die *Mindestlänge* 14 oder mehr Zeichen und beschreiben, dass Kennwörter besser als „Passphrase“ (ein langer Satz) zu verstehen sind, der sich leichter merken lässt als eine kurze Zufallsfolge; die Länge ist wichtiger als die Komplexität. Das *minimale Kennwortalter* sollte mindestens 1 Tag betragen, sonst kann ein Benutzer den Kennwortverlauf umgehen, indem er das Kennwort mehrfach hintereinander ändert und so zum alten Kennwort zurückkehrt. Zu häufigen Änderungen rät die aktuelle Fachdiskussion ab, weil sie zu schwachen Mustern führen („Sommer2024!“ wird zu „Herbst2024!“). Besser ist ein langes Kennwort, das nur bei Verdacht auf Kompromittierung geändert wird, kombiniert mit einer Prüfung gegen Listen bekannter schwacher Kennwörter und einer Mehrfaktor-Authentifizierung.

Das folgende Skript liest die aktuelle Domänenkennwortrichtlinie aus, vergleicht sie mit einer Sollvorgabe und gibt Abweichungen aus. Es zeigt auch, wie man die Richtlinie per PowerShell ändert, und enthält eine Prüfung, welche Konten Kennwörter besitzen, die nie ablaufen.

```powershell
Import-Module ActiveDirectory

# 1) Aktuelle Kennwortrichtlinie der Domain lesen
$ist = Get-ADDefaultDomainPasswordPolicy
$ist | Select-Object MinPasswordLength, PasswordHistoryCount, MaxPasswordAge, MinPasswordAge,
                     ComplexityEnabled, ReversibleEncryptionEnabled, LockoutThreshold,
                     LockoutDuration, LockoutObservationWindow

# 2) Sollvorgabe festlegen und vergleichen
$soll = @{ MinPasswordLength = 14; PasswordHistoryCount = 24; ComplexityEnabled = $true;
           MinPasswordAgeTage = 1 }
$abweichungen = @()
if ($ist.MinPasswordLength -lt $soll.MinPasswordLength) { $abweichungen += "Mindestlaenge zu klein: $($ist.MinPasswordLength)" }
if ($ist.PasswordHistoryCount -lt $soll.PasswordHistoryCount) { $abweichungen += "Kennwortverlauf zu klein: $($ist.PasswordHistoryCount)" }
if (-not $ist.ComplexityEnabled) { $abweichungen += "Komplexitaet ausgeschaltet" }
if ($ist.MinPasswordAge.TotalDays -lt $soll.MinPasswordAgeTage) { $abweichungen += "Minimales Alter < 1 Tag" }
if ($ist.ReversibleEncryptionEnabled) { $abweichungen += "Umkehrbare Verschluesselung aktiv (unzulaessig)" }
if ($abweichungen) { $abweichungen } else { "Richtlinie entspricht der Sollvorgabe." }

# 3) Richtlinie aendern (nach Freigabe und Sicherung des GPO)
Set-ADDefaultDomainPasswordPolicy -Identity "corp.contoso.com" `
    -MinPasswordLength 14 -PasswordHistoryCount 24 -MinPasswordAge "1.00:00:00" `
    -ComplexityEnabled $true -ReversibleEncryptionEnabled $false

# 4) Konten mit Kennwort, das nie ablaeuft (aktive Benutzer)
Get-ADUser -Filter 'Enabled -eq $true -and PasswordNeverExpires -eq $true' `
    -Properties PasswordNeverExpires, PasswordLastSet |
    Select-Object SamAccountName, PasswordLastSet | Sort-Object PasswordLastSet
```

Schritt 1 gibt die Einstellungen der Standardrichtlinie aus; `MaxPasswordAge` und die Zeitspannen werden als Zeitwerte (Tage.Stunden:Minuten:Sekunden) ausgegeben. Schritt 2 prüft die Werte gegen eine Vorgabe. Die Abweichungen erscheinen im Klartext; das Muster lässt sich als regelmäßige Kontrolle verwenden. Schritt 3 ändert die Werte direkt im AD; man kann dazu auch den Editor im GPO „Default Domain Policy“ verwenden. Schritt 4 sucht Benutzer, deren Kennwort nie abläuft. Bei Menschen ist das meist unerwünscht; für Dienstkonten kann es nötig sein, besser ersetzt man sie durch verwaltete Dienstkonten (Modul 4).

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, die Kennwortrichtlinie in ein GPO an einer OU zu schreiben und zu wundern, dass sie nicht wirkt: Sie gilt dann nur für lokale Konten. Der zweite Fehler ist, eine sehr kurze Gültigkeit (30 Tage) mit einer großen Komplexität zu verbinden, ohne die Länge zu erhöhen; das führt zu Kennwörtern, die auf Zetteln am Bildschirm stehen. Der dritte Fehler ist das Aktivieren der *umkehrbaren Verschlüsselung* (Reversible Encryption), die Kennwörter im Klartext rekonstruierbar speichert; sie wird nur für wenige alte Anwendungen benötigt.

```powershell
# FALSCH: Kennwortrichtlinie als GPO an der OU - betrifft nur lokale Konten der Computer
New-GPLink -Name "Kennwortrichtlinie" -Target "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com"

# RICHTIG: In der Default Domain Policy (oder einem GPO mit hoeherer Prioritaet an der Domain-Wurzel)
#          bzw. fuer Ausnahmen eine differenzierte Richtlinie (Lerneinheit 8.8)
Get-GPInheritance -Target "DC=corp,DC=contoso,DC=com" | Select-Object -ExpandProperty GpoLinks
```

> **Ergänzung aus der Nachrecherche**
>
> Die Aussage, dass Kennwort- und Kontosperrrichtlinien über die Default Domain Policy für Domänenkonten wirken und in anderen GPOs nur lokale Konten betreffen, sowie die empfohlenen Werte (Mindestlänge 14, minimales Alter mindestens 1 Tag) stammen aus den abgerufenen Seiten zur Windows-Sicherheitsbasislinie („Windows security baseline“, Microsoft Learn, Azure Policy Guest Configuration). Die Standardwerte der Domain-Richtlinie (zum Beispiel Mindestlänge 7, Verlauf 24, maximales Alter 42 Tage, Komplexität eingeschaltet) und die Diskussion zum regelmäßigen Wechsel von Kennwörtern stammen aus dem Fachwissen und sind nicht abgerufen; die Standardwerte sollten im eigenen System mit Schritt 1 gelesen werden.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen erhält bei einer Prüfung die Beanstandung, die Mindestlänge betrage nur 8 Zeichen. Die IT setzt sie auf 14, schaltet das erzwungene 30-Tage-Ändern ab und führt zusätzlich eine Mehrfaktor-Anmeldung für Fernzugriffe ein. Für die Benutzer wird erklärt, dass ein Satz als Kennwort erlaubt ist. Die Zahl der Anrufe beim Helpdesk wegen vergessener Kennwörter sinkt, weil nicht mehr alle vier Wochen ein neues Kennwort gebraucht wird.

## 8.8 Fine-Grained Password Policies

Die Domain-weite Kennwortrichtlinie passt nicht für alle. Administratoren sollten längere Kennwörter haben als normale Benutzer, Dienstkonten haben andere Anforderungen als Menschen, und Konten, die nur an einem Terminal im Lager genutzt werden, brauchen vielleicht eine einfachere Regel. Dafür gibt es seit Windows Server 2008 die *differenzierten Kennwortrichtlinien* (Fine-Grained Password Policies, FGPP). Sie sind unabhängig von Gruppenrichtlinien: Jede Richtlinie ist ein Objekt der Klasse *Password Settings Object* (PSO) im Container `CN=Password Settings Container,CN=System` der Domain, das alle Einstellungen der Kennwort- und Sperrrichtlinie enthält und direkt Benutzern oder globalen Sicherheitsgruppen zugewiesen wird. Die Microsoft-Dokumentation nennt als einfachste Verwaltung das *Active Directory-Verwaltungscenter* (ADAC), das eine eigene Oberfläche dafür bietet, und die PowerShell-Cmdlets des Active-Directory-Moduls.

Ein PSO enthält unter anderem Namen, *Rang* (Precedence), Mindestlänge, Komplexität, Verlauf, minimales und maximales Alter, umkehrbare Verschlüsselung sowie Sperrschwelle, Sperrdauer und Zeitfenster. Aus der Dokumentation zum Cmdlet `New-ADFineGrainedPasswordPolicy` ergibt sich, dass mindestens `-Name` und `-Precedence` angegeben werden müssen. Der Rang ist eine ganze Zahl; ist mehr als ein PSO auf einen Benutzer anwendbar, gewinnt das Objekt mit dem *niedrigsten Rang*.

Wie ermittelt das System das wirksame PSO eines Benutzers? Die Dokumentation zu `Get-ADUserResultantPasswordPolicy` beschreibt die Regeln: Ein PSO, das *direkt dem Benutzerkonto* zugewiesen ist, gewinnt immer, auch wenn ein anderes PSO über eine Gruppe einen besseren Rang hätte. Gibt es keine direkte Zuweisung, werden alle PSOs betrachtet, die über Gruppenmitgliedschaften gelten, und dasjenige mit dem niedrigsten Rang wird gewählt. Gibt es auch hier keine, gilt die Kennwortrichtlinie der Domain. Ein PSO gilt *nicht* für Computer und nicht für Organisationseinheiten; wer eine OU abdecken will, legt eine globale Sicherheitsgruppe an, die die Benutzer der OU enthält (die sogenannte Schattengruppe, shadow group) und pflegt sie per Skript oder Regel.

Das folgende Beispiel legt zwei PSOs an: eine strenge Richtlinie für Administratoren und eine für Dienstkonten. Es weist sie Gruppen zu und prüft, welche Richtlinie ein Benutzer tatsächlich erhält.

```powershell
Import-Module ActiveDirectory

# 1) Strenge Richtlinie fuer Administratoren (niedriger Rang = hoehere Prioritaet)
New-ADFineGrainedPasswordPolicy -Name "PSO-Admins" -Precedence 10 `
    -MinPasswordLength 16 -PasswordHistoryCount 24 -ComplexityEnabled $true `
    -MinPasswordAge "1.00:00:00" -MaxPasswordAge "90.00:00:00" `
    -LockoutThreshold 5 -LockoutDuration "00:30:00" -LockoutObservationWindow "00:30:00" `
    -ReversibleEncryptionEnabled $false `
    -Description "Administratorkonten: 16 Zeichen, Sperre nach 5 Fehlversuchen"

# 2) Richtlinie fuer Dienstkonten (lange Kennwoerter, keine automatische Sperre)
New-ADFineGrainedPasswordPolicy -Name "PSO-Dienstkonten" -Precedence 20 `
    -MinPasswordLength 25 -PasswordHistoryCount 24 -ComplexityEnabled $true `
    -MinPasswordAge "1.00:00:00" -MaxPasswordAge "365.00:00:00" `
    -LockoutThreshold 0 -ReversibleEncryptionEnabled $false

# 3) Den Gruppen zuweisen (globale Sicherheitsgruppen, nicht OUs)
Add-ADFineGrainedPasswordPolicySubject -Identity "PSO-Admins"      -Subjects "G-Administratoren"
Add-ADFineGrainedPasswordPolicySubject -Identity "PSO-Dienstkonten" -Subjects "G-Dienstkonten"

# 4) Uebersicht ueber alle PSOs, geordnet nach Rang
Get-ADFineGrainedPasswordPolicy -Filter * |
    Sort-Object Precedence |
    Select-Object Name, Precedence, MinPasswordLength, MaxPasswordAge, LockoutThreshold

# 5) Wer unterliegt welchem PSO?
Get-ADFineGrainedPasswordPolicy -Filter * | ForEach-Object {
    $p = $_
    Get-ADFineGrainedPasswordPolicySubject -Identity $p |
        Select-Object @{n="PSO";e={$p.Name}}, Name, ObjectClass
}

# 6) Welches PSO gilt tatsaechlich fuer ein Konto? (Ergebnis wie "Resultant")
Get-ADUserResultantPasswordPolicy -Identity "adm.mmeier"
Get-ADUserResultantPasswordPolicy -Identity "jschmid"     # keine Ausgabe: Domainrichtlinie gilt
```

Schritt 1 erzeugt das strenge PSO mit Rang 10; Zeitwerte werden als „Tage.Stunden:Minuten:Sekunden“ angegeben. Schritt 2 erzeugt das PSO für Dienstkonten mit Rang 20 und sehr langen Kennwörtern; die Sperrschwelle 0 bedeutet „nie sperren“, was bei Dienstkonten Sinn hat, damit ein falsch konfigurierter Dienst nicht das Konto sperrt und damit einen Ausfall verursacht. Schritt 3 weist die PSOs den Gruppen zu. Schritt 4 zeigt eine Übersicht nach Rang. Schritt 5 listet für jedes PSO die Konten und Gruppen, auf die es angewendet wird. Schritt 6 fragt das wirksame Ergebnis für ein Konto ab; für ein Konto ohne PSO liefert das Cmdlet nichts, dann gilt die Richtlinie der Domain.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die Erwartung, dass ein PSO auf eine OU wirkt: Es wirkt nur auf Benutzer und globale Sicherheitsgruppen. Der zweite Fehler ist das Anlegen mehrerer PSOs mit demselben Rang, was die Auswahl unklar macht; jedes PSO bekommt eine eindeutige Zahl (mit Abständen wie 10, 20, 30, um später Raum zu lassen). Der dritte Fehler ist, die Zuordnung nicht zu prüfen: Ein Administratorkonto, das über zwei Gruppen zwei PSOs erhält, bekommt das mit dem niedrigeren Rang, was man erwartet oder auch nicht. Der vierte Fehler ist, Einstellungen im PSO vollständig anzugeben, aber die Domainrichtlinie weiterzupflegen und dann unterschiedliche Werte zu erwarten.

```powershell
# FALSCH: PSO soll "fuer die OU Dienstkonten" gelten - eine OU kann kein Subject sein
Add-ADFineGrainedPasswordPolicySubject -Identity "PSO-Dienstkonten" -Subjects "OU=Dienstkonten,OU=Contoso,DC=corp,DC=contoso,DC=com"

# RICHTIG: Globale Sicherheitsgruppe als Schattengruppe, die alle Konten der OU enthaelt
$konten = Get-ADUser -SearchBase "OU=Dienstkonten,OU=Contoso,DC=corp,DC=contoso,DC=com" -Filter *
Add-ADGroupMember -Identity "G-Dienstkonten" -Members $konten
Add-ADFineGrainedPasswordPolicySubject -Identity "PSO-Dienstkonten" -Subjects "G-Dienstkonten"
```

> **Ergänzung aus der Nachrecherche**
>
> Die Pflichtparameter `-Name` und `-Precedence`, die Regeln zur Auswahl des wirksamen PSO (direkte Zuweisung vor Gruppen, niedrigster Rang gewinnt, sonst Domainrichtlinie) und die Verwaltung über das Active Directory-Verwaltungscenter belegen die abgerufenen Seiten zu „New-ADFineGrainedPasswordPolicy“, „Get-ADFineGrainedPasswordPolicy“, „Get-ADUserResultantPasswordPolicy“ und „Advanced AD DS management using Active Directory Administrative Center“ (Microsoft Learn). Dass ein PSO für Computer und OUs nicht gilt, und den Aufbau mit Schattengruppen kennt man aus dem Fachwissen; die genannten Rangwerte und Beispiele (16 Zeichen, 25 Zeichen) sind Lernbeispiele und keine Empfehlung von Microsoft.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Krankenhaus hat Verwaltungsangestellte, Ärztinnen, IT-Administratoren und Konten für Geräte an der Pforte. Für die IT-Administratoren gilt ein PSO mit 16 Zeichen und strenger Sperre, für die Stationskonten ein PSO ohne Ablauf, aber mit langer Sperrdauer, weil wiederholtes Anmelden vor Ort erwartbar ist. Alle anderen Konten unterliegen der Domainrichtlinie. Ein Skript prüft jede Nacht, ob die Schattengruppen den OUs entsprechen, und meldet Konten, die in keiner Gruppe auftauchen.

## 8.9 Account Lockout

Die *Kontosperrung* (Account Lockout) schützt vor dem Erraten von Kennwörtern: Nach einer bestimmten Anzahl falscher Anmeldeversuche wird das Konto gesperrt. Drei Einstellungen steuern sie. Die *Kontosperrschwelle* (Account lockout threshold) nennt die Zahl der fehlgeschlagenen Versuche, bei der gesperrt wird; der Wert 0 bedeutet, dass nie gesperrt wird. Die *Kontosperrdauer* (Account lockout duration) legt fest, wie viele Minuten das Konto gesperrt bleibt; der Wert 0 bedeutet, dass es gesperrt bleibt, bis ein Administrator es entsperrt. Das *Zurücksetzungsfenster* (Reset account lockout counter after, auch Beobachtungsfenster, Observation Window) gibt an, nach wie vielen Minuten ohne weiteren Fehlversuch der Zähler für falsche Kennwörter wieder auf null gesetzt wird. Die Dokumentation zur Sicherheitsbasislinie fordert, dass das Fenster kleiner oder gleich der Sperrdauer ist.

Die Auswahl der Werte ist ein Abwägen zwischen zwei Gefahren. Eine zu lockere Einstellung lässt Angreifer ungestört raten. Eine zu strenge Einstellung ermöglicht einen *Denial-of-Service-Angriff*: Wer absichtlich falsche Kennwörter für viele Konten eingibt, sperrt ganze Abteilungen. Die Microsoft-Empfehlung nennt deshalb für die Sperrdauer und das Zurücksetzungsfenster jeweils *15 Minuten oder mehr* und für die Schwelle in der Sicherheitsbasislinie den Wert *10*. Wichtig ist auch: Gesperrte Konten verursachen laut der Dokumentation die meisten Anrufe beim Helpdesk. Eine kurze Dauer von etwa 15 Minuten dämpft den Aufwand, weil die Sperre von selbst abläuft.

Wie funktioniert die Sperrung technisch? Jeder Domain Controller zählt falsche Kennwörter im Attribut `badPwdCount`. Damit die Sperrung domainweit greift, leiten die Domain Controller Fehlversuche an den *PDC-Emulator* (Lerneinheit 6.4) weiter, der den Zähler führt. Wird die Schwelle erreicht, wird das Attribut `lockoutTime` gesetzt, das Konto ist gesperrt, und das Ereignis *4740* im Sicherheitsprotokoll nennt Konto und den *Quellcomputer*, von dem die falschen Anmeldungen kamen. Dieser Name ist der wichtigste Hinweis bei der Suche nach der Ursache: Häufig ist es ein Gerät mit gespeichertem altem Kennwort (Handy mit Mail-Konto, ein Netzlaufwerk, ein Dienst, eine geplante Aufgabe) und nicht ein Angreifer.

Für Hybridumgebungen beschreibt die Dokumentation zur Smart Lockout von Microsoft Entra, dass die Schwelle in Entra *kleiner* und die Sperrdauer *länger* als im lokalen AD sein sollte; als Faustregel nennt sie, dass die lokale Schwelle mindestens zwei- bis dreimal so hoch wie die in Entra ist, damit die Cloud Angriffe abfängt, bevor sie das lokale AD erreichen.

Das folgende Skript sucht gesperrte Konten, findet über die Ereignisse die Quelle der Sperrung und entsperrt ein Konto. Es zeigt auch die Sperreinstellungen der Domain und prüft ein Benutzerkonto auf Fehlversuche je Domain Controller.

```powershell
Import-Module ActiveDirectory

# 1) Aktuell gesperrte Konten der Domain
Search-ADAccount -LockedOut | Select-Object SamAccountName, LockedOut, LastLogonDate

# 2) Domaineinstellungen zur Sperre ansehen
Get-ADDefaultDomainPasswordPolicy |
    Select-Object LockoutThreshold, LockoutDuration, LockoutObservationWindow

# 3) Ursache suchen: Ereignis 4740 auf dem PDC-Emulator der letzten 24 Stunden
$pdc = (Get-ADDomain).PDCEmulator
Get-WinEvent -ComputerName $pdc -FilterHashtable @{
    LogName = "Security"; Id = 4740; StartTime = (Get-Date).AddHours(-24) } |
  ForEach-Object {
    $x = [xml]$_.ToXml()
    $d = @{}
    foreach ($n in $x.Event.EventData.Data) { $d[$n.Name] = $n.'#text' }
    [pscustomobject]@{
        Zeit   = $_.TimeCreated
        Konto  = $d["TargetUserName"]
        Quelle = $d["TargetDomainName"]      # Name des Computers, von dem die Fehlversuche kamen
    }
  } | Sort-Object Zeit -Descending | Format-Table -AutoSize

# 4) Fehlversuche je Domain Controller (Zaehler wird zwischen DCs nicht sofort repliziert)
$name = "mmeier"
Get-ADDomainController -Filter * | ForEach-Object {
    $u = Get-ADUser -Identity $name -Server $_.HostName -Properties badPwdCount, lockoutTime, LockedOut
    [pscustomobject]@{ DC = $_.HostName; BadPwd = $u.badPwdCount; Gesperrt = $u.LockedOut }
}

# 5) Konto entsperren (nach Klaerung der Ursache, nicht vorher)
Unlock-ADAccount -Identity $name
```

Schritt 1 listet gesperrte Konten. Schritt 2 zeigt die Domaineinstellungen. Schritt 3 liest das Ereignis 4740 auf dem PDC-Emulator, weil die Sperrung dort verarbeitet wird; das Feld `TargetDomainName` enthält bei diesem Ereignis den Namen des Quellcomputers (so beschreibt es das Ereignis). Schritt 4 fragt jeden Domain Controller nach dem Zähler: Weil `badPwdCount` nicht sofort repliziert wird, sieht man in diesem Schritt, wo Fehlversuche auftraten. Schritt 5 entsperrt das Konto. Wichtig ist die Reihenfolge: Entsperrt man, ohne die Quelle der falschen Kennwörter zu beheben, wird das Konto in kurzer Zeit wieder gesperrt.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, das Konto zu entsperren, ohne die Ursache zu finden. Das Konto wird nach Minuten wieder gesperrt, und der Anwender ruft erneut an. Der zweite Fehler ist, bei der Fehlersuche auf dem falschen Domain Controller zu suchen; die Ereignisse stehen auf dem PDC-Emulator und auf dem Domain Controller, der die Anmeldung bearbeitet hat. Der dritte Fehler ist eine Sperrschwelle von 3 mit einer Sperrdauer von 0 (bis zur manuellen Entsperrung): Das ist ein Geschenk für jeden, der die Organisation lahmlegen will.

```powershell
# FALSCH: Schwelle 3, Dauer 0 (manuell entsperren), Fenster 1 Minute
Set-ADDefaultDomainPasswordPolicy -Identity "corp.contoso.com" -LockoutThreshold 3 `
    -LockoutDuration "00:00:00" -LockoutObservationWindow "00:01:00"

# RICHTIG: Schwelle 10, Dauer 15 Minuten, Fenster 15 Minuten (Fenster <= Dauer)
Set-ADDefaultDomainPasswordPolicy -Identity "corp.contoso.com" -LockoutThreshold 10 `
    -LockoutDuration "00:15:00" -LockoutObservationWindow "00:15:00"
```

> **Ergänzung aus der Nachrecherche**
>
> Die Bedeutung von Schwelle, Dauer und Zurücksetzungsfenster, die Bedingung „Fenster kleiner oder gleich der Dauer“, die Empfehlungen von 15 oder mehr Minuten sowie die Schwelle 10 aus der Microsoft-Sicherheitsbasislinie, die Gefahr des Denial-of-Service und die Hinweise zu Entra Smart Lockout belegen die abgerufenen Seiten „Windows security baseline“, „Set the account lockout threshold to recommended value“ und „Protect user accounts from attacks with Microsoft Entra smart lockout“ (Microsoft Learn). Die Rolle des PDC-Emulators beim Weiterleiten der Fehlversuche, das Ereignis 4740 mit dem Feld für den Quellcomputer und das Verhalten von `badPwdCount` stammen aus dem Fachwissen und sollten im Labor überprüft werden.

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Mitarbeiterin wird jeden Morgen um 8:05 Uhr gesperrt. Das Ereignis 4740 nennt als Quelle den Namen ihres alten Laptops, der noch im Netzwerk hängt und mit dem früheren Kennwort Verbindungen zu einem Netzlaufwerk versucht. Nach dem Entfernen der gespeicherten Anmeldedaten auf diesem Gerät treten keine Sperrungen mehr auf. Ohne das Ereignis wäre die Suche nach einem vermuteten Angriff auf das Konto zeitaufwendig und vergeblich gewesen.

## 8.10 Übungsaufgaben zu Modul 08

Die Aufgaben 1 bis 3 prüfen das Verständnis, die Aufgaben 4 bis 8 sind praktische Aufgaben für die Laborumgebung.

**Aufgabe 8.1** **Kerberos erklären.** Beschreiben Sie in eigenen Worten die drei Austausche von Kerberos (AS, TGS, AP) und nennen Sie, welches Ticket in welchem Schritt ausgestellt wird. Erklären Sie, warum der Zugriff auf eine Freigabe über die IP-Adresse oft NTLM verwendet.

**Aufgabe 8.2** **Zeit und Tickets.** Ein Server geht 12 Minuten vor, Benutzer können sich dort nicht mehr anmelden. Erklären Sie die Ursache und die Lösung. Welche Rolle spielt die Zeitquelle des PDC-Emulators?

**Aufgabe 8.3** **Richtlinienort.** Ein Kollege hat die Kennwortrichtlinie (Mindestlänge 14) in einem GPO an der OU „Benutzer“ konfiguriert; die Domänenbenutzer können weiterhin 8-stellige Kennwörter setzen. Erklären Sie das und nennen Sie zwei Lösungen.

**Aufgabe 8.4** **SPN prüfen.** Suchen Sie in der Laborumgebung mit `setspn` alle SPNs eines Mitgliedsservers, prüfen Sie auf Duplikate in der Gesamtstruktur und verbinden Sie sich danach einmal per FQDN und einmal per IP-Adresse mit einer Freigabe. Zeigen Sie mit `klist`, bei welcher Verbindung ein Dienstticket entsteht.

**Aufgabe 8.5** **NTLM-Bericht.** Schreiben Sie ein Skript, das die Anmeldeereignisse 4624 der letzten 24 Stunden auswertet und die zehn häufigsten Kombinationen aus Konto und Quelle ausgibt, die NTLM verwenden. Speichern Sie das Ergebnis als CSV-Datei.

**Aufgabe 8.6** **LDAPS-Prüfung.** Schreiben Sie ein Skript, das für jeden Domain Controller der Domain prüft, ob Port 636 erreichbar ist und wie viele Tage das angebotene Zertifikat noch gültig ist. Domain Controller mit weniger als 30 Tagen Restlaufzeit oder ohne LDAPS sollen in einer Warnliste erscheinen.

**Aufgabe 8.7** **Delegierung und Bericht.** Delegieren Sie an die Gruppe „G-Helpdesk“ in der OU „Benutzer“ das Zurücksetzen von Kennwörtern und das Entsperren von Konten. Erstellen Sie dann einen Bericht aller ausdrücklich gesetzten ACEs der OU und prüfen Sie praktisch, dass ein Helpdesk-Mitglied ein Kennwort zurücksetzen kann, in einer anderen OU aber nicht.

**Aufgabe 8.8** **Differenzierte Richtlinie und Sperrung.** Legen Sie ein PSO für Administratoren mit 16 Zeichen und Sperrschwelle 5 an, weisen Sie es einer Gruppe zu und prüfen Sie mit `Get-ADUserResultantPasswordPolicy`. Lösen Sie dann absichtlich eine Sperrung eines Testkontos aus, finden Sie die Quelle über das Ereignis 4740 und entsperren Sie das Konto.

## 8.11 Lösungen zu den Übungsaufgaben

**Lösung 8.1.** Im *AS-Austausch* weist sich der Client mit Kennwort oder Schlüssel aus und erhält vom KDC das *TGT*. Im *TGS-Austausch* legt er das TGT vor und erhält ein *Dienstticket* für einen bestimmten Dienst. Im *AP-Austausch* legt er das Dienstticket dem Dienst vor, der den Client damit ohne Rückfrage am Domain Controller erkennt. Beim Zugriff über die IP-Adresse kann der Client keinen passenden SPN (zum Beispiel `cifs/srv01.corp.contoso.com`) bilden, weil ein SPN einen Namen und keine Adresse enthält. Ohne gültigen Zielnamen überspringt das Sicherheitspaket Negotiate Kerberos und verwendet NTLM.

**Lösung 8.2.** Kerberos erlaubt nur eine Zeitabweichung von weniger als fünf Minuten (Standardwert von `SkewTime`). Bei 12 Minuten Differenz lehnt der Server die Tickets ab (Fehler `KRB_AP_ERR_SKEW`). Lösung: die Zeit korrigieren und die Ursache beheben (zum Beispiel die Zeitsynchronisierung der virtuellen Maschine mit dem Host abschalten und die Domain-Hierarchie nutzen). Die Domain-Hierarchie läuft vom PDC-Emulator der Stammdomain, der idealerweise eine verlässliche externe Zeitquelle hat, über die anderen Domain Controller zu den Mitgliedern (Lerneinheit 6.9). Mit `w32tm /resync` auf dem Server und `klist purge` auf dem Client wird die Wirkung geprüft.

**Lösung 8.3.** Kennwortrichtlinien für Domänenkonten gelten nur, wenn sie in der *Default Domain Policy* oder einem höher priorisierten GPO an der Domain-Wurzel stehen. Ein GPO an einer OU wirkt nur auf die lokalen Konten der Computer in dieser OU. Lösungen: (1) die Einstellung in die Default Domain Policy übernehmen, (2) für einen Teil der Benutzer eine differenzierte Kennwortrichtlinie (PSO) anlegen und der Benutzergruppe zuweisen.

**Lösung 8.4.**

```text
setspn -L SRV01                 # SPNs des Computerkontos
setspn -X -F                    # Duplikate in der Gesamtstruktur
klist purge
net use Z: \\srv01.corp.contoso.com\Daten
klist | findstr /i "srv01"     # Dienstticket cifs/srv01... ist vorhanden
net use Z: /delete
klist purge
net use Z: \\10.10.0.21\Daten
klist | findstr /i "srv01"     # kein Dienstticket: NTLM wurde verwendet
```

Beim Zugriff per FQDN erscheint ein Dienstticket, beim Zugriff per IP-Adresse nicht. Die Adresse `10.10.0.21` ist im Beispiel die Adresse von SRV01 und muss an die eigene Laborumgebung angepasst werden. Wer im Sicherheitsprotokoll des Servers das Ereignis 4624 ansieht, erkennt die NTLM-Anmeldung am Anmeldepaket.

**Lösung 8.5.**

```powershell
$start = (Get-Date).AddHours(-24)
$rows = Get-WinEvent -FilterHashtable @{ LogName="Security"; Id=4624; StartTime=$start } |
  ForEach-Object {
    $x = [xml]$_.ToXml(); $d = @{}
    foreach ($n in $x.Event.EventData.Data) { $d[$n.Name] = $n.'#text' }
    if ($d["AuthenticationPackageName"] -eq "NTLM") {
        [pscustomobject]@{ Konto = "$($d['TargetDomainName'])\$($d['TargetUserName'])"; Quelle = $d["WorkstationName"] }
    }
  }
$rows | Group-Object Konto, Quelle | Sort-Object Count -Descending | Select-Object -First 10 Count, Name |
    Export-Csv -Path "D:\NTLM-Bericht.csv" -NoTypeInformation -Encoding UTF8
```

Das Skript liest die Ereignisse, filtert auf das Anmeldepaket NTLM, gruppiert nach Konto und Quelle und schreibt die zehn häufigsten Kombinationen in eine CSV-Datei. Die Auswertung gilt nur für den Domain Controller, auf dem das Skript läuft; für die ganze Domain muss es auf jedem Domain Controller ausgeführt werden.

**Lösung 8.6.**

```powershell
$warnung = foreach ($dc in (Get-ADDomainController -Filter *).HostName) {
    $tage = $null
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient($dc, 636)
        $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, ({$true}))
        $ssl.AuthenticateAsClient($dc)
        $c = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($ssl.RemoteCertificate)
        $tage = [int]($c.NotAfter - (Get-Date)).TotalDays
        $tcp.Close()
    } catch { }
    if ($null -eq $tage -or $tage -lt 30) {
        [pscustomobject]@{ DC = $dc; RestTage = $tage; Hinweis = $(if ($null -eq $tage) {"kein LDAPS"} else {"laeuft bald ab"}) }
    }
}
$warnung | Format-Table -AutoSize
```

Gelingt der TLS-Aufbau nicht, bleibt `$tage` leer und der Domain Controller landet mit dem Hinweis „kein LDAPS“ in der Warnliste; ein Zertifikat mit weniger als 30 Tagen Restlaufzeit wird ebenfalls gemeldet. Das Skript eignet sich als geplante Aufgabe.

**Lösung 8.7.** Die `dsacls`-Befehle aus Lerneinheit 8.6 erledigen die Delegierung; mit dem Bericht aus Schritt 5 prüft man, dass die Gruppe in der Liste der ausdrücklich gesetzten Rechte steht. Für den praktischen Test meldet man sich als Mitglied von „G-Helpdesk“ an und setzt mit `Set-ADAccountPassword -Identity testuser -Reset` das Kennwort eines Benutzers in der OU zurück; der Befehl gelingt. In einer anderen OU, an der keine Delegierung besteht, endet der gleiche Befehl mit „Zugriff verweigert“. Das beweist, dass die Delegierung auf die OU begrenzt ist.

**Lösung 8.8.**

```powershell
New-ADFineGrainedPasswordPolicy -Name "PSO-Admins" -Precedence 10 -MinPasswordLength 16 `
    -ComplexityEnabled $true -PasswordHistoryCount 24 `
    -MinPasswordAge "1.00:00:00" -MaxPasswordAge "90.00:00:00" `
    -LockoutThreshold 5 -LockoutDuration "00:30:00" -LockoutObservationWindow "00:30:00"
Add-ADFineGrainedPasswordPolicySubject -Identity "PSO-Admins" -Subjects "G-Administratoren"
Get-ADUserResultantPasswordPolicy -Identity "adm.mmeier"     # liefert PSO-Admins

# Sperrung ausloesen (nur Testkonto im Labor!), 5 falsche Anmeldungen
1..5 | ForEach-Object { net use \\dc01\IPC$ /user:CORP\testuser FalschesKennwort 2>$null }
Search-ADAccount -LockedOut
Get-WinEvent -ComputerName (Get-ADDomain).PDCEmulator -FilterHashtable @{LogName="Security";Id=4740} -MaxEvents 3 |
    Select-Object TimeCreated, Message
Unlock-ADAccount -Identity testuser
```

Die Abfrage mit `Get-ADUserResultantPasswordPolicy` liefert für Mitglieder der Gruppe das PSO `PSO-Admins`. Das Testkonto muss unter der Richtlinie stehen, die man prüfen will; wird es für die Sperre verwendet, muss es dem PSO unterliegen (sonst gilt die Schwelle der Domain). Im Ereignis 4740 steht als Quelle der Computer, von dem aus die falschen Kennwörter eingegeben wurden. Die Sperre endet nach der im PSO festgelegten Dauer von 30 Minuten oder sofort mit `Unlock-ADAccount`.
