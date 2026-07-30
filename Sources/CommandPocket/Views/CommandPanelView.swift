import SwiftUI

struct CommandPanelView: View {
    @EnvironmentObject private var store: CommandStore
    @State private var isQuickAddPresented: Bool

    let onRequestQuickAdd: () -> Void
    let onClose: () -> Void

    init(
        quickAddInitiallyPresented: Bool,
        onRequestQuickAdd: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        _isQuickAddPresented = State(initialValue: quickAddInitiallyPresented)
        self.onRequestQuickAdd = onRequestQuickAdd
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if isQuickAddPresented {
                QuickAddView {
                    isQuickAddPresented = false
                }
                .environmentObject(store)
            } else {
                commandList
            }
        }
        .frame(width: 380)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            if let feedback = store.copyFeedback {
                Text(feedback)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.82), in: Capsule())
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.16), value: store.copyFeedback)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isQuickAddPresented ? "快速添加" : "命令口袋")
                    .font(.headline)
                Text(isQuickAddPresented ? "从剪贴板保存命令" : "点击一行即可复制")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !isQuickAddPresented {
                Text("⌥ Space")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

                Button {
                    isQuickAddPresented = true
                    onRequestQuickAdd()
                } label: {
                    Label("快速添加", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Button("返回") {
                    isQuickAddPresented = false
                }
                .controlSize(.small)
            }
        }
        .padding(16)
    }

    private var commandList: some View {
        Group {
            if store.sortedCommands.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "terminal")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                    Text("还没有保存命令")
                        .font(.headline)
                    Text("复制一条命令，然后按 ⌥⇧Space 快速添加。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("添加第一条命令") {
                        isQuickAddPresented = true
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.sortedCommands) { item in
                        CommandRowView(
                            item: item,
                            onCopy: {
                                store.copy(item)
                                if UserDefaults.standard.bool(forKey: "collapseAfterCopy") {
                                    Task {
                                        try? await Task.sleep(for: .milliseconds(300))
                                        onClose()
                                    }
                                }
                            },
                            onPin: { store.togglePin(item) },
                            onDelete: { store.delete(item) }
                        )
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(height: 390)
        .onExitCommand(perform: onClose)
    }
}

private struct CommandRowView: View {
    let item: CommandItem
    let onCopy: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onCopy) {
            HStack(spacing: 11) {
                Image(systemName: iconName)
                    .frame(width: 30, height: 30)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(item.name)
                            .font(.body.weight(.medium))
                            .lineLimit(1)
                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(item.command)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(item.isPinned ? "取消置顶" : "置顶", action: onPin)
            Divider()
            Button("删除", role: .destructive, action: onDelete)
        }
    }

    private var iconName: String {
        switch item.group {
        case "Git": return "arrow.triangle.branch"
        case "Go": return "shippingbox"
        case "前端": return "curlybraces"
        case "服务器": return "server.rack"
        case "网络": return "network"
        case "日志": return "doc.text.magnifyingglass"
        case "认证": return "key"
        case "容器": return "cube"
        default: return "terminal"
        }
    }
}
