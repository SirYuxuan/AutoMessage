import Foundation

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let code: String
    let message: String
    let timestamp: Date
    let ruleName: String
    
    init(code: String, message: String, ruleName: String) {
        self.id = UUID()
        self.code = code
        self.message = message
        self.timestamp = Date()
        self.ruleName = ruleName
    }
} 