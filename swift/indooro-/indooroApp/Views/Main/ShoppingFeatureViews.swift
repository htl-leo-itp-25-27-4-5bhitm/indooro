import SwiftUI

struct ShoppingStopMarker: View {
    let index: Int
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.orange : Color.blue)
                .frame(width: isActive ? 26 : 22, height: isActive ? 26 : 22)
                .shadow(color: (isActive ? Color.orange : Color.blue).opacity(0.28), radius: 4, x: 0, y: 1)

            Text("\(index)")
                .font(.caption2.weight(.bold))
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

struct ShoppingSessionPanel: View {
    let snapshot: ShoppingRouteSnapshot
    let onOpenList: () -> Void
    let onMarkCurrentStopDone: () -> Void
    let onSkipCurrentStop: () -> Void
    let onToggleMode: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Einkaufstour")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(snapshot.listName)
                        .font(.headline)
                }

                Spacer()

                Button(snapshot.routeMode.title) {
                    onToggleMode()
                }
                .font(.caption2.weight(.semibold))
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            if let currentStop = snapshot.currentStop {
                Divider()

                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentStop.title)
                            .font(.subheadline.weight(.semibold))
                        Text(currentStop.itemNamesPreview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(snapshot.remainingStopCount) Stopps, \(snapshot.remainingProductCount) offen")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    Button {
                        onMarkCurrentStopDone()
                    } label: {
                        Text("Erledigt")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("Ueberspringen") {
                        onSkipCurrentStop()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        onOpenList()
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            } else {
                Text("Alle Stopps erledigt!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Liste oeffnen") {
                    onOpenList()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if snapshot.unresolvedProductCount > 0 {
                Label(
                    "\(snapshot.unresolvedProductCount) Artikel nicht im Layout",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption2)
                .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

private enum ShoppingShareMode {
    case copy
    case move
}

private struct ShoppingSharePresentation: Identifiable {
    let id = UUID()
    let fileURL: URL
    let sourceListID: UUID
    let movedItemIDs: Set<UUID>?
}

private struct ShoppingSelectionContext: Identifiable {
    let id = UUID()
    let listID: UUID
}

struct ShoppingListsSheet: View {
    @ObservedObject var listManager: ShoppingListManager
    @ObservedObject var sessionManager: ShoppingSessionManager
    @ObservedObject var beaconManager: BeaconManager
    @Binding var pendingImportPackage: ShoppingTransferPackage?
    @Binding var importErrorMessage: String?

    let onStartSession: (UUID) -> Void
    let onStopSession: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showCreateAlert = false
    @State private var newListName = ""
    @State private var renameTarget: ShoppingList?
    @State private var renameDraft = ""
    @State private var showFileImporter = false
    @State private var shareSelectionContext: ShoppingSelectionContext?
    @State private var sharePresentation: ShoppingSharePresentation?

    var body: some View {
        NavigationStack {
            List {
                Section("Importieren") {
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("Liste aus Datei importieren", systemImage: "square.and.arrow.down")
                    }

                    Text("Importierte Indooro-Dateien koennen als neue Liste angelegt oder in eine bestehende Liste zusammengefuehrt werden.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Listen") {
                    ForEach(listManager.lists) { list in
                        shoppingListRow(for: list)
                    }
                }

                if let selectedList = listManager.selectedList {
                    ShoppingListDetailContent(
                        selectedList: selectedList,
                        preview: sessionManager.previewSnapshot(
                            for: selectedList.id,
                            listManager: listManager,
                            beaconManager: beaconManager,
                            mode: selectedList.id == sessionManager.activeListID ? sessionManager.routeMode : .optimized
                        ),
                        listManager: listManager,
                        sessionManager: sessionManager,
                        beaconManager: beaconManager,
                        onStartSession: onStartSession,
                        onStopSession: onStopSession,
                        onExportList: { exportList(listID: selectedList.id) },
                        onShareItems: { shareSelectionContext = ShoppingSelectionContext(listID: selectedList.id) },
                        onToggleItemDone: { itemID in
                            toggleItem(itemID: itemID, in: selectedList.id)
                        },
                        onDeleteItem: { itemID in
                            listManager.removeItem(itemID, from: selectedList.id)
                        }
                    )
                }
            }
            .navigationTitle("Einkaufslisten")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newListName = ""
                        showCreateAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .alert("Neue Liste", isPresented: $showCreateAlert) {
            TextField("Name", text: $newListName)
            Button("Abbrechen", role: .cancel) {}
            Button("Erstellen") {
                listManager.createList(named: newListName)
            }
        } message: {
            Text("Lege eine weitere Einkaufsliste an.")
        }
        .alert("Liste umbenennen", isPresented: renameAlertBinding) {
            TextField("Name", text: $renameDraft)
            Button("Abbrechen", role: .cancel) {
                renameTarget = nil
            }
            Button("Speichern") {
                if let renameTarget {
                    listManager.renameList(renameTarget.id, to: renameDraft)
                }
                renameTarget = nil
            }
        } message: {
            Text("Passe den Namen der Liste an.")
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.indooroShoppingList]
        ) { result in
            handleFileImport(result)
        }
        .sheet(item: $pendingImportPackage) { package in
            ShoppingImportPreviewSheet(
                package: package,
                availableLists: listManager.lists,
                preferredMergeTargetID: listManager.selectedList?.id,
                onImportAsNewList: { listName in
                    importAsNewList(package, preferredName: listName)
                },
                onMergeIntoList: { targetListID in
                    mergeImport(package, into: targetListID)
                }
            )
        }
        .sheet(item: $shareSelectionContext) { context in
            if let list = listManager.list(with: context.listID) {
                ShoppingItemSelectionSheet(
                    list: list,
                    onShareCopy: { itemIDs in
                        startShare(for: context.listID, itemIDs: itemIDs, mode: .copy)
                    },
                    onShareMove: { itemIDs in
                        startShare(for: context.listID, itemIDs: itemIDs, mode: .move)
                    }
                )
            } else {
                ContentUnavailableView("Liste nicht gefunden", systemImage: "cart")
            }
        }
        .sheet(item: $sharePresentation) { presentation in
            ShareSheet(activityItems: [presentation.fileURL]) { completed in
                completeShare(presentation, completed: completed)
            }
        }
        .alert("Aktion fehlgeschlagen", isPresented: importErrorAlertBinding) {
            Button("OK", role: .cancel) {
                importErrorMessage = nil
            }
        } message: {
            Text(importErrorMessage ?? "Die Liste konnte nicht importiert werden.")
        }
    }

    private func shoppingListRow(for list: ShoppingList) -> some View {
        Button {
            listManager.selectList(list.id)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(list.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if sessionManager.activeListID == list.id {
                            Text("Aktiv")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15), in: Capsule())
                                .foregroundColor(.blue)
                        }
                    }

                    Text("\(list.openItemCount) Artikel offen, \(list.completedItemCount) abgeschlossen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: listManager.isSelectedList(list.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(listManager.isSelectedList(list.id) ? .blue : .secondary.opacity(0.6))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if listManager.lists.count > 1 {
                Button(role: .destructive) {
                    if sessionManager.activeListID == list.id {
                        onStopSession()
                    }
                    listManager.deleteList(list.id)
                } label: {
                    Label("Loeschen", systemImage: "trash")
                }
            }

            Button {
                renameTarget = list
                renameDraft = list.name
            } label: {
                Label("Umbenennen", systemImage: "pencil")
            }
            .tint(.orange)
        }
    }

    private func toggleItem(itemID: UUID, in listID: UUID) {
        guard let selectedList = listManager.list(with: listID),
              let item = selectedList.items.first(where: { $0.id == itemID }) else {
            return
        }

        let nextStatus: ShoppingListItemStatus = item.status == .done ? .open : .done
        listManager.updateItemStatus(itemID, in: listID, status: nextStatus)

        if sessionManager.activeListID == listID {
            sessionManager.sync(listManager: listManager, beaconManager: beaconManager)
        }
    }

    private func exportList(listID: UUID) {
        startShare(for: listID, itemIDs: nil, mode: .copy)
    }

    private func startShare(for listID: UUID, itemIDs: Set<UUID>?, mode: ShoppingShareMode) {
        do {
            let package = try listManager.makeTransferPackage(
                for: listID,
                itemIDs: itemIDs,
                kind: itemIDs == nil ? .fullList : .itemSelection
            )
            let fileURL = try ShoppingTransferService.writePackageToTemporaryFile(package)
            sharePresentation = ShoppingSharePresentation(
                fileURL: fileURL,
                sourceListID: listID,
                movedItemIDs: mode == .move ? itemIDs : nil
            )
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func completeShare(_ presentation: ShoppingSharePresentation, completed: Bool) {
        defer {
            try? FileManager.default.removeItem(at: presentation.fileURL)
            sharePresentation = nil
        }

        guard completed, let movedItemIDs = presentation.movedItemIDs else {
            return
        }

        listManager.removeItems(movedItemIDs, from: presentation.sourceListID)
        if sessionManager.activeListID == presentation.sourceListID {
            sessionManager.sync(listManager: listManager, beaconManager: beaconManager)
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                pendingImportPackage = try ShoppingTransferService.loadPackage(from: url)
                importErrorMessage = nil
            } catch {
                importErrorMessage = error.localizedDescription
            }
        case .failure(let error):
            importErrorMessage = error.localizedDescription
        }
    }

    private func importAsNewList(_ package: ShoppingTransferPackage, preferredName: String) {
        pendingImportPackage = nil
        _ = listManager.importPackageAsNewList(package, preferredName: preferredName)
    }

    private func mergeImport(_ package: ShoppingTransferPackage, into listID: UUID) {
        listManager.mergePackage(package, into: listID)
        if sessionManager.activeListID == listID {
            sessionManager.sync(listManager: listManager, beaconManager: beaconManager)
        }
        pendingImportPackage = nil
    }

    private var renameAlertBinding: Binding<Bool> {
        Binding(
            get: { renameTarget != nil },
            set: { isPresented in
                if !isPresented {
                    renameTarget = nil
                }
            }
        )
    }

    private var importErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { importErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    importErrorMessage = nil
                }
            }
        )
    }
}

