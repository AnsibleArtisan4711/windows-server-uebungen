# Modul 10 - Geraete, USB und Druck

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „Gruppenrichtlinien für Windows 11 – 100 Richtlinien im Detail“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, farbige Boxen als Zitatblöcke mit fettem Titel, Steckbriefe als Tabellen, Übungsaufgaben und Lösungen als fortlaufend nummerierte Absätze). **Nummerierung:** Die Überschriften der Richtlinien tragen hier die laufende Nummer 1 bis 100 aus der Modultabelle; die Verweise im Text („Abschnitt 43“) meinen diese Nummer. (Im LaTeX-Satz zählen die Überschriften je Modul neu, etwa 5.3.) **Die Beispiele (PowerShell, INF) wurden für dieses Repository nicht ausgeführt**; sie verändern Gruppenrichtlinien, Registry und Sicherheitseinstellungen und gehören nur in eine Testumgebung (Pilot-OU, Testdomäne). Übersicht zum Modul: [README](README.md).

**Dauer:** 10 Unterrichtsstunden (Annahme: 1 Stunde je Richtlinie)  
**Priorität:** 1 bis 3 (drei Richtlinien mit Priorität 1, sechs mit Priorität 2, eine mit Priorität 3)

| Nr. | Lerneinheit (Richtlinie)                     | Prio | Stunden |
|----:|:---------------------------------------------|:----:|:-------:|
|  91 | Installation unbekannter Geräte einschränken |  2   |    1    |
|  92 | USB-Massenspeicher kontrollieren             |  1   |    1    |
|  93 | Schreibzugriff auf USB blockieren            |  1   |    1    |
|  94 | Druckertreiberinstallation begrenzen         |  1   |    1    |
|  95 | IPP/IPPS-Druck sicher konfigurieren          |  2   |    1    |
|  96 | Windows Protected Print prüfen               |  2   |    1    |
|  97 | Kamera-Zugriff steuern                       |  2   |    1    |
|  98 | Mikrofon-Zugriff steuern                     |  2   |    1    |
|  99 | Bluetooth steuern                            |  3   |    1    |
| 100 | Automatische Wiedergabe deaktivieren         |  1   |    1    |
|     | **Summe**                                    |      | **10**  |

**Worum es in diesem Modul geht.** Jedes Gerät, das man an einen Rechner anschließt, bringt Code mit: einen Treiber, der im Kern des Betriebssystems läuft, oder Dateien, die ein Benutzer öffnet. Ein präpariertes USB-Gerät, ein manipulierter Druckertreiber oder ein Funkgerät in Reichweite sind deshalb klassische Wege in ein Unternehmensnetz. Außerdem verlassen Daten über dieselben Wege das Haus: auf einem USB-Stick, in einem Druckauftrag, über Kamera und Mikrofon. Dieses Modul behandelt die Kontrolle dieser Schnittstellen in drei Gruppen. Die Abschnitte 91 bis 93 betreffen angeschlossene Geräte und Wechseldatenträger, 94 bis 96 den Druck, 97 bis 99 Kamera, Mikrofon und Funk, und der Abschnitt 100 die automatische Wiedergabe von Medien. Alle Einstellungen sind Kompromisse zwischen Sicherheit und Arbeitsfähigkeit; ohne Pilotgruppe und Ausnahmeverfahren (zum Beispiel für Techniker mit Messgeräten) scheitert jede dieser Richtlinien an der Realität.

> **Merke**
>
> Der Grundsatz dieses Moduls lautet „erst erlauben, was gebraucht wird, dann den Rest sperren“. Das ist aufwendiger als der umgekehrte Weg (alles erlauben und Einzelnes sperren), aber robuster, denn neue Gerätearten sind dann standardmäßig draußen. Die Bestandsaufnahme der tatsächlich eingesetzten Geräte (Tastaturen, Mäuse, Headsets, Scanner, Drucker, Kartenleser) gehört deshalb immer an den Anfang.

## 91 Installation unbekannter Geräte einschränken

| **Feld**        | **Steckbrief**                                                                                                                 |
|:----------------|:-------------------------------------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> Geräteinstallation \> Einschränkungen bei der Geräteinstallation |
| Einstellung     | Installation nicht beschriebener Geräte verhindern                                                                             |
| Empfehlung      | Aktiviert nach Test                                                                                                            |
| Ziel / Zweck    | Reduziert Risiko durch unbekannte Hardware                                                                                     |
| Zielbereich     | Computer                                                                                                                       |
| Priorität       | 2                                                                                                                              |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.                                    |

Wenn man ein neues Gerät anschließt, sucht Windows einen passenden Treiber und installiert ihn automatisch. Das ist bequem, aber auch ein Risiko: Der Treiber läuft mit hohen Rechten, und ein Gerät kann sich als etwas anderes ausgeben, als es ist. Die Richtlinien zur *Geräteinstallation* (*Device Installation Restrictions*) erlauben es, die Installation zu steuern. Sie arbeiten mit vier Kennzeichen eines Geräts: der *Geräteinstanz-ID* (genau dieses eine Gerät), der *Geräte-ID* (Hersteller und Modell), der *Geräteklasse* (zum Beispiel Tastatur oder Drucker, als GUID) und der Eigenschaft „austauschbar“ (Wechselgeräte). Für jedes Kennzeichen gibt es je eine Erlauben- und eine Verhindern-Richtlinie.

Die Einstellung aus dem Lehrplan, „Installation von Geräten verhindern, die nicht durch andere Richtlinien beschrieben sind“ (*Prevent installation of devices not described by other policy settings*), wirkt wie eine Standardsperre: Alles, was nicht ausdrücklich erlaubt ist, wird nicht installiert. Laut Microsoft-Dokumentation steht sie unter dem im Steckbrief genannten Pfad, der Registrywert heißt `DenyUnspecified` im Schlüssel `Software\Policies\Microsoft\Windows\DeviceInstall\Restrictions`. Wichtig ist ein Hinweis derselben Dokumentation: Diese Einstellung wurde durch die Richtlinie „Mehrstufige Auswertungsreihenfolge für Erlauben- und Verhindern-Richtlinien über alle Gerätekriterien anwenden“ (*Apply layered order of evaluation ...*) ersetzt, die differenzierter arbeitet; Microsoft empfiehlt, diese zu verwenden. Bei Konflikt ist die geschichtete Variante aktiv und die ältere wird ignoriert. In dieser Reihenfolge gilt: Geräteinstanz-ID vor Geräte-ID vor Geräteklasse vor Wechselgeräte, und innerhalb jeder Stufe verhindert zuerst die Sperre und erlaubt dann die Freigabe.

> **Ergänzung aus der Nachrecherche**
>
> Prüfung der Wirkung laut Microsoft: In der Datei `C:\Windows\INF\setupapi.dev.log` erscheint ein Abschnitt „Device Installation Restrictions Policy Check“ mit Status SUCCESS. Ein blockiertes Gerät erzeugt die Meldung „Die Installation dieses Geräts ist durch die Systemrichtlinie verboten“ (englisch *The installation of this device is forbidden by system policy*). Vorsicht bei der Option „auch auf bereits installierte Geräte anwenden“: Microsofts Beispiel warnt, dass eine Sperre der Klasse „Datenträger“ samt Rückwirkung sogar die interne Festplatte unbrauchbar machen kann. Microsoft empfiehlt außerdem, die Konfiguration mit mehreren Exemplaren eines Geräts zu testen, zum Beispiel mehreren USB-Sticks.

Das Beispiel inventarisiert zunächst die angeschlossenen Geräte nach Klasse und liefert damit die Grundlage für die Erlaubnisliste. Danach legt es eine GPO mit der geschichteten Auswertung und einer Sperre für Druckerklassen an (die GUID `{4d36e979-e325-11ce-bfc1-08002be10318}` der Druckerklasse nennt die Microsoft-Dokumentation). Die Registrynamen der Liste (`DenyDeviceClasses`, `DenyDeviceClassesRetroactive`, `EnableInstallationPolicyLayering`) sind aus meiner Kenntnis und im Pilot zu prüfen. Das Beispiel setzt bewusst *keine* Rückwirkung.

```ps
# 1) Bestandsaufnahme: welche Geraeteklassen sind im Einsatz?
Get-PnpDevice -PresentOnly |
    Group-Object Class |
    Sort-Object Count -Descending |
    Select-Object Count, Name, @{n='ClassGuid'; e={ ($_.Group | Select-Object -First 1).ClassGuid }}

# 2) GPO: geschichtete Auswertung + Sperre der Druckerklasse (ohne Rueckwirkung)
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEV-Geraeteinstallation"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName EnableInstallationPolicyLayering -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DenyDeviceClasses -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key "$key\DenyDeviceClasses" -ValueName 1 -Type String -Value "{4d36e979-e325-11ce-bfc1-08002be10318}"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DenyDeviceClassesRetroactive -Type DWord -Value 0

# 3) Am Testrechner: Protokoll auf den Richtlinienpruefung-Abschnitt durchsuchen
Select-String -Path "C:\Windows\INF\setupapi.dev.log" -Pattern 'Device Installation Restrictions Policy Check' |
    Select-Object -Last 3
```

