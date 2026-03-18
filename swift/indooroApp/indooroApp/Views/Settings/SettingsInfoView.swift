import SwiftUI

struct SettingsInfoView: View {
    @ObservedObject var beaconManager: BeaconManager
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("show_live_position") private var showLivePosition = true

    var body: some View {
        NavigationStack {
            List {
                appOverviewSection
                layoutsSection
                preferencesSection
                accountSection
                supportSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Info & Settings")
        }
    }

    private var appOverviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "location.north.line.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)

                    Text("Indooro")
                        .font(.title3.weight(.semibold))
                }

                Text("Indoor Navigation für schnelle Wege im Markt.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
        }
    }

    private var preferencesSection: some View {
        Section("Präferenzen") {
            Toggle(isOn: $notificationsEnabled) {
                Label("Benachrichtigungen", systemImage: "bell")
            }

            Toggle(isOn: $showLivePosition) {
                Label("Live-Position anzeigen", systemImage: "location")
            }
        }
    }

    private var layoutsSection: some View {
        Section("Layouts") {
            NavigationLink {
                LayoutSelectionView(beaconManager: beaconManager)
            } label: {
                HStack(spacing: 12) {
                    Label("Layout auswählen", systemImage: "square.stack.3d.down.forward")

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(beaconManager.currentLayoutName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(beaconManager.selectedLayoutId == nil ? "Aktuelles Server-Layout" : "Gespeicherte Version")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let savedAt = beaconManager.currentLayoutSavedAt, !savedAt.isEmpty {
                Label("Aktiv seit \(formattedLayoutDate(savedAt))", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var accountSection: some View {
        Section("Konto (Demo)") {
            NavigationLink {
                LoginDemoView()
            } label: {
                Label("Login", systemImage: "person.badge.key")
            }

            NavigationLink {
                RegisterDemoView()
            } label: {
                Label("Registrieren", systemImage: "person.badge.plus")
            }
        }
    }

    private var supportSection: some View {
        Section("App") {
            Label("Version 1.0 Demo", systemImage: "info.circle")
                .foregroundColor(.secondary)
        }
    }
}

private struct LayoutSelectionView: View {
    @ObservedObject var beaconManager: BeaconManager

    var body: some View {
        List {
            currentLayoutSection
            historySection
        }
        .navigationTitle("Layouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    beaconManager.loadLayoutHistory(forceReload: true)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            beaconManager.loadLayoutHistory()
        }
    }

    private var currentLayoutSection: some View {
        Section("Live") {
            Button {
                beaconManager.selectCurrentLayout()
            } label: {
                LayoutSelectionRow(
                    title: "Aktuelles Server-Layout",
                    subtitle: "Verwendet immer das zuletzt exportierte Layout aus LeoCloud.",
                    detail: beaconManager.selectedLayoutId == nil ? beaconManager.currentLayoutName : "Zum Live-Stand wechseln",
                    isSelected: beaconManager.selectedLayoutId == nil,
                    systemImage: "server.rack"
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var historySection: some View {
        Section("Letzte Layouts") {
            if beaconManager.isLoadingLayoutHistory {
                HStack {
                    ProgressView()
                    Text("Layout-Historie wird geladen …")
                        .foregroundColor(.secondary)
                }
            } else if let error = beaconManager.layoutHistoryError, beaconManager.layoutHistory.isEmpty {
                Text(error)
                    .foregroundColor(.secondary)
            } else if beaconManager.layoutHistory.isEmpty {
                Text("Noch keine gespeicherten Layout-Versionen vorhanden.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(beaconManager.layoutHistory) { layout in
                    Button {
                        beaconManager.selectLayout(layout)
                    } label: {
                        LayoutSelectionRow(
                            title: layout.shopName,
                            subtitle: "Gespeichert \(formattedLayoutDate(layout.savedAt))",
                            detail: "\(layout.elementCount) Elemente",
                            isSelected: beaconManager.selectedLayoutId == layout.layoutId,
                            systemImage: "clock.arrow.circlepath"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct LayoutSelectionRow: View {
    let title: String
    let subtitle: String
    let detail: String
    let isSelected: Bool
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.accentColor.opacity(0.14))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: systemImage)
                        .foregroundColor(.accentColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }

                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct LoginDemoView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = true
    @State private var showAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero(title: "Willkommen zurück", subtitle: "Demo Login ohne Backend")
                form
            }
            .padding(20)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Demo Modus", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Login ist aktuell nur als UI-Demo eingebaut.")
        }
    }

    private var form: some View {
        VStack(spacing: 14) {
            TextField("E-Mail", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .padding()
                .background(fieldBackground)

            SecureField("Passwort", text: $password)
                .textContentType(.password)
                .padding()
                .background(fieldBackground)

            Toggle("Eingeloggt bleiben", isOn: $rememberMe)
                .font(.subheadline)
                .padding(.top, 4)

            Button {
                showAlert = true
            } label: {
                Text("Login")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding(16)
        .background(cardBackground)
    }
}

private struct RegisterDemoView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var acceptTerms = false
    @State private var showAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero(title: "Neues Konto", subtitle: "Demo Registrierung ohne Backend")
                form
            }
            .padding(20)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("Registrieren")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Demo Modus", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Registrierung ist aktuell nur als UI-Demo eingebaut.")
        }
    }

    private var form: some View {
        VStack(spacing: 14) {
            TextField("Name", text: $name)
                .textContentType(.name)
                .padding()
                .background(fieldBackground)

            TextField("E-Mail", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .padding()
                .background(fieldBackground)

            SecureField("Passwort", text: $password)
                .textContentType(.newPassword)
                .padding()
                .background(fieldBackground)

            Toggle("AGB akzeptieren (Demo)", isOn: $acceptTerms)
                .font(.subheadline)
                .padding(.top, 4)

            Button {
                showAlert = true
            } label: {
                Text("Konto erstellen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!acceptTerms)
            .padding(.top, 4)
        }
        .padding(16)
        .background(cardBackground)
    }
}

private func hero(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .font(.largeTitle.weight(.bold))
            .foregroundColor(.primary)

        Text(subtitle)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

private var backgroundGradient: LinearGradient {
    LinearGradient(
        colors: [
            Color.accentColor.opacity(0.12),
            Color(.systemBackground)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
}

private var fieldBackground: some View {
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color(.secondarySystemBackground))
}

private func formattedLayoutDate(_ value: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    if let date = formatter.date(from: value) {
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    let fallbackFormatter = ISO8601DateFormatter()
    if let date = fallbackFormatter.date(from: value) {
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    return value
}

#Preview {
    SettingsInfoView(beaconManager: BeaconManager())
}
