# Modul 03 - Forest-, Domain- und OU-Design

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Tabellen als Markdown-Tabellen, Übungsaufgaben und Lösungen als Absätze). Die Überschriften sind wie in der Quelle nach Modul und Lerneinheit nummeriert (3.1 bis 3.9; 3.10 Übungsaufgaben, 3.11 Lösungen). **Die PowerShell-Beispiele wurden für dieses Repository nicht ausgeführt**; sie setzen eine Windows-Server-Laborumgebung mit der fiktiven Domain `corp.contoso.com` voraus und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain. Übersicht zum Modul: [README](README.md).

|                                       |              |
|:--------------------------------------|:-------------|
| Dauer laut Modulübersicht             | 12 Stunden   |
| Summe der Lerneinheiten (Detailblatt) | 10,5 Stunden |
| Priorität                             | 1            |

| Nr. | Lerneinheit            | Dauer (h) | Prio |
|----:|:-----------------------|----------:|-----:|
| 3.1 | Namespace Design       |         1 |    1 |
| 3.2 | Forest Design          |         1 |    1 |
| 3.3 | Domain Design          |       1,5 |    1 |
| 3.4 | OU Design              |         1 |    1 |
| 3.5 | Delegation             |         1 |    1 |
| 3.6 | Administrative Grenzen |       1,5 |    1 |
| 3.7 | Standortanforderungen  |         1 |    2 |
| 3.8 | Namenskonventionen     |         1 |    2 |
| 3.9 | Design Review          |       1,5 |    2 |
|     | **Summe**              |  **10,5** |      |

> **Merke**
>
> Die Stundensumme der Lerneinheiten im Detailblatt (10,5 h) weicht von der Dauer in der Modulübersicht (12 h) ab. Dieses Skript behandelt alle Lerneinheiten des Detailblatts vollständig; die Abweichung ist im Lehrplan selbst zu klären.

Design heißt in Active Directory: Entscheidungen treffen, die man später nur mit hohem Aufwand ändern kann. Der Domainname, die Zahl der Forests und Domains und die Struktur der Organisationseinheiten bestimmen, wie sicher, wie wartbar und wie delegierbar die Umgebung die nächsten zehn Jahre sein wird. Dieses Modul vermittelt keine Rezepte, sondern eine Denkweise: Man beginnt mit den *Anforderungen* (Sicherheit, Verwaltung, Standorte, Wachstum), leitet daraus die Struktur ab und prüft das Ergebnis in einem Review. Wo möglich, schreiben wir die Regeln als kleine PowerShell-Werkzeuge, damit sie nicht nur im Dokument stehen, sondern prüfbar sind.

Die Grundregel lautet: *so einfach wie möglich, so komplex wie nötig*. Für die allermeisten Organisationen bedeutet das ein Forest, eine Domain, eine flache, funktional gegliederte OU-Struktur und mehrere Sites. Abweichungen sind erlaubt, brauchen aber eine dokumentierte Begründung.

## 3.1 Namespace Design

Der *Namespace* (Namensraum) ist der DNS-Name, unter dem die Domains des Forests stehen. Er ist die sichtbarste Designentscheidung, denn er erscheint in jedem Benutzernamen (`anna@corp.contoso.com`), in jedem Computernamen (`PC01.corp.contoso.com`) und in jedem Zertifikat. Die Microsoft-Dokumentation empfiehlt, die Active-Directory-Umgebung zuerst zu entwerfen und die DNS-Struktur danach darauf auszurichten; existiert bereits ein DNS-Namensraum, wird die AD-Umgebung unabhängig entworfen und entweder als eigener Namensraum oder als Subdomain des bestehenden Namens umgesetzt.

Es gibt im Wesentlichen drei Modelle. Erstens kann man *denselben Namen intern und extern* verwenden (`contoso.com` für die Website und für AD). Das ist ohne Zusatzaufwand nicht ratsam: Man betreibt dann ein *Split-DNS*, in dem interne und externe Server dieselbe Zone mit unterschiedlichem Inhalt bedienen, und muss jeden öffentlichen Host (zum Beispiel `www`) auch intern pflegen. Zweitens kann man eine *Subdomain* des registrierten Namens verwenden (`corp.contoso.com` oder `ad.contoso.com`). Das ist die in der Praxis bewährte Lösung, weil interne und externe Namen klar getrennt sind, der Name aber der Organisation gehört. Drittens kann man einen *eigenen, getrennt registrierten Namen* verwenden (`contoso-intern.net`). Das ist ebenfalls sauber, schafft aber einen zweiten Namen, den man pflegen muss.

Dazu kommen Regeln, die die Dokumentation von Microsoft zusammenfasst: Man registriert die Namen, die im Internet erreichbar sind, bei einem Registrar, damit sie niemand anderes verwenden kann; man verwendet keine Namen bestehender Firmen oder Produkte; man vermeidet Akronyme, Namen von Geschäftsbereichen (sie ändern sich) und Unterstriche; man begrenzt die Tiefe der Hierarchie (Microsoft nennt höchstens fünf Ebenen unter der Wurzel als Richtwert); und man verwendet mindestens zwei Beschriftungen (*Labels*), also kein einzelnes Wort wie `contoso`. Einzelne-Label-Domains lassen sich nicht registrieren, verlangen Zusatzkonfiguration und führen zu Problemen bei der Auflösung und der dynamischen Registrierung von DNS-Einträgen. Die Endung `.local` sollte man vermeiden, weil sie für besondere Namensdienste im Netzwerk vorgesehen ist.

> **Ergänzung aus der Nachrecherche**
>
> Laut der Microsoft-Anleitung zur Domainnamen-Vergabe besteht jeder Domainname aus einem DNS-Namen und einem NetBIOS-Namen. Wenn das Präfix (erste Label) höchstens 15 Zeichen lang ist, entspricht der NetBIOS-Name dem Präfix; empfohlen wird, beide gleich zu halten. Das Präfix soll nur Internet-Standardzeichen enthalten (A–Z, a–z, 0–9 und den Bindestrich), nicht ausschließlich aus Ziffern bestehen und nicht veralten (also keine Produktlinien oder Betriebssysteme enthalten). Ein *disjunkter Namensraum* entsteht, wenn das primäre DNS-Suffix eines Computers nicht zum DNS-Namen seiner Domain passt; er führt zu schwer erkennbaren Fehlern bei der Registrierung von DNS-Einträgen und sollte vermieden werden.

Das folgende Skript ist ein kleines Werkzeug für die Namensentscheidung. Es prüft einen Namensvorschlag gegen die genannten Regeln und fragt zusätzlich einen öffentlichen Resolver, ob der Name im Internet bereits genutzt wird. Der Test auf eine öffentliche Registrierung ersetzt keine Prüfung beim Registrar, ist aber ein schneller Hinweis auf Namenskonflikte.

```powershell
function Test-AdDomainName {
    param([Parameter(Mandatory)][string]$Name)
    $meldungen = New-Object System.Collections.Generic.List[string]
    $labels = $Name.ToLower().Split(".")

    if ($labels.Count -lt 2)              { $meldungen.Add("Single-Label-Name: nicht registrierbar, Zusatzkonfiguration noetig") }
    if ($labels[-1] -eq "local")          { $meldungen.Add("Endung .local vermeiden") }
    if ($labels.Count -gt 5)              { $meldungen.Add("Mehr als 5 Ebenen: Hierarchie zu tief") }
    foreach ($l in $labels) {
        if ($l -notmatch '^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$') { $meldungen.Add("Label '$l' enthaelt unzulaessige Zeichen oder ist zu lang/kurz") }
        if ($l -match '^[0-9]+$')         { $meldungen.Add("Label '$l' besteht nur aus Ziffern") }
    }
    if ($labels[0].Length -gt 15)         { $meldungen.Add("Erstes Label hat >15 Zeichen: NetBIOS-Name muss separat gewaehlt werden") }

    # Wird die oberste registrierbare Domain (die letzten zwei Labels) bereits im Internet genutzt?
    if ($labels.Count -ge 2) {
        $basis = ($labels[-2..-1]) -join "."
        $oeffentlich = Resolve-DnsName -Name $basis -Server 1.1.1.1 -Type NS -ErrorAction SilentlyContinue
        if ($oeffentlich) { $meldungen.Add("Hinweis: '$basis' ist im Internet aufloesbar. Gehoert sie Ihrer Organisation?") }
    }
    [pscustomobject]@{ Name = $Name; Gueltig = ($meldungen.Count -eq 0); Meldungen = $meldungen }
}

Test-AdDomainName -Name "corp.contoso.com"
Test-AdDomainName -Name "contoso.local"
Test-AdDomainName -Name "firmenname"
Test-AdDomainName -Name "vertrieb_nord.beispiel.at"
```

Die Funktion zerlegt den Namen in seine Labels und prüft sie einzeln mit einem regulären Ausdruck: Ein Label darf nur Buchstaben, Ziffern und Bindestriche enthalten, nicht mit einem Bindestrich beginnen oder enden und höchstens 63 Zeichen lang sein. Die weiteren Zeilen setzen die Regeln „mindestens zwei Labels“, „nicht `.local`“, „höchstens fünf Ebenen“ und „erstes Label höchstens 15 Zeichen“ um. Der Aufruf von `Resolve-DnsName` fragt die letzten zwei Labels bei einem öffentlichen Resolver ab; eine Antwort bedeutet, dass der Name im Internet bereits existiert. Wichtig: Dieses Ergebnis ist ein *Hinweis*, kein Verbot. Die Subdomain `corp.contoso.com` ist legitim, wenn `contoso.com` der eigenen Organisation gehört. Am Ende erzeugt die Funktion ein Objekt, das sich weiterverarbeiten lässt.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die Wahl eines historisch gewachsenen Namens wie `firma.local` oder eines einzelnen Worts. Beides funktioniert anfangs, verursacht aber später Probleme bei Zertifikaten, bei der Cloud-Anbindung (damit Benutzer sich in Microsoft Entra ID mit ihrem UPN anmelden können, muss dessen Suffix ein dort überprüfbarer, also registrierter Domainname sein) und bei Zusammenschlüssen. Ein zweiter Fehler ist die Verwendung eines Namens, den die Organisation nicht besitzt. Wenn jemand diesen Namen später registriert, stehen interne und externe Welt im Konflikt.

