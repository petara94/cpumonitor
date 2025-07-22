import SwiftUI

struct SettingsView: View {
    @AppStorage("cpuUpdateInterval") private var cpuUpdateInterval: Double = 0.25
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Интервал обновления CPU")
                .font(.headline)
            HStack {
                Slider(value: $cpuUpdateInterval, in: 0.1...2.0, step: 0.05)
                Text(String(format: "%.2f сек", cpuUpdateInterval))
                    .frame(width: 70, alignment: .leading)
            }
            Text("Измените интервал обновления CPU (от 0.1 до 2 секунд)")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(24)
        .frame(width: 320, height: 160)
    }
}

#Preview {
    SettingsView()
} 