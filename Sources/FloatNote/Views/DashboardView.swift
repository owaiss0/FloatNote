import SwiftUI

struct DashboardView: View {
    enum FocusField {
        case search
    }
    @FocusState private var focusedField: FocusField?
    
    @ObservedObject var windowManager = WindowManager.shared
    @State private var selectedNoteID: UUID?
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            // Detail editor or placeholder
            if let noteID = selectedNoteID, let note = windowManager.notes.first(where: { $0.id == noteID }) {
                NoteDetailView(note: note)
            } else {
                ContentUnavailableView("No Note Selected", systemImage: "note.text", description: Text("Select a note from the sidebar or create a new one to start writing."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .background(
            Button("", action: { focusedField = .search })
                .keyboardShortcut("f", modifiers: .command)
                .hidden()
        )
    }
    
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .search)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(.rect(cornerRadius: 8))
            .padding(10)
            .padding(.top, 36)
            
            // Notes List
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(filteredNotes) { note in
                        DashboardNoteRow(note: note, isSelected: selectedNoteID == note.id)
                            .onTapGesture {
                                selectedNoteID = note.id
                            }
                    }
                }
                .padding(8)
            }
            
            Spacer()
            
            // Bottom bar
            HStack {
                Button(action: createNewNote) {
                    Label("New Note", systemImage: "square.and.pencil")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                
                Spacer()
                
                Text("\(windowManager.notes.count) ^[note](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.clear)
        }
        .background(.thinMaterial)
        .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 320)
    }
    
    
    private var filteredNotes: [StickyNote] {
        if searchText.isEmpty {
            return windowManager.notes
        } else {
            return windowManager.notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func createNewNote() {
        windowManager.createNewNote()
        // Select the newly created note automatically
        if let newNote = windowManager.notes.last {
            selectedNoteID = newNote.id
        }
    }
}
