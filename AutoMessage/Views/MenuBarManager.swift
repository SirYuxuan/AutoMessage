import SwiftUI
import AppKit
import ServiceManagement

class MenuBarManager: NSObject, NSWindowDelegate {
    static let shared = MenuBarManager()
    private var statusItem: NSStatusItem?
    private var window: NSWindow?
    private let settingsManager = SettingsManager.shared
    private let generalSettings = GeneralSettings.shared
    private var ruleStore: RuleStore?
    private var autoPasteSettings: AutoPasteSettings?
    private var monitoringState: MonitoringState?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    
    private override init() {
        super.init()
        setupMenuBar()
        setupEventMonitors()
        
        // 监听菜单栏图标可见性变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenuBarIconVisibility),
            name: NSNotification.Name("MenuBarIconVisibilityChanged"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupEventMonitors() {
        // 本地事件监听器（当应用程序激活时）
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }
        
        // 全局事件监听器（当应用程序在后台时）
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let modifiers = Int(event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue)
        let keyCode = Int(event.keyCode)
        let currentCombo = KeyCombo(keyCode: keyCode, modifiers: modifiers)
        
        if currentCombo == settingsManager.showWindowHotkey {
            DispatchQueue.main.async { [weak self] in
                self?.showMainWindow()
            }
            return true
        }
        return false
    }
    
    func setupWithEnvironmentObjects(ruleStore: RuleStore?, autoPasteSettings: AutoPasteSettings?, monitoringState: MonitoringState?) {
        self.ruleStore = ruleStore
        self.autoPasteSettings = autoPasteSettings
        self.monitoringState = monitoringState
    }
    
    private func setupMenuBar() {
        if generalSettings.showMenuBarIcon {
            // 创建状态栏图标
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            
            if let button = statusItem?.button {
                let image = NSImage(systemSymbolName: "message.fill", accessibilityDescription: "AutoMessage")
                image?.isTemplate = true  // 使图标适应系统暗色/亮色模式
                button.image = image
                button.imagePosition = .imageLeft
            }
            
            // 创建菜单
            let menu = NSMenu()
            
            // 主窗口选项
            let mainWindowItem = NSMenuItem(title: "主窗口", action: #selector(showMainWindow), keyEquivalent: "")
            mainWindowItem.target = self
            menu.addItem(mainWindowItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // 开机自启动选项
            let launchAtLoginItem = NSMenuItem(title: "开机自启", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
            launchAtLoginItem.target = self
            launchAtLoginItem.state = settingsManager.launchAtLogin ? .on : .off
            menu.addItem(launchAtLoginItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // 退出选项
            let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
            quitItem.target = self
            menu.addItem(quitItem)
            
            // 设置菜单
            statusItem?.menu = menu
        }
    }
    
    @objc private func updateMenuBarIconVisibility() {
        if generalSettings.showMenuBarIcon {
            if statusItem == nil {
                setupMenuBar()
            }
        } else {
            if let statusItem = statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
                self.statusItem = nil
            }
        }
    }
    
    @objc private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        // 如果已经有窗口存在，直接显示
        if let existingWindow = self.window {
            existingWindow.makeKeyAndOrderFront(nil)
            existingWindow.center()
            
            // 如果窗口被最小化，恢复它
            if existingWindow.isMiniaturized {
                existingWindow.deminiaturize(nil)
            }
            
            // 确保窗口可见
            existingWindow.orderFrontRegardless()
            return
        }
        
        // 如果没有窗口，创建一个新的
        let contentView = ContentView()
            .environmentObject(ruleStore ?? RuleStore())
            .environmentObject(autoPasteSettings ?? AutoPasteSettings())
            .environmentObject(monitoringState ?? MonitoringState())
        
        // 创建一个自定义窗口控制器
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        window.title = "AutoMessage"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        
        // 设置窗口行为
        window.collectionBehavior = [.fullScreenAuxiliary]
        
        // 设置窗口代理来处理关闭事件
        window.delegate = self
        
        // 保存窗口引用
        self.window = window
        
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
    
    @objc private func toggleLaunchAtLogin() {
        settingsManager.launchAtLogin.toggle()
        updateMenuState()
    }
    
    @objc private func updateMenuState() {
        if let menuItem = statusItem?.menu?.items.first(where: { $0.title == "开机自启" }) {
            menuItem.state = settingsManager.launchAtLogin ? .on : .off
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
} 
