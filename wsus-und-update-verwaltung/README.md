# WSUS und Update-Verwaltung: Übungsreihe

Praktische Übungen zum Lehrplan **P03 WSUS und Update-Verwaltung**. Diese Fassung deckt alle **12 Module** ab (104 UE, 78 Stunden zu 45 Minuten). Jede Übung besteht aus einer Markdown-Datei mit nummerierten Schritten. Zu jedem Schritt gibt es den Menüweg in der grafischen Oberfläche und, wo möglich, den PowerShell-Befehl.

**Status: Entwurf.** Nicht alles ist geprüft; jede Übung nennt ihren Teststand in einem Warnhinweis.

## Module

| Modul | Thema | Übung | UE |
|---|---|---|---|
| [01](01-update-verwaltung-und-wsus-lebenszyklus/) | Grundlagen der Update-Verwaltung und WSUS-Lebenszyklus | 01.1 | 8 |
| [02](02-laborumgebung-ad-und-netzwerk/) | Vorbereitung der Laborumgebung (AD und Netzwerk) | 02.1 | 8 |
| [03](03-wsus-installation-und-grundkonfiguration/) | WSUS Installation und Grundkonfiguration | 03.1 | 10 |
| [04](04-client-anbindung-per-gpo/) | Client-Anbindung mittels Gruppenrichtlinien (GPO) | 04.1 | 10 |
| [05](05-computergruppen-und-zielgruppenadressierung/) | WSUS-Computergruppen und Zielgruppenadressierung | 05.1 | 8 |
| [06](06-genehmigungen-und-zeitplaene/) | Update-Verwaltung, Genehmigungen und Zeitpläne | 06.1 | 10 |
| [07](07-berichte-und-compliance/) | Überwachung, Berichterstattung und Compliance | 07.1 | 8 |
| [08](08-wartung-und-bereinigung/) | Wartung, Bereinigung (Cleanup) und Optimierung | 08.1 | 8 |
| [09](09-datenbank-und-speicher/) | Datenbankverwaltung (WID vs. SQL) und Speicher (Priorität 2, optional) | 09.1 | 8 |
| [10](10-troubleshooting-und-diagnose/) | Troubleshooting und Diagnosewerkzeuge | 10.1 | 10 |
| [11](11-https-fuer-wsus/) | Sicherheit und Best Practices (SSL/TLS für WSUS) (Priorität 2, optional) | 11.1 | 8 |
| [12](12-moderne-alternativen/) | Moderne Alternativen: WUfB, Intune und Azure Update Manager (Priorität 2, optional) | 12.1 | 8 |

Die Module 09, 11 und 12 haben im Lehrplan Priorität 2 (Vertiefung) und können bei Zeitmangel gekürzt oder im Selbststudium bearbeitet werden. Modul 12 ist eine reine Konzeptaufgabe ohne Labor.

## Labor

Alle Übungen laufen in einem isolierten Hyper-V-Labor ohne Verbindung zu produktiven Netzen.

| Element | Wert |
|---|---|
| Switch | privat, `vSwitch-WSUS-Privat` |
| Netz | 192.168.100.0/24, ohne Gateway und ohne DHCP, alle Adressen statisch |
| `WSUS01` | Windows Server 2022 Evaluation, 192.168.100.10, AD DS, DNS und WSUS, Domäne `wsuslab.internal` (2 vCPU, mindestens 6 GB RAM, 100 GB) |
| `CLIENT01` | Windows 11 Enterprise Evaluation, 192.168.100.20, Generation 2 mit vTPM, in der OU `Clients` |

**Internetphasen:** `CLIENT01` hat nie Internet. `WSUS01` bekommt in den Modulen 03 und 06 (bei Bedarf 07 und 09) zeitweise einen zweiten Adapter `EXTERN` am `Default Switch` und wird danach wieder getrennt.

**Prüfpunkte:** `M2-Basis` (Ende Modul 02), `M3-WSUS` (nach Modul 03), `vor-M6`, `vor-M10`, `vor-M11`. Die Namen `vor-M6` und `vor-M10` sind Vorschläge dieser Reihe, der Lehrplan nennt für diese Stellen keinen Namen.

Server und Domänencontroller sind in diesem Labor dieselbe Maschine. Das ist eine Laborvereinfachung und nicht als Produktivdesign gedacht.

## Was geprüft wurde

- **Windows:** nichts ausgeführt. Am 12.11.2026 gelesen und mit den Übungen abgeglichen wurden bei Microsoft Learn: die Cmdlet-Liste des Moduls `UpdateServices` (`Get-WsusUpdate`, `Approve-WsusUpdate`, `Get-WsusComputer`, `Add-WsusComputer`, `Invoke-WsusServerCleanup`), `Get-WindowsUpdateLog`, das Reindex-Skript der WSUS-Datenbank und die Aussagen zum Lebenszyklus von WSUS und der Windows Internal Database. Alles Übrige ist mit „nicht bestätigt“ oder „sinngemäß“ markiert, besonders Menünamen, erwartete Ausgaben, API-Aufrufe, Fehlercodes und das Verhalten von `WsusUtil.exe`.
- **Fachlektorat:** Abweichungen und eigene Ergänzungen gegenüber dem Lehrplan stehen in [lehrplan-hinweise.md](lehrplan-hinweise.md).
- **Bekannte Lücken im Cmdlet-Umfang:** Das Modul `UpdateServices` hat kein Cmdlet zum Anlegen von Computergruppen und kein Cmdlet zum Entfernen von Computern. Die Übungen nutzen dafür die Konsole.

## Sicherheit

Die Übungen ändern Gruppenrichtlinien, Dienste, Zertifikate und Datenbanken und provozieren in Modul 10 absichtlich Fehler. Nur im Labor ausführen, nie auf produktiven Servern. Selbstsignierte Zertifikate (Modul 11) sind kein Muster für die Produktion.

## Lizenz

Skripte und Befehle: MIT ([LICENSE](../LICENSE)). Texte: CC BY 4.0 ([LICENSE-DOCS.md](../LICENSE-DOCS.md)).
