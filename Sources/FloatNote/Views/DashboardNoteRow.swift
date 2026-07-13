import SwiftUI

struct DashboardNoteRow: View {
    @ObservedObject var note: StickyNote
    var isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.title.isEmpty ? "Untitled Note" : note.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)
            
            HStack(spacing: 8) {
                Text(formattedDate(note.createdAt))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                
                Text(note.content.isEmpty ? "No additional text" : note.content)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.6) : .secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor : Color.black.opacity(0.03))
        .clipShape(.rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(isSelected ? 0.0 : 0.05), lineWidth: 1)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
