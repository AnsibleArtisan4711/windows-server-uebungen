# Hinweise zum Lehrplan P04 (Fachlektorat)

Stand: 12.11.2026. Abweichungen und Ergänzungen der Übungen gegenüber dem Lehrplan. Der Lehrplan selbst wurde nicht verändert.

## Ergänzungen, die der Lehrplan nicht vorgibt

| Stelle | Ergänzung | Grund |
|---|---|---|
| Alle Module | Zeitangaben in Stunden aus UE zu 45 Minuten | Der Lehrplan nennt UE; die Stundenangabe ist eine Schätzung |
| Modul 02 | Befehle für OUs, Benutzer, Gruppen, DNS und `Transfer.vhdx`; `Read-Host` für das Benutzerkennwort | Lehrplan nennt die Objekte, aber keine Befehle |
| Modul 02 | `CAPolicy.inf` per `Set-Content -Encoding Default` | ANSI-Kodierung ist gefordert, Kodierung des Cmdlets nicht bestätigt |
| Modul 03 | Befehle für Installation, `certutil -setreg`, CDP/AIA | Lehrplan beschreibt die Schritte in Worten |
| Modul 04 | `-OutputCertRequestFile` beim Installieren der SubCA | Parameter existiert laut Microsoft Learn (12.11.2026); Lehrplan lässt den Ablageort offen |
| Modul 07 | OCSP-URL alternativ mit `Add-CAAuthorityInformationAccess -AddToCertificateOcsp` | Cmdlet-Parameter laut Microsoft Learn (12.11.2026) |
| Modul 09 | `exportPSK=NO` und Hinweis zum gemeinsamen Geheimnis | Geheimnisse gehören nicht in Exporte |
| Modul 10 | `CAPolicy.inf` in die Sicherung aufgenommen | Gehört laut Migrationsablauf dazu |
| Modul 12 | CAPI2-Protokoll per `wevtutil` | Alternative zur Oberfläche, nicht bestätigt |

## Auffälligkeiten im Rohmaterial

- Modul 11 und der Lehrplan-Änderungsvermerk: Die Vorlage `Corp-Webserver-V1` trägt „Im Antrag angeben“. Ob die Bewertung „erfüllt ESC1 nicht“ trägt, hängt an den Registrierungsrechten und ist in der Übung als eigene Analyse formuliert, nicht als Fakt.
- Modul 07, Aufgabe 4: Der Lehrplan lässt offen, ob für die OCSP-Signaturvorlage Rechte direkt oder auf einer Kopie gesetzt werden. Die Übung folgt dem Lehrplan (direkt) und verweist auf Modul 05.
- „Nicht bestätigt“ laut Lehrplan und unverändert übernommen: INF-Syntax von `certreq`, deutsche Menü- und GPO-Namen, Dateinamen der CRL/CRT, Wirkung von `certutil -pulse`, Statusanzeige des Online Responders, Ereignis-IDs 4886/4887, Syntax von `netsh nps export`, Fehlercode bei Ausfall der Sperrprüfung, Browserverhalten bei erforderlichem Clientzertifikat, Jahr und URL des SpecterOps-Papers.
- Das Labor hat eine einzige Issuing-CA, die zugleich Webserver, Online Responder und NPS ist. Hochverfügbarkeit der CRL-Verteilung ist nicht abbildbar.
