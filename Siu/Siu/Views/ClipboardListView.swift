// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import SwiftUI

// MARK: - Monokai Pro Warm Theme
// Inspired by Monokai Pro (Filter Spectrum) — warm, elegant, soft contrast
enum Theme {
    // Backgrounds
    static let bg          = Color(hex: "2D2A2E")       // Monokai Pro bg
    static let bgLight     = Color(hex: "353236")       // slightly lighter
    static let bgHover     = Color(hex: "403E41")       // hover state
    static let bgSelected  = Color(hex: "4A474D")       // selected
    
    // Accents — Monokai Pro warm palette
    static let yellow      = Color(hex: "FFD866")       // warm yellow
    static let orange      = Color(hex: "FC9867")       // warm orange
    static let pink        = Color(hex: "FF6188")       // soft pink
    static let green       = Color(hex: "A9DC76")       // fresh green
    static let purple      = Color(hex: "AB9DF2")       // lavender
    static let cyan        = Color(hex: "78DCE8")       // soft cyan
    
    // Text
    static let text        = Color(hex: "FCFCFA")       // primary text
    static let textSoft    = Color(hex: "C1C0C0")       // secondary
    static let textMuted   = Color(hex: "727072")       // muted
    static let textDim     = Color(hex: "5B595C")       // very dim
    
    // Functional
    static let danger      = Color(hex: "FF6188")
    static let border      = Color(hex: "4A474D")
    
    // Code
    static let codeBg      = Color(hex: "221F22")       // deeper for code blocks
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

// MARK: - Main View
struct ClipboardListView: View {
    @ObservedObject var storage: ClipboardStorage
    @ObservedObject var monitor: ClipboardMonitor
    @ObservedObject var panelController: FloatingPanelController
    
    @State private var searchText = ""
    @State private var showClearConfirmation = false
    @State private var showHotKeySheet = false
    @State private var copiedItemId: UUID? = nil
    @State private var currentClipboardItemId: UUID? = nil
    
    private var filteredItems: [ClipboardItem] {
        storage.filteredItems(searchText: searchText, filter: .all)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle area (header doubles as drag zone)
            headerBar
            searchBar
            dividerLine
            listContent
            dividerLine
            footerBar
        }
        .frame(width: FloatingPanelController.panelWidth,
               height: FloatingPanelController.panelHeight)
        .background(Theme.bg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
        .shadow(color: Theme.orange.opacity(0.04), radius: 40, x: 0, y: 0)
        .alert("确认清空", isPresented: $showClearConfirmation) {
            Button("取消", role: .cancel) {}
            Button("清空全部", role: .destructive) {
                storage.deleteAllItems()
            }
        } message: {
            Text("即将清除所有历史记录，此操作不可逆。")
        }
        .sheet(isPresented: $showHotKeySheet) {
            HotKeySettingsSheet(isPresented: $showHotKeySheet)
        }
    }
    
