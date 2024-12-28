import SwiftUI

struct MonitorView: View {
    @EnvironmentObject var ruleStore: RuleStore
    @EnvironmentObject var autoPasteSettings: AutoPasteSettings
    @EnvironmentObject var monitoringState: MonitoringState
    @StateObject private var monitor = MessageMonitor.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Label("验证码监控", systemImage: "message.fill")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                
                // 监控开关
                Button(action: {
                    monitoringState.isMonitoring.toggle()
                    if monitoringState.isMonitoring {
                        monitor.startMonitoring()
                    } else {
                        monitor.stopMonitoring()
                    }
                }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(monitoringState.isMonitoring ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(monitoringState.isMonitoring ? "监控中" : "已停止")
                            .foregroundColor(monitoringState.isMonitoring ? .green : .red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(monitoringState.isMonitoring ? Color.green : Color.red, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(Color(NSColor.windowBackgroundColor))
            
            ScrollView {
                VStack(spacing: 20) {
                    // 状态卡片
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("监控状态", systemImage: "antenna.radiowaves.left.and.right")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("监控状态")
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(monitoringState.isMonitoring ? Color.green : Color.red)
                                            .frame(width: 6, height: 6)
                                        Text(monitoringState.isMonitoring ? "正在监控" : "已停止")
                                            .foregroundColor(monitoringState.isMonitoring ? .green : .red)
                                    }
                                }
                                
                                HStack {
                                    Text("自动粘贴")
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(autoPasteSettings.isEnabled ? Color.green : Color.red)
                                            .frame(width: 6, height: 6)
                                        Text(autoPasteSettings.isEnabled ? "已启用" : "已禁用")
                                            .foregroundColor(autoPasteSettings.isEnabled ? .green : .red)
                                    }
                                }
                                
                                HStack {
                                    Text("验证码规则")
                                    Spacer()
                                    Text("\(ruleStore.rules.filter { $0.isEnabled }.count) 条规则启用中")
                                        .foregroundColor(.blue)
                                }
                            }
                            .font(.system(size: 13))
                        }
                    }
                    
                    // 功能说明卡片
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("功能说明", systemImage: "info.circle.fill")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                BulletPoint("实时监控短信内容，自动识别验证码")
                                BulletPoint("支持自定义验证码匹配规则")
                                BulletPoint("验证码会自动复制到剪贴板")
                                BulletPoint("可配置自动粘贴和自动回车功能")
                                BulletPoint("收验证码时会发送系统通知")
                            }
                        }
                    }
                    
                    // GitHub 链接卡片
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("开源地址", systemImage: "link")
                                .font(.headline)
                            
                            Button(action: {
                                NSWorkspace.shared.open(URL(string: "https://github.com/SirYuxuan/AutoMessage")!)
                            }) {
                                HStack(spacing: 12) {
                                    Image("github")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.primary)
                                    
                                    Text("SirYuxuan/AutoMessage")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("欢迎 Star 和提交 Issue")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
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
            print("MonitorView appeared, updating dependencies...")
            monitor.updateDependencies(ruleStore: ruleStore, autoPasteSettings: autoPasteSettings)
            if monitoringState.isMonitoring {
                print("Starting monitoring...")
                monitor.startMonitoring()
            }
        }
        .onChange(of: monitoringState.isMonitoring) { isMonitoring in
            print("Monitoring state changed to: \(isMonitoring)")
            monitor.updateDependencies(ruleStore: ruleStore, autoPasteSettings: autoPasteSettings)
            if isMonitoring {
                monitor.startMonitoring()
            } else {
                monitor.stopMonitoring()
            }
        }
        .onChange(of: ruleStore.rules) { _ in
            print("Rules changed, updating dependencies...")
            monitor.updateDependencies(ruleStore: ruleStore, autoPasteSettings: autoPasteSettings)
        }
        .onChange(of: autoPasteSettings.isEnabled) { _ in
            print("AutoPaste settings changed, updating dependencies...")
            monitor.updateDependencies(ruleStore: ruleStore, autoPasteSettings: autoPasteSettings)
        }
        .onChange(of: autoPasteSettings.delay) { _ in
            print("AutoPaste delay changed, updating dependencies...")
            monitor.updateDependencies(ruleStore: ruleStore, autoPasteSettings: autoPasteSettings)
        }
        .onChange(of: autoPasteSettings.autoEnter) { _ in
            print("AutoPaste autoEnter changed, updating dependencies...")
            monitor.updateDependencies(ruleStore: ruleStore, autoPasteSettings: autoPasteSettings)
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
    }
}

struct MonitorView_Previews: PreviewProvider {
    static var previews: some View {
        MonitorView()
    }
} 
