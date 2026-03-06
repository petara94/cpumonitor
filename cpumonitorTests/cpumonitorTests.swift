//
//  cpumonitorTests.swift
//  cpumonitorTests
//
//  Created by petr_ivanov1 on 18.02.2025.
//

import Testing
import Cocoa
@testable import cpumonitor

struct cpumonitorTests {

    // MARK: - CpuLoad.percent()

    @Test func percentZeroLoad() {
        let load = CpuLoad(user: 0, system: 0, idle: 100, nice: 0)
        #expect(load.percent() == 0)
    }

    @Test func percentFullLoad() {
        let load = CpuLoad(user: 80, system: 20, idle: 0, nice: 0)
        #expect(load.percent() == 100)
    }

    @Test func percentHalfLoad() {
        let load = CpuLoad(user: 25, system: 25, idle: 50, nice: 0)
        #expect(load.percent() == 50)
    }

    @Test func percentAllZeros() {
        let load = CpuLoad(user: 0, system: 0, idle: 0, nice: 0)
        #expect(load.percent() == 0)
    }

    @Test func percentClampTo100() {
        // Even with large values, percent should not exceed 100
        let load = CpuLoad(user: UInt32.max / 2, system: UInt32.max / 2, idle: 0, nice: 0)
        #expect(load.percent() <= 100)
    }

    // MARK: - CpuScanner.scan()

    @Test func scanReturnsNonEmptyArray() {
        let cores = CpuScanner.scan()
        #expect(!cores.isEmpty)
    }

    // MARK: - CpuScanner.scanCpuDiffs()

    @Test func scanCpuDiffsMatchesCoreCount() {
        let scanner = CpuScanner()
        let diffs = scanner.scanCpuDiffs()
        let cores = CpuScanner.scan()
        #expect(diffs.count == cores.count)
    }

    // MARK: - NSColor.colorFromCPULoad()

    @Test func colorGreenForLowLoad() {
        #expect(NSColor.colorFromCPULoad(10) == NSColor.systemGreen)
    }

    @Test func colorYellowForMediumLoad() {
        #expect(NSColor.colorFromCPULoad(30) == NSColor.systemYellow)
    }

    @Test func colorOrangeForHighLoad() {
        #expect(NSColor.colorFromCPULoad(60) == NSColor.systemOrange)
    }

    @Test func colorRedForVeryHighLoad() {
        #expect(NSColor.colorFromCPULoad(90) == NSColor.systemRed)
    }

    @Test func colorGrayForOverflow() {
        #expect(NSColor.colorFromCPULoad(101) == NSColor.systemGray)
    }
}