```powershell
# FALSCH: historischer Name, kein registrierter Besitz, keine Cloud-Kompatibilitaet
Install-ADDSForest -DomainName "firma.local" -DomainNetbiosName "FIRMA"

# RICHTIG: Subdomain eines eigenen, registrierten Namens
Install-ADDSForest -DomainName "ad.firma.at" -DomainNetbiosName "FIRMA"
# UPN-Suffix fuer Cloud/E-Mail-Gleichheit nachtraeglich hinzufuegen:
Get-ADForest | Set-ADForest -UPNSuffixes @{ Add = "firma.at" }
```

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Gemeinde plant die Einführung von Microsoft 365. Ihre bestehende Domain heißt `gemeinde.local`. Weil sich E-Mail-Adressen und Anmeldenamen der Mitarbeiter unterscheiden sollen, richtet man ein zusätzliches UPN-Suffix `gemeinde.gv.at` ein und ändert die UPNs der Konten per Skript. Die interne Domain bleibt zunächst bestehen; ein Umzug auf einen registrierten Namen wird als Projekt für das nächste Hardware-Refresh vorgemerkt. Die Verbindung zwischen Domainname und UPN zu verstehen, ersparte hier eine Neuinstallation.

## 3.2 Forest Design

Die Frage „Wie viele Forests brauchen wir?“ lässt sich mit einer einfachen Regel beantworten: so wenige wie möglich. Jeder zusätzliche Forest bringt eigene Domain Controller, eigenes Schema, eigene Administratoren, eigene Sicherungen und eigene Vertrauensstellungen. Ein weiterer Forest ist nur dann gerechtfertigt, wenn eine Anforderung sich innerhalb eines Forests nicht erfüllen lässt. Das sind im Kern zwei Anforderungen: *Isolation* (Daten, Dienste oder Verwaltung müssen technisch getrennt sein, also eine echte Sicherheitsgrenze) und *Autonomie* (eine Gruppe braucht das Recht, Schema, Konfiguration oder Rollen selbstständig zu steuern).

Ein weiteres Argument für den Forest ist das *Schema*. Weil alle Domains im Forest dasselbe Schema nutzen, müssen sich alle auf Schemaerweiterungen (Exchange, Configuration Manager) einigen. Hat eine Einheit abweichende Anforderungen an das Schema, ist dies ein Grund für einen eigenen Forest. Weitere typische Gründe sind Firmenübernahmen (die übernommene Umgebung läuft zunächst separat), rechtliche Trennung von Gesellschaften, besonders schützenswerte Bereiche (zum Beispiel Forschung oder Zahlungsverkehr), Testumgebungen und ein dedizierter *Verwaltungs-Forest* für hochprivilegierte Konten (siehe Modul 9).

Mehrere Forests werden über *Vertrauensstellungen* (Trusts) verbunden. Eine *Forest Trust* verbindet zwei Forests transitiv, sodass Benutzer aus allen Domains beider Forests auf Ressourcen im anderen Forest zugreifen können, sofern sie dort berechtigt sind. Eine *External Trust* verbindet zwei einzelne Domains und ist nicht transitiv. Eine *Shortcut Trust* verkürzt die Vertrauenswege innerhalb eines Forests. Zwei Schutzmechanismen sind bei Trusts zu kennen: *SID-Filterung* verhindert, dass ein Konto aus dem vertrauten Forest über manipulierte SID-History-Einträge Rechte im vertrauenden Forest erlangt; die *selektive Authentifizierung* legt fest, dass Benutzer aus dem vertrauten Forest nur auf Server zugreifen dürfen, für die sie ausdrücklich das Recht „Authentifizieren“ bekommen haben.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu Berechtigungsmodellen beschreibt, dass die Gruppe *Enterprise Admins* nur in der Forest-Root-Domain existiert und standardmäßig Mitglied der Gruppe *Administrators* in allen Domains des Forests ist. Mitglied dort ist standardmäßig nur das eingebaute Administratorkonto der Root-Domain. Die Mitgliedschaft wird laut Microsoft in einem sauber entworfenen Delegationsmodell nur beim Aufbau des Forests oder für forestweite Änderungen benötigt (zum Beispiel das Hinzufügen oder Entfernen von Domains, das Einrichten von Forest Trusts oder das Anheben der Funktionsebene); die meisten Rechte der Gruppe lassen sich an weniger privilegierte Gruppen delegieren.

Das folgende Skript hilft bei der Bestandsaufnahme und Entscheidung. Der erste Teil listet alle Vertrauensstellungen mit den sicherheitsrelevanten Eigenschaften. Der zweite Teil ist eine kleine Entscheidungshilfe, die aus drei Fragen eine Empfehlung ableitet; sie ersetzt kein Gespräch mit den Beteiligten, macht die Kriterien aber explizit.

```powershell
Import-Module ActiveDirectory

# Teil 1: Bestandsaufnahme der Vertrauensstellungen
Get-ADTrust -Filter * |
    Select-Object Name, Direction, TrustType, ForestTransitive,
                  SelectiveAuthentication, SIDFilteringQuarantined |
    Format-Table -AutoSize

# Teil 2: Entscheidungshilfe "ein Forest oder mehrere?"
function Get-ForestEmpfehlung {
    param(
        [Parameter(Mandatory)][bool]$TechnischeIsolationNoetig,   # echte Sicherheitsgrenze gefordert?
        [Parameter(Mandatory)][bool]$EigenesSchemaNoetig,          # abweichende Schemaanforderungen?
        [Parameter(Mandatory)][bool]$RechtlichGetrennt             # eigene Rechtsperson/Haftung?
    )
    $gruende = @()
    if ($TechnischeIsolationNoetig) { $gruende += "Isolation: Sicherheitsgrenze ist der Forest" }
    if ($EigenesSchemaNoetig)       { $gruende += "Schema: Erweiterungen wirken forestweit" }
    if ($RechtlichGetrennt)         { $gruende += "Rechtliche Trennung: getrennte Verantwortung" }
    if ($gruende.Count -eq 0) {
        "Ein Forest genuegt. Abgrenzung per OU, Delegation und Gruppenrichtlinien."
    } else {
        "Zusaetzlicher Forest pruefen. Gruende:"
        $gruende | ForEach-Object { " - $_" }
    }
}

Get-ForestEmpfehlung -TechnischeIsolationNoetig $false -EigenesSchemaNoetig $false -RechtlichGetrennt $false
Get-ForestEmpfehlung -TechnischeIsolationNoetig $true  -EigenesSchemaNoetig $false -RechtlichGetrennt $true
```

Die Abfrage mit `Get-ADTrust` zeigt pro Vertrauensstellung die Richtung, die Art, ob sie forestweit transitiv ist und ob selektive Authentifizierung und SID-Filterung aktiv sind. In gewachsenen Umgebungen entdeckt man hier häufig alte Vertrauensstellungen, die niemand mehr braucht und die eine unnötige Angriffsfläche darstellen. Die Funktion `Get-ForestEmpfehlung` verlangt drei Ja/Nein-Angaben (`[bool]`) und gibt entweder die Empfehlung „ein Forest“ oder die Liste der Gründe für einen weiteren Forest aus. Der Wert der Funktion liegt in der Dokumentation: Wer ein Design begründen muss, hat die Kriterien schriftlich vorliegen.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die Annahme, eine zusätzliche Domain im selben Forest ersetze einen eigenen Forest. Sie tut es nicht (siehe Modul 1). Ein zweiter Fehler: Trusts anzulegen und *nie wieder zu überprüfen*. Alte Trusts bleiben bestehen, nachdem die Partnerfirma längst weg ist, und stellen ein Risiko dar. Ein dritter Fehler ist das Anlegen einer Vertrauensstellung ohne selektive Authentifizierung zwischen Umgebungen unterschiedlichen Schutzbedarfs.

