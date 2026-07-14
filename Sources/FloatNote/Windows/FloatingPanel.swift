import AppKit
import SwiftUI

// MARK: - Custom NSHostingView that accepts first mouse click
public class ClickThroughHostingView<Content: View>: NSHostingView<Content> {
    override public func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

// MARK: - Floating Panel
public class FloatingPanel: NSPanel {
    public init(contentRect: NSRect, backing: NSWindow.BackingStoreType = .buffered, defer flag: Bool = false) {
        super.init(
            contentRect: contentRect,
            styleMask: [.resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: backing,
            defer: flag
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        
        // Ensure it appears on all desktops/spaces and overlay fullscreen apps
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Seamless visual appearance
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = false // Set to false to prevent native titlebar interception
        self.backgroundColor = .clear
        self.hasShadow = true
        self.minSize = NSSize(width: 150, height: 40)
        if #available(macOS 11.0, *) {
            self.titlebarSeparatorStyle = .none
        }
        
        // Hide standard window buttons
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    // Allow the panel to receive keyboard focus when the user interacts with the TextEditor
    public override var canBecomeKey: Bool {
        return true
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
}

// MARK: - Draggable Window View Overlay
public struct DraggableWindowView: NSViewRepresentable {
    public init() {}
    
    public func makeNSView(context: Context) -> NSView {
        return DraggableNSView()
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {}
}

class DraggableNSView: NSView {
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            super.mouseDown(with: event)
        } else {
            self.window?.performDrag(with: event)
        }
    }
}
