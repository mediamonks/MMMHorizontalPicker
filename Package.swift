// swift-tools-version:5.5
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
    dependencies: [
		.package(url: "https://github.com/mediamonks/MMMCommonUI", .upToNextMajor(from: "3.6.1"))
    ],
    targets: [
        .target(
            name: "MMMHorizontalPicker",
            dependencies: [
				"MMMCommonUI"
            ],
            path: "Sources",
            publicHeadersPath: "."
		)
    ]
)
