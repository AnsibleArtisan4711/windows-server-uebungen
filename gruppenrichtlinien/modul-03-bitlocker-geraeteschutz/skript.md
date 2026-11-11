# Modul 03 - BitLocker und Geraeteschutz

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Gruppenrichtlinien für Windows 11 – 100 Richtlinien im Detail“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Steckbriefe als Tabellen, Übungsaufgaben und Lösungen als fortlaufend nummerierte Absätze). **Nummerierung:** Die Überschriften der Richtlinien tragen hier die laufende Nummer 1 bis 100 aus der Modultabelle; die Verweise im Text („Abschnitt 43“) meinen diese Nummer. (Im LaTeX-Satz zählen die Überschriften je Modul neu, etwa 5.3.) **Die Beispiele (PowerShell, INF) wurden für dieses Repository nicht ausgeführt**; sie verändern Gruppenrichtlinien, Registry und Sicherheitseinstellungen und gehören nur in eine Testumgebung (Pilot-OU, Testdomäne). Übersicht zum Modul: [README](README.md).

**Dauer:** 10 Unterrichtsstunden (Annahme: 1 Stunde je Richtlinie)  
**Priorität:** überwiegend 1 (vier Richtlinien mit Priorität 2)

| Nr. | Lerneinheit (Richtlinie)                                       | Prio | Stunden |
|----:|:---------------------------------------------------------------|:----:|:-------:|
|  21 | BitLocker für Betriebssystemlaufwerk erzwingen                 |  1   |    1    |
|  22 | BitLocker Recovery in AD sichern                               |  1   |    1    |
|  23 | BitLocker ohne Recovery Backup verhindern                      |  1   |    1    |
|  24 | Wechseldatenträger verschlüsseln                               |  2   |    1    |
|  25 | Schreibzugriff auf unverschlüsselte USB-Datenträger verweigern |  2   |    1    |
|  26 | VBS aktivieren                                                 |  1   |    1    |
|  27 | Credential Guard aktivieren                                    |  1   |    1    |
|  28 | LSA-Schutz aktivieren                                          |  1   |    1    |
|  29 | Windows Hello for Business erzwingen                           |  2   |    1    |
|  30 | Biometrie nur verwaltet zulassen                               |  2   |    1    |
|     | **Summe**                                                      |      | **10**  |

**Worum es in diesem Modul geht.** Dieses Modul schützt zwei Dinge: die *Daten* auf dem Gerät, falls es verloren geht oder gestohlen wird (BitLocker, Abschnitte 21 bis 25), und die *Anmeldeinformationen* im Arbeitsspeicher und bei der Anmeldung, falls das Gerät im Betrieb angegriffen wird (VBS, Credential Guard, LSA-Schutz, Windows Hello, Abschnitte 26 bis 30). Die Einstellungen liegen überwiegend unter Computerkonfiguration \> Administrative Vorlagen. Viele dieser Funktionen hängen von Hardware ab (TPM, UEFI, Secure Boot, Virtualisierung). Deshalb entscheidet vor jedem Rollout eine Inventur darüber, welche Geräte überhaupt geeignet sind. Eine Hardwareinventur gehört zu jeder Pilotphase dieses Moduls.

## 21 BitLocker für Betriebssystemlaufwerk erzwingen

| **Feld**        | **Steckbrief**                                                                                                                          |
|:----------------|:----------------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> BitLocker-Laufwerkverschlüsselung \> Betriebssystemlaufwerke |
| Einstellung     | Zusätzliche Authentifizierung beim Start anfordern                                                                                      |
| Empfehlung      | Aktiviert, TPM verwenden                                                                                                                |
| Ziel / Zweck    | Schützt Daten bei Verlust oder Diebstahl                                                                                                |
| Zielbereich     | Computer                                                                                                                                |
| Priorität       | 1                                                                                                                                       |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                             |

Ein verlorener Laptop ist kein Sicherheitsproblem, wenn man mit der Festplatte nichts anfangen kann. *BitLocker* verschlüsselt dazu die Laufwerke mit einem symmetrischen Schlüssel. Der Schlüssel wird vom *TPM* (*Trusted Platform Module*, einem Sicherheitschip auf der Hauptplatine) bewahrt und nur herausgegeben, wenn der Startvorgang unverändert ist. Wird die Festplatte in einen anderen Rechner gesteckt oder wird der Startvorgang manipuliert, bleibt der Schlüssel im TPM, und die Daten bleiben unlesbar. Als Algorithmus nennt die Microsoft-Dokumentation AES mit 128 oder 256 Bit; die empfohlene Betriebsart ist XTS-AES, und Microsoft gibt als Standard XTS-AES 128 an.

Die Richtlinie „Zusätzliche Authentifizierung beim Start anfordern“ (englisch *Require additional authentication at startup*) legt fest, wie BitLocker beim Start den Schlüssel freigibt. Der Lehrplan wählt die Variante „TPM verwenden“, also die Freigabe allein durch das TPM ohne PIN. Das ist für den Benutzer am bequemsten: Der Rechner startet ohne Eingabe, aber die Platte lässt sich außerhalb dieses Geräts nicht lesen. Strengere Varianten verlangen zusätzlich eine PIN oder einen USB-Schlüssel; sie erhöhen den Schutz gegen Angriffe auf einen laufenden oder schlafenden Rechner, verursachen aber Rückfragen am Helpdesk. Die Option „BitLocker ohne kompatibles TPM zulassen“ sollte in einer TPM-Umgebung deaktiviert bleiben.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft gibt es außerdem die *Geräteverschlüsselung* (device encryption), die BitLocker auf geeigneten Geräten automatisch einschaltet. Ab Windows 11 24H2 sind die früheren Voraussetzungen (DMA-Schutz und HSTI beziehungsweise Modern Standby) entfallen, sodass mehr Geräte infrage kommen. Bei domänenverbundenen oder Entra-verbundenen Geräten wird der Klartextschlüssel entfernt, sobald der Wiederherstellungsschlüssel erfolgreich gesichert wurde. Die Richtlinie „Require device encryption“ gibt es laut Microsoft nur als CSP/Intune, nicht als klassische Gruppenrichtlinie.

Das folgende Beispiel zeigt die Konfiguration per GPO-Registry und eine Prüfung am Client. Die Werte stammen aus meiner Kenntnis der BitLocker-ADMX-Datei (`UseAdvancedStartup`, `EnableBDEWithNoTPM`, `UseTPM`); die Bedeutung der Zahlen sollte im Pilot gegen den Gruppenrichtlinien-Editor geprüft werden. Das Skript legt nur eine neue GPO an und verändert noch keinen Rechner. Das Aktivieren von BitLocker selbst erfolgt auf dem Client.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "BL-OS-Laufwerk"
$key = "HKLM\SOFTWARE\Policies\Microsoft\FVE"

# Zusaetzliche Authentifizierung beim Start verlangen
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName UseAdvancedStartup -Type DWord -Value 1
# BitLocker ohne kompatibles TPM NICHT zulassen
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName EnableBDEWithNoTPM -Type DWord -Value 0
# TPM-Start: 2 = TPM zulassen (ohne PIN)
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName UseTPM -Type DWord -Value 2

# Auf dem Client: TPM und Schutzstatus pruefen, danach verschluesseln
Get-Tpm | Select-Object TpmPresent, TpmReady
Get-BitLockerVolume -MountPoint $env:SystemDrive |
    Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionMethod, KeyProtector
