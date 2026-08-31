// swift-tools-version: 5.9
import PackageDescription

#if os(macOS)
let package = Package(
    name: "Sentinel",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SentinelCore", targets: ["SentinelCore"]),
        .executable(name: "Sentinel", targets: ["SentinelApp"]),
        .executable(name: "SentinelHelper", targets: ["SentinelHelper"])
    ],
    dependencies: [
        .package(url: "https://github.com/Lakr233/SkyLightWindow", from: "1.0.0")
    ],
    targets: [
        .target(name: "SentinelCore"),
        .executableTarget(
            name: "SentinelApp",
            dependencies: [
                "SentinelCore",
                .product(name: "SkyLightWindow", package: "SkyLightWindow")
            ]
        ),
        .executableTarget(name: "SentinelHelper", dependencies: ["SentinelCore"]),
        .testTarget(name: "SentinelCoreTests", dependencies: ["SentinelCore"])
    ]
)
#else
let package = Package(
    name: "Sentinel",
    products: [
        .library(name: "SentinelCore", targets: ["SentinelCore"])
    ],
    targets: [
        .target(name: "SentinelCore"),
        .testTarget(name: "SentinelCoreTests", dependencies: ["SentinelCore"])
    ]
)
#endif
