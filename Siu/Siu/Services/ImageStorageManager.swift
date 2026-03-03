// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import AppKit
import Foundation

@MainActor
final class ImageStorageManager: Sendable {
    static let shared = ImageStorageManager()
    
    private init() {}
    
    func saveImage(_ image: NSImage) -> String? {
        let fileName = "\(UUID().uuidString).png"
        let filePath = Constants.imagesDirectory.appendingPathComponent(fileName)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        do {
            try pngData.write(to: filePath)
            generateThumbnail(from: image, fileName: fileName)
            return fileName
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    func deleteImage(fileName: String) {
        let imagePath = Constants.imagesDirectory.appendingPathComponent(fileName)
        let thumbPath = Constants.thumbnailsDirectory.appendingPathComponent("thumb_\(fileName)")
        
        try? FileManager.default.removeItem(at: imagePath)
        try? FileManager.default.removeItem(at: thumbPath)
    }
    
    func loadImage(fileName: String) -> NSImage? {
        let filePath = Constants.imagesDirectory.appendingPathComponent(fileName)
        return NSImage(contentsOf: filePath)
    }
    
    nonisolated func loadThumbnail(fileName: String) -> NSImage? {
        let thumbPath = Constants.thumbnailsDirectory.appendingPathComponent("thumb_\(fileName)")
        if FileManager.default.fileExists(atPath: thumbPath.path) {
            return NSImage(contentsOf: thumbPath)
        }
        let filePath = Constants.imagesDirectory.appendingPathComponent(fileName)
        return NSImage(contentsOf: filePath)
    }
    
    func storageSize() -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        
        for dir in [Constants.imagesDirectory, Constants.thumbnailsDirectory] {
            if let enumerator = fileManager.enumerator(at: dir, includingPropertiesForKeys: [.fileSizeKey]) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += Int64(fileSize)
                    }
                }
            }
        }
        
        return totalSize
    }
    
    func formattedStorageSize() -> String {
        let bytes = storageSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func generateThumbnail(from image: NSImage, fileName: String) {
        let maxSize = Constants.thumbnailMaxSize
        let originalSize = image.size
        
        var newSize = originalSize
        if originalSize.width > maxSize || originalSize.height > maxSize {
            let ratio = min(maxSize / originalSize.width, maxSize / originalSize.height)
            newSize = NSSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
        }
        
        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: originalSize),
                   operation: .copy,
                   fraction: 1.0)
        thumbnail.unlockFocus()
        
        guard let tiffData = thumbnail.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return
        }
        
        let thumbPath = Constants.thumbnailsDirectory.appendingPathComponent("thumb_\(fileName)")
        try? pngData.write(to: thumbPath)
    }
}
