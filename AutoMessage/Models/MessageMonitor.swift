import Foundation
import SQLite3
import UserNotifications
import AppKit

class MessageMonitor: ObservableObject {
    @Published var messages: [MessageItem] = []
    private var database: OpaquePointer?
    private var lastMessageId: Int64 = 0
    private var timer: Timer?
    private var ruleStore: RuleStore?
    private var autoPasteSettings: AutoPasteSettings?
    
    init() {
        openDatabase()
    }
    
    func updateDependencies(ruleStore: RuleStore, autoPasteSettings: AutoPasteSettings) {
        self.ruleStore = ruleStore
        self.autoPasteSettings = autoPasteSettings
    }
    
    deinit {
        stopMonitoring()
        sqlite3_close(database)
    }
    
    private func openDatabase() {
        let path = NSString(string: "~/Library/Messages/chat.db").expandingTildeInPath
        if sqlite3_open(path, &database) != SQLITE_OK {
            print("无法打开数据库")
            return
        }
    }
    
    func startMonitoring() {
        loadLatestMessages()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkNewMessages()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func loadLatestMessages() {
        let query = """
            SELECT message.ROWID, message.text, message.date, message.is_from_me
            FROM message
            WHERE message.text IS NOT NULL
            ORDER BY message.date DESC
            LIMIT 20
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            var newMessages: [MessageItem] = []
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let text = String(cString: sqlite3_column_text(statement, 1))
                let date = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_double(statement, 2)))
                let isFromMe = sqlite3_column_int(statement, 3) != 0
                
                let message = MessageItem(
                    id: id,
                    text: text,
                    date: date,
                    isFromMe: isFromMe
                )
                newMessages.append(message)
                
                if id > lastMessageId {
                    lastMessageId = id
                }
            }
            
            DispatchQueue.main.async {
                self.messages = newMessages
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    private func processMessage(_ message: MessageItem) {
        guard let ruleStore = ruleStore,
              let autoPasteSettings = autoPasteSettings else { return }
        
        // 只处理接收到的消息
        guard !message.isFromMe else { return }
        
        // 遍历所有启用的规则
        for rule in ruleStore.rules where rule.isEnabled {
            if let regex = try? NSRegularExpression(pattern: rule.pattern) {
                let range = NSRange(message.text.startIndex..<message.text.endIndex, in: message.text)
                if let match = regex.firstMatch(in: message.text, range: range) {
                    let matchedString = (message.text as NSString).substring(with: match.range)
                    
                    // 复制验证码到剪贴板
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(matchedString, forType: .string)
                    
                    // 发送通知
                    sendNotification(code: matchedString)
                    
                    // 如果启用了自动粘贴，执行粘贴操作
                    if autoPasteSettings.isEnabled {
                        print("自动粘贴已启用，延时：\(autoPasteSettings.delay)秒")
                        DispatchQueue.main.asyncAfter(deadline: .now() + autoPasteSettings.delay) {
                            print("延时结束，开始执行自动粘贴")
                            self.performAutoPaste()
                        }
                    } else {
                        print("自动粘贴未启用")
                    }
                    
                    // 更新消息对象
                    var updatedMessage = message
                    updatedMessage.verificationCode = matchedString
                    
                    // 更新UI
                    DispatchQueue.main.async {
                        if let index = self.messages.firstIndex(where: { $0.id == message.id }) {
                            self.messages[index] = updatedMessage
                        }
                    }
                    
                    break // 找到第一个匹配就停止
                }
            }
        }
    }
    
    private func sendNotification(code: String) {
        let content = UNMutableNotificationContent()
        content.title = "收到验证码"
        content.body = "验证码：\(code)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func checkNewMessages() {
        let query = """
            SELECT message.ROWID, message.text, message.date, message.is_from_me
            FROM message
            WHERE message.ROWID > ? AND message.text IS NOT NULL
            ORDER BY message.date DESC
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, lastMessageId)
            
            var newMessages: [MessageItem] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let text = String(cString: sqlite3_column_text(statement, 1))
                let date = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_double(statement, 2)))
                let isFromMe = sqlite3_column_int(statement, 3) != 0
                
                let message = MessageItem(
                    id: id,
                    text: text,
                    date: date,
                    isFromMe: isFromMe
                )
                newMessages.append(message)
                
                // 处理新消息
                processMessage(message)
                
                if id > lastMessageId {
                    lastMessageId = id
                }
            }
            
            if !newMessages.isEmpty {
                DispatchQueue.main.async {
                    self.messages.insert(contentsOf: newMessages, at: 0)
                }
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    private func performAutoPaste() {
        print("开始执行自动粘贴...")
        
        // 模拟 Command+V 快捷键
        let source = CGEventSource(stateID: .combinedSessionState)
        print("创建事件源：\(source != nil ? "成功" : "失败")")
        
        // Command 键按下
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        // V 键按下
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        // V 键抬起
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        // Command 键抬起
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        let loc = CGEventTapLocation.cghidEventTap
        
        cmdDown?.flags = .maskCommand
        vDown?.flags = .maskCommand
        vUp?.flags = .maskCommand
        
        cmdDown?.post(tap: loc)
        vDown?.post(tap: loc)
        vUp?.post(tap: loc)
        cmdUp?.post(tap: loc)
        
        // 如果启用了自动回���
        if autoPasteSettings?.autoEnter ?? false {
            // 等待一小段时间再按回车
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 回车键按下
                let enterDown = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: true)
                // 回车键抬起
                let enterUp = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: false)
                
                enterDown?.post(tap: loc)
                enterUp?.post(tap: loc)
                
                print("自动回车已执行")
            }
        }
        
        print("自动粘贴执行完成")
    }
} 