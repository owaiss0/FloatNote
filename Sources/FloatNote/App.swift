import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as an accessory app (menu bar only, hides dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Load and show notes
        WindowManager.shared.loadNotes()
        
        // Set up Status Bar Item
        statusBarController = StatusBarController()
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
        
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(preferencesClicked), keyEquivalent: "")
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        
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
    
    @objc private func preferencesClicked() {
        WindowManager.shared.showPreferences()
    }
    
    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
    
    // MARK: - NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        WindowManager.shared.showAllNotes()
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