```powershell
# FALSCH: Trusts nie pruefen
# (alte Partner-Forests koennen weiterhin Ressourcen erreichen)

# RICHTIG: regelmaessig inventarisieren und die Verbindung testen
Get-ADTrust -Filter * | ForEach-Object {
    $ok = $true
    try { Get-ADDomain -Identity $_.Target -ErrorAction Stop | Out-Null } catch { $ok = $false }
    "{0,-30} {1,-12} erreichbar: {2}" -f $_.Target, $_.Direction, $ok
}
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Konzern kauft drei kleinere Firmen. Jede hat ein eigenes Active Directory. Statt sofort zu konsolidieren, richtet das IT-Team Forest Trusts mit selektiver Authentifizierung ein: Nur ausgewählte Benutzer dürfen auf definierte Server zugreifen. In den folgenden zwei Jahren migriert es die Umgebungen schrittweise in den Hauptforest (Modul 12) und entfernt die Trusts am Ende. Die Trusts waren Mittel zum Zweck, nicht Dauerzustand.

## 3.3 Domain Design

Eine Domain ist eine Replikations- und Verwaltungseinheit, aber *keine* Sicherheitsgrenze. Früher gab es viele gute Gründe für mehrere Domains: Die Replikation einer großen Datenbank über schmale WAN-Leitungen, getrennte Kennwortrichtlinien für Administratoren und Benutzer, eine abgeschirmte Verwaltung von Standorten und Skalierungsgrenzen. Die meisten dieser Gründe sind entfallen: Die Replikation arbeitet heute effizient (nur geänderte Attribute werden übertragen), Kennwortrichtlinien lassen sich pro Gruppe mit *Fine-Grained Password Policies* steuern (Modul 8), Delegation läuft über OUs, und moderne Server verkraften Millionen von Objekten in einer Domain. Das *Ein-Domain-Modell* ist deshalb heute der Standard.

Gründe, die auch heute noch für mehrere Domains sprechen können, sind selten: eine sehr große Umgebung mit wirklich getrennten Replikationsanforderungen (zum Beispiel Standorte mit sehr schlechter Anbindung und sehr vielen Objekten), unterschiedliche Datenhoheit oder regulatorische Vorgaben, die eine Trennung der Datenhaltung verlangen, oder historische Gegebenheiten, die man nicht mehr umbauen will. Diese Gründe müssen konkret und belegbar sein. *Organisatorische* Gründe („die Abteilung möchte ihre eigene Domain“) sind kein ausreichender Grund, denn sie lassen sich mit OUs lösen.

Jede zusätzliche Domain verursacht Kosten: mindestens zwei weitere Domain Controller, eigene FSMO-Rollen, eigene Kennwortrichtlinie, zusätzliche Gruppenrichtlinien, Replikation der Global Catalogs und komplexere Anwendungsanbindung. Mehrere Domains führen außerdem zu mehr Fehlerquellen bei Gruppenverschachtelung und beim Zugriff über Domänengrenzen hinweg. Wer sie trotzdem braucht, legt eine *Child-Domain* (Subdomain im selben Namensraum, etwa `sales.corp.contoso.com`) oder eine neue *Domain Tree* (neuer Namensraum im selben Forest) an.

Das folgende Beispiel zeigt, wie eine Child-Domain erstellt wird, und gleichzeitig, wie man aus dem Bestand erkennt, ob eine Umgebung tatsächlich mehr als eine Domain braucht. Der zweite Teil ist eine Auswertung: Er zählt Objekte und Domain Controller pro Domain und gibt einen Anhaltspunkt für das Verhältnis von Aufwand und Nutzen.

```powershell
# Teil 1: Child-Domain anlegen (auf dem kuenftigen DC der neuen Domain, Rolle installiert)
$cred = Get-Credential "CORP\Administrator"       # Enterprise Admin noetig
$dsrm = Read-Host -AsSecureString "DSRM-Kennwort"
$p = @{
    NewDomainName                 = "sales"
    ParentDomainName              = "corp.contoso.com"
    NewDomainNetbiosName          = "SALES"
    DomainMode                    = "WinThreshold"
    InstallDns                    = $true
    Credential                    = $cred
    SafeModeAdministratorPassword = $dsrm
}
Test-ADDSDomainInstallation @p
Install-ADDSDomain @p -Force

# Teil 2: Auswertung, ob mehrere Domains ueberhaupt gerechtfertigt sind
Get-ADForest | Select-Object -ExpandProperty Domains | ForEach-Object {
    $dom = $_
    $benutzer  = (Get-ADUser     -Filter * -Server $dom).Count
    $computer  = (Get-ADComputer -Filter * -Server $dom).Count
    $dcs       = (Get-ADDomainController -Filter * -Server $dom).Count
    [pscustomobject]@{ Domain = $dom; Benutzer = $benutzer; Computer = $computer; DCs = $dcs }
} | Format-Table -AutoSize
```

Teil 1 nutzt dieselbe Technik wie bei der Forest-Installation, aber mit `Install-ADDSDomain`: Die Child-Domain bekommt den Namen `sales`, hängt unter `corp.contoso.com` und wird von einem Konto der Enterprise Admins angelegt. Teil 2 iteriert über alle Domains des Forests und zählt Benutzer, Computer und Domain Controller. Ergibt sich dabei, dass eine Domain weniger als einige tausend Konten hat und auf einem Standort liegt, ist die Frage berechtigt, wofür die separate Domain gebraucht wird. Bei kleinen Domains spricht meist alles für eine Konsolidierung.

### Typische Fehler und Stolperfallen

Der erste Fehler ist die *organisatorische Domain*, also pro Abteilung oder Standort eine eigene Domain, weil es „übersichtlicher“ sei. Das Ergebnis ist ein überladenes Verzeichnis mit hohem Betriebsaufwand und mit Risiken: In jeder Domain bleiben privilegierte Konten, und die Domänenadministratoren einer Child-Domain gefährden den Forest. Der zweite Fehler ist ein sogenannter *leerer Root* (Forest-Root-Domain ohne Benutzer, mit eigenen Domain Controllern und Kinderdomains darunter), der früher als Sicherheitsmaßnahme empfohlen wurde; heute ist er für die meisten Umgebungen unnötig und verursacht Kosten ohne Gewinn.

```powershell
# FALSCH: pro Abteilung eine Domain
# vertrieb.corp.contoso.com / einkauf.corp.contoso.com / it.corp.contoso.com

# RICHTIG: eine Domain, Abteilungen als OUs mit Delegation
New-ADOrganizationalUnit -Name "Vertrieb" -Path "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com"
New-ADOrganizationalUnit -Name "Einkauf"  -Path "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Eine Organisation betreibt seit 2003 einen leeren Root und drei Kinderdomains. Beim Update der Domain Controller stellt das Team fest, dass 14 Domain Controller auf Windows-Server-Ebene gewartet werden, obwohl insgesamt nur 600 Benutzer existieren. Im Rahmen eines Projekts konsolidiert es die Umgebung in eine Domain; es spart acht Domain Controller, mehrere Gruppenrichtlinien und vereinfacht die Berechtigungsstruktur. Bei der Umstellung hilft das Wissen aus Modul 12.

## 3.4 OU Design

Während Forest und Domain selten verändert werden, ist die OU-Struktur ein lebendiges Werkzeug. Ihr Entwurf folgt drei Fragen: *Wer verwaltet diese Objekte?* (Delegation), *welche Einstellungen gelten für sie?* (Gruppenrichtlinien) und *wie sieht ihr Lebenszyklus aus?* (Anlage, Änderung, Deaktivierung, Löschung). Eine gute OU-Struktur beantwortet diese Fragen mit wenigen, klar benannten Ebenen. Eine schlechte spiegelt das Organigramm wider und muss bei jeder Umstrukturierung angepasst werden.

Ein bewährtes Muster trennt zuerst nach *Objektart* und dann nach *Verwaltungsbereich*: Auf oberster Ebene eine OU für die Organisation (`Contoso`), darunter `Benutzer`, `Computer`, `Server`, `Gruppen`, `Dienstkonten` und `Admin`. Unter `Benutzer` und `Computer` folgen bei Bedarf die Standorte oder Abteilungen, wenn deren Verwaltung unterschiedlich ist. Der Hintergrund: Gruppenrichtlinien enthalten Benutzer- und Computerkonfiguration getrennt; wenn Benutzer und Computer in verschiedenen OUs liegen, kann man beide Teile gezielt verknüpfen und den jeweils unbenutzten Teil deaktivieren, was die Verarbeitung beschleunigt und die Fehlersuche vereinfacht.

Die Microsoft-Dokumentation zur Delegation über OUs empfiehlt, die standardmäßig vorhandenen Container und OUs (zum Beispiel `Users` und `Domain Controllers`) weiterhin von den Dienstadministratoren verwalten zu lassen. Wer Kontrolle über Objekte delegieren möchte, soll zusätzliche OUs anlegen, die Objekte dorthin verschieben und die Kontrolle an die zuständigen Datenadministratoren delegieren. So bleibt die Standardkonfiguration unverändert, und die Delegation ist leicht nachvollziehbar.

Als Richtwerte gelten: nicht mehr als drei bis vier Ebenen; keine Verschachtelung nur der Optik wegen; Namen ohne Sonderzeichen; ein Löschschutz auf allen OUs; und eine eigene OU für Objekte, die auf ihr Löschen warten oder deaktiviert sind (`Deaktiviert` oder `Quarantäne`). Das folgende Skript baut eine OU-Struktur datengetrieben auf. Die Struktur steht als verschachtelte Hashtable am Anfang; die Funktion erzeugt sie rekursiv und überspringt vorhandene OUs, sodass das Skript wiederholt ausgeführt werden kann.