Schritt 1 gruppiert die angeschlossenen Geräte nach Klasse und zeigt die Klassen-GUID, die man für die Listen benötigt. Schritt 2 legt die GPO an: Die geschichtete Auswertung wird aktiviert, die Liste der gesperrten Klassen enthält die Druckerklasse, und die Rückwirkung bleibt ausgeschaltet, damit bereits installierte Geräte unberührt bleiben. Schritt 3 bestätigt am Testrechner, dass die Richtlinie vom Geräteinstallationsdienst ausgewertet wurde.

**Typische Fehler.** Falsch: die Standardsperre zu aktivieren, ohne vorher die Erlaubnislisten für Tastatur, Maus, Monitor und Dockingstation zu pflegen. Der Rechner startet dann eventuell ohne Eingabegerät. Richtig: erst Bestandsaufnahme und Erlaubnisliste, dann Sperre im Pilot. Zweiter Fehler: die Rückwirkung zu aktivieren und damit eingebaute Geräte (Festplatte, Netzwerkkarte) abzuschalten. Dritter Fehler: die ältere Standardsperre und die geschichtete Auswertung zu mischen; die geschichtete Variante gewinnt, und die Ergebnisse überraschen.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Betreiber von Messeständen will verhindern, dass fremde USB-Geräte an Vorführrechner angeschlossen werden. Die Erlaubnisliste enthält die Geräte-IDs der firmeneigenen Maus, Tastatur und des Kartenlesers; alle anderen Geräte werden nicht installiert. Der Besucher mit dem Stick bekommt die Meldung „Installation durch Systemrichtlinie verboten“.

## 92 USB-Massenspeicher kontrollieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> Wechselspeicherzugriff        |
| Einstellung     | Wechseldatenträger Zugriff                                                                  |
| Empfehlung      | Nach Datenklassifizierung                                                                   |
| Ziel / Zweck    | Reduziert Datenabfluss                                                                      |
| Zielbereich     | Computer/User                                                                               |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

*USB-Massenspeicher* (englisch *mass storage*) sind Sticks, externe Festplatten und Speicherkarten. Sie haben zwei Risiken: Daten gehen unkontrolliert hinaus (Abschnitt 93), und Schadsoftware kommt unkontrolliert herein. Windows kennt dafür den Satz von Richtlinien unter „Wechselspeicherzugriff“ (*Removable Storage Access*). Er unterscheidet Klassen von Wechselmedien: Wechseldatenträger (USB-Sticks und Festplatten), CDs und DVDs, Disketten, Bandlaufwerke und tragbare Geräte (WPD, etwa Smartphones und Kameras). Pro Klasse kann man das Lesen und das Schreiben verweigern, und es gibt eine zusammenfassende Richtlinie „Wechselmedien: Jeglichen Zugriff verweigern“. Die meisten Richtlinien existieren sowohl unter Computer- als auch unter Benutzerkonfiguration.

Der Lehrplan sagt „nach Datenklassifizierung“: Wie streng die Einstellung ist, hängt davon ab, was auf den Rechnern liegt. Eine sinnvolle Abstufung unterscheidet drei Gruppen. In der normalen Büroflotte genügt es, Schreibzugriff nur für ungeschützte Medien zu erlauben (Abschnitt 93 und Modul 03). Für Bereiche mit vertraulichen Daten (Personal, Entwicklung, Finanzen) ist der Lesezugriff erlaubt und der Schreibzugriff verweigert. Für Hochsicherheitsbereiche und Produktionsrechner kann jeder Zugriff verweigert werden. Die Gruppenzugehörigkeit löst man technisch über eigene OUs oder Sicherheitsgruppen-Filter für die GPOs.

> **Ergänzung aus der Nachrecherche**
>
> Microsoft weist in der Dokumentation zu den WPD-Richtlinien ausdrücklich darauf hin, dass die Richtlinie für tragbare Geräte nicht als verlässliche Sperre für Wechseldatenträger taugt: Sie erzwingt die Protokolle PTP, MTP und MSC, aber wer einen USB-Stick einsteckt, kann ihn unter Umständen trotzdem im Explorer durchsuchen. Für eine echte Sperre muss die Klasse „Wechseldatenträger“ (nicht WPD) gewählt werden, und für eine vollständige Kontrolle, auch gegen Geräte, die sich anders melden, kommen zusätzlich die Geräteinstallationsrichtlinien aus Abschnitt 91 oder Funktionen von Defender for Endpoint (Gerätesteuerung) in Betracht. Letzteres ist nach meiner Kenntnis ein Lizenzthema und im Pilot zu klären.

Das Beispiel legt eine GPO an, die für eine Abteilung den Lesezugriff erlaubt und den Schreibzugriff sperrt, und führt dazu eine Inventur der vorhandenen Wechseldatenträger durch. Der Registryschlüssel mit der Klassen-GUID `{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}` steht in der Policy-CSP-Dokumentation; die Werte `Deny_Read` und `Deny_Write` sind aus meiner Kenntnis und im Pilot zu prüfen.

```ps
# Inventur: welche Wechseldatenträger (USB) sind aktuell angeschlossen?
Get-CimInstance Win32_DiskDrive |
    Where-Object { $_.InterfaceType -eq 'USB' } |
    Select-Object Model, SerialNumber, Size, MediaType

# GPO fuer eine Abteilung: lesen erlaubt, schreiben verweigert (Computerseite)
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEV-USB-NurLesen"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName Deny_Read  -Type DWord -Value 0
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName Deny_Write -Type DWord -Value 1

# Wirkung am Client pruefen
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}" |
    Select-Object Deny_Read, Deny_Write
```

Die Inventur zeigt, welche USB-Laufwerke aktuell angeschlossen sind; sie lässt sich per Skript über viele Rechner sammeln und liefert die Datenbasis für die Klassifizierung. Die GPO setzt `Deny_Write` auf 1 und `Deny_Read` auf 0. Die Abfrage am Client bestätigt die Werte. Beachten Sie die Einheit der Wirkung: Die Richtlinie betrifft die Wechseldatenträger-Klasse; Handys und Kameras, die über das tragbare-Geräte-Protokoll arbeiten, sind eine eigene Klasse.

**Typische Fehler.** Falsch: die Richtlinie ohne Ausnahmeverfahren zu aktivieren. Dann blockiert sie den Techniker, der Firmware von einem Stick einspielen muss. Richtig: dokumentierte Ausnahmegruppe mit befristeter Freigabe. Zweiter Fehler: nur die Computerseite oder nur die Benutzerseite zu setzen, obwohl beide existieren und gelten; im Konfliktfall setzt die Computerkonfiguration sich nicht immer durch, es zählt die restriktivere Wirkung (nach meiner Kenntnis, im Pilot prüfen). Dritter Fehler: sich auf WPD zu verlassen (siehe Ergänzung).

> **Praxisbeispiel**
>
> Beispielszenario: Die Personalabteilung erhält den Lesemodus. Beim Datenträgeraustausch mit dem Steuerberater wird ein verschlüsselter Stick verwendet, den die IT bereitstellt. Ein Stick aus dem Privatbesitz lässt sich lesen, aber nicht beschreiben, und Daten gehen nicht ungeschützt hinaus.

## 93 Schreibzugriff auf USB blockieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> System \> Wechselspeicherzugriff        |
| Einstellung     | Wechseldatenträger: Schreibzugriff verweigern                                               |
| Empfehlung      | Aktiviert für Hochsicherheitsgruppen                                                        |
| Ziel / Zweck    | Verhindert Datenkopie auf USB                                                               |
| Zielbereich     | Computer/User                                                                               |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Dieser Abschnitt behandelt die wichtigste Einzelsperre aus der Gruppe: „Wechseldatenträger: Schreibzugriff verweigern“ (*Removable Disks: Deny write access*). Laut Policy-CSP-Dokumentation gilt: Ist die Einstellung aktiviert, wird der Schreibzugriff auf diese Klasse verweigert; ist sie deaktiviert oder nicht konfiguriert, ist er erlaubt. Als Computereinstellung heißt der Policy CSP `Storage/RemovableDiskDenyWriteAccess` (Windows 10, Version 1809 und höher; Werte 0 und 1, Standard 0). Für einzelne Benutzer gibt es die Variante unter der Benutzerkonfiguration.

