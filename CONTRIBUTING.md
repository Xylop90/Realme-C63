# Beitragsrichtlinien / Contributing Guidelines

Vielen Dank für dein Interesse an Xtreme XA-vI ROM für Realme C63! Wir freuen uns über jeden Beitrag zur Verbesserung dieses Projekts.

Thank you for your interest in contributing to Xtreme XA-vI ROM for Realme C63! We welcome contributions from the community.

---

## 🌍 Sprachen / Languages

Diese Dokumentation ist auf Deutsch und Englisch verfügbar.  
This documentation is available in German and English.

---

## 🤝 Wie kann ich beitragen? / How Can I Contribute?

### Bug Reports / Fehlerberichte

Wenn du einen Bug findest:

1. **Prüfe**, ob der Bug bereits gemeldet wurde (GitHub Issues durchsuchen)
2. **Erstelle ein neues Issue** mit folgenden Informationen:
   - Klare Beschreibung des Problems
   - Schritte zur Reproduktion
   - Erwartetes vs. tatsächliches Verhalten
   - Screenshots (falls relevant)
   - Geräteinfo: ROM-Version, Android-Version, Build-Nummer
   - Logs (falls vorhanden)

If you find a bug:

1. **Check** if the bug has already been reported (search GitHub Issues)
2. **Create a new issue** with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs. actual behavior
   - Screenshots (if applicable)
   - Device info: ROM version, Android version, build number
   - Logs (if available)

### Feature Requests / Feature-Wünsche

Für neue Features:

1. **Durchsuche** bestehende Issues, um Duplikate zu vermeiden
2. **Erstelle ein Issue** mit:
   - Detaillierte Beschreibung des Features
   - Use Cases und Vorteile
   - Mögliche Implementierungsideen (optional)

For new features:

1. **Search** existing issues to avoid duplicates
2. **Create an issue** with:
   - Detailed feature description
   - Use cases and benefits
   - Possible implementation ideas (optional)

### Code-Beiträge / Code Contributions

#### Vorbereitung / Preparation

1. **Fork** das Repository
2. **Clone** deinen Fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Realme-C63.git
   cd Realme-C63
   ```
3. **Erstelle einen Branch** für deine Änderungen:
   ```bash
   git checkout -b feature/your-feature-name
   ```
   oder
   ```bash
   git checkout -b bugfix/issue-number-description
   ```

#### Entwicklung / Development

1. **Befolge die Code-Standards**:
   - Verwende konsistente Einrückung (4 Spaces für Shell-Skripte)
   - Kommentiere komplexen Code
   - Halte Funktionen klein und fokussiert
   - Validiere Shell-Skripte mit `bash -n script.sh`

2. **Teste deine Änderungen**:
   - Teste lokal auf deinem Gerät (falls möglich)
   - Prüfe, ob bestehende Funktionalität nicht beeinträchtigt wird
   - Dokumentiere Testschritte im Pull Request

3. **Commit-Nachrichten**:
   - Verwende klare, beschreibende Nachrichten
   - Format: `[type]: Brief description`
   - Typen: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
   - Beispiele:
     ```
     feat: Add battery optimization module
     fix: Resolve WiFi connection issue on boot
     docs: Update TWRP installation guide
     ```

4. **Dokumentation aktualisieren**:
   - Aktualisiere README.md, wenn nötig
   - Dokumentiere neue Features in den entsprechenden Guides
   - Füge Einträge zum CHANGELOG.md hinzu

#### Pull Request einreichen / Submitting a Pull Request

1. **Push** deinen Branch:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Erstelle einen Pull Request**:
   - Gehe zu deinem Fork auf GitHub
   - Klicke "New Pull Request"
   - Wähle deinen Branch
   - Fülle die PR-Beschreibung aus:
     - Was wurde geändert?
     - Warum wurde es geändert?
     - Wie wurde es getestet?
     - Screenshots (falls UI-Änderungen)
     - Referenziere relevante Issues (#issue-nummer)

3. **Code Review abwarten**:
   - Maintainer werden deinen PR prüfen
   - Sei offen für Feedback und Änderungsvorschläge
   - Aktualisiere deinen PR basierend auf Feedback

4. **Nach dem Merge**:
   - Lösche deinen Feature-Branch (optional)
   - Aktualisiere deinen Fork:
     ```bash
     git checkout main
     git pull upstream main
     git push origin main
     ```

## 📝 Code-Standards / Code Standards

### Shell-Skripte / Shell Scripts

- Verwende `#!/bin/bash` Shebang
- Aktiviere strict mode: `set -euo pipefail`
- Validiere Skripte mit `shellcheck` (falls verfügbar)
- Verwende aussagekräftige Variablennamen
- Kommentiere komplexe Logik
- Funktionen über 50 Zeilen sollten aufgeteilt werden

### Dokumentation

- Verwende Markdown für alle Dokumentationsdateien
- Halte Zeilen unter 100 Zeichen (wo möglich)
- Verwende klare Überschriften und Struktur
- Füge Code-Beispiele in Codeblöcken hinzu
- Aktualisiere das Datum "Last Updated" in geänderten Dokumenten

### Commit-Richtlinien

- Ein Commit pro logische Änderung
- Teste vor jedem Commit
- Verwende aussagekräftige Commit-Nachrichten
- Vermeide "WIP" oder "test" Commits im finalen PR

## 🔍 Review-Prozess / Review Process

1. **Automatische Checks**:
   - Shell-Skript Syntax-Validierung
   - Markdown-Lint (falls konfiguriert)

2. **Manuelle Review**:
   - Code-Qualität und -Stil
   - Funktionalität und Logik
   - Dokumentation und Kommentare
   - Potenzielle Sicherheitsprobleme

3. **Feedback**:
   - Konstruktives Feedback wird gegeben
   - Änderungen können angefordert werden
   - Diskussion über Implementierungsdetails

4. **Merge**:
   - Nach erfolgreicher Review wird der PR gemerged
   - Contributor wird in CHANGELOG.md erwähnt

## 🏆 Anerkennung / Recognition

- Alle Contributors werden im CHANGELOG.md erwähnt
- Signifikante Beiträge werden in Release Notes hervorgehoben
- Top Contributors können Maintainer-Rechte erhalten

## 💬 Kommunikation / Communication

- **GitHub Issues**: Für Bug Reports und Feature Requests
- **GitHub Discussions**: Für allgemeine Fragen und Diskussionen
- **Pull Requests**: Für Code-Reviews und technische Diskussionen

## 🚫 Was nicht erwünscht ist / What Not to Do

- Spam oder Off-Topic Beiträge
- Respektloses Verhalten gegenüber anderen
- Plagiate oder Copyright-Verletzungen
- Malicious Code oder Sicherheitslücken
- Ungetestete oder nicht funktionierende Änderungen

## ⚖️ Lizenz / License

Durch deinen Beitrag stimmst du zu, dass deine Arbeit unter der MIT License lizenziert wird, genau wie das Hauptprojekt.

By contributing, you agree that your contributions will be licensed under the MIT License, the same as the main project.

---

## 📚 Nützliche Ressourcen / Useful Resources

- [Git Tutorial](https://git-scm.com/docs/gittutorial)
- [Markdown Guide](https://www.markdownguide.org/)
- [Shell Scripting Tutorial](https://www.shellscript.sh/)
- [Android ROM Development](https://source.android.com/)

---

**Vielen Dank für deinen Beitrag! / Thank you for contributing!**

Bei Fragen kannst du jederzeit ein Issue erstellen oder die Maintainer kontaktieren.

If you have questions, feel free to create an issue or contact the maintainers.
