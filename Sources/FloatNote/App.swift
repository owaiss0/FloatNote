import SwiftUI
import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as an accessory app (menu bar only, hides dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Move to Applications folder if run from elsewhere (e.g. Downloads)
        moveToApplicationsIfNeeded()
        
        // Setup Main Menu for standard text shortcuts (Copy, Paste, Undo, etc.)
        setupMainMenu()
        
        // Load and show notes
        WindowManager.shared.loadNotes()
        
        // Set up Status Bar Item
        statusBarController = StatusBarController()
    }
    
    private func moveToApplicationsIfNeeded() {
        let bundlePath = Bundle.main.bundlePath
        
        // Skip prompt during development or if already in /Applications
        if bundlePath.contains("/.build/") || bundlePath.contains("/DerivedData/") || bundlePath.contains("/stnotes") {
            return
        }
        
        let appsDirectory = "/Applications"
        if bundlePath.hasPrefix(appsDirectory) {
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Move to Applications folder?"
        alert.informativeText = "FloatNote can move itself to the Applications folder so that it is easily accessible and runs correctly."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Do Not Move")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let fileManager = FileManager.default
            let appName = URL(fileURLWithPath: bundlePath).lastPathComponent
            let destinationPath = (appsDirectory as NSString).appendingPathComponent(appName)
            let destinationURL = URL(fileURLWithPath: destinationPath)
            
            do {
                // If an older copy exists, delete it first
                if fileManager.fileExists(atPath: destinationPath) {
                    try fileManager.removeItem(atPath: destinationPath)
                }
                
                // Copy bundle to /Applications
                try fileManager.copyItem(at: URL(fileURLWithPath: bundlePath), to: destinationURL)
                
                // Launch the copied app
                let configuration = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.openApplication(at: destinationURL, configuration: configuration) { _, error in
                    DispatchQueue.main.async {
                        if error == nil {
                            NSApp.terminate(nil)
                        }
                    }
                }
            } catch {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Move Failed"
                errorAlert.informativeText = "Could not move FloatNote to Applications: \(error.localizedDescription)"
                errorAlert.runModal()
            }
        }
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        WindowManager.shared.isAppTerminating = true
        return .terminateNow
    }
    
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // App Menu (required, even if hidden)
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        
        // Add Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(settingsClicked), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        
        // Add Check for Updates
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        appMenu.addItem(updateItem)
        
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit FloatNote", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        // Edit Menu (crucial for copy/paste/undo/redo shortcuts!)
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        
        NSApp.mainMenu = mainMenu
    }
    
    @objc func checkForUpdates() {
        let url = URL(string: "https://api.github.com/repos/owaiss0/FloatNote/releases/latest")!
        
        var request = URLRequest(url: url)
        request.setValue("FloatNoteUpdateChecker", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // If checking fails (e.g. offline)
            guard let data = data, error == nil else {
                DispatchQueue.main.async { [weak self] in
                    self?.showConnectionErrorAlert()
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String,
                   let htmlUrl = json["html_url"] as? String {
                    
                    let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                    
                    DispatchQueue.main.async { [weak self] in
                        if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                            self?.showUpdateAlert(version: latestVersion, downloadURL: htmlUrl)
                        } else {
                            self?.showUpToDateAlert(version: currentVersion)
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                        self?.showUpToDateAlert(version: current)
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                    self?.showUpToDateAlert(version: current)
                }
            }
        }
        task.resume()
    }
    
    private func showUpdateAlert(version: String, downloadURL: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available!"
        alert.informativeText = "A new version of FloatNote (v\(version)) is available. Would you like to visit the release page to download it?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download Now")
        alert.addButton(withTitle: "Later")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: downloadURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private func showUpToDateAlert(version: String) {
        let alert = NSAlert()
        alert.messageText = "Up to Date"
        alert.informativeText = "You are currently running the latest version of FloatNote (v\(version))."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showConnectionErrorAlert() {
        let alert = NSAlert()
        alert.messageText = "Check Failed"
        alert.informativeText = "Could not connect to GitHub to check for updates. Please check your internet connection and try again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func settingsClicked() {
        WindowManager.shared.showPreferences()
    }
}

@MainActor
class StatusBarController: NSObject, NSMenuDelegate {
    private var statusBarItem: NSStatusItem
    
    override init() {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Sticky Notes")
        }
        
        setupMenu()
    }
    
    private func newNoteModifierFlags() -> NSEvent.ModifierFlags {
        var flags = NSEvent.ModifierFlags()
        if UserDefaults.standard.bool(forKey: "shortcutNewNoteCmd") { flags.insert(.command) }
        if UserDefaults.standard.bool(forKey: "shortcutNewNoteOpt") { flags.insert(.option) }
        if UserDefaults.standard.bool(forKey: "shortcutNewNoteShift") { flags.insert(.shift) }
        if UserDefaults.standard.bool(forKey: "shortcutNewNoteCtrl") { flags.insert(.control) }
        return flags
    }
    
    private func showAllModifierFlags() -> NSEvent.ModifierFlags {
        var flags = NSEvent.ModifierFlags()
        if UserDefaults.standard.bool(forKey: "shortcutShowAllCmd") { flags.insert(.command) }
        if UserDefaults.standard.bool(forKey: "shortcutShowAllOpt") { flags.insert(.option) }
        if UserDefaults.standard.bool(forKey: "shortcutShowAllShift") { flags.insert(.shift) }
        if UserDefaults.standard.bool(forKey: "shortcutShowAllCtrl") { flags.insert(.control) }
        return flags
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self
        
        let keyNew = UserDefaults.standard.string(forKey: "shortcutNewNoteKey") ?? ""
        let keyShowAll = UserDefaults.standard.string(forKey: "shortcutShowAllKey") ?? ""
        
        let newNoteItem = NSMenuItem(title: "New Note", action: #selector(newNoteClicked), keyEquivalent: keyNew)
        if !keyNew.isEmpty {
            newNoteItem.keyEquivalentModifierMask = newNoteModifierFlags()
        } else {
            newNoteItem.keyEquivalentModifierMask = []
        }
        newNoteItem.target = self
        menu.addItem(newNoteItem)
        
        let showAllItem = NSMenuItem(title: "Show All Notes", action: #selector(showAllNotesClicked), keyEquivalent: keyShowAll)
        if !keyShowAll.isEmpty {
            showAllItem.keyEquivalentModifierMask = showAllModifierFlags()
        } else {
            showAllItem.keyEquivalentModifierMask = []
        }
        showAllItem.target = self
        menu.addItem(showAllItem)
        
        let dashboardItem = NSMenuItem(title: "Notes Dashboard...", action: #selector(dashboardClicked), keyEquivalent: "")
        dashboardItem.target = self
        menu.addItem(dashboardItem)
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(settingsClicked), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(updateClicked), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit FloatNote", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusBarItem.menu = menu
    }
    
    @objc private func newNoteClicked() {
        WindowManager.shared.createNewNote()
    }
    
    @objc private func showAllNotesClicked() {
        WindowManager.shared.showAllNotes()
    }
    
    @objc private func dashboardClicked() {
        WindowManager.shared.showDashboard()
    }
    
    @objc private func settingsClicked() {
        WindowManager.shared.showPreferences()
    }
    
    @objc private func updateClicked() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.checkForUpdates()
        }
    }
    
    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
    
    // MARK: - NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        setupMenu()
    }
}

@main
struct StickyNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
