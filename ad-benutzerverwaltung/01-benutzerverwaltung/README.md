# Modul 01: Benutzerverwaltung

| Datei | Zweck |
|---|---|
| [01.1-benutzerverwaltung-im-active-directory.md](01.1-benutzerverwaltung-im-active-directory.md) | Übung mit Hintergrund, Prüfbefehlen, Musterlösung |
| `01.1-ou-struktur-anlegen.ps1` | Legt die OU-Struktur an (idempotent, `-WhatIf`) |
| `01.1-benutzer-anlegen.ps1` | Legt Benutzer aus der CSV an (Schlüssel: Personalnummer, Protokoll ohne Kennwörter) |
| `01.1-mitarbeiter.csv` | Übungsdaten, 13 Zeilen, zwei davon absichtlich fehlerhaft |
| `01.1-aufraeumen.ps1` | Setzt die Test-Domäne zurück (Schutz: nur `alpenwerk.example`) |

Skripte und CSV sind UTF-8 mit BOM gespeichert (Windows PowerShell 5.1). Beim Kopieren in der Kodierung belassen.
