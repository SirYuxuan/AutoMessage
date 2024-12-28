import Foundation

class LogStore: ObservableObject {
    static let shared = LogStore()
    
    @Published var logs: [LogEntry] {
        didSet {
            saveLogs()
        }
    }
    
    private let saveKey = "SavedLogs"
    private let maxLogs = 1000 // 最多保存1000条记录
    
    private init() {
        // 尝试从 UserDefaults 加载日志
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decodedLogs = try? JSONDecoder().decode([LogEntry].self, from: data) {
            self.logs = decodedLogs
        } else {
            self.logs = []
        }
    }
    
    func addLog(_ entry: LogEntry) {
        DispatchQueue.main.async {
            self.logs.insert(entry, at: 0) // 新日志插入到最前面
            
            // 如果超过最大数量，删除旧的日志
            if self.logs.count > self.maxLogs {
                self.logs = Array(self.logs.prefix(self.maxLogs))
            }
        }
    }
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func clearLogs() {
        logs.removeAll()
    }
} 