# Modul 01 - Active Directory Grundlagen und Architektur

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Tabellen als Markdown-Tabellen, Übungsaufgaben und Lösungen als Absätze). Die Überschriften sind wie in der Quelle nach Modul und Lerneinheit nummeriert (1.1 bis 1.9; 1.10 Übungsaufgaben, 1.11 Lösungen). **Die PowerShell-Beispiele wurden für dieses Repository nicht ausgeführt**; sie setzen eine Windows-Server-Laborumgebung mit der fiktiven Domain `corp.contoso.com` voraus und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain. Übersicht zum Modul: [README](README.md).

|                                       |              |
|:--------------------------------------|:-------------|
| Dauer laut Modulübersicht             | 8 Stunden    |
| Summe der Lerneinheiten (Detailblatt) | 10,5 Stunden |
| Priorität                             | 1            |

| Nr. | Lerneinheit              | Dauer (h) | Prio |
|----:|:-------------------------|----------:|-----:|
| 1.1 | AD DS Einordnung         |         1 |    1 |
| 1.2 | Verzeichnisdienstprinzip |         1 |    1 |
| 1.3 | Objekte und Attribute    |       1,5 |    1 |
| 1.4 | Schema                   |         1 |    1 |
| 1.5 | Forest                   |         1 |    1 |
| 1.6 | Domain                   |       1,5 |    1 |
| 1.7 | Organizational Units     |         1 |    2 |
| 1.8 | Sites                    |         1 |    2 |
| 1.9 | Domain Controller        |       1,5 |    2 |
|     | **Summe**                |  **10,5** |      |

> **Merke**
>
> Die Stundensumme der Lerneinheiten im Detailblatt (10,5 h) weicht von der Dauer in der Modulübersicht (8 h) ab. Dieses Skript behandelt alle Lerneinheiten des Detailblatts vollständig; die Abweichung ist im Lehrplan selbst zu klären.

Dieses Modul legt das Fundament für den gesamten Kurs. Wer am Ende versteht, was ein Verzeichnisdienst ist, wie Active Directory seine Daten ordnet und warum Forest, Domain, Organisationseinheit, Site und Domain Controller jeweils eine eigene Aufgabe haben, kann alle folgenden Module (Installation, Design, Gruppenrichtlinien, Sicherheit, Betrieb) einordnen. Die Beispiele verwenden durchgehend eine fiktive Laborumgebung: die Domain `corp.contoso.com` mit dem NetBIOS-Namen `CORP`, zwei Domain Controllern `DC01` und `DC02`, einem Memberserver `SRV01` und einem Windows-Client `PC01`. Alle PowerShell-Beispiele sind auf einem Domain Controller oder auf einem Verwaltungsrechner mit den Remoteserver-Verwaltungstools (RSAT) lauffähig.

## 1.1 AD DS Einordnung

Ein Unternehmensnetzwerk besteht aus Benutzern, Computern, Druckern, Dateifreigaben und Anwendungen. Ohne zentrale Verwaltung müsste auf jedem Server jedes Benutzerkonto einzeln angelegt werden, jedes Kennwort einzeln gepflegt und jede Berechtigung einzeln vergeben werden. Schon bei zehn Servern und hundert Mitarbeitern wäre das fehleranfällig und praktisch nicht mehr nachvollziehbar. Genau dieses Problem löst ein *Verzeichnisdienst*: Er speichert die Identitäten und Ressourcen einer Organisation an einer zentralen Stelle und stellt sie allen Systemen im Netzwerk zur Verfügung. *Active Directory Domain Services* (AD DS) ist der Verzeichnisdienst von Microsoft, der seit Windows 2000 Server zum Kern praktisch jeder Windows-Infrastruktur gehört.

AD DS erfüllt dabei drei Aufgaben gleichzeitig. Erstens ist es ein *Identitätsspeicher*: Benutzerkonten, Computerkonten und Gruppen liegen als Objekte in einer Datenbank. Zweitens ist es ein *Authentifizierungsdienst*: Wenn sich ein Benutzer an einem Computer anmeldet, prüft ein Domain Controller mit dem Protokoll Kerberos (und als Rückfallebene NTLM), ob Benutzername und Kennwort stimmen. Drittens ist es eine *Verwaltungsplattform*: Über Gruppenrichtlinien lassen sich Einstellungen für tausende Computer zentral festlegen, über Delegation lassen sich Verwaltungsaufgaben gezielt an Teams übertragen. Diese drei Funktionen greifen ineinander, und genau deshalb ist AD DS in den meisten Firmen so schwer wegzudenken.

Technisch beruht AD DS auf Standards. Die Objekte werden über das *Lightweight Directory Access Protocol* (LDAP) abgefragt, die Anmeldung läuft über Kerberos, und die Namensauflösung, mit der Clients ihre Domain Controller überhaupt finden, übernimmt das *Domain Name System* (DNS). Dieser Zusammenhang ist so wichtig, dass er sich als Faustregel merken lässt: Wenn Active Directory Probleme macht, ist sehr oft DNS die Ursache. Das vertiefen wir in Modul 5.

> **Merke**
>
> **AD DS** ist nur eine von mehreren Active-Directory-Rollen. Daneben gibt es unter anderem AD Certificate Services (Zertifikate), AD Federation Services (Föderation), AD Lightweight Directory Services (ein abgespeckter Verzeichnisdienst für Anwendungen) und AD Rights Management Services. Wenn in der Praxis von „dem Active Directory“ gesprochen wird, ist fast immer AD DS gemeint.

Bevor wir tiefer einsteigen, schauen wir uns eine laufende Umgebung an. Das folgende Skript lädt das PowerShell-Modul `ActiveDirectory` und gibt drei Übersichten aus: die Domain, den Forest und alle Domain Controller. Es ist ein guter erster Schritt in jeder unbekannten Umgebung, weil man mit drei Befehlen weiß, wie die Umgebung aufgebaut ist.

```powershell
# Modul laden (auf einem DC oder mit installierten RSAT-Tools vorhanden)
Import-Module ActiveDirectory

# Informationen zur eigenen Domain
Get-ADDomain |
    Select-Object Name, DNSRoot, NetBIOSName, DomainMode, PDCEmulator

# Informationen zum Forest
Get-ADForest |
    Select-Object Name, ForestMode, SchemaMaster, DomainNamingMaster

# Alle Domain Controller der Domain mit Standort und Rolle
Get-ADDomainController -Filter * |
    Select-Object Name, Site, IPv4Address, IsGlobalCatalog, OperatingSystem |
    Format-Table -AutoSize
```

Die erste Abfrage liefert den DNS-Namen der Domain (`DNSRoot`), den kurzen NetBIOS-Namen für die Anmeldung im Format `CORP\benutzer` und die Funktionsebene (`DomainMode`), die festlegt, welche Funktionen die Domain unterstützt. Die zweite Abfrage zeigt, auf welchen Servern die forestweiten Spezialrollen Schema Master und Domain Naming Master liegen, die wir in Modul 6 genauer besprechen. Die dritte Abfrage listet jeden Domain Controller mit seinem Standort (Site), seiner IP-Adresse und der Information, ob er ein Global Catalog ist. Die Ausgabe wird mit `Format-Table -AutoSize` lesbar gemacht. Wichtig: `Select-Object` reduziert die Ausgabe nur für die Anzeige; die Objekte selbst enthalten noch viel mehr Eigenschaften.

### Typische Fehler und Stolperfallen

Ein sehr häufiger Denkfehler ist die Gleichsetzung von lokalem Active Directory und *Microsoft Entra ID* (früher Azure Active Directory). Beide verwalten Identitäten, sind aber technisch völlig verschiedene Systeme: AD DS arbeitet mit Kerberos, LDAP und Gruppenrichtlinien auf Servern im eigenen Netz, Entra ID ist ein Cloud-Dienst, der mit Protokollen wie OpenID Connect, SAML und OAuth arbeitet und keine Domain Controller im herkömmlichen Sinn kennt. In Modul 12 betrachten wir, wie beide über Entra Connect gekoppelt werden. Ein zweiter Fehler: Benutzer für Dateifreigaben lokal auf jedem Server anzulegen, weil die Domain „noch nicht fertig“ sei. Dieses Vorgehen schafft Altlasten, die später mühsam bereinigt werden müssen.

```powershell
# FALSCH: lokales Konto auf dem Server, das niemand zentral verwaltet
New-LocalUser -Name "ftp_alt" -NoPassword

# RICHTIG: zentrales Konto in der Domain und Gruppe fuer die Berechtigung
New-ADUser -Name "Dateiserver Zugriff" -SamAccountName "svc-datei" `
    -AccountPassword (Read-Host -AsSecureString "Kennwort") -Enabled $true
