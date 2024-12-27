import Foundation
import ServiceManagement

class LaunchAtLogin: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            if #available(macOS 13.0, *) {
                try? SMAppService.mainApp.register()
            } else {
                let success = SMLoginItemSetEnabled("com.yuansirios.AutoMessage.LaunchHelper" as CFString, isEnabled)
                if !success {
                    // 如果设置失败，恢复状态
                    self.isEnabled = oldValue
                }
            }
            UserDefaults.standard.set(isEnabled, forKey: "LaunchAtLogin.isEnabled")
        }
    }
    
    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "LaunchAtLogin.isEnabled")
    }
} 