```

Die drei Registrywerte bilden die Teile der Richtlinie ab. `Get-Tpm` zeigt, ob ein TPM vorhanden und einsatzbereit ist; fehlt es, sollte der Rechner nicht in die BitLocker-OU. `Get-BitLockerVolume` zeigt Status, Schutzzustand, Verfahren und die vorhandenen Schlüsselschützer. Verschlüsselt wird auf dem Client zum Beispiel mit `Enable-BitLocker -MountPoint C: -TpmProtector -RecoveryPasswordProtector`; dieser Befehl sollte erst laufen, wenn die Sicherung des Wiederherstellungskennworts (Abschnitt 22) geregelt ist.

**Typische Fehler.** Falsch: BitLocker erzwingen, ohne zuvor Wiederherstellungsschlüssel zu sichern. Fällt dann das TPM aus oder ändert ein BIOS-Update die Startmessung, fragt BitLocker nach dem 48-stelligen Wiederherstellungskennwort, das niemand hat. Richtig: zuerst Abschnitt 22 und 23 umsetzen, dann erzwingen. Zweiter Fehler: BIOS-Updates, Firmware- oder Boot-Änderungen auf Rechnern mit aktivem BitLocker einzuspielen, ohne den Schutz vorher auszusetzen (`Suspend-BitLocker`). Dritter Fehler: der Schutz im Ruhezustand „Standby“: Laut Microsoft ist ein Rechner im Standby anfällig für DMA-Angriffe, weil Daten im Arbeitsspeicher bleiben; für höhere Sicherheit wird empfohlen, Standby zu deaktivieren und Ruhezustand mit Startauthentifizierung zu verwenden.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Vertriebsmitarbeiter verliert sein Notebook im Zug. Weil das Gerät mit BitLocker und TPM geschützt war, genügt eine Meldung an die IT, ein Sperren des Kontos und der Eintrag im Verlustregister. Ohne BitLocker wäre eine Datenschutzverletzung zu melden gewesen. Die Beurteilung, ob eine Meldepflicht besteht, ist eine rechtliche Frage und hier keine Rechtsberatung.

## 22 BitLocker Recovery in AD sichern

| **Feld**        | **Steckbrief**                                                                                               |
|:----------------|:-------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> BitLocker-Laufwerkverschlüsselung |
| Einstellung     | BitLocker-Wiederherstellungsinformationen in AD DS speichern                                                 |
| Empfehlung      | Aktiviert                                                                                                    |
| Ziel / Zweck    | Sichert Wiederherstellbarkeit verschlüsselter Clients                                                        |
| Zielbereich     | Computer                                                                                                     |
| Priorität       | 1                                                                                                            |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                  |

Das *Wiederherstellungskennwort* (recovery password) ist die Notfallschlüsselung von BitLocker: ein 48-stelliger Zahlencode, mit dem man ein Laufwerk entsperrt, wenn der normale Weg über das TPM nicht mehr funktioniert. Es entsteht, wenn BitLocker eingerichtet wird, und es hilft nur, wenn es *vorher* an einem sicheren, zentralen Ort gespeichert wurde. Die Richtlinie „Choose how BitLocker-protected operating system drives can be recovered“ (Wiederherstellungsoptionen für Betriebssystemlaufwerke) sorgt dafür, dass die Informationen in Active Directory Domain Services (AD DS) liegen, und zwar am Computerobjekt.

Laut Microsoft werden pro Computer zwei Dinge gespeichert: das 48-stellige Wiederherstellungskennwort und das *Schlüsselpaket* (key package). Mit dem Schlüsselpaket und dem Kennwort lassen sich Teile eines Laufwerks auch bei schwerem Datenträgerschaden wiederherstellen; es funktioniert nur für das Laufwerk, für das es erzeugt wurde. Das Schlüsselpaket benötigt das Werkzeug `Repair-bde`. In der Richtlinie wählt man „Wiederherstellungskennwort und Schlüsselpaket sichern“ oder nur das Kennwort. Wichtig ist der Ausgangszustand: Laut Microsoft wird standardmäßig *nichts* in AD DS oder Entra ID gesichert. Ohne diese Richtlinie existiert also kein zentrales Backup.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft werden bei Entra-hybrid-verbundenen Geräten die Wiederherstellungskennwörter sowohl in Active Directory als auch in Entra ID gesichert, bei rein Entra-verbundenen Geräten in Entra ID. Domänenadministratoren lesen die Kennwörter mit dem BitLocker Recovery Password Viewer. Microsoft empfiehlt, Rechner zuerst in die Domäne aufzunehmen und erst danach BitLocker einzuschalten; danach geschieht die Sicherung automatisch. Wurde BitLocker vor der Richtlinie aktiviert, wird nichts nachträglich gesichert.

Das Beispiel zeigt die Richtlinie und – wichtiger – das Nachsichern bestehender Rechner mit den von Microsoft dokumentierten Befehlen. Die Registrywerte (`OSActiveDirectoryBackup` und verwandte) stammen aus meiner Kenntnis der ADMX-Vorlage und sollten gegen den Editor geprüft werden; die Nachsicherung nutzt Cmdlets aus der Microsoft-Dokumentation. Die Nachsicherung verändert Active Directory (sie schreibt Attribute am Computerobjekt) und sollte mit dem AD-Team abgestimmt sein.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "BL-Recovery-AD"
$key = "HKLM\SOFTWARE\Policies\Microsoft\FVE"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName OSRecovery -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName OSManageDRA -Type DWord -Value 0
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName OSRecoveryPassword -Type DWord -Value 2
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName OSActiveDirectoryBackup -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName OSActiveDirectoryInfoToStore -Type DWord -Value 1

# Bestehende Rechner: Recovery-Passwort nachsichern (auf dem Client, als Admin)
$prot = (Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector |
        Where-Object KeyProtectorType -eq 'RecoveryPassword'
foreach ($p in $prot) {
    Backup-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId $p.KeyProtectorId
}
```

Die GPO-Werte entsprechen den Auswahlfeldern: Wiederherstellungsoptionen konfigurieren, keine Wiederherstellungsagenten verwalten, Wiederherstellungskennwort erlaubt, Sicherung in AD DS aktiv, und „Kennwort und Schlüsselpaket“ als Informationsumfang (Wert 1). Der zweite Teil sucht am Client alle Schlüsselschützer vom Typ `RecoveryPassword` und sichert jeden mit `Backup-BitLockerKeyProtector`. Der Befehl stammt aus der Microsoft-Dokumentation (Operations-Guide). Der Vollständigkeit halber nennt Microsoft auch den Weg `manage-bde -protectors -adbackup`.

**Typische Fehler.** Falsch ist, anzunehmen, dass die Richtlinie bereits verschlüsselte Rechner rückwirkend sichert. Laut Microsoft tut sie das nicht, es braucht ein Nachsichern per Skript. Ein zweiter Fehler: die Berechtigungen im Active Directory zu vergessen. Wenn der Rechner das Attribut nicht schreiben darf, scheitert die Sicherung; die Prüfung erfolgt über das Computerobjekt und den Recovery-Password-Viewer. Dritter Fehler: ein Wiederherstellungskennwort nach der Benutzung nicht zu erneuern. Microsoft empfiehlt, ein verwendetes Kennwort ungültig zu machen und ein neues zu erzeugen und zu sichern (Entfernen und Hinzufügen des Schützers).

> **Praxisbeispiel**
>
> Beispielszenario: Nach einem BIOS-Update fragt ein Notebook im Außendienst nach dem Wiederherstellungsschlüssel. Der Helpdesk sucht das Computerobjekt in Active Directory, liest das 48-stellige Kennwort aus dem Reiter „BitLocker-Wiederherstellung“ und gibt es nach Identitätsprüfung telefonisch durch. Danach wird das Kennwort rotiert, damit der jetzt bekannte Schlüssel nicht erneut gilt.

## 23 BitLocker ohne Recovery Backup verhindern

| **Feld**        | **Steckbrief**                                                                                               |
|:----------------|:-------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> BitLocker-Laufwerkverschlüsselung |
| Einstellung     | BitLocker erst aktivieren, wenn Wiederherstellungsinformationen gespeichert sind                             |
| Empfehlung      | Aktiviert                                                                                                    |
| Ziel / Zweck    | Verhindert Datenverlust durch fehlende Recovery Keys                                                         |
| Zielbereich     | Computer                                                                                                     |
| Priorität       | 1                                                                                                            |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                  |

Abschnitt 22 sorgt dafür, dass Wiederherstellungsinformationen gesichert *werden*. Abschnitt 23 sorgt dafür, dass BitLocker nur startet, wenn die Sicherung *gelungen ist*. Technisch ist das ein Kontrollkästchen in derselben Richtlinie: „Do not enable BitLocker until recovery information is stored in AD DS for operating system drives“. Wenn es aktiviert ist, kann ein Benutzer BitLocker nur einschalten, wenn der Rechner mit der Domäne verbunden ist und die Sicherung nach AD DS erfolgreich war. Schlägt die Sicherung fehl, bleibt BitLocker aus. Der Zweck ist einfach: Es gibt keine verschlüsselten Laufwerke, für die niemand den Schlüssel hat.

