import Foundation

class RuleStore: ObservableObject {
    @Published var rules: [Rule] {
        didSet {
            saveRules()
        }
    }
    
    private let saveKey = "SavedRules"
    
    init() {
        // 尝试从 UserDefaults 加载规则
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decodedRules = try? JSONDecoder().decode([Rule].self, from: data) {
            self.rules = decodedRules
        } else {
            // 如果没有保存的规则，使用默认规则
            self.rules = [
                Rule(
                    name: "6位数字验证码",
                    pattern: "(?<![0-9])[0-9]{6}(?![0-9])",
                    isEnabled: true,
                    description: "匹配短信中的6位数字验证码，如：123456"
                ),
                Rule(
                    name: "4-8位混合验证码",
                    pattern: "(?i)(?<![a-z0-9])[a-z0-9]{4,8}(?![a-z0-9])",
                    isEnabled: true,
                    description: "匹配4-8位数字和字母组合的验证码，如：a2B4、12345678"
                )
            ]
        }
    }
    
    private func saveRules() {
        if let encoded = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
} 