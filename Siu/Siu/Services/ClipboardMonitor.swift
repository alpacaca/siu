// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import AppKit
import Combine
import SwiftData

@MainActor
final class ClipboardMonitor: ObservableObject {
    @Published var isMonitoring: Bool = false
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var storage: ClipboardStorage?
    private var isInternalChange: Bool = false
    
    func configure(storage: ClipboardStorage) {
        self.storage = storage
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        lastChangeCount = NSPasteboard.general.changeCount
        isMonitoring = true
        
        timer = Timer.scheduledTimer(withTimeInterval: Constants.clipboardPollingInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.checkForChanges()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    func markInternalChange() {
        isInternalChange = true
    }
    
    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        if isInternalChange {
            isInternalChange = false
            return
        }
        
        processPasteboardContent(pasteboard)
    }
    
    private func processPasteboardContent(_ pasteboard: NSPasteboard) {
        guard let storage = storage else { return }
        
        if let imageData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: imageData) {
            storage.addImageItem(image)
            return
        }
        
        if let imageData = pasteboard.data(forType: .png),
           let image = NSImage(data: imageData) {
            storage.addImageItem(image)
            return
        }
        
        if let text = pasteboard.string(forType: .string) {
            storage.addTextItem(text)
            return
        }
    }
}
