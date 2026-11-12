# Hinweise zum Lehrplan P61 (Fachlektorat)

Stand: 12.11.2026. Abweichungen und Ergänzungen der Übungen gegenüber dem Lehrplan. Der Lehrplan selbst wurde nicht verändert.

## Ergänzungen, die der Lehrplan nicht vorgibt

| Stelle | Ergänzung | Grund |
|---|---|---|
| Alle Module | Zeitangaben in Stunden aus UE zu 45 Minuten | Der Lehrplan nennt UE; die Stundenangabe ist eine Schätzung |
| Modul 02 | Befehle für Switch, Adressen, `hosts`, `TrustedHosts`, Prüfpunkte; `Get-Credential` für Anmeldedaten | Lehrplan nennt die Schritte, aber nicht alle Befehle |
| Modul 03 | `Set-Content` für die Importliste | Lehrplan nennt den Import ohne Beispiel |
| Modul 04 | `New-VHD` und `Add-VMHardDiskDrive` für die Festplatte; `Get-Disk` vor dem Formatieren | Lehrplan nennt die Platte, der Host-Befehl und die Vorab-Prüfung sind ergänzt |
| Modul 05 | `Export-Certificate`, `Import-Certificate`, Abfrage des Fingerabdrucks per `SslStream` | Lehrplan nennt „Vertrauen herstellen“ und „Fingerabdruck prüfen“ ohne Befehl |
| Modul 06 | `New-LocalUser` mit `Read-Host -AsSecureString` | Lehrplan nennt den Benutzer `leser01` ohne Befehl |
| Modul 07 | `icacls` für den Feed-Ordner | Zugriff für Network Service laut Microsoft Learn; Syntax nicht bestätigt |
| Modul 09 | `$alt` als Sicherung des `TrustedHosts`-Werts vor dem Leeren | Verhindert, dass der Wert verloren geht |

## Auffälligkeiten im Rohmaterial

- **Keine Domäne:** Das Labor ist eine Arbeitsgruppe, weil die Vorgabe nur zwei Server vorsieht und das Gateway nicht auf einem Domänencontroller laufen darf. Einmalanmeldung, gruppenbasierter Zugriff und Suche im Active Directory sind darum Theorie.
- **Versionsstand:** Laut Release-History (12.11.2026) ist 2606 die jüngste Version; ob eine neuere erschienen ist, ist nicht bestätigt.
- **Nicht bestätigt laut Lehrplan und unverändert übernommen:** deutsche Menünamen, Installer-Wortlaut, Anmeldeseite, `Test-WSMan` mit Anmeldedaten, Fehlermeldungen der Störungen, Verhalten der Leserrolle, Hyper-V in der verschachtelten VM, Edge auf Windows Server 2025.

## Quellen (Microsoft Learn, am 12.11.2026 in Auszügen gelesen)

- https://learn.microsoft.com/windows-server/manage/windows-admin-center/overview
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/understand/what-is
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/understand/faq
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/plan/installation-options
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/deploy/install
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/deploy/prepare-environment
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/deploy/network-requirements
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/support/release-history
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/support/
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/support/known-issues
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/support/troubleshooting
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/use/get-started
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/use/manage-servers
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/use/logging
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/configure/shared-connections
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/configure/user-access-control
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/configure/update-certificate
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/configure/using-extensions
- https://learn.microsoft.com/windows-server/manage/windows-admin-center/configure/websocket-validation
- https://learn.microsoft.com/windows-server/security/kerberos/kerberos-constrained-delegation-overview