Der Lehrplan beschränkt die Einstellung auf Hochsicherheitsgruppen. Das ist die pragmatische Lesart: Flächendeckend blockiert sie den normalen Austausch von Dateien, und viele Unternehmen setzen stattdessen eine gezielte Alternative ein, die in der Microsoft-Dokumentation ausdrücklich genannt wird. Es ist die Richtlinie „Schreibzugriff auf Laufwerke verweigern, die nicht durch BitLocker geschützt sind“ (Windows-Komponenten \> BitLocker-Laufwerkverschlüsselung \> Wechseldatenlaufwerke). Der Effekt: Benutzer können auf Wechseldatenträger nur schreiben, wenn diese mit BitLocker To Go verschlüsselt sind. Gestohlene oder verlorene Sticks sind damit unlesbar, und die IT behält die Kontrolle über die Schlüssel (siehe Modul 03, Abschnitt 25, wo BitLocker für Wechseldatenträger beschrieben ist).

> **Merke**
>
> Unterscheiden Sie zwei Schutzziele. *Datenabfluss verhindern* bedeutet, das Kopieren auf fremde Medien zu unterbinden: Dafür dient die Schreibsperre. *Verlust absichern* bedeutet, dass verlorene Medien nichts verraten: Dafür dient die Verschlüsselung. Die Kombination „Schreiben nur auf BitLocker-geschützte Medien“ deckt beides teilweise ab, ersetzt aber keine Datenverlust-Schutzlösung (DLP).

Das Beispiel zeigt beide Wege nebeneinander: die harte Sperre für Hochsicherheitsgruppen und die weiche Variante mit BitLocker-Pflicht für den Rest. Die Registrynamen der BitLocker-Richtlinie (`RDVDenyWriteAccess` im Schlüssel `FVE`) sind aus meiner Kenntnis und im Pilot zu prüfen. Die Prüfung am Client nutzt das Cmdlet `Get-BitLockerVolume` des BitLocker-Moduls.

```ps
Import-Module GroupPolicy

# A) Hochsicherheitsgruppe: Schreiben auf Wechseldatentraeger komplett verweigern
$hs  = New-GPO -Name "DEV-USB-Schreibsperre-HS"
$rsd = "HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}"
Set-GPRegistryValue -Name $hs.DisplayName -Key $rsd -ValueName Deny_Write -Type DWord -Value 1

# B) Restliche Flotte: Schreiben nur auf BitLocker-geschuetzte Medien
$bl = New-GPO -Name "DEV-USB-NurBitLocker"
Set-GPRegistryValue -Name $bl.DisplayName -Key "HKLM\SOFTWARE\Policies\Microsoft\FVE" `
    -ValueName RDVDenyWriteAccess -Type DWord -Value 1

# Am Client: Status der angeschlossenen Datentraeger (Verschluesselung)
Get-BitLockerVolume | Select-Object MountPoint, VolumeType, ProtectionStatus, EncryptionPercentage
```

Variante A sperrt das Schreiben vollständig und eignet sich für wenige, klar benannte Gruppen. Variante B lässt das Schreiben zu, aber nur auf mit BitLocker geschützten Medien; ein unverschlüsselter Stick wird schreibgeschützt eingebunden. Die Abfrage am Client zeigt den Schutzstatus von Datenträgern, soweit BitLocker sie kennt.

**Typische Fehler.** Falsch: die Schreibsperre auf alle Rechner anzuwenden und dann Ausnahmen per Zuruf zu vergeben, bis niemand mehr weiß, wer was darf. Richtig: Ausnahmen über eine Gruppe, begrenzte Dauer, Dokumentation. Zweiter Fehler: zu glauben, die Sperre verhindere jeden Abfluss. Daten können über E-Mail, Cloud-Upload, Drucker oder Smartphone-Fotos abfließen; die Sperre ist eine Schicht. Dritter Fehler: die Folgen für Sicherungsprogramme zu übersehen, die auf USB-Platten sichern; sie scheitern still. Richtig: Backups vorher prüfen.

> **Praxisbeispiel**
>
> Beispielszenario: In der Entwicklung liegen Quelltexte, die nicht abfließen dürfen. Die Entwicklungsrechner erhalten die harte Schreibsperre, Datenaustausch läuft über einen Dateiserver. Alle übrigen Abteilungen dürfen auf BitLocker-geschützte Sticks schreiben, die die IT ausgibt.

## 94 Druckertreiberinstallation begrenzen

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Drucker                                 |
| Einstellung     | Point-and-Print-Einschränkungen                                                             |
| Empfehlung      | Nur genehmigte Server                                                                       |
| Ziel / Zweck    | Reduziert PrintNightmare-ähnliche Risiken                                                   |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 1                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Der *Druckspooler* (Dienst „Druckwarteschlange“) ist ein alter, sehr mächtiger Teil von Windows. Er läuft mit höchsten Rechten, lädt Druckertreiber und verwaltet Druckaufträge. Der Treiber eines Druckers ist Code, der in diesem Dienst läuft. *Point and Print* ist die Funktion, die es einem Benutzer erlaubt, einen Netzwerkdrucker zu verbinden, ohne den Treiber selbst zu installieren: Der Client lädt ihn vom Druckserver. Wenn ein Angreifer es schafft, einen Client mit einem bösartigen Druckserver zu verbinden, kann er so Code mit hohen Rechten ausführen lassen. Genau dieses Muster steckte hinter den als „PrintNightmare“ bekannt gewordenen Schwachstellen des Jahres 2021 (nach meiner Kenntnis, als Hintergrund; die technischen Einzelheiten stehen nicht in den abgerufenen Quellen).

Microsofts Reaktion bestand aus zwei Teilen. Erstens änderte Microsoft am 10. August 2021 das Standardverhalten von Point and Print: Die Installation und Aktualisierung von Treibern erfordert seitdem Administratorrechte (Hinweis auf den Beitrag „Point and Print Default Behavior Change“ und KB5005652 in der Baseline-Dokumentation). Zweitens gibt es die Richtlinie „Druckertreiberinstallation auf Administratoren beschränken“ (*Limits print driver installation to Administrators*, Registrywert `RestrictDriverInstallationToAdministrators` im Schlüssel `Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint`). Die Baseline empfiehlt den Zustand „Aktiviert“; nach der Policy-CSP-Dokumentation ist die Richtlinie auch als MDM-Einstellung ab Windows 11 22H2 vorhanden, und ihr Standardverhalten ist ohnehin die Beschränkung auf Administratoren.

> **Ergänzung aus der Nachrecherche**
>
> Die klassische Richtlinie „Point-and-Print-Einschränkungen“ (Computerkonfiguration \> Administrative Vorlagen \> Drucker) arbeitet mit einer Serverliste: Laut Microsoft-Dokumentation laden Clients Treiberkomponenten dann nur von ausdrücklich genannten Servern, und die Eingabe erfolgt als voll qualifizierte Namen, durch Semikolon getrennt. Die Dokumentation beschreibt dazu zwei Warnungs-Optionen („Keine Warnung oder Erhöhungsaufforderung“ und „Nur Warnung anzeigen“). Für die Sicherheit ist wichtig, dass ältere Hilfeartikel diese Optionen im Zusammenhang mit *Funktionsstörungen* empfehlen; aus Sicht der Härtung bleibt die Erhöhungsaufforderung besser aktiviert (im Pilot abzuwägen). Zudem greift die Richtlinie nach Microsoft nur in der Computerkonfiguration; die ältere Benutzerkonfiguration wird von modernen Systemen ignoriert und ist veraltet.

Das Beispiel setzt beide Richtlinien in einer GPO und listet anschließend die installierten Druckertreiber auf einem Client, um unerwartete Treiber zu finden. Die Registrywerte `Restricted`, `TrustedServers` und `ServerList` sowie die Warnoptionen `NoWarningNoElevationOnInstall` und `UpdatePromptSettings` sind teilweise aus der Microsoft-Dokumentation (der Wert `Restricted` im Schlüssel `PointAndPrint` ist dort bestätigt), teilweise aus meiner Kenntnis; im Pilot zu prüfen.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEV-Druck-PointAndPrint"
$pp  = "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"

# Treiberinstallation nur durch Administratoren
Set-GPRegistryValue -Name $gpo.DisplayName -Key $pp -ValueName RestrictDriverInstallationToAdministrators -Type DWord -Value 1

# Point and Print nur zu genehmigten Servern; Erhoehungsaufforderung bleibt aktiv
Set-GPRegistryValue -Name $gpo.DisplayName -Key $pp -ValueName Restricted -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $pp -ValueName TrustedServers -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key $pp -ValueName ServerList -Type String -Value "print01.contoso.local;print02.contoso.local"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $pp -ValueName NoWarningNoElevationOnInstall -Type DWord -Value 0
Set-GPRegistryValue -Name $gpo.DisplayName -Key $pp -ValueName UpdatePromptSettings -Type DWord -Value 0

# Am Client: welche Treiber sind installiert, und woher kommen sie?
Get-PrinterDriver | Select-Object Name, Manufacturer, DriverVersion, Environment | Sort-Object Manufacturer
```

