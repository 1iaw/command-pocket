// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CommandPocket",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "CommandPocket", targets: ["CommandPocket"])
    ],
    targets: [
        .executableTarget(
            name: "CommandPocket",
            path: "Sources/CommandPocket"
        ),
        .testTarget(
            name: "CommandPocketTests",
            dependencies: ["CommandPocket"],
            path: "Tests/CommandPocketTests"
        )
    ]
)

