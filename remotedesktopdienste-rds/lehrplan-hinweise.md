# Hinweise zum Lehrplan P59 (Fachlektorat)

Stand: 12.11.2026. Abweichungen und Ergänzungen der Übungen gegenüber dem Lehrplan. Der Lehrplan selbst wurde nicht verändert.

## Ergänzungen, die der Lehrplan nicht vorgibt

| Stelle | Ergänzung | Grund |
|---|---|---|
| Alle Module | Zeitangaben in Stunden aus UE zu 45 Minuten | Der Lehrplan nennt UE; die Stundenangabe ist eine Schätzung |
| Modul 02 | Befehle für Switch, Adressen, DNS, Domänenbeitritt, OUs, Benutzer, Gruppen und Prüfpunkte; `Read-Host` für Kennwörter | Lehrplan nennt die Objekte, aber keine Befehle |
| Modul 03 | Alternative `New-RDSessionDeployment` und `Get-RDServer` | Lehrplan nennt die Oberfläche; Syntax laut Microsoft Learn (12.11.2026) |
| Modul 06 | Export der öffentlichen `.cer`-Dateien über die Admin-Freigabe und `Import-Certificate` | Lehrplan nennt „Vertrauen herstellen“ ohne Weg |
| Modul 07 | `Set-RDDeploymentGatewayConfiguration -BypassLocal` als Alternative | Parameter laut Microsoft Learn (12.11.2026); `-GatewayMode` ist ebenfalls Pflicht und im Text vermerkt |
| Modul 08 | WMI-Aufrufe für Grace-Zeitraum, Lizenzserverliste und Lizenzart | Aufrufe laut Troubleshooting-Artikel (12.11.2026); Lehrplan nennt `GetGracePeriodDays` nur sinngemäß |
| Modul 09 | `Grant-SmbShareAccess` und `icacls` mit dem Computerkonto `RDS01$` | Lehrplan nennt „Vollzugriff für `RDS01$`“ ohne Befehl |
| Modul 10 | GPO-Anlage mit `New-GPO` und `New-GPLink` | Lehrplan nennt die Schritte in Worten |
| Modul 12 | Lesen des Registrywerts `UserAuthentication` mit `Get-ItemProperty` | Wert laut Microsoft Learn (12.11.2026) |
| Modul 13 | `Get-WinEvent -ListLog '*TerminalServices*'` | Namen der Protokolle sind im Lehrplan *nicht bestätigt* |

## Auffälligkeiten im Rohmaterial

- **Lizenzstand im Labor:** Eine Aktivierung des Lizenzservers und die Installation von CALs sind ohne Internet und ohne gültigen Lizenzcode nicht möglich. Modul 08 behandelt sie darum als Theorie; praktisch gearbeitet wird mit dem Grace-Zeitraum.
- **Versionsregel der CALs:** Der erste Entwurf des Lehrplans nannte sie falsch herum. Korrigiert nach Microsoft Learn: CAL-Version muss zum Session Host passen und darf nicht neuer sein als der Lizenzserver.
- **Prüfpunkte:** Der Lehrplan verlangt gemeinsame Prüfpunkte aller drei VMs, weil ein einzelner Rücksetzer des Domänencontrollers das Verzeichnis gegen die anderen VMs verschieben kann. Die Übungen setzen das um.
- **Supportstand:** Windows Server 2022 ist laut Microsoft Learn (Seite vom 13.10.2026) seit dem 13.10.2026 im erweiterten Support. Der Evaluationszeitraum von Windows Server 2022 und Windows 11 ist nicht geprüft.
- **Nicht bestätigt laut Lehrplan und unverändert übernommen:** deutsche Menünamen, Parameter von `New-RDRemoteApp` und `Add-RDServer`, Rollennamen in `Get-RDServer`, GPO-Pfade für Verbindungsgrenzen, Sitzungslimits und Umleitung, Namen der TerminalServices-Protokolle, Wirkung der NLA-Richtlinie auf einen laufenden Server.
- **Kein Hochverfügbarkeitsszenario:** Ein zweiter Session Host, ein Broker-Cluster und ein Gateway im Randnetz sind im 3-VM-Labor nicht abbildbar.
