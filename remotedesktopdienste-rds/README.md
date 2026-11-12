# Remotedesktopdienste (RDS): Übungsreihe

Praktische Übungen zum Lehrplan **P59 Remotedesktopdienste (RDS)**. Diese Fassung deckt alle **13 Module** ab (104 UE, 78 Stunden zu 45 Minuten). Jede Übung besteht aus einer Markdown-Datei mit Teilaufgaben, Menüweg in der grafischen Oberfläche und, wo möglich, dem PowerShell-Befehl.

**Status: Entwurf.** Nichts wurde auf Windows ausgeführt; jede Übung nennt ihren Teststand in einem Warnhinweis. Der Lehrplan selbst wurde noch nicht geprüft.

## Module

| Modul | Thema | Übung | UE |
|---|---|---|---|
| [01](01-rds-grundlagen-und-architektur/) | RDS-Grundlagen, Architektur und Lizenzüberblick | 01.1 | 8 |
| [02](02-laborvorbereitung/) | Vorbereitung der Laborumgebung | 02.1 | 6 |
| [03](03-sitzungsbasierte-bereitstellung/) | Bereitstellung der sitzungsbasierten Umgebung | 03.1 | 10 |
| [04](04-sitzungssammlungen/) | Sitzungssammlungen und Desktopzugriff | 04.1 | 8 |
| [05](05-remoteapps-und-web-access/) | RemoteApps und Web Access | 05.1 | 8 |
| [06](06-zertifikate/) | Zertifikate für Remotedesktopdienste | 06.1 | 8 |
| [07](07-remotedesktopgateway/) | Remotedesktopgateway (Priorität 2, optional) | 07.1 | 8 |
| [08](08-lizenzierung/) | Lizenzierung (RDS-CALs) | 08.1 | 8 |
| [09](09-benutzerprofil-datentraeger/) | Profilverwaltung mit Benutzerprofil-Datenträgern | 09.1 | 8 |
| [10](10-gruppenrichtlinien-fuer-rds/) | Gruppenrichtlinien für RDS | 10.1 | 8 |
| [11](11-druck-und-laufwerksumleitung/) | Druck- und Laufwerksumleitung (Priorität 2, optional) | 11.1 | 6 |
| [12](12-sicherheit-und-nla/) | Sicherheit und Netzwerkebenenauthentifizierung | 12.1 | 8 |
| [13](13-ueberwachung-und-fehlersuche/) | Überwachung und Fehlersuche | 13.1 | 10 |

Die Module 07 und 11 haben im Lehrplan Priorität 2 (Vertiefung) und können bei Zeitmangel entfallen; kein Pflichtmodul setzt sie voraus.

## Labor

Alle Übungen laufen in einem isolierten Hyper-V-Labor ohne Verbindung zu produktiven Netzen und ohne Internet.

| Element | Wert |
|---|---|
| Switch | privat, `vSwitch-RDS-Privat` |
| Netz | 192.168.70.0/24, ohne Gateway und ohne DHCP, alle Adressen statisch |
| `DC01` | Windows Server 2022 Evaluation, 192.168.70.10, AD DS und DNS, Domäne `rdslab.internal` (vor Kursbeginn aufgebaut) |
| `RDS01` | Windows Server 2022 Evaluation (Desktopdarstellung), 192.168.70.20; trägt Connection Broker, Web Access, Session Host, ab Modul 07 Gateway, ab Modul 08 Licensing |
| `CL01` | Windows 11 Enterprise Evaluation, 192.168.70.50, Generation 2 mit virtuellem TPM |

Namen: OUs `RDS-Server` und `Clients`, Benutzer `user1` und `user2`, Gruppen `SG-RDS-Users` und `SG-RDS-Verwaltung`, Alias `rds.rdslab.internal` (CNAME auf `rds01.rdslab.internal`).

**Prüfpunkte, immer auf allen drei VMs gemeinsam:** `M2-Basis`, `M3-RDS`, `M6-Zert`, `vor-M10`, `vor-M12`, `vor-M13`.

Alle Rollen auf einem Server und der Domänencontroller als Dateiserver für die UPD-Freigabe (Modul 09) sind Laborvereinfachungen und kein Produktivdesign. Eine CAL-Aktivierung ist im Labor ohne Internet nicht möglich (Modul 08 behandelt sie als Theorie). Zertifikate sind selbst signiert (Modul 06).

## Was geprüft wurde

- **Windows:** nichts ausgeführt. Am 12.11.2026 bei Microsoft Learn gelesen: Lizenzmodelle, Aktivierungswege und Versionsregeln, Lizenzmodus und WMI-Aufrufe für den Grace-Zeitraum, Zertifikatsanforderungen und `Set-RDCertificate`, Syntax von `New-RDSessionDeployment` und `Set-RDSessionCollectionConfiguration`, UPD-Grenzen, Gateway-Zertifikat und Bypass-Option, Ursachen der Meldung „restricted the types of logon“. Alles Übrige (deutsche Menünamen, Parameter von `New-RDSessionCollection`, `New-RDRemoteApp`, `Add-RDServer`, GPO-Pfade für Sitzungslimits und Umleitung, Ereignisprotokollnamen, Ausgaben) ist mit „nicht bestätigt“ oder „sinngemäß“ markiert.
- **Fachlektorat:** Abweichungen und Ergänzungen stehen in [lehrplan-hinweise.md](lehrplan-hinweise.md).

## Sicherheit

Die Übungen erzeugen Zertifikate mit privaten Schlüsseln (`.pfx`), UPD-Freigaben und Gruppenrichtlinien. Nur im Labor ausführen. `.pfx`-Dateien, Kennwörter und Prüfpunkte gehören nicht in Berichte oder Repositories. Der Stammspeicher von `CL01` wird nach dem Kurs wieder bereinigt.

## Lizenz

Skripte und Befehle: MIT ([LICENSE](../LICENSE)). Texte: CC BY 4.0 ([LICENSE-DOCS.md](../LICENSE-DOCS.md)).