```

Im Beispiel oben sieht man außerdem die typische Schreibweise des Backticks (`````) als Zeilenfortsetzung in PowerShell. Der Backtick muss das letzte Zeichen der Zeile sein, sonst bricht der Befehl mit einem Syntaxfehler ab. Für längere Parameterlisten ist *Splatting* (siehe Modul 2) die robustere Variante.

### Praxisbezug

> **Praxisbeispiel**
>
> Ein mittelständisches Unternehmen mit 250 Mitarbeitern betreibt zwei Domain Controller. Neue Mitarbeiter werden durch die Personalabteilung gemeldet, das IT-Team legt genau einmal das Konto an, ordnet es einer Abteilungsgruppe zu, und der Zugriff auf Dateiserver, Drucker, VPN und Anwendungen funktioniert sofort, weil alle Systeme das Verzeichnis befragen. Scheidet die Person aus, genügt es, das Konto zu deaktivieren, und sämtliche Zugänge sind gleichzeitig gesperrt. Dieses Zusammenspiel aus einem Konto, vielen Systemen ist der eigentliche Wert von AD DS.

## 1.2 Verzeichnisdienstprinzip

Ein Verzeichnisdienst ist eine spezialisierte Datenbank. Anders als eine klassische relationale Datenbank ist er für sehr viele Lesezugriffe und vergleichsweise wenige Änderungen optimiert. Das entspricht dem Alltag: Ein Benutzerkonto wird einmal angelegt, aber jeden Tag viele Male abgefragt, etwa bei jeder Anmeldung, jedem Dateizugriff und jeder Adressbuchsuche. Die Daten sind *hierarchisch* in einem Baum organisiert, wobei jeder Eintrag (Objekt) einen eindeutigen Platz im Baum hat. Die Struktur geht auf den Standard X.500 zurück, aus dem das schlankere LDAP hervorging.

Vier Prinzipien tragen jeden Verzeichnisdienst. Die *Hierarchie* erlaubt es, Objekte logisch zu gruppieren, etwa in Standorte und Abteilungen. Die *Suche* ermöglicht es, Objekte anhand von Eigenschaften zu finden, zum Beispiel alle Benutzer einer Abteilung. Die *Replikation* sorgt dafür, dass mehrere Server dieselben Daten halten, damit der Ausfall eines Servers den Dienst nicht stoppt. Die *Sicherheit* schließlich bedeutet, dass jedes Objekt eine Zugriffsliste (ACL) besitzt, die regelt, wer es lesen oder ändern darf. Active Directory setzt alle vier Prinzipien um, mit der Besonderheit, dass es *Multi-Master-Replikation* verwendet: Änderungen dürfen auf jedem Domain Controller erfolgen und werden danach zu allen anderen verteilt.

Jedes Objekt im Verzeichnis hat einen *Distinguished Name* (DN), also einen eindeutigen Pfad im Baum. Der DN `CN=Anna Muster,OU=Benutzer,DC=corp,DC=contoso,DC=com` wird von rechts nach links gelesen: Die Domain `corp.contoso.com` besteht aus den Domain-Komponenten (`DC`) `com`, `contoso` und `corp`, darin liegt die Organisationseinheit (`OU`) `Benutzer`, darin das Objekt mit dem Common Name (`CN`) `Anna Muster`. Der letzte Teil links, hier `CN=Anna Muster`, heißt *Relative Distinguished Name* (RDN) und muss nur innerhalb seines Containers eindeutig sein. Deshalb dürfen zwei Objekte mit dem Namen „Anna Muster“ in zwei verschiedenen OUs existieren, aber nicht in derselben.

Wer Verzeichnisse durchsucht, schreibt LDAP-Filter. Sie sind in Präfixnotation geschrieben: Der Operator steht vor den Bedingungen und alles steht in Klammern. `(&(objectClass=user)(department=Vertrieb))` bedeutet „UND, Objektklasse ist user, Abteilung ist Vertrieb“. Daneben gibt es `|` für ODER und `!` für NICHT. Das folgende Beispiel zeigt drei Abfragen mit steigender Komplexität und führt vor, wie man in PowerShell einen Filter an das Verzeichnis übergibt. Der Parameter `-LDAPFilter` reicht den Filter unverändert an den Server weiter, was oft schneller und für Kenner leichter zu lesen ist als der PowerShell-eigene `-Filter`.

```powershell
Import-Module ActiveDirectory

# 1) Ein Benutzer anhand des Anmeldenamens
Get-ADObject -LDAPFilter "(&(objectClass=user)(sAMAccountName=amuster))" `
    -Properties distinguishedName, whenCreated

# 2) Alle aktivierten Benutzer mit gesetzter Abteilung
#    (Bit-Filter 1.2.840.113556.1.4.803 prueft das Flag ACCOUNTDISABLE = 2)
Get-ADUser -LDAPFilter "(&(objectCategory=person)(department=*)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" `
    -Properties department | Select-Object Name, department

# 3) Suche nur in einem Teilbaum, nicht in der ganzen Domain
Get-ADUser -SearchBase "OU=Benutzer,DC=corp,DC=contoso,DC=com" `
    -SearchScope OneLevel -Filter * | Select-Object Name
```

Die erste Abfrage nutzt den allgemeinen Befehl `Get-ADObject`, der jede Objektart findet; die Eigenschaften müssen mit `-Properties` ausdrücklich angefordert werden, weil nicht alle Attribute standardmäßig geladen werden. Die zweite Abfrage verwendet einen sogenannten Bit-Filter: Das Attribut `userAccountControl` speichert mehrere Einstellungen als Bits in einer Zahl, und die lange Zahlenfolge `1.2.840.113556.1.4.803` ist die Kennung der Regel „bitweises UND“. Mit dem vorangestellten `!` werden alle Konten ausgewählt, bei denen das Bit für „deaktiviert“ nicht gesetzt ist. Die dritte Abfrage zeigt `-SearchBase` und `-SearchScope`: `OneLevel` sucht nur direkt in der angegebenen OU, `Subtree` (Standard) durchsucht auch alle untergeordneten OUs.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu Windows Server 2025 beschreibt, dass die Active-Directory-Datenbank (ESE) seit Windows 2000 mit einer Seitengröße von 8 KB arbeitet und dass diese Architektur Grenzen im gesamten Verzeichnis nach sich zieht, etwa bei der maximalen Größe eines einzelnen Objekts. Eine optionale 32-KB-Seitengröße hebt viele dieser Grenzen an (mehrwertige Attribute können dann etwa 3 200 Werte aufnehmen). Das wird in Lerneinheit 1.9 (Domain Controller) vertieft.

### Typische Fehler und Stolperfallen

Der häufigste Fehler bei LDAP-Filtern sind vergessene Klammern oder ein falsch gesetzter Operator. Der Filter `objectClass=user` ohne umgebende Klammern ist für `-LDAPFilter` ungültig, während der PowerShell-Parameter `-Filter` eine andere Syntax erwartet. Wer beide Syntaxen vermischt, bekommt entweder Fehlermeldungen oder leere Ergebnisse. Ein zweiter Klassiker: Eine Suche mit `-Filter *` über die gesamte Domain in einem großen Verzeichnis dauert lange und belastet den Domain Controller; wer genau weiß, wo gesucht werden muss, sollte immer `-SearchBase` setzen.

```powershell
# FALSCH: LDAP-Syntax im PowerShell-Filter und umgekehrt
Get-ADUser -Filter "(department=Vertrieb)"
Get-ADUser -LDAPFilter "department -eq 'Vertrieb'"

# RICHTIG: jeder Parameter mit seiner eigenen Syntax
Get-ADUser -Filter "department -eq 'Vertrieb'"
Get-ADUser -LDAPFilter "(department=Vertrieb)"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Webanwendung soll ihre Benutzer gegen Active Directory authentifizieren. Der Entwickler braucht dafür einen LDAP-Suchfilter, mit dem die Anwendung den Benutzer anhand des eingegebenen Anmeldenamens findet: `(&(objectClass=user)(sAMAccountName=%u))`. Weil der Administrator das Prinzip der Filtersyntax versteht, kann er den Filter prüfen, ein eigenes Dienstkonto mit minimalen Leserechten einrichten und im Test mit `Get-ADObject -LDAPFilter` nachvollziehen, welche Treffer die Anwendung bekommt.

## 1.3 Objekte und Attribute

Alles, was Active Directory speichert, ist ein *Objekt*. Ein Benutzer ist ein Objekt, ein Computer ist ein Objekt, eine Gruppe, eine OU, ein Drucker, eine Gruppenrichtlinie und sogar die Einstellungen des Verzeichnisses selbst. Jedes Objekt gehört zu einer *Objektklasse*, die festlegt, welche Eigenschaften es haben kann. Die Eigenschaften heißen *Attribute*. Ein Benutzerobjekt hat zum Beispiel die Attribute `givenName` (Vorname), `sn` (Nachname), `mail`, `department` und viele weitere, ein Computerobjekt dagegen `dNSHostName` oder `operatingSystem`.

