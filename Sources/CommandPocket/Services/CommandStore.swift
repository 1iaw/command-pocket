import Foundation

@MainActor
final class CommandStore: ObservableObject {
    @Published private(set) var commands: [CommandItem] = []
    @Published var copyFeedback: String?

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        load()
    }

    var sortedCommands: [CommandItem] {
        commands.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            if $0.sortOrder != $1.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }
            return $0.updatedAt > $1.updatedAt
        }
    }

    var groups: [String] {
        Array(Set(commands.map(\.group))).sorted()
    }

    func add(name: String, command: String, group: String) {
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCommand.isEmpty else { return }

        commands.append(
            CommandItem(
                name: trimmedName.isEmpty ? NamingService.suggestName(for: trimmedCommand) : trimmedName,
                command: trimmedCommand,
                group: group.isEmpty ? NamingService.suggestGroup(for: trimmedCommand) : group,
                sortOrder: commands.count
            )
        )
        save()
    }

    func delete(_ item: CommandItem) {
        commands.removeAll { $0.id == item.id }
        save()
    }

    func togglePin(_ item: CommandItem) {
        guard let index = commands.firstIndex(where: { $0.id == item.id }) else { return }
        commands[index].isPinned.toggle()
        commands[index].updatedAt = Date()
        save()
    }

    func copy(_ item: CommandItem) {
        ClipboardService.write(item.command)
        copyFeedback = "已复制：\(item.name)"

        Task {
            try? await Task.sleep(for: .seconds(1.4))
            if copyFeedback == "已复制：\(item.name)" {
                copyFeedback = nil
            }
        }
    }

    func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder.pretty.encode(commands)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            copyFeedback = "保存失败：\(error.localizedDescription)"
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder.iso8601.decode([CommandItem].self, from: data)
        else {
            commands = Self.defaultCommands()
            save()
            return
        }
        commands = saved
    }

    private static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base
            .appendingPathComponent("CommandPocket", isDirectory: true)
            .appendingPathComponent("commands.json")
    }

    private static func defaultCommands() -> [CommandItem] {
        [
            CommandItem(name: "查看 Git 状态", command: "git status", group: "Git", sortOrder: 0),
            CommandItem(name: "整理 Go 依赖", command: "go mod tidy", group: "Go", sortOrder: 1),
            CommandItem(name: "启动前端开发环境", command: "npm run dev", group: "前端", sortOrder: 2),
            CommandItem(name: "查看实时日志", command: "tail -f app.log", group: "日志", sortOrder: 3)
        ]
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
