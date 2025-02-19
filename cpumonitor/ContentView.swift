//
//  ContentView.swift
//  cpumonitor
//
//  Created by petr_ivanov1 on 18.02.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack {
            Image("MenuIcon").frame(height: 100)
                .help(Text("petara94 aka разраб"))

            Divider().frame(height: 100)

            VStack() {
                Text("Welcome to CPU usage monitor!")
                Text("Смотри в трей и балдей!")
                Text("by petara94")
            }
        }
        .padding(10)
    }
}

#Preview {
    ContentView()
}
