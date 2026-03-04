// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import SwiftUI

// MARK: - Snippet List View
struct SnippetListView: View {
    @ObservedObject var storage: SnippetStorage
    @ObservedObject var monitor: ClipboardMonitor
    @ObservedObject var panelController: FloatingPanelController
    
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    @State private var showAddSheet = false
    @State private var editingItem: SnippetItem? = nil
    @State private var copiedItemId: UUID? = nil
    
    private var filteredItems: [SnippetItem] {
        storage.filteredItems(searchText: searchText, selectedTag: selectedTag)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            snippetSearchBar
            if !storage.allTags.isEmpty {
                tagFilterBar
            }
            snippetDivider
            snippetListContent
        }
        .sheet(isPresented: $showAddSheet) {
            SnippetEditSheet(
                mode: .add,
                existingTags: storage.allTags,
                onSave: { key, value, isEncrypted, tag in
                    storage.addItem(key: key, value: value, isEncrypted: isEncrypted, tag: tag)
                }
            )
        }
        .sheet(item: $editingItem) { item in
            SnippetEditSheet(
                mode: .edit(item: item),
                existingTags: storage.allTags,
                onSave: { key, value, isEncrypted, tag in
                    storage.updateItem(item, key: key, value: value, isEncrypted: isEncrypted, tag: tag)
                }
            )
        }
    }
    
    // MARK: - Search Bar
    private var snippetSearchBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
                
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.text)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textMuted)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.bgLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.border.opacity(0.5), lineWidth: 0.5)
                    )
            )
            
            // Add button
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.bg)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Theme.green)
                            .shadow(color: Theme.green.opacity(0.3), radius: 4)
                    )
            }
            .buttonStyle(.plain)
            .help("Add")
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
    
    // MARK: - Tag Filter Bar
    private var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                TagChip(label: "All", isSelected: selectedTag == nil) {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        selectedTag = nil
                    }
                }
                
                ForEach(storage.allTags, id: \.self) { tag in
                    TagChip(label: tag, isSelected: selectedTag == tag) {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            selectedTag = selectedTag == tag ? nil : tag
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.bottom, 6)
    }
    
    private var snippetDivider: some View {
        Rectangle()
            .fill(Theme.borderGlow)
            .frame(height: 0.5)
            .opacity(0.6)
    }
    
    // MARK: - List Content
    private var snippetListContent: some View {
        Group {
            if filteredItems.isEmpty {
                snippetEmptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredItems) { item in
                            SnippetRow(
                                item: item,
                                isCopied: copiedItemId == item.id,
                                onCopy: { copyItem($0) },
                                onEdit: { editingItem = $0 },
                                onDelete: { storage.deleteItem($0) }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var snippetEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.shield")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(Theme.textDim)
            
            Text(searchText.isEmpty && selectedTag == nil ? "Vault is empty" : "No matches")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.textMuted)
            
            if searchText.isEmpty && selectedTag == nil {
                Text("Tap + to add a snippet")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.textDim)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func copyItem(_ item: SnippetItem) {
        monitor.markInternalChange()
        storage.copyValue(item)
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            copiedItemId = item.id
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            panelController.hidePanel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                copiedItemId = nil
            }
        }
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(isSelected ? Theme.bg : Theme.textSoft)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.purple : Theme.bgLight)
                        .shadow(color: isSelected ? Theme.purple.opacity(0.25) : .clear, radius: 4)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : (isHovered ? Theme.border : Theme.border.opacity(0.3)),
                            lineWidth: 0.5
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Snippet Row (Redesigned — bottom action bar)
struct SnippetRow: View {
    let item: SnippetItem
    let isCopied: Bool
    let onCopy: (SnippetItem) -> Void
    let onEdit: (SnippetItem) -> Void
    let onDelete: (SnippetItem) -> Void
    
    @State private var isHovered = false
    @State private var showSecret = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area — tap to copy
            HStack(spacing: 0) {
                // Left accent with glow
                RoundedRectangle(cornerRadius: 1)
                    .fill(item.isEncrypted ? Theme.purple : Theme.green)
                    .frame(width: 2.5)
                    .padding(.vertical, 6)
                    .shadow(color: (item.isEncrypted ? Theme.purple : Theme.green).opacity(0.35), radius: 3, x: 0, y: 0)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Key + badges
                    HStack(spacing: 6) {
                        Text(item.key)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.yellow)
                            .lineLimit(1)
                        
                        if item.isEncrypted {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Theme.purple.opacity(0.7))
                        }
                        
                        if !item.tag.isEmpty {
                            Text(item.tag)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundStyle(Theme.cyan.opacity(0.9))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(
                                    Capsule()
                                        .fill(Theme.cyan.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .stroke(Theme.cyan.opacity(0.2), lineWidth: 0.5)
                                        )
                                )
                        }
                        
                        Spacer()
                    }
                    
                    // Value — encrypted or plain, max 3 lines
                    HStack(spacing: 4) {
                        if item.isEncrypted && !showSecret {
                            Text(String(repeating: "•", count: min(item.value.count, 24)))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Theme.textMuted)
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(item.value)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Theme.text.opacity(0.85))
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if item.isEncrypted {
                            Button {
                                withAnimation(.easeInOut(duration: 0.12)) {
                                    showSecret.toggle()
                                }
                            } label: {
                                Image(systemName: showSecret ? "eye.slash" : "eye")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.purple.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Theme.codeBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Theme.border.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                }
                .padding(.leading, 10)
                .padding(.trailing, 10)
                .padding(.vertical, 8)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onCopy(item)
            }
            
            // Bottom action bar — slides in on hover
            if isHovered {
                HStack(spacing: 0) {
                    SnippetInlineAction(icon: "doc.on.clipboard", label: "Copy", color: Theme.green) {
                        onCopy(item)
                    }
                    
                    Rectangle()
                        .fill(Theme.border.opacity(0.3))
                        .frame(width: 0.5)
                        .padding(.vertical, 4)
                    
                    SnippetInlineAction(icon: "pencil", label: "Edit", color: Theme.cyan) {
                        onEdit(item)
                    }
                    
                    Rectangle()
                        .fill(Theme.border.opacity(0.3))
                        .frame(width: 0.5)
                        .padding(.vertical, 4)
                    
                    SnippetInlineAction(icon: "trash", label: "Delete", color: Theme.pink) {
                        onDelete(item)
                    }
                }
                .frame(height: 28)
                .background(Theme.bgLight.opacity(0.6))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .fill(Theme.green.opacity(isCopied ? 0.1 : 0))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(
                    isHovered ? Theme.border.opacity(0.6) : Color.clear,
                    lineWidth: 0.5
                )
        )
        .scaleEffect(isCopied ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isCopied)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .padding(.horizontal, 6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button {
                onCopy(item)
            } label: {
                Label("Copy", systemImage: "doc.on.clipboard")
            }
            Button {
                onEdit(item)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                onDelete(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var backgroundColor: Color {
        if isHovered { return Theme.bgHover.opacity(0.5) }
        return Color.clear
    }
}

// MARK: - Inline Action Button (for bottom bar)
struct SnippetInlineAction: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .medium))
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(0.3)
            }
            .foregroundStyle(isHovered ? color : Theme.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isHovered ? color.opacity(0.08) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Action Button (kept for compatibility)
struct SnippetActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isHovered ? color : Theme.textMuted)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isHovered ? color.opacity(0.15) : Theme.bgLight)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Edit Mode
enum SnippetEditMode: Identifiable {
    case add
    case edit(item: SnippetItem)
    
    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let item): return item.id.uuidString
        }
    }
}