Microsoft erklärt die Grenzen in den FAQ: Wenn die Sicherung anfangs scheitert (zum Beispiel weil kein Domänencontroller erreichbar ist), versucht BitLocker es *nicht erneut*. Mit dem Kontrollkästchen verhindert man genau diese Situation, weil BitLocker dann gar nicht erst aktiviert wird. Beim Aktivieren wird automatisch ein Wiederherstellungskennwort erzeugt. Nach der Anleitung gilt außerdem: Die Rotation des Wiederherstellungskennworts nach der Verwendung (Einstellung „Configure recovery password rotation“) wirkt nur, wenn diese Pflichtsicherung konfiguriert ist; diese Rotation gibt es laut Microsoft nur über CSP, nicht als Gruppenrichtlinie.

> **Merke**
>
> Zwei Richtlinien, ein Ziel: Abschnitt 22 sagt „sichere die Schlüssel“, Abschnitt 23 sagt „ohne Sicherung keine Verschlüsselung“. Beide stehen in derselben Richtlinie „Choose how BitLocker-protected operating system drives can be recovered“. Für feste und für Wechsel-Datenlaufwerke gibt es jeweils eigene Richtlinien mit demselben Kontrollkästchen.

Das folgende Beispiel ergänzt die GPO aus Abschnitt 22 um die Pflichtsicherung und zeigt ein Prüfskript für Clients. Die Registrywerte stammen aus meiner Kenntnis der ADMX-Vorlage und gehören im Pilot geprüft; die Wirkung des Kontrollkästchens ist in der Microsoft-Dokumentation beschrieben. Das Skript liest nur Daten und ändert nichts.

```ps
# Pflichtsicherung vor BitLocker-Aktivierung (OS-Laufwerk)
Set-GPRegistryValue -Name "BL-Recovery-AD" `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\FVE" `
    -ValueName OSRequireActiveDirectoryBackup -Type DWord -Value 1

# Pruefskript fuer Clients: Welche Rechner sind verschluesselt, aber ohne Recovery-Passwort?
$v = Get-BitLockerVolume -MountPoint $env:SystemDrive
$hatRecovery = [bool]($v.KeyProtector | Where-Object KeyProtectorType -eq 'RecoveryPassword')
[pscustomobject]@{
    Computer      = $env:COMPUTERNAME
    Status        = $v.VolumeStatus
    RecoveryPW    = $hatRecovery
}
```

Die erste Anweisung fügt der bestehenden GPO den Wert `OSRequireActiveDirectoryBackup` hinzu. Das Prüfskript fragt das Systemlaufwerk ab und gibt Rechnernamen, Verschlüsselungsstatus und ein Kennzeichen aus, ob ein Wiederherstellungskennwort-Schützer existiert. Die Ausgabe kann zentral (zum Beispiel über Remoting oder ein Inventarwerkzeug) gesammelt werden. Der Abgleich mit dem Active Directory (existiert am Computerobjekt ein Wiederherstellungsobjekt?) ist ein zweiter, getrennter Schritt.

**Typische Fehler.** Falsch: die Pflichtsicherung auf Geräten zu erzwingen, die selten im Büro sind. Notebooks ohne Domänenverbindung (zum Beispiel im Homeoffice ohne VPN beim ersten Start) können BitLocker dann nicht aktivieren und bleiben unverschlüsselt. Richtig: Entra-Join oder Always-On-VPN so einplanen, dass die Sicherung beim Einrichten möglich ist, oder BitLocker im Auslieferungsprozess vor der Auslieferung aktivieren. Zweiter Fehler: Geräte mit Hardwareverschlüsselung nicht zu beachten; laut Microsoft werden bei selbstverschlüsselnden Laufwerken die Einstellungen zur Verschlüsselungsmethode ignoriert. Dritter Fehler: Pflichtsicherung zu aktivieren, ohne die AD-Berechtigungen vorher geprüft zu haben (siehe Abschnitt 22).

> **Praxisbeispiel**
>
> Beispielszenario: Nach der Einführung der Pflichtsicherung melden fünf Außendienstler, dass sich BitLocker „nicht einschalten“ lässt. Ursache: Sie waren beim Einrichten nicht im Firmennetz. Der Helpdesk bittet sie, sich einmalig mit VPN zu verbinden; danach läuft die Verschlüsselung.

## 24 Wechseldatenträger verschlüsseln

| **Feld**        | **Steckbrief**                                                                                                                        |
|:----------------|:--------------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> BitLocker-Laufwerkverschlüsselung \> Wechseldatenlaufwerke |
| Einstellung     | Verwendung von BitLocker auf Wechseldatenlaufwerken steuern                                                                           |
| Empfehlung      | Aktiviert                                                                                                                             |
| Ziel / Zweck    | Schützt Daten auf USB-Medien                                                                                                          |
| Zielbereich     | Computer                                                                                                                              |
| Priorität       | 2                                                                                                                                     |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                           |

USB-Sticks und externe Festplatten gehen noch leichter verloren als Notebooks. *BitLocker To Go* nennt Microsoft die Verschlüsselung für Wechseldatenträger. Die Richtlinie „Control use of BitLocker on removable drives“ (deutsch etwa: Verwendung von BitLocker auf Wechseldatenlaufwerken steuern) legt fest, ob und wie Benutzer BitLocker auf solchen Laufwerken anwenden dürfen. Laut Microsoft kann man damit erlauben, dass Benutzer BitLocker-Schutz anwenden, und getrennt davon, dass sie die Verschlüsselung anhalten oder entfernen dürfen. Wird die Richtlinie deaktiviert, können Benutzer BitLocker auf Wechseldatenträgern gar nicht nutzen.

Diese Richtlinie allein verschlüsselt noch nichts, sie *erlaubt* die Verschlüsselung und bereitet die Verwendung vor. Die eigentliche Pflicht entsteht erst durch Abschnitt 25 (Schreibzugriff nur auf verschlüsselte Datenträger). In einer Gesamtlösung gehören vier Richtlinien zusammen: die Nutzung erlauben (Abschnitt 24), Kennwortregeln für Wechseldatenträger festlegen („Configure use of passwords for removable data drives“), Wiederherstellung regeln („Choose how BitLocker-protected removable drives can be recovered“) und den Schreibzugriff beschränken (Abschnitt 25). Laut Microsoft müssen Kennwörter für Wechseldatenträger mindestens acht Zeichen haben, und die Komplexitätsprüfung benötigt zusätzlich die Richtlinie „Kennwort muss Komplexitätsanforderungen entsprechen“ (Abschnitt 3).

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft werden die Kennwortvorgaben nur beim Einschalten von BitLocker durchgesetzt, nicht beim Entsperren: BitLocker erlaubt das Entsperren mit jedem vorhandenen Schützer. Mit „Require complexity“ braucht der Rechner beim Aktivieren eine Verbindung zu einem Domänencontroller. Kennwörter als Schützer sind laut Microsoft nicht möglich, wenn per Gruppenrichtlinie FIPS-konforme Algorithmen erzwungen werden. Die Verschlüsselungsart (vollständig oder nur belegter Speicherplatz) ist über „Enforce drive encryption type on removable data drives“ wählbar.

Das Beispiel zeigt die Basisrichtlinie und – auf einem Testrechner – die Verschlüsselung eines USB-Sticks mit Kennwort und gesichertem Wiederherstellungskennwort. Die Registrywerte sind aus meiner Kenntnis der ADMX-Vorlage abgeleitet. Die Verschlüsselung formatiert den Stick nicht, sie kann aber bei einem Abbruch zu Problemen führen; nutzen Sie einen Teststick ohne wichtige Daten.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "BL-Wechseldatentraeger"
$key = "HKLM\SOFTWARE\Policies\Microsoft\FVE"

# BitLocker auf Wechsellaufwerken erlauben (Benutzer duerfen anwenden)
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName RDVConfigureBDE -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName RDVAllowBDE     -Type DWord -Value 1

# Kennwort als Schutz verlangen, Mindestlaenge 12
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName RDVPassphrase           -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName RDVPassphraseLength     -Type DWord -Value 12

# Testgeraet: Stick E: verschluesseln
$pw = Read-Host "Kennwort fuer den Stick" -AsSecureString
Enable-BitLocker -MountPoint "E:" -PasswordProtector -Password $pw -UsedSpaceOnly
Add-BitLockerKeyProtector -MountPoint "E:" -RecoveryPasswordProtector
```

