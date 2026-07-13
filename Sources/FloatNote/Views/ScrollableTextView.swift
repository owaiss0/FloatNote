import SwiftUI
import AppKit

public struct ScrollableTextView: NSViewRepresentable {
    @Binding var text: String
    var isEditable: Bool
    
    public init(text: Binding<String>, isEditable: Bool) {
        self._text = text
        self.isEditable = isEditable
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        
        let textView = NSTextView()
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.textColor = NSColor.black
        textView.alignment = .left
        textView.isRichText = false
        textView.textContainerInset = NSSize(width: 12, height: 12)
        
        // Setup wrapping
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        
        textView.delegate = context.coordinator
        
        scrollView.documentView = textView
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        if textView.string != text {
            textView.string = text
        }
        
        if textView.isEditable != isEditable {
            textView.isEditable = isEditable
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ScrollableTextView
        
        init(_ parent: ScrollableTextView) {
            self.parent = parent
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
