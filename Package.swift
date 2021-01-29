// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "MMMHorizontalPicker",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "MMMHorizontalPicker",
            targets: ["MMMHorizontalPicker"]
		)
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MMMHorizontalPicker",
            dependencies: [],
            path: "Sources"
		),
        .testTarget(
            name: "MMMHorizontalPickerTests",
            dependencies: ["MMMHorizontalPicker"],
            path: "Tests"
		)
    ]
)