Die ersten beiden Werte erlauben BitLocker für Wechseldatenträger, die nächsten beiden verlangen ein Kennwort mit Mindestlänge 12. Auf dem Testrechner verschlüsselt `Enable-BitLocker` den Stick mit Kennwortschutz und nur dem belegten Speicherplatz (`-UsedSpaceOnly`); `Add-BitLockerKeyProtector` ergänzt ein Wiederherstellungskennwort. Dieses muss gespeichert werden (Abschnitt 22); die Wiederherstellungsrichtlinie für Wechsellaufwerke sorgt dafür, dass es nach AD DS gesichert wird.

**Typische Fehler.** Falsch: davon auszugehen, dass auf anderen Rechnern ohne BitLocker (etwa bei Kunden oder auf Fremd-PCs) alles lesbar ist. Verschlüsselte Sticks lassen sich unter aktuellen Windows-Versionen lesen, aber auf Macs oder Linux nicht ohne Zusatzsoftware. Richtig: bei externen Datenaustauschwegen eine alternative Lösung (verschlüsselte Container oder Dateiaustausch) vorsehen. Zweiter Fehler: „UsedSpaceOnly“ für Sticks zu nutzen, auf denen früher vertrauliche Daten lagen; gelöschte Daten im freien Bereich bleiben dann unverschlüsselt (laut Microsoft kann der freie Speicher mit `manage-bde -w` nachträglich gewischt werden). Dritter Fehler: die Verschlüsselung auf einem Stick zu aktivieren und das Kennwort nirgends zu hinterlegen.

> **Praxisbeispiel**
>
> Beispielszenario: Eine Behörde verteilt zehn verschlüsselte USB-Sticks an Außendienstmitarbeiter. Für jeden Stick ist ein Wiederherstellungskennwort im AD gesichert, und die Mitarbeiter wissen, dass sie das Kennwort nicht auf dem Stick notieren dürfen.

## 25 Schreibzugriff auf unverschlüsselte USB-Datenträger verweigern

| **Feld**        | **Steckbrief**                                                                                                                        |
|:----------------|:--------------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> BitLocker-Laufwerkverschlüsselung \> Wechseldatenlaufwerke |
| Einstellung     | Schreibzugriff auf nicht BitLocker-geschützte Wechseldatenträger verweigern                                                           |
| Empfehlung      | Aktiviert                                                                                                                             |
| Ziel / Zweck    | Erzwingt Verschlüsselung für mobile Daten                                                                                             |
| Zielbereich     | Computer                                                                                                                              |
| Priorität       | 2                                                                                                                                     |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                           |

Nachdem Abschnitt 24 die Verschlüsselung möglich gemacht hat, macht diese Richtlinie sie zur Pflicht. Ist sie aktiviert, werden alle Wechseldatenträger, die nicht mit BitLocker geschützt sind, *schreibgeschützt* eingebunden. Geschützte Laufwerke werden mit Lese- und Schreibzugriff eingebunden. Der Benutzer sieht den Inhalt eines fremden Sticks weiterhin, kann aber nichts daraufspeichern, es sei denn, er verschlüsselt ihn zuerst; laut Intune-Dokumentation muss er dazu den BitLocker-Einrichtungsassistenten abschließen, bevor Schreibzugriff gewährt wird.

Zwei Optionen erweitern die Regel. Mit „Schreibzugriff auf Geräte verweigern, die in einer anderen Organisation konfiguriert wurden“ darf man nur auf Laufwerke schreiben, deren *Identifikationsfeld* zur eigenen Organisation passt. Das Feld wird über die Richtlinie „Provide the unique identifiers for your organization“ gesetzt und mit `manage-bde.exe` auf Laufwerke geschrieben; ein Wert darf bis zu 260 Zeichen lang sein. So verhindert man, dass Mitarbeiter vertrauliche Daten auf BitLocker-Sticks eines Dritten kopieren, auf denen sie nicht kontrollieren können, wer sie lesen kann.

> **Merke**
>
> Wichtige Abhängigkeiten laut Microsoft: Wird diese Richtlinie aktiviert, muss die Verwendung von TPM-Startschlüssel und PIN sowie die Verwendung von Wiederherstellungsschlüsseln für Wechseldatenträger *nicht erlaubt* sein. Außerdem wird die Richtlinie ignoriert, wenn „Removable Disks: Deny write access“ aus dem Bereich „System \> Wechselspeicherzugriff“ aktiv ist (Abschnitt 93, Modul 10).

Das Beispiel setzt die Richtlinie samt Identifikationsfeld und zeigt, wie man das Feld auf einem Stick setzt. Die Registrywerte (`RDVDenyWriteAccess`, `RDVDenyCrossOrg`) stammen teilweise aus der Policy-CSP-Dokumentation (für den Wert `RDVDenyWriteAccess` unter dem FVE-Schlüssel) und teilweise aus meiner Kenntnis; `DiscoveryVolumeType` und das Identifikationsfeld sind im Pilot gegen den Editor zu prüfen. Die Firma „Muster-GmbH“ ist ein Platzhalter.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "BL-USB-Schreibschutz"
$key = "HKLM\SOFTWARE\Policies\Microsoft\FVE"

# Unverschluesselte Wechseldatentraeger nur lesend
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName RDVDenyWriteAccess -Type DWord -Value 1
# Fremde Organisationen: kein Schreibzugriff
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName RDVDenyCrossOrg    -Type DWord -Value 1
# Eigenes Identifikationsfeld
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName IdentificationField        -Type String -Value "Muster-GmbH"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName AllowedIdentificationField -Type String -Value "Muster-GmbH"

