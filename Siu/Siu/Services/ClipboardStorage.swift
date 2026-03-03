// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import Foundation
import AppKit
import Combine

@MainActor
final class ClipboardStorage: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var itemCount: Int = 0
    
    private let storageURL: URL
    private var saveTask: Task<Void, Never>?
    
    init() {
        self.storageURL = Constants.appSupportDirectory.appendingPathComponent("clipboard_history.json")
        loadItems()
    }
    
    func addTextItem(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let lastText = items.first(where: { $0.contentType == .text }) {
            if lastText.content == trimmed { return }
        }
        
        let preview = String(trimmed.prefix(Constants.previewMaxLength))
        let item = ClipboardItem(content: trimmed, contentType: .text, contentPreview: preview)
        
        items.insert(item, at: 0)
        cleanupAndSave()
    }
    
    func addImageItem(_ image: NSImage) {
        guard let fileName = ImageStorageManager.shared.saveImage(image) else { return }
        
        let item = ClipboardItem(imageFileName: fileName, contentType: .image, contentPreview: "[图片]")
        items.insert(item, at: 0)
        cleanupAndSave()
    }
    
    func deleteItem(_ item: ClipboardItem) {
        if let fileName = item.imageFileName {
            ImageStorageManager.shared.deleteImage(fileName: fileName)
        }
        items.removeAll { $0.id == item.id }
        itemCount = items.count
        scheduleSave()
    }
    
    func deleteAllItems() {
        for item in items {
            if let fileName = item.imageFileName {
                ImageStorageManager.shared.deleteImage(fileName: fileName)
            }
        }
        items.removeAll()
        itemCount = 0
        scheduleSave()
    }
    
    func togglePin(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isPinned.toggle()
            scheduleSave()
        }
    }
    
    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.contentType {
        case .text:
            if let text = item.content {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let image = item.loadFullImage(), let tiffData = image.tiffRepresentation {
                pasteboard.setData(tiffData, forType: .tiff)
            }
        }
    }
    
    func filteredItems(searchText: String, filter: FilterType) -> [ClipboardItem] {
        var result = items
        
        result.sort { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.createdAt > b.createdAt
        }
        
        switch filter {
        case .all: break
        case .text:
            result = result.filter { $0.contentType == .text }
        case .image:
            result = result.filter { $0.contentType == .image }
        }
        
        if !searchText.isEmpty {
            result = result.filter { item in
                if item.contentType == .text {
                    return item.content?.localizedCaseInsensitiveContains(searchText) ?? false
                }
                return false
            }
        }
        
        return result
    }
    
    private func cleanupAndSave() {
        let maxCount = Constants.maxHistoryCount
        if items.count > maxCount {
            let unpinned = items.filter { !$0.isPinned }
            let excess = items.count - maxCount
            let toRemove = Array(unpinned.suffix(excess))
            
            for item in toRemove {
                if let fileName = item.imageFileName {
                    ImageStorageManager.shared.deleteImage(fileName: fileName)
                }
                items.removeAll { $0.id == item.id }
            }
        }
        
        itemCount = items.count
        scheduleSave()
    }
    
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self.saveItems()
        }
    }
    
    private func saveItems() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(items) else {
            print("Failed to encode clipboard items")
            return
        }
        
        do {
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to save clipboard items: \(error)")
        }
    }
    
    private func loadItems() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            itemCount = 0
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let data = try? Data(contentsOf: storageURL),
              let loaded = try? decoder.decode([ClipboardItem].self, from: data) else {
            print("Failed to load clipboard items")
            itemCount = 0
            return
        }
        
        items = loaded
        itemCount = items.count
    }
}

enum FilterType: String, CaseIterable {
    case all = "全部"
    case text = "文本"
    case image = "图片"
}
