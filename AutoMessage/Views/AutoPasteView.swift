import SwiftUI

struct AutoPasteView: View {
    @StateObject private var settings = AutoPasteSettings()
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Label("自动粘贴设置", systemImage: "doc.on.clipboard.fill")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(Color(NSColor.windowBackgroundColor))
            
            ScrollView {
                VStack(spacing: 20) {
                    // 主开关卡片
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Toggle("启用自动粘贴", isOn: $settings.isEnabled)
                                    .toggleStyle(SwitchToggleStyle())
                            }
                            
                            Text(settings.isEnabled ? 
                                "自动粘贴功能已开启，验证码将会自粘贴到当前活动窗口" :
                                "开启后，验证码将会自动粘贴到当前活动窗口")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 延时设置卡片
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("延时设置", systemImage: "clock.fill")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("延时时间")
                                    Spacer()
                                    Text(String(format: "%.1f 秒", settings.delay))
                                        .foregroundColor(.blue)
                                        .monospacedDigit()
                                }
                                
                                Slider(
                                    value: $settings.delay,
                                    in: 0.1...3.0,
                                    step: 0.1
                                )
                                .disabled(!settings.isEnabled)
                                
                                Text("设置自动粘贴前的等待时间，可以避免目标窗口未完全激活")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .opacity(settings.isEnabled ? 1 : 0.6)
                    
                    // 自动回车设置卡片
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("自动回车", systemImage: "return")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle("粘贴后自动按回车", isOn: $settings.autoEnter)
                                    .disabled(!settings.isEnabled)
                                
                                Text("开启后，粘贴验证码后会自动按下回车键")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .opacity(settings.isEnabled ? 1 : 0.6)
                    
                    // 使用说明卡片
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("使用说明", systemImage: "info.circle.fill")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                BulletPoint("收到验证码后，会自动复制到剪贴板")
                                BulletPoint("点击需要输入验证码的窗口")
                                BulletPoint("验证码会在设定的延时后自动粘贴")
                                BulletPoint("如果自动粘贴失败，可以适当增加延时时间")
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
    }
}

struct AutoPasteView_Previews: PreviewProvider {
    static var previews: some View {
        AutoPasteView()
    }
} 
