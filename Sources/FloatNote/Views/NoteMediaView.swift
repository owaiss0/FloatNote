import SwiftUI
import AppKit

public struct NoteMediaView: View {
    let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public var body: some View {
        Group {
            if isImageURL(url) {
                if url.scheme == "file" {
                    if let nsImage = NSImage(contentsOf: url) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        fileIconView
                    }
                } else {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }
            } else {
                fileIconView
            }
        }
        .frame(width: 80, height: 80)
        .clipped()
        .clipShape(.rect(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        }
    }
    
    private var fileIconView: some View {
        VStack(spacing: 4) {
            Image(systemName: fileSystemIcon(for: url))
                .font(.system(size: 22))
                .foregroundStyle(.black.opacity(0.6))
            
            Text(url.lastPathComponent)
                .font(.system(size: 8))
                .bold()
                .lineLimit(1)
                .foregroundStyle(.black.opacity(0.7))
                .padding(.horizontal, 4)
            
            Text(url.pathExtension.uppercased())
                .font(.system(size: 7))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.black.opacity(0.1))
                .clipShape(.rect(cornerRadius: 3))
                .foregroundStyle(.black.opacity(0.6))
        }
        .frame(width: 80, height: 80)
        .background(Color.white.opacity(0.3))
        .onTapGesture {
            NSWorkspace.shared.open(url)
        }
        .help("Click to Open file/link")
    }
    
    private func isImageURL(_ url: URL) -> Bool {
        let pathExtension = url.pathExtension.lowercased()
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "tiff", "bmp"]
        return imageExtensions.contains(pathExtension)
    }
    
    private func fileSystemIcon(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf": return "doc.richtext"
        case "zip", "tar", "gz", "rar": return "doc.zipper"
        case "mp3", "wav", "m4a": return "music.note"
        case "mp4", "mov", "avi": return "video"
        case "txt", "rtf", "md": return "doc.text"
        default:
            return url.scheme == "file" ? "doc.fill" : "link"
        }
    }
}