    // MARK: - Header (draggable)
    private var headerBar: some View {
        HStack(spacing: 8) {
            // Logo — Siu with Monokai accent colors
            HStack(spacing: 1) {
                Text("S")
                    .foregroundStyle(Theme.yellow)
                Text("i")
                    .foregroundStyle(Theme.orange)
                Text("u")
                    .foregroundStyle(Theme.pink)
            }
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            
            Spacer()
            
            // Hotkey settings
            HeaderButton(icon: "keyboard", color: Theme.textMuted) {
                showHotKeySheet = true
            }
            .help("快捷键设置")
            
            // Close
            HeaderButton(icon: "xmark", color: Theme.textMuted) {
                panelController.hidePanel()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }
    
    // MARK: - Search
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textMuted)
            
            TextField("搜索...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
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
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
    
    // MARK: - Divider
    private var dividerLine: some View {
        Rectangle()
            .fill(Theme.border.opacity(0.4))
            .frame(height: 0.5)
    }
    
    // MARK: - List Content
    private var listContent: some View {
        Group {
            if filteredItems.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 1) {
                            ForEach(filteredItems) { item in
                                ClipboardRow(
                                    item: item,
                                    isCopied: copiedItemId == item.id,
                                    isCurrentClipboard: currentClipboardItemId == item.id,
                                    onSelect: { selectItem($0) },
                                    onDelete: { storage.deleteItem($0) },
                                    onTogglePin: { storage.togglePin($0) }
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: panelController.isVisible) { _, visible in
                        if visible {
                            detectCurrentClipboardItem()
                            // Scroll to the matched item
                            if let id = currentClipboardItemId {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        proxy.scrollTo(id, anchor: .top)
                                    }
                                }
                            }
                        } else {
                            currentClipboardItemId = nil
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Match current system clipboard content to an item in the list
    private func detectCurrentClipboardItem() {
        let pasteboard = NSPasteboard.general
        
        // Try text match first
        if let clipText = pasteboard.string(forType: .string) {
            let trimmed = clipText.trimmingCharacters(in: .whitespacesAndNewlines)
            if let matched = storage.items.first(where: { $0.contentType == .text && $0.content == trimmed }) {
                currentClipboardItemId = matched.id
                return
            }
        }
        
        // Try image match — compare with the most recent image item
        if pasteboard.types?.contains(.tiff) == true || pasteboard.types?.contains(.png) == true {
            if let matched = storage.items.first(where: { $0.contentType == .image }) {
                currentClipboardItemId = matched.id
                return
            }
        }
        
        currentClipboardItemId = nil
    }
    
    private func selectItem(_ item: ClipboardItem) {
        monitor.markInternalChange()
        storage.copyToPasteboard(item)
        
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
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "clipboard")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(Theme.textDim)
            
            Text(searchText.isEmpty ? "空空如也" : "没有匹配结果")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textMuted)
            
            if searchText.isEmpty {
                Text("复制内容后自动记录")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textDim)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Footer
    private var footerBar: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Theme.green)
                .frame(width: 5, height: 5)
                .padding(.trailing, 5)
            
            Text("\(storage.itemCount)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.textSoft)
            
            Text(" 条")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textMuted)
            
            Text("  ·  \(ImageStorageManager.shared.formattedStorageSize())")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textDim)
            
            Spacer()
            
            // Purge
            Button {
                showClearConfirmation = true
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "trash")
                        .font(.system(size: 9))
                    Text("清空")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Theme.pink.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Theme.pink.opacity(0.08))
                )
            }
            .buttonStyle(.plain)
            .disabled(storage.itemCount == 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.bgLight.opacity(0.5))
    }
}

// MARK: - Header Button
struct HeaderButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isHovered ? Theme.text : color)
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered ? Theme.bgHover : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Clipboard Row (List style)
struct ClipboardRow: View {
    let item: ClipboardItem
    let isCopied: Bool
    let isCurrentClipboard: Bool
    let onSelect: (ClipboardItem) -> Void
    let onDelete: (ClipboardItem) -> Void
    let onTogglePin: (ClipboardItem) -> Void
    
    @State private var isHovered = false
    @State private var thumbnailImage: NSImage?
    
    private var isCodeLike: Bool {
        guard let text = item.content else { return false }
        let indicators = ["{", "}", "=>", "->", "func ", "def ", "class ", "import ",
                          "const ", "let ", "var ", "return ", "//", "/*", "<div", "</"]
        return indicators.contains(where: { text.contains($0) })
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left accent line
            RoundedRectangle(cornerRadius: 1)
                .fill(accentColor)
                .frame(width: 2.5)
                .padding(.vertical, 6)
            
            VStack(alignment: .leading, spacing: 3) {
                // Pin badge inline
                if item.isPinned {
                    HStack(spacing: 3) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 7))
                        Text("置顶")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(Theme.yellow.opacity(0.7))
                }
                
