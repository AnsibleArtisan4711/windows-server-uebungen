# Zertifikatsdienste und PKI (AD CS): Übungsreihe

Praktische Übungen zum Lehrplan **P04 Zertifikatsdienste und PKI (AD CS)**. Diese Fassung deckt alle **12 Module** ab (116 UE, 87 Stunden zu 45 Minuten). Jede Übung besteht aus einer Markdown-Datei mit Teilaufgaben, Menüweg in der grafischen Oberfläche und, wo möglich, dem PowerShell-Befehl.

**Status: Entwurf.** Nichts wurde auf Windows ausgeführt; jede Übung nennt ihren Teststand in einem Warnhinweis.

## Module

| Modul | Thema | Übung | UE |
|---|---|---|---|
| [01](01-pki-grundlagen/) | Grundlagen der Public Key Infrastructure (PKI) | 01.1 | 8 |
| [02](02-design-und-vorbereitung/) | Design und Vorbereitung einer zweistufigen PKI | 02.1 | 8 |
| [03](03-offline-root-ca/) | Bereitstellung der Offline-Root-CA | 03.1 | 12 |
| [04](04-enterprise-issuing-ca/) | Bereitstellung der ausstellenden Enterprise-CA | 04.1 | 12 |
| [05](05-zertifikatvorlagen/) | Verwaltung von Zertifikatvorlagen (Templates) | 05.1 | 10 |
| [06](06-ausstellung-und-autoenrollment/) | Zertifikatsausstellung und Autoenrollment | 06.1 | 10 |
| [07](07-sperrlisten-und-ocsp/) | Sperrlisten (CRL) und Online Responder (OCSP) | 07.1 | 12 |
| [08](08-webserver-und-client-zertifikate/) | Zertifikate für Webserver und Clients | 08.1 | 10 |
| [09](09-zertifikatsbasierte-authentifizierung/) | Zertifikatsbasierte Authentifizierung (802.1X / NPS) (Priorität 2, optional) | 09.1 | 10 |
| [10](10-sicherung-und-wiederherstellung/) | Sicherung, Wiederherstellung und Migrationskonzept der CA | 10.1 | 8 |
| [11](11-sicherheit-und-fehlkonfigurationen/) | Sicherheit, Fehlkonfigurationen und Best Practices | 11.1 | 8 |
| [12](12-troubleshooting-und-diagnose/) | Troubleshooting und Diagnosewerkzeuge (Priorität 2, optional) | 12.1 | 8 |

Die Module 09 und 12 haben im Lehrplan Priorität 2 (Vertiefung) und können bei Zeitmangel gekürzt werden.

## Labor

Alle Übungen laufen in einem isolierten Hyper-V-Labor ohne Verbindung zu produktiven Netzen.

| Element | Wert |
|---|---|
| Switch | privat, `vSwitch-PKI-Privat` |
| Netz | 192.168.60.0/24, ohne Gateway und ohne DHCP, alle Adressen statisch |
| `DC01` | Windows Server 2022 Evaluation, 192.168.60.10, AD DS und DNS, Domäne `corp.internal` (vor Kursbeginn aufgebaut) |
| `ROOTCA01` | Windows Server 2022 Evaluation, Arbeitsgruppe, **ohne Netzwerkadapter**; Datenaustausch nur über `Transfer.vhdx` (1 GB, NTFS, Laufwerk `T:`) |
| `SUBCA01` | Windows Server 2022 Evaluation, 192.168.60.20; Enterprise Issuing CA, zugleich IIS (CDP/AIA), Online Responder und NPS |
| `CL01` | Windows 11, 192.168.60.50, tritt in Modul 06 der Domäne bei |

Namen: CA `Corp-Root-CA` und `Corp-Issuing-CA`, Alias `pki.corp.internal` (CNAME auf `subca01.corp.internal`), `www.corp.internal`.

**Prüfpunkte:** `M4-PKI` (`DC01`, `SUBCA01`) am Ende von Modul 04; Rückweg vor den Modulen 10 und 11. Für `ROOTCA01` gibt es keinen Prüfpunkt, sondern die Sicherung in Modul 10.

Eine einzige Issuing-CA ist zugleich Webserver, Online Responder und NPS. Das ist eine Laborvereinfachung und nicht als Produktivdesign gedacht.

## Was geprüft wurde

- **Windows:** nichts ausgeführt. Am 12.11.2026 bei Microsoft Learn gelesen: die Parameter von `Install-AdcsCertificationAuthority`, `Add-CACrlDistributionPoint` und `Add-CAAuthorityInformationAccess`, sowie die certutil-Verben `-backupdb`, `-backupkey`, `-restoredb`, `-restorekey`, `-dspublish`, `-CATemplates`, `-CAInfo` und `-setreg chain\ChainCacheResyncFiletime`. Alles Übrige (INF-Syntax von `certreq`, deutsche Menünamen, Dateinamen von CRL und CRT, Ereignis-IDs, Fehlercodes, Ausgaben) ist mit „nicht bestätigt“ oder „sinngemäß“ markiert.
- **Fachlektorat:** Abweichungen und Ergänzungen stehen in [lehrplan-hinweise.md](lehrplan-hinweise.md).

## Sicherheit

Die Übungen erzeugen CA-Schlüssel, Sicherungen mit privaten Schlüsseln, Sperrungen und in Modul 11 eine Analyse einer unsicheren Vorlage. Nur im Labor ausführen. Schlüsseldateien, Kennwörter und gemeinsame Geheimnisse (Modul 09) gehören nicht in Berichte oder Repositories. Die Vorlage `Corp-Risk-Web` wird nie veröffentlicht.

## Lizenz

Skripte und Befehle: MIT ([LICENSE](../LICENSE)). Texte: CC BY 4.0 ([LICENSE-DOCS.md](../LICENSE-DOCS.md)).