Manche Attribute sind Pflicht (*mandatory*), andere optional (*optional*). Manche speichern genau einen Wert (*single-valued*), andere mehrere (*multi-valued*); das Attribut `proxyAddresses` eines Postfachbenutzers enthält beispielsweise mehrere E-Mail-Adressen. Einige Attribute werden nicht gespeichert, sondern bei Bedarf berechnet (*constructed attributes*), zum Beispiel `canonicalName` oder `memberOf`, das aus den Mitgliedslisten der Gruppen abgeleitet wird. Bei Gruppen sind `member` (Vorwärts-Link) und `memberOf` (Rückwärts-Link) ein Paar *verknüpfter Attribute*: Fügt man einen Benutzer zu einer Gruppe hinzu, wird nur `member` geändert, und `memberOf` am Benutzer ergibt sich daraus.

Für die Praxis ist die Unterscheidung der *Bezeichner* eines Objekts besonders wichtig, denn sie verwechseln viele Einsteiger. Der `sAMAccountName` ist der kurze Anmeldename (maximal 20 Zeichen für Benutzer) im alten Format `CORP\amuster`. Der `userPrincipalName` (UPN) hat das E-Mail-ähnliche Format `amuster@corp.contoso.com`. Der *Distinguished Name* ändert sich, sobald das Objekt umbenannt oder verschoben wird. Der *Security Identifier* (SID) ist die technische Kennung, mit der Windows Berechtigungen vergibt; er bleibt innerhalb der Domain stabil. Die `objectGUID` ist eine weltweit eindeutige Kennung, die sich nie ändert, auch nicht bei Umbenennung oder Verschiebung. Wer ein Objekt dauerhaft referenzieren will, etwa in einer Synchronisation oder Datenbank, nimmt deshalb die `objectGUID` oder die SID, niemals den DN.

Das folgende Beispiel legt eine OU und ein Benutzerkonto an, liest anschließend gezielt einzelne Attribute aus und ändert ein Attribut. Es zeigt auch, warum man bei `Get-ADUser` die gewünschten Eigenschaften ausdrücklich nennt.

```powershell
Import-Module ActiveDirectory
$domain = (Get-ADDomain).DistinguishedName      # DC=corp,DC=contoso,DC=com

# OU anlegen (falls noch nicht vorhanden)
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Benutzer'" -SearchBase $domain)) {
    New-ADOrganizationalUnit -Name "Benutzer" -Path $domain
}

# Benutzer anlegen
$kennwort = Read-Host -AsSecureString "Startkennwort fuer amuster"
New-ADUser -Name "Anna Muster" -GivenName "Anna" -Surname "Muster" `
    -SamAccountName "amuster" -UserPrincipalName "amuster@corp.contoso.com" `
    -Department "Vertrieb" -Path "OU=Benutzer,$domain" `
    -AccountPassword $kennwort -Enabled $true

# Gezielt Eigenschaften lesen: Bezeichner im Vergleich
Get-ADUser -Identity amuster -Properties Department, ObjectGUID, SID, WhenCreated |
    Select-Object Name, SamAccountName, UserPrincipalName,
                  DistinguishedName, ObjectGUID, SID, Department

# Attribut aendern
Set-ADUser -Identity amuster -Title "Vertriebsassistenz" -OfficePhone "+43 1 5550100"
```

Die ersten Zeilen holen den DN der Domain und prüfen, ob die OU `Benutzer` bereits existiert, damit das Skript mehrfach ausgeführt werden kann, ohne zu scheitern. `New-ADUser` legt das Konto an; ohne `-Enabled $true` würde es deaktiviert entstehen, weil `New-ADUser` neue Konten standardmäßig deaktiviert anlegt. Das Kennwort wird nicht im Klartext im Skript abgelegt, sondern als `SecureString` abgefragt. Die Abfrage mit `Get-ADUser` zeigt nebeneinander alle Bezeichner des Objekts, sodass der Unterschied zwischen Anmeldename, UPN, DN, GUID und SID sichtbar wird. `Set-ADUser` ändert Attribute des Objekts, wobei die bekannten Attribute über sprechende Parameter wie `-Title` und `-OfficePhone` erreichbar sind; für alle anderen gibt es `-Replace @{attribut=wert}`.

### Typische Fehler und Stolperfallen

Der erste Stolperstein ist `-Properties *`. Der Befehl lädt alle Attribute, was bei einem einzelnen Objekt zur Analyse praktisch ist, in einem Skript über tausende Konten aber unnötig Last erzeugt. Der zweite Stolperstein betrifft die Referenz auf Objekte: Wer in einer Datenbank den DN speichert, hat nach der nächsten Umorganisation tote Verweise. Der dritte betrifft Attribute mit mehreren Werten: `Set-ADUser -Replace` ersetzt den gesamten Inhalt, `-Add` hängt einen Wert an. Wer versehentlich `-Replace` statt `-Add` nutzt, löscht bestehende Werte.

```powershell
# FALSCH: DN als dauerhafter Schluessel und alle Attribute laden
Get-ADUser -Identity "CN=Anna Muster,OU=Benutzer,DC=corp,DC=contoso,DC=com" -Properties *

# RICHTIG: GUID als stabile Referenz und nur benoetigte Attribute
$guid = (Get-ADUser amuster).ObjectGUID
Get-ADUser -Identity $guid -Properties Department, Title

# Mehrwertiges Attribut: Wert hinzufuegen statt alles zu ersetzen
Set-ADUser amuster -Add @{ proxyAddresses = "smtp:anna.m@contoso.com" }
```

### Praxisbezug

> **Praxisbeispiel**
>
> Das Personalsystem liefert jede Nacht eine Liste aller Mitarbeiter mit Personalnummer. Ein Synchronisationsskript soll die Abteilung im Active Directory aktualisieren. Wenn es die Konten über die in einem Attribut wie `employeeID` abgelegte Personalnummer zuordnet statt über den Namen oder den DN, bleibt die Zuordnung auch nach Heirat, Namensänderung oder Verschiebung in eine andere OU korrekt.

## 1.4 Schema

Das *Schema* ist der Bauplan des Verzeichnisses. Es definiert, welche Objektklassen es gibt, welche Attribute es gibt und welche Attribute eine Klasse enthalten darf oder muss. Technisch besteht das Schema selbst aus Objekten im Verzeichnis: Jede Klasse ist ein Objekt der Klasse `classSchema`, jedes Attribut ein Objekt der Klasse `attributeSchema`. Das Schema ist in einer eigenen Verzeichnispartition abgelegt, dem *Schema Naming Context*, und wird auf alle Domain Controller des gesamten Forests repliziert. Es gibt pro Forest genau ein Schema.

Klassen sind durch *Vererbung* verbunden. Die Klasse `user` erbt von `organizationalPerson`, diese von `person`, und diese wiederum von `top`, der Wurzel aller Klassen. Dadurch bekommt ein Benutzer alle Attribute der Elternklassen automatisch. Man unterscheidet *strukturelle* Klassen (von denen echte Objekte angelegt werden können, etwa `user`), *abstrakte* Klassen (nur als Vorlage für die Vererbung) und *Hilfsklassen* (*auxiliary*), die sich nachträglich an bestehende Klassen anhängen lassen, um Attribute zu ergänzen.

Das Schema ist kein Ort für tägliche Experimente. Eine Schemaerweiterung wirkt forestweit, wird auf alle Domain Controller repliziert und kann nicht zurückgenommen werden. Neue Klassen und Attribute lassen sich lediglich deaktivieren (*defunct* setzen), aber nicht mehr löschen. Die Kennung (Object Identifier, OID) einer Klasse oder eines Attributs muss weltweit eindeutig sein und darf nicht erfunden oder wiederverwendet werden. Diese Vorgaben nennt auch die Microsoft-Dokumentation zu Schemaänderungen. Änderungen am Schema dürfen nur Mitglieder der Gruppe *Schema Admins* vornehmen, und sie werden auf dem Domain Controller mit der Rolle *Schema Master* ausgeführt. Typische Erweiterungen stammen von Software wie Exchange Server oder Configuration Manager, deren Installationsprogramme das Schema mitliefern.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft-Dokumentation sollte man das Schema nur erweitern, wenn keine vorhandene Objektklasse die Anforderungen erfüllt; vorzuziehen ist es, eine bestehende Klasse über eine Hilfsklasse zu ergänzen statt eine Unterklasse abzuleiten, weil Unterklassen die Oberflächenelemente der ursprünglichen Klasse (zum Beispiel die Eigenschaftenseiten eines Benutzers) nicht erben. Vor jeder Schemaerweiterung muss sichergestellt sein, dass alle Domain Controller des Forests online sind und die eingehende Replikation fehlerfrei läuft; Microsoft nennt dafür die Prüfung mit `repadmin /replsum`.

Das folgende Beispiel liest das Schema nur lesend. Es ermittelt die Vererbungskette der Klasse `user`, zeigt die Version des Schemas und listet für eine Klasse die direkt definierten Pflicht- und optionalen Attribute. Damit lernt man, wie man das Schema nachschlägt, ohne etwas zu verändern.

```powershell
Import-Module ActiveDirectory
$schemaNC = (Get-ADRootDSE).schemaNamingContext

