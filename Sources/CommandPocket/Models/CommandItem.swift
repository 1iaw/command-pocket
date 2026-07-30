import Foundation

struct CommandItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var command: String
    var group: String
    var isPinned: Bool
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        group: String = "其他",
        isPinned: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.group = group
        self.isPinned = isPinned
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

