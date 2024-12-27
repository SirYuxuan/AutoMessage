import SwiftUI

struct MessageRow: View {
    let message: MessageItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(message.isFromMe ? "发送" : "接收")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(formatDate(message.date))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let code = message.verificationCode {
                    Text(code)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Text(message.text)
                .font(.system(size: 13))
                .lineLimit(3)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
} 