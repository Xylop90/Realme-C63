# Frequently Asked Questions (FAQ)
## Häufig gestellte Fragen

Diese FAQ beantwortet die häufigsten Fragen zu Xtreme XA-vI ROM für Realme C63.

This FAQ answers the most common questions about Xtreme XA-vI ROM for Realme C63.

---

## Table of Contents / Inhaltsverzeichnis

- [General Questions / Allgemeine Fragen](#general-questions--allgemeine-fragen)
- [Installation Questions / Installations-Fragen](#installation-questions--installations-fragen)
- [Device & Compatibility / Gerät & Kompatibilität](#device--compatibility--gerät--kompatibilität)
- [Features & Performance / Features & Leistung](#features--performance--features--leistung)
- [Issues & Troubleshooting / Probleme & Fehlerbehebung](#issues--troubleshooting--probleme--fehlerbehebung)
- [Root & Modifications / Root & Modifikationen](#root--modifications--root--modifikationen)
- [Updates & Support / Updates & Unterstützung](#updates--support--updates--unterstützung)

---

## General Questions / Allgemeine Fragen

### Was ist Xtreme XA-vI ROM? / What is Xtreme XA-vI ROM?

**DE:** Xtreme XA-vI ist eine leistungsoptimierte Custom ROM für das Realme C63, basierend auf Android 14. Sie bietet verbesserte Performance, reduzierte Bloatware, erweiterte Sicherheit und Anpassungsmöglichkeiten.

**EN:** Xtreme XA-vI is a performance-optimized custom ROM for Realme C63, based on Android 14. It offers improved performance, reduced bloatware, enhanced security, and customization options.

### Ist diese ROM kostenlos? / Is this ROM free?

**Ja / Yes!** Diese ROM ist Open Source und kostenlos unter der MIT License verfügbar.

Yes! This ROM is open source and freely available under the MIT License.

### Wer entwickelt diese ROM? / Who develops this ROM?

**DE:** Die ROM wird entwickelt von Alexander Mathey (Elektronikx-Center-Matte) und der Community.

**EN:** The ROM is developed by Alexander Mathey (Elektronikx-Center-Matte) and the community.

### Ist diese ROM stabil? / Is this ROM stable?

**DE:** Version 1.0 ist derzeit in der Beta-Phase. Während sie bereits gut funktioniert, können noch Bugs auftreten. Erstelle immer ein Backup vor der Installation!

**EN:** Version 1.0 is currently in beta phase. While it already works well, bugs may still occur. Always create a backup before installation!

---

## Installation Questions / Installations-Fragen

### Wie installiere ich die ROM? / How do I install the ROM?

Siehe unsere detaillierten Guides / See our detailed guides:
1. [Bootloader Unlock](docs/BOOTLOADER_UNLOCK.md)
2. [TWRP Installation](docs/TWRP_INSTALLATION.md)
3. [ROM Installation](docs/ROM_INSTALLATION.md)

### Muss ich meinen Bootloader entsperren? / Do I need to unlock my bootloader?

**Ja / Yes!** Ein entsperrter Bootloader ist **zwingend erforderlich** für die Installation jeder Custom ROM.

Yes! An unlocked bootloader is **mandatory** for installing any custom ROM.

### Werden meine Daten gelöscht? / Will my data be erased?

**Ja / Yes:**
- Bootloader-Entsperrung löscht **alle Daten**
- Clean Flash (empfohlen) löscht **alle Daten**
- Dirty Flash (Update) behält Daten, aber Backup wird **dringend empfohlen**

Yes:
- Bootloader unlocking erases **all data**
- Clean flash (recommended) erases **all data**
- Dirty flash (update) keeps data, but backup is **strongly recommended**

### Brauche ich einen PC für die Installation? / Do I need a PC for installation?

**Empfohlen / Recommended:** Ja, für Bootloader-Unlock und Fastboot-Installation.

**Alternative:** Installation über TWRP direkt auf dem Gerät möglich (ohne PC).

Yes, recommended for bootloader unlock and fastboot installation.

Alternative: Installation via TWRP directly on device possible (without PC).

### Wie lange dauert die Installation? / How long does installation take?

**Gesamt / Total:** 30-60 Minuten
- Bootloader Unlock: 5-10 Minuten
- TWRP Installation: 5 Minuten
- ROM Installation: 10-15 Minuten
- Erster Boot: 5-15 Minuten

### Kann ich ohne TWRP installieren? / Can I install without TWRP?

**Ja / Yes,** über Fastboot ist möglich, aber TWRP wird **stark empfohlen** für:
- Backups
- Einfachere Installation
- Fehlerbehebung

Yes, via fastboot is possible, but TWRP is **strongly recommended** for:
- Backups
- Easier installation
- Troubleshooting

---

## Device & Compatibility / Gerät & Kompatibilität

### Für welche Geräte ist diese ROM? / What devices is this ROM for?

**Nur / Only:** Realme C63

**Nicht kompatibel mit / Not compatible with:** Anderen Realme-Modellen / Other Realme models

### Funktioniert es mit Realme C63 5G?

**Nein / No.** Diese ROM ist **nur für Realme C63 4G**. Installation auf anderen Modellen kann zu Bricks führen!

No. This ROM is **only for Realme C63 4G**. Installing on other models may brick your device!

### Welche Android-Version? / What Android version?

**Android 14** mit Realme UI 5.0 Basis.

### Funktionieren alle Hardware-Features? / Do all hardware features work?

**Ziel / Goal:** Ja, alle Features sollen funktionieren.

**Beta-Phase:** Manche Features können Bugs haben. Siehe [Known Issues](docs/CHANGELOG.md#known-issues).

Goal: Yes, all features should work.

Beta phase: Some features may have bugs. See [Known Issues](docs/CHANGELOG.md#known-issues).

---

## Features & Performance / Features & Leistung

### Was sind die Hauptvorteile? / What are the main advantages?

- ⚡ Bessere Performance / Better performance
- 🔋 Längere Akkulaufzeit / Longer battery life
- 🎯 Weniger Bloatware / Less bloatware
- 🔒 Verbesserte Sicherheit / Enhanced security
- 🎨 Mehr Anpassungsmöglichkeiten / More customization

### Ist die ROM schneller als Stock? / Is the ROM faster than stock?

**Ja / Yes!** Erwartete Verbesserungen:
- 15-20% schnellere Systemgeschwindigkeit
- Reduzierter RAM-Verbrauch
- Schnellere App-Starts
- Optimierte Boot-Zeit

Expected improvements:
- 15-20% faster system speed
- Reduced RAM usage
- Faster app launches
- Optimized boot time

### Sind Google Apps enthalten? / Are Google apps included?

**Nein / No.** GApps müssen separat installiert werden. Siehe [ROM Installation Guide](docs/ROM_INSTALLATION.md#step-5-install-gapps-optional).

No. GApps must be installed separately. See [ROM Installation Guide](docs/ROM_INSTALLATION.md#step-5-install-gapps-optional).

### Kann ich die ROM anpassen? / Can I customize the ROM?

**Ja / Yes!** Die ROM bietet viele Anpassungsmöglichkeiten:
- Themes
- Fonts
- Icons
- Status bar
- Navigation
- Performance-Profile

---

## Issues & Troubleshooting / Probleme & Fehlerbehebung

### Gerät bootet nicht / Device won't boot

**Lösungen / Solutions:**
1. Warte mindestens 15 Minuten beim ersten Boot
2. Boot in TWRP → Wipe Cache/Dalvik
3. Falls nötig: Clean Flash wiederholen
4. Als letztes: TWRP Backup wiederherstellen

### Boot Loop (ständiges Neustarten) / Boot loop

**Lösungen / Solutions:**
1. Boot in TWRP
2. Wipe Cache + Dalvik Cache
3. Falls weiter: Factory Reset + ROM neu flashen
4. Stelle sicher, dass du die richtige ROM-Version hast

### Kein Mobilfunknetz / No mobile network

**Lösungen / Solutions:**
1. Überprüfe APN-Einstellungen
2. Netzwerkeinstellungen zurücksetzen
3. SIM-Karte neu einlegen
4. ROM neu flashen mit komplettem Wipe

### WiFi/Bluetooth funktioniert nicht / WiFi/Bluetooth not working

**Lösungen / Solutions:**
1. Flugmodus ein/aus
2. Netzwerkeinstellungen zurücksetzen
3. Wipe Cache in TWRP
4. ROM neu flashen

### Apps stürzen ab / Apps crashing

**Lösungen / Solutions:**
1. Cache/Daten der App löschen
2. App neu installieren
3. Wipe Dalvik/ART Cache in TWRP
4. Überprüfe ob GApps korrekt installiert sind

### Akku entlädt sich schnell / Battery draining fast

**Normal:** Erste 2-3 Tage - System optimiert sich.

**Lösungen / Solutions:**
1. Warte ein paar Tage
2. Überprüfe Akkuverbrauch in Einstellungen
3. Deaktiviere ungenutzte Hintergrunddienste
4. Reduziere Bildschirmhelligkeit

### Kamera funktioniert nicht / Camera not working

**Lösungen / Solutions:**
1. Cache/Daten der Kamera-App löschen
2. Überprüfe Kamera-Berechtigungen
3. Probiere alternative Kamera-App
4. ROM neu flashen

---

## Root & Modifications / Root & Modifikationen

### Ist die ROM gerootet? / Is the ROM rooted?

**Nein / No.** Root ist optional. Du kannst Magisk installieren, wenn du Root möchtest.

No. Root is optional. You can install Magisk if you want root.

### Wie roote ich mein Gerät? / How do I root my device?

Siehe [Rooting Guide](docs/ROOTING_GUIDE.md) für detaillierte Anweisungen mit Magisk.

See [Rooting Guide](docs/ROOTING_GUIDE.md) for detailed instructions with Magisk.

### Funktionieren Banking-Apps? / Do banking apps work?

**Ohne Root:** Ja, sollten funktionieren.

**Mit Root:** Verwende Magisk Hide/DenyList, um Root vor Banking-Apps zu verstecken.

Without root: Yes, should work.

With root: Use Magisk Hide/DenyList to hide root from banking apps.

### Kann ich Xposed/LSPosed verwenden? / Can I use Xposed/LSPosed?

**Ja / Yes,** wenn du gerootet bist. Installation auf eigene Gefahr.

Yes, if you're rooted. Install at your own risk.

### Kann ich einen Custom Kernel installieren? / Can I install a custom kernel?

**Ja / Yes,** aber teste vorsichtig. Inkompatible Kernel können Boot Loops verursachen.

Yes, but test carefully. Incompatible kernels may cause boot loops.

---

## Updates & Support / Updates & Unterstützung

### Wie oft gibt es Updates? / How often are updates released?

**Sicherheitsupdates:** Monatlich (geplant)

**Feature-Updates:** Nach Bedarf

**Major Releases:** Mehrmals pro Jahr

Security updates: Monthly (planned)

Feature updates: As needed

Major releases: Several times per year

### Wie installiere ich Updates? / How do I install updates?

**Dirty Flash (empfohlen für Updates):**
1. Download neue ROM-Version
2. Boot in TWRP
3. Wipe nur Dalvik/Cache
4. Flash neue ROM
5. Reboot

**Clean Flash (für Major Updates):**
- Vollständiger Wipe + Neuinstallation

### Funktionieren OTA-Updates? / Do OTA updates work?

**Aktuell / Currently:** Nein, manuelle Installation erforderlich.

**Geplant / Planned:** OTA-Support in zukünftigen Versionen.

Currently: No, manual installation required.

Planned: OTA support in future versions.

### Verliere ich Root nach Update? / Do I lose root after update?

**Ja / Yes,** Magisk muss nach jedem ROM-Update neu installiert werden.

Yes, Magisk needs to be reinstalled after each ROM update.

### Gibt es eine Community? / Is there a community?

**Ja / Yes:**
- GitHub Issues: Bug-Reports und Fragen
- GitHub Discussions: Community-Diskussionen (falls aktiviert)
- XDA Developers: Community-Forum

### Kann ich downgraden? / Can I downgrade?

**Ja / Yes,** aber mache einen Clean Flash. Dirty Flash bei Downgrades kann Probleme verursachen.

Yes, but do a clean flash. Dirty flash when downgrading may cause problems.

---

## Safety & Security / Sicherheit

### Ist die Installation sicher? / Is installation safe?

**Ja / Yes,** wenn du die Anleitungen befolgst. **Aber:**
- Garantie wird ungültig
- Bootloader-Unlock reduziert Sicherheit
- Immer Backups erstellen!

Yes, if you follow the instructions. But:
- Warranty is voided
- Bootloader unlock reduces security
- Always create backups!

### Kann ich mein Gerät "bricken"? / Can I brick my device?

**Unwahrscheinlich / Unlikely,** aber möglich bei:
- Installation auf falsches Gerät
- Unterbrochene Installation
- Inkompatible Modifications

**Schutz / Protection:**
- TWRP Backup vor Installation
- Befolge Anleitungen genau
- Stelle sicher: richtiges Gerät + richtige ROM

### Was passiert mit meiner Garantie? / What happens to my warranty?

**Bootloader-Unlock ungültig macht Garantie.**

In einigen Regionen kannst du Garantieansprüche verlieren.

Bootloader unlock voids warranty.

In some regions you may lose warranty claims.

### Sind meine Daten sicher? / Is my data safe?

**Ja / Yes:**
- Verschlüsselung bleibt aktiv
- Keine Spyware/Malware
- Open Source (du kannst Code prüfen)

**Empfehlung / Recommendation:**
- Verwende starkes Passwort
- Aktiviere Geräteverschlüsselung
- Regelmäßige Backups

---

## Miscellaneous / Sonstiges

### Kann ich zur Stock ROM zurückkehren? / Can I return to stock ROM?

**Ja / Yes:**
1. Download offizielle Stock ROM
2. Flash über Fastboot oder offizielles Flash-Tool
3. Bootloader kann wieder gesperrt werden (optional)

### Funktioniert Netflix/Amazon Prime? / Does Netflix/Amazon Prime work?

**Normalerweise ja / Usually yes.**

Falls nicht:
- SafetyNet-Prüfung erforderlich
- Verwende Magisk + Universal SafetyNet Fix
- Manche DRM-Inhalte in niedriger Qualität

### Wo finde ich weitere Hilfe? / Where can I find more help?

Siehe [SUPPORT.md](SUPPORT.md) für alle Support-Optionen.

See [SUPPORT.md](SUPPORT.md) for all support options.

### Kann ich übersetzen helfen? / Can I help with translations?

**Ja / Yes!** Siehe [CONTRIBUTING.md](CONTRIBUTING.md) wie du beitragen kannst.

Yes! See [CONTRIBUTING.md](CONTRIBUTING.md) on how you can contribute.

---

## Nicht gefunden? / Not Found?

Wenn deine Frage hier nicht beantwortet wurde:

If your question isn't answered here:

1. **Durchsuche** [GitHub Issues](https://github.com/Xylop90/Realme-C63/issues)
2. **Lies** die [Dokumentation](docs/)
3. **Stelle eine Frage** via [Question Template](https://github.com/Xylop90/Realme-C63/issues/new?template=question.md)

---

**Letzte Aktualisierung / Last Updated:** 2026-01-10

**Hast du weitere Fragen? / Have more questions?**  
→ [Create an Issue](https://github.com/Xylop90/Realme-C63/issues/new/choose)
