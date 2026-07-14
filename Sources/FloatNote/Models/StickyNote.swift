import Foundation
import SwiftUI
import Combine

public final class StickyNote: ObservableObject, Identifiable, Codable {
    public let id: UUID
    @Published public var content: String
    @Published public var colorHex: String
    @Published public var x: Double
    @Published public var y: Double
    @Published public var width: Double
    @Published public var height: Double
    public let createdAt: Date
    
    @Published public var title: String
    @Published public var opacity: Double
    @Published public var isPinned: Bool
    @Published public var isAlwaysOnTop: Bool
    @Published public var isCollapsed: Bool
    @Published public var expandedHeight: Double
    
    // Auto-hide idle settings
    @Published public var isAutoHideEnabled: Bool
    @Published public var autoHideDelay: Double
    @Published public var isAutoHidden: Bool
    
    // Window state & last modified timestamp
    @Published public var isWindowOpen: Bool
    @Published public var lastModifiedAt: Date
    
    private var cancellables = Set<AnyCancellable>()
    
    enum CodingKeys: CodingKey {
        case id, content, colorHex, x, y, width, height, createdAt
        case title, opacity, isPinned, isAlwaysOnTop, isCollapsed, expandedHeight
        case isAutoHideEnabled, autoHideDelay, isAutoHidden
        case isWindowOpen, lastModifiedAt
    }
    
    public init(
        id: UUID = UUID(),
        content: String = "",
        colorHex: String = "#FFF9A6",
        x: Double = 100,
        y: Double = 100,
        width: Double = 320,
        height: Double = 320,
        createdAt: Date = Date(),
        title: String = "",
        opacity: Double = 1.0,
        isPinned: Bool = false,
        isAlwaysOnTop: Bool = true,
        isCollapsed: Bool = false,
        expandedHeight: Double = 320,
        isAutoHideEnabled: Bool = false,
        autoHideDelay: Double = 5.0,
        isAutoHidden: Bool = false,
        isWindowOpen: Bool = true,
        lastModifiedAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.colorHex = colorHex
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.createdAt = createdAt
        self.title = title
        self.opacity = opacity
        self.isPinned = isPinned
        self.isAlwaysOnTop = isAlwaysOnTop
        self.isCollapsed = isCollapsed
        self.expandedHeight = expandedHeight
        self.isAutoHideEnabled = isAutoHideEnabled
        self.autoHideDelay = autoHideDelay
        self.isAutoHidden = isAutoHidden
        self.isWindowOpen = isWindowOpen
        self.lastModifiedAt = lastModifiedAt
        
        setupAutosave()
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
        width = try container.decode(Double.self, forKey: .width)
        let decodedHeight = try container.decode(Double.self, forKey: .height)
        self.height = decodedHeight
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isAlwaysOnTop = try container.decodeIfPresent(Bool.self, forKey: .isAlwaysOnTop) ?? true
        isCollapsed = try container.decodeIfPresent(Bool.self, forKey: .isCollapsed) ?? false
        expandedHeight = try container.decodeIfPresent(Double.self, forKey: .expandedHeight) ?? decodedHeight
        
        isAutoHideEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAutoHideEnabled) ?? false
        autoHideDelay = try container.decodeIfPresent(Double.self, forKey: .autoHideDelay) ?? 5.0
        isAutoHidden = try container.decodeIfPresent(Bool.self, forKey: .isAutoHidden) ?? false
        
        isWindowOpen = try container.decodeIfPresent(Bool.self, forKey: .isWindowOpen) ?? true
        lastModifiedAt = try container.decodeIfPresent(Date.self, forKey: .lastModifiedAt) ?? Date()
        
        setupAutosave()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(title, forKey: .title)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(isAlwaysOnTop, forKey: .isAlwaysOnTop)
        try container.encode(isCollapsed, forKey: .isCollapsed)
        try container.encode(expandedHeight, forKey: .expandedHeight)
        
        try container.encode(isAutoHideEnabled, forKey: .isAutoHideEnabled)
        try container.encode(autoHideDelay, forKey: .autoHideDelay)
        try container.encode(isAutoHidden, forKey: .isAutoHidden)
        
