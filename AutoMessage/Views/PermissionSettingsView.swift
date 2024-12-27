import SwiftUI
import UserNotifications

class PermissionManager: ObservableObject {
    @Published var accessibilityEnabled = false
    @Published var notificationsEnabled = false
    @Published var fullDiskAccessEnabled = false
    
    func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func checkFullDiskAccess() {
        // 尝试读取 Messages 数据库来检查权限
        let path = NSString(string: "~/Library/Messages/chat.db").expandingTildeInPath
        fullDiskAccessEnabled = FileManager.default.isReadableFile(atPath: path)
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
            }
        }
    }
}

struct PermissionSettingsView: View {
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var launchAtLogin = LaunchAtLogin()
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Label("权限设置", systemImage: "lock.shield.fill")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(Color(NSColor.windowBackgroundColor))
            
            ScrollView {
                VStack(spacing: 20) {
                    // 完全磁盘访问权限卡片
                    PermissionSection(
                        permissionName: "完全磁盘访问权限",
                        icon: "externaldrive.fill",
                        isGranted: permissionManager.fullDiskAccessEnabled,
                        description: "用于读取短信数据库，实现验证码自动识别",
                        actionButtonTitle: "打开系统偏好设置",
                        action: {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                        }
                    )
                    
                    // 辅助功能权限卡片
                    PermissionSection(
                        permissionName: "辅助功能权限",
                        icon: "figure.roll",
                        isGranted: permissionManager.accessibilityEnabled,
                        description: "用于自动粘贴验证码到目标窗口",
                        actionButtonTitle: "打开系统偏好设置",
                        action: {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                        }
                    )
                    
                    // 通知权限卡片
                    PermissionSection(
                        permissionName: "通知权限",
                        icon: "bell.badge.fill",
                        isGranted: permissionManager.notificationsEnabled,
                        description: "用于在收到验证码时发送通知提醒",
                        actionButtonTitle: "授权通知权限",
                        action: {
                            permissionManager.requestNotificationPermission()
                        }
                    )
                    
                    // 开机自启动卡片
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("开机自启动", systemImage: "power")
                                    .font(.headline)
                                Spacer()
                                Toggle("", isOn: $launchAtLogin.isEnabled)
                                    .toggleStyle(SwitchToggleStyle())
                            }
                            
                            Text("开启后，系统启动时会自动运行 AutoMessage")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 权限说明卡片
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("权限说明", systemImage: "info.circle.fill")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                BulletPoint("完全磁盘访问权限用于读取短信内容，确保验证码识别功能")
                                BulletPoint("辅助功能权限用于自动填充验证码，确保安全便捷")
                                BulletPoint("通知权限用于在收到验证码时及时提醒")
                                BulletPoint("所有权限仅用于实现必要功能，不会用于其他用途")
                                BulletPoint("您可以随时在系统设置中管理这些权限")
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
        .onAppear {
            permissionManager.checkAccessibilityPermission()
            permissionManager.checkNotificationPermission()
            permissionManager.checkFullDiskAccess()
        }
    }
}

// 权限部分视图
struct PermissionSection: View {
    let permissionName: String
    let icon: String
    let isGranted: Bool
    let description: String
    let actionButtonTitle: String
    let action: () -> Void
    
    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    // 状态图标
                    ZStack {
                        Circle()
                            .fill(isGranted ? Color.green.opacity(0.1) : Color.secondary.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isGranted ? .green : .secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(permissionName)
                                .font(.headline)
                            
                            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isGranted ? .green : .red)
                        }
                        
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                if !isGranted {
                    Button(action: action) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text(actionButtonTitle)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
} 