//
//  Tray.swift
//  cpumonitor
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
    var cpuScanner: CpuScanner = CpuScanner()
    var settingsWindow: NSWindow?
    var settingsCancellable: AnyCancellable?
    @AppStorage("cpuUpdateInterval") var cpuUpdateInterval: Double = 0.25
    private var lastInterval: Double = 0.25

    private static let settingsWindowWidth: CGFloat = 340
    private static let settingsWindowHeight: CGFloat = 180

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Создаем иконку в трее
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

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
        let contentView = ContentView()
        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.behavior = .transient

        // Добавляем меню в трей
        constructMenu()

        // Подписки на sleep/wake
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceCenter.addObserver(self, selector: #selector(handleSleep), name: NSWorkspace.willSleepNotification, object: nil)
        workspaceCenter.addObserver(self, selector: #selector(handleWake), name: NSWorkspace.didWakeNotification, object: nil)
        workspaceCenter.addObserver(self, selector: #selector(handleSleep), name: NSWorkspace.screensDidSleepNotification, object: nil)
        workspaceCenter.addObserver(self, selector: #selector(handleWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: cpuUpdateInterval, repeats: true) { [weak self] _ in
            self?.updateTrayIcon()
        }
        lastInterval = cpuUpdateInterval
    }

    @objc func handleSleep() {
        timer?.invalidate()
        timer = nil
        print("[cpumonitor] Timer stopped (sleep/screen off)")
    }

    @objc func handleWake() {
        cpuScanner.resetLastLoads()
        startTimer()
        print("[cpumonitor] Timer restarted (wake/screen on)")
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
            window.setContentSize(NSSize(width: Self.settingsWindowWidth, height: Self.settingsWindowHeight))
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

    func updateTrayIcon() {
        if let button = statusItem.button {
            button.image = NSImage.cpuLoadFromArray(cpuScanner.scanCpuDiffs().map({ $0.percent() }))
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        timer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

extension TrayBar: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == settingsWindow {
            settingsWindow = nil
        }
    }
}