        try container.encode(isWindowOpen, forKey: .isWindowOpen)
        try container.encode(lastModifiedAt, forKey: .lastModifiedAt)
    }
    
    private func setupAutosave() {
        let contentPublisher = $content.dropFirst().map { _ in () }
        let colorPublisher = $colorHex.dropFirst().map { _ in () }
        let xPublisher = $x.dropFirst().map { _ in () }
        let yPublisher = $y.dropFirst().map { _ in () }
        let wPublisher = $width.dropFirst().map { _ in () }
        let hPublisher = $height.dropFirst().map { _ in () }
        
        let titlePublisher = $title.dropFirst().map { _ in () }
        let opacityPublisher = $opacity.dropFirst().map { _ in () }
        let pinnedPublisher = $isPinned.dropFirst().map { _ in () }
        let alwaysOnTopPublisher = $isAlwaysOnTop.dropFirst().map { _ in () }
        let collapsedPublisher = $isCollapsed.dropFirst().map { _ in () }
        let expandedHeightPublisher = $expandedHeight.dropFirst().map { _ in () }
        
        let autoHideEnabledPublisher = $isAutoHideEnabled.dropFirst().map { _ in () }
        let autoHideDelayPublisher = $autoHideDelay.dropFirst().map { _ in () }
        let autoHiddenPublisher = $isAutoHidden.dropFirst().map { _ in () }
        let windowOpenPublisher = $isWindowOpen.dropFirst().map { _ in () }
        
        let p1 = Publishers.Merge6(contentPublisher, colorPublisher, xPublisher, yPublisher, wPublisher, hPublisher)
        let p2 = Publishers.Merge6(titlePublisher, opacityPublisher, pinnedPublisher, alwaysOnTopPublisher, collapsedPublisher, expandedHeightPublisher)
        let p3 = Publishers.Merge4(autoHideEnabledPublisher, autoHideDelayPublisher, autoHiddenPublisher, windowOpenPublisher)
        
        p1.merge(with: p2)
            .merge(with: p3)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.lastModifiedAt = Date()
                Task { @MainActor in
                    WindowManager.shared.saveNotes()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Color Hex Helpers
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 253, 253, 150) // Default pastel yellow
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    public func toHex() -> String? {
        let uic = NSColor(self)
        guard let rgbColor = uic.usingColorSpace(.deviceRGB) else {
            return nil
        }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(
            format: "#%02lX%02lX%02lX",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}

// MARK: - Reusable Styling Extensions
extension View {
    @ViewBuilder
    public func noteBackground(for hex: String) -> some View {
        if hex == "gradient-sunset" {
            self.background(LinearGradient(colors: [Color(hex: "#FFB347"), Color(hex: "#F12711")], startPoint: .topLeading, endPoint: .bottomTrailing))
        } else if hex == "gradient-ocean" {
            self.background(LinearGradient(colors: [Color(hex: "#2193b0"), Color(hex: "#6dd5ed")], startPoint: .topLeading, endPoint: .bottomTrailing))
        } else if hex == "gradient-lavender" {
            self.background(LinearGradient(colors: [Color(hex: "#E8D7FF"), Color(hex: "#BCE2FF")], startPoint: .topLeading, endPoint: .bottomTrailing))
        } else if hex == "gradient-mint" {
            self.background(LinearGradient(colors: [Color(hex: "#BFFCC6"), Color(hex: "#BCE2FF")], startPoint: .topLeading, endPoint: .bottomTrailing))
        } else {
            self.background(Color(hex: hex))
        }
    }
}

extension StickyNote {
    public static func circleFill(for colorOption: String) -> AnyShapeStyle {
        if colorOption == "gradient-sunset" {
            return AnyShapeStyle(LinearGradient(colors: [Color(hex: "#FFB347"), Color(hex: "#F12711")], startPoint: .topLeading, endPoint: .bottomTrailing))
        } else if colorOption == "gradient-ocean" {
            return AnyShapeStyle(LinearGradient(colors: [Color(hex: "#2193b0"), Color(hex: "#6dd5ed")], startPoint: .topLeading, endPoint: .bottomTrailing))
        } else if colorOption == "gradient-lavender" {
            return AnyShapeStyle(LinearGradient(colors: [Color(hex: "#E8D7FF"), Color(hex: "#BCE2FF")], startPoint: .topLeading, endPoint: .bottomTrailing))
        } else if colorOption == "gradient-mint" {
            return AnyShapeStyle(LinearGradient(colors: [Color(hex: "#BFFCC6"), Color(hex: "#BCE2FF")], startPoint: .topLeading, endPoint: .bottomTrailing))
        } else {
            return AnyShapeStyle(Color(hex: colorOption))
        }
    }
}