                // Content
                contentView
            }
            .padding(.leading, 10)
            .padding(.trailing, 6)
            .padding(.vertical, 8)
            
            Spacer(minLength: 4)
            
            // Time
            Text(item.createdAt.relativeFormatted())
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Theme.textDim)
                .fixedSize()
                .padding(.trailing, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.yellow.opacity(isCopied ? 0.12 : 0))
        )
        .overlay(
            Group {
                if isCurrentClipboard {
                    HStack(spacing: 0) {
                        Spacer()
                        // "当前" badge
                        Text("当前")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Theme.bg)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(Theme.yellow)
                            )
                            .padding(.trailing, 8)
                            .padding(.top, 6)
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isCurrentClipboard ? Theme.yellow.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isCopied ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isCopied)
        .padding(.horizontal, 6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onSelect(item)
        }
        .contextMenu {
            Button {
                onSelect(item)
            } label: {
                Label("复制", systemImage: "doc.on.clipboard")
            }
            Button {
                onTogglePin(item)
            } label: {
                Label(item.isPinned ? "取消置顶" : "置顶", systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            Divider()
            Button(role: .destructive) {
                onDelete(item)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .task {
            if item.contentType == .image, let fileName = item.imageFileName {
                thumbnailImage = ImageStorageManager.shared.loadThumbnail(fileName: fileName)
            }
        }
    }
    
    private var accentColor: Color {
        switch item.contentType {
        case .image: return Theme.purple
        case .text:
            if isCodeLike { return Theme.cyan }
            return Theme.orange
        }
    }
    
    private var backgroundColor: Color {
        if isCurrentClipboard { return Theme.yellow.opacity(0.08) }
        if isHovered { return Theme.bgHover.opacity(0.6) }
        return Color.clear
    }
    
    // MARK: - Content
    @ViewBuilder
    private var contentView: some View {
        switch item.contentType {
        case .text:
            textView
        case .image:
            imageView
        }
    }
    
    @ViewBuilder
    private var textView: some View {
        let text = item.content ?? ""
        if isCodeLike {
            Text(text.prefix(200))
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(Theme.text.opacity(0.9))
                .lineLimit(4)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.codeBg)
                )
        } else {
            Text(text.prefix(150))
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.text.opacity(0.9))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var imageView: some View {
        HStack(spacing: 8) {
            if let image = thumbnailImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.bgLight)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(Theme.textDim)
                            .font(.system(size: 16))
                    }
            }
            Text("图片")
                .font(.system(size: 12))
                .foregroundStyle(Theme.purple.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - HotKey Settings Sheet
struct HotKeySettingsSheet: View {
    @Binding var isPresented: Bool
    @State private var isRecording = false
    @State private var hotKeyDisplay: String = ""
    @State private var conflictWarning: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "keyboard")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.orange)
                Text("快捷键设置")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("当前快捷键")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text(hotKeyDisplay)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            isRecording ? Theme.orange : Color.primary.opacity(0.1),
                                            lineWidth: isRecording ? 2 : 0.5
                                        )
                                )
                        )
                    
                    Spacer()
                    
                    Button(isRecording ? "取消" : "录制新快捷键") {
                        isRecording.toggle()
                        if !isRecording { conflictWarning = nil }
                    }
                    .buttonStyle(.bordered)
                }
                
                if isRecording {
                    Text("请按下新的快捷键组合（需包含 ⌘/⌃/⌥ 修饰键）...")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.orange)
                }
                
                if let warning = conflictWarning {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.pink)
                        Text(warning)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.pink)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Button("恢复默认 (⌘⇧V)") {
                    UserDefaults.standard.removeObject(forKey: "hotKeyKeyCode")
                    UserDefaults.standard.removeObject(forKey: "hotKeyModifiers")
                    HotKeyManager.shared.reRegister()
                    loadDisplay()
                    conflictWarning = nil
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("完成") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.orange)
            }
        }
        .padding(20)
        .frame(width: 400)
        .background(
            HotKeyRecorderView(isRecording: $isRecording, onKeyRecorded: { keyCode, modifiers in
                if let conflict = checkConflict(keyCode: keyCode, modifiers: modifiers) {
                    conflictWarning = conflict
                    return
                }
                UserDefaults.standard.set(Int(keyCode), forKey: "hotKeyKeyCode")
                UserDefaults.standard.set(Int(modifiers.rawValue), forKey: "hotKeyModifiers")
                HotKeyManager.shared.reRegister()
                isRecording = false
                conflictWarning = nil
                loadDisplay()
            })
            .frame(width: 0, height: 0)
        )
        .onAppear { loadDisplay() }
    }
    
    private func loadDisplay() {
        let keyCode = UserDefaults.standard.integer(forKey: "hotKeyKeyCode")
        let modifiers = UserDefaults.standard.integer(forKey: "hotKeyModifiers")
        if keyCode == 0 {
            hotKeyDisplay = "⌘ ⇧ V"
        } else {
            let flags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
            hotKeyDisplay = HotKeyFormatter.format(keyCode: UInt16(keyCode), modifiers: flags)
        }
    }
    
    private func checkConflict(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String? {
        let flags = modifiers.intersection(.deviceIndependentFlagsMask)
        struct KnownShortcut {
            let keyCode: UInt16; let modifiers: NSEvent.ModifierFlags; let description: String
        }
        let systemShortcuts: [KnownShortcut] = [
            KnownShortcut(keyCode: 8,  modifiers: [.command], description: "⌘C (复制)"),
            KnownShortcut(keyCode: 9,  modifiers: [.command], description: "⌘V (粘贴)"),
            KnownShortcut(keyCode: 7,  modifiers: [.command], description: "⌘X (剪切)"),
            KnownShortcut(keyCode: 6,  modifiers: [.command], description: "⌘Z (撤销)"),
            KnownShortcut(keyCode: 0,  modifiers: [.command], description: "⌘A (全选)"),
            KnownShortcut(keyCode: 1,  modifiers: [.command], description: "⌘S (保存)"),
            KnownShortcut(keyCode: 12, modifiers: [.command], description: "⌘Q (退出)"),
            KnownShortcut(keyCode: 13, modifiers: [.command], description: "⌘W (关闭窗口)"),
            KnownShortcut(keyCode: 45, modifiers: [.command], description: "⌘N (新建)"),
            KnownShortcut(keyCode: 17, modifiers: [.command], description: "⌘T (新标签)"),
            KnownShortcut(keyCode: 35, modifiers: [.command], description: "⌘P (打印)"),
            KnownShortcut(keyCode: 3,  modifiers: [.command], description: "⌘F (查找)"),
            KnownShortcut(keyCode: 4,  modifiers: [.command], description: "⌘H (隐藏)"),
            KnownShortcut(keyCode: 46, modifiers: [.command], description: "⌘M (最小化)"),
            KnownShortcut(keyCode: 48, modifiers: [.command], description: "⌘Tab (切换应用)"),
            KnownShortcut(keyCode: 49, modifiers: [.command], description: "⌘Space (Spotlight)"),
            KnownShortcut(keyCode: 6,  modifiers: [.command, .shift], description: "⌘⇧Z (重做)"),
            KnownShortcut(keyCode: 18, modifiers: [.command, .shift], description: "⌘⇧3 (截屏)"),
            KnownShortcut(keyCode: 21, modifiers: [.command, .shift], description: "⌘⇧4 (区域截屏)"),
            KnownShortcut(keyCode: 23, modifiers: [.command, .shift], description: "⌘⇧5 (截屏工具)"),
            KnownShortcut(keyCode: 49, modifiers: [.control], description: "⌃Space (切换输入法)"),
        ]
        for sc in systemShortcuts {
            let scFlags = sc.modifiers.intersection(.deviceIndependentFlagsMask)
            if keyCode == sc.keyCode && flags == scFlags {
                return "与系统快捷键 \(sc.description) 冲突，请换一个组合"
            }
        }
        return nil
    }
}

