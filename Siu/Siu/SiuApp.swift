// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import SwiftUI
import AppKit

@main
struct SiuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView(storage: appDelegate.storage)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let storage = ClipboardStorage()
    let clipboardMonitor = ClipboardMonitor()
    let panelController = FloatingPanelController()
    
    private var statusItem: NSStatusItem?
    
    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupServices()
    }
    
    @MainActor
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: NSColor.controlTextColor
            ]
            button.attributedTitle = NSAttributedString(string: "Siu", attributes: attributes)
            button.action = #selector(togglePanel)
            button.target = self
            
            panelController.statusItemButton = button
        }
    }
    
    @MainActor
    private func setupServices() {
        clipboardMonitor.configure(storage: storage)
        clipboardMonitor.startMonitoring()
        
        let listView = ClipboardListView(
            storage: storage,
            monitor: clipboardMonitor,
            panelController: panelController
        )
        panelController.setupPanel(content: listView)
        
        // Register system-wide hotkey via Carbon API (reliable even when app not focused)
        HotKeyManager.shared.register { [weak self] in
            self?.panelController.togglePanel()
        }
    }
    
    @MainActor
    @objc private func togglePanel() {
        panelController.togglePanel()
    }
}
