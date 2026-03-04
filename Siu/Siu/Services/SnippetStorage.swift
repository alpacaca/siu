// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import Foundation
import AppKit
import Combine

@MainActor
final class SnippetStorage: ObservableObject {
    @Published var items: [SnippetItem] = []
    
    private let storageURL: URL
    private var saveTask: Task<Void, Never>?
    
    /// All unique tags across items (non-empty, sorted)
    var allTags: [String] {
        let tags = Set(items.compactMap { $0.tag.isEmpty ? nil : $0.tag })
        return tags.sorted()
    }
    
    init() {
        self.storageURL = Constants.appSupportDirectory.appendingPathComponent("snippets.json")
        loadItems()
    }
    
    func addItem(key: String, value: String, isEncrypted: Bool = false, tag: String = "") {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, !trimmedValue.isEmpty else { return }
        
        let item = SnippetItem(key: trimmedKey, value: trimmedValue, isEncrypted: isEncrypted, tag: tag)
        items.insert(item, at: 0)
        scheduleSave()
    }
    
    func updateItem(_ item: SnippetItem, key: String, value: String, isEncrypted: Bool, tag: String) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        items[index].value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        items[index].isEncrypted = isEncrypted
        items[index].tag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        scheduleSave()
    }
    
    func deleteItem(_ item: SnippetItem) {
        items.removeAll { $0.id == item.id }
        scheduleSave()
    }
    
    func copyValue(_ item: SnippetItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.value, forType: .string)
    }
    
    func filteredItems(searchText: String, selectedTag: String? = nil) -> [SnippetItem] {
        var result = items
        
        // Tag filter
        if let tag = selectedTag, !tag.isEmpty {
            result = result.filter { $0.tag == tag }
        }
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.key.localizedCaseInsensitiveContains(searchText) ||
                $0.value.localizedCaseInsensitiveContains(searchText) ||
                $0.tag.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            self.saveItems()
        }
    }
    
    private func saveItems() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
    
    private func loadItems() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let data = try? Data(contentsOf: storageURL),
              let loaded = try? decoder.decode([SnippetItem].self, from: data) else { return }
        items = loaded
    }
}
