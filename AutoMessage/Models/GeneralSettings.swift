import SwiftUI

class GeneralSettings: ObservableObject {
    static let shared = GeneralSettings()
    
    @AppStorage("showNotification") var showNotification: Bool = true
    @AppStorage("showMenuBarIcon") var showMenuBarIcon: Bool = true
    
    private init() {}
} 