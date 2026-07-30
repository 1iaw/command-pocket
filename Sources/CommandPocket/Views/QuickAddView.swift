import SwiftUI

struct QuickAddView: View {
    @EnvironmentObject private var store: CommandStore

    @State private var command: String
    @State private var name: String
    @State private var group: String
    @State private var validationMessage: String?
    @FocusState private var focusedField: Field?

    let onSaved: () -> Void

    private enum Field {
        case command
        case name
    }

    init(onSaved: @escaping () -> Void) {
        let clipboard = ClipboardService.readText()
        _command = State(initialValue: clipboard)
        _name = State(initialValue: NamingService.suggestName(for: clipboard))
        _group = State(initialValue: NamingService.suggestGroup(for: clipboard))
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section {
                TextEditor(text: $command)
                    .font(.body.monospaced())
                    .frame(minHeight: 92)
                    .focused($focusedField, equals: .command)
                    .onChange(of: command) { newValue in
                        name = NamingService.suggestName(for: newValue)
                        group = NamingService.suggestGroup(for: newValue)
                        validationMessage = nil
                    }
            } header: {
                Text("命令")
            }

            Section {
                HStack {
                    TextField("命令名称", text: $name)
                        .focused($focusedField, equals: .name)
                    Button {
                        name = NamingService.suggestName(for: command)
                    } label: {
                        Label("自动命名", systemImage: "sparkles")
                    }
                    .controlSize(.small)
                }

                Picker("分组", selection: $group) {
                    ForEach(allGroups, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }
            }

            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Spacer()
                Button("保存命令 ↵", action: save)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
            }
        }
        .formStyle(.grouped)
        .onAppear {
            focusedField = command.isEmpty ? .command : .name
        }
    }

    private var allGroups: [String] {
        Array(Set(store.groups + ["Git", "Go", "前端", "服务器", "网络", "日志", "认证", "容器", "其他"]))
            .sorted()
    }

    private func save() {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = "请输入要保存的命令"
            return
        }
        if let reason = NamingService.sensitiveReason(for: trimmed) {
            validationMessage = reason
            return
        }

        store.add(name: name, command: trimmed, group: group)
        onSaved()
    }
}