// MARK: - Edit Sheet
struct SnippetEditSheet: View {
    let mode: SnippetEditMode
    let existingTags: [String]
    let onSave: (String, String, Bool, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var key: String = ""
    @State private var value: String = ""
    @State private var isEncrypted: Bool = false
    @State private var tag: String = ""
    
    private var title: String {
        switch mode {
        case .add: return "New Snippet"
        case .edit: return "Edit Snippet"
        }
    }
    
    private var isValid: Bool {
        !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isAddMode: Bool {
        if case .add = mode { return true }
        return false
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Image(systemName: isAddMode ? "plus.circle" : "pencil.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.green)
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                Spacer()
            }
            
            Divider()
            
            // Key field
            VStack(alignment: .leading, spacing: 6) {
                Text("Key")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                
                TextField("", text: $key)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
            }
            
            // Value field
            VStack(alignment: .leading, spacing: 6) {
                Text("Value")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $value)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(minHeight: 80, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                    )
            }
            
            // Tag + Encrypt row
            HStack(spacing: 12) {
                // Tag field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tag")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 6) {
                        TextField("", text: $tag)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                        
                        if !existingTags.isEmpty {
                            Menu {
                                ForEach(existingTags, id: \.self) { t in
                                    Button(t) {
                                        tag = t
                                    }
                                }
                            } label: {
                                Image(systemName: "tag")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.purple)
                                    .frame(width: 26, height: 22)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Theme.purple.opacity(0.12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 5)
                                                    .stroke(Theme.purple.opacity(0.2), lineWidth: 0.5)
                                            )
                                    )
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                        }
                    }
                }
                
                // Encrypt toggle
                VStack(alignment: .leading, spacing: 6) {
                    Text("Encrypt")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    Toggle(isOn: $isEncrypted) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 11))
                            .foregroundStyle(isEncrypted ? Theme.purple : Theme.textMuted)
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
                .fixedSize()
            }
            
            Divider()
            
            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    onSave(key, value, isEncrypted, tag)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.green)
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            if case .edit(let item) = mode {
                key = item.key
                value = item.value
                isEncrypted = item.isEncrypted
                tag = item.tag
            }
        }
    }
}
