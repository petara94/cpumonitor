//
//  AppDelegate.swift
//  solyanka
//
//  Created by petr_ivanov1 on 12.02.2025.
//


import Cocoa
import SwiftUI


class TrayBar: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var timer: Timer?
    var cpuScanner: CpuScaner = CpuScaner()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Создаем иконку в трее
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength) //CGFloat(24))
        
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
        }
        
        // Запускаем таймер для обновления изображения
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            self.updateTrayIcon()
        }
        
        // Создаем popover с SwiftUI-вью
        popover = NSPopover()
        let contentView = ContentView() // Ваше SwiftUI-вью
        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.behavior = .transient // Popover автоматически закрывается при клике вне его
        
        // Добавляем меню в трей
        constructMenu()
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
