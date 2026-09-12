// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "MoonRabbit",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "MoonRabbit", targets: ["MoonRabbit"])],
    targets: [
        .executableTarget(name: "MoonRabbit", resources: [.process("Resources")]),
        .testTarget(name: "MoonRabbitTests", dependencies: ["MoonRabbit"])
    ]
)