// MARK: - HotKey Formatter
enum HotKeyFormatter {
    static func format(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(keyCodeToString(keyCode))
        return parts.joined(separator: " ")
    }
    
    static func keyCodeToString(_ keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 10: "B", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
            32: "U", 33: "[", 34: "I", 35: "P", 36: "↩", 37: "L", 38: "J", 39: "'",
            40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            48: "⇥", 49: "Space", 50: "`",
        ]
        return keyMap[keyCode] ?? "Key\(keyCode)"
    }
}

// MARK: - HotKey Recorder NSView
struct HotKeyRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onKeyRecorded: (UInt16, NSEvent.ModifierFlags) -> Void
    
    func makeNSView(context: Context) -> HotKeyRecorderNSView {
        let view = HotKeyRecorderNSView()
        view.onKeyRecorded = onKeyRecorded
        return view
    }
    
    func updateNSView(_ nsView: HotKeyRecorderNSView, context: Context) {
        nsView.isRecordingEnabled = isRecording
        nsView.onKeyRecorded = onKeyRecorded
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

class HotKeyRecorderNSView: NSView {
    var isRecordingEnabled = false
    var onKeyRecorded: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        guard isRecordingEnabled else {
            super.keyDown(with: event)
            return
        }
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers.contains(.command) || modifiers.contains(.control) || modifiers.contains(.option) else {
            return
        }
        onKeyRecorded?(event.keyCode, modifiers)
    }
}

// MARK: - Visual Effect (kept for compatibility)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