Der erste Wert beschränkt die Treiberinstallation auf Administratoren. Die folgenden Werte aktivieren die Point-and-Print-Einschränkung, tragen zwei genehmigte Server ein und lassen die Warn- und Erhöhungsabfragen aktiv (Wert 0 bedeutet nach meiner Kenntnis, dass die Abfrage erscheint). Die Abfrage der installierten Treiber hilft, unerwartete Hersteller oder Versionen zu entdecken; ein Treiber, den kein Druckserver ausgeliefert hat, ist verdächtig.

**Typische Fehler.** Falsch: die Einschränkung zu aktivieren, ohne die Druckserver in die Liste aufzunehmen. Danach scheitert das Verbinden mit der Fehlermeldung zu fehlenden Treibern; typische Fehlerbilder nennt Microsoft mit den Ereignissen 4098 und 8192 (Gruppenrichtlinien-Drucker) sowie 215 im PrintService-Admin-Protokoll. Richtig: Serverliste zuerst, Pilot mit echten Druckern. Zweiter Fehler: die Warnungen auszuschalten, um Rückfragen zu vermeiden. Dritter Fehler: den Spooler auf Domänencontrollern und Servern ohne Druckfunktion nicht abzuschalten; wer nicht druckt, braucht den Dienst nicht (nach meiner Kenntnis eine verbreitete Härtungsempfehlung, im Pilot zu prüfen).

> **Praxisbeispiel**
>
> Beispielszenario: Ein Mitarbeiter bringt ein Notebook mit und verbindet es mit einem Drucker eines unbekannten Servers im Besprechungsraum. Die Richtlinie lässt die Verbindung nur zu den beiden genehmigten Servern zu; die Verbindung scheitert, und der Helpdesk bekommt die Anfrage statt eines unbemerkten Treiberdownloads.

## 95 IPP/IPPS-Druck sicher konfigurieren

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Drucker                                 |
| Einstellung     | IPP/IPPS-Richtlinien                                                                        |
| Empfehlung      | IPPS bevorzugen/erzwingen nach Kompatibilität                                               |
| Ziel / Zweck    | Erhöht Sicherheit beim Netzwerkdruck                                                        |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Das *Internet Printing Protocol* (IPP) ist ein standardisiertes, auf HTTP aufbauendes Protokoll für den Druck. Jede Anfrage ist eine HTTP-Nachricht, Drucker werden über Adressen wie `ipps://drucker.example.com/ipp/print` angesprochen. IPP ersetzt den klassischen treiberbasierten Druck: Windows liefert dafür den eingebauten „Microsoft IPP Class Driver“ mit, der mit Mopria-zertifizierten Druckern spricht. Nach Microsofts Darstellung entfällt damit die Installation von Treibern von Drittanbietern, was die Sicherheit verbessert, weil die Zahl der verarbeiteten Druckformate klein ist und die Übertragung verschlüsselt werden kann. Das ist der Grund, warum Microsoft den Umstieg ausdrücklich empfiehlt.

Der Unterschied zwischen *IPP* und *IPPS*: Das S steht für *secure* und bedeutet, dass die Verbindung mit TLS verschlüsselt ist, so wie bei HTTPS. Reines IPP überträgt Druckaufträge im Klartext, sodass Dokumente im Netz mitgelesen werden könnten. Zwei Richtlinien sind relevant. „IPPS für IPP-Drucker verlangen“ (*Require IPPS for IPP printers*): Aktiviert, können nur IPP-Drucker installiert werden, die IPPS unterstützen; deaktiviert oder nicht konfiguriert, sind auch IPP-Drucker ohne IPPS erlaubt (Standard). Die Einstellung steht unter Computerkonfiguration \> Administrative Vorlagen \> Drucker, der Wert heißt `RequireIpps` im Schlüssel `Software\Policies\Microsoft\Windows NT\Printers\IPP`, und sie ist laut Policy-CSP-Dokumentation ab Windows 11 24H2 mit dem Update KB5062660 verfügbar. Die zweite Richtlinie, „TLS/SSL-Sicherheitsrichtlinie für IPP-Drucker festlegen“, bestimmt die Zertifikatsprüfung. Wichtig ist der Standard: Laut Microsoft werden standardmäßig alle Zertifikatsfehler ignoriert, damit Drucker mit selbstsignierten Zertifikaten funktionieren; wer die Einstellung aktiviert, schaltet alle Zertifikatsprüfungen ein (verfügbar ab 24H2 mit KB5052093).

> **Ergänzung aus der Nachrecherche**
>
> Diese Standardeinstellung ist sicherheitlich heikel: Verschlüsselung ohne Zertifikatsprüfung schützt nicht vor einem Mann-in-der-Mitte-Angriff, weil ein Angreifer mit eigenem Zertifikat nicht auffällt. Der Weg zu echter Sicherheit führt deshalb über Drucker mit gültigen Zertifikaten einer Unternehmens-CA (siehe Microsofts Hinweis zum IPP-Druck über HTTPS: Zertifikat einer vertrauenswürdigen CA, bei Domänenmitgliedschaft einer Unternehmens-CA, oder das selbstsignierte Zertifikat auf dem Client installieren, aber nur für vertrauenswürdige Server). Das ist Verwaltungsaufwand pro Drucker und der Hauptgrund, warum viele Umgebungen die Zertifikatsprüfung zunächst nicht erzwingen.

Das Beispiel prüft zuerst, welche Drucker im Netzwerk per IPP angebunden sind und ob sie IPPS verwenden, und legt dann die Richtlinie zunächst im Pilot an. Die Spalte `PortName` der Druckerliste enthält die Adresse; die Annahme, dass IPPS-Adressen mit `https` oder `ipps` beginnen, ist aus meiner Kenntnis, und die Portbezeichnungen sind im Pilot zu prüfen. Die Zertifikatsrichtlinie wird hier bewusst nicht gesetzt, sondern erst nach der Inventur.

```ps
# Inventur: Drucker mit IPP-Anbindung und Verschluesselungsstatus (Heuristik ueber den Portnamen)
Get-Printer | ForEach-Object {
    $port = Get-PrinterPort -Name $_.PortName -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Drucker = $_.Name
        Port    = $_.PortName
        Adresse = $port.Description
        IPPS    = ($_.PortName -match '^(https|ipps)://')
    }
} | Format-Table -AutoSize

# Pilot-GPO: IPPS verlangen (nur fuer die Pilotgruppe verknuepfen!)
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEV-Druck-IPPS-Pilot"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\IPP" `
    -ValueName RequireIpps -Type DWord -Value 1
```

Die Inventur listet jeden Drucker mit Port und prüft heuristisch auf IPPS. Alle Drucker mit dem Ergebnis `False` sind Kandidaten für eine Umstellung oder einen Austausch. Die Pilot-GPO setzt `RequireIpps` auf 1; verknüpft wird sie nur mit der Pilot-OU, weil nicht-IPPS-Drucker danach nicht mehr installierbar sind. Die Voraussetzung für die Richtlinie ist ein Windows 11 in der Version 24H2 mit dem genannten Update; auf älteren Systemen bleibt sie ohne Wirkung.

**Typische Fehler.** Falsch: IPPS zu erzwingen, bevor die Drucker es können oder Zertifikate haben. Die Folge ist ein Druckausfall. Richtig: Inventur, Firmware-Updates, erst dann erzwingen. Zweiter Fehler: zu glauben, „verschlüsselt“ heiße „geprüft“: Ohne aktivierte Zertifikatsprüfung ist der Schutz begrenzt (siehe Ergänzung). Dritter Fehler: den Standardport 631 für IPP und 443 für IPPS zu verwechseln oder die Firewall (Modul 04) nicht anzupassen.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Unternehmen ersetzt zehn alte Netzwerkdrucker durch Mopria-zertifizierte Geräte. Die Drucker erhalten Zertifikate der internen CA, die Clients verbinden sich per IPPS, und in der Folge entfallen Treiberpakete und deren Pflege.

## 96 Windows Protected Print prüfen

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Drucker                                 |
| Einstellung     | Windows Protected Print                                                                     |
| Empfehlung      | Pilotieren und kompatible Drucker prüfen                                                    |
| Ziel / Zweck    | Modernisiert Drucksicherheit                                                                |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

*Windows Protected Print Mode* (WPP) ist der konsequente Schritt nach dem IPP-Umstieg: Der Computer druckt dann *ausschließlich* über den eingebauten Windows-Ready-Print-Stack und lädt *keine* Druckertreiber von Drittanbietern mehr. Nach Microsofts Darstellung entsteht beim Aktivieren ein neuer, eingeschränkter Spooler-Prozess: Er läuft nicht mehr mit SYSTEM-Rechten, verweigert das Laden fremder Module und lässt nur von Microsoft signierte Dateien zu, die für IPP nötig sind. Die XPS-Wiedergabe läuft im Benutzerkontext statt als SYSTEM, und es werden Schutzmechanismen aktiviert (Control Flow Guard, CET, Sperre für Kindprozesse, Redirection Guard, Arbitrary Code Guard). Microsoft beschreibt, dass der Modus mehr als die Hälfte der bisher gemeldeten Sicherheitsprobleme im Windows-Druck entschärft. Für die Verwaltung entfällt zudem die Treiberpflege.

Die Konfiguration ist einfach, die Folgen sind groß. Die Richtlinie „Windows Protected Print konfigurieren“ steht unter Computerkonfiguration \> Administrative Vorlagen \> Drucker, der Registrywert heißt `WindowsProtectedPrintGroupPolicyState` im Schlüssel `Software\Policies\Microsoft\Windows NT\Printers\WPP`; sie ist ab Windows 11 24H2 verfügbar. Per Intune lässt sich dieselbe Einstellung mit dem OMA-URI `./Device/Vendor/MSFT/Policy/Config/Printers/ConfigureWindowsProtectedPrint` und dem Wert `<enabled/>` setzen. Ist sie nicht konfiguriert, gibt es keine Einschränkungen; Microsoft kündigt in den FAQ an, dass der Modus „zu einem späteren Zeitpunkt“ standardmäßig eingeschaltet werden soll, nennt aber keinen Termin. Der Lehrplan sagt deshalb zu Recht „pilotieren“.

> **Merke**
>
> Beachten Sie, was beim Einschalten geschieht: Drucker mit Treibern von Drittanbietern werden *deinstalliert*, und der Treiber wird aus dem Treiberspeicher entfernt. Kompatible (Mopria-zertifizierte) Drucker lassen sich neu installieren und nutzen dann Windows Ready Print. Nicht kompatible Drucker bleiben unbenutzbar, solange der Modus aktiv ist. Software-Drucker wie XPS-Writer und Fax werden entfernt. Auch Scanner funktionieren nur, wenn sie Mopria-zertifiziert sind.

Das Beispiel prüft die Bereitschaft: Es listet die Drucker mit ihren Treibern und markiert jene, die nicht der eingebauten IPP-Klasse zugeordnet sind. Der Name des Microsoft-IPP-Klassentreibers ist aus der Dokumentation entnommen („Microsoft IPP Class Driver“), die Namensliste der Virtualdrucker ist beispielhaft. Danach legt es die Pilot-GPO an.

```ps
# Bereitschaftspruefung: wer druckt nicht ueber den IPP-Klassentreiber?
Get-Printer | Select-Object Name, DriverName, PortName |
    Where-Object { $_.DriverName -notmatch 'IPP Class Driver' -and
                   $_.Name -notmatch 'PDF|XPS|OneNote|Fax' } |
    Format-Table -AutoSize

