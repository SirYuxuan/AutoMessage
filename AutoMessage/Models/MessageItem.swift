import Foundation

struct MessageItem: Identifiable {
    let id: Int64
    let text: String
    let date: Date
    let isFromMe: Bool
    var verificationCode: String?
} 