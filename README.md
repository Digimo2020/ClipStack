<p align="center">
  <img src="docs/cover.png" alt="ClipStack: clipboard history for your Mac" width="100%">
</p>

<h1 align="center">ClipStack</h1>

<p align="center">
  <a href="https://github.com/Digimo2020/ClipStack/releases/latest"><img alt="Latest version" src="https://img.shields.io/github/v/release/Digimo2020/ClipStack?label=version&color=7c3aed&style=flat-square"></a>
  <a href="https://github.com/Digimo2020/ClipStack/commits/main"><img alt="Last update" src="https://img.shields.io/github/last-commit/Digimo2020/ClipStack?label=last%20update&color=6366f1&style=flat-square"></a>
  <a href="https://github.com/Digimo2020/ClipStack/releases/latest"><img alt="Release date" src="https://img.shields.io/github/release-date/Digimo2020/ClipStack?label=released&color=8b5cf6&style=flat-square"></a>
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-111827?style=flat-square&logo=apple&logoColor=white">
  <a href="LICENSE"><img alt="PolyForm Noncommercial License 1.0.0" src="https://img.shields.io/badge/license-PolyForm%20Noncommercial-8b5cf6?style=flat-square"></a>
</p>

<p align="center">
  A tiny, fast clipboard history for macOS. Press <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>V</kbd> and paste anything you copied recently.<br>
  Like Windows + V, for your Mac.
</p>

<p align="center">
  <a href="https://github.com/Digimo2020/ClipStack/releases/latest"><b>⬇ Download the latest DMG</b></a>
  &nbsp;·&nbsp;
  <a href="https://github.com/Digimo2020/ClipStack/releases/latest/download/ClipStack-Setup.exe"><b>Download Windows installer</b></a>
</p>

<p align="center">macOS DMG · Windows EXE installer</p>

---

## Features

- **Clipboard history**: keeps your last 50 copies (set anywhere from 20 to 200). Text and images.
- **One shortcut**: <kbd>⌘</kbd><kbd>⇧</kbd><kbd>V</kbd> opens a floating panel. Change it in Settings.
- **Paste instantly**: press <kbd>⏎</kbd> or click an item and it is pasted into the app you were using.
- **Search and filters**: type to search, or filter by All, Text, Images, Links, Pinned.
- **Emoji picker**: open the 😀 Emoji tab (or press <kbd>⌘</kbd><kbd>E</kbd>), search by name (heart, fire, thumbs…) and insert any emoji into your text.
- **Pin favourites**: pinned items are never removed.
- **Private by design**: history stays on your device. On Mac, known password-manager clipboard formats are ignored; on both platforms you can pause capturing.
- **Native and light**: Swift and SwiftUI, lives in the menu bar, no Dock icon, dark mode supported.
- **Windows companion**: a React and Electron app with tray access, local history, image previews, search, pinning and configurable shortcuts.

## Download

