import SwiftUI

struct GeneralSettingsView: View {
    @StateObject private var generalSettings = GeneralSettings.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var isRecordingHotkey = false
    @State private var showAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Label("通用设置", systemImage: "gearshape.fill")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(Color(NSColor.windowBackgroundColor))
            
            ScrollView {
                VStack(spacing: 20) {
                    // 基本设置卡片
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("基本设置", systemImage: "switch.2")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                // 开机自启动
                                HStack {
                                    Image(systemName: "power")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                        .frame(width: 24, height: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("开机自启")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("应用程序随系统启动自动运行")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $settingsManager.launchAtLogin)
                                        .labelsHidden()
                                        .toggleStyle(SwitchToggleStyle())
                                        .scaleEffect(0.8)
                                }
                                .onChange(of: settingsManager.launchAtLogin) { _ in
                                    NotificationCenter.default.post(name: NSNotification.Name("LaunchAtLoginChanged"), object: nil)
                                }
                                
                                Divider()
                                    .padding(.vertical, 4)
                                
                                // 显示通知
                                HStack {
                                    Image(systemName: "bell.badge")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                        .frame(width: 24, height: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("显示通知")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("当收到验证码时显示系统通知")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $generalSettings.showNotification)
                                        .labelsHidden()
                                        .toggleStyle(SwitchToggleStyle())
                                        .scaleEffect(0.8)
                                }
                                
                                Divider()
                                    .padding(.vertical, 4)
                                
                                // 显示菜单栏图标
                                HStack {
                                    Image(systemName: "menubar.rectangle")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                        .frame(width: 24, height: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("显示菜单栏图标")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("在菜单栏显示应用程序图标")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { generalSettings.showMenuBarIcon },
                                        set: { newValue in
                                            if !newValue && settingsManager.showWindowHotkey.keyCode == 0 {
                                                showAlert = true
                                            } else {
                                                generalSettings.showMenuBarIcon = newValue
                                                NotificationCenter.default.post(name: NSNotification.Name("MenuBarIconVisibilityChanged"), object: nil)
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle())
                                    .scaleEffect(0.8)
                                }
                            }
                        }
                    }
                    
                    // 快捷键设置卡片
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("快捷键设置", systemImage: "keyboard")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "window.badge.plus")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                        .frame(width: 24, height: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("显示主窗口")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("快速打开应用程序主窗口")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    HotkeyRecorder(
                                        keyCombo: $settingsManager.showWindowHotkey,
                                        isRecording: $isRecordingHotkey
                                    )
                                }
                                .onChange(of: settingsManager.showWindowHotkey) { _ in
                                    NotificationCenter.default.post(name: NSNotification.Name("ShowWindowHotkeyChanged"), object: nil)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("无法隐藏菜单栏图标"),
                message: Text("请先设置显示主窗口的快捷键，否则隐藏菜单栏图标后将无法打开应用程序窗口。"),
                primaryButton: .default(Text("去设置快捷键")) {
                    isRecordingHotkey = true
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }
}

struct SettingToggleItem: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct GeneralSettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
} 