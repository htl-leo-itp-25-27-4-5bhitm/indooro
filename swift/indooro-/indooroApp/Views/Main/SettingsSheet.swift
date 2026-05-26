import SwiftUI

struct SettingsSheet: View {
    @Binding var trackingMode: TrackingMode
    @Binding var mapScale: Double
    @Binding var tapSetsTarget: Bool
    let canShowAR: Bool
    let userPosition: CGPoint?
    let onShowAR: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Tracking") {
                    Picker("Modus", selection: $trackingMode) {
                        Text("Beacon").tag(TrackingMode.beacon)
                        Text("Debug (kein Beacon)").tag(TrackingMode.debugNoBeacons)
                    }

                    if let pos = userPosition {
                        HStack {
                            Text("Position")
                            Spacer()
                            Text("\(String(format: "%.1f", pos.x))m / \(String(format: "%.1f", pos.y))m")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Karte") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Kartengroesse")
                            Spacer()
                            Text("\(Int(mapScale * 100))%")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $mapScale, in: 0.5...1.0, step: 0.05)
                    }
                    .padding(.vertical, 2)

                    Toggle("Tap setzt Ziel", isOn: $tapSetsTarget)
                }

                Section("AR") {
                    Button {
                        onShowAR()
                    } label: {
                        Label("AR Route starten", systemImage: "arkit")
                    }
                    .disabled(!canShowAR)

                    if !canShowAR {
                        Text("Waehle zuerst ein Ziel, damit eine Route berechnet werden kann.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
