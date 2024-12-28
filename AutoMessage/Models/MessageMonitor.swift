import Foundation
import SQLite3
import UserNotifications
import AppKit

class MessageMonitor: ObservableObject {
    static let shared = MessageMonitor()
    
    @Published var messages: [MessageItem] = []
    private var database: OpaquePointer?
    private var lastMessageId: Int64 = 0
    private var timer: Timer?
    private var ruleStore: RuleStore = RuleStore()
    private var autoPasteSettings: AutoPasteSettings = AutoPasteSettings()
    
    private init() {
        openDatabase()
    }
    
    func updateDependencies(ruleStore: RuleStore, autoPasteSettings: AutoPasteSettings) {
        print("更新依赖 - RuleStore: \(ruleStore), AutoPasteSettings: \(autoPasteSettings)")
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
            SELECT message.ROWID, message.text, message.date/1000000000 + 978307200, message.is_from_me
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
                if let textData = sqlite3_column_text(statement, 1) {
                    let text = String(cString: textData)
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
            }
            
            DispatchQueue.main.async {
                self.messages = newMessages
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    private func processMessage(_ message: MessageItem) {
        print("开始处理消息: \(message.text)")
        
        // 只处理接收到的消息
        guard !message.isFromMe else {
            print("跳过自己发送的消息")
            return
        }
        
        print("正在检查 \(ruleStore.rules.count) 条规则")
        
        // 遍历所有启用的规则
        for rule in ruleStore.rules where rule.isEnabled {
            print("检查规则: \(rule.name), 模式: \(rule.pattern)")
            if let regex = try? NSRegularExpression(pattern: rule.pattern) {
                let range = NSRange(message.text.startIndex..<message.text.endIndex, in: message.text)
                if let match = regex.firstMatch(in: message.text, range: range) {
                    let matchedString = (message.text as NSString).substring(with: match.range)
                    print("找到匹配: \(matchedString)")
                    
                    // 记录日志
                    print("正在记录日志...")
                    DispatchQueue.main.async {
                        print("添加日志到 LogStore...")
                        LogStore.shared.addLog(LogEntry(code: matchedString, message: message.text, ruleName: rule.name))
                        print("日志添加完成")
                    }
                    
                    // 复制验证码到剪贴板
                    print("正在复制到剪贴板...")
                    DispatchQueue.main.async {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(matchedString, forType: .string)
                        print("验证码已复制到剪贴板")
                    }
                    
                    // 发送通知
                    print("正在发送通知...")
                    sendNotification(code: matchedString)
                    
                    // 如果启用自动粘贴，执行粘贴操作
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
                            print("消息列表已更新")
                        }
                    }
                    
                    print("消息处理完成")
                    break // 找到第一个匹配就停止
                } else {
                    print("未找到匹配")
                }
            } else {
                print("正则表达式编译失败: \(rule.pattern)")
            }
        }
    }
    
    private func sendNotification(code: String) {
        // 检查是否启用了通知
        guard GeneralSettings.shared.showNotification else {
            print("通知已禁用，跳过发送通知")
            return
        }
        
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
        print("已发送通知")
    }
    
    private func checkNewMessages() {
        print("开始检查新消息...")
        let query = """
            SELECT message.ROWID, message.text, message.date/1000000000 + 978307200, message.is_from_me
            FROM message
            WHERE message.ROWID > ? AND message.text IS NOT NULL
            ORDER BY message.date DESC
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            print("SQL 查询准备成功")
            sqlite3_bind_int64(statement, 1, lastMessageId)
            
            var newMessages: [MessageItem] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                if let textData = sqlite3_column_text(statement, 1) {
                    let text = String(cString: textData)
                    let date = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_double(statement, 2)))
                    let isFromMe = sqlite3_column_int(statement, 3) != 0
                    
                    print("发现新消息: ID=\(id), Text=\(text), Date=\(date), IsFromMe=\(isFromMe)")
                    
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
                        print("更新最后消息ID为: \(lastMessageId)")
                    }
                }
            }
            
            if !newMessages.isEmpty {
                print("发现 \(newMessages.count) 条新消息")
                DispatchQueue.main.async {
                    self.messages.insert(contentsOf: newMessages, at: 0)
                }
            } else {
                print("没有发现新消息")
            }
        } else {
            print("SQL 查询准备失败")
            let errorMessage = String(cString: sqlite3_errmsg(database))
            print("SQL错误: \(errorMessage)")
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
        
        // 如果启用了自动回车
        if autoPasteSettings.autoEnter {
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
