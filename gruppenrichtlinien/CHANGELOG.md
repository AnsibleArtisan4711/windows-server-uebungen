# Changelog

Alle nennenswerten Änderungen an diesem Repository. Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/).

## [Unveröffentlicht]

### Hinzugefügt

- Skript als Markdown: `skript.md` und `README.md` in jedem der 10 Modulordner, `docs/skript-einleitung.md`, `docs/skript-quellenverzeichnis.md` und `docs/richtlinien-index.md` (aus der LaTeX-Quelle umgewandelt, 119 Codebeispiele zeichengleich geprüft)
- Lizenzen: MIT für Code (`LICENSE`), CC BY 4.0 für Texte (`LICENSE-DOCS.md`)

### Hinweise zur Umwandlung

- Überschriften der Richtlinien mit der laufenden Nummer 1 bis 100 (Modultabelle, Verweise „Abschnitt N“) statt der im LaTeX-Satz je Modul neu zählenden Nummern
- Modul 02: In der Quelle steht vor der letzten Lösung kein Zähler (`\setcounter`); sie ist hier als „Lösung 8“ nummeriert
- In den Modulen 02 bis 10 stehen einzelne Lösungen zu praktischen Aufgaben als Codeblöcke mit Kommentar („# Loesung …“) zwischen den Textlösungen
