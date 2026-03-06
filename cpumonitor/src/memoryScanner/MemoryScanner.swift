//
//  MemoryScanner.swift
//  cpumonitor
//

import Foundation
import Darwin

struct MemoryUsage {
    var appMemory: UInt64      // App (active + inactive - purgeable)
    var wiredMemory: UInt64    // Wired (ядро, нельзя выгрузить)
    var compressedMemory: UInt64 // Compressed
    var freeMemory: UInt64     // Free + purgeable
    var totalMemory: UInt64    // Всего физической памяти

    var usedMemory: UInt64 {
        appMemory + wiredMemory + compressedMemory
    }

    var usedPercent: UInt8 {
        guard totalMemory > 0 else { return 0 }
        let p = Float(usedMemory) / Float(totalMemory)
        return UInt8(min(100, max(0, p * 100)))
    }

    var appPercent: UInt8 {
        guard totalMemory > 0 else { return 0 }
        return UInt8(min(100, max(0, Float(appMemory) / Float(totalMemory) * 100)))
    }

    var wiredPercent: UInt8 {
        guard totalMemory > 0 else { return 0 }
        return UInt8(min(100, max(0, Float(wiredMemory) / Float(totalMemory) * 100)))
    }

    var compressedPercent: UInt8 {
        guard totalMemory > 0 else { return 0 }
        return UInt8(min(100, max(0, Float(compressedMemory) / Float(totalMemory) * 100)))
    }

    func gigabytes(_ bytes: UInt64) -> Double {
        Double(bytes) / 1_073_741_824.0
    }
}

class MemoryScanner {
    static func scan() -> MemoryUsage {
        let totalMemory = ProcessInfo.processInfo.physicalMemory

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryUsage(appMemory: 0, wiredMemory: 0, compressedMemory: 0, freeMemory: 0, totalMemory: totalMemory)
        }

        let pageSize = UInt64(vm_kernel_page_size)

        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let free = UInt64(stats.free_count) * pageSize
        let purgeable = UInt64(stats.purgeable_count) * pageSize

        let appMemory = (active + inactive) > purgeable ? (active + inactive - purgeable) : 0
        let freeMemory = free + purgeable

        return MemoryUsage(
            appMemory: appMemory,
            wiredMemory: wired,
            compressedMemory: compressed,
            freeMemory: freeMemory,
            totalMemory: totalMemory
        )
    }
}
