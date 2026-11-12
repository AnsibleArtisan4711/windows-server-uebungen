# Windows Admin Center: Übungsreihe

Praktische Übungen zum Lehrplan **P61 Windows Admin Center**. Diese Fassung deckt alle **9 Module** ab (52 UE, 39 Stunden zu 45 Minuten). Jede Übung besteht aus einer Markdown-Datei mit Teilaufgaben, Menüweg in der grafischen Oberfläche und, wo möglich, dem PowerShell-Befehl.

**Status: Entwurf.** Nichts wurde auf Windows ausgeführt; jede Übung nennt ihren Teststand in einem Warnhinweis.

## Module

| Modul | Thema | Übung | UE |
|---|---|---|---|
| [01](01-grundlagen-architektur-einordnung/) | Grundlagen, Architektur, Lebenszyklus und Einordnung | 01.1 | 4 |
| [02](02-laborvorbereitung-und-installation/) | Laborvorbereitung und Installation des Gateways | 02.1 | 8 |
| [03](03-verbindungen-und-authentifizierung/) | Verbindungen und Authentifizierung | 03.1 | 5 |
| [04](04-verwaltung-rollen-dienste-speicher/) | Verwaltung von Rollen, Diensten, Speicher und Dateien | 04.1 | 8 |
| [05](05-zertifikate-und-absicherung/) | Zertifikate und Absicherung des Gateways | 05.1 | 5 |
| [06](06-berechtigungen-rbac-protokollierung/) | Berechtigungen, RBAC und Protokollierung | 06.1 | 6 |
| [07](07-updates-und-erweiterungen/) | Updates und Erweiterungen (Priorität 2, optional) | 07.1 | 5 |
| [08](08-hyperv-verwaltung/) | Hyper-V-Verwaltung im Windows Admin Center (Priorität 2, optional) | 08.1 | 5 |
| [09](09-fehlersuche-diagnose-abgrenzung/) | Fehlersuche, Diagnosewerkzeuge und Abgrenzung | 09.1 | 6 |

Die Module 07 und 08 haben im Lehrplan Priorität 2 (Vertiefung) und können bei Zeitmangel entfallen; kein Pflichtmodul setzt sie voraus und kein Rückbau hängt von ihnen ab.

## Labor

Alle Übungen laufen in einem isolierten Hyper-V-Labor ohne Verbindung zu produktiven Netzen und ohne Internet. Das Labor hat **keine Domäne**; Funktionen, die eine Domäne brauchen (Einmalanmeldung, gruppenbasierter Zugriff, Suche im Active Directory), werden nur als Theorie behandelt.

| Element | Wert |
|---|---|
| Switch | privat, `vSwitch-WAC-Privat` |
| Netz | 192.168.80.0/24, ohne Gateway, ohne DHCP, ohne DNS, alle Adressen statisch |
| `WAC01` | Windows Server 2025 Evaluation (Desktopdarstellung), 192.168.80.10, Arbeitsgruppe; Gateway und Browser (Laborvereinfachung) |
| `ZIEL01` | Windows Server 2025 Evaluation (Desktopdarstellung), 192.168.80.20, Arbeitsgruppe; Verwaltungsziel |

Namen: `wac01.wac.internal` und `ziel01.wac.internal` über die Datei `hosts`; Verwaltungskonto der lokale `Administrator`, weiterer Benutzer `leser01` (Modul 06).

**Prüfpunkte, immer auf beiden VMs gemeinsam:** `M2-Basis`, `M2-WAC`, `vor-M4`, `vor-M5`, `vor-M6`, `vor-M8`, `vor-M9`.

Das Installationsprogramm und die Evaluationsmedien werden **vor dem Labor** aus dem Internet geladen (Microsoft Evaluation Center) und per virtueller Festplatte oder ISO in die VMs gebracht. Danach gibt es kein Internet: kein Erweiterungsfeed, keine Azure-Funktionen, keine Online-Prüfung auf Updates. Zertifikate sind selbst signiert (Modul 05).

## Was geprüft wurde

- **Windows:** nichts ausgeführt. Am 12.11.2026 bei Microsoft Learn in Auszügen gelesen: Installationsmodi und Ports, Dienst `WindowsAdminCenter`, Cmdlets `Set-WACCertificateSubjectName` und `Set-WACCertificateAcl`, RBAC mit drei lokalen Gruppen, Ereigniskanal *WindowsAdminCenter*, Feeds, Lebenszyklusregeln. Alles Übrige (deutsche Menünamen, Installer-Wortlaut, Fehlermeldungen, Ausgaben) ist mit „nicht bestätigt“ markiert.
- **Syntax:** Die PowerShell-Blöcke wurden mit dem PowerShell-Parser geprüft (nicht ausgeführt).
- **Fachlektorat:** Abweichungen und Ergänzungen stehen in [lehrplan-hinweise.md](lehrplan-hinweise.md).

## Sicherheit

Die Übungen erzeugen ein Zertifikat mit privatem Schlüssel, ändern `TrustedHosts` und beenden Dienste. Nur im Labor ausführen. Kennwörter nur interaktiv eingeben, nichts davon in Berichte oder Repositories aufnehmen. Der Stammspeicher von `WAC01` wird nach dem Kurs bereinigt.

## Lizenz

Skripte und Befehle: MIT ([LICENSE](../LICENSE)). Texte: CC BY 4.0 ([LICENSE-DOCS.md](../LICENSE-DOCS.md)).
