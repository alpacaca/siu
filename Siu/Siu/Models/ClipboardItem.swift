// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import Foundation
import AppKit

enum ClipboardContentType: String, Codable, CaseIterable {
    case text
    case image
    
    var displayName: String {
        switch self {
        case .text: return "文本"
        case .image: return "图片"
        }
    }
    
    var iconName: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        }
    }
}

final class ClipboardItem: Identifiable, Codable, ObservableObject, @unchecked Sendable {
    let id: UUID
    var content: String?
    var imageFileName: String?
    var contentType: ClipboardContentType
    var createdAt: Date
    var contentPreview: String
    var isPinned: Bool
    
    var imagePath: URL? {
        guard let fileName = imageFileName else { return nil }
        return Constants.imagesDirectory.appendingPathComponent(fileName)
    }
    
    var thumbnailPath: URL? {
        guard let fileName = imageFileName else { return nil }
        return Constants.thumbnailsDirectory.appendingPathComponent("thumb_\(fileName)")
    }
    
    init(content: String? = nil,
         imageFileName: String? = nil,
         contentType: ClipboardContentType,
         contentPreview: String) {
        self.id = UUID()
        self.content = content
        self.imageFileName = imageFileName
        self.contentType = contentType
        self.createdAt = Date()
        self.contentPreview = contentPreview
        self.isPinned = false
    }
    
    func loadThumbnail() -> NSImage? {
        guard let path = thumbnailPath, FileManager.default.fileExists(atPath: path.path) else {
            return loadFullImage()
        }
        return NSImage(contentsOf: path)
    }
    
    func loadFullImage() -> NSImage? {
        guard let path = imagePath, FileManager.default.fileExists(atPath: path.path) else {
            return nil
        }
        return NSImage(contentsOf: path)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content, imageFileName, contentType, createdAt, contentPreview, isPinned
    }
}
