import SwiftUI

struct RuleConfigView: View {
    @EnvironmentObject var ruleStore: RuleStore
    @State private var selectedRule: Rule?
    @State private var isCreatingNewRule = false
    @State private var testMessage = ""
    @State private var testResult: String?
    
    var body: some View {
        HSplitView {
            // 左侧规则列表
            VStack(spacing: 0) {
                // 标题区域
                HStack(spacing: 12) {
                    Label("验证规则", systemImage: "list.bullet.rectangle")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        isCreatingNewRule = true
                        selectedRule = nil
                    }) {
                        Label("添加规则", systemImage: "plus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(12)
                .background(
                    Color(NSColor.controlBackgroundColor)
                        .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
                )
                
                // 规则列表
                List(ruleStore.rules, selection: $selectedRule) { rule in
                    RuleListItem(rule: rule)
                        .id(rule.id)
                        .tag(rule)
                        .contextMenu {
                            Button(action: {
                                deleteRule(rule)
                            }) {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
                .listStyle(PlainListStyle())
            }
            .frame(minWidth: 240, maxWidth: 300)
            .background(Color(NSColor.controlBackgroundColor))
            
            // 右侧内容区域
            ZStack {
                Color(NSColor.windowBackgroundColor)
                    .ignoresSafeArea()
                
                if isCreatingNewRule {
                    RuleEditView(
                        editingRule: .constant(Rule()),
                        isNewRule: true,
                        onSave: { newRule in
                            ruleStore.rules.append(newRule)
                            selectedRule = newRule
                            isCreatingNewRule = false
                        },
                        onCancel: {
                            isCreatingNewRule = false
                        }
                    )
                } else if let ruleIndex = ruleStore.rules.firstIndex(where: { $0.id == selectedRule?.id }) {
                    RuleEditView(
                        editingRule: $ruleStore.rules[ruleIndex],
                        isNewRule: false,
                        onSave: { _ in
                            selectedRule = ruleStore.rules[ruleIndex]
                        },
                        onCancel: nil
                    )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("请选择或创建规则")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        Text("在左侧列表中选择一个规则进行编辑，或点击添加按钮创建新规则")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deleteRule(_ rule: Rule) {
        if let index = ruleStore.rules.firstIndex(where: { $0.id == rule.id }) {
            ruleStore.rules.remove(at: index)
            if selectedRule?.id == rule.id {
                selectedRule = nil
            }
        }
    }
}

// 规则列表项视图
struct RuleListItem: View {
    @EnvironmentObject var ruleStore: RuleStore
    @State private var isEnabled: Bool
    let rule: Rule
    
    init(rule: Rule) {
        self.rule = rule
        self._isEnabled = State(initialValue: rule.isEnabled)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态指示点
            Button(action: {
                if let index = ruleStore.rules.firstIndex(where: { $0.id == rule.id }) {
                    isEnabled.toggle()
                    ruleStore.rules[index].isEnabled = isEnabled
                    ruleStore.saveRules()
                }
            }) {
                Circle()
                    .fill(isEnabled ? Color.green : Color.red.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(isEnabled ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: isEnabled ? Color.green.opacity(0.3) : Color.red.opacity(0.2), radius: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isEnabled ? .primary : .secondary)
                Text(rule.pattern)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(Color.clear)
        .contentShape(Rectangle())
        .opacity(isEnabled ? 1 : 0.8)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RulesUpdated"))) { _ in
            // 当规则更新时，检查并更新本地状态
            if let updatedRule = ruleStore.rules.first(where: { $0.id == rule.id }) {
                isEnabled = updatedRule.isEnabled
            }
        }
    }
}

// 规则编辑视图
struct RuleEditView: View {
    @Binding var editingRule: Rule
    @State private var testMessage = ""
    @State private var testResult: String?
    
    let isNewRule: Bool
    let onSave: (Rule) -> Void
    let onCancel: (() -> Void)?
    
    init(editingRule: Binding<Rule>, isNewRule: Bool, onSave: @escaping (Rule) -> Void, onCancel: (() -> Void)?) {
        self._editingRule = editingRule
        self.isNewRule = isNewRule
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部操作栏
            HStack {
                Label(
                    isNewRule ? "创建新规则" : "编辑规则",
                    systemImage: isNewRule ? "plus.circle.fill" : "pencil.circle.fill"
                )
                .font(.title2.bold())
                
                Spacer()
                
                if isNewRule {
                    Button("取消") {
                        onCancel?()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("创建") {
                        onSave(editingRule)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            // 内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 规则基本信息卡片
                    VStack(spacing: 20) {
                        HStack {
                            TextField("规则名称", text: $editingRule.name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Toggle("启用规则", isOn: $editingRule.isEnabled)
                                .toggleStyle(SwitchToggleStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("匹配模式", systemImage: "text.magnifyingglass")
                                .font(.headline)
                            TextEditor(text: $editingRule.pattern)
                                .font(.system(.body, design: .monospaced))
                                .frame(height: 100)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.textBackgroundColor)))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("规则说明", systemImage: "text.alignleft")
                                .font(.headline)
                            TextEditor(text: $editingRule.description)
                                .frame(height: 80)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.textBackgroundColor)))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    
                    // 规则测试区域
                    VStack(alignment: .leading, spacing: 16) {
                        Label("规则测试", systemImage: "checkmark.circle")
                            .font(.headline)
                        
                        TextEditor(text: $testMessage)
                            .frame(height: 100)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.textBackgroundColor)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        
                        HStack {
                            Button(action: { testRule() }) {
                                Label("测试规则", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            
                            if let result = testResult {
                                HStack {
                                    Image(systemName: result.hasPrefix("匹配成功") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    Text(result)
                                }
                                .foregroundColor(result.hasPrefix("匹配成功") ? .green : .red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(result.hasPrefix("匹配成功") ? 
                                            Color.green.opacity(0.1) : 
                                            Color.red.opacity(0.1))
                                )
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                }
                .padding(20)
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func testRule() {
        if let regex = try? NSRegularExpression(pattern: editingRule.pattern) {
            let range = NSRange(testMessage.startIndex..<testMessage.endIndex, in: testMessage)
            if let match = regex.firstMatch(in: testMessage, range: range) {
                let matchedString = (testMessage as NSString).substring(with: match.range)
                testResult = "匹配成功：\(matchedString)"
            } else {
                testResult = "匹配失败"
            }
        } else {
            testResult = "正则表达式无效"
        }
    }
} 