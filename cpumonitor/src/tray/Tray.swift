//
//  AppDelegate.swift
//  solyanka
//
//  Created by petr_ivanov1 on 12.02.2025.
//


import Cocoa
import SwiftUI
import Combine


class TrayBar: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var timer: Timer?
    var cpuScanner: CpuScaner = CpuScaner()
    var settingsWindow: NSWindow?
    var settingsCancellable: AnyCancellable?
    @AppStorage("cpuUpdateInterval") var cpuUpdateInterval: Double = 0.25
    private var lastInterval: Double = 0.25
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Создаем иконку в трее
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength) //CGFloat(24))
        
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
        }
        
        // Запускаем таймер для обновления изображения
        startTimer()
        // Глобальный shortcut Cmd+,
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.command) && event.characters == "," {
                self?.openSettingsWindow(nil)
                return nil
            }
            return event
        }
        // Подписка на изменения интервала через NotificationCenter
        settingsCancellable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let newInterval = UserDefaults.standard.double(forKey: "cpuUpdateInterval")
                if abs(newInterval - self.lastInterval) > 0.0001 && newInterval > 0.05 {
                    self.lastInterval = newInterval
                    self.cpuUpdateInterval = newInterval
                    self.startTimer()
                }
            }
        // Создаем popover с SwiftUI-вью
        popover = NSPopover()
        let contentView = ContentView() // Ваше SwiftUI-вью
        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.behavior = .transient // Popover автоматически закрывается при клике вне его
        
        // Добавляем меню в трей
        constructMenu()
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: cpuUpdateInterval, repeats: true) { [weak self] _ in
            self?.updateTrayIcon()
        }
        lastInterval = cpuUpdateInterval
    }
    
    @objc func togglePopover(_ sender: Any?) {
        print("toggle called")
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
    func constructMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Open", action: #selector(openMainWindow(_:)), keyEquivalent: "O"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettingsWindow(_:)), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func openMainWindow(_ sender: Any?) {
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(sender)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc func openSettingsWindow(_ sender: Any?) {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Настройки"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 340, height: 180))
            window.isReleasedWhenClosed = false
            window.center()
            window.level = .floating
            window.standardWindowButton(.zoomButton)?.isEnabled = false
            window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
            window.standardWindowButton(.closeButton)?.isEnabled = true
            window.delegate = self
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // Функция для обновления иконки в трее
    func updateTrayIcon() {
        if let button = statusItem.button {
            button.image = NSImage.cpuLoadFromArray(cpuScanner.ScanCpuDiffs().map({$0.Percent()}))
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Останавливаем таймер
        timer?.invalidate()
    }
}

extension TrayBar: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == settingsWindow {
            settingsWindow = nil
        }
    }
}

extension NSImage {
    static func cpuLoadFromArray(_ array: [UInt8]) -> NSImage {
        let width = 5
        let padding = 1
        let columnWidth = CGFloat(width)
        let columnHeight = CGFloat(32)
        let size = NSSize(width: (width+padding)*array.count, height: 32) // Размер изображения
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        NSColor.clear.set()
        NSRect(origin: .zero, size: size).fill()
        
        for (i, value) in array.enumerated() {
            let barHeight: CGFloat = CGFloat(value) * columnHeight / CGFloat(100) - CGFloat(1)
            
            let columnRect = NSRect(
                x: CGFloat(i) * (columnWidth + CGFloat(padding)),
                y: 1,
                width: columnWidth,
                height: barHeight < 5 ? 5 : barHeight
            )
            NSColor.colorFromCPULoad(value).setFill()
            columnRect.fill()
        }
        
        image.unlockFocus()
        
        return image
    }
}

extension NSColor {
    static func colorFromCPULoad(_ load: UInt8) -> NSColor {
        switch load {
        case 0..<25:
            return NSColor.systemGreen
        case 25..<50:
            return NSColor.systemYellow
        case 50..<80:
            return NSColor.systemOrange
        case 80...100:
            return NSColor.systemRed
        default:
            return NSColor.systemGray
        }
    }
}