# 1) Schema-Version (objectVersion) des Forests
Get-ADObject -Identity $schemaNC -Properties objectVersion |
    Select-Object DistinguishedName, objectVersion

# 2) Vererbungskette der Klasse "user" bis zur Wurzel
$klasse = "user"
while ($klasse) {
    $obj = Get-ADObject -SearchBase $schemaNC -LDAPFilter "(&(objectClass=classSchema)(lDAPDisplayName=$klasse))" `
        -Properties subClassOf, mustContain, mayContain
    Write-Output ("{0,-25} Pflicht: {1}, optional: {2}" -f $obj.Name,
        @($obj.mustContain).Count, @($obj.mayContain).Count)
    if ($obj.subClassOf -eq $klasse) { break }     # "top" verweist auf sich selbst
    $klasse = $obj.subClassOf
}

# 3) Wer darf das Schema aendern? (nur lesen)
Get-ADGroupMember -Identity "Schema Admins" | Select-Object Name, objectClass
```

Die erste Abfrage liest das Attribut `objectVersion` am Wurzelobjekt der Schemapartition; es ist eine Zahl, die jeder Windows-Server-Version zugeordnet ist und in der Microsoft-Dokumentation nachgeschlagen werden kann. Die Schleife in Schritt 2 beginnt bei der Klasse `user` und folgt dem Attribut `subClassOf` immer weiter zur Elternklasse, bis sie bei `top` ankommt, das auf sich selbst verweist. In jedem Schritt wird angezeigt, wie viele Pflicht- und optionale Attribute die Klasse selbst definiert. Der dritte Befehl listet die Mitglieder der Gruppe `Schema Admins`; diese Gruppe sollte im Normalbetrieb leer sein.

### Typische Fehler und Stolperfallen

Der größte Fehler im Umgang mit dem Schema ist Unvorsichtigkeit: eine Erweiterung „mal eben“ in der Produktivumgebung auszuführen, ohne Test und ohne Rückfallplan. Weil sich Änderungen nicht rückgängig machen lassen, bleibt im Fehlerfall nur die Wiederherstellung des gesamten Forests aus einer Sicherung. Ebenfalls riskant ist es, Mitglieder dauerhaft in `Schema Admins` zu belassen. Diese Gruppe sollte nur für die Dauer einer Erweiterung befüllt und danach wieder geleert werden.

```powershell
# FALSCH: Dauerhaft ein Konto in Schema Admins lassen
Add-ADGroupMember -Identity "Schema Admins" -Members "admin-max"

# RICHTIG: Nur fuer die Aenderung hinzufuegen, danach sofort entfernen
Add-ADGroupMember -Identity "Schema Admins" -Members "admin-max"
# ... Schemaerweiterung im Aenderungsfenster durchfuehren und pruefen ...
Remove-ADGroupMember -Identity "Schema Admins" -Members "admin-max" -Confirm:$false
```

### Praxisbezug

> **Praxisbeispiel**
>
> Vor der Einführung von Exchange Server oder Windows LAPS meldet die Installation, dass das Schema erweitert werden muss. Ein erfahrener Administrator prüft zuerst die Replikation mit `repadmin /replsum`, vergewissert sich über ein aktuelles System-State-Backup der Domain Controller, führt die Erweiterung zuerst in einer Testumgebung aus, dokumentiert die Schemaversion vor und nach der Änderung und leert danach die Gruppe Schema Admins wieder.

## 1.5 Forest

Ein *Forest* (Gesamtstruktur) ist die oberste Einheit in Active Directory. Er besteht aus einer oder mehreren Domains, die ein gemeinsames Schema, eine gemeinsame Konfiguration und einen gemeinsamen Global Catalog haben. Man kann sich einen Forest wie einen Wald aus Bäumen vorstellen: Jeder Baum ist ein Namensraum von Domains (`contoso.com` mit `corp.contoso.com` und `sales.contoso.com`), und mehrere Bäume mit unterschiedlichen Namensräumen (`contoso.com` und `fabrikam.com`) können im selben Forest vereint sein.

Der entscheidende Punkt, den viele Einsteiger falsch lernen: Die *Sicherheitsgrenze* von Active Directory ist der Forest, nicht die Domain. Innerhalb eines Forests gibt es automatisch transitive Vertrauensstellungen zwischen allen Domains, und die Gruppe *Enterprise Admins* hat Rechte in jeder Domain des Forests. Ein Administrator einer Kinderdomain kann unter bestimmten Umständen das gesamte Verzeichnis kompromittieren. Wer wirklich getrennte Sicherheitsbereiche braucht, etwa für eine Tochtergesellschaft mit eigener Verwaltung oder eine hochsicher abgeschottete Verwaltungsumgebung, plant daher einen eigenen Forest und verbindet diesen bei Bedarf über eine *Forest Trust* (Gesamtstrukturvertrauensstellung).

Die Faustregel für das Design lautet: so wenige Forests wie möglich, solange die Anforderungen an Isolation und Autonomie erfüllt sind. Mehr Forests bedeuten mehr Domain Controller, mehr Verwaltungsaufwand, mehr Vertrauensstellungen und mehr Komplexität. Typische Gründe für einen zusätzlichen Forest sind Firmenzukäufe, rechtliche Trennung von Verantwortlichkeiten, Testumgebungen und ein eigener Verwaltungs-Forest für privilegierte Konten. Das vertiefen wir in Modul 3 (Design) und Modul 9 (Sicherheit).

> **Ergänzung aus der Nachrecherche**
>
> Die *Funktionsebene* (Functional Level) legt fest, welche Domain-Controller-Versionen im Forest oder in der Domain zulässig sind und welche Funktionen zur Verfügung stehen. Laut Microsoft-Dokumentation gibt es mit Windows Server 2025 eine neue Funktionsebene, die für die optionale 32-KB-Datenbankseitengröße erforderlich ist; sie entspricht dem Wert 10 für `DomainLevel` und `ForestLevel` bei unbeaufsichtigten Installationen. Neue Forests müssen mindestens auf der Ebene Windows Server 2016 laufen, und die Ebene Windows Server 2012 R2 wird von Windows-Server-2025-Domain-Controllern nicht mehr unterstützt. Windows Server 2019 und 2022 verwenden weiterhin die Ebene Windows Server 2016 als höchste.

Das folgende Skript fragt die wichtigsten Eigenschaften eines Forests ab, listet die Domains, die globalen Katalogserver und bestehende Vertrauensstellungen. Es ist ein Werkzeug, um die Frage „Wie ist diese Umgebung aufgebaut?“ in einer Minute zu beantworten.

```powershell
Import-Module ActiveDirectory

$forest = Get-ADForest
"Forest-Name        : " + $forest.Name
"Funktionsebene     : " + $forest.ForestMode
"Domains            : " + ($forest.Domains -join ", ")
"Global Catalogs    : " + ($forest.GlobalCatalogs -join ", ")
"Schema Master      : " + $forest.SchemaMaster
"Domain Naming Master: " + $forest.DomainNamingMaster
"Sites              : " + ($forest.Sites -join ", ")

# Bestehende Vertrauensstellungen der aktuellen Domain
Get-ADTrust -Filter * |
    Select-Object Name, Direction, TrustType, ForestTransitive
```

Der Code nutzt die Eigenschaften des Objekts, das `Get-ADForest` zurückliefert, und fügt Mehrfachwerte mit `-join` zu einer lesbaren Zeile zusammen. In einer frischen Laborumgebung wird die Liste der Trusts leer sein; in gewachsenen Umgebungen zeigt sie, welche Verbindungen zu anderen Domains und Forests bestehen und ob sie eine Richtung haben (`Direction`) und forestweit transitiv sind (`ForestTransitive`).

### Typische Fehler und Stolperfallen

Der häufigste Designfehler ist die Annahme, mehrere Domains in einem Forest würden Administratoren sauber voneinander trennen. Das tun sie nicht, denn die Sicherheitsgrenze ist der Forest. Der zweite Fehler ist das Gegenstück: für jede Abteilung oder jeden Standort eine eigene Domain oder gar einen eigenen Forest aufzubauen, obwohl OUs und Sites dafür vorgesehen sind. Das führt zu überladenen Umgebungen, die mit wenig Personal kaum zu betreiben sind.

```powershell
# FALSCH (gedanklich): "Die Niederlassung bekommt eine eigene Domain, damit der
# lokale Admin nichts anderes sehen oder aendern kann."
# Der Admin der Kinderdomain bleibt innerhalb des Forests angreifbar/gefaehrlich.

# RICHTIG: Verwaltung per OU-Delegation, Isolation nur mit eigenem Forest.
# Beispiel: lokale Administratoren duerfen nur in "OU=Niederlassung" Benutzer zuruecksetzen.
# (Praktische Umsetzung der Delegation folgt in Modul 3 und 8.)
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Unternehmen übernimmt einen kleineren Wettbewerber, der ein eigenes Active Directory betreibt. Anstatt sofort alles zusammenzuführen, richtet das IT-Team zunächst eine Forest Trust ein, damit Mitarbeiter beider Firmen auf gemeinsame Ressourcen zugreifen können, und plant die Konsolidierung in einem späteren Projekt (Modul 12). Der separate Forest dient in der Übergangszeit auch als Sicherheitsgrenze.

## 1.6 Domain

Eine *Domain* ist die zentrale Verwaltungs- und Replikationseinheit innerhalb eines Forests. In ihr liegen die Benutzer-, Gruppen- und Computerobjekte, für die eine gemeinsame Kennwortrichtlinie, eine gemeinsame Kontosperrrichtlinie und eine gemeinsame Gruppe von Domain Controllern gilt. Jede Domain hat einen DNS-Namen wie `corp.contoso.com`, den ihre Mitglieder zur Namensauflösung nutzen, und einen NetBIOS-Namen wie `CORP`, der aus Kompatibilitätsgründen weiterhin existiert (für die Anmeldung im Format `CORP\benutzer`). Alle Domain Controller einer Domain halten eine vollständige, schreibbare Kopie der Domaindaten und gleichen Änderungen untereinander ab.

Für das Verständnis der Replikation ist die Aufteilung des Verzeichnisses in *Partitionen* (Naming Contexts) entscheidend. Jeder Domain Controller speichert mindestens drei Partitionen. Die *Domainpartition* enthält die Objekte der eigenen Domain und wird nur zwischen den Domain Controllern dieser Domain repliziert. Die *Konfigurationspartition* beschreibt die Struktur des Forests (Sites, Dienste, Partitionen) und wird an alle Domain Controller des Forests repliziert. Die *Schemapartition* enthält das Schema und wird ebenfalls forestweit repliziert. Dazu kommen optionale *Anwendungspartitionen*, beispielsweise für AD-integriertes DNS. Der Global Catalog (GC) hält zusätzlich eine teilweise, schreibgeschützte Kopie der Objekte aller anderen Domains, damit Suchen über den ganzen Forest hinweg möglich sind.

Die *Domänenfunktionsebene* bestimmt, welche Funktionen innerhalb der Domain verfügbar sind. Sie lässt sich nur anheben, nicht ohne Weiteres senken, und setzt voraus, dass alle Domain Controller der Domain eine passende Windows-Server-Version haben. Die Anhebung ist ein bewusster Schritt, der in der Praxis meist erst nach dem Ersetzen der letzten alten Domain Controller erfolgt. Wie bei Funktionsebenen üblich, sollte man sie nur dann anheben, wenn man die neuen Funktionen auch braucht und keinen Rückweg benötigt.

Das folgende Beispiel zeigt, wie man die Partitionen eines Domain Controllers sowie wichtige Domaineinstellungen auslesen kann. Es nutzt das RootDSE-Objekt, eine spezielle, immer vorhandene Auskunftsstelle jedes Domain Controllers, die sich ohne Authentifizierung abfragen lässt und beschreibt, was der Server anbietet.

```powershell
Import-Module ActiveDirectory

# RootDSE: Auskunft des Domain Controllers ueber sich selbst
$rootDse = Get-ADRootDSE
"Standard-Domainpartition  : " + $rootDse.defaultNamingContext
"Konfigurationspartition   : " + $rootDse.configurationNamingContext
"Schemapartition           : " + $rootDse.schemaNamingContext
"Alle Partitionen          :"
$rootDse.namingContexts | ForEach-Object { "   " + $_ }

# Domain-weite Einstellungen
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode,
    InfrastructureMaster, RIDMaster, PDCEmulator

# Die Standard-Kennwortrichtlinie der Domain
Get-ADDefaultDomainPasswordPolicy |
    Select-Object MinPasswordLength, PasswordHistoryCount,
                  MaxPasswordAge, LockoutThreshold
```

Die RootDSE-Ausgabe zeigt, dass ein einzelner Domain Controller nicht nur „die Domain“ kennt, sondern mehrere getrennte Datenbereiche, die unterschiedlich weit repliziert werden. Der Aufruf von `Get-ADDomain` zeigt außerdem, welche Domain Controller die domainweiten Spezialrollen RID Master, PDC Emulator und Infrastructure Master besitzen; sie sind Thema von Modul 6. Zum Schluss wird die domainweit geltende Standard-Kennwortrichtlinie angezeigt. Dass es pro Domain genau eine solche Standardrichtlinie gibt, ist ein klassischer Grund, mehrere Domains zu betreiben, und zugleich der Grund, warum es heute die *Fine-Grained Password Policies* gibt (Modul 8).

### Typische Fehler und Stolperfallen

Der erste Stolperstein ist die Namensgebung. Ein DNS-Name wie `contoso.local` war früher verbreitet, ist aber ein Problem, weil die Endung `.local` für Multicast-DNS (mDNS) reserviert ist und mit Zusatzkonfigurationen auf Clients kollidiert; öffentliche Zertifikate lassen sich dafür ebenfalls nicht ausstellen. Besser ist eine Subdomain eines Namens, den die Organisation tatsächlich besitzt, zum Beispiel `ad.contoso.com` oder `corp.contoso.com`. Der zweite Stolperstein: Eine Domain lässt sich später nur mit großem Aufwand umbenennen. Die Wahl des Namens muss daher zu Beginn sorgfältig erfolgen.

```powershell
# FALSCH: nicht routbarer, historisch gewachsener Name
# Install-ADDSForest -DomainName "contoso.local"

# RICHTIG: Subdomain eines eigenen, registrierten Namens
# Install-ADDSForest -DomainName "corp.contoso.com" -DomainNetbiosName "CORP"
# (Die Installation selbst behandeln wir ausfuehrlich in Modul 2.)
```

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Firma mit Hauptsitz und fünf Niederlassungen überlegt, für jede Niederlassung eine eigene Domain zu betreiben. Nach der Analyse stellt sich heraus, dass überall dieselbe Kennwortrichtlinie gelten soll und keine rechtliche Trennung nötig ist. Die Entscheidung fällt für genau eine Domain; die Niederlassungen werden als Sites für die Replikation und als OUs für die Delegation abgebildet. Der Betriebsaufwand sinkt erheblich, weil nur eine Domain gepflegt, gesichert und überwacht werden muss.

## 1.7 Organizational Units

Eine *Organisationseinheit* (OU) ist ein Container innerhalb einer Domain, der Objekte gliedert. Sie dient drei Zwecken: der Strukturierung (Ordnung im Verzeichnis), der *Delegation* (ein Team darf Objekte in genau dieser OU verwalten) und der *Gruppenrichtlinienverknüpfung* (eine Gruppenrichtlinie wird mit einer OU verknüpft und gilt für die darin enthaltenen Benutzer und Computer). Die OU ist das wichtigste Verwaltungswerkzeug im Alltag, weil sie flexibel ist: Objekte lassen sich beliebig zwischen OUs verschieben, ohne Sicherheitskennungen zu ändern.

Neben den OUs gibt es in jeder neuen Domain einige *Standard-Container*, darunter `Users` und `Computers`. Das sind keine OUs. Der entscheidende Unterschied: Auf einen Container lässt sich keine Gruppenrichtlinie verknüpfen und keine Delegation so fein einstellen wie auf eine OU. Neue Computerkonten landen standardmäßig im Container `Computers`, neue Benutzer im Container `Users`, und genau dort sollten sie nicht bleiben. Mit den Werkzeugen `redircmp` und `redirusr` lässt sich der Standardspeicherort für neu angelegte Computer- und Benutzerobjekte auf eine eigene OU umleiten.

Beim Entwurf der OU-Struktur sollte man sich nicht am Organigramm orientieren, sondern an den Fragen „Wer verwaltet diese Objekte?“ und „Welche Einstellungen gelten für sie?“. Abteilungen ändern sich häufig, Verwaltungs- und Richtlinienmodelle selten. Zu tiefe Verschachtelungen (mehr als etwa drei bis vier Ebenen) erschweren die Fehlersuche bei Gruppenrichtlinien und die Delegation. Das Thema vertiefen wir in Modul 3.

Ein häufig übersehenes Detail ist der Schutz vor versehentlichem Löschen. In den Eigenschaften einer OU gibt es die Option „Objekt vor zufälligem Löschen schützen“. Sie setzt eine ACL, die das Löschen ablehnt, solange sie aktiv ist. Das folgende Skript baut eine kleine, sinnvolle Grundstruktur auf, verschiebt ein Benutzerkonto in die passende OU und leitet den Standardspeicherort neuer Computer um.

```powershell
Import-Module ActiveDirectory
$root = (Get-ADDomain).DistinguishedName

# Oberste OU der Organisation, darunter getrennte OUs nach Objektart
New-ADOrganizationalUnit -Name "Contoso" -Path $root -ProtectedFromAccidentalDeletion $true
$basis = "OU=Contoso,$root"
foreach ($name in "Benutzer","Computer","Gruppen","Server","Dienstkonten") {
    New-ADOrganizationalUnit -Name $name -Path $basis -ProtectedFromAccidentalDeletion $true
}

# Benutzer verschieben (anhand der GUID, falls DN unbekannt)
$u = Get-ADUser -Identity amuster
Move-ADObject -Identity $u.ObjectGUID -TargetPath "OU=Benutzer,$basis"

# Neue Computerkonten sollen nicht mehr im Container "Computers" landen
# (nur auf einem DC mit Domain-Admin-Rechten ausfuehren)
redircmp "OU=Computer,$basis"
```

Zuerst wird die oberste OU `Contoso` angelegt und gleich gegen versehentliches Löschen geschützt. Anschließend erzeugt die Schleife fünf Unter-OUs, die nach Objektart getrennt sind; das ist ein robustes Grundmuster, weil Gruppenrichtlinien für Computer und für Benutzer ohnehin getrennt gelten. `Move-ADObject` verschiebt das Benutzerkonto, wobei die Referenz über die `ObjectGUID` verhindert, dass der Befehl am alten, inzwischen ungültigen DN scheitert. Schließlich wird mit `redircmp` der Standardspeicherort für neue Computerkonten auf die OU `Computer` umgeleitet. Das Skript lässt sich nicht beliebig oft wiederholen, weil die OUs beim zweiten Durchlauf schon existieren; in produktiven Skripten prüft man vorher mit `Get-ADOrganizationalUnit`, wie in Lerneinheit 1.3 gezeigt.

### Typische Fehler und Stolperfallen

Ein typischer Fehler ist die Fehlermeldung beim Löschen einer OU: „Zugriff verweigert“ oder „Der Vorgang ist für ein geschütztes Objekt nicht zulässig“. Sie bedeutet nicht, dass Rechte fehlen, sondern dass der Löschschutz aktiv ist. Wer die OU wirklich entfernen will, muss den Schutz erst aufheben. Der zweite Fehler ist das Anlegen einer OU-Struktur, die den Aufbau der Firma spiegelt („Geschäftsführung“, „Vertrieb“, „Einkauf“), obwohl die IT nach Objektart und Verwaltungsrolle arbeitet.

```powershell
# FALSCH: OU loeschen, ohne den Schutz aufzuheben (Fehler: Zugriff verweigert)
Remove-ADOrganizationalUnit -Identity "OU=Test,OU=Contoso,DC=corp,DC=contoso,DC=com" -Confirm:$false

# RICHTIG: erst den Schutz aufheben, dann loeschen (auch Unterobjekte)
$ou = "OU=Test,OU=Contoso,DC=corp,DC=contoso,DC=com"
Set-ADOrganizationalUnit -Identity $ou -ProtectedFromAccidentalDeletion $false
Remove-ADOrganizationalUnit -Identity $ou -Recursive -Confirm:$false
```

### Praxisbezug

> **Praxisbeispiel**
>
> Das Helpdesk-Team soll nur Kennwörter von Benutzern zurücksetzen, aber nichts anderes verändern dürfen. Mit der OU-Struktur lässt sich das sauber lösen: Die Gruppe `HELPDESK` erhält per Delegation das Recht „Kennwort zurücksetzen“ nur auf der OU `Benutzer`. Ohne diese Struktur müsste man dem Helpdesk entweder zu viele Rechte geben (etwa durch Mitgliedschaft in den Domänen-Admins) oder jede Änderung selbst durchführen.

## 1.8 Sites

Eine *Site* bildet die physische oder netzwerktechnische Struktur ab: Sie fasst ein oder mehrere gut miteinander verbundene IP-Subnetze zusammen, typischerweise einen Standort mit schnellem lokalem Netz. Domains und Sites sind voneinander unabhängig. Eine Domain kann sich über viele Sites erstrecken, und eine Site kann Domain Controller mehrerer Domains enthalten. Die Struktur der OUs sagt etwas über die Verwaltung, die Struktur der Sites etwas über das Netzwerk.

Sites erfüllen zwei Aufgaben. Erstens steuern sie die *Replikation*: Zwischen Domain Controllern innerhalb einer Site wird sehr schnell und ohne Komprimierung repliziert, zwischen Sites dagegen in festen Intervallen und komprimiert, damit WAN-Leitungen geschont werden. Zweitens steuern sie die *Client-Zuordnung*: Ein Client ermittelt anhand seiner IP-Adresse, zu welchem Subnetz und damit zu welcher Site er gehört, und bevorzugt dann einen Domain Controller derselben Site. Damit wird verhindert, dass sich ein Client in München über die WAN-Leitung an einem Domain Controller in Hamburg anmeldet, obwohl vor Ort ein Server steht.

Die Verbindung zwischen Sites heißt *Site Link*. Jeder Site Link hat Kosten, ein Replikationsintervall und einen Zeitplan. Der *Knowledge Consistency Checker* (KCC) erzeugt daraus automatisch die Replikationstopologie. Das Standardintervall liegt bei 180 Minuten. Details zu Site Links, Subnetzen, Bridgehead-Servern und Fehlersuche folgen in Modul 5.

Das Beispiel zeigt, wie man eine neue Site mit Subnetz und Site Link anlegt und den Client-Standort prüft. Dabei werden Cmdlets des Moduls `ActiveDirectory` verwendet, die Sites, Subnetze und Site Links als Objekte behandeln.

```powershell
Import-Module ActiveDirectory

# Neue Site fuer die Niederlassung Graz und das zugehoerige Subnetz
New-ADReplicationSite -Name "Graz"
New-ADReplicationSubnet -Name "10.20.0.0/24" -Site "Graz" -Location "Graz, Hauptstrasse 1"

# Site Link zwischen Standard-Site und Graz (Kosten 100, alle 60 Minuten)
New-ADReplicationSiteLink -Name "Wien-Graz" `
    -SitesIncluded "Default-First-Site-Name","Graz" `
    -Cost 100 -ReplicationFrequencyInMinutes 60

# Uebersicht aller Sites, Subnetze und Site Links
Get-ADReplicationSite -Filter * | Select-Object Name
Get-ADReplicationSubnet -Filter * | Select-Object Name, Site
Get-ADReplicationSiteLink -Filter * |
    Select-Object Name, Cost, ReplicationFrequencyInMinutes

# Auf einem Client: Zu welcher Site gehoert dieser Computer?
nltest /dsgetsite
```

Die ersten Befehle legen die Site `Graz` an und ordnen ihr das Subnetz `10.20.0.0/24` zu. Entscheidend ist die Subnetzzuordnung: Nur wenn das Subnetz des Clients bekannt ist, kann er einer Site zugeordnet werden. Der Site Link verbindet die Standardsite mit der neuen Site; Kosten und Intervall steuern, wie die Replikation zwischen beiden abläuft. Der Befehl `nltest /dsgetsite` zeigt auf einem Client die Site an, zu der er laut AD gehört. Er ist ein sehr nützliches Hilfsmittel, wenn sich Clients scheinbar an „falschen“ Domain Controllern anmelden.

### Typische Fehler und Stolperfallen

Der häufigste Fehler im Zusammenhang mit Sites sind *fehlende Subnetze*. Wenn ein neues Netz in Betrieb geht, aber das Subnetz nicht im Active Directory eingetragen wird, kann ein Client dort keiner Site zugeordnet werden. Er wählt dann einen beliebigen Domain Controller aus, oft über die WAN-Leitung, und die Anmeldung wird langsam. Auf den Domain Controllern findet sich dann in der Datei `netlogon.log` oder im Ereignisprotokoll der Hinweis „NO_CLIENT_SITE“.

```powershell
# FALSCH: Neues Netz in Betrieb nehmen, aber Subnetz nicht eintragen
# (Clients erscheinen in der Standard-Site oder ohne Zuordnung)

# RICHTIG: Subnetz vor der Inbetriebnahme anlegen und der Site zuordnen
New-ADReplicationSubnet -Name "10.30.5.0/24" -Site "Graz"

# Kontrolle: Alle Subnetze und ihre Sites
Get-ADReplicationSubnet -Filter * | Sort-Object Site | Format-Table Name, Site
```

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Filiale wird neu eröffnet. Das Netzwerkteam meldet das Subnetz, und die AD-Verantwortlichen legen vorab die Site und das Subnetz an, bevor der erste Rechner angeschlossen wird. Am Eröffnungstag melden sich die Mitarbeiter am lokalen Read-Only Domain Controller an, die Gruppenrichtlinien werden lokal bezogen und die WAN-Leitung bleibt frei für Geschäftsanwendungen. Hätte man die Site vergessen, würden sich Clients und Anwendungen unvorhersehbar am Hauptstandort authentifizieren.

## 1.9 Domain Controller

Ein *Domain Controller* (DC) ist ein Windows-Server, auf dem die Rolle AD DS installiert und konfiguriert ist. Er hält die Datenbank, beantwortet LDAP-Abfragen, stellt Kerberos-Tickets aus und repliziert Änderungen an seine Partner. Technisch laufen dafür mehrere Dienste: Der Dienst `NTDS` (Active Directory Domain Services) betreibt die Datenbank, `KDC` (Kerberos Key Distribution Center) stellt Tickets aus, `Netlogon` verwaltet die Anmeldekanäle und registriert den DC im DNS, `DNS` übernimmt die Namensauflösung, und `DFSR` repliziert den Ordner SYSVOL, der Gruppenrichtlinien und Anmeldeskripte enthält.

Die Verzeichnisdatenbank liegt standardmäßig unter `C:\Windows\NTDS` in der Datei `ntds.dit`, zusammen mit den Transaktionsprotokollen. Der Ordner SYSVOL liegt unter `C:\Windows\SYSVOL`. In Produktivumgebungen wird empfohlen, Datenbank und Protokolle auf dedizierte Laufwerke zu legen, was schon bei der Installation festgelegt werden kann (Modul 2). Entscheidend für die Verfügbarkeit ist: Jede Domain braucht *mindestens zwei* Domain Controller. Fällt der einzige DC aus, ist niemand mehr in der Lage, sich anzumelden, und die Wiederherstellung wird zur Notfallaktion.

Weil Active Directory mit Multi-Master-Replikation arbeitet, sind Domain Controller grundsätzlich gleichberechtigt. Einzelne Aufgaben, die sich nicht mehrfach verteilen lassen, liegen auf besonderen Domain Controllern (FSMO-Rollen, Modul 6). Außerdem kann ein DC zusätzlich die Funktion eines *Global Catalog* haben, der forestweite Suchen und die Auflösung universaler Gruppenmitgliedschaften bei der Anmeldung erlaubt. Ein *Read-Only Domain Controller* (RODC) ist eine schreibgeschützte Variante für Standorte mit geringer physischer Sicherheit (Modul 2).

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft-Dokumentation verwenden mit Windows Server 2025 neu installierte Forests und Domains ein 32-KB-Seitenformat der Datenbank, laufen aber standardmäßig in einem 8-KB-Simulationsmodus. Domain Controller, die per Feature-Update (In-Place-Upgrade) aktualisiert wurden, behalten ihr 8-KB-Format. Der Wechsel auf 32-KB-Seiten ist eine forestweite Operation, setzt Windows-Server-2025-Domain-Controller überall und die passende Funktionsebene voraus, lässt sich nicht rückgängig machen und macht ältere 8-KB-Sicherungen unbrauchbar, sofern nicht der gesamte Forest autoritativ wiederhergestellt wird. Backup-Software muss mit dem neuen Format getestet werden.

Das folgende Skript prüft die Gesundheit eines Domain Controllers auf einfache Weise: Es kontrolliert die Kerndienste, zeigt Größe und Ort der Datenbank und führt einen Diagnosetest aus. Für eine erste Einschätzung braucht man keine Zusatzwerkzeuge; `dcdiag` gehört zu jedem Domain Controller.

```powershell
# Kerndienste eines Domain Controllers pruefen
$dienste = "NTDS","Netlogon","KDC","DNS","DFSR","W32Time"
Get-Service -Name $dienste |
    Select-Object Name, Status, StartType | Format-Table -AutoSize

# Datenbank und Protokolle
$ntds = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters").'DSA Database file'
Get-Item $ntds | Select-Object FullName, @{n="GroesseMB";e={[math]::Round($_.Length/1MB,1)}}

# Rollen des Servers: Global Catalog? Standort?
Get-ADDomainController -Identity $env:COMPUTERNAME |
    Select-Object Name, Site, IsGlobalCatalog, IsReadOnly, OperatingSystem

# Kurzdiagnose: Konnektivitaet, Replikation, Dienste, DNS
dcdiag /test:Connectivity /test:Services /test:Replications /test:DNS /q
```

Der erste Block listet die sechs Dienste, die für einen funktionierenden DC wichtig sind; ist einer davon angehalten, gibt es meist sofort Probleme. Im zweiten Block liest das Skript aus der Registrierung den Speicherort der Datenbankdatei und zeigt deren Größe an, damit man ein Gefühl dafür bekommt, wie groß das Verzeichnis ist. Der dritte Block kombiniert AD-Informationen (Standort, Global Catalog, Read-Only-Status). Der vierte Block startet `dcdiag` mit einer Auswahl von Tests; der Schalter `/q` (quiet) unterdrückt erfolgreiche Tests, sodass nur Fehler erscheinen. Fehlt jede Ausgabe, ist das ein gutes Zeichen. Mehr zu `dcdiag`, `repadmin` und `nltest` folgt in Modul 11.

### Typische Fehler und Stolperfallen

Die klassischen Fehler im Betrieb von Domain Controllern sind seit Jahren dieselben. Erstens ein einziger Domain Controller in der Domain, oft aus Kostengründen. Zweitens zusätzliche Software wie Datei-, Druck- oder Datenbankdienste auf demselben Server; jede zusätzliche Rolle vergrößert die Angriffsfläche. Drittens das Zurücksetzen eines virtualisierten Domain Controllers über einen Snapshot: Die interne Versionszählung (USN) der Datenbank passt dann nicht mehr zu den Replikationspartnern, es kommt zu einem sogenannten USN Rollback und dauerhaft inkonsistenten Daten. Moderne Hypervisoren stellen die VM-Generation-ID bereit, mit der Windows Server eine solche Situation erkennt und sich schützt, doch sollte man sich nie auf Snapshots als Sicherung verlassen.

```powershell
# FALSCH: Einziger DC, kein Ersatz, Sicherung nur per VM-Snapshot
# (Ausfall bedeutet Totalverlust der Anmeldung; Snapshot-Restore gefaehrdet die Replikation)

# RICHTIG: Mindestens zwei DCs an getrennten Hosts, echte AD-faehige Sicherung
Get-ADDomainController -Filter * | Select-Object Name, Site     # sind es mindestens 2?
# Sicherung des System State (Beispiel, Ziel E: muss existieren):
wbadmin start systemstatebackup -backupTarget:E: -quiet
```

### Praxisbezug

> **Praxisbeispiel**
>
> Am Montagmorgen melden mehrere Benutzer, dass sich ihr Rechner nur langsam anmeldet. Der Administrator führt auf dem Hauptstandort-DC die Kurzdiagnose aus. `dcdiag` meldet, dass der Dienst `DFSR` nicht läuft und SYSVOL deshalb nicht repliziert wird; Gruppenrichtlinien werden nicht mehr geladen, was die Anmeldung verzögert. Nach dem Neustart des Dienstes ist das Problem behoben. Dieses Muster, nämlich ein Symptom beim Benutzer und eine Ursache im Dienstzustand des DC, begegnet einem in der Praxis sehr oft.

## 1.10 Übungsaufgaben zu Modul 01

Die Aufgaben steigen in der Schwierigkeit: Die ersten drei prüfen das Verständnis der Begriffe, die Aufgaben vier bis acht verlangen praktische Arbeit in einer Laborumgebung (zwei Domain Controller, eine Domain `corp.contoso.com`). Lösen Sie jede Aufgabe zuerst selbst, bevor Sie die Lösungen im nächsten Abschnitt lesen.

**Aufgabe 1.1** **Begriffe einordnen.** Erklären Sie in je ein bis zwei Sätzen den Unterschied zwischen Forest, Domain und Organisationseinheit. Nennen Sie für jede Einheit einen Grund, warum man sie einsetzt.

**Aufgabe 1.2** **Sicherheitsgrenze.** Ein Kollege behauptet: „Wir legen für die Tochterfirma eine eigene Domain im bestehenden Forest an, dann ist ihre Verwaltung vollständig vom Rest getrennt.“ Beurteilen Sie die Aussage und begründen Sie Ihre Antwort.

**Aufgabe 1.3** **Bezeichner.** Gegeben ist ein Benutzerobjekt mit dem DN `CN=Anna Muster,OU=Benutzer,DC=corp,DC=contoso,DC=com`. Nennen Sie fünf verschiedene Bezeichner eines Benutzerobjekts und geben Sie an, welcher sich bei einer Verschiebung der Anna Muster in die OU `Vertrieb` ändert und welche stabil bleiben.

**Aufgabe 1.4** **Umgebung erkunden.** Schreiben Sie ein PowerShell-Skript, das den Namen des Forests, die Funktionsebene, alle Domain Controller mit Site und Global-Catalog-Eigenschaft sowie den Inhaber der Rolle Schema Master ausgibt.

**Aufgabe 1.5** **LDAP-Filter.** Formulieren Sie einen LDAP-Filter, der alle *aktivierten* Benutzerkonten findet, deren Attribut `department` den Wert `Vertrieb` hat. Führen Sie ihn mit `Get-ADUser -LDAPFilter` aus und geben Sie Name und Anmeldename aus.

**Aufgabe 1.6** **OU-Struktur aufbauen.** Legen Sie unter der Domain eine OU `Contoso` mit den Unter-OUs `Benutzer`, `Computer`, `Gruppen` und `Server` an. Alle OUs sollen vor zufälligem Löschen geschützt sein. Das Skript soll mehrfach ausführbar sein, ohne Fehler zu erzeugen.

**Aufgabe 1.7** **Schema nachschlagen.** Ermitteln Sie per PowerShell die Vererbungskette der Klasse `computer` bis `top` und die Schemaversion (`objectVersion`). Verändern Sie dabei nichts.

**Aufgabe 1.8** **Standort einrichten.** Legen Sie die Site `Linz` mit dem Subnetz `10.40.0.0/24` an, verbinden Sie sie per Site Link `Wien-Linz` (Kosten 200, Replikation alle 120 Minuten) mit der Standardsite und prüfen Sie das Ergebnis mit den passenden `Get-`Cmdlets. Erklären Sie, was passiert, wenn das Subnetz vergessen wird.

## 1.11 Lösungen zu den Übungsaufgaben

**Lösung 1.1.** Ein *Forest* ist die oberste Einheit mit gemeinsamem Schema, gemeinsamer Konfiguration und Global Catalog; man setzt einen weiteren Forest ein, wenn echte Isolation oder getrennte Verantwortung nötig ist. Eine *Domain* ist eine Verwaltungs- und Replikationseinheit mit eigener Kennwortrichtlinie und eigenen Domain Controllern; man setzt mehrere Domains nur ein, wenn Replikations- oder Richtlinienanforderungen es verlangen. Eine *Organisationseinheit* ist ein Container innerhalb einer Domain für Strukturierung, Delegation und Gruppenrichtlinienverknüpfung; sie ist das normale Alltagswerkzeug.

**Lösung 1.2.** Die Aussage ist falsch. Die Sicherheitsgrenze in Active Directory ist der Forest, nicht die Domain. Innerhalb eines Forests bestehen automatisch transitive Vertrauensstellungen, und die Gruppe Enterprise Admins hat Rechte in allen Domains. Ein Administrator der Kinderdomain kann sich unter bestimmten Umständen Rechte im gesamten Forest verschaffen. Für echte Trennung braucht die Tochterfirma einen eigenen Forest (verbunden über eine Forest Trust). Für reine Delegation genügt eine OU mit passenden Rechten.

**Lösung 1.3.** Mögliche Bezeichner: Distinguished Name, `sAMAccountName`, `userPrincipalName`, `objectGUID` und SID. Bei der Verschiebung in eine andere OU ändert sich *nur der DN*. Der Anmeldename, der UPN, die GUID und die SID bleiben stabil. Deshalb gehört der DN nie als dauerhafter Schlüssel in eine Datenbank.

**Lösung 1.4.**

```powershell
Import-Module ActiveDirectory
$forest = Get-ADForest
"Forest            : " + $forest.Name
"Funktionsebene    : " + $forest.ForestMode
"Schema Master     : " + $forest.SchemaMaster
Get-ADDomainController -Filter * |
    Select-Object Name, Site, IsGlobalCatalog |
    Format-Table -AutoSize
```

Das Skript nutzt `Get-ADForest` für Forest-Eigenschaften und `Get-ADDomainController -Filter *`, um alle Domain Controller der Domain mit ihren Eigenschaften zu holen. `Select-Object` wählt die gewünschten Spalten aus.

**Lösung 1.5.**

```powershell
Get-ADUser -LDAPFilter "(&(objectCategory=person)(objectClass=user)(department=Vertrieb)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" |
    Select-Object Name, SamAccountName
```

Der Filter verknüpft mit `&` drei Bedingungen: Kategorie und Klasse stellen sicher, dass nur Benutzerkonten (keine Kontakte oder Computer) gefunden werden, `department=Vertrieb` wählt die Abteilung aus, und der negierte Bit-Filter auf `userAccountControl` schließt deaktivierte Konten aus (Bit 2 = `ACCOUNTDISABLE`). Alternativ funktioniert in PowerShell auch `-Filter "Enabled -eq $true -and Department -eq 'Vertrieb'"`.

**Lösung 1.6.**

```powershell
Import-Module ActiveDirectory
$root = (Get-ADDomain).DistinguishedName

function Neue-OU {
    param([string]$Name, [string]$Pfad)
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $Pfad -SearchScope OneLevel)) {
        New-ADOrganizationalUnit -Name $Name -Path $Pfad -ProtectedFromAccidentalDeletion $true
        Write-Output "OU angelegt: $Name in $Pfad"
    } else {
        Write-Output "OU vorhanden: $Name in $Pfad"
    }
}

