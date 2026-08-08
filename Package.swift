// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SoundUp",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "SoundUpCore",
            path: "Sources/SoundUpCore"
        ),
        .executableTarget(
            name: "SoundUp",
            dependencies: ["SoundUpCore"],
            path: "Sources/SoundUp"
        ),
        .testTarget(
            name: "SoundUpCoreTests",
            dependencies: ["SoundUpCore"],
            path: "Tests/SoundUpCoreTests"
        )
    ]
)
