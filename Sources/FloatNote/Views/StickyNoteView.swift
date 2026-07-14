import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

public struct StickyNoteView: View {
    @ObservedObject var note: StickyNote
    var onDelete: () -> Void
    var onNewNote: () -> Void
    
    // Available premium colors and gradients
    private let colors = [
        "#FFF9A6", // Yellow
        "#FFC5D9", // Pink
        "#BCE2FF", // Blue
        "#BFFCC6", // Green
        "#E8D7FF", // Purple
        "#FFD1A9", // Orange
        "gradient-sunset",
        "gradient-ocean",
        "gradient-lavender",
        "gradient-mint"
    ]
    
    @State private var showCloseAlert = false
    @State private var isPreviewMode = false
    @State private var showSettingsPopover = false
    @State private var isDragModeActive = false
    @State private var autoHideTask: Task<Void, Never>?
    
    @AppStorage("shortcutNewNoteKey") private var shortcutNewNoteKey: String = ""
    @AppStorage("shortcutNewNoteCmd") private var shortcutNewNoteCmd: Bool = false
    @AppStorage("shortcutNewNoteOpt") private var shortcutNewNoteOpt: Bool = false
    @AppStorage("shortcutNewNoteShift") private var shortcutNewNoteShift: Bool = false
    @AppStorage("shortcutNewNoteCtrl") private var shortcutNewNoteCtrl: Bool = false
    
    @AppStorage("shortcutCloseNoteKey") private var shortcutCloseNoteKey: String = ""
    @AppStorage("shortcutCloseNoteCmd") private var shortcutCloseNoteCmd: Bool = false
    @AppStorage("shortcutCloseNoteOpt") private var shortcutCloseNoteOpt: Bool = false
    @AppStorage("shortcutCloseNoteShift") private var shortcutCloseNoteShift: Bool = false
    @AppStorage("shortcutCloseNoteCtrl") private var shortcutCloseNoteCtrl: Bool = false
    
    @AppStorage("shortcutSaveKey") private var shortcutSaveKey: String = ""
    @AppStorage("shortcutSaveCmd") private var shortcutSaveCmd: Bool = false
    @AppStorage("shortcutSaveOpt") private var shortcutSaveOpt: Bool = false
    @AppStorage("shortcutSaveShift") private var shortcutSaveShift: Bool = false
    @AppStorage("shortcutSaveCtrl") private var shortcutSaveCtrl: Bool = false
    
