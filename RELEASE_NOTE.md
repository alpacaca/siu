# Release Notes

## v1.0.0

> Initial release of **Siu** — a lightweight clipboard manager for macOS.

### Features

**Clipboard**
- Automatic clipboard history recording (text & images)
- Global hotkey `⌘⇧V` to summon the floating panel from any app
- Pin frequently used items to the top
- Fuzzy search across clipboard history
- Code snippet detection with monospaced display
- Current clipboard item highlight
- One-click purge of history

**Vault**
- Save and organize reusable text snippets
- Encrypted entry support — content masked with `•••`, toggle visibility on hover
- Tag-based grouping with quick filter chips
- Inline action bar (Copy / Edit / Delete) on hover
- Search across snippet names and values

**Design**
- Monokai Pro–inspired dark theme with cyberpunk / HUD glow accents
- Gradient borders, glow shadows, and monospaced typography
- Menu bar–only app (no Dock icon), minimal footprint
- Drag-to-install DMG with custom background

### System Requirements

- macOS 14.0+
- Apple Silicon or Intel

### Install

Download `Siu.dmg` from [Releases](../../releases), open it, and drag `Siu.app` into **Applications**.

Or build from source:

```bash
cd Siu
bash build.sh
open Siu.dmg
```
