# AD-Übungen: Benutzerverwaltung im Active Directory

Praxisübung zur Benutzerverwaltung in einer **eigenen, isolierten Test-Domäne** (zwei Hyper-V-VMs, privater Switch). Alle Namen, Firmen und Domänen sind frei erfunden (`alpenwerk.example`).

## Inhalt

| Modul | Übung | Stufe |
|---|---|---|
| [01-benutzerverwaltung](01-benutzerverwaltung/) | 01.1 Benutzerverwaltung im Active Directory (Benutzer anlegen, Alltag, Rechte über A-G-DL-P) | Aufbau |

## Stand

**Entwurf.** Die PowerShell-Skripte wurden mit einem simulierten ActiveDirectory-Modul getestet, nicht in einem echten Active Directory. Einzelne Befehle und Ausgaben sind in der Übung als „nicht bestätigt“ gekennzeichnet. Abweichungen bitte als Issue melden.

## Sicherheit

- Nur in einer isolierten Testumgebung ausführen, nie in einer produktiven Domäne.
- Die Skripte enthalten und protokollieren keine Kennwörter.
- `01.1-aufraeumen.ps1` löscht die Übungs-OUs und prüft vorher den Domänennamen.

## Lizenz

Skripte: MIT ([LICENSE](LICENSE)). Texte und Anleitungen: CC BY-NC-SA 4.0 ([LICENSE-DOCS.md](LICENSE-DOCS.md)). Microsoft, Windows und Active Directory sind Marken der Microsoft-Gruppe; dieses Projekt steht in keiner Verbindung zu Microsoft.