    public init(note: StickyNote, onDelete: @escaping () -> Void, onNewNote: @escaping () -> Void) {
        self.note = note
        self.onDelete = onDelete
        self.onNewNote = onNewNote
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header / Drag bar
            HStack(spacing: 8) {
                // Custom Close Button
                Button(action: triggerCloseAction) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.black.opacity(0.35))
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help("Close / Delete")
                
                // Custom Collapse/Expand Button
                Button(action: toggleCollapse) {
                    Image(systemName: note.isCollapsed ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                        .foregroundStyle(.black.opacity(0.35))
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help(note.isCollapsed ? "Expand" : "Collapse")
                
                Spacer()
                
                // Custom Title Field
                TextField("Untitled Note", text: $note.title, prompt: Text("Untitled Note").foregroundStyle(.black.opacity(0.5)))
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .disabled(note.isPinned)
                    .frame(maxWidth: 160)
                    .onTapGesture {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                
                Spacer()
                
                // Always-On-Top Toggle Button
                Button(action: toggleAlwaysOnTop) {
                    Image(systemName: note.isAlwaysOnTop ? "pin.fill" : "pin")
                        .foregroundStyle(.black.opacity(note.isAlwaysOnTop ? 0.6 : 0.35))
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help(note.isAlwaysOnTop ? "Disable Always on Top" : "Enable Always on Top")
                
                // Lock / Read-only Button
                Button(action: toggleLock) {
                    Image(systemName: note.isPinned ? "lock.fill" : "lock.open")
                        .foregroundStyle(.black.opacity(note.isPinned ? 0.6 : 0.35))
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help(note.isPinned ? "Unlock Note" : "Lock Note")
                
                // Drag Mode (Hand) Toggle Button
                Button(action: {
                    isDragModeActive.toggle()
                }) {
                    Image(systemName: isDragModeActive ? "hand.raised.fill" : "hand.raised")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isDragModeActive ? .white : .black.opacity(0.45))
                        .frame(width: 26, height: 26)
                        .background(isDragModeActive ? Color.green : Color.black.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(isDragModeActive ? "Disable Dragging" : "Enable Dragging")
                
                // New Note Button
                Button(action: onNewNote) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.black.opacity(0.35))
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help("New Note")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                StickyNote.circleFill(for: note.colorHex).opacity(0.95)
            )
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        WindowManager.shared.toggleCollapse(for: note)
                    }
            )
            
            // Render body content only if not collapsed
            if !note.isCollapsed {
                Divider()
                    .background(Color.black.opacity(0.1))
                
                // Text Area & Media Tray
                VStack(alignment: .leading, spacing: 0) {
                    if isPreviewMode {
                        // Markdown Preview Mode
                        ScrollView {
                            Text(formattedMarkdown(note.content))
                                .font(.system(.body))
                                .foregroundStyle(.black.opacity(0.85))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    } else {
                        // Text Editor Mode using Custom AppKit TextView (fixed selection)
                        ZStack(alignment: .topLeading) {
                            ScrollableTextView(text: $note.content, isEditable: !note.isPinned)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            if note.content.isEmpty {
                                Text("Type or paste anything...")
                                    .foregroundStyle(.black.opacity(0.25))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .font(.system(.body))
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    
                    // Render Dropped Media
                    if !fileURLs.isEmpty {
                        Divider()
                            .background(Color.black.opacity(0.05))
                        
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(fileURLs, id: \.self) { url in
                                    NoteMediaView(url: url)
                                }
                            }
                            .padding(8)
                        }
                        .scrollIndicators(.visible)
                        .frame(height: 100)
                        .background(Color.black.opacity(0.03))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .noteBackground(for: note.colorHex)
                
                Divider()
                    .background(Color.black.opacity(0.05))
                
                // Bottom bar / Controls
                HStack {
                    // Color Pickers
                    HStack(spacing: 6) {
                        ForEach(colors, id: \.self) { colorOption in
                            Circle()
                                .fill(StickyNote.circleFill(for: colorOption))
                                .overlay {
                                    Circle()
                                        .stroke(Color.black.opacity(note.colorHex == colorOption ? 0.6 : 0.15), lineWidth: 1.5)
                                }
                                .frame(width: 14, height: 14)
                                .onTapGesture {
                                    note.colorHex = colorOption
                                }
                                .help("Change Color")
                        }
                    }
                    
                    Spacer()
                    
                    // Word / Character Count (Subtle)
                    Text("\(wordCount)w  \(characterCount)c")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.black.opacity(0.4))
                        .padding(.trailing, 8)
                    
                    // Settings Popover (Gear Icon)
                    Button(action: toggleSettingsPopover) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.black.opacity(0.4))
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .help("More Settings")
                    .popover(isPresented: $showSettingsPopover, arrowEdge: .bottom) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Note Settings")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            // Opacity Control
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Opacity")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(Int(note.opacity * 100))%")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                Slider(value: $note.opacity, in: 0.3...1.0)
                                    .controlSize(.small)
                            }
                            
                            Divider()
                            
                            // Auto-Hide Idle Settings
                            VStack(alignment: .leading, spacing: 6) {
                                Toggle("Auto-Hide when Idle", isOn: $note.isAutoHideEnabled)
                                    .font(.system(size: 11))
                                    .controlSize(.small)
                                
                                if note.isAutoHideEnabled {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Delay")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            TextField("", value: $note.autoHideDelay, format: .number)
                                                .textFieldStyle(.roundedBorder)
                                                .frame(width: 40)
                                                .multilineTextAlignment(.trailing)
                                                .controlSize(.small)
                                            Text("s")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                        Slider(value: $note.autoHideDelay, in: 1...60, step: 1)
                                            .controlSize(.small)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Action Buttons Stack
                            VStack(spacing: 8) {
                                Button(action: saveChangesAction) {
                                    Label("Save Changes", systemImage: "checkmark.circle")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                                
                                Button(action: exportNoteAction) {
                                    Label("Export Note...", systemImage: "arrow.down.doc")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                                
                                Button(role: .destructive, action: deleteNoteAction) {
                                    Label("Delete Note", systemImage: "trash")
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(16)
                        .frame(width: 200)
                        .colorScheme(isSystemDark ? .dark : .light)
                    }
                    
                    // Markdown Preview Toggle
                    Button(action: togglePreviewMode) {
                        Image(systemName: isPreviewMode ? "pencil.circle.fill" : "eye.circle.fill")
                            .foregroundStyle(.black.opacity(0.5))
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .help(isPreviewMode ? "Edit Note" : "Preview Markdown")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(StickyNote.circleFill(for: note.colorHex).opacity(0.95))
            }
            
            // Hidden buttons to capture keyboard shortcuts
            backgroundShortcuts
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .noteBackground(for: note.colorHex)
        .opacity(note.isAutoHidden ? 0.0 : note.opacity)
        .clipShape(.rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.15), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .overlay {
            if isDragModeActive {
                ZStack(alignment: .topTrailing) {
                    // Full-window dragging background
                    Color.black.opacity(0.12)
                        .background(DraggableWindowView())
                    
                    // Large center drag indicator
                    VStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Drag Mode Active")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .allowsHitTesting(false)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Clickable exit button aligned with header hand icon
                    Button(action: {
                        isDragModeActive = false
                    }) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .padding(.trailing, 31)
                    .help("Disable Dragging")
                }
                .clipShape(.rect(cornerRadius: 12))
            }
        }
        // Force Light colorScheme to avoid dark-mode contrast issues
        .colorScheme(.light)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TriggerClosePrompt-\(note.id.uuidString)"))) { _ in
            triggerCloseAction()
        }
        // Right-Click Context Menu
        .contextMenu {
            Button(action: { onNewNote() }) {
                Label("New Note", systemImage: "plus")
            }
            Button(action: { WindowManager.shared.toggleCollapse(for: note) }) {
                Label(note.isCollapsed ? "Expand Note" : "Collapse Note", systemImage: note.isCollapsed ? "chevron.down" : "chevron.up")
            }
            Button(action: toggleLock) {
                Label(note.isPinned ? "Unlock Note" : "Lock Note", systemImage: note.isPinned ? "lock.open" : "lock")
            }
            Button(action: toggleAlwaysOnTop) {
                Label(note.isAlwaysOnTop ? "Disable Always on Top" : "Enable Always on Top", systemImage: "pin")
            }
            Divider()
            Menu("Change Color") {
                ForEach(colors, id: \.self) { colorOption in
                    Button(colorDisplayName(colorOption)) {
                        note.colorHex = colorOption
                    }
                }
            }
            Divider()
            Button(role: .destructive, action: deleteNoteAction) {
                Label("Delete Note", systemImage: "trash")
            }
        }
        // Enable dragging and dropping of files/text
        .onDrop(of: [.item], isTargeted: nil) { providers in
            if note.isPinned { return false } // No dropping on locked notes
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        if let url = url {
                            DispatchQueue.main.async {
                                if note.content.isEmpty {
                                    note.content = url.absoluteString
                                } else {
                                    note.content += "\n\(url.absoluteString)"
                                }
                            }
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier("public.utf8-plain-text") {
                    provider.loadItem(forTypeIdentifier: "public.utf8-plain-text", options: nil) { text, _ in
                        if let data = text as? Data, let decoded = String(data: data, encoding: .utf8) {
                            DispatchQueue.main.async {
                                if note.content.isEmpty {
                                    note.content = decoded
                                } else {
                                    note.content += "\n\(decoded)"
                                }
                            }
                        }
                    }
                }
            }
            return true
        }
        // Auto-Hide Idle handlers
        .onAppear(perform: resetAutoHideTimer)
        .onChange(of: note.content) { _, _ in
            resetAutoHideTimer()
        }
        .onChange(of: note.isAutoHideEnabled) { _, _ in
            resetAutoHideTimer()
            WindowManager.shared.saveNotes()
        }
        .onChange(of: note.autoHideDelay) { _, _ in
            resetAutoHideTimer()
            WindowManager.shared.saveNotes()
        }
        .onChange(of: note.isAutoHidden) { oldValue, isHidden in
            WindowManager.shared.updateWindowVisibility(for: note)
            if !isHidden {
                resetAutoHideTimer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("WindowBecameKey-\(note.id.uuidString)"))) { _ in
            autoHideTask?.cancel()
            if note.isAutoHidden {
                withAnimation(.easeInOut(duration: 0.3)) {
                    note.isAutoHidden = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("WindowResignedKey-\(note.id.uuidString)"))) { _ in
            resetAutoHideTimer()
        }
        .onDisappear {
            autoHideTask?.cancel()
        }
        .ignoresSafeArea()
    }
    
    // Check if empty to delete immediately, otherwise show prompt
    private func triggerCloseAction() {
        if note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            WindowManager.shared.deleteNote(note)
        } else {
            let alert = NSAlert()
            alert.messageText = "Close Note"
            alert.informativeText = "What do you want to do with this note? You can hide it to view later, or delete it permanently."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "Delete Permanently")
            
            // Activate the app so the alert modal handles focus properly
            NSApp.activate(ignoringOtherApps: true)
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                WindowManager.shared.hideNote(note)
            } else if response == .alertThirdButtonReturn {
                WindowManager.shared.deleteNote(note)
            }
        }
    }
    
    // Auto-Hide Timer reset
    private func resetAutoHideTimer() {
        autoHideTask?.cancel()
        
        if note.isAutoHidden {
            withAnimation(.easeInOut(duration: 0.3)) {
                note.isAutoHidden = false
            }
        }
        
        // If window is currently the key window, do NOT start the auto-hide count
        let isWindowKey = WindowManager.shared.window(for: note)?.isKeyWindow ?? false
        if isWindowKey {
            return
        }
        
        if note.isAutoHideEnabled {
            autoHideTask = Task {
                do {
                    try await Task.sleep(for: .seconds(note.autoHideDelay))
                    guard !Task.isCancelled else { return }
                    
                    let isWindowKeyNow = await MainActor.run {
                        WindowManager.shared.window(for: note)?.isKeyWindow ?? false
                    }
                    if isWindowKeyNow {
                        return
                    }
                    
                    withAnimation(.easeInOut(duration: 0.5)) {
                        note.isAutoHidden = true
                    }
                } catch {}
            }
        }
    }
    
    // Extracted Button Actions
    private func toggleCollapse() {
        WindowManager.shared.toggleCollapse(for: note)
    }
    
    private func toggleAlwaysOnTop() {
        note.isAlwaysOnTop.toggle()
        WindowManager.shared.updateWindowLevel(for: note)
    }
    
    private func toggleLock() {
        note.isPinned.toggle()
    }
    
    private func toggleSettingsPopover() {
        showSettingsPopover.toggle()
    }
    
    private func togglePreviewMode() {
        isPreviewMode.toggle()
    }
    
    private func exportNoteAction() {
        showSettingsPopover = false
        exportNote()
    }
    
    private func deleteNoteAction() {
        showSettingsPopover = false
        WindowManager.shared.deleteNote(note)
    }
    
    private func saveChangesAction() {
        showSettingsPopover = false
        WindowManager.shared.saveNotes()
    }
    
    private var isSystemDark: Bool {
        if let appearance = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            return appearance == .darkAqua
        }
        return false
    }
    
    private var fileURLs: [URL] {
        extractFileURLs(from: note.content)
    }
    
    // Word and character count helpers
    private var wordCount: Int {
        let components = note.content.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.count
    }
    
    private var characterCount: Int {
        note.content.count
    }
    
    // Export note content using NSSavePanel
    private func exportNote() {
        NSApp.activate(ignoringOtherApps: true)
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText, .plainText]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = note.title.isEmpty ? "Note" : note.title
        
        if let window = WindowManager.shared.window(for: note) {
            savePanel.beginSheetModal(for: window) { response in
                if response == .OK, let url = savePanel.url {
                    try? note.content.write(to: url, atomically: true, encoding: .utf8)
                }
            }
        } else {
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    try? note.content.write(to: url, atomically: true, encoding: .utf8)
                }
            }
        }
    }
    
    // Modifier helpers
    private var newNoteModifiers: EventModifiers {
        var modifiers: EventModifiers = []
        if shortcutNewNoteCmd { modifiers.insert(.command) }
        if shortcutNewNoteOpt { modifiers.insert(.option) }
        if shortcutNewNoteShift { modifiers.insert(.shift) }
        if shortcutNewNoteCtrl { modifiers.insert(.control) }
        return modifiers
    }
    
    private var closeNoteModifiers: EventModifiers {
        var modifiers: EventModifiers = []
        if shortcutCloseNoteCmd { modifiers.insert(.command) }
        if shortcutCloseNoteOpt { modifiers.insert(.option) }
        if shortcutCloseNoteShift { modifiers.insert(.shift) }
        if shortcutCloseNoteCtrl { modifiers.insert(.control) }
        return modifiers
    }
    
    private var saveNoteModifiers: EventModifiers {
        var modifiers: EventModifiers = []
        if shortcutSaveCmd { modifiers.insert(.command) }
        if shortcutSaveOpt { modifiers.insert(.option) }
        if shortcutSaveShift { modifiers.insert(.shift) }
        if shortcutSaveCtrl { modifiers.insert(.control) }
        return modifiers
    }

    // Background shortcuts
    @ViewBuilder
    private var backgroundShortcuts: some View {
        ZStack {
            if !shortcutCloseNoteKey.isEmpty, let char = shortcutCloseNoteKey.first {
                Button("", action: triggerCloseAction)
                    .keyboardShortcut(KeyEquivalent(char), modifiers: closeNoteModifiers)
            }
            if !shortcutNewNoteKey.isEmpty, let char = shortcutNewNoteKey.first {
                Button("", action: onNewNote)
                    .keyboardShortcut(KeyEquivalent(char), modifiers: newNoteModifiers)
            }
            if !shortcutSaveKey.isEmpty, let char = shortcutSaveKey.first {
                Button("", action: { WindowManager.shared.saveNotes() })
                    .keyboardShortcut(KeyEquivalent(char), modifiers: saveNoteModifiers)
            }
        }
        .buttonStyle(.plain)
        .hidden() // Completely hides the shortcut views from layout/drawing hierarchy
    }
    
    // Extract File and Web URLs/Paths from text content
    private func extractFileURLs(from text: String) -> [URL] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text)) ?? []
        
        var urls: [URL] = []
        for match in matches {
            if let url = match.url {
                urls.append(url)
            }
        }
        return urls
    }
    
    // Markdown formatting helper
    private func formattedMarkdown(_ text: String) -> AttributedString {
        do {
            return try AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString(text)
        }
    }
    
    // Display names of colors/gradients in context menus
    private func colorDisplayName(_ colorOption: String) -> String {
        if colorOption.hasPrefix("gradient-") {
            return colorOption.replacingOccurrences(of: "gradient-", with: "").capitalized + " Gradient"
        }
        switch colorOption {
        case "#FFF9A6": return "Yellow"
        case "#FFC5D9": return "Pink"
        case "#BCE2FF": return "Blue"
        case "#BFFCC6": return "Green"
        case "#E8D7FF": return "Purple"
        case "#FFD1A9": return "Orange"
        default: return colorOption
        }
    }
    
    // Drag mode helper view
    private var dragActiveOverlay: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            Text("Drag Mode Active")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .allowsHitTesting(false)
    }
}
