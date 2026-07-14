import AppKit
import SwiftUI
import Combine

@MainActor
public final class WindowManager: NSObject, ObservableObject, NSWindowDelegate {
    public static let shared = WindowManager()
    
    @Published public var notes: [StickyNote] = []
    
    public var isAppTerminating = false
    
    private var windows: [UUID: FloatingPanel] = [:]
    private var preferencesWindow: NSWindow?
    private var dashboardWindow: NSWindow?
    
    private var saveURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0].appendingPathComponent("FloatNote", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent("notes.json")
    }
    
    public func loadNotes() {
        if let data = try? Data(contentsOf: saveURL),
           let decoded = try? JSONDecoder().decode([StickyNote].self, from: data) {
            self.notes = decoded
        } else {
            self.notes = []
        }
        
        if notes.isEmpty {
            createNewNote()
            return
        }
        
        let openNotes = notes.filter { $0.isWindowOpen }
        
        if openNotes.isEmpty {
            if let lastActive = notes.sorted(by: { $0.lastModifiedAt > $1.lastModifiedAt }).first {
                lastActive.isWindowOpen = true
                showWindow(for: lastActive)
            }
        } else {
            for note in openNotes {
                showWindow(for: note)
            }
        }
    }
    
    public func getNotes() -> [StickyNote] {
        return notes
    }
    
    public func showAllNotes() {
        for note in notes {
            note.isAutoHidden = false
            showWindow(for: note)
            updateWindowVisibility(for: note)
        }
    }
    
    public func saveNotes() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        let url = saveURL
        DispatchQueue.global(qos: .background).async {
            try? data.write(to: url)
        }
    }
    
    public func showWindow(for note: StickyNote) {
        note.isWindowOpen = true
        saveNotes()
        
        if let existingWindow = windows[note.id] {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true) // Activate app so unpinned notes come to frontmost screen!
            return
        }
        
        let height = note.isCollapsed ? 40.0 : note.height
        let rect = NSRect(x: note.x, y: note.y, width: note.width, height: height)
        let panel = FloatingPanel(contentRect: rect)
        panel.minSize = note.isCollapsed ? NSSize(width: 150, height: 40) : NSSize(width: 150, height: 150)
        panel.level = note.isAlwaysOnTop ? .floating : .normal
        panel.alphaValue = note.isAutoHidden ? 0.0 : CGFloat(note.opacity)
        
        let view = StickyNoteView(note: note, onDelete: { [weak self] in
            self?.deleteNote(note)
        }, onNewNote: { [weak self] in
            self?.createNewNote(relativeTo: note)
        })
        
        panel.contentView = ClickThroughHostingView(rootView: view)
        panel.delegate = self
        panel.identifier = NSUserInterfaceItemIdentifier(note.id.uuidString)
        
        if !note.isAutoHidden {
            panel.makeKeyAndOrderFront(nil)
        }
        windows[note.id] = panel
        
        NSApp.activate(ignoringOtherApps: true) // Activate app on spawn
    }
    
    public func createNewNote(relativeTo sourceNote: StickyNote? = nil) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var x = screen.midX - 160
        var y = screen.midY - 160
        
        if let source = sourceNote {
            x = source.x + 30
            y = source.y - 30
        }
        
        // Find existing open note coordinates to offset and cascade
        let openNotes = notes.filter { $0.isWindowOpen }
        while openNotes.contains(where: { abs($0.x - x) < 5 && abs($0.y - y) < 5 }) {
            x += 30
            y -= 30 // Shifting down-right in macOS AppKit screen coordinates (y increases going upwards)
            
            // If the note goes too far right or down, wrap it back to center
            if x + 320 > screen.maxX || y - 320 < screen.minY {
                x = screen.midX - 160
                y = screen.midY - 160
                break
            }
        }
        
        // Use user-defined default color/opacity if available
        let defaultColorHex = UserDefaults.standard.string(forKey: "defaultColorHex") ?? "#FFF9A6"
        let defaultOpacity = UserDefaults.standard.double(forKey: "defaultOpacity") != 0.0 ? UserDefaults.standard.double(forKey: "defaultOpacity") : 1.0
        
        let newNote = StickyNote(content: "", colorHex: defaultColorHex, x: x, y: y, width: 320, height: 320, title: "", opacity: defaultOpacity, isPinned: false, isAlwaysOnTop: true, isCollapsed: false, expandedHeight: 320, isWindowOpen: true, lastModifiedAt: Date())
        notes.append(newNote)
        saveNotes()
        
        showWindow(for: newNote)
    }
    
    public func updateWindowLevel(for note: StickyNote) {
        if let window = windows[note.id] {
            window.level = note.isAlwaysOnTop ? .floating : .normal
        }
    }
    
    public func updateWindowVisibility(for note: StickyNote) {
        guard let window = windows[note.id] else { return }
        let targetAlpha: CGFloat = note.isAutoHidden ? 0.1 : CGFloat(note.opacity)
        let isAutoHidden = note.isAutoHidden
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            window.animator().alphaValue = targetAlpha
        } completionHandler: {
            if !isAutoHidden {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    public func window(for note: StickyNote) -> NSWindow? {
        return windows[note.id]
    }
    
    public func toggleCollapse(for note: StickyNote) {
        guard let window = windows[note.id] else { return }
        
        note.isCollapsed.toggle()
        
        var frame = window.frame
        let collapsedHeight: CGFloat = 40
        
        if note.isCollapsed {
            window.minSize = NSSize(width: 150, height: 40)
            note.expandedHeight = frame.height
            let newY = frame.origin.y + (frame.height - collapsedHeight)
            frame.origin.y = newY
            frame.size.height = collapsedHeight
            window.setFrame(frame, display: true, animate: true)
        } else {
            window.minSize = NSSize(width: 150, height: 150)
            let newY = frame.origin.y - (note.expandedHeight - frame.height)
            frame.origin.y = newY
            frame.size.height = note.expandedHeight
            window.setFrame(frame, display: true, animate: true)
        }
        saveNotes()
    }
    
    public func hideNote(_ note: StickyNote) {
        note.isWindowOpen = false
        saveNotes()
        
        if let window = windows[note.id] {
            window.delegate = nil
            window.close()
            windows.removeValue(forKey: note.id)
        }
    }
    
    public func deleteNote(_ note: StickyNote) {
        if let window = windows[note.id] {
            window.delegate = nil
            window.close()
            windows.removeValue(forKey: note.id)
        }
        
        notes.removeAll(where: { $0.id == note.id })
        saveNotes()
    }
    
    public func showPreferences() {
        if let existing = preferencesWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let view = PreferencesView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 430),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "FloatNote Settings"
        window.contentView = NSHostingView(rootView: view)
        window.setFrameAutosaveName("SettingsWindow")
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        self.preferencesWindow = window
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func showDashboard() {
        if let existing = dashboardWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let view = DashboardView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 850, height: 550),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "FloatNote Dashboard"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentView = NSHostingView(rootView: view)
        window.setFrameAutosaveName("DashboardWindow")
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        self.dashboardWindow = window
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func closeAll() {
        for window in windows.values {
            window.close()
        }
        windows.removeAll()
    }
    
    // MARK: - NSWindowDelegate
    
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        if isAppTerminating { return true }
        
        guard let idString = sender.identifier?.rawValue,
              let id = UUID(uuidString: idString) else { return true }
        
        if let note = notes.first(where: { $0.id == id }) {
            if note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                deleteNote(note)
                return true
            } else {
                NotificationCenter.default.post(name: Notification.Name("TriggerClosePrompt-\(idString)"), object: nil)
                return false // Prevent instant closure
            }
        }
        
        return true
    }
    
    public func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let idString = window.identifier?.rawValue,
              let id = UUID(uuidString: idString) else { return }
              
        let frame = window.frame
        if let note = notes.first(where: { $0.id == id }) {
            note.x = frame.origin.x
            note.y = frame.origin.y
        }
    }
    
    public func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let idString = window.identifier?.rawValue,
              let id = UUID(uuidString: idString) else { return }
              
        let frame = window.frame
        if let note = notes.first(where: { $0.id == id }) {
            if !note.isCollapsed {
                note.width = frame.width
                note.height = frame.height
                note.expandedHeight = frame.height
            } else {
                note.width = frame.width
            }
        }
    }
    
    public func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        if window == preferencesWindow {
            preferencesWindow = nil
        } else if window == dashboardWindow {
            dashboardWindow = nil
        } else if let idString = window.identifier?.rawValue, let id = UUID(uuidString: idString) {
            windows.removeValue(forKey: id)
        }
    }
    
    public func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let idString = window.identifier?.rawValue else { return }
        NotificationCenter.default.post(name: Notification.Name("WindowBecameKey-\(idString)"), object: nil)
    }
    
    public func windowDidResignKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let idString = window.identifier?.rawValue else { return }
        NotificationCenter.default.post(name: Notification.Name("WindowResignedKey-\(idString)"), object: nil)
    }
}