private struct ShoppingListDetailContent: View {
    let selectedList: ShoppingList
    let preview: ShoppingRouteSnapshot?

    @ObservedObject var listManager: ShoppingListManager
    @ObservedObject var sessionManager: ShoppingSessionManager
    @ObservedObject var beaconManager: BeaconManager

    let onStartSession: (UUID) -> Void
    let onStopSession: () -> Void
    let onExportList: () -> Void
    let onShareItems: () -> Void
    let onToggleItemDone: (UUID) -> Void
    let onDeleteItem: (UUID) -> Void

    var body: some View {
        Section("Tour") {
            tourSectionContent
        }

        Section("Teilen & Export") {
            transferSectionContent
        }

        if let preview, !preview.orderedStops.isEmpty {
            Section("Offene Stopps") {
                ForEach(Array(preview.orderedStops.enumerated()), id: \.element.id) { index, stop in
                    ShoppingStopSectionView(
                        index: index + 1,
                        stop: stop,
                        isActiveStop: sessionManager.activeListID == selectedList.id && index == 0,
                        onToggleItemDone: onToggleItemDone,
                        onDeleteItem: onDeleteItem
                    )
                }
            }
        }

        if let preview, !preview.unresolvedItems.isEmpty {
            Section("Nicht im aktuellen Layout") {
                ForEach(preview.unresolvedItems) { item in
                    unresolvedItemRow(item)
                }
            }
        }

        if let preview, !preview.completedItems.isEmpty {
            Section("Erledigt / abgeschlossen") {
                ForEach(preview.completedItems) { item in
                    completedItemRow(item)
                }

                Button("Abgeschlossene Eintraege entfernen") {
                    listManager.clearCompletedItems(in: selectedList.id)
                }
                .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private var transferSectionContent: some View {
        Button {
            onExportList()
        } label: {
            Label("Liste exportieren", systemImage: "square.and.arrow.up")
        }

        Button {
            onShareItems()
        } label: {
            Label("Artikel teilen", systemImage: "person.2")
        }
        .disabled(selectedList.openItemCount == 0)

        Text("Export erstellt eine Indooro-Datei. Beim Teilen koennen einzelne offene Artikel an ein anderes Geraet gesendet werden.")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var tourSectionContent: some View {
        if sessionManager.activeListID == selectedList.id {
            Label("Diese Liste ist aktuell aktiv.", systemImage: "location.fill")
                .foregroundColor(.blue)
        } else {
            Text("Starte eine Einkaufstour, um die Stopps nacheinander abzufahren.")
                .foregroundColor(.secondary)
        }

        HStack {
            if sessionManager.activeListID == selectedList.id {
                Button("Tour beenden") {
                    onStopSession()
                }
                .buttonStyle(.bordered)
            } else {
                Button("Tour starten") {
                    onStartSession(selectedList.id)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedList.openItemCount == 0)
            }

            Spacer()

            Button("Neu optimieren") {
                if sessionManager.activeListID == selectedList.id {
                    onStartSession(selectedList.id)
                }
            }
            .buttonStyle(.bordered)
            .disabled(sessionManager.activeListID != selectedList.id)
        }

        if sessionManager.activeListID == selectedList.id {
            Button("Reihenfolge: \(sessionManager.routeMode.title)") {
                sessionManager.toggleRouteMode(
                    listManager: listManager,
                    beaconManager: beaconManager
                )
            }
            .buttonStyle(.bordered)
        }
    }

    private func unresolvedItemRow(_ item: ShoppingListItem) -> some View {
        ShoppingListItemRow(
            item: item,
            accentColor: .orange
        ) {
            Menu("Status") {
                Button("Als nicht gefunden markieren") {
                    listManager.updateItemStatus(item.id, in: selectedList.id, status: .missing)
                }
                Button("Ueberspringen") {
                    listManager.updateItemStatus(item.id, in: selectedList.id, status: .skipped)
                }
                Button("Loeschen", role: .destructive) {
                    listManager.removeItem(item.id, from: selectedList.id)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private func completedItemRow(_ item: ShoppingListItem) -> some View {
        ShoppingListItemRow(
            item: item,
            accentColor: .green
        ) {
            HStack(spacing: 8) {
                Button("Offen") {
                    listManager.updateItemStatus(item.id, in: selectedList.id, status: .open)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(role: .destructive) {
                    listManager.removeItem(item.id, from: selectedList.id)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}

private struct ShoppingStopSectionView: View {
    let index: Int
    let stop: ShoppingStop
    let isActiveStop: Bool
    let onToggleItemDone: (UUID) -> Void
    let onDeleteItem: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ShoppingStopMarker(index: index, isActive: isActiveStop)

                VStack(alignment: .leading, spacing: 3) {
                    Text(stop.title)
                        .font(.headline)
                    Text("\(stop.totalQuantity) Artikel")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isActiveStop {
                    Text("Naechster")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.16), in: Capsule())
                        .foregroundColor(.orange)
                }
            }

            ForEach(stop.items) { item in
                ShoppingListItemRow(
                    item: item,
                    accentColor: isActiveStop ? .orange : .blue,
                    trailingContent: {
                        HStack(spacing: 8) {
                            Button(item.status == .done ? "Offen" : "Erledigt") {
                                onToggleItemDone(item.id)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button(role: .destructive) {
                                onDeleteItem(item.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                )
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ShoppingListItemRow<TrailingContent: View>: View {
    let item: ShoppingListItem
    let accentColor: Color
    let trailingContent: () -> TrailingContent

    init(
        item: ShoppingListItem,
        accentColor: Color,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent
    ) {
        self.item = item
        self.accentColor = accentColor
        self.trailingContent = trailingContent
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(accentColor.opacity(0.18))
                .frame(width: 8)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                    if item.quantity > 1 {
                        Text("x\(item.quantity)")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12), in: Capsule())
                    }
                }

                Text("Regal: \(item.layoutCode)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(item.status.badgeTitle)
                    .font(.caption2)
                    .foregroundColor(accentColor)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Text("\(String(format: "%.2f", item.price)) EUR")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                trailingContent()
            }
        }
        .padding(.vertical, 4)
    }
}
