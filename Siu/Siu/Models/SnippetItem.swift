// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import Foundation

final class SnippetItem: Identifiable, Codable, ObservableObject, @unchecked Sendable {
    let id: UUID
    var key: String
    var value: String
    var isEncrypted: Bool
    var tag: String
    var createdAt: Date
    
    init(key: String, value: String, isEncrypted: Bool = false, tag: String = "") {
        self.id = UUID()
        self.key = key
        self.value = value
        self.isEncrypted = isEncrypted
        self.tag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id, key, value, isEncrypted, tag, createdAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        key = try container.decode(String.self, forKey: .key)
        value = try container.decode(String.self, forKey: .value)
        isEncrypted = try container.decodeIfPresent(Bool.self, forKey: .isEncrypted) ?? false
        tag = try container.decodeIfPresent(String.self, forKey: .tag) ?? ""
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