# Auf einem Teststick das Identifikationsfeld setzen
manage-bde -SetIdentifier E:
manage-bde -Status E:
```

Die ersten beiden Werte entsprechen den Optionen der Richtlinie. Die beiden Zeichenfolgen bilden die Richtlinie „Provide the unique identifiers“ ab: Das Identifikationsfeld wird auf neue Laufwerke geschrieben, das erlaubte Feld bestimmt, welche Laufwerke als „eigene“ gelten. `manage-bde -SetIdentifier` schreibt das konfigurierte Feld auf einen bestehenden Stick, `manage-bde -Status` zeigt es an.

**Typische Fehler.** Falsch: die Richtlinie aktivieren, ohne die Benutzer zu informieren. Sie sehen „Zugriff verweigert“ beim Kopieren und wissen nicht warum. Richtig: eine Anleitung und eine kurze Schulung vor dem Rollout. Zweiter Fehler: die Richtlinie in Kombination mit der Sperre aus Abschnitt 93 zu planen, ohne zu bedenken, dass die Sperre Vorrang hat (BitLocker-Regel wird dann ignoriert). Dritter Fehler: Wiederherstellungsschlüssel für Wechseldatenträger zuzulassen, während die Richtlinie aktiv ist; das ist laut Microsoft ausdrücklich nicht zulässig.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Mitarbeiter will Dateien auf den Stick eines Kunden kopieren. Der Stick ist unverschlüsselt, und die Richtlinie lässt das Schreiben nicht zu. Der Mitarbeiter nutzt stattdessen den freigegebenen Dateiaustauschdienst. Die Datenabflusskontrolle funktioniert, ohne dass ein Administrator eingreifen muss.

## 26 VBS aktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> Device Guard                  |
| Einstellung     | Virtualisierungsbasierte Sicherheit aktivieren                                              |
| Empfehlung      | Aktiviert                                                                                   |
| Ziel / Zweck    | Aktiviert isolierte Sicherheitsfunktionen                                                   |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

*Virtualisierungsbasierte Sicherheit* (englisch *Virtualization-Based Security*, VBS) nutzt den Hypervisor von Windows, um einen kleinen, isolierten Bereich im Arbeitsspeicher zu schaffen, auf den das normale Betriebssystem nicht zugreifen kann, auch nicht mit Administratorrechten. In diesem Bereich laufen Sicherheitsfunktionen, die Angreifer sonst auf dem normalen Weg angreifen würden. VBS ist die Grundlage für mehrere Funktionen: Credential Guard (Abschnitt 27), die Speicherintegrität (*memory integrity*, auch *HVCI*, Hypervisor-protected code integrity) und weitere. Laut Microsoft wird VBS durch das Konfigurieren dieser Funktionen mit aktiviert; es genügt also, eine davon zu setzen.

In der Gruppenrichtlinie heißt die Einstellung „Turn on Virtualization Based Security“ (Device Guard). Dort wählt man die Plattformsicherheitsstufe, also „Secure Boot“ oder „Secure Boot und DMA-Schutz“, und kann die Speicherintegrität („Virtualization Based Protection of Code Integrity“) einschalten, entweder *mit* oder *ohne* UEFI-Sperre. Laut Microsoft wählt man „Enabled without UEFI lock“, wenn man die Funktion später per Richtlinie wieder abschalten können will; „with UEFI lock“ verhindert das Abschalten per Richtlinie oder aus der Ferne, und man braucht dann Zugriff auf das UEFI-BIOS. Für die Pilotphase ist daher immer die Variante *ohne* Sperre zu empfehlen. Microsoft empfiehlt für die Plattformsicherheit in den meisten Fällen „Secure Boot“; „Secure Boot mit DMA“ aktiviert VBS nur auf Rechnern mit IOMMU.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft müssen alle Treiber auf dem System mit der Speicherintegrität kompatibel sein, sonst kann das System ausfallen; man soll die Funktion zuerst auf einer Testgruppe aktivieren. Der Modus „Mandatory“ verhindert den Systemstart, wenn Hypervisor oder Secure Kernel nicht laden; Microsoft warnt vor besonderer Vorsicht. Zur Wiederherstellung bei Startproblemen: Richtlinie deaktivieren, in die Windows-Wiederherstellungsumgebung booten und den Registrywert `Enabled` unter `HypervisorEnforcedCodeIntegrity` auf 0 setzen; bei UEFI-Sperre muss zusätzlich Secure Boot abgeschaltet werden. Laut Microsoft werden VBS und Credential Guard ab Windows 11 22H2 auf Geräten, die die Systemanforderungen erfüllen, standardmäßig aktiviert.

Das Beispiel legt die GPO an und prüft den Zustand am Client mit dem von Microsoft dokumentierten CIM-Befehl. Es verwendet die Registrywerte aus der Microsoft-Dokumentation zur Speicherintegrität (hier im Policy-Pfad nach meiner Kenntnis der ADMX-Vorlage). Neustart erforderlich; die Pilotgruppe sollte nur kompatible Hardware enthalten.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "SEC-VBS"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard"

Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName EnableVirtualizationBasedSecurity -Type DWord -Value 1
# 1 = Secure Boot, 3 = Secure Boot mit DMA-Schutz
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName RequirePlatformSecurityFeatures   -Type DWord -Value 1
# Speicherintegritaet (HVCI) ohne UEFI-Sperre
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName HypervisorEnforcedCodeIntegrity  -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName Locked                           -Type DWord -Value 0

# Am Client nach dem Neustart: laeuft VBS?
Get-CimInstance -Namespace 'root/Microsoft/Windows/DeviceGuard' -ClassName Win32_DeviceGuard |
    Select-Object VirtualizationBasedSecurityStatus, SecurityServicesRunning, SecurityServicesConfigured
```

Die vier Werte bilden die Einstellung ab: VBS an, Plattformsicherheit Secure Boot, Speicherintegrität an und keine UEFI-Sperre. Der CIM-Aufruf stammt aus der Microsoft-Dokumentation und zeigt den Status; der Wert 2 bei `VirtualizationBasedSecurityStatus` bedeutet nach meiner Kenntnis „läuft“ (1 = aktiviert, aber nicht gestartet, 0 = aus). `SecurityServicesRunning` listet die laufenden Dienste (zum Beispiel 1 für Credential Guard, 2 für Speicherintegrität).

**Typische Fehler.** Falsch: VBS flächendeckend zu aktivieren, ohne Hardware und Treiber zu prüfen. Inkompatible Treiber (alte Gerätetreiber, bestimmte Sicherheits- oder Virtualisierungssoftware) führen zu Startfehlern oder abgeschalteter Speicherintegrität. Richtig: eine Pilotgruppe mit der typischen Hardwarevielfalt und das Windows-Sicherheitsprotokoll auf inkompatible Treiber prüfen. Zweiter Fehler: Aktivierung mit UEFI-Sperre in der Pilotphase; ein Rückzug ist dann nur mit BIOS-Zugriff möglich. Dritter Fehler: auf virtuellen Maschinen oder älteren Geräten VBS zu erzwingen, ohne dass die Hardware-Virtualisierung dafür aktiviert ist.

> **Praxisbeispiel**
>
> Beispielszenario: Nach der Aktivierung meldet ein Konstruktionsbüro, dass eine Lizenzdongle-Software nicht mehr startet. Ursache: ein alter Treiber ist mit der Speicherintegrität inkompatibel. Der Hersteller liefert einen neuen Treiber; bis dahin bleibt die Gruppe in einer Ausnahme-OU.

## 27 Credential Guard aktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> Device Guard                  |
| Einstellung     | Virtualisierungsbasierte Sicherheit aktivieren                                              |
| Empfehlung      | Aktiviert mit Credential Guard                                                              |
| Ziel / Zweck    | Schützt Anmeldeinformationen vor Diebstahl                                                  |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Wer sich an Windows anmeldet, hinterlässt im Arbeitsspeicher des Prozesses LSASS (*Local Security Authority Subsystem Service*) Geheimnisse: NTLM-Hashes, Kerberos-Tickets (*Ticket-Granting Tickets*) und gespeicherte Domänenanmeldeinformationen. Angriffswerkzeuge lesen sie aus und nutzen sie auf anderen Rechnern weiter (*Pass-the-Hash*, *Pass-the-Ticket*). *Credential Guard* verschiebt diese Geheimnisse in den durch VBS isolierten Bereich. Laut Microsoft kommuniziert der LSA-Prozess dann mit dem isolierten Prozess `LSAIso.exe`, der die Geheimnisse hält; seine Daten sind für den Rest des Betriebssystems nicht zugänglich.

In der Gruppenrichtlinie ist Credential Guard Teil der Einstellung „Turn On Virtualization Based Security“: Dort wählt man in der Liste „Credential Guard Configuration“ entweder „Enabled with UEFI lock“ oder „Enabled without lock“. Laut Microsoft wählt man die Variante *ohne* Sperre, wenn man Credential Guard später aus der Ferne abschalten können möchte; nach Anwenden der Richtlinie ist ein Neustart nötig. Ein wichtiger Hinweis aus der Dokumentation: Credential Guard sollte aktiviert werden, bevor ein Gerät der Domäne beitritt oder sich ein Domänenbenutzer zum ersten Mal anmeldet. Wird es erst danach aktiviert, können Benutzer- und Gerätegeheimnisse bereits kompromittiert sein.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft werden ab Windows 11 22H2 VBS und Credential Guard auf allen Geräten standardmäßig aktiviert, die die Systemanforderungen erfüllen; Credential Guard wird nur auf 64-Bit-Geräten mit Secure Boot unterstützt. Zusätzlich gibt es „Machine Identity Isolation“ (Credential Guard für Computerkonto-Anmeldeinformationen) mit den Modi Audit und Enforcement. Im Enforcement-Modus wird das Computerkontogeheimnis in Credential Guard verschoben; startet Credential Guard nach einem Neustart nicht, kann die Domänenanmeldung scheitern und ein lokaler Administrator muss eingreifen. Wird der Enforcement-Modus abgeschaltet, muss der Rechner aus der Domäne genommen und neu aufgenommen werden.