# Pilot-GPO: Windows Protected Print einschalten (nur Pilot-OU!)
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEV-Druck-WPP-Pilot"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\WPP" `
    -ValueName WindowsProtectedPrintGroupPolicyState -Type DWord -Value 1

# Am Pilotclient nach gpupdate: Drucker neu pruefen
gpupdate /force | Out-Null
Get-Printer | Select-Object Name, DriverName
```

Die erste Abfrage zeigt Drucker, die nicht den IPP-Klassentreiber nutzen (und keine bekannten virtuellen Drucker sind); für sie ist ein Austausch oder eine Ausnahme einzuplanen. Die Pilot-GPO setzt den Zustand auf 1; der Wertetyp und -inhalt ist aus meiner Kenntnis und im Pilot zu prüfen. Die letzte Abfrage zeigt nach der Verarbeitung, welche Drucker übrig bleiben.

**Typische Fehler.** Falsch: WPP flächendeckend auszurollen und danach Dutzende Drucker verschwinden zu sehen. Richtig: Inventur, Pilotgruppe, Austauschplan. Zweiter Fehler: Verwaltungsrechner mit WPP zu betreiben, während Druckserver ohne WPP laufen: Laut Microsoft kann man mit einem Client im WPP-Modus Druckserver ohne WPP nicht verwalten, weil Letztere auf Altlasten setzen. Beide Seiten gleichziehen. Dritter Fehler: die Folgen für virtuelle Drucker (XPS, Fax, OneNote) zu übersehen. Für OneNote stellt Microsoft einen geschützten virtuellen Drucker bereit (ab OneNote-Version 2410 auf Windows 11 26100).

> **Praxisbeispiel**
>
> Beispielszenario: Eine Kanzlei ersetzt zwölf alte Multifunktionsgeräte durch Mopria-zertifizierte Modelle und aktiviert WPP für alle Rechner. Der Helpdesk kennt keine Treiberprobleme mehr, und die Prüfer beim Audit sehen ein deutlich kleineres Angriffsprofil der Druckwarteschlange.

## 97 Kamera-Zugriff steuern

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> App-Datenschutz  |
| Einstellung     | Kamerazugriff für Apps                                                                      |
| Empfehlung      | Nach Datenschutzvorgabe                                                                     |
| Ziel / Zweck    | Schützt Privatsphäre                                                                        |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Eine Kamera am Arbeitsplatz ist unverzichtbar für Videokonferenzen und zugleich ein Datenschutzthema. Die Richtlinie „Zulassen, dass Windows-Apps auf die Kamera zugreifen“ (*Let Windows apps access the camera*) legt fest, ob Apps die Kamera nutzen dürfen. Laut Policy-CSP-Dokumentation gibt es drei Zustände: „Benutzer hat die Kontrolle“ (Wert 0, Standard), „Erzwungen zulassen“ (Wert 1) und „Erzwungen verweigern“ (Wert 2); der restriktivste Wert ist 2. Die Einstellung steht unter Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> App-Datenschutz, im Registryschlüssel `Software\Policies\Microsoft\Windows\AppPrivacy`. Sie ist ab Windows 10, Version 1607 verfügbar.

Interessant ist die Feinsteuerung. Neben der Vorgabe für alle Apps lassen sich Listen von Apps angeben, die abweichend behandelt werden: „Diese Apps erzwungen zulassen“, „Diese Apps erzwungen verweigern“ und „Benutzer hat die Kontrolle für diese Apps“. Die Apps werden über ihren *Paketfamiliennamen* (*Package Family Name*) angegeben, den man mit dem Cmdlet `Get-AppPackage` ermittelt. Eine app-spezifische Angabe überschreibt die allgemeine Vorgabe. Ein typisches Konzept lautet daher: Vorgabe „verweigern“ und nur die Konferenz-App (zum Beispiel Teams) erzwungen zulassen. Laut Microsoft müssen offene Apps oder der Rechner neu gestartet werden, damit eine Änderung wirkt.

> **Ergänzung aus der Nachrecherche**
>
> Grenzen der Einstellung: Der Name sagt es schon, die Richtlinie betrifft *Windows-Apps* (Store-/Paket-Apps). Klassische Desktop-Programme, zu denen viele Konferenzprogramme gehören, unterliegen nach meiner Kenntnis einer eigenen Schaltfläche in den Windows-Einstellungen („Desktop-Apps den Zugriff erlauben“), die sich nicht über diese Richtlinie steuern lässt. Wer die Kamera wirklich sperren will, nutzt zusätzlich die Geräteinstallationsrichtlinien aus Abschnitt 91 (Gerätesperre per Klasse oder Geräte-ID). Auch der Datenschutz hat eine rechtliche Seite: Eine Kamera- oder Mikrofonsperre kann arbeitsrechtliche und datenschutzrechtliche Fragen berühren (keine Rechtsberatung); die Abstimmung mit Datenschutzbeauftragten und Betriebsrat ist vor der Einführung ratsam.

Das Beispiel setzt die Vorgabe „verweigern“ und nennt einen Paketfamiliennamen als Ausnahme. Den Namen der Ausnahme-App ermittelt der erste Block; im Beispiel ist der Platzhalter durch den tatsächlichen Namen zu ersetzen. Die Form der Liste (ein Wert, mehrere Namen durch Semikolon getrennt) entspricht den Angaben der Policy-CSP-Dokumentation zu `ForceAllowTheseApps`; die Registrywertnamen `LetAppsAccessCamera` und `LetAppsAccessCamera_ForceAllowTheseApps` sind aus meiner Kenntnis und im Pilot zu prüfen.

```ps
# 1) Paketfamiliennamen der erlaubten App ermitteln (Beispiel: Kamera-App)
Get-AppxPackage -AllUsers | Where-Object Name -match 'Camera|Teams' |
    Select-Object Name, PackageFamilyName

# 2) GPO: Vorgabe "verweigern" (2), Ausnahme fuer genannte Apps "erzwungen zulassen"
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEV-Kamera"
$ap  = "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $ap -ValueName LetAppsAccessCamera -Type DWord -Value 2
Set-GPRegistryValue -Name $gpo.DisplayName -Key $ap -ValueName LetAppsAccessCamera_ForceAllowTheseApps `
    -Type MultiString -Value @("MSTeams_8wekyb3d8bbwe")

# 3) Am Client: Wirkung pruefen
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" |
    Select-Object LetAppsAccessCamera, LetAppsAccessCamera_ForceAllowTheseApps