```powershell
Import-Module ActiveDirectory
$root = (Get-ADDomain).DistinguishedName

# Sollstruktur als Baum: Name -> Unterstruktur
$struktur = [ordered]@{
    "Contoso" = [ordered]@{
        "Benutzer"     = [ordered]@{ "Wien" = @{}; "Graz" = @{}; "Extern" = @{} }
        "Computer"     = [ordered]@{ "Arbeitsplaetze" = @{}; "Notebooks" = @{} }
        "Server"       = [ordered]@{ "Dateiserver" = @{}; "Anwendungen" = @{} }
        "Gruppen"      = [ordered]@{ "Berechtigung" = @{}; "Verteiler" = @{} }
        "Dienstkonten" = @{}
        "Admin"        = [ordered]@{ "Konten" = @{}; "Gruppen" = @{} }
        "Deaktiviert"  = @{}
    }
}

function New-OuBaum {
    param([System.Collections.IDictionary]$Baum, [string]$Pfad)
    foreach ($name in $Baum.Keys) {
        $dn = "OU=$name,$Pfad"
        if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'" -ErrorAction SilentlyContinue)) {
            New-ADOrganizationalUnit -Name $name -Path $Pfad -ProtectedFromAccidentalDeletion $true
            Write-Output "angelegt : $dn"
        } else {
            Write-Output "vorhanden: $dn"
        }
        if ($Baum[$name].Count -gt 0) { New-OuBaum -Baum $Baum[$name] -Pfad $dn }
    }
}
New-OuBaum -Baum $struktur -Pfad $root

# Kontrolle: Struktur als Einrueckung anzeigen und Tiefe pruefen
Get-ADOrganizationalUnit -Filter * -SearchBase "OU=Contoso,$root" |
    Sort-Object DistinguishedName |
    ForEach-Object {
        $tiefe = ($_.DistinguishedName -replace ",$root$","").Split(",").Count
        ("  " * ($tiefe - 1)) + $_.Name + $(if ($tiefe -gt 4) { "   <-- zu tief" })
    }
```

Die Hashtable `$struktur` beschreibt die gewünschte Struktur wie ein Inhaltsverzeichnis. Die Funktion `New-OuBaum` legt jede OU an, prüft vorher über den Distinguished Name, ob sie schon existiert, und ruft sich für die Unterstruktur selbst wieder auf (Rekursion). Der Löschschutz wird mitgesetzt. Die Kontrollausgabe sortiert die OUs nach DN, berechnet aus dem DN die Tiefe (Anzahl der Komponenten unterhalb der Domain) und markiert Einträge, die tiefer als vier Ebenen liegen. Eine so beschriebene Struktur ist reproduzierbar: In einer Testumgebung kann man sie jederzeit identisch aufbauen.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die Nachbildung des Organigramms: `Geschäftsführung`, darunter `Abteilungen`, darunter `Teams`. Nach jeder Umstrukturierung sind die OUs falsch. Der zweite Fehler ist die Nutzung der Standardcontainer `Users` und `Computers` für den Alltag, denn auf Container lassen sich keine Gruppenrichtlinien verknüpfen. Der dritte Fehler ist, in einer OU *Benutzer, Computer und Gruppen gemischt* abzulegen; dann lassen sich Richtlinien nicht sauber trennen.

```powershell
# FALSCH: Objekte bleiben in den Standardcontainern
Get-ADUser     -Filter * -SearchBase "CN=Users,DC=corp,DC=contoso,DC=com"
Get-ADComputer -Filter * -SearchBase "CN=Computers,DC=corp,DC=contoso,DC=com"   # (hier sollte nichts liegen)

# RICHTIG: Neue Computer landen automatisch in der richtigen OU, vorhandene werden verschoben
redircmp "OU=Arbeitsplaetze,OU=Computer,OU=Contoso,DC=corp,DC=contoso,DC=com"
Get-ADComputer -Filter * -SearchBase "CN=Computers,DC=corp,DC=contoso,DC=com" |
    Move-ADObject -TargetPath "OU=Arbeitsplaetze,OU=Computer,OU=Contoso,DC=corp,DC=contoso,DC=com"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Für eine neue Softwareverteilung per Gruppenrichtlinie soll ein Programm nur auf Arbeitsplatzrechnern installiert werden, nicht auf Servern und nicht auf Notebooks. In der sauberen Struktur verknüpft der Administrator die Richtlinie mit der OU `Arbeitsplaetze`; Server und Notebooks sind nicht betroffen. Hätte die OU-Struktur das Organigramm nachgebildet, müsste er Ausnahmen über Sicherheitsfilter oder WMI-Filter pflegen.

## 3.5 Delegation

*Delegation* bedeutet, einzelne Verwaltungsaufgaben gezielt an Personen oder Teams zu übertragen, ohne ihnen alle Rechte zu geben. Es ist die praktische Umsetzung des *Least-Privilege-Prinzips*: Jede Rolle erhält genau die Rechte, die sie für ihre Aufgabe braucht, und nur dort, wo sie sie braucht. Die Microsoft-Dokumentation begründet das mit dem Schutz vor versehentlichen oder böswilligen Schäden: Je weniger Konten Mitglied der hochprivilegierten Gruppen sind, desto kleiner ist die Angriffsfläche.

Das Verfahren folgt immer demselben Muster: Man legt eine *Rolle* als Sicherheitsgruppe an (zum Beispiel `ROL-Helpdesk`), nimmt die zuständigen Personen in die Gruppe auf, legt die betroffenen Objekte in eine OU und überträgt der Gruppe *auf dieser OU* die benötigten Berechtigungen. Das Ergebnis lässt sich vererbbar gestalten, sodass es auch für Unter-OUs gilt. Der Assistent „Zuweisen von Aufgaben“ (Delegation of Control Wizard) bietet für häufige Aufgaben vorbereitete Rechte an. Laut Microsoft-Dokumentation sind das unter anderem: Benutzerkonten erstellen, löschen und verwalten, Kennwörter zurücksetzen und die Änderung beim nächsten Anmelden erzwingen, alle Benutzerinformationen lesen, die Mitgliedschaft einer Gruppe ändern, einen Computer in eine Domain aufnehmen, Gruppenrichtlinienverknüpfungen verwalten und Resultant Set of Policy (Planung oder Protokollierung) erzeugen.

Im Hintergrund schreibt die Delegation Einträge in die *Zugriffssteuerungsliste* (ACL) der OU. Das lässt sich auch ohne Assistenten skripten, mit dem Befehl `dsacls` oder mit PowerShell. Das folgende Beispiel delegiert der Gruppe `ROL-Helpdesk` das Zurücksetzen von Kennwörtern, das Entsperren von Konten und das Ändern der Anzeigeeigenschaften für Benutzer in genau einer OU. Anschließend wird die ACL ausgelesen, um das Ergebnis zu überprüfen.

```powershell
Import-Module ActiveDirectory
$ou    = "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com"
$rolle = "ROL-Helpdesk"

# Rolle als Sicherheitsgruppe anlegen (falls noch nicht vorhanden)
if (-not (Get-ADGroup -Filter "Name -eq '$rolle'")) {
    New-ADGroup -Name $rolle -GroupScope Global -GroupCategory Security `
        -Path "OU=Berechtigung,OU=Gruppen,OU=Contoso,DC=corp,DC=contoso,DC=com" `
        -Description "Delegation: Kennwort zuruecksetzen und Konten entsperren in OU Benutzer"
}

# Delegation: nur Benutzerobjekte (Klasse user), vererbt auf Unterobjekte (/I:S)
dsacls $ou /I:S /G "CORP\${rolle}:CA;Reset Password;user"        # Kennwort zuruecksetzen
dsacls $ou /I:S /G "CORP\${rolle}:RPWP;lockoutTime;user"         # Konto entsperren
dsacls $ou /I:S /G "CORP\${rolle}:RPWP;pwdLastSet;user"          # "Kennwort bei naechster Anmeldung aendern"
dsacls $ou /I:S /G "CORP\${rolle}:RPWP;telephoneNumber;user"     # Beispiel fuer ein Attribut

# Kontrolle: Welche expliziten (nicht geerbten) Eintraege hat die OU?
(Get-Acl -Path "AD:\$ou").Access |
    Where-Object { -not $_.IsInherited } |
    Select-Object IdentityReference, AccessControlType, ActiveDirectoryRights, InheritanceType |
    Format-Table -AutoSize -Wrap
```

Das Skript legt zunächst die Rollengruppe an. Der Befehl `dsacls` trägt dann gezielt Rechte ein: `CA` steht für „Control Access“ (ein erweitertes Recht wie „Reset Password“), `RPWP` für „Read Property, Write Property“ (lesen und schreiben eines Attributs), der letzte Teil `user` beschränkt das Recht auf Objekte der Klasse Benutzer. Mit `/I:S` gilt der Eintrag für die Unterobjekte (und nicht für die OU selbst). Zum Schluss liest `Get-Acl` über den Provider `AD:` die ACL der OU und zeigt nur die nicht geerbten Einträge, damit man die gerade gesetzten Rechte sofort sieht. Wichtig: Die Delegation wirkt auf einer *OU*; die Objekte müssen also dort liegen.

### Typische Fehler und Stolperfallen

Der erste Fehler ist die Delegation an *einzelne Personen* statt an Rollengruppen. Beim Personalwechsel muss man dann die ACL bereinigen; mit Gruppen genügt eine Mitgliedschaftsänderung. Der zweite Fehler ist die Vergabe zu weitreichender Rechte („Vollzugriff“, englisch `GenericAll`) auf der Domain-Wurzel, weil es „einfacher“ ist; dadurch wird aus der Delegation ein Sicherheitsrisiko. Der dritte Fehler ist das Rätselraten, wenn die Delegation bei Administratorkonten nicht wirkt: Mitglieder geschützter Gruppen (zum Beispiel Domain Admins) und die Gruppen selbst werden von einem Hintergrundprozess regelmäßig auf die Sicherheitsbeschreibung des Objekts `AdminSDHolder` zurückgesetzt, wie die Microsoft-Dokumentation zu den Standardgruppen beschreibt. Rechte, die man auf einer OU für diese Konten setzt, werden dort überschrieben.

```powershell
# FALSCH: Delegation an eine Person, mit zu breitem Recht auf der ganzen Domain
dsacls "DC=corp,DC=contoso,DC=com" /G "CORP\max.muster:GA"