Das Beispiel zeigt die Registrywerte der Richtlinie und die Prüfung am Client. Der Wert `LsaCfgFlags` mit 1 für „mit UEFI-Sperre“ und 2 für „ohne Sperre“ stammt aus der Microsoft-Dokumentation (DeviceGuard-CSP); der Registrypfad der Gruppenrichtlinie ist nach meiner Kenntnis `Policies\Microsoft\Windows\DeviceGuard`. Verwenden Sie in der Pilotphase die Variante ohne Sperre.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "SEC-CredentialGuard"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard"

Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName EnableVirtualizationBasedSecurity -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName RequirePlatformSecurityFeatures   -Type DWord -Value 1
# Credential Guard: 2 = aktiviert ohne UEFI-Sperre, 1 = mit UEFI-Sperre
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName LsaCfgFlags                       -Type DWord -Value 2

# Am Client nach Neustart pruefen
(Get-CimInstance -Namespace 'root/Microsoft/Windows/DeviceGuard' -ClassName Win32_DeviceGuard).SecurityServicesRunning
Get-Process -Name LsaIso -ErrorAction SilentlyContinue | Select-Object Name, Id
```

Die ersten beiden Werte aktivieren VBS (Abschnitt 26); `LsaCfgFlags = 2` aktiviert Credential Guard ohne UEFI-Sperre. Am Client zeigt `SecurityServicesRunning` die laufenden Dienste (der Wert 1 steht nach meiner Kenntnis für Credential Guard), und die Existenz des Prozesses `LsaIso` belegt, dass der isolierte LSA-Prozess läuft.

**Typische Fehler.** Falsch: Credential Guard mit UEFI-Sperre zu aktivieren und danach festzustellen, dass ein Rückbau Zugang zum BIOS jedes Geräts braucht. Richtig: zuerst ohne Sperre pilotieren. Zweiter Fehler: Anwendungen zu übersehen, die Anmeldeinformationen auslesen müssen, etwa ältere Single-Sign-On-Lösungen, Authentifizierung per NTLMv1, unconstrained delegation oder bestimmte VPN-Clients. Solche Anwendungen funktionieren mit Credential Guard nicht mehr, was gerade der Zweck der Funktion ist. Dritter Fehler: anzunehmen, Credential Guard schütze vor jedem Angriff. Es schützt Hashes und Tickets, nicht vor Keyloggern oder vor Missbrauch der Sitzung eines angemeldeten Benutzers.

> **Praxisbeispiel**
>
> Beispielszenario: Nach der Einführung zeigt ein Angriffssimulationswerkzeug, dass das Auslesen von Hashes aus LSASS auf Clients nicht mehr funktioniert. Die laterale Bewegung des Angreifers im Test scheitert an der Übernahme des ersten Administratorkontos.

## 28 LSA-Schutz aktivieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> Lokale Sicherheitsautorität   |
| Einstellung     | LSASS als geschützten Prozess ausführen                                                     |
| Empfehlung      | Aktiviert                                                                                   |
| Ziel / Zweck    | Härtet Credential-Schutz                                                                    |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Der *LSA-Schutz* (*Local Security Authority protection*) läuft nicht in einem Hypervisor-isolierten Bereich wie Credential Guard, sondern macht LSASS zu einem *geschützten Prozess* (*Protected Process Light*, PPL). Das Betriebssystem erlaubt dann nur Code in LSASS, der von Microsoft signiert ist, und verhindert, dass andere Prozesse (auch Administratorprozesse) den Speicher auslesen oder Code einschleusen. Laut Microsoft schützt der LSA-Schutz vor Diebstahl von Geheimnissen, indem er unsichere LSA-Codeeinschleusung und Speicherabbilder blockiert. LSA-Schutz und Credential Guard ergänzen sich, und Systeme, die Credential Guard unterstützen, können zusätzlich LSA-Schutz nutzen.

Die Einstellung „Configures LSASS to run as a protected process“ gibt es ab Windows 11 22H2 als Gruppenrichtlinie mit zwei Optionen: „Enabled with UEFI Lock“ (Wert `RunAsPPL = 1`, mit einer UEFI-Variablen, die sich nicht per Registry oder Richtlinie ändern lässt) und „Enabled without UEFI Lock“ (`RunAsPPL = 2`). Auf Geräten mit neuer Installation von Windows 11 22H2 oder neuer ist die Funktion laut Microsoft automatisch aktiviert, wenn das Gerät in einem Unternehmensverbund (AD, Entra oder hybrid) ist und HVCI-fähig; dabei wird keine UEFI-Variable gesetzt. Für Upgrades gibt es laut Microsoft eine Auswertungsphase von fünf Tagen und danach nach einem Neustart die Aktivierung; Unternehmensrichtlinien übersteuern dieses Verhalten.

> **Ergänzung aus der Nachrecherche**
>
> Vor der Aktivierung sollte man den *Auditmodus* verwenden. Laut Microsoft ist er auf Windows 11 22H2 und neuer standardmäßig aktiv und schreibt Ereignisse im CodeIntegrity-Log, welche LSA-Plug-ins und Treiber im geschützten Modus nicht laden würden. Auf Geräten mit aktivierter Smart App Control werden keine Audit-Ereignisse erzeugt. Das Debuggen eigener LSA-Plug-ins ist mit aktivem Schutz nicht möglich. Zum Deaktivieren per Richtlinie muss die Option „Disabled“ gesetzt werden; „Nicht konfiguriert“ entfernt eine frühere Einstellung nicht.

Das folgende Beispiel richtet den Schutz per Gruppenrichtlinien-Registry ein und liest das Ereignis, das den erfolgreichen Start als geschützter Prozess belegt. Registrypfad und Wert stammen aus der Microsoft-Dokumentation (`HKLM\SYSTEM\CurrentControlSet\Control\Lsa`, `RunAsPPL`); die Gruppenrichtlinie schreibt den Wert über die Einstellungen-Funktion (*Preferences*) beziehungsweise die neue Richtlinie. Neustart erforderlich.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "SEC-LSA-Schutz"

# Wie von Microsoft beschrieben: RunAsPPL im Lsa-Schluessel (2 = ohne UEFI-Variable)
Set-GPPrefRegistryValue -Name $gpo.DisplayName -Context Computer -Action Update `
    -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" `
    -ValueName RunAsPPL -Type DWord -Value 2

# Am Client: Wurde LSASS als geschuetzter Prozess gestartet? (WinInit-Ereignis 12)
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Wininit'; Id=12} `
    -MaxEvents 3 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Message

# Audit: Plug-ins/Treiber, die nicht laden koennten (CodeIntegrity-Log)
Get-WinEvent -LogName 'Microsoft-Windows-CodeIntegrity/Operational' -MaxEvents 20 -ErrorAction SilentlyContinue |
    Where-Object Message -match 'lsass' | Select-Object TimeCreated, Id, Message
