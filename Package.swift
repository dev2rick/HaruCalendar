// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "HaruCalendar",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "HaruCalendar", targets: ["HaruCalendar"]),
    ],
    targets: [
        .target(name: "HaruCalendar"),
        .testTarget(
            name: "HaruCalendarTests",
            dependencies: ["HaruCalendar"]
        ),
    ]
)
