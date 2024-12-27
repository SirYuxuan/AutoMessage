//
//  ContentView.swift
//  AutoMessage
//
//  Created by 雨轩 on 2024/12/27.
//

import SwiftUI
import AppKit

struct MenuItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    
    static let allItems = [
        MenuItem(title: "监控状态", icon: "message.fill"),
        MenuItem(title: "规则配置", icon: "text.badge.checkmark"),
        MenuItem(title: "自动粘贴", icon: "doc.on.clipboard.fill"),
        MenuItem(title: "权限设置", icon: "lock.shield.fill"),
    ]
}

struct ContentView: View {
    @StateObject private var ruleStore = RuleStore()
    @StateObject private var autoPasteSettings = AutoPasteSettings()
    @StateObject private var monitoringState = MonitoringState()
    @State private var selectedMenuItem: MenuItem? = MenuItem.allItems.first
    @State private var hoveredItem: MenuItem?
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // 状态指示器
                HStack {
                    Circle()
                        .fill(monitoringState.isMonitoring ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(monitoringState.isMonitoring ? "监控中" : "已停止")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor))
                
                // 菜单列表
                List(MenuItem.allItems, selection: $selectedMenuItem) { item in
                    Button(action: {
                        selectedMenuItem = item
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 24, height: 24)
                                .foregroundColor(getItemColor(item))
                            
                            Text(item.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(getItemColor(item))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(getItemBackgroundColor(item))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { isHovered in
                        hoveredItem = isHovered ? item : nil
                    }
                }
                .listStyle(SidebarListStyle())
                .background(Color(NSColor.windowBackgroundColor))
            }
            .frame(width: 200)
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1)
                    .padding(.trailing, -1),
                alignment: .trailing
            )
        } detail: {
            VStack {
                if let item = selectedMenuItem {
                    destinationView(for: item.title)
                } else {
                    Text("请选择功能")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                        .padding()
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 900, minHeight: 800)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environmentObject(ruleStore)
        .environmentObject(autoPasteSettings)
        .environmentObject(monitoringState)
    }
    
    private func getItemColor(_ item: MenuItem) -> Color {
        if selectedMenuItem == item {
            return .blue
        }
        return hoveredItem == item ? .blue.opacity(0.7) : .secondary
    }
    
    private func getItemBackgroundColor(_ item: MenuItem) -> Color {
        if selectedMenuItem == item {
            return .blue.opacity(0.15)
        }
        return hoveredItem == item ? .blue.opacity(0.08) : .clear
    }
    
    @ViewBuilder
    private func destinationView(for title: String) -> some View {
        switch title {
        case "监控状态":
            MonitorView()
        case "规则配置":
            RuleConfigView()
        case "自动粘贴":
            AutoPasteView()
        case "权限设置":
            PermissionSettingsView()
        default:
            Text("未知页面")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
