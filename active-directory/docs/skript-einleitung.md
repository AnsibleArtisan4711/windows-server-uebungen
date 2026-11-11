# Einleitung

> **Hinweis:** Teil des Skripts „Active Directory – Lernskript“, aus der LaTeX-Quelle in Markdown umgewandelt. Die Kapitel zu den Modulen stehen als `skript.md` in den Modulordnern.

Dieses Skript begleitet den Kurs „Active Directory“ und folgt dem Lehrplan aus der Datei *Lehrplan - Active Directory.xlsx*. Jede Lerneinheit des Blatts „Lehrplan in Details“ bildet einen eigenen Abschnitt, in der Reihenfolge des Lehrplans. Jeder Abschnitt erklärt zuerst das Thema in zusammenhängender Prosa, zeigt dann ein vollständiges Beispiel mit Erläuterung, nennt typische Fehler mit Gegenbeispiel (falsch und richtig) und endet mit dem Praxisbezug. Am Ende jedes Moduls stehen Übungsaufgaben mit steigender Schwierigkeit; die Lösungen mit Erklärung folgen getrennt dahinter.

## Die Laborumgebung

Alle Beispiele verwenden dieselbe fiktive Umgebung: die Domain `corp.contoso.com` (NetBIOS-Name `CORP`) mit den Domain Controllern `DC01` (10.10.0.11) und `DC02` (10.10.0.12), dem Mitgliedsserver `SRV01` und dem Client `PC01`. Alle Namen, Adressen und Konten sind erfunden und dürfen ohne Bedenken in einer isolierten Testumgebung nachgebaut werden. Führen Sie die Skripte niemals ungeprüft in einer produktiven Domain aus. Die meisten Skripte unterstützen den Probelauf mit `-WhatIf`.

## Hinweise zur Struktur und zu den Stunden

Das Gesamtdokument bindet jedes Modul über das Paket `subfiles` ein; jedes Modul lässt sich auch einzeln kompilieren. Die Dateinamen enthalten Leerzeichen und Kommas und werden in Anführungszeichen eingebunden; das funktioniert mit der verwendeten Konfiguration (getestet mit `pdflatex`).

Beim Prüfen der Stunden fällt auf, dass das Blatt „Lehrplan in Details“ für jedes Modul 10,5 Stunden ergibt, während das Blatt „Lehrplan in Modulen“ je Modul 8, 12, 12, 12, 12, 10, 12, 12, 12, 12, 10 und 10 Stunden nennt. Die Abweichung wird in jedem Modulkopf offen ausgewiesen; die Seitenzahl der Module orientiert sich am höheren Wert.

> **Ergänzung aus der Nachrecherche**
>
> Kennzeichnung der Quellen: Fachliche Aussagen, die auf der Microsoft-Dokumentation beruhen, wurden über die Microsoft-Learn-Suche geprüft; die Liste im Quellenverzeichnis trennt „tatsächlich abgerufen“ und „weiterführend“. Aussagen ohne Quellenbeleg beruhen auf allgemeinem Fachwissen und sind an den betreffenden Stellen als solche gekennzeichnet. Rechtliche Hinweise sind keine Rechtsberatung.
