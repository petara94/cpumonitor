//
//  NSImage+CombinedTray.swift
//  cpumonitor
//

import Cocoa

extension NSImage {
    private static let spacing: CGFloat = 4

    static func combinedTrayIcon(cpu: NSImage, memory: NSImage) -> NSImage {
        let h: CGFloat = 32
        let totalWidth = cpu.size.width + spacing + memory.size.width

        let image = NSImage(size: NSSize(width: totalWidth, height: h))
        image.lockFocus()

        NSColor.clear.set()
        NSRect(origin: .zero, size: NSSize(width: totalWidth, height: h)).fill()

        cpu.draw(
            in: NSRect(x: 0, y: 0, width: cpu.size.width, height: h),
            from: .zero, operation: .sourceOver, fraction: 1.0
        )

        let memX = cpu.size.width + spacing
        memory.draw(
            in: NSRect(x: memX, y: 0, width: memory.size.width, height: h),
            from: .zero, operation: .sourceOver, fraction: 1.0
        )

        image.unlockFocus()
        return image
    }
}
