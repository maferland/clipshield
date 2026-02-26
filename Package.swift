// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClipShield",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClipShield",
            path: "ClipShield"
        ),
        .testTarget(
            name: "ClipShieldTests",
            dependencies: ["ClipShield"],
            path: "ClipShieldTests"
        ),
    ]
)