```

`Set-GPPrefRegistryValue` legt einen Registry-Eintrag in den Einstellungen (*Preferences*) der GPO an; so beschreibt es Microsoft für die Gruppenrichtlinienvariante (Computerkonfiguration \> Einstellungen \> Windows-Einstellungen \> Registrierung). Das System-Ereignis 12 („LSASS.exe was started as a protected process with level: 4“) belegt laut Microsoft den Erfolg. Die dritte Abfrage filtert Audit-Ereignisse zu LSASS; die genaue Ereignis-ID ist im Pilot am Beispiel zu bestimmen.

**Typische Fehler.** Falsch: LSA-Schutz zu aktivieren, ohne zuvor Plug-ins und Treiber (Smartcard-Treiber, Passwortfilter, Kryptoplug-ins) zu inventarisieren; unsignierte Komponenten laden dann nicht, und Anmeldungen schlagen fehl. Richtig: Auditmodus auswerten, alle Plug-ins mit Microsoft-Signatur versehen oder ersetzen. Zweiter Fehler: UEFI-Sperre in der Pilotphase. Zum Entfernen der UEFI-Variablen braucht man laut Microsoft ein eigenes Werkzeug, und es kann das Zurücksetzen von Secure Boot erfordern. Dritter Fehler: die Richtlinie auf „Nicht konfiguriert“ zu setzen, um sie zurückzunehmen: Sie bleibt wirksam.

> **Praxisbeispiel**
>
> Beispielszenario: In einem Unternehmen mit Smartcard-Anmeldung zeigt das Audit-Protokoll, dass ein älterer Smartcard-Treiber nicht signiert ist. Der Hersteller liefert eine neue Version; erst danach wird der LSA-Schutz im Pilot verpflichtend.

## 29 Windows Hello for Business erzwingen

| **Feld**        | **Steckbrief**                                                                                        |
|:----------------|:------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Windows Hello for Business |
| Einstellung     | Windows Hello for Business verwenden                                                                  |
| Empfehlung      | Aktiviert                                                                                             |
| Ziel / Zweck    | Fördert starke, phishingresistentere Anmeldung                                                        |
| Zielbereich     | Computer/User                                                                                         |
| Priorität       | 2                                                                                                     |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.           |

Kennwörter lassen sich erraten, abfangen und per Phishing erbeuten. *Windows Hello for Business* (WHfB) ersetzt das Kennwort bei der Anmeldung durch einen Schlüsselpaar-Mechanismus: Auf dem Gerät wird ein privater Schlüssel erzeugt, bevorzugt im TPM, und der Benutzer entsperrt ihn mit einer PIN oder einem biometrischen Merkmal. Die PIN gilt nur auf diesem Gerät und wird nicht übertragen; ein Angreifer, der sie abfängt, kann sie auf einem anderen Gerät nicht verwenden. Dadurch ist die Anmeldung deutlich resistenter gegen Phishing. Der Lehrplan nennt das „phishingresistentere“ Anmeldung; „resistenter“ ist hier die richtige Wortwahl, denn gegen jeden Angriff schützt auch Hello nicht.

Die Gruppenrichtlinie „Use Windows Hello for Business“ gibt es laut Microsoft sowohl in der Computer- als auch in der Benutzerkonfiguration. Die Computerseite führt dazu, dass *alle* Benutzer, die sich an den Zielgeräten anmelden, die Einrichtung versuchen. Die Benutzerseite betrifft nur die Zielbenutzer. Sind beide konfiguriert, hat die Benutzereinstellung Vorrang. Eine zweite empfohlene Einstellung ist „Use a hardware security device“ (Computerkonfiguration), die verlangt, dass der Schlüssel im TPM liegt.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft ist die beste Methode für die Verteilung, die GPO an die Domäne zu verknüpfen und über die *Sicherheitsgruppenfilterung* nur die Mitglieder einer Zielgruppe zu erfassen; so ist ein gestaffelter Rollout möglich. Je nach Vertrauensmodell sind weitere Einstellungen nötig: beim *Cloud Kerberos Trust* (hybrid) die Richtlinie „Use cloud Kerberos trust for on-premises authentication“ (nur Computerkonfiguration; die Datei `Passport.admx` muss aktuell sein); beim On-Premises-Certificate-Trust zusätzlich „Use certificate for on-premises authentication“ und die automatische Zertifikatregistrierung. Wird Windows Hello sowohl per Gruppenrichtlinie als auch per Intune konfiguriert, haben die Gruppenrichtlinien Vorrang.

Das Beispiel richtet WHfB für einen hybriden Cloud-Kerberos-Trust-Betrieb ein. Es verwendet die in der Dokumentation genannten Einstellungsnamen; die Registrywerte (`Enabled`, `RequireSecurityDevice`, `UseCloudTrustForOnPremAuth`) im Schlüssel `Policies\Microsoft\PassportForWork` stammen aus meiner Kenntnis der ADMX-Datei `Passport.admx` und sind im Pilot zu prüfen. Das Skript legt nur die GPO an und verlinkt sie nicht.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "SEC-WHfB"
$key = "HKLM\SOFTWARE\Policies\Microsoft\PassportForWork"

Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName Enabled                   -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName RequireSecurityDevice      -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName UseCloudTrustForOnPremAuth -Type DWord -Value 1

# Phasenweiser Rollout ueber Sicherheitsgruppe statt OU: GPO an Domaene, Filter auf Gruppe
Set-GPPermission -Name $gpo.DisplayName -TargetName "GG-WHfB-Pilot" -TargetType Group -PermissionLevel GpoApply
Set-GPPermission -Name $gpo.DisplayName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoRead -Replace

# Am Client: Ist das Geraet bereit? (Hybrid/Entra-Status und Hello-Voraussetzungen)
dsregcmd /status
```

Die ersten drei Zeilen aktivieren WHfB, verlangen ein Sicherheitsgerät (TPM) und schalten Cloud Kerberos Trust ein. Die zwei `Set-GPPermission`-Zeilen setzen die von Microsoft empfohlene Gruppenfilterung um: Die Pilotgruppe erhält „GpoApply“, die Gruppe „Authentifizierte Benutzer“ nur Leserecht (`-Replace` entfernt das vorherige Anwendungsrecht). Der Name „Authenticated Users“ ist auf deutschen Systemen lokalisiert („Authentifizierte Benutzer“) und muss dem System angepasst werden. `dsregcmd /status` zeigt den Registrierungs- und Vorbereitungsstatus des Geräts; Microsoft verweist darauf für die Diagnose.

**Typische Fehler.** Falsch: WHfB zu erzwingen, ohne das Vertrauensmodell festzulegen; ohne passende Infrastruktur (zum Beispiel Cloud Kerberos Trust oder Zertifikatsdienste) schlägt die Anmeldung an lokalen Ressourcen fehl. Zweiter Fehler: Hardware ohne TPM mit „Use a hardware security device“ zu bedienen; die Einrichtung scheitert dann. Dritter Fehler: den Prozess Benutzer nicht zu erklären: Die Einrichtung verlangt eine Mehrfaktor-Bestätigung und das Anlegen einer PIN, und Benutzer ohne Erklärung rufen den Helpdesk an.

> **Praxisbeispiel**
>
> Beispielszenario: Die IT beginnt mit einer Gruppe von 30 Benutzern. Nach vier Wochen sind alle Fachabteilungen durchgerollt; die Zahl der Kennwort-Rücksetzungen sinkt spürbar, weil Benutzer sich mit der PIN anmelden und die Kennwortvergessen-Fälle seltener werden.

## 30 Biometrie nur verwaltet zulassen

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> Biometrie        |
| Einstellung     | Verwendung von Biometrie zulassen                                                           |
| Empfehlung      | Nach Organisationsvorgabe                                                                   |
| Ziel / Zweck    | Steuert biometrische Anmeldung kontrolliert                                                 |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Biometrische Verfahren (Fingerabdruck, Gesichtserkennung) sind bequem und werden bei Windows Hello (Abschnitt 29) als Alternative zur PIN genutzt. Sie sind aber auch datenschutzrechtlich sensibel: Biometrische Daten gelten in der DSGVO als besondere Kategorie personenbezogener Daten. Die Richtlinien im Bereich „Biometrie“ erlauben es, die Verwendung zentral zu steuern. Der Lehrplan formuliert bewusst „nach Organisationsvorgabe“: Es gibt keine allgemeingültige Empfehlung, ob Biometrie erlaubt sein soll. Die Entscheidung ist eine Abwägung zwischen Komfort und Sicherheit auf der einen und Datenschutz und Mitbestimmung auf der anderen Seite.

Die Gruppenrichtlinien dieses Bereichs umfassen nach meiner Kenntnis die Einstellungen „Allow the use of biometrics“, „Allow users to log on using biometrics“ und „Allow domain users to log on using biometrics“. Wichtig ist, was die Biometrie *nicht* tut: Die biometrische Vorlage verlässt das Gerät nicht; sie schaltet lediglich den lokalen Schlüssel von Windows Hello frei. Damit gilt auch die Aussage, dass Windows Hello for Business mit Biometrie keine biometrischen Daten an den Domänencontroller sendet. Diese Beschreibung entstammt meiner Kenntnis der Windows-Hello-Architektur und ist nicht aus den abgerufenen Seiten belegt; sie sollte mit der Microsoft-Dokumentation zu Windows Hello abgeglichen werden.

