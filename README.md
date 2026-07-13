# FloatNote 📝

FloatNote is a sleek, feature-rich floating sticky notes manager for macOS, designed to keep your thoughts, code snippets, and tasks accessible right from the menu bar. Built natively in **Swift** and **SwiftUI**, it offers fluid animations, premium custom card layouts, and complete keyboard shortcut customization.

---

## Key Features ✨

*   **Floating Panels**: Notes float above other applications and fullscreen spaces, letting you reference information effortlessly.
*   **Notes Dashboard**: A clean split-view dashboard featuring a native sidebar of custom note cards, search query filters with instant keyboard focus, and a rich markdown text editor.
*   **Focus-Aware Auto-Hide**: Notes automatically hide after $N$ seconds of inactivity and instantly reappear when you click or start typing, keeping your workspace clutter-free.
*   **Double-Click Collapsing**: Double-click any note header to collapse it into a slim titlebar, keeping it on screen without taking up space.
*   **Lock & Pin Controls**: Toggle notes to be Always-On-Top (`pin`) or Read-Only (`lock`) to prevent accidental edits.
*   **Markdown Preview**: Instantly toggle between plain text editing and rendered Markdown preview.
*   **System Appearance Matching**: Fully responsive to macOS Dark Mode and Light Mode, with explicit pastel paper contrast handling.
*   **Custom Shortcuts Builder**: Map event modifiers (`⌘`, `⌥`, `⇧`, `⌃`) and custom key combinations for actions like *New Note*, *Close Note*, *Show All*, and *Save Note*.

---

## Keyboard Shortcuts & Configuration ⚙️

Customize key combinations directly inside the **Preferences** panel:
*   **New Note**: Create notes with your custom modifiers + key.
*   **Close Note**: Archive notes instantly.
*   **Show All Notes**: Bring all hidden notes back to the screen.
*   **Save Note**: Force-save changes to disk.
*   **Search Focus (⌘F)**: Instantly highlight the search bar in the Notes Dashboard.

*Note: All shortcuts (except `⌘Q` to Quit) are disabled by default to prevent key conflicts until you choose to configure them.*

---

## Build & Run 🚀

### Prerequisites
*   macOS 11.0 or newer
*   Xcode 15.0 or newer (or Swift 5.9+ Toolchain)

### Setup & Compilation

Clone the repository and build using the Swift Package Manager:

```bash
git clone https://github.com/owaiss0/FloatNote.git
cd FloatNote
chmod +x run.sh
./run.sh
```

The app will compile and start in the background. Look for the note icon in your macOS Menu Bar.

---

## Architecture & Code Structure 🏗️

The codebase is organized cleanly as a Swift Package:

*   **`Sources/FloatNote/App.swift`**: Handles the accessory lifecycle, status bar menu bar controller, and dynamic menu shortcut updates.
*   **`Sources/FloatNote/Windows/`**:
    *   `WindowManager.swift`: Manages note windows, layouts, focus-aware notifications, auto-save state, and preference defaults.
    *   `FloatingPanel.swift`: Custom `NSPanel` subclass configuration for transparent, draggable, and shadow-backed windows.
*   **`Sources/FloatNote/Views/`**:
    *   `StickyNoteView.swift`: Main sticky note view containing custom header controls, markdown toggle, and popover settings.
    *   `DashboardView.swift`: Dual-column Notes Dashboard with adaptive Dark Mode sidebar cards and details.
    *   `PreferencesView.swift`: Shortcut builder and color/opacity configuration interface.
    *   `ScrollableTextView.swift`: Text editor integration with custom AppKit scroll bars and line spacings.

---

## License 📄

This project is open-source and licensed under the terms of the [MIT License](LICENSE).