# RICHTIG: Rolle, begrenztes Recht, begrenzter Ort
dsacls "OU=Benutzer,OU=Contoso,DC=corp,DC=contoso,DC=com" /I:S /G "CORP\ROL-Helpdesk:CA;Reset Password;user"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Das Helpdesk eines Unternehmens soll Kennwörter zurücksetzen, aber keine Gruppen ändern und keine Konten löschen. Der Administrator legt die Rolle `ROL-Helpdesk` an, delegiert auf der OU `Benutzer` nur „Reset Password“ und „lockoutTime“ und dokumentiert die Delegation in einer Tabelle (Rolle, Ort, Recht, Verantwortlicher). Bei der halbjährlichen Überprüfung wird die ACL per Skript ausgelesen und mit der Tabelle verglichen; Abweichungen werden untersucht.

## 3.6 Administrative Grenzen

Eine *administrative Grenze* ist eine Linie, an der Verwaltungsrechte, Sicherheitsannahmen oder Replikationsflüsse enden. Wer ein Active Directory entwirft, muss wissen, welche Grenze welche Aufgabe erfüllt, denn die häufigsten Entwurfsfehler entstehen durch Verwechslung. Es gibt fünf Ebenen. Die *Forest-Grenze* ist die einzige echte *Sicherheitsgrenze*: Sie trennt Schema, Konfiguration, Global Catalog und die Reichweite der Enterprise Admins. Die *Domain-Grenze* ist eine *Richtlinien- und Replikationsgrenze*: Sie legt Kennwortrichtlinie, Kontosperrung, Domain-Admins und die Replikation der Domainpartition fest, schützt aber nicht vor einem böswilligen Domänenadministrator. Die *OU-Grenze* ist eine *Delegationsgrenze*: Rechte lassen sich auf einen Teilbaum beschränken. Die *Site-Grenze* ist eine *Netzwerk- und Replikationsgrenze*: Sie steuert, welcher Domain Controller für welchen Client zuständig ist. Die *GPO-Grenze* schließlich bestimmt, für welche Objekte welche Einstellungen gelten (Verknüpfung, Sicherheitsfilter, WMI-Filter).

Eine zweite Unterscheidung ist die zwischen *Dienstadministratoren* und *Datenadministratoren*. Dienstadministratoren verwalten die Infrastruktur von Active Directory (Domain Controller, Schema, Replikation, DNS); ihre Gruppen sind Enterprise Admins, Domain Admins und Administratoren. Datenadministratoren verwalten Objekte innerhalb des Verzeichnisses (Benutzer, Gruppen, Computer) in einem abgegrenzten Teilbaum. Die Trennung beider Rollen ist die wichtigste Maßnahme zur Reduktion von Risiken, weil nur wenige Personen Dienstadministratorrechte brauchen. Die Microsoft-Dokumentation weist darauf hin, dass die drei höchstprivilegierten Gruppen (Enterprise Admins, Domain Admins, Administrators) in der Praxis als *gleich mächtig* betrachtet werden sollten, denn ein Mitglied einer dieser Gruppen kann sich selbst in die anderen aufnehmen; häufig enthält gerade die Gruppe Administrators mehr Mitglieder als die beiden anderen zusammen.

Ein dritter Gesichtspunkt ist die *rollenbasierte Zugriffssteuerung* (RBAC). Microsoft beschreibt, dass man in der einfachsten Umsetzung Rollen als Gruppen im Active Directory abbildet und diesen Gruppen Rechte für die tägliche Verwaltung innerhalb eines definierten Bereichs delegiert. Für jede Rolle sollte festgelegt sein, welche Aufgaben sie hat, auf welchen Systemen sie Rechte benötigt, wer Mitglied ist und wie die Mitgliedschaften verwaltet werden. Diese Struktur wird in Modul 9 zum Tier-Modell erweitert.

Das folgende Skript macht die Grenzen sichtbar. Es listet die Mitglieder der privilegierten Gruppen (rekursiv, also einschließlich verschachtelter Gruppen) und zeigt, welche Konten dabei auffallen: etwa Konten ohne Kennwortablauf, Konten, die lange nicht angemeldet waren, oder Konten, die gleichzeitig Dienstkonten sein könnten. Damit entsteht ein Überblick über den Bereich der Dienstadministratoren.

```powershell
Import-Module ActiveDirectory
$gruppen = "Enterprise Admins","Schema Admins","Domain Admins","Administrators",
           "Account Operators","Server Operators","Backup Operators","Print Operators"

$bericht = foreach ($g in $gruppen) {
    try {
        $mitglieder = Get-ADGroupMember -Identity $g -Recursive -ErrorAction Stop
    } catch { continue }       # Gruppe existiert in dieser Domain nicht (z. B. Enterprise Admins)
    foreach ($m in $mitglieder | Where-Object objectClass -eq "user") {
        $u = Get-ADUser $m -Properties PasswordNeverExpires, LastLogonDate, Enabled, Description
        [pscustomobject]@{
            Gruppe               = $g
            Konto                = $u.SamAccountName
            Aktiv                = $u.Enabled
            KennwortLaeuftNie    = $u.PasswordNeverExpires
            LetzteAnmeldung      = $u.LastLogonDate
            Beschreibung         = $u.Description
        }
    }
}

# Anzahl pro Gruppe und auffaellige Konten
$bericht | Group-Object Gruppe | Select-Object Name, Count | Sort-Object Count -Descending
$bericht | Where-Object { $_.KennwortLaeuftNie -or $_.LetzteAnmeldung -lt (Get-Date).AddDays(-90) } |
    Format-Table Gruppe, Konto, Aktiv, KennwortLaeuftNie, LetzteAnmeldung -AutoSize
$bericht | Export-Csv ".\Privilegierte-Konten.csv" -NoTypeInformation -Encoding UTF8
```

Die Schleife durchläuft jede privilegierte Gruppe. Mit `-Recursive` werden auch Mitglieder verschachtelter Gruppen erfasst. Weil nicht jede Gruppe in jeder Domain existiert (die Enterprise Admins gibt es nur in der Forest-Root-Domain), fängt der `try/catch`-Block den Fehler ab und springt zur nächsten Gruppe. Für jedes Benutzerkonto werden Kennwortablauf, Anmeldezeit und Beschreibung geladen. Die erste Auswertung zählt die Mitglieder pro Gruppe; die zweite zeigt Auffälligkeiten (Kennwort läuft nie ab, mehr als 90 Tage nicht angemeldet). Ergebnis ist ein Überblick, den man als Ausgangspunkt für das Aufräumen nutzt.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist die Gleichsetzung von Domain-Grenze und Sicherheitsgrenze, die wir in Modul 1 und in der Forest-Planung schon kennengelernt haben. Ein weiterer häufiger Fehler ist die Aufnahme von *Alltagskonten* in privilegierte Gruppen: Die IT-Mitarbeiterin liest E-Mails und surft im Netz mit einem Konto, das gleichzeitig Domain Admin ist. Ein Schadcode in einem E-Mail-Anhang läuft dann mit voller Domänenmacht. Die Lösung sind getrennte Konten: ein normales Konto für den Alltag und ein Administratorkonto, das nur auf Verwaltungsrechnern verwendet wird (Modul 9).

```powershell
# FALSCH: das Alltagskonto ist gleichzeitig Domain Admin
Add-ADGroupMember -Identity "Domain Admins" -Members "anna.muster"

# RICHTIG: separates Administratorkonto in einer eigenen OU, nur dieses ist privilegiert
New-ADUser -Name "adm-anna.muster" -SamAccountName "adm-anna.muster" `
    -Path "OU=Konten,OU=Admin,OU=Contoso,DC=corp,DC=contoso,DC=com" `
    -AccountPassword (Read-Host -AsSecureString "Kennwort") -Enabled $true
Add-ADGroupMember -Identity "Domain Admins" -Members "adm-anna.muster"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Bei einer Sicherheitsprüfung wird festgestellt, dass 37 Personen Mitglied der Gruppe Domain Admins sind, obwohl nur fünf Personen Domain Controller verwalten. Der Administrator setzt das Skript aus dieser Lerneinheit ein, identifiziert die Konten, klärt mit den Verantwortlichen, wer welche Rechte braucht, und ersetzt die Mitgliedschaften durch delegierte Rollen auf den passenden OUs. Nach vier Wochen sind es sieben Mitglieder, und der Rest der Verwaltung läuft über Delegation.

## 3.7 Standortanforderungen

Der Entwurf der Sites und die Platzierung der Domain Controller folgen den Standorten der Organisation und der Qualität der Netzwerkverbindungen. Pro Standort muss man drei Fragen beantworten: *Wie viele Benutzer* arbeiten dort? *Wie zuverlässig und schnell* ist die Leitung zum Hauptstandort? Und *wie sicher* ist der Serverraum? Aus den Antworten ergibt sich, ob der Standort einen eigenen schreibbaren Domain Controller, einen RODC oder gar keinen Domain Controller braucht.

Als Faustregel gilt: Ein Standort mit vielen Benutzern oder schlechter und unzuverlässiger Leitung bekommt einen *eigenen* Domain Controller, damit Anmeldungen auch bei Leitungsausfall funktionieren. Ist der Serverraum nicht abschließbar oder fehlt qualifiziertes Personal, wählt man einen *RODC* (Lerneinheit 2.6). Ein kleiner Standort mit zuverlässiger Leitung braucht eventuell gar keinen Domain Controller: Die Clients melden sich über die WAN-Leitung am Hauptstandort an, was bei guter Anbindung akzeptabel ist. In jedem Fall müssen die Subnetze des Standorts in Active Directory definiert und einer Site zugeordnet sein (Modul 1.8), damit die Clients den nächstgelegenen Domain Controller finden. Für die Platzierung des *Global Catalog* gilt in kleinen und mittleren Umgebungen: auf allen Domain Controllern aktivieren; Details in Modul 6.

Auch beim Namen der Site gibt es Regeln. Die Microsoft-Dokumentation empfiehlt, einen gültigen DNS-Namen zu verwenden (erlaubt sind Buchstaben, Ziffern, Bindestrich und Punkt als Trenner; unzulässig sind unter anderem Komma, Doppelpunkt, Ausrufezeichen, @, \#, \$, %, &, Klammern und Leerzeichen), weil die Site sonst nur dort verfügbar ist, wo ein Microsoft-DNS-Server eingesetzt wird. Die maximale Länge einer Beschriftung beträgt 63 Zeichen. Praktisch bedeutet das: Standortnamen wie `Wien`, `Graz` oder `Wien-Floridsdorf` sind unproblematisch, Namen mit Leerzeichen oder Sonderzeichen dagegen nicht.

Das nachfolgende Skript macht aus einer Standortliste (CSV) einen Vorschlag für die Domain-Controller-Platzierung und legt auf Wunsch Sites und Subnetze an. Es bewertet die Standorte nach einfachen, anpassbaren Regeln und ist damit ein Beispiel dafür, wie man Entwurfsregeln in Werkzeuge gießt.

```powershell
Import-Module ActiveDirectory