```

Der erste Block ermittelt Paketfamiliennamen. Der zweite legt die GPO an: Die Vorgabe 2 verweigert allen Apps den Zugriff, die Liste nennt Teams als Ausnahme (der Name im Beispiel ist ein Platzhalter und muss durch die Ausgabe von Schritt 1 ersetzt werden). Der dritte Block liest die wirksamen Werte zurück. Zeigt die App trotz Richtlinie noch die Kamera, wurde sie vermutlich vor der Verarbeitung geöffnet; Neustart der App klärt das.

**Typische Fehler.** Falsch: die Kamera zu sperren und die Konferenz-App zu vergessen. Am Montag stehen alle Videokonferenzen. Richtig: Ausnahmeliste vor dem Rollout, Pilot mit echten Besprechungen. Zweiter Fehler: zu glauben, die Richtlinie sperre die Hardware. Sie steuert den App-Zugriff, nicht das Gerät selbst; Desktop-Programme und Treiberzugriff bleiben davon unberührt. Dritter Fehler: die Paketfamiliennamen von Hand zu tippen. Richtig: aus `Get-AppxPackage` kopieren.

> **Praxisbeispiel**
>
> Beispielszenario: In einem Callcenter ist die Kamera nicht erlaubt. Die Vorgabe „verweigern“ gilt für alle Arbeitsplätze, in der Schulungs-OU ist sie „Benutzer hat die Kontrolle“. Bei einer Kundenprüfung zeigt die Firma die Richtlinie als Teil ihres Datenschutzkonzepts.

## 98 Mikrofon-Zugriff steuern

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> App-Datenschutz  |
| Einstellung     | Mikrofonzugriff für Apps                                                                    |
| Empfehlung      | Nach Datenschutzvorgabe                                                                     |
| Ziel / Zweck    | Schützt Privatsphäre                                                                        |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 2                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Für das Mikrofon gilt dieselbe Systematik wie für die Kamera aus Abschnitt 97: Die Richtlinie „Zulassen, dass Windows-Apps auf das Mikrofon zugreifen“ (*Let Windows apps access the microphone*) steht an derselben Stelle (App-Datenschutz), hat die Werte „Benutzer hat die Kontrolle“, „erzwungen zulassen“ und „erzwungen verweigern“ und kennt die drei App-Listen. Nach meiner Kenntnis heißen die Registrywerte `LetAppsAccessMicrophone`, `LetAppsAccessMicrophone_ForceAllowTheseApps` und so weiter und liegen im selben Schlüssel `AppPrivacy`; die ausdrückliche Bestätigung habe ich nur für die Kamera-Variante abgerufen, die Mikrofon-Variante ist daher im Pilot zu prüfen.

Was unterscheidet das Mikrofon aus Sicht des Datenschutzes? Der Schaden eines unbemerkten Mithörens ist größer, weil Gespräche im Raum aufgenommen werden können, und die Sichtbarkeit ist geringer: Eine Kamera hat oft eine Leuchte, ein Mikrofon nicht. Die Windows-Oberfläche zeigt aktive Mikrofonnutzung durch ein Symbol im Infobereich an (nach meiner Kenntnis), was aber kein Ersatz für eine technische Sperre ist. Dazu kommen Gegenstellen, die man leicht übersieht: Sprachassistenten, Diktierfunktionen und Spracherkennung, die ebenfalls auf das Mikrofon zugreifen; je nach Datenschutzvorgabe sind auch diese zu bewerten (siehe Modul 07).

> **Merke**
>
> Kamera und Mikrofon sind ein Paar, werden aber getrennt gesteuert. Es lohnt sich, beide Einstellungen in einer gemeinsamen GPO („DEV-Kamera-Mikrofon“) zu pflegen, denn Ausnahmen für Konferenz-Apps gelten fast immer für beide. Gleichzeitig sind die Ausnahmelisten pro Einstellung getrennt zu pflegen: Eine App, die nur das Mikrofon braucht (Diktierprogramm), soll keine Kamera bekommen.

Das Beispiel setzt die Mikrofonvorgabe analog zum Kameraskript und schreibt zusätzlich ein kurzes Prüfskript, das den Zustand beider Einstellungen auf einem Client als Objekt ausgibt. Das ist die Form, die man für eine Konformitätsprüfung über viele Rechner braucht.

```ps
Import-Module GroupPolicy
$gpo = Get-GPO -Name "DEV-Kamera"          # bestehende GPO erweitern
$ap  = "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $ap -ValueName LetAppsAccessMicrophone -Type DWord -Value 2
Set-GPRegistryValue -Name $gpo.DisplayName -Key $ap -ValueName LetAppsAccessMicrophone_ForceAllowTheseApps `
    -Type MultiString -Value @("MSTeams_8wekyb3d8bbwe")

# Konformitaetspruefung auf einem Client (als Objekt, fuer Sammlung ueber viele Rechner)
$p = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ErrorAction SilentlyContinue
$name = @{0='Benutzer entscheidet'; 1='Erzwungen zulassen'; 2='Erzwungen verweigern'}
[pscustomobject]@{
    Computer = $env:COMPUTERNAME
    Kamera   = if ($p -and $null -ne $p.LetAppsAccessCamera)     { $name[[int]$p.LetAppsAccessCamera] }     else { 'nicht konfiguriert' }
    Mikrofon = if ($p -and $null -ne $p.LetAppsAccessMicrophone) { $name[[int]$p.LetAppsAccessMicrophone] } else { 'nicht konfiguriert' }
}
```

Der erste Block erweitert die vorhandene GPO um die Mikrofon-Werte. Der zweite Block liest beide Einstellungen aus der Registry, übersetzt die Zahlen in Klartext (0, 1, 2) und behandelt den Fall, dass nichts konfiguriert ist. Die Ausgabe als Objekt ermöglicht es, die Ergebnisse vieler Rechner in einer Tabelle zusammenzuführen.

**Typische Fehler.** Falsch: Kamera zu sperren und das Mikrofon zu vergessen (oder umgekehrt), sodass ein Teil des Zwecks verfehlt wird. Richtig: beide Einstellungen gemeinsam planen. Zweiter Fehler: Headsets mit Mikrofon in der Geräteinstallation zu sperren (Abschnitt 91), obwohl man sie für Telefonie braucht; Mikrofonsperre und Geräteklasse getrennt entscheiden. Dritter Fehler: die Beschäftigten nicht zu informieren; wer nicht weiß, warum das Mikrofon in Teams nicht geht, ruft den Helpdesk an oder umgeht die Sperre mit privaten Geräten.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Krankenhaus sperrt das Mikrofon auf allen Stationsrechnern, um Gespräche über Patienten nicht versehentlich aufzuzeichnen. In den Besprechungsräumen gilt eine Ausnahme für die Konferenz-App. Die Konformitätsprüfung läuft monatlich per Skript und wird dem Datenschutzbeauftragten vorgelegt.

## 99 Bluetooth steuern

| **Feld**        | **Steckbrief**                                                                              |
|:----------------|:--------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Netzwerk \> Bluetooth                   |
| Einstellung     | Bluetooth-Richtlinien                                                                       |
| Empfehlung      | Nach Geräteklasse                                                                           |
| Ziel / Zweck    | Reduziert Funkangriffs- und Datenabflussrisiken                                             |
| Zielbereich     | Computer                                                                                    |
| Priorität       | 3                                                                                           |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren. |

Bluetooth ist ein Funkstandard für kurze Distanzen und verbindet Tastaturen, Mäuse, Headsets, Lautsprecher und Telefone. Funk bedeutet: Ein Angreifer muss nicht im Netz sein, es genügt die Nähe. Bluetooth-Geräte können sich zudem als etwas anderes ausgeben (eine Tastatur, die Befehle eintippt), und über Bluetooth lassen sich Dateien austauschen. Der Lehrplan verlangt eine Steuerung „nach Geräteklasse“. Eine ehrliche Anmerkung zum Pfad im Steckbrief: Einen klassischen ADMX-Pfad „Netzwerk \> Bluetooth“ habe ich bei der Recherche nicht bestätigen können. Die abgerufenen Microsoft-Seiten beschreiben Bluetooth-Einstellungen über den Policy CSP (Intune und andere MDM-Werkzeuge) sowie über die Geräteinstallationsrichtlinien. In einer rein gruppenrichtlinienbasierten Umgebung wird Bluetooth daher häufig über Abschnitt 91 gesteuert (Sperre der Bluetooth-Geräteklasse oder bestimmter Geräte-IDs), alternativ über Intune.

Welche Einstellungen die Dokumentation für den Policy CSP nennt: `AllowDiscoverableMode` (ob andere Geräte den Rechner finden können; Werte 0 und 1, Standard 1, der restriktivste Wert ist 0), `AllowAdvertising` (ob der Rechner Bluetooth-Werbung sendet), `AllowPrepairing` (verhindert, dass mitgelieferte Zubehörgeräte automatisch koppeln), `AllowPromptedProximalConnections` (unterdrückt Swift Pair und andere Nähe-Szenarien), `ServicesAllowedList` (erlaubte Dienste und Profile) und `LocalDeviceName`. Die Einstellung `ServicesAllowedList` realisiert die Steuerung nach Geräteklasse am genauesten: Man erlaubt nur bestimmte Dienste-UUIDs.

