//
//  NSImage+CpuLoad.swift
//  cpumonitor
//

import Cocoa

extension NSImage {
    private static let columnWidth: CGFloat = 5
    private static let columnPadding: CGFloat = 1
    private static let columnHeight: CGFloat = 32
    private static let minBarHeight: CGFloat = 5

    static func cpuLoadFromArray(_ array: [UInt8]) -> NSImage {
        let size = NSSize(
            width: (columnWidth + columnPadding) * CGFloat(array.count),
            height: columnHeight
        )
        let image = NSImage(size: size)

        image.lockFocus()

        NSColor.clear.set()
        NSRect(origin: .zero, size: size).fill()

        for (i, value) in array.enumerated() {
            let barHeight = CGFloat(value) * columnHeight / 100 - 1

            let columnRect = NSRect(
                x: CGFloat(i) * (columnWidth + columnPadding),
                y: 1,
                width: columnWidth,
                height: max(minBarHeight, barHeight)
            )
            NSColor.colorFromCPULoad(value).setFill()
            columnRect.fill()
        }

        image.unlockFocus()

        return image
    }
}
