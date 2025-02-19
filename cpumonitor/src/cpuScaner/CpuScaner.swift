//
//  CpuScaner.swift
//  solyanka
//
//  Created by petr_ivanov1 on 13.02.2025.
//

import Foundation

public struct CpuLoad {
    var user: UInt32
    var system: UInt32
    var idle: UInt32
    var nice: UInt32
    
    public func Percent() -> UInt8 {
        if user + system + idle == 0 {
            return 0
        }
        let used = Float(user + system)
        let total = Float(user + system + idle)
        let pertcent = used / total
        
        return UInt8(pertcent*100)
    }
}

public class CpuScaner {
    var lastCpuLoads: [CpuLoad] = []
    
    init()  {
        lastCpuLoads = CpuScaner.scan()
    }
    
    public func ScanCpuDiffs() -> [CpuLoad] {
        let newCpuLoads = CpuScaner.scan()
        var diffs:[CpuLoad] = []
        
        guard newCpuLoads.count == lastCpuLoads.count else {
            return []
        }
        
        for i in 0...newCpuLoads.count - 1 {
            diffs.append(CpuLoad(
                user: UInt32(newCpuLoads[i].user - lastCpuLoads[i].user),
                system: UInt32(newCpuLoads[i].system - lastCpuLoads[i].system),
                idle: UInt32(newCpuLoads[i].idle - lastCpuLoads[i].idle),
                nice: UInt32(newCpuLoads[i].nice - lastCpuLoads[i].nice)
            ))
        }
        
        lastCpuLoads = newCpuLoads
        
        return diffs
    }
    
    static func scan() -> [CpuLoad] {
        var cpuInfo: processor_info_array_t?
        var processorMsgCount: mach_msg_type_number_t = 0
        var processorCount: natural_t = 0
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processorCount, &cpuInfo, &processorMsgCount)
        
        guard result == KERN_SUCCESS else {
            print("Ошибка при получении информации о процессоре")
            return []
        }
        
        var cpuLoads: [CpuLoad] = []
        
        if let cpuInfo = cpuInfo {
            for i in 0..<Int(processorCount) {
                let offset = Int(CPU_STATE_MAX) * i
                let user = UInt32(cpuInfo[offset + Int(CPU_STATE_USER)])
                let system = UInt32(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
                let idle = UInt32(cpuInfo[offset + Int(CPU_STATE_IDLE)])
                let nice = UInt32(cpuInfo[offset + Int(CPU_STATE_NICE)])
                
                cpuLoads.append(CpuLoad(user: user, system: system, idle: idle, nice: nice))
            }
        }
        
        // Освобождаем память
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(processorMsgCount))
        
        return cpuLoads
    }
}
