import SwiftUI

struct NoteDetailView: View {
    @ObservedObject var note: StickyNote
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar (Title + Status bar items)
            HStack(spacing: 12) {
                TextField("Title", text: $note.title, prompt: Text("Title").foregroundColor(.black.opacity(0.4)))
                    .font(.title3)
                    .fontWeight(.bold)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.black)
                    .disabled(note.isPinned)
                
                Spacer()
                
                // Color Pickers
                HStack(spacing: 5) {
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
                    }
                }
                .padding(.trailing, 8)
                
                // Always-on-top toggle
                Button(action: toggleAlwaysOnTop) {
                    Image(systemName: note.isAlwaysOnTop ? "pin.fill" : "pin")
                        .foregroundStyle(note.isAlwaysOnTop ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.bordered)
                .help(note.isAlwaysOnTop ? "Disable Always on Top" : "Enable Always on Top")
                
                // Pinned / Lock Toggle
                Button(action: toggleLock) {
                    Image(systemName: note.isPinned ? "lock.fill" : "lock.open")
                        .foregroundStyle(note.isPinned ? .red : .secondary)
                }
                .buttonStyle(.bordered)
                .help(note.isPinned ? "Unlock Note" : "Lock Note")
                
                // Delete Note Button
                Button(role: .destructive, action: deleteNote) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.bordered)
                .help("Delete Note")
            }
            .padding(12)
            .background(Color.black.opacity(0.04))
            
            Divider()
                .background(Color.black.opacity(0.1))
            
            // Editor View
            ZStack(alignment: .topLeading) {
                ScrollableTextView(text: $note.content, isEditable: !note.isPinned)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if note.content.isEmpty {
                    Text("Type or paste anything...")
                        .foregroundColor(.black.opacity(0.25))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .font(.system(.body))
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .noteBackground(for: note.colorHex)
        .colorScheme(.light)
    }
    
    private func toggleAlwaysOnTop() {
        note.isAlwaysOnTop.toggle()
        WindowManager.shared.updateWindowLevel(for: note)
    }
    
    private func toggleLock() {
        note.isPinned.toggle()
    }
    
    private func deleteNote() {
        WindowManager.shared.deleteNote(note)
    }
}
