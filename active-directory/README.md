# Active Directory – Lernskript

Lernskript zu Active Directory Domain Services in zwölf Modulen: von Grundlagen und Architektur über Installation, Design, Objektverwaltung, DNS, Sites und Replikation, FSMO und Global Catalog, Gruppenrichtlinien und Authentifizierung bis zu Security und Tiering, Backup und Disaster Recovery, Monitoring und Hybrid Identity. Jede Lerneinheit hat eine Erklärung, ein vollständiges Beispiel (meist PowerShell), typische Fehler mit Gegenbeispiel und einen Praxisbezug. Am Ende jedes Moduls stehen acht Übungsaufgaben mit Lösungen.

## Wichtig: Was dieses Repository (noch) ist

- Es enthält das **Skript als Markdown**, ein Kapitel pro Modul (`skript.md`), dazu [Einleitung](docs/skript-einleitung.md) und [Quellenverzeichnis](docs/skript-quellenverzeichnis.md) im Ordner `docs`.
- Eine eigenständige Übungsreihe mit Skripten, Testdateien und Lösungen je Modul ist **noch nicht** Teil des Repositories (die Übungsaufgaben am Kapitelende gehören zum Skript).
- **Die Beispiele (PowerShell) wurden für dieses Repository nicht ausgeführt.** Sie setzen eine Windows-Server-Laborumgebung voraus (fiktive Domain `corp.contoso.com`, `DC01`, `DC02`, `SRV01`, `PC01`) und verändern Verzeichnisobjekte, DNS, Replikation und Sicherheitseinstellungen. Nur in einer isolierten Testumgebung verwenden, nie ungeprüft in einer produktiven Domain.
- **Stundenangaben:** In jedem Modul weicht die Summe der Lerneinheiten laut Detailblatt (je 10,5 Stunden) von der Dauer laut Modulübersicht ab (zusammen 134 Stunden laut Modulübersicht). Das Skript behandelt alle Lerneinheiten vollständig; die Abweichung ist im Lehrplan selbst zu klären (siehe Einleitung).
- Die Recherche beruhte laut Quellenverzeichnis überwiegend auf Suchausschnitten der Microsoft-Dokumentation. Maßgeblich ist immer die aktuelle Dokumentation von Microsoft.

## Module

| Modul | Thema | Dauer laut Übersicht | Summe Detailblatt | Prio | Stand |
|---|---|---|---|---|---|
| [01](modul-01-grundlagen-architektur/) | Grundlagen und Architektur | 8 Stunden | 10,5 Stunden | 1 | Skript verfügbar |
| [02](modul-02-ad-ds-installation-deployment/) | AD DS Installation und Deployment | 12 Stunden | 10,5 Stunden | 1 | Skript verfügbar |
| [03](modul-03-forest-domain-ou-design/) | Forest-, Domain- und OU-Design | 12 Stunden | 10,5 Stunden | 1 | Skript verfügbar |
| [04](modul-04-benutzer-gruppen-computer/) | Benutzer, Gruppen, Computer | 12 Stunden | 10,5 Stunden | 1 | Skript verfügbar |
| [05](modul-05-dns-sites-replikation/) | DNS, Sites und Replikation | 12 Stunden | 10,5 Stunden | 1 | Skript verfügbar |
| [06](modul-06-fsmo-gc-dc-betrieb/) | FSMO, Global Catalog, DC-Betrieb | 10 Stunden | 10,5 Stunden | 1 | Skript verfügbar |
| [07](modul-07-gruppenrichtlinien-konfiguration/) | Gruppenrichtlinien und Konfiguration | 12 Stunden | 10,5 Stunden | 1 | Skript verfügbar |
| [08](modul-08-authentifizierung-autorisierung/) | Authentifizierung und Autorisierung | 12 Stunden | 10,5 Stunden | 1 | Skript verfügbar |
| [09](modul-09-security-hardening-tiering/) | Security, Hardening, Tiering | 12 Stunden | 10,5 Stunden | 1 | Skript verfügbar |
| [10](modul-10-backup-restore-dr/) | Backup, Restore, Disaster Recovery | 12 Stunden | 10,5 Stunden | 1 | Skript verfügbar |
| [11](modul-11-monitoring-troubleshooting/) | Monitoring und Troubleshooting | 10 Stunden | 10,5 Stunden | 1 | Skript verfügbar |
| [12](modul-12-hybrid-identity-migration-governance/) | Hybrid Identity, Migration, Governance | 10 Stunden | 10,5 Stunden | 2 | Skript verfügbar |

Priorität: 1 = höchste.

## Lizenz

- **Code** (Beispieldateien und Skripte, falls das Repository solche enthält): [MIT-Lizenz](LICENSE)
- **Texte** (die Modul-READMEs, die Kapitel `skript.md` und die Dateien unter `docs/`): [CC BY 4.0](LICENSE-DOCS.md)
- Microsoft, Windows, Windows Server, Active Directory und Microsoft Entra sind Marken der Microsoft-Unternehmensgruppe; dieses Repository steht in keiner Verbindung zu Microsoft.

Autor: AnsibleArtisan4711
