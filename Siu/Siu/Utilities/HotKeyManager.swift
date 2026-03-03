// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import AppKit
import Carbon

/// Reliable system-wide hotkey using Carbon RegisterEventHotKey API.
/// This works even when the app has no focus / is not frontmost.
@MainActor
final class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var onToggle: (() -> Void)?

    private init() {}

    func register(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle
        unregister()
        
        let keyCode = storedKeyCode()
        let modifiers = storedCarbonModifiers()
        
        installCarbonHandler()
        registerHotKey(keyCode: keyCode, carbonModifiers: modifiers)
    }

    func reRegister() {
        guard let handler = onToggle else { return }
        register(onToggle: handler)
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    // MARK: - Private

    private func installCarbonHandler() {
        let eventSpec = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: UInt32(kEventHotKeyPressed))]

        // Store self pointer for C callback
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        
        var handler: EventHandlerRef?
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyCallback,
            1,
            eventSpec,
            refcon,
            &handler
        )
        if status == noErr {
            eventHandler = handler
        }
    }

    private func registerHotKey(keyCode: UInt32, carbonModifiers: UInt32) {
        let hotKeyID = EventHotKeyID(signature: fourCharCode("SiuH"), id: 1)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr {
            hotKeyRef = ref
        }
    }

    func handleHotKeyEvent() {
        onToggle?()
    }

    // MARK: - Key mapping helpers

    private func storedKeyCode() -> UInt32 {
        let stored = UserDefaults.standard.integer(forKey: "hotKeyKeyCode")
        if stored != 0 {
            return UInt32(stored)
        }
        return UInt32(Constants.defaultHotKeyKeyCode) // 9 = V
    }

    private func storedCarbonModifiers() -> UInt32 {
        let stored = UserDefaults.standard.integer(forKey: "hotKeyModifiers")
        if stored != 0 {
            let flags = NSEvent.ModifierFlags(rawValue: UInt(stored))
            return carbonModifiers(from: flags)
        }
        return carbonModifiers(from: Constants.defaultHotKeyModifiers)
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        return mods
    }
}

// MARK: - Carbon C callback (must be a free function)
private func hotKeyCallback(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData = userData else { return OSStatus(eventNotHandledErr) }
    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    Task { @MainActor in
        manager.handleHotKeyEvent()
    }
    return noErr
}

// MARK: - Utility
private func fourCharCode(_ string: String) -> OSType {
    var result: OSType = 0
    for char in string.utf8.prefix(4) {
        result = (result << 8) | OSType(char)
    }
    return result
}
