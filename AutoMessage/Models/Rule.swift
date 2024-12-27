import Foundation

struct Rule: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var pattern: String
    var isEnabled: Bool
    var description: String
    var lastModified: Date
    
    init(id: UUID = UUID(), name: String = "新规则", pattern: String = "", isEnabled: Bool = true, description: String = "", lastModified: Date = Date()) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.isEnabled = isEnabled
        self.description = description
        self.lastModified = lastModified
    }
    
    // 实现 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // 实现相等性比较
    static func == (lhs: Rule, rhs: Rule) -> Bool {
        lhs.id == rhs.id
    }
} 