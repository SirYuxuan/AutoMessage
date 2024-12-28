import Foundation
import SwiftUI
import ServiceManagement

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var launchAtLogin: Bool {
        didSet {
            if #available(macOS 13.0, *) {
                if launchAtLogin {
                    try? SMAppService.mainApp.register()
                } else {
                    try? SMAppService.mainApp.unregister()
                }
            }
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
        }
    }
    
    @Published var showWindowHotkey: KeyCombo {
        didSet {
            if let encoded = try? JSONEncoder().encode(showWindowHotkey) {
                UserDefaults.standard.set(encoded, forKey: "showWindowHotkey")
            }
            NotificationCenter.default.post(name: NSNotification.Name("ShowWindowHotkeyChanged"), object: nil)
        }
    }
    
    private init() {
        // 初始化开机自启动状态
        if #available(macOS 13.0, *) {
            self.launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
        
        // 初始化快捷键设置
        if let data = UserDefaults.standard.data(forKey: "showWindowHotkey"),
           let decoded = try? JSONDecoder().decode(KeyCombo.self, from: data) {
            self.showWindowHotkey = decoded
        } else {
            // 默认快捷键：⌘M
            self.showWindowHotkey = KeyCombo(keyCode: 46, modifiers: Int(NSEvent.ModifierFlags.command.rawValue))
        }
    }
    
    func updateLaunchAtLoginState() {
        if #available(macOS 13.0, *) {
            self.launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
} 