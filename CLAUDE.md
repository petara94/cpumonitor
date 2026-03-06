# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

macOS menu bar (tray) app that displays per-core CPU load as colored bar columns. Built with Swift/SwiftUI, requires macOS 13.5+.

## Build & Run

This is an Xcode project (no SPM). Open `cpumonitor.xcodeproj` in Xcode or build from CLI:

```bash
xcodebuild -project cpumonitor.xcodeproj -scheme cpumonitor build
xcodebuild -project cpumonitor.xcodeproj -scheme cpumonitor -destination 'platform=macOS' test
```

## Architecture

- **Entry point**: `cpumonitorApp.swift` — `@main` App struct with `@NSApplicationDelegateAdaptor` connecting to `TrayBar`
- **TrayBar** (`src/tray/Tray.swift`) — `NSApplicationDelegate` managing the status bar item, popover, settings window, and the update timer. Also contains `NSImage.cpuLoadFromArray` extension that renders CPU bars and `NSColor.colorFromCPULoad` for color thresholds (green/yellow/orange/red)
- **CpuScaner** (`src/cpuScaner/CpuScaner.swift`) — reads per-core CPU stats via `host_processor_info` Mach API, computes diffs between scans to get current load percentages
- **SettingsView** (`src/tray/SettingsView.swift`) — SwiftUI view for adjusting update interval (0.1–2.0s), persisted via `@AppStorage("cpuUpdateInterval")`
- **ContentView** (`ContentView.swift`) — simple welcome window shown on app launch

## Key Details

- Settings use `@AppStorage("cpuUpdateInterval")` with `UserDefaults.didChangeNotification` to reactively restart the timer
- Tray icon is dynamically generated: each CPU core = one colored column (5px wide, 32px tall)
- Global shortcut `Cmd+,` opens settings window
- UI text is partially in Russian
