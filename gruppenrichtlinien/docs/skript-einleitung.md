# Einleitung

> **Hinweis:** Teil des Skripts „Gruppenrichtlinien für Windows 11 – 100 Richtlinien im Detail“, aus der LaTeX-Quelle in Markdown umgewandelt. Die Kapitel zu den Modulen stehen als `skript.md` in den Modulordnern.

> **Hinweis zur Umwandlung:** Der folgende Text ist unverändert aus der Quelle übernommen. Die dort genannten Grün-Kästen („Ergänzung aus der Nachrecherche“) erscheinen hier als Zitatblöcke mit fettem Titel; ebenso die Kästen **Merke** und **Praxisbeispiel**. Die Überschriften der Richtlinien tragen in der Markdown-Fassung die laufende Nummer 1 bis 100.

Dieses Skript erklärt die 100 Gruppenrichtlinien (englisch *Group Policy Objects*, kurz GPO) des Lehrplans „100 Gruppenrichtlinien“ für Windows 11 in Active-Directory- und Hybridumgebungen. Eine Gruppenrichtlinie ist eine zentral definierte Sammlung von Einstellungen, die Windows beim Start und bei der Anmeldung des Benutzers von einem Domänencontroller abholt und lokal durchsetzt. Der Lehrplan gliedert die 100 Richtlinien in zehn Kategorien. In diesem Skript entspricht jede Kategorie einem Modul, und jede Richtlinie bekommt einen eigenen Abschnitt.

**Wichtiger Hinweis zur Planung.** Der Lehrplan enthält keine Stundenangaben. Für den Richtwert „mindestens eine Seite pro Unterrichtsstunde“ wird deshalb angenommen, dass jede Richtlinie eine Unterrichtsstunde umfasst, ein Modul also 10 Stunden. Diese Annahme ist nicht aus dem Lehrplan abgeleitet und sollte bei Bedarf angepasst werden.

**Grundlage.** Es lagen keine eigenen Kursunterlagen vor. Der Inhalt beruht auf dem Lehrplan, Fachwissen und einer Recherche in der Microsoft-Dokumentation. Ergänzungen aus der Recherche sind in grünen Kästen gekennzeichnet. Die verwendeten Quellen stehen am Ende des Skripts.

**Aufbau eines Abschnitts.** Jeder Abschnitt beginnt mit einem Steckbrief aus dem Lehrplan (Pfad, Einstellung, Empfehlung, Ziel, Zielbereich, Priorität, Rollout-Hinweis). Es folgen die Erklärung, ein vollständiges Beispiel, typische Fehler und der Praxisbezug.

**Vorgehen im Betrieb.** Der Lehrplan empfiehlt für jede Richtlinie, zuerst eine Pilot-OU oder Testgruppe zu verwenden, danach gestaffelt auszurollen und Ausnahmen zu dokumentieren. Das gilt als Grundregel für das ganze Skript. Wo diese Regel nicht uneingeschränkt funktioniert (zum Beispiel bei Kennwortrichtlinien für Domänenkonten), wird es im jeweiligen Abschnitt erklärt.

**Haftungshinweis.** Alle Empfehlungen müssen gegen Fachanwendungen, Hardware, Druck, VPN, Security-Tools und Betriebsprozesse pilotiert werden. Die Beispiele sind für eine Testumgebung gedacht und nicht ungeprüft produktiv einzusetzen.
