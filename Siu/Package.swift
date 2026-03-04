// swift-tools-version: 5.10
//
// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.
//

import PackageDescription

let package = Package(
    name: "Siu",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Siu",
            path: "Siu",
            exclude: [
                "Info.plist",
                "Siu.entitlements"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
