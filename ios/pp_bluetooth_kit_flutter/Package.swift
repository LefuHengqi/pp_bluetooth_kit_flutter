// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "pp_bluetooth_kit_flutter",
    platforms: [
        .iOS("10.0")
    ],
    products: [
        .library(
            name: "pp-bluetooth-kit-flutter",
            targets: ["pp_bluetooth_kit_flutter"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/ZipArchive/ZipArchive.git",
            exact: "2.4.3"
        ),
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .binaryTarget(
            name: "PPBaseKit",
            path: "Frameworks/PPBaseKit.xcframework"
        ),
        .binaryTarget(
            name: "PPBluetoothKit",
            path: "Frameworks/PPBluetoothKit.xcframework"
        ),
        .target(
            name: "pp_bluetooth_kit_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "ZipArchive", package: "ZipArchive"),
                "PPBaseKit",
                "PPBluetoothKit"
            ],
            path: "Sources/pp_bluetooth_kit_flutter"
        )
    ]
)
