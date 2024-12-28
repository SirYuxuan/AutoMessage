import SwiftUI
import Carbon.HIToolbox

struct KeyCombo: Codable, Equatable {
    var keyCode: Int
    var modifiers: Int
    
    var description: String {
        var desc = ""
        
        if modifiers & Int(NSEvent.ModifierFlags.control.rawValue) != 0 {
            desc += "⌃"
        }
        if modifiers & Int(NSEvent.ModifierFlags.option.rawValue) != 0 {
            desc += "⌥"
        }
        if modifiers & Int(NSEvent.ModifierFlags.shift.rawValue) != 0 {
            desc += "⇧"
        }
        if modifiers & Int(NSEvent.ModifierFlags.command.rawValue) != 0 {
            desc += "⌘"
        }
        
        if let specialKey = KeyCombo.specialKeyMap[keyCode] {
            desc += specialKey
        } else {
            if let char = KeyCombo.characterMap[keyCode] {
                desc += char
            }
        }
        
        return desc
    }
    
    static let specialKeyMap: [Int: String] = [
        kVK_Return: "↩",
        kVK_Tab: "⇥",
        kVK_Space: "Space",
        kVK_Delete: "⌫",
        kVK_Escape: "⎋",
        kVK_Command: "⌘",
        kVK_Shift: "⇧",
        kVK_CapsLock: "⇪",
        kVK_Option: "⌥",
        kVK_Control: "⌃",
        kVK_RightCommand: "⌘",
        kVK_RightShift: "⇧",
        kVK_RightOption: "⌥",
        kVK_RightControl: "⌃",
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_DownArrow: "↓",
        kVK_UpArrow: "↑",
    ]
    
    static let characterMap: [Int: String] = [
        kVK_ANSI_A: "A",
        kVK_ANSI_B: "B",
        kVK_ANSI_C: "C",
        kVK_ANSI_D: "D",
        kVK_ANSI_E: "E",
        kVK_ANSI_F: "F",
        kVK_ANSI_G: "G",
        kVK_ANSI_H: "H",
        kVK_ANSI_I: "I",
        kVK_ANSI_J: "J",
        kVK_ANSI_K: "K",
        kVK_ANSI_L: "L",
        kVK_ANSI_M: "M",
        kVK_ANSI_N: "N",
        kVK_ANSI_O: "O",
        kVK_ANSI_P: "P",
        kVK_ANSI_Q: "Q",
        kVK_ANSI_R: "R",
        kVK_ANSI_S: "S",
        kVK_ANSI_T: "T",
        kVK_ANSI_U: "U",
        kVK_ANSI_V: "V",
        kVK_ANSI_W: "W",
        kVK_ANSI_X: "X",
        kVK_ANSI_Y: "Y",
        kVK_ANSI_Z: "Z",
        kVK_ANSI_0: "0",
        kVK_ANSI_1: "1",
        kVK_ANSI_2: "2",
        kVK_ANSI_3: "3",
        kVK_ANSI_4: "4",
        kVK_ANSI_5: "5",
        kVK_ANSI_6: "6",
        kVK_ANSI_7: "7",
        kVK_ANSI_8: "8",
        kVK_ANSI_9: "9"
    ]
}

struct HotkeyRecorder: View {
    @Binding var keyCombo: KeyCombo
    @Binding var isRecording: Bool
    
    var body: some View {
        Button(action: {
            isRecording.toggle()
        }) {
            Text(isRecording ? "录制中..." : keyCombo.description)
                .frame(minWidth: 100)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isRecording ? Color.blue : Color.gray.opacity(0.5))
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if isRecording {
                    let modifiers = Int(event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue)
                    keyCombo = KeyCombo(keyCode: Int(event.keyCode), modifiers: modifiers)
                    isRecording = false
                    return nil
                }
                return event
            }
        }
    }
} 
