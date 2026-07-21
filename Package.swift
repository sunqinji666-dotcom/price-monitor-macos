// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PriceMonitor",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "PriceMonitor", targets: ["PriceMonitor"])],
    targets: [.executableTarget(name: "PriceMonitor")]
)