> **Merke**
>
> Biometrie ist eine Entscheidung der Organisation, nicht der IT allein. Klären Sie vorher mit Datenschutzbeauftragten und gegebenenfalls Betriebsrat, ob biometrische Anmeldung zulässig sein soll. Dies ist keine Rechtsberatung; die rechtliche Beurteilung ist Sache der Verantwortlichen.

Das Beispiel zeigt, wie man die Biometrie-Einstellung zentral setzt und den Zustand am Client prüft. Die Registrywerte (Schlüssel `Policies\Microsoft\Biometrics`, Wert `Enabled`) stammen aus meiner Kenntnis der ADMX-Datei und sind im Pilot zu prüfen. Das Skript legt nur die GPO an.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "SEC-Biometrie"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Biometrics"

# 1 = Biometrie erlaubt, 0 = Biometrie nicht erlaubt (nach Organisationsvorgabe waehlen)
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName Enabled -Type DWord -Value 1

# Am Client: Ist ein biometrisches Geraet vorhanden und aktiv?
Get-PnpDevice -Class Biometric -ErrorAction SilentlyContinue |
    Select-Object FriendlyName, Status
```

Der Wert `Enabled` steuert, ob Windows die Verwendung von Biometrie zulässt. Die zweite Abfrage listet biometrische Geräte (Fingerabdruckleser, Infrarotkamera) und deren Status. Fehlt Hardware, ist die Richtlinie wirkungslos, und der Lehrplan-Hinweis „nach Organisationsvorgabe“ bleibt eine reine Konfigurationsfrage.

**Typische Fehler.** Falsch: Biometrie pauschal zu verbieten, ohne Alternativen zu bieten; Benutzer weichen dann auf schwache PINs aus. Falsch auch: Biometrie pauschal zu erlauben, ohne die Mitbestimmung zu klären. Richtig: eine dokumentierte Entscheidung mit Begründung und Ausnahmeverfahren. Zweiter Fehler: zu übersehen, dass die Gruppenrichtlinie nur die Windows-Funktion steuert, nicht Anwendungen, die eigene biometrische Verfahren mitbringen. Dritter Fehler: Annahme, Biometrie sei stärker als jede PIN. Bei Windows Hello for Business ist die PIN durch das TPM geschützt und kann in vielen Umgebungen ebenso sicher sein.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Unternehmen lässt Fingerabdruck und Gesichtserkennung nach einer Betriebsvereinbarung zu, verlangt aber weiterhin die PIN als Rückfallverfahren. Die Einstellung wird in einer eigenen GPO gepflegt, damit sich die Entscheidung unabhängig von der WHfB-Richtlinie ändern lässt.

## Übungsaufgaben zu Modul 03

**Aufgabe 1.** **(leicht)** Erklären Sie, welche Rolle das TPM bei BitLocker spielt und warum ein ausgebauter Datenträger ohne TPM unlesbar bleibt.

**Aufgabe 2.** **(leicht)** Welche zwei Informationen werden laut Microsoft in AD DS gesichert, und wofür dient das Schlüsselpaket?

**Aufgabe 3.** **(leicht)** Worin unterscheiden sich „mit UEFI-Sperre“ und „ohne Sperre“ bei VBS, Credential Guard und LSA-Schutz? Warum pilotiert man ohne Sperre?

**Aufgabe 4.** **(mittel)** Warum reicht Abschnitt 22 allein nicht aus, und was ergänzt Abschnitt 23?

**Aufgabe 5.** **(mittel)** Wie hängen die Richtlinien aus den Abschnitten 24 und 25 zusammen, und welche Einschränkungen nennt Microsoft für Abschnitt 25?

**Aufgabe 6.** **(praktisch)** Schreiben Sie ein Skript, das auf einem Client prüft, ob das Systemlaufwerk verschlüsselt ist, ein Wiederherstellungskennwort besitzt und dieses nach AD sichert.

**Aufgabe 7.** **(praktisch)** Schreiben Sie ein Skript, das über CIM prüft, ob VBS läuft und welche Sicherheitsdienste (Credential Guard, Speicherintegrität) aktiv sind, und das Ergebnis als CSV schreibt.

**Aufgabe 8.** **(schwer)** Planen Sie den Rollout von VBS, Credential Guard und LSA-Schutz für 2 000 Clients mit gemischter Hardware: Inventur, Pilotgruppen, Kriterien für den Abbruch, Rückfallplan.

## Lösungen zu Modul 03

**Lösung 1.** Das TPM bewahrt den Schlüssel und gibt ihn nur frei, wenn die Messwerte des Startvorgangs unverändert sind. Ein ausgebauter Datenträger wird an einem anderen Rechner ohne dieses TPM betrieben; der Schlüssel fehlt, und die Daten bleiben verschlüsselt.

**Lösung 2.** Wiederherstellungskennwort (48 Ziffern) und Schlüsselpaket. Das Schlüsselpaket erlaubt zusammen mit dem Kennwort und `Repair-bde` die Wiederherstellung von Teilen eines physisch beschädigten Laufwerks. Es gilt nur für das Laufwerk, für das es erzeugt wurde.

**Lösung 3.** Mit UEFI-Sperre wird die Einstellung in einer UEFI-Variablen verankert und lässt sich nicht per Richtlinie oder aus der Ferne ändern; zum Zurücknehmen braucht man UEFI/BIOS-Zugriff (bei VBS und Credential Guard) beziehungsweise ein Spezialwerkzeug und eventuell Secure-Boot-Reset (bei LSA-Schutz). Ohne Sperre lässt sich die Einstellung per Richtlinie zurücknehmen, was für Pilotphasen unverzichtbar ist.

**Lösung 4.** Abschnitt 22 sichert, wenn gesichert werden kann. Wenn die Sicherung scheitert (kein DC erreichbar), verschlüsselt BitLocker trotzdem, und der Schlüssel fehlt. Abschnitt 23 erzwingt, dass BitLocker erst startet, wenn die Sicherung gelungen ist.

**Lösung 5.** Abschnitt 24 erlaubt BitLocker auf Wechseldatenträgern (und legt fest, was Benutzer dürfen), Abschnitt 25 verlangt Verschlüsselung für den Schreibzugriff. Laut Microsoft darf dann kein TPM-Startschlüssel/PIN und kein Wiederherstellungsschlüssel für Wechseldatenträger erlaubt sein, und die Richtlinie wird ignoriert, wenn „Removable Disks: Deny write access“ aktiv ist.

**Lösung 6.** Beispiel: `$v = Get-BitLockerVolume -MountPoint $env:SystemDrive`; wenn `$v.VolumeStatus` gleich `FullyEncrypted` und ein `RecoveryPassword`-Schützer vorhanden ist, `Backup-BitLockerKeyProtector` für jeden dieser Schützer aufrufen; sonst Fehlermeldung oder Rückgabe an die Inventarisierung. Siehe Beispiele in Abschnitt 22 und 23.

**Lösung 7.** Der Befehl steht im Code unten; die Zahlen sind nach Microsoft-Dokumentation zu deuten.

```ps
# Loesung (VBS-Inventur)
Get-CimInstance -Namespace root/Microsoft/Windows/DeviceGuard -ClassName Win32_DeviceGuard |
    Select-Object @{n='Computer'; e={$env:COMPUTERNAME}}, VirtualizationBasedSecurityStatus,
        @{n='Running'; e={$_.SecurityServicesRunning -join ';'}} |
    Export-Csv vbs.csv -NoTypeInformation
```

**Lösung 8.** Beispiel: (1) Inventur per Skript (TPM, Secure Boot, Virtualisierung, Treiberliste); (2) Pilot 1 mit 20 IT-Rechnern, Pilot 2 mit je einem Gerät pro Hardwaremodell, Pilot 3 mit einer Fachabteilung; (3) Reihenfolge LSA-Audit \> VBS/HVCI \> Credential Guard; (4) Abbruchkriterien: Bluescreens, nicht ladende Treiber, Anmeldefehler, blockierte Fachanwendungen; (5) Rückfall: Richtlinie auf „Disabled“ (nicht „Nicht konfiguriert“) und ohne UEFI-Sperre, Wiederherstellung über WinRE-Anleitung; (6) Kommunikation und Ausnahme-OU.