# Beispieldaten (in der Praxis: Import-Csv ".\standorte.csv")
$standorte = @"
Name,Subnetz,Benutzer,WanMbit,WanZuverlaessig,ServerraumSicher
Wien,10.10.0.0/24,300,1000,ja,ja
Graz,10.20.0.0/24,60,50,ja,nein
Linz,10.30.0.0/24,8,20,nein,nein
Villach,10.40.0.0/24,5,100,ja,nein
"@ | ConvertFrom-Csv

function Get-DcEmpfehlung($s) {
    $benutzer = [int]$s.Benutzer
    $wan      = [int]$s.WanMbit
    $stabil   = $s.WanZuverlaessig -eq "ja"
    $sicher   = $s.ServerraumSicher -eq "ja"
    if ($benutzer -ge 100)                         { if ($sicher) { "Schreibbarer DC (mind. 2)" } else { "Serverraum verbessern, dann 2 DCs" } }
    elseif (-not $stabil -or $wan -lt 30)          { if ($sicher) { "Schreibbarer DC" } else { "RODC" } }
    elseif ($benutzer -ge 25)                      { if ($sicher) { "Schreibbarer DC" } else { "RODC" } }
    else                                           { "Kein DC: Anmeldung ueber WAN" }
}

$plan = foreach ($s in $standorte) {
    [pscustomobject]@{ Standort = $s.Name; Subnetz = $s.Subnetz; Empfehlung = Get-DcEmpfehlung $s }
}
$plan | Format-Table -AutoSize

# Sites und Subnetze anlegen (zuerst mit -WhatIf pruefen!)
foreach ($s in $standorte) {
    if (-not (Get-ADReplicationSite -Filter "Name -eq '$($s.Name)'")) {
        New-ADReplicationSite -Name $s.Name -WhatIf
    }
    if (-not (Get-ADReplicationSubnet -Filter "Name -eq '$($s.Subnetz)'")) {
        New-ADReplicationSubnet -Name $s.Subnetz -Site $s.Name -WhatIf
    }
}
```

Der Block `@" ... "@` ist ein sogenannter Here-String, der mehrzeiligen Text enthält; `ConvertFrom-Csv` wandelt ihn in Objekte um. In der Praxis liest man die Daten aus einer Datei. Die Funktion `Get-DcEmpfehlung` setzt die Entscheidungsregeln um: große Standorte bekommen zwei schreibbare Domain Controller, Standorte mit unzuverlässiger oder langsamer Leitung einen eigenen (bei unsicherem Serverraum einen RODC), kleine Standorte mit guter Anbindung keinen. Die Zahlen sind *Beispielwerte* und gehören an die Anforderungen der Organisation angepasst. Die letzte Schleife zeigt, wie man Sites und Subnetze anlegt, solange sie noch nicht vorhanden sind; der Schalter `-WhatIf` verhindert die tatsächliche Änderung und zeigt nur an, was passieren würde. Erst nach der Prüfung entfernt man ihn.

### Typische Fehler und Stolperfallen

Der erste Fehler ist, die Standortplanung nach dem Netzplan zu vergessen: Neue Subnetze entstehen, aber niemand trägt sie ein. Der zweite Fehler ist die Platzierung *schreibbarer* Domain Controller in unsicheren Räumen, weil „es nur ein kleiner Server“ ist. Ein gestohlener Domain Controller ist ein Totalschaden für die Domain; die Lösung ist der RODC. Der dritte Fehler ist das Gegenteil: Zu viele Domain Controller an kleinen Standorten mit guter Leitung, die Pflege kosten und Risiken schaffen, ohne einen Nutzen zu haben.

```powershell
# FALSCH: schreibbarer DC in der Abstellkammer der Filiale
Install-ADDSDomainController -DomainName corp.contoso.com -SiteName "Villach" -Credential $cred

# RICHTIG: RODC fuer unsichere Standorte (vorbereitetes Konto, Delegation, begrenzte PRP)
Add-ADDSReadOnlyDomainControllerAccount -DomainControllerAccountName "RODC-VILLACH01" `
    -DomainName corp.contoso.com -SiteName "Villach" `
    -DelegatedAdministratorAccountName "CORP\Filiale-Admins"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Ein Handelsunternehmen mit 25 Filialen prüft die Standortliste. Zehn Filialen haben weniger als zehn Mitarbeiter und stabile Leitungen: Dort entfällt der Domain Controller. Acht Filialen haben Außenstellen mit unsicherem Serverraum und bekommen einen RODC. Sieben Filialen mit mehr als 50 Mitarbeitern und schlechten Leitungen erhalten schreibbare Domain Controller in abschließbaren Schränken. Die Entscheidung wird in einer Tabelle dokumentiert und jährlich überprüft.

## 3.8 Namenskonventionen

Namenskonventionen sind unscheinbar und doch eines der wirksamsten Mittel, um ein Verzeichnis lesbar und automatisierbar zu halten. Ein Name wie `SRV-FS-WIEN-01` sagt auf einen Blick Rolle, Funktion, Standort und Nummer, ein Name wie `Testserver2neu` sagt nichts und führt im Zweifel zu Fehlern. Eine Konvention beschreibt für jede Objektart die Bestandteile, die erlaubten Zeichen und die Länge. Sie sollte *kurz*, *eindeutig* und *ohne Informationen, die veralten* sein.

Für *Computer* nennt die Microsoft-Dokumentation Empfehlungen: ein Name, der leicht zu merken ist und den Zweck beschreibt; eindeutig in der ganzen Organisation; nur ASCII-Zeichen und die in RFC 1123 genannten Zeichen (A–Z, a–z, 0–9, Bindestrich); keine Unterscheidung nach Groß- und Kleinschreibung, weil DNS sie nicht unterscheidet; und höchstens 15 Zeichen wegen des NetBIOS-Namens. Für *Benutzer* gilt: Der `sAMAccountName` ist auf 20 Zeichen begrenzt; ein nachvollziehbares Schema wie `nachname.v` oder `vorname.nachname` und eine Regel für Namensgleichheiten (Zusatzziffer) verhindern Konflikte. Der UPN folgt meist der E-Mail-Adresse. Für *Gruppen* bewährt sich ein Präfix, das Art und Bereich anzeigt, etwa `G-` für globale Gruppen, `DL-` für domänenlokale Gruppen und `ROL-` für Rollen. Für *Dienstkonten* etwa `svc-` oder bei gMSA `gmsa-`. Für *Gruppenrichtlinien* ein Schema wie `C-` (Computer) und `U-` (User) mit sprechendem Namen. Für *Sites* ein kurzer Standortname im DNS-konformen Format; für *OUs* aussagekräftige Namen ohne Sonderzeichen.

Eine Konvention nützt nur, wenn sie *durchgesetzt* wird. Dafür eignen sich Skripte, die Namen vor der Anlage prüfen oder erzeugen. Das folgende Beispiel enthält zwei Funktionen: Die erste erzeugt einen eindeutigen `sAMAccountName` aus Vor- und Nachnamen (Umlaute werden ersetzt, bei Kollisionen wird eine Nummer angehängt), die zweite prüft Computernamen gegen die Regeln und listet Verstöße im Bestand.

```powershell
Import-Module ActiveDirectory

function ConvertTo-AsciiName([string]$Text) {
    $t = $Text.ToLower()
    $t = $t -replace "ä","ae" -replace "ö","oe" -replace "ü","ue" -replace "ß","ss"
    $t = $t.Normalize([Text.NormalizationForm]::FormD) -replace "\p{Mn}",""     # Akzente entfernen
    $t -replace "[^a-z0-9]",""
}

function New-SamAccountNameVorschlag {
    param([Parameter(Mandatory)][string]$Vorname, [Parameter(Mandatory)][string]$Nachname)
    $basis = (ConvertTo-AsciiName $Vorname).Substring(0,1) + "." + (ConvertTo-AsciiName $Nachname)
    if ($basis.Length -gt 20) { $basis = $basis.Substring(0,20) }
    $name = $basis; $zaehler = 1
    while (Get-ADUser -Filter "SamAccountName -eq '$name'") {
        $zaehler++
        $suffix = [string]$zaehler
        $name = $basis.Substring(0, [math]::Min($basis.Length, 20 - $suffix.Length)) + $suffix
    }
    $name
}

New-SamAccountNameVorschlag -Vorname "Jürgen" -Nachname "Müller"       # j.mueller
New-SamAccountNameVorschlag -Vorname "Anna"   -Nachname "Muster"       # a.muster (oder a.muster2, ...)

# Bestandsprüfung: Computernamen, die gegen die Konvention verstossen
Get-ADComputer -Filter * | Where-Object {
    $_.Name -notmatch '^[A-Za-z0-9-]{1,15}$' -or $_.Name -notmatch '^(PC|NB|SRV|DC)-'
} | Select-Object Name, DistinguishedName
```

