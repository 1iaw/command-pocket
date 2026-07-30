import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: CommandStore
    @AppStorage("collapseAfterCopy") private var collapseAfterCopy = false

    var body: some View {
        Form {
            Toggle("复制命令后自动收起面板", isOn: $collapseAfterCopy)

            LabeledContent("展开快捷键", value: "⌥ Space")
            LabeledContent("快速添加快捷键", value: "⌥ ⇧ Space")
            LabeledContent("已保存命令", value: "\(store.commands.count) 条")
        }
        .padding(20)
        .frame(width: 420)
    }
}

