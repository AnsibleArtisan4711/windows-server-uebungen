# 100 Gruppenrichtlinien für Windows 11 – Lernskript

Lernskript zu den 100 wichtigsten Gruppenrichtlinien für Windows 11 in Active-Directory- und Hybridumgebungen, nach einem eigenen Lehrplan in zehn Modulen mit je zehn Richtlinien. Jede Richtlinie hat einen Steckbrief (Pfad, Einstellung, Empfehlung, Ziel, Zielbereich, Priorität, Rollout-Hinweis), eine Erklärung, ein vollständiges Beispiel, typische Fehler und einen Praxisbezug. Am Ende jedes Moduls stehen acht Übungsaufgaben mit Lösungen. Den Gesamtüberblick bietet der [Index der 100 Richtlinien](docs/richtlinien-index.md).

## Wichtig: Was dieses Repository (noch) ist

- Es enthält das **Skript als Markdown**, ein Kapitel pro Modul (`skript.md`), dazu [Einleitung](docs/skript-einleitung.md), [Quellenverzeichnis](docs/skript-quellenverzeichnis.md) und [Index](docs/richtlinien-index.md) im Ordner `docs`.
- Eine eigenständige Übungsreihe mit Skripten, Testdateien und Lösungen je Modul ist **noch nicht** Teil des Repositories (die Übungsaufgaben am Kapitelende gehören zum Skript).
- **Die Beispiele (PowerShell, INF-Sicherheitsvorlagen) wurden für dieses Repository nicht ausgeführt.** Sie ändern Gruppenrichtlinien, Registrywerte und Sicherheitseinstellungen. Nur in einer Testumgebung (Testdomäne, Pilot-OU) verwenden, nie ungeprüft produktiv.
- Die Stundenangabe (1 Stunde je Richtlinie, 100 Stunden insgesamt) ist laut Einleitung eine Annahme und nicht aus dem Lehrplan abgeleitet.
- Die Recherche beruhte laut Quellenverzeichnis nur auf Suchausschnitten der Microsoft-Dokumentation; für die Module 02 bis 07 liegt keine vollständige Einzelliste der Adressen vor. Maßgeblich ist immer die aktuelle Dokumentation von Microsoft.
- Alle Empfehlungen müssen gegen Fachanwendungen, Hardware, Druck, VPN, Security-Tools und Betriebsprozesse pilotiert werden. Hinweise zu Datenschutz und Protokollierung von Beschäftigtendaten sind keine Rechtsberatung.

## Module

| Modul | Thema | Richtlinien | Dauer | Prio | Stand |
|---|---|---|---|---|---|
| [01](modul-01-security-baseline/) | Security Baseline | 1–10 | 10 h | überwiegend 1 (zwei Richtlinien mit Priorität 2) | Skript verfügbar |
| [02](modul-02-defender-asr/) | Defender und ASR | 11–20 | 10 h | überwiegend 1 (zwei Richtlinien mit Priorität 2) | Skript verfügbar |
| [03](modul-03-bitlocker-geraeteschutz/) | BitLocker und Geraeteschutz | 21–30 | 10 h | überwiegend 1 (vier Richtlinien mit Priorität 2) | Skript verfügbar |
| [04](modul-04-windows-firewall-netzwerk/) | Windows Firewall und Netzwerk | 31–40 | 10 h | überwiegend 1 (drei Richtlinien mit Priorität 2) | Skript verfügbar |
| [05](modul-05-update-servicing/) | Update und Servicing | 41–50 | 10 h | 1 bis 3 (fünf Richtlinien mit Priorität 1, vier mit Priorität 2, eine mit Priorität 3) | Skript verfügbar |
| [06](modul-06-anwendungssteuerung-browser/) | Anwendungssteuerung und Browser | 51–60 | 10 h | 1 und 2 (fünf Richtlinien je Stufe) | Skript verfügbar |
| [07](modul-07-benutzererlebnis-datenschutz/) | Benutzererlebnis und Datenschutz | 61–70 | 10 h | 1 bis 3 (zwei Richtlinien mit Priorität 1, vier mit Priorität 2, vier mit Priorität 3) | Skript verfügbar |
| [08](modul-08-konten-laps-rechte/) | Konten, LAPS und Rechte | 71–80 | 10 h | 1 und 2 (sieben Richtlinien mit Priorität 1, drei mit Priorität 2) | Skript verfügbar |
| [09](modul-09-audit-logging-forensik/) | Audit, Logging und Forensik | 81–90 | 10 h | 1 und 2 (sechs Richtlinien mit Priorität 1, vier mit Priorität 2) | Skript verfügbar |
| [10](modul-10-geraete-usb-druck/) | Geraete, USB und Druck | 91–100 | 10 h | 1 bis 3 (drei Richtlinien mit Priorität 1, sechs mit Priorität 2, eine mit Priorität 3) | Skript verfügbar |

Priorität: 1 = höchste.

## Lizenz

- **Code** (Beispieldateien und Skripte, falls das Repository solche enthält): [MIT-Lizenz](LICENSE)
- **Texte** (die Modul-READMEs, die Kapitel `skript.md` und die Dateien unter `docs/`): [CC BY 4.0](LICENSE-DOCS.md)
- Microsoft, Windows, Windows 11, Microsoft Defender, BitLocker und Active Directory sind Marken der Microsoft-Unternehmensgruppe; dieses Repository steht in keiner Verbindung zu Microsoft.

Autor: AnsibleArtisan4711