| Platform | Installer | Requirements |
| --- | --- | --- |
| macOS | [Download ClipStack.dmg](https://github.com/Digimo2020/ClipStack/releases/latest/download/ClipStack.dmg) | macOS 14+ (Apple Silicon) |
| Windows | [Download ClipStack-Setup.exe](https://github.com/Digimo2020/ClipStack/releases/latest/download/ClipStack-Setup.exe) | Windows 10/11 (64-bit) |

Installers are attached to the [latest public release](https://github.com/Digimo2020/ClipStack/releases/latest). The Windows installer is per-user and does not require administrator access. It is unsigned, so Windows may show a SmartScreen prompt on first launch.

## Windows quick start

1. Download and run [ClipStack-Setup.exe](https://github.com/Digimo2020/ClipStack/releases/latest/download/ClipStack-Setup.exe). Choose an install folder if you want to change the default.
2. Start ClipStack from the Start menu. It stays in the notification area by the clock; use the hidden-icons arrow if you don't see it.
3. Copy text or an image, then press **Ctrl+Shift+V** to open history.
4. Select an item to copy it back, then paste with **Ctrl+V**. Search or use the Text, Images, Links and Pinned filters to find it.
5. Open **Settings** to change the shortcut, history size, pause capture, clear unpinned items, or launch on sign-in.

Windows screenshots below use sample data and show the app interface. For the full install and usage tutorial, open the [ClipStack Setup Guide (PDF)](docs/ClipStack-Setup-Guide.pdf).

<p align="center">
  <img src="docs/windows-history.png" alt="ClipStack Windows clipboard history window" width="420">
</p>

<p align="center"><em>History window: search, filter, pin and copy text or images.</em></p>

<p align="center">
  <img src="docs/windows-settings.png" alt="ClipStack Windows settings window" width="420">
</p>

<p align="center"><em>Settings: choose a shortcut, set the history size, pause capture and launch at sign-in.</em></p>

Windows currently uses **Ctrl+Shift+V**, **Ctrl+Alt+V** or **Alt+V**. The default avoids Windows' built-in **Win+V** clipboard history. Selecting a history item copies it to the clipboard; press **Ctrl+V** in the destination app to paste it.

Windows history is stored locally under `%APPDATA%\ClipStack\` as JSON and image files. ClipStack does not send clipboard contents over the network. Clipboard formats marked by an app as excluded from clipboard monitoring are skipped when Windows exposes that marker.

## Install (step by step)

**Requirements:** macOS 14 Sonoma or newer (Apple Silicon).

1. **Download** `ClipStack.dmg` from the [latest release](https://github.com/Digimo2020/ClipStack/releases/latest).
2. **Open the DMG** and drag **ClipStack** onto the **Applications** folder.
3. **First launch.** ClipStack is not notarized by Apple (that needs a paid developer account), so macOS shows *"Apple could not verify ClipStack…"* . This is expected. Do either of these once:
   - Click **Done**, open **System Settings → Privacy & Security**, scroll down to *"ClipStack was blocked"* and click **Open Anyway**; or
   - run this in Terminal:
     ```bash
     xattr -dr com.apple.quarantine /Applications/ClipStack.app
     ```
4. **Open ClipStack again.** A clipboard icon appears in your menu bar.
5. **Allow auto-paste (optional but recommended).** The first time you pick an item, macOS asks for **Accessibility** permission. Turn ClipStack on in *System Settings → Privacy & Security → Accessibility*. Without it, ClipStack still copies the item and you press <kbd>⌘V</kbd> yourself.
6. **Try it.** Copy a few things, press <kbd>⌘</kbd><kbd>⇧</kbd><kbd>V</kbd>, pick one.

## Keyboard shortcuts

| Key | Action |
| --- | --- |
| <kbd>⌘</kbd><kbd>⇧</kbd><kbd>V</kbd> | Open or close the history |
| <kbd>↑</kbd> <kbd>↓</kbd> | Move the selection |
| <kbd>⏎</kbd> | Paste the selected item |
| <kbd>⌘</kbd><kbd>1</kbd> – <kbd>9</kbd> | Paste item 1–9 directly |
| <kbd>⌘</kbd><kbd>E</kbd> | Jump to the Emoji tab |
| <kbd>⌘</kbd><kbd>P</kbd> | Pin or unpin |
| <kbd>⌘</kbd><kbd>⌫</kbd> | Delete the selected item |
| <kbd>Esc</kbd> | Close |

> **Why not just ⌘V?** <kbd>⌘</kbd><kbd>V</kbd> is the system Paste shortcut, so taking it over would break pasting everywhere. In Settings you can pick another combination: ⌘⌥V, ⌃⇧V, ⌃⌥V or ⌥V.

## Settings

Click the menu bar icon → **Settings…**

- Shortcut preset
- History size (20 – 200 items)
- Pause capturing, clear history (pinned items are kept)
- Launch at login
- Accessibility status

## Build from source

You need Xcode command line tools (Swift 5.9+).

```bash
git clone https://github.com/Digimo2020/ClipStack.git
cd ClipStack
./build.sh --install      # builds, copies to /Applications and launches
./scripts/make_dmg.sh     # optional: build/ClipStack.dmg
```

The Windows app is in `windows/`. On a Windows machine with Node.js 22+ installed, run `npm ci`, `npm run typecheck`, `npm test`, and `npm run package:win` from that directory. The result is `windows/release/ClipStack-Setup.exe`.

Set a version with `VERSION=1.2 ./build.sh`.

Maintainers: `./scripts/release.sh patch "what changed"` builds the Mac app, checks the Windows code, commits and pushes a version tag. GitHub Actions then builds the DMG on macOS, builds and checks the EXE on Windows, and publishes both installers to the public release.

## Privacy

ClipStack has no network code, no analytics and no accounts. History is stored locally in `~/Library/Application Support/ClipStack/`. Items marked as concealed or transient by other apps (for example password managers) are never saved.

## Troubleshooting

- **The shortcut does nothing.** Another app may use the same keys. Pick a different one in Settings.
- **It copies but does not paste.** Grant Accessibility permission (step 5). After updating the app you may need to remove and re-add it in that list.
- **"ClipStack is damaged" or "can't be opened".** Run the `xattr` command from step 3.

## License

ClipStack is licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE). It is free to use for personal and other permitted noncommercial purposes. See the full license for the applicable terms.

© Kazi Fahim · [GitHub @Digimo2020](https://github.com/Digimo2020)
