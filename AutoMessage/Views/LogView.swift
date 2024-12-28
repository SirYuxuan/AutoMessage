import SwiftUI

struct LogView: View {
    @ObservedObject private var logStore = LogStore.shared
    @State private var selectedLog: LogEntry?
    @State private var showCopiedAlert = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Label("验证码日志", systemImage: "list.bullet.rectangle.portrait")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                
                Button(action: {
                    logStore.clearLogs()
                }) {
                    Label("清空日志", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(Color(NSColor.windowBackgroundColor))
            
            // 日志列表
            if logStore.logs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "text.badge.checkmark")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("暂无验证码记录")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            } else {
                List(logStore.logs) { log in
                    LogEntryRow(log: log, dateFormatter: dateFormatter)
                        .contextMenu {
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(log.code, forType: .string)
                                showCopiedAlert = true
                                
                                // 2秒后自动隐藏提示
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCopiedAlert = false
                                }
                            }) {
                                Label("复制验证码", systemImage: "doc.on.doc")
                            }
                            
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(log.message, forType: .string)
                            }) {
                                Label("复制完整消息", systemImage: "doc.on.clipboard")
                            }
                        }
                }
                .listStyle(PlainListStyle())
            }
        }
        .overlay(
            showCopiedAlert ?
            VStack {
                Spacer()
                Text("验证码已复制")
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.8))
                    )
                    .padding(.bottom, 20)
            }
            .animation(.easeInOut, value: showCopiedAlert)
            : nil
        )
    }
}

struct LogEntryRow: View {
    let log: LogEntry
    let dateFormatter: DateFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(log.code)
                    .font(.system(.title3, design: .monospaced))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(dateFormatter.string(from: log.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Text(log.message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text("匹配规则：\(log.ruleName)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
} 