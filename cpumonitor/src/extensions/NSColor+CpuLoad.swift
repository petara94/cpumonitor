//
//  NSColor+CpuLoad.swift
//  cpumonitor
//

import Cocoa

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
