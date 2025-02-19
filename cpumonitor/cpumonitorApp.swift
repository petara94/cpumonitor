//
//  cpumonitorApp.swift
//  cpumonitor
//
//  Created by petr_ivanov1 on 18.02.2025.
//

import SwiftUI

@main
struct cpumonitorApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: TrayBar// Подключаем AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView().fixedSize()
        }.windowResizability(.contentSize)
    }
}
