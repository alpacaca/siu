// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import Foundation
import AppKit

enum Constants {
    static let appName = "Siu"
    static let maxHistoryCount = 1000
    static let clipboardPollingInterval: TimeInterval = 0.5
    static let thumbnailMaxSize: CGFloat = 200
    static let previewMaxLength = 100
    
    static let defaultHotKeyKeyCode: UInt16 = 9 // V key
    static let defaultHotKeyModifiers: NSEvent.ModifierFlags = [.command, .shift]
    
    static var appSupportDirectory: URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent(appName)
        if !fileManager.fileExists(atPath: appDir.path) {
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        return appDir
    }
    
    static var imagesDirectory: URL {
        let imagesDir = appSupportDirectory.appendingPathComponent("Images")
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: imagesDir.path) {
            try? fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        }
        return imagesDir
    }
    
    static var thumbnailsDirectory: URL {
        let thumbDir = appSupportDirectory.appendingPathComponent("Thumbnails")
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: thumbDir.path) {
            try? fileManager.createDirectory(at: thumbDir, withIntermediateDirectories: true)
        }
        return thumbDir
    }
}
