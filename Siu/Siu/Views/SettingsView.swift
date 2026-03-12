// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import SwiftUI
import AppKit
import ServiceManagement

struct SettingsView: View {
    @AppStorage("maxHistoryCount") private var maxHistoryCount = 1000
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("clipboardSoundName") private var clipboardSoundName = "Blow"
    @ObservedObject var storage: ClipboardStorage
    
    @State private var showClearAlert = false
    @State private var hotKeyDisplay: String = ""
    
    private static let availableSounds: [(name: String, label: String)] = [
        ("OFF",       "关闭"),
        ("Blow",      "Blow — 轻柔吹气"),
        ("Pop",       "Pop — 气泡弹出"),
        ("Tink",      "Tink — 轻敲"),
        ("Glass",     "Glass — 玻璃"),
        ("Ping",      "Ping — 清脆叮"),
        ("Morse",     "Morse — 电码滴"),
        ("Funk",      "Funk — 复古嘟"),
        ("Bottle",    "Bottle — 瓶声"),
        ("Hero",      "Hero — 英雄"),
        ("Frog",      "Frog — 蛙鸣"),
        ("Purr",      "Purr — 呼噜"),
        ("Basso",     "Basso — 低沉"),
        ("Sosumi",    "Sosumi — 经典"),
        ("Submarine", "Submarine — 声纳"),
    ]
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
            
            storageTab
                .tabItem {
                    Label("存储", systemImage: "internaldrive")
                }
            
            aboutTab
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(width: 420, height: 340)
        .onAppear {
            loadHotKeyDisplay()
        }
    }
    
    private var generalTab: some View {
        Form {
            Section("启动") {
                Toggle("开机自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }
            
            Section("快捷键") {
                HStack {
                    Text("呼出悬浮窗")
                    Spacer()
                    Text(hotKeyDisplay)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.primary.opacity(0.06))
                        )
                        .foregroundStyle(.secondary)
                    Text("（在悬浮窗内可修改）")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Section("提示音") {
                HStack {
                    Text("复制提示音")
                    Spacer()
                    Picker("", selection: $clipboardSoundName) {
                        ForEach(Self.availableSounds, id: \.name) { sound in
                            Text(sound.label).tag(sound.name)
                        }
                    }
                    .frame(width: 180)
                    
                    Button {
                        if clipboardSoundName != "OFF" {
                            NSSound(named: clipboardSoundName)?.play()
                        }
                    } label: {
                        Image(systemName: "speaker.wave.2")
                    }
                    .buttonStyle(.borderless)
                    .disabled(clipboardSoundName == "OFF")
                    .help("试听")
                }
            }
            
            Section("历史记录") {
                HStack {
                    Text("最大保留条数")
                    Spacer()
                    TextField("", value: $maxHistoryCount, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private var storageTab: some View {
        Form {
            Section("存储信息") {
                HStack {
                    Text("当前记录数")
                    Spacer()
                    Text("\(storage.itemCount) 条")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("存储占用")
                    Spacer()
                    Text(ImageStorageManager.shared.formattedStorageSize())
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("数据管理") {
                Button("清空所有记录", role: .destructive) {
                    showClearAlert = true
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert("确认清空", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) {}
            Button("清空全部", role: .destructive) {
                storage.deleteAllItems()
            }
        } message: {
            Text("确定要清空所有粘贴板历史记录吗？此操作不可撤销。")
        }
    }
    
    private var aboutTab: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text("SIU")
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundStyle(.orange)
            
            Text("版本 1.0.0")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            
            Text("轻量级粘贴板历史管理工具")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            
            Spacer()
            
            Text("Copyright © 2026 Siu. All rights reserved.")
                .font(.system(size: 10))
                .foregroundStyle(.quaternary)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }
    
    private func loadHotKeyDisplay() {
        let keyCode = UserDefaults.standard.integer(forKey: "hotKeyKeyCode")
        let modifiers = UserDefaults.standard.integer(forKey: "hotKeyModifiers")
        
        if keyCode == 0 {
            hotKeyDisplay = "⌘ ⇧ V"
        } else {
            let flags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
            hotKeyDisplay = HotKeyFormatter.format(keyCode: UInt16(keyCode), modifiers: flags)
        }
    }
}