Die Funktion `ConvertTo-AsciiName` ersetzt Umlaute und entfernt Akzente. `New-SamAccountNameVorschlag` bildet aus dem ersten Buchstaben des Vornamens, einem Punkt und dem Nachnamen den Basisnamen, kürzt ihn auf 20 Zeichen und hängt bei Kollisionen eine laufende Nummer an, wobei die Gesamtlänge von 20 Zeichen nie überschritten wird. Die Bestandsprüfung am Ende listet alle Computerkonten, deren Name entweder unzulässige Zeichen enthält, zu lang ist oder nicht mit einem der erlaubten Präfixe (`PC-`, `NB-`, `SRV-`, `DC-`) beginnt. Das Skript ändert nichts, es liefert eine Liste zur Bereinigung.

### Typische Fehler und Stolperfallen

Der erste Fehler ist die Verwendung von Informationen, die veralten, im Namen: Ein Server heißt `SRV-WIEN-2012`, läuft aber längst unter Windows Server 2022 an einem anderen Standort. Der zweite Fehler ist die Vermischung: Einmal `Schmidt.Anna`, einmal `anna_schmidt`, einmal `aschmidt`, was jede Automatisierung erschwert. Der dritte Fehler ist das Ignorieren von Längengrenzen: Wer Gruppen- oder Benutzernamen über 20 Zeichen für den `sAMAccountName` wählt, bekommt Fehler beim Anlegen oder Abschneidungen, die zu Kollisionen führen.

```powershell
# FALSCH: zu lange und inkonsistente Namen
New-ADUser -Name "Anna Musterfrau-Hofmann" -SamAccountName "Anna_Musterfrau-Hofmann_Vertrieb"   # > 20 Zeichen

# RICHTIG: Schema, begrenzte Laenge, eindeutiger Name
New-ADUser -Name "Anna Musterfrau-Hofmann" -SamAccountName "a.musterfrauhofmann" `
    -UserPrincipalName "anna.musterfrau-hofmann@contoso.com"
```

### Praxisbezug

> **Praxisbeispiel**
>
> Beim Onboarding neuer Mitarbeiter legt die Personalabteilung Vorname, Nachname und Eintrittsdatum in einem Formular ab. Ein Skript erzeugt daraus nach der Namenskonvention den Anmeldenamen, die E-Mail-Adresse und den UPN, legt das Konto in der richtigen OU an und trägt es in die Basisgruppen ein. Weil die Namensregeln im Code stehen, entstehen keine Abweichungen und keine Doppelungen mehr; der Helpdesk spart Zeit bei jeder Neuanlage.

## 3.9 Design Review

Ein *Design Review* ist die systematische Überprüfung eines Entwurfs oder einer bestehenden Umgebung gegen definierte Kriterien. Man führt es vor der Umsetzung (Entwurfsreview), nach größeren Änderungen und in regelmäßigen Abständen (zum Beispiel jährlich) durch. Der Review hat drei Ziele: Fehler finden, bevor sie teuer werden, Abweichungen von den Prinzipien begründen oder beheben, und den Entwurf so dokumentieren, dass ein neuer Kollege ihn versteht.

Ein brauchbarer Review prüft sieben Bereiche. Erstens den *Namensraum*: gültiger, registrierter Name, kein `.local`, kein einzelnes Label. Zweitens die *Struktur*: Anzahl Forests und Domains mit Begründung, Funktionsebenen. Drittens die *OU-Struktur*: Tiefe, Trennung nach Objektart, Löschschutz, Nutzung der Standardcontainer. Viertens die *Delegation*: Rollengruppen statt Einzelpersonen, kleinste Rechte, Dokumentation. Fünftens die *Standorte*: Sites und Subnetze vollständig, Domain-Controller-Platzierung begründet. Sechstens die *Namenskonventionen*: Einhaltung im Bestand. Siebtens die *Privilegierte Konten*: Zahl der Mitglieder, getrennte Administratorkonten. Jeder Prüfpunkt wird mit *Ergebnis*, *Risiko* und *Maßnahme* dokumentiert.

Das Skript dieser Lerneinheit führt die automatisierbaren Prüfungen aus, schreibt sie in einen Bericht und gibt eine Gesamtübersicht. Die nicht automatisierbaren Prüfungen (zum Beispiel „ist die Begründung für zwei Domains plausibel?“) bleiben ein Gespräch, aber das Skript liefert die Zahlen dafür.

```powershell
Import-Module ActiveDirectory
$domain = Get-ADDomain
$forest = Get-ADForest
$root   = $domain.DistinguishedName
$ergebnis = New-Object System.Collections.Generic.List[object]
function Pruefe([string]$Bereich, [string]$Punkt, [bool]$Ok, [string]$Detail) {
    $ergebnis.Add([pscustomobject]@{ Bereich=$Bereich; Pruefpunkt=$Punkt; Ergebnis=$(if ($Ok) {"OK"} else {"ABWEICHUNG"}); Detail=$Detail })
}

# 1) Namensraum
Pruefe "Namensraum" "Kein .local" (-not $forest.Name.EndsWith(".local")) $forest.Name
Pruefe "Namensraum" "Mind. zwei Labels" ($forest.Name.Split(".").Count -ge 2) $forest.Name

# 2) Struktur
Pruefe "Struktur" "Ein Forest, moeglichst eine Domain" ($forest.Domains.Count -le 1) ("{0} Domain(s)" -f $forest.Domains.Count)
Pruefe "Struktur" "Funktionsebene mind. Windows Server 2016" ($forest.ForestMode -match "2016|2025|Threshold") $forest.ForestMode

# 3) OU-Struktur
$ous = Get-ADOrganizationalUnit -Filter * -Properties ProtectedFromAccidentalDeletion
$ungeschuetzt = $ous | Where-Object { -not $_.ProtectedFromAccidentalDeletion }
Pruefe "OU" "Alle OUs mit Loeschschutz" ($ungeschuetzt.Count -eq 0) ("{0} ohne Schutz" -f @($ungeschuetzt).Count)
$maxTiefe = ($ous | ForEach-Object { ($_.DistinguishedName -replace ",$root$","").Split(",").Count } | Measure-Object -Maximum).Maximum
Pruefe "OU" "Maximale Tiefe <= 4" ($maxTiefe -le 4) "Tiefe $maxTiefe"
$inContainer = @(Get-ADComputer -Filter * -SearchBase "CN=Computers,$root" -SearchScope OneLevel)
Pruefe "OU" "Keine Computer im Container Computers" ($inContainer.Count -eq 0) ("{0} Objekt(e)" -f $inContainer.Count)

# 4) Standorte
$subnetze = @(Get-ADReplicationSubnet -Filter *)
$dcs      = @(Get-ADDomainController -Filter *)
Pruefe "Standorte" "Subnetze definiert" ($subnetze.Count -gt 0) ("{0} Subnetz(e)" -f $subnetze.Count)
Pruefe "Standorte" "Mind. 2 Domain Controller" ($dcs.Count -ge 2) ("{0} DC(s)" -f $dcs.Count)

# 5) Privilegierte Konten
$da = @(Get-ADGroupMember "Domain Admins" -Recursive)
Pruefe "Privilegien" "Domain Admins <= 5 Mitglieder" ($da.Count -le 5) ("{0} Mitglied(er)" -f $da.Count)
$sa = @(Get-ADGroupMember "Schema Admins" -ErrorAction SilentlyContinue)
Pruefe "Privilegien" "Schema Admins leer" ($sa.Count -eq 0) ("{0} Mitglied(er)" -f $sa.Count)

$ergebnis | Format-Table -AutoSize -Wrap
$ergebnis | Export-Csv ".\Design-Review-$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation -Encoding UTF8
"Abweichungen: " + @($ergebnis | Where-Object Ergebnis -eq "ABWEICHUNG").Count
```

Die Funktion `Pruefe` sammelt jeden Prüfpunkt mit Bereich, Ergebnis und Detail. Die Abschnitte folgen den Prüfbereichen aus dem Text: Der Namensraum wird gegen die Regeln geprüft, die Struktur gegen die Faustregel „ein Forest, eine Domain“, die OUs auf Löschschutz, Tiefe und Containernutzung, die Standorte auf definierte Subnetze und mindestens zwei Domain Controller, die Privilegien auf Mitgliederzahl. Die Schwellenwerte (fünf Mitglieder, Tiefe vier) sind Beispielwerte und gehören an die Organisation angepasst. Das Ergebnis wird als Tabelle ausgegeben und als CSV gespeichert; die letzte Zeile zählt die Abweichungen. Eine Abweichung ist kein Fehler an sich, sie verlangt eine Begründung oder eine Maßnahme.

### Typische Fehler und Stolperfallen

Der häufigste Fehler ist, den Review *nur einmalig* durchzuführen. Active Directory lebt: Neue Standorte, neue Anwendungen und neue Administratoren verändern die Umgebung, und nach zwei Jahren stimmt das Bild nicht mehr. Der zweite Fehler ist ein Review ohne Maßnahmenliste: Befunde, die niemand verantwortet, verschwinden in der Schublade. Der dritte ist die Fixierung auf Skriptergebnisse: Ein Skript findet 23 OUs ohne Löschschutz, aber nicht, dass die gesamte OU-Struktur das Organigramm abbildet.

```powershell
# FALSCH: Befund nur anzeigen
$ergebnis | Where-Object Ergebnis -eq "ABWEICHUNG"

