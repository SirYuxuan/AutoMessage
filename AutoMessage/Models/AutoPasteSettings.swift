import SwiftUI

class AutoPasteSettings: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "AutoPaste.isEnabled")
        }
    }
    
    @Published var delay: Double {
        didSet {
            UserDefaults.standard.set(delay, forKey: "AutoPaste.delay")
        }
    }
    
    @Published var autoEnter: Bool {
        didSet {
            UserDefaults.standard.set(autoEnter, forKey: "AutoPaste.autoEnter")
        }
    }
    
    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "AutoPaste.isEnabled")
        self.delay = UserDefaults.standard.double(forKey: "AutoPaste.delay")
        self.autoEnter = UserDefaults.standard.bool(forKey: "AutoPaste.autoEnter")
        
        // 设置默认值
        if self.delay == 0 {
            self.delay = 0.5
            UserDefaults.standard.set(self.delay, forKey: "AutoPaste.delay")
        }
    }
} 