# Dateidienste, DFS und Druckserver: Übungsreihe

Praktische Übungen zum Lehrplan **P02 Dateidienste, DFS und Druckserver**. Diese Fassung deckt alle **12 Module** ab (120 UE). Jede Übung besteht aus einer Markdown-Datei mit nummerierten Schritten. Zu jedem Schritt gibt es den Menüweg in der grafischen Oberfläche und, wo möglich, den PowerShell-Befehl.

**Status: Entwurf.** Nicht alles ist geprüft; jede Übung nennt ihren Teststand in einem Warnhinweis.

## Module

| Modul | Thema | Übung | UE |
|---|---|---|---|
| [01](01-dateiserver-und-smb/) | Grundlagen Windows Dateiserver und SMB | 01.1 | 10 |
| [02](02-berechtigungen-ntfs-und-freigaben/) | Berechtigungskonzepte: Freigabe- und NTFS-Berechtigungen | 02.1 | 12 |
| [03](03-schattenkopien-und-vorgaengerversionen/) | Dateiserver-Verwaltung, Schattenkopien und Vorgängerversionen | 03.1 | 8 |
| [04](04-fsrm-kontingente-und-dateiblockierung/) | FSRM Teil 1: Kontingente (Quotas) und Dateiprüfung | 04.1 | 10 |
| [05](05-fsrm-klassifizierung-und-speicherberichte/) | FSRM Teil 2: Dateiklassifizierung und Speicherberichte (Priorität 2, optional) | 05.1 | 8 |
| [06](06-dfs-namespaces/) | Distributed File System (DFS): Namespaces | 06.1 | 10 |
| [07](07-dfs-replikation/) | Distributed File System (DFS): Replikation | 07.1 | 10 |
| [08](08-offlinedateien-und-branchcache/) | Offlinedateien und BranchCache (Priorität 2, optional) | 08.1 | 8 |
| [09](09-druckserver-grundlagen/) | Grundlagen Windows Druckserver | 09.1 | 10 |
| [10](10-druckerpools-und-gpo-verteilung/) | Fortgeschrittenes Druckmanagement und GPO-Verteilung | 10.1 | 10 |
| [11](11-fehlersuche-datei-und-druckdienste/) | Troubleshooting: Dateidienste und Druckserver | 11.1 | 10 |
| [12](12-abschlussprojekt/) | Abschlussprojekt: Datei- und Druckdienste mit DFS-Ausfallsicherheit | 12.1 | 14 |

Die Module 05 und 08 haben im Lehrplan Priorität 2 (optional). Das Abschlussprojekt (12) braucht sie nicht.

## Labor

Alle Übungen laufen in einem isolierten Hyper-V-Labor ohne Verbindung zu produktiven Netzen.

| Element | Wert |
|---|---|
| Switch | privat, `vSwitch-File-Privat` |
| Netz | 192.168.10.0/24, ohne Gateway und ohne DHCP |
| `DC1` | Windows Server 2022 Evaluation, 192.168.10.10, AD DS und DNS, Domäne `corp.example.internal` |
| `FS1` | Windows Server 2022 Evaluation, 192.168.10.20, Dateiserver und Druckserver |
| `FS2` | Windows Server 2022 Evaluation, 192.168.10.21, ab Modul 6 |
| `CL1` | Windows 11 Enterprise Evaluation, 192.168.10.50 |

Vor jedem Modul einen Checkpoint anlegen (`m00-labor-fertig`, danach `mNN-ende`). Die Übungen nehmen die deutsche Oberfläche an (Gruppen `Domänen-Benutzer`, `Jeder`, NetBIOS-Name `CORP`). Bei englischer Oberfläche ersetzt du die Namen, die Stellen sind im Text vermerkt.

## Was geprüft wurde

- **Windows:** nichts ausgeführt. Cmdlets, Parameter und Dokumentationsaussagen wurden stichprobenweise gegen Microsoft Learn geprüft (Datum und Umfang stehen im Warnhinweis jeder Übung). Alles Übrige ist mit „nicht bestätigt“ oder „sinngemäß“ markiert, besonders Menünamen, erwartete Ausgaben und das Verhalten von DFS und Druckverteilung.
- **Fachlektorat:** Abweichungen und eigene Ergänzungen gegenüber dem Lehrplan sind im Text gekennzeichnet (z. B. gekappte Vererbung, `DL_IT_Modify` in Modul 12).
- **Bekannte Einzelpunkte des Ausfalls:** `DC1` und der Druckserver `FS1` (Modul 12).

## Sicherheit

Die Übungen ändern Berechtigungen, Freigaben, Dienste und schalten in Modul 11 und 12 Server ab. Nur im Labor ausführen, nie auf produktiven Servern.

## Lizenz

Skripte und Befehle: MIT ([LICENSE](../LICENSE)). Texte: CC BY 4.0 ([LICENSE-DOCS.md](../LICENSE-DOCS.md)).
