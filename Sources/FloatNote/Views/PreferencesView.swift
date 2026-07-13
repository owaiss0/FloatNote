import SwiftUI

public struct PreferencesView: View {
    @AppStorage("defaultOpacity") private var defaultOpacity: Double = 1.0
    @AppStorage("defaultColorHex") private var defaultColorHex: String = "#FFF9A6"
    
    // Custom Keyboard Shortcuts (empty key means disabled by default)
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
    
    @AppStorage("shortcutShowAllKey") private var shortcutShowAllKey: String = ""
    @AppStorage("shortcutShowAllCmd") private var shortcutShowAllCmd: Bool = false
    @AppStorage("shortcutShowAllOpt") private var shortcutShowAllOpt: Bool = false
    @AppStorage("shortcutShowAllShift") private var shortcutShowAllShift: Bool = false
    @AppStorage("shortcutShowAllCtrl") private var shortcutShowAllCtrl: Bool = false
    
    @AppStorage("shortcutSaveKey") private var shortcutSaveKey: String = ""
    @AppStorage("shortcutSaveCmd") private var shortcutSaveCmd: Bool = false
    @AppStorage("shortcutSaveOpt") private var shortcutSaveOpt: Bool = false
    @AppStorage("shortcutSaveShift") private var shortcutSaveShift: Bool = false
    @AppStorage("shortcutSaveCtrl") private var shortcutSaveCtrl: Bool = false
    
    private let colors = [
        "#FFF9A6", // Yellow
        "#FFC5D9", // Pink
        "#BCE2FF", // Blue
        "#BFFCC6", // Green
        "#E8D7FF", // Purple
        "#FFD1A9"  // Orange
    ]
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .padding(.bottom, 4)
            
            // Default Color Select
            VStack(alignment: .leading, spacing: 6) {
                Text("Default Color for New Notes")
                    .font(.headline)
                HStack(spacing: 8) {
                    ForEach(colors, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(defaultColorHex == hex ? 0.6 : 0.15), lineWidth: 2)
                            )
                            .onTapGesture {
                                defaultColorHex = hex
                            }
                    }
                }
            }
            
            // Opacity Slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Default Opacity")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(defaultOpacity * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Slider(value: $defaultOpacity, in: 0.3...1.0)
            }
            
            Divider()
            
            // Custom Shortcuts Builder
            VStack(alignment: .leading, spacing: 10) {
                Text("Custom Keyboard Shortcuts")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    shortcutSelector(title: "New Note", key: $shortcutNewNoteKey, cmd: $shortcutNewNoteCmd, opt: $shortcutNewNoteOpt, shift: $shortcutNewNoteShift, ctrl: $shortcutNewNoteCtrl)
                    shortcutSelector(title: "Close Note", key: $shortcutCloseNoteKey, cmd: $shortcutCloseNoteCmd, opt: $shortcutCloseNoteOpt, shift: $shortcutCloseNoteShift, ctrl: $shortcutCloseNoteCtrl)
                    shortcutSelector(title: "Show All", key: $shortcutShowAllKey, cmd: $shortcutShowAllCmd, opt: $shortcutShowAllOpt, shift: $shortcutShowAllShift, ctrl: $shortcutShowAllCtrl)
                    shortcutSelector(title: "Save Note", key: $shortcutSaveKey, cmd: $shortcutSaveCmd, opt: $shortcutSaveOpt, shift: $shortcutSaveShift, ctrl: $shortcutSaveCtrl)
                }
            }
            
            Spacer()
            
            // Helper Action
            HStack {
                Button("Show All Hidden Notes") {
                    WindowManager.shared.showAllNotes()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
        }
        .padding(20)
        .frame(width: 420, height: 420)
    }
    
    private func shortcutSelector(
        title: String,
        key: Binding<String>,
        cmd: Binding<Bool>,
        opt: Binding<Bool>,
        shift: Binding<Bool>,
        ctrl: Binding<Bool>
    ) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 80, alignment: .leading)
            
            HStack(spacing: 4) {
                modifierButton(label: "⌘", isOn: cmd)
                modifierButton(label: "⌥", isOn: opt)
                modifierButton(label: "⇧", isOn: shift)
                modifierButton(label: "⌃", isOn: ctrl)
            }
            
            Text("+")
                .foregroundColor(.secondary)
                .font(.caption)
            
            TextField("Key", text: key)
                .textFieldStyle(.roundedBorder)
                .frame(width: 32)
                .controlSize(.small)
                .multilineTextAlignment(.center)
                .onChange(of: key.wrappedValue) { oldValue, newValue in
                    if newValue.count > 1 {
                        key.wrappedValue = String(newValue.prefix(1))
                    }
                }
        }
    }
    
    private func modifierButton(label: String, isOn: Binding<Bool>) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .frame(width: 22, height: 18)
                .background(isOn.wrappedValue ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundColor(isOn.wrappedValue ? .white : .primary)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}
