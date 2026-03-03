// Copyright (c) 2026 alpaca. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for details.

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("maxHistoryCount") private var maxHistoryCount = 1000
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @ObservedObject var storage: ClipboardStorage
    
    @State private var showClearAlert = false
    @State private var hotKeyDisplay: String = ""
    
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
        .frame(width: 420, height: 280)
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