# RICHTIG: Befund mit Verantwortlichem, Frist und Status in eine Massnahmenliste uebernehmen
$ergebnis | Where-Object Ergebnis -eq "ABWEICHUNG" | ForEach-Object {
    [pscustomobject]@{ Bereich=$_.Bereich; Befund=$_.Pruefpunkt; Detail=$_.Detail
                       Verantwortlich=""; Frist=(Get-Date).AddDays(30).ToString("yyyy-MM-dd"); Status="offen" }
} | Export-Csv ".\Massnahmen.csv" -NoTypeInformation -Encoding UTF8
```

### Praxisbezug

> **Praxisbeispiel**
>
> Vor einer Fusion verlangt der Käufer ein IT-Due-Diligence. Das IT-Team legt den jährlichen Design-Review der letzten drei Jahre mit den Maßnahmenlisten vor. Der Käufer sieht, dass Abweichungen erkannt, begründet oder behoben wurden, und bewertet das Active Directory als geordnet. Ohne die Dokumentation hätte der Nachweis eine Woche Analysearbeit bedeutet.

## 3.10 Übungsaufgaben zu Modul 03

Die Aufgaben 1 bis 3 sind Entwurfsfragen, Aufgaben 4 bis 8 sind praktische Skriptaufgaben für die Laborumgebung.

**Aufgabe 3.1** **Namensbewertung.** Bewerten Sie die Namen `contoso.local`, `ad.contoso.com`, `contoso`, `vertrieb_nord.contoso.com` und `it.vertrieb.sued.hamburg.corp.contoso.com`. Begründen Sie jeweils kurz, welche Regeln verletzt werden.

**Aufgabe 3.2** **Forest oder OU?** Eine Tochtergesellschaft mit 40 Mitarbeitern möchte „eigene Administratoren und unabhängige Verwaltung“. Welche Fragen stellen Sie, bevor Sie sich für einen eigenen Forest, eine eigene Domain oder eine OU mit Delegation entscheiden?

**Aufgabe 3.3** **Grenzen zuordnen.** Ordnen Sie jede der folgenden Anforderungen der Grenze zu, die sie erfüllt (Forest, Domain, OU, Site, GPO): (a) Helpdesk darf Kennwörter zurücksetzen; (b) Das Schema darf nicht von der Tochterfirma verändert werden; (c) Clients sollen sich am örtlichen DC anmelden; (d) Alle Arbeitsplatzrechner erhalten dieselbe Bildschirmsperre; (e) Es gilt eine gemeinsame Mindestkennwortlänge.

**Aufgabe 3.4** **Namensprüfer.** Erweitern Sie die Funktion `Test-AdDomainName` um eine Prüfung, die Unterstriche meldet, und testen Sie sie mit drei eigenen Namen.

**Aufgabe 3.5** **OU-Struktur.** Bauen Sie mit dem rekursiven Skript aus Lerneinheit 3.4 die Struktur `Contoso` mit den Unter-OUs `Benutzer`, `Computer`, `Server`, `Gruppen`, `Dienstkonten` und `Deaktiviert` auf. Führen Sie das Skript zweimal aus und erklären Sie das Ergebnis des zweiten Durchlaufs.

**Aufgabe 3.6** **Delegation.** Delegieren Sie der Gruppe `ROL-GruppenPfleger` das Recht, die Mitglieder (Attribut `member`) von Gruppen in der OU `Berechtigung` zu ändern, aber keine Gruppen anzulegen oder zu löschen. Überprüfen Sie das Ergebnis mit `Get-Acl`.

**Aufgabe 3.7** **Namensgenerator.** Erweitern Sie `New-SamAccountNameVorschlag` so, dass auch ein UPN im Format `vorname.nachname@contoso.com` erzeugt wird, und testen Sie die Funktion mit „Hans-Peter Müller-Lüdenscheidt“.

**Aufgabe 3.8** **Review.** Führen Sie das Review-Skript aus Lerneinheit 3.9 in Ihrer Laborumgebung aus. Wählen Sie zwei Abweichungen aus und schreiben Sie je eine Maßnahme mit Verantwortlichem und Frist.

## 3.11 Lösungen zu den Übungsaufgaben

**Lösung 3.1.** `contoso.local`: Endung `.local` sollte vermieden werden, der Name ist nicht registrierbar. `ad.contoso.com`: in Ordnung, wenn `contoso.com` der Organisation gehört. `contoso`: einzelnes Label, nicht registrierbar, verlangt Zusatzkonfiguration. `vertrieb_nord.contoso.com`: Unterstrich im Label, der Name des Geschäftsbereichs kann veralten, Anwendungen können den Namen ablehnen. `it.vertrieb.sued.hamburg.corp.contoso.com`: sieben Labels, die Hierarchie ist zu tief; außerdem enthält sie Geschäftsbereichs- und Ortsnamen.

**Lösung 3.2.** Wichtige Fragen: Braucht die Tochter technische Isolation (anderes Schutzniveau, regulatorische Vorgaben)? Braucht sie ein eigenes Schema? Ist sie eine eigene Rechtsperson mit eigener Haftung? Welche Anwendungen laufen dort? Wie viele Administratoren sind nötig, und welche Aufgaben sollen sie wirklich ausführen? Ergeben die Antworten „nein“, genügt eine OU mit Delegation; sie ist in dieser Größe fast immer richtig. Eine eigene Domain wäre unverhältnismäßig, ein eigener Forest nur bei echtem Isolationsbedarf gerechtfertigt.

**Lösung 3.3.** (a) OU (Delegation); (b) Forest (Schema gilt forestweit); (c) Site (Client-DC-Zuordnung); (d) GPO (Verknüpfung mit der OU der Arbeitsplatzrechner); (e) Domain (die Standardkennwortrichtlinie gilt domainweit; Ausnahmen mit Fine-Grained Password Policies).

**Lösung 3.4.**

```powershell
# Ergaenzung in Test-AdDomainName, innerhalb der foreach-Schleife ueber $labels:
if ($l.Contains("_")) { $meldungen.Add("Label '$l' enthaelt Unterstrich") }
```

Das Muster aus der Lerneinheit meldet den Unterstrich bereits indirekt, weil der reguläre Ausdruck ihn nicht zulässt; die gezielte Meldung ist jedoch aussagekräftiger. Test: `vertrieb_nord.beispiel.at` liefert zwei Meldungen, `ad.beispiel.at` keine.

**Lösung 3.5.** Beim zweiten Durchlauf meldet das Skript für jede OU „vorhanden“ und legt nichts neu an. Das liegt an der Prüfung per Distinguished Name vor dem Anlegen (*Idempotenz*): Das Ergebnis eines Skripts soll unabhängig davon sein, wie oft es ausgeführt wird. Ohne die Prüfung käme es beim zweiten Durchlauf zu Fehlern, weil die OUs bereits existieren.

**Lösung 3.6.**

```powershell
$ou = "OU=Berechtigung,OU=Gruppen,OU=Contoso,DC=corp,DC=contoso,DC=com"
dsacls $ou /I:S /G "CORP\ROL-GruppenPfleger:RPWP;member;group"
(Get-Acl "AD:\$ou").Access | Where-Object { $_.IdentityReference -like "*ROL-GruppenPfleger" } |
    Select-Object IdentityReference, ActiveDirectoryRights, ObjectType, InheritanceType
```

Das Recht `RPWP` auf das Attribut `member` der Klasse `group` erlaubt, Mitglieder hinzuzufügen und zu entfernen. Weil weder das Recht „Untergeordnete Objekte erstellen“ noch „Löschen“ vergeben wurde, kann die Rolle keine Gruppen anlegen oder löschen.

**Lösung 3.7.**

```powershell
function New-UpnVorschlag([string]$Vorname, [string]$Nachname, [string]$Suffix = "contoso.com") {
    $v = ConvertTo-AsciiName ($Vorname -replace "-","")
    $n = ConvertTo-AsciiName ($Nachname -replace "-","")
    "{0}.{1}@{2}" -f $v, $n, $Suffix
}
New-UpnVorschlag "Hans-Peter" "Müller-Lüdenscheidt"      # hanspeter.muellerluedenscheidt@contoso.com
```

Die Bindestriche werden vor der Umwandlung entfernt, weil `ConvertTo-AsciiName` alle Zeichen außerhalb von a–z und 0–9 verwirft. Der UPN darf länger als 20 Zeichen sein; die Längenbegrenzung gilt nur für den `sAMAccountName`.

**Lösung 3.8.** Eine mögliche Lösung: Befund „5 OUs ohne Löschschutz“ (Maßnahme: Löschschutz bei allen OUs mit `Set-ADOrganizationalUnit` und dem Parameter `-ProtectedFromAccidentalDeletion` setzen, Verantwortlich: AD-Team, Frist: 14 Tage) und Befund „9 Domain Admins“ (Maßnahme: Mitgliedschaften prüfen, Rollen delegieren, Verantwortlich: Sicherheitsbeauftragter, Frist: 30 Tage). Entscheidend ist, dass jede Maßnahme einen Verantwortlichen, eine Frist und eine Überprüfungsmöglichkeit hat.
