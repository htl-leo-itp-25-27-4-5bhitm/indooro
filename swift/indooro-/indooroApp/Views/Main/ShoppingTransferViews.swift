import SwiftUI

struct ShoppingImportPreviewSheet: View {
    let package: ShoppingTransferPackage
    let availableLists: [ShoppingList]
    let preferredMergeTargetID: UUID?
    let onImportAsNewList: (String) -> Void
    let onMergeIntoList: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var mergeTargetID: UUID?
    @State private var importedListName = ""

    private var sortedItems: [ShoppingTransferItem] {
        package.items.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Datei") {
                    infoRow(title: "Typ", value: package.kind.title)
                    infoRow(title: "Listenname", value: package.sourceListName)
                    infoRow(title: "Artikel", value: "\(package.totalQuantity)")
                    infoRow(title: "Exportiert", value: package.exportedAt.formatted(date: .abbreviated, time: .shortened))

                    if let sender = package.senderDisplayName, !sender.isEmpty {
                        infoRow(title: "Absender", value: sender)
                    }

                    if let note = package.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notiz")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(note)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Importieren") {
                    TextField("Name der neuen Liste", text: $importedListName)
                        .textInputAutocapitalization(.words)

                    Button("Neue Liste erstellen und importieren") {
                        onImportAsNewList(normalizedImportedListName)
                    }
                    .buttonStyle(.borderedProminent)

                    if !availableLists.isEmpty {
                        Picker("In Liste zusammenfuehren", selection: mergeTargetBinding) {
                            ForEach(availableLists) { list in
                                Text(list.name).tag(Optional(list.id))
                            }
                        }

                        Button("In gewaehlte Liste zusammenfuehren") {
                            guard let mergeTargetID else { return }
                            onMergeIntoList(mergeTargetID)
                        }
                        .disabled(mergeTargetID == nil)
                    }
                }

                Section("Vorschau") {
                    ForEach(sortedItems.indices, id: \.self) { index in
                        let item = sortedItems[index]
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(item.name)
                                    .font(.subheadline.weight(.semibold))
                                if item.quantity > 1 {
                                    Text("x\(item.quantity)")
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.12), in: Capsule())
                                }
                                Spacer()
                                Text(item.status.badgeTitle)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(item.status == .open ? .blue : .secondary)
                            }

                            Text("Regal: \(item.layoutCode)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Liste importieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if mergeTargetID == nil {
                mergeTargetID = preferredMergeTargetID ?? availableLists.first?.id
            }
            if importedListName.isEmpty {
                importedListName = package.suggestedImportedListName
            }
        }
    }

    private var normalizedImportedListName: String {
        let trimmed = importedListName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? package.suggestedImportedListName : trimmed
    }

    private var mergeTargetBinding: Binding<UUID?> {
        Binding(
            get: { mergeTargetID },
            set: { mergeTargetID = $0 }
        )
    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ShoppingItemSelectionSheet: View {
    let list: ShoppingList
    let onShareCopy: (Set<UUID>) -> Void
    let onShareMove: (Set<UUID>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedItemIDs: Set<UUID> = []

    private var openItems: [ShoppingListItem] {
        list.items
            .filter { $0.status == .open }
            .sorted { lhs, rhs in
                if lhs.addedAt == rhs.addedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.addedAt < rhs.addedAt
            }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("\(selectedItemIDs.count) von \(openItems.count) Positionen ausgewaehlt")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Alle") {
                            selectedItemIDs = Set(openItems.map(\.id))
                        }
                        .font(.caption.weight(.semibold))

                        Button("Keine") {
                            selectedItemIDs.removeAll()
                        }
                        .font(.caption.weight(.semibold))
                    }
                }

                Section("Offene Artikel") {
                    ForEach(openItems) { item in
                        Button {
                            toggle(item.id)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedItemIDs.contains(item.id) ? .blue : .secondary)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(item.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        if item.quantity > 1 {
                                            Text("x\(item.quantity)")
                                                .font(.caption2.weight(.bold))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color.secondary.opacity(0.12), in: Capsule())
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Text("Regal: \(item.layoutCode)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Artikel teilen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button("Kopie teilen") {
                        let selectedIDs = selectedItemIDs
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onShareCopy(selectedIDs)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedItemIDs.isEmpty)

                    Button("Aus Liste senden") {
                        let selectedIDs = selectedItemIDs
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onShareMove(selectedIDs)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedItemIDs.isEmpty)
                }
                .padding()
                .background(.regularMaterial)
            }
        }
    }

    private func toggle(_ itemID: UUID) {
        if selectedItemIDs.contains(itemID) {
            selectedItemIDs.remove(itemID)
        } else {
            selectedItemIDs.insert(itemID)
        }
    }
}