> **Ergänzung aus der Nachrecherche**
>
> Ein Beispiel aus Microsofts Dokumentation zu Passkeys: In Umgebungen mit eingeschränktem Bluetooth lässt sich der Funk komplett abschalten (Advertising 0, Discoverable 0, Prepairing 0, Proximal Connections 0) und über die Dienstliste nur der FIDO-Dienst zulassen (UUIDs `0000FFFD-0000-1000-8000-00805F9B34FB` und `0000FFF9-0000-1000-8000-00805F9B34FB`). Außerdem zeigt das Beispiel, wie man die Bluetooth-Netzwerkfunktion (PAN) über die Geräte-ID `BTH\MS_BTHPAN` per Geräteinstallationsrichtlinie sperrt, damit der Rechner nicht als Brücke oder zum Tethering dient. Die Dienste-UUID-Liste ist für die tatsächliche Gerätenutzung (Headsets, Mäuse) auf die benötigten Profile zu erweitern; eine fertige Liste habe ich nicht abgerufen.

Das Beispiel zeigt zwei Dinge: erstens die Inventur der Bluetooth-Geräte (Klasse `Bluetooth`), damit man weiß, was gebraucht wird; zweitens die Sperre des Bluetooth-PAN-Adapters per GPO-Registry, im Format der Geräteinstallationsrichtlinie. Die Registrywerte `DenyDeviceIDs` und `DenyDeviceIDsRetroactive` sind aus meiner Kenntnis und im Pilot zu prüfen; die Geräte-ID stammt aus der Microsoft-Dokumentation. In der Beispielausgabe ist das Zeichen `\` wörtlich zu lesen.

```ps
# 1) Inventur: welche Bluetooth-Geraete sind gekoppelt oder angeschlossen?
Get-PnpDevice -Class Bluetooth -PresentOnly |
    Select-Object FriendlyName, Status, InstanceId | Format-Table -AutoSize

# 2) GPO: nur den Bluetooth-PAN-Adapter (Tethering/Netzwerk) sperren, nicht Maus/Headset
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEV-Bluetooth-PAN"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DenyDeviceIDs -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key "$key\DenyDeviceIDs" -ValueName 1 -Type String -Value "BTH\MS_BTHPAN"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DenyDeviceIDsRetroactive -Type DWord -Value 1
```

Die Inventur zeigt gekoppelte und aktive Bluetooth-Geräte; sie macht sichtbar, ob Bluetooth wirklich gebraucht wird. Die GPO sperrt gezielt eine Geräte-ID (den PAN-Adapter), nicht den gesamten Bluetooth-Funk; die Rückwirkung ist hier bewusst eingeschaltet, weil nur dieses eine Gerät betroffen ist. Vorsicht bei der Ausweitung auf ganze Klassen: Sperrt man die Klasse „Bluetooth“ mit Rückwirkung, fallen auch Tastaturen und Mäuse aus, die über Bluetooth verbunden sind.

**Typische Fehler.** Falsch: Bluetooth pauschal zu sperren, ohne zu wissen, dass Mäuse, Headsets und Telefonie darauf laufen. Richtig: Inventur, dann gezielte Sperre. Zweiter Fehler: auf eine Gruppenrichtlinie zu warten, die es für Bluetooth so nicht gibt; die Steuerung läuft über Intune/CSP oder Geräteinstallation. Dritter Fehler: Passkey-Szenarien (Anmeldung per Telefon) zu übersehen, die Bluetooth als Nähe-Beleg nutzen; eine strikte Sperre kann diese Anmeldung verhindern.

> **Praxisbeispiel**
>
> Beispielszenario: Ein Produktionsunternehmen erlaubt nur firmeneigene Headsets und sperrt das Tethering. Das PAN-Gerät ist über die Geräte-ID gesperrt, Entdeckbarkeit abgeschaltet. Mitarbeiter können ihr Telefon nicht als Internetbrücke an den Arbeitsrechner hängen und damit die Firewall umgehen.

## 100 Automatische Wiedergabe deaktivieren

| **Feld**        | **Steckbrief**                                                                                  |
|:----------------|:------------------------------------------------------------------------------------------------|
| Pfad            | Computerkonfiguration \> Administrative Vorlagen \> Windows-Komponenten \> AutoPlay-Richtlinien |
| Einstellung     | AutoPlay deaktivieren                                                                           |
| Empfehlung      | Aktiviert für alle Laufwerke                                                                    |
| Ziel / Zweck    | Reduziert Malware-Start von Medien                                                              |
| Zielbereich     | Computer                                                                                        |
| Priorität       | 1                                                                                               |
| Rollout-Hinweis | Zuerst Pilot-OU/Testgruppe, danach gestaffelt produktiv ausrollen; Ausnahmen dokumentieren.     |

*AutoPlay* (deutsch „Automatische Wiedergabe“) beginnt laut Microsoft, von einem Laufwerk zu lesen, sobald ein Medium eingelegt wird; dadurch starten die Setupdatei eines Programms oder die Musik eines Datenträgers sofort. Genau das nutzten Würmer in der Vergangenheit: Sie legten eine Datei `autorun.inf` auf einen USB-Stick, und der Schadcode startete ohne weiteres Zutun des Benutzers. Die Microsoft-Baseline begründet die Härtung entsprechend: Ein Angreifer könnte die Funktion nutzen, um ein Programm zu starten, das den Rechner oder die Daten beschädigt. Sie stuft die Einstellung „Turn off Autoplay“ als kritisch ein und erwartet den Zustand „Aktiviert: Alle Laufwerke“.

Die technische Umsetzung ist ein Bitmuster im Registrywert `NoDriveTypeAutoRun` (Schlüssel `Software\Microsoft\Windows\CurrentVersion\Policies\Explorer`). Die Baseline erwartet den Wert 255 (hexadezimal `0xFF`), das heißt alle Laufwerkstypen. Die Option „CD-ROM- und Wechselmedienlaufwerke“ setzt dagegen den Wert `0xB5`, bei dem nur RAM-Laufwerke ausgenommen sind (Angabe der Microsoft-Dokumentation zu einem Sonderfall). Die Einstellung existiert sowohl in der Computer- als auch in der Benutzerkonfiguration; bei Konflikt hat die Computerkonfiguration Vorrang. Wichtig ist die Grenze: Mit der Richtlinie kann man AutoPlay nicht auf Laufwerken aktivieren, auf denen es standardmäßig deaktiviert ist.

> **Ergänzung aus der Nachrecherche**
>
> Microsoft dokumentiert in einem Troubleshooting-Artikel eine Nebenwirkung: Auf einem Laptop mit „HotStart“-Tasten (Windows 7) funktionierten die Tasten nicht mehr, nachdem AutoPlay für alle Laufwerke deaktiviert wurde (Wert `0xFF`). Als Abhilfe nennt die Dokumentation, die Option „CD-ROM- und Wechselmedienlaufwerke“ zu wählen. Das Beispiel ist alt, zeigt aber die Methode: Wer eine Härtung trifft, muss herstellerspezifische Software auf den eigenen Geräten testen. Nach meiner Kenntnis gibt es weitere AutoPlay-Richtlinien, etwa „Standardverhalten für AutoRun festlegen“ (keine AutoRun-Befehle ausführen) und „AutoPlay für Nicht-Volumegeräte deaktivieren“; ihre genauen Bezeichnungen und Werte habe ich nicht abgerufen und sind im Pilot zu prüfen.

Das Beispiel setzt die empfohlene Baseline-Einstellung per GPO, liest den Wert aus und rechnet das Bitmuster in lesbare Laufwerkstypen um. Die Bedeutung der Bits (Bit 2 Wechselmedien, Bit 3 Festplatten, Bit 4 Netzwerk, Bit 5 optische Laufwerke, Bit 6 RAM, Bit 7 unbekannte Typen) ist aus meiner Kenntnis; die beiden dokumentierten Werte 255 und 0xB5 lassen sich damit nachrechnen: `0xB5` hat die Bits für Wechselmedien (4), optische Laufwerke (32), unbekannte Typen (128) sowie die Bits 1 und 16 gesetzt.

```ps
Import-Module GroupPolicy
$gpo = New-GPO -Name "DEV-AutoPlay-Aus"
Set-GPRegistryValue -Name $gpo.DisplayName `
    -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ValueName NoDriveTypeAutoRun -Type DWord -Value 255

# Am Client: Wert lesen und in Laufwerkstypen uebersetzen
$wert = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ErrorAction SilentlyContinue).NoDriveTypeAutoRun
if ($null -eq $wert) { 'NoDriveTypeAutoRun nicht gesetzt: AutoPlay verhaelt sich nach Standard' }
else {
    $typen = @{ 4 = 'Wechselmedien'; 8 = 'Festplatten'; 16 = 'Netzlaufwerke'; 32 = 'Optische Laufwerke'; 64 = 'RAM-Laufwerke'; 128 = 'Unbekannt' }
    $aus = $typen.Keys | Where-Object { $wert -band $_ } | Sort-Object | ForEach-Object { $typen[$_] }
    "Wert $wert (0x{0:X}): AutoPlay deaktiviert fuer: {1}" -f $wert, ($aus -join ', ')
}
```

