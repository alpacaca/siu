// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController: ObservableObject {
    @Published var isVisible: Bool = false
    
    private var panel: NSPanel?
    private var clickOutsideMonitor: Any?
    private var escMonitor: Any?
    
    /// Reference to the status item button (kept for fallback)
    weak var statusItemButton: NSStatusBarButton?
    
    static let panelWidth: CGFloat = 460
    static let panelHeight: CGFloat = 520
    
    func setupPanel<Content: View>(content: Content) {
        let hostingView = NSHostingView(rootView: content)
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.panelHeight),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true   // Enable dragging
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.contentView = hostingView
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .utilityWindow
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.panel = panel
    }
    
    func togglePanel() {
        if isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }
    
    func showPanel() {
        guard let panel = panel else { return }
        
        positionBelowStatusItem(panel)
        
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1.0
        }
        
        isVisible = true
        
        // Click outside to dismiss
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                guard let self = self, self.isVisible, let panel = self.panel else { return }
                let screenPoint: NSPoint
                if let eventWindow = event.window {
                    screenPoint = eventWindow.convertPoint(toScreen: event.locationInWindow)
                } else {
                    screenPoint = event.locationInWindow
                }
                if !panel.frame.contains(screenPoint) {
                    self.hidePanel()
                }
            }
        }
        
        // ESC to dismiss
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                Task { @MainActor in
                    self?.hidePanel()
                }
                return nil
            }
            return event
        }
    }
    
    func hidePanel() {
        guard let panel = panel else { return }
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self = self, let panel = self.panel else { return }
                panel.orderOut(nil)
                panel.alphaValue = 1.0
            }
        })
        
        isVisible = false
        
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
        if let monitor = escMonitor {
            NSEvent.removeMonitor(monitor)
            escMonitor = nil
        }
    }
    
    /// Position panel so its top-left corner is directly below the status bar icon
    private func positionBelowStatusItem(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size
        
        if let button = statusItemButton, let buttonWindow = button.window {
            // Get the status item's screen-space rect
            let buttonRect = button.convert(button.bounds, to: nil)
            let screenRect = buttonWindow.convertToScreen(buttonRect)
            
            // Panel top-left: aligned to the left edge of the icon, just below the menu bar
            let x = screenRect.minX
            let y = screenRect.minY - panelSize.height  // macOS y is bottom-up; minY of icon - panel height
            
            // Clamp to screen bounds
            let clampedX = min(max(x, screenFrame.minX), screenFrame.maxX - panelSize.width)
            let clampedY = max(y, screenFrame.minY)
            
            panel.setFrameOrigin(NSPoint(x: clampedX, y: clampedY))
        } else {
            // Fallback: center on screen
            let x = screenFrame.midX - panelSize.width / 2
            let y = screenFrame.midY - panelSize.height / 2 + screenFrame.height * 0.1
            panel.setFrameOrigin(NSPoint(x: x, y: max(y, screenFrame.minY)))
        }
    }
}
