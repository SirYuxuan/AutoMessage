//
//  AutoMessageApp.swift
//  AutoMessage
//
//  Created by 雨轩 on 2024/12/27.
//

import SwiftUI
import SwiftData
import AppKit

@main
struct AutoMessageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var ruleStore = RuleStore()
    @StateObject private var autoPasteSettings = AutoPasteSettings()
    @StateObject private var monitoringState = MonitoringState()
    
    init() {
        // 确保在主线程中设置
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.prohibited)
        }
        
        // 初始化 MessageMonitor
        let monitor = MessageMonitor.shared
        monitor.updateDependencies(ruleStore: ruleStore, autoPasteSettings: autoPasteSettings)
        if monitoringState.isMonitoring {
            monitor.startMonitoring()
        }
    }
    
    var body: some Scene {
        Settings { }
            .commands {
                // 移除所有默认菜单
                CommandGroup(replacing: CommandGroupPlacement.appInfo) { }
                CommandGroup(replacing: CommandGroupPlacement.newItem) { }
                CommandGroup(replacing: CommandGroupPlacement.pasteboard) { }
                CommandGroup(replacing: CommandGroupPlacement.undoRedo) { }
                CommandGroup(replacing: CommandGroupPlacement.systemServices) { }
                CommandGroup(replacing: CommandGroupPlacement.windowList) { }
                CommandGroup(replacing: CommandGroupPlacement.help) { }
            }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?
    
    // 添加环境对象的引用
    let ruleStore = RuleStore()
    let autoPasteSettings = AutoPasteSettings()
    let monitoringState = MonitoringState()
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // 在应用程序完全启动前设置激活策略
        NSApp.setActivationPolicy(.prohibited)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化菜单栏管理器
        menuBarManager = MenuBarManager.shared
        menuBarManager?.setupWithEnvironmentObjects(
            ruleStore: ruleStore,
            autoPasteSettings: autoPasteSettings,
            monitoringState: monitoringState
        )
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
