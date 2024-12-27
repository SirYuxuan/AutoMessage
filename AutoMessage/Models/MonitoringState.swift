import SwiftUI

class MonitoringState: ObservableObject {
    @Published var isMonitoring: Bool {
        didSet {
            UserDefaults.standard.set(isMonitoring, forKey: "Monitoring.isEnabled")
        }
    }
    
    init() {
        self.isMonitoring = UserDefaults.standard.bool(forKey: "Monitoring.isEnabled")
    }
} 