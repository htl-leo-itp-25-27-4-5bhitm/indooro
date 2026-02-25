import SwiftUI

struct SettingsInfoView: View {
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("show_live_position") private var showLivePosition = true

    var body: some View {
        NavigationStack {
            List {
                appOverviewSection
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

#Preview {
    SettingsInfoView()
}
