# Hinweise zum Lehrplan P03 (Fachlektorat)

Stand: 12.11.2026. Abweichungen und Ergänzungen der Übungen gegenüber dem Lehrplan. Der Lehrplan selbst wurde nicht verändert.

## Ergänzungen, die der Lehrplan nicht vorgibt

| Stelle | Ergänzung | Grund |
|---|---|---|
| Alle Module | Zeitangaben in Stunden aus UE zu 45 Minuten | Der Lehrplan nennt UE; die Stundenangabe ist eine Schätzung |
| Modul 02 | Hinweis auf das virtuelle TPM (`Set-VMKeyProtector`, `Enable-VMTPM`) | Windows 11 braucht es; die Befehle sind nicht bestätigt |
| Modul 02 | Adapter in `LAB` umbenannt | Der Lehrplan nennt den Adapter `LAB`; ohne Umbenennung bleibt er `Ethernet` |
| Modul 03 | Feature-Namen mit `Get-WindowsFeature UpdateServices*` prüfen | Namen sind nicht bestätigt |
| Modul 03 | `appcmd`-Variante für die MIME-Typen | Alternative zur Oberfläche, Syntax nicht bestätigt |
| Modul 04 | Registryweg per `Set-GPRegistryValue` | gleichwertig zur Oberfläche, Parameter nicht bestätigt |
| Modul 04 | COM-Aufruf `DetectNow()` als Scan | `usoclient` ist nicht dokumentiert |
| Modul 06 | Prüfpunkt `vor-M6` | Lehrplan nennt den Prüfpunkt, aber keinen Namen |
| Modul 06 | `Get-WsusUpdate` kann Definitionsupdates nicht über `-Classification` filtern | Wertebereich `All`, `Critical`, `Security`, `WSUS` (Microsoft Learn, 12.11.2026) |
| Modul 08 | Geplante Aufgabe für die Bereinigung | Zusatz für 8.3, nur anlegen und prüfen |
| Modul 10 | Prüfpunkt `vor-M10`, Log nach `C:\Temp` | Zusatz, damit der Rückbau gesichert ist |
| Modul 12 | Teil 3 „Beurteilung“ der Nachfolger-Aussage | Kontrollfrage 3 des Lehrplans, als Aufgabe ausgeführt |

## Auffälligkeiten im Rohmaterial

- Das Modul `UpdateServices` bietet kein Cmdlet zum Anlegen von Computergruppen und keins zum Entfernen von Computern (Cmdlet-Liste von Microsoft Learn, 12.11.2026). Der Lehrplan verlangt in Modul 05 und 08 diese Schritte, ohne einen Weg zu nennen. Die Übungen verwenden die Konsole und für das Anlegen den API-Aufruf `CreateComputerTargetGroup` (nicht bestätigt).
- Modul 08, Aufgabe 4: Das Wiedererscheinen von `CLIENT01` nach dem Entfernen ist im Lehrplan als „erwartet, nicht bestätigt“ geführt. Die Übung übernimmt diese Kennzeichnung.
- Modul 07, Kontrollfrage 2: Die Formel für die „Prozentuale Übereinstimmung“ ist im Lehrplan nicht angegeben. Die Musterlösung gibt nur den sinngemäßen Anteil an und nennt die Formel nicht bestätigt.
- Modul 10: Die Fehlercodes `0x8024402C`, `0x80072EE2` und `0x80072EE6` werden im Lehrplan genannt. Die Bedeutungen in der Musterlösung stammen aus dem Gedächtnis und sind nicht bestätigt.
- Modul 11, Aufgabe 2: Der Lehrplan verlangt zuerst die IIS-Konfiguration von Hand und danach `WsusUtil.exe configuressl`. Ob beide Wege sich überlagern oder `configuressl` die Pflicht selbst setzt, ist nicht bestätigt.
- Quellen: Titel und Zuordnung des BSI-Bausteins OPS.1.1.3 sind laut Lehrplan nicht an der Originalquelle geprüft und bleiben so gekennzeichnet.

## Lebenszyklus

Laut Microsoft-Learn-Seite *Features removed or no longer developed in Windows Server* (gelesen am 12.11.2026) wird WSUS nicht mehr aktiv weiterentwickelt, bleibt aber unterstützt und erhält Sicherheits- und Qualitätsupdates. Die Windows Internal Database ist dort als deprecated geführt. Für Neuplanungen ist das relevant (Module 01, 09 und 12). Vor Kursstart erneut prüfen.