Neue-OU -Name "Contoso" -Pfad $root
foreach ($n in "Benutzer","Computer","Gruppen","Server") {
    Neue-OU -Name $n -Pfad "OU=Contoso,$root"
}
```

Die Funktion prüft vor dem Anlegen, ob die OU im angegebenen Pfad auf der obersten Ebene bereits existiert (`-SearchScope OneLevel`). Damit kann das Skript beliebig oft laufen. Der Parameter `-ProtectedFromAccidentalDeletion $true` setzt den Löschschutz.

**Lösung 1.7.**

```powershell
Import-Module ActiveDirectory
$schemaNC = (Get-ADRootDSE).schemaNamingContext
(Get-ADObject -Identity $schemaNC -Properties objectVersion).objectVersion

$klasse = "computer"
while ($klasse) {
    $obj = Get-ADObject -SearchBase $schemaNC `
        -LDAPFilter "(&(objectClass=classSchema)(lDAPDisplayName=$klasse))" -Properties subClassOf
    $obj.Name
    if ($obj.subClassOf -eq $klasse) { break }
    $klasse = $obj.subClassOf
}
```

Die Schleife folgt dem Attribut `subClassOf`. Die Kette beginnt bei `computer` und endet bei `top`, das auf sich selbst verweist. Wichtig ist, dass alle Befehle nur lesen; es wird nichts am Schema verändert.

**Lösung 1.8.**

```powershell
New-ADReplicationSite -Name "Linz"
New-ADReplicationSubnet -Name "10.40.0.0/24" -Site "Linz"
New-ADReplicationSiteLink -Name "Wien-Linz" `
    -SitesIncluded "Default-First-Site-Name","Linz" `
    -Cost 200 -ReplicationFrequencyInMinutes 120

Get-ADReplicationSite -Filter * | Select-Object Name
Get-ADReplicationSubnet -Filter * | Select-Object Name, Site
Get-ADReplicationSiteLink -Filter * | Select-Object Name, Cost, ReplicationFrequencyInMinutes
```

Wird das Subnetz vergessen, kann ein Client im Netz `10.40.0.0/24` keiner Site zugeordnet werden. Er wählt dann einen beliebigen Domain Controller, was zu langsamen Anmeldungen über die WAN-Leitung führen kann. Die Folge ist im Ereignisprotokoll des Domain Controllers sichtbar (Hinweis auf einen Client ohne Site).
