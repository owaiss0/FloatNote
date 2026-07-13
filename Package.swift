// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FloatNote",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FloatNote", targets: ["FloatNote"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "FloatNote",
            dependencies: [],
            path: "Sources/FloatNote"
        )
    ]
)
