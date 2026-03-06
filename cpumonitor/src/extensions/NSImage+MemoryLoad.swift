//
//  NSImage+MemoryLoad.swift
//  cpumonitor
//

import Cocoa

extension NSImage {
    private static let memColumnWidth: CGFloat = 7
    private static let memColumnHeight: CGFloat = 32
    private static let memMinBarHeight: CGFloat = 5
    private static let memTextColumnGap: CGFloat = 2
    private static let memFontSize: CGFloat = 9

    static func memoryLoadImage(_ memory: MemoryUsage) -> NSImage {
        let usedGB = memory.gigabytes(memory.usedMemory)
        let text = String(format: "%.0fG", usedGB)

        let font = NSFont.monospacedSystemFont(ofSize: memFontSize, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
        ]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let totalWidth = textSize.width + memTextColumnGap + memColumnWidth

        let image = NSImage(size: NSSize(width: totalWidth, height: memColumnHeight))
        image.lockFocus()

        NSColor.clear.set()
        NSRect(origin: .zero, size: NSSize(width: totalWidth, height: memColumnHeight)).fill()

        // Текст
        let textY = (memColumnHeight - textSize.height) / 2
        (text as NSString).draw(at: NSPoint(x: 0, y: textY), withAttributes: attrs)

        // Колба
        let barHeight = max(memMinBarHeight, CGFloat(memory.usedPercent) * memColumnHeight / 100 - 1)
        let columnRect = NSRect(
            x: textSize.width + memTextColumnGap,
            y: 1,
            width: memColumnWidth,
            height: barHeight
        )
        NSColor.colorFromCPULoad(memory.usedPercent).setFill()
        columnRect.fill()

        image.unlockFocus()
        return image
    }
}
