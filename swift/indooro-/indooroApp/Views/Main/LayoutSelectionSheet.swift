import SwiftUI

struct LayoutSelectionSheet: View {
    @ObservedObject var beaconManager: BeaconManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Server") {
                    Button {
                        beaconManager.selectCurrentServerLayout()
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Aktuelles Server-Layout")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Lädt immer den Live-Stand aus der LeoCloud.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                            selectionIndicator(isSelected: beaconManager.selectedLayoutMode == .currentServer)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section("Letzte Layout-Versionen") {
                    if beaconManager.isLoadingLayoutHistory && beaconManager.layoutHistory.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Versionen werden geladen...")
                                .foregroundColor(.secondary)
                        }
                    } else if beaconManager.layoutHistory.isEmpty {
                        Text("Keine gespeicherten Versionen gefunden.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(beaconManager.layoutHistory) { version in
                            Button {
                                beaconManager.selectLayoutVersion(version.layoutId)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(version.displayName)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(version.detailText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }

                                    Spacer()
                                    selectionIndicator(
                                        isSelected: beaconManager.selectedLayoutMode == .version
                                            && beaconManager.selectedLayoutId == version.layoutId
                                    )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Layout wählen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                beaconManager.refreshLayoutHistory()
            }
            .onAppear {
                beaconManager.refreshLayoutHistory()
            }
        }
    }

    @ViewBuilder
    private func selectionIndicator(isSelected: Bool) -> some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundColor(isSelected ? .blue : .secondary.opacity(0.5))
            .font(.title3)
    }
}