Der erste Block legt die GPO an und setzt den Baseline-Wert 255. Der zweite Block liest den Wert und prüft jedes Bit mit dem Operator `-band`; ausgegeben wird, für welche Laufwerkstypen AutoPlay abgeschaltet ist. Der Wert 255 deckt alle Typen ab; ein Wert von 181 (`0xB5`) würde dagegen nur die genannten Typen abschalten. Das Beispiel macht aus einer kryptischen Zahl eine prüfbare Aussage, die man in einer Konformitätsübersicht verwenden kann.

**Typische Fehler.** Falsch: AutoPlay nur in der Benutzerkonfiguration zu deaktivieren und die Computerseite zu vergessen, sodass Dienstkonten und neue Profile die Funktion behalten. Richtig: Computerkonfiguration setzen (sie hat Vorrang). Zweiter Fehler: zu glauben, damit sei das Medienproblem gelöst. AutoPlay verhindert nur den Start durch Einlegen; ein Benutzer, der eine Datei vom Stick öffnet, startet sie trotzdem. Dafür sind Defender, ASR-Regeln (Modul 02) und die Anwendungssteuerung (Modul 06) zuständig. Dritter Fehler: Spezialsoftware auf den eigenen Geräten nicht zu testen (siehe Ergänzung).

> **Praxisbeispiel**
>
> Beispielszenario: Auf einer Messe verteilt ein Aussteller Sticks mit Prospekten. Ein Besucher schließt einen davon an einen Arbeitsrechner an. Weil AutoPlay deaktiviert ist, startet nichts von selbst; der Defender (Modul 02) prüft die Dateien beim Öffnen, und die Schreibsperre aus Abschnitt 93 verhindert, dass Daten auf den Stick gehen.

## Übungsaufgaben zu Modul 10

**Aufgabe 1.** **(leicht)** Nennen Sie die vier Kennzeichen, nach denen die Geräteinstallationsrichtlinien Geräte unterscheiden, und ihre Rangfolge bei der geschichteten Auswertung.

**Aufgabe 2.** **(leicht)** Warum ist „Schreiben nur auf BitLocker-geschützte Medien“ oft besser als eine komplette Schreibsperre?

**Aufgabe 3.** **(leicht)** Was ist Point and Print, und warum war es Ziel der PrintNightmare-Angriffe?

**Aufgabe 4.** **(mittel)** Worin unterscheiden sich IPP und IPPS, und warum schützt IPPS ohne Zertifikatsprüfung nur begrenzt?

**Aufgabe 5.** **(mittel)** Was geschieht mit vorhandenen Druckern, wenn Windows Protected Print aktiviert wird, und wie bereiten Sie die Einführung vor?

**Aufgabe 6.** **(praktisch)** Schreiben Sie ein Skript, das alle angeschlossenen Geräte nach Klasse gruppiert und die Klassen-GUID ausgibt, und erzeugen Sie damit eine GPO, die eine Klasse Ihrer Wahl sperrt (ohne Rückwirkung).

**Aufgabe 7.** **(praktisch)** Schreiben Sie ein Konformitätsskript, das auf einem Client `Deny_Write`, `NoDriveTypeAutoRun` und `RestrictDriverInstallationToAdministrators` liest und als Objekt ausgibt.

**Aufgabe 8.** **(schwer)** Entwerfen Sie ein Geräte- und Druckkonzept für ein Unternehmen mit 400 Clients, einer Entwicklungsabteilung, einer Personalabteilung und 15 Netzwerkdruckern. Berücksichtigen Sie USB, Druck, Kamera/Mikrofon und Bluetooth, die Ausnahmeverfahren und die Abstimmung mit dem Datenschutz.

## Lösungen zu Modul 10

**Lösung 1.** Geräteinstanz-ID, Geräte-ID, Geräteklasse, Wechselgeräte. Die geschichtete Auswertung wertet in dieser Reihenfolge aus; die spezifischere Angabe gewinnt gegen die allgemeinere (Instanz-ID vor Geräte-ID vor Klasse vor Wechselgeräte), und innerhalb jeder Stufe wird zuerst das Verhindern, dann das Erlauben ausgewertet.

**Lösung 2.** Die Verschlüsselung schützt vor Verlust und Diebstahl und erlaubt trotzdem den Dateiaustausch mit freigegebenen Medien. Die komplette Schreibsperre ist wirksamer gegen Abfluss, aber unpraktisch und führt zu Umgehungen. Sinnvoll ist eine Abstufung nach Datenklassifizierung.

**Lösung 3.** Point and Print lädt Druckertreiber automatisch von einem Druckserver auf den Client. Der Treiber läuft im Spooler mit hohen Rechten. Verbindet man den Client mit einem bösartigen Server, kann dieser Code mit hohen Rechten einschleusen. Gegenmittel: Treiberinstallation nur für Administratoren, Serverliste, IPP statt Treiber.

**Lösung 4.** IPP überträgt im Klartext, IPPS mit TLS. Standardmäßig ignoriert Windows Zertifikatsfehler (damit selbstsignierte Zertifikate funktionieren). Ein Angreifer mit eigenem Zertifikat fällt dadurch nicht auf. Erst die aktivierte Zertifikatsprüfung mit Zertifikaten einer vertrauenswürdigen CA schließt die Lücke.

**Lösung 5.** Drucker mit Treibern von Drittanbietern werden deinstalliert und die Treiber aus dem Treiberspeicher entfernt; kompatible Drucker können neu installiert werden. Vorbereitung: Inventur, Mopria-Zertifizierung prüfen, Austauschplan, Pilotgruppe, Server und Clients gleich behandeln, virtuelle Drucker prüfen.

```ps
# Loesung 6
Get-PnpDevice -PresentOnly | Group-Object Class |
    Select-Object Count, Name, @{n='ClassGuid'; e={ ($_.Group | Select-Object -First 1).ClassGuid }} |
    Sort-Object Count -Descending

Import-Module GroupPolicy
$gpo = New-GPO -Name "DEV-Klasse-Sperre"
$key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DenyDeviceClasses -Type DWord -Value 1
Set-GPRegistryValue -Name $gpo.DisplayName -Key "$key\DenyDeviceClasses" -ValueName 1 -Type String -Value "{4d36e979-e325-11ce-bfc1-08002be10318}"
Set-GPRegistryValue -Name $gpo.DisplayName -Key $key -ValueName DenyDeviceClassesRetroactive -Type DWord -Value 0
```

```ps
# Loesung 7
function Get-Wert($pfad, $name) {
    $p = Get-ItemProperty $pfad -ErrorAction SilentlyContinue
    if ($p -and $null -ne $p.$name) { $p.$name } else { 'nicht gesetzt' }
}
[pscustomobject]@{
    Computer       = $env:COMPUTERNAME
    UsbDenyWrite   = Get-Wert "HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}" 'Deny_Write'
    AutoPlayMaske  = Get-Wert "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" 'NoDriveTypeAutoRun'
    TreiberNurAdmin = Get-Wert "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" 'RestrictDriverInstallationToAdministrators'
}
```

**Lösung 8.** Beispiel: Inventur der Geräte und Drucker. USB: Entwicklung harte Schreibsperre, Personal Lesemodus, übrige Abteilungen Schreiben nur auf BitLocker-geschützte Medien; Ausnahmen über eine Gruppe mit Frist. Geräteinstallation: Erlaubnisliste für Standardperipherie, geschichtete Auswertung, Pilot. Druck: Treiberinstallation nur Administratoren, Point and Print nur zu genehmigten Servern, Umstieg der 15 Drucker auf IPPS mit CA-Zertifikaten, WPP im Pilot nach Austausch inkompatibler Geräte. Kamera/Mikrofon: Vorgabe nach Datenschutzkonzept, Konferenz-App als Ausnahme. Bluetooth: Inventur, gezielte Sperre (PAN), Rest nach Bedarf. AutoPlay: überall aus. Datenschutz: Zweck, Information der Beschäftigten, Abstimmung mit Datenschutzbeauftragtem und Betriebsrat (keine Rechtsberatung). Risiken: Aussperren von Peripherie, Druckausfall, Umgehung durch private Geräte; Gegenmaßnahmen: Pilotringe, Rückfall-GPO, Helpdesk-Anleitung, Monitoring.
