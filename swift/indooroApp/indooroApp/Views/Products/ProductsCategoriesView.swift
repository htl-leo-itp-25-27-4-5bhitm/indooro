import SwiftUI

struct ProductsCategoriesView: View {
    @ObservedObject var beaconManager: BeaconManager
    let onSelectProduct: (Product) -> Void

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Produkte")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing, content: toolbarTrailing)
                }
        }
        .onAppear {
            beaconManager.loadAllProducts()
        }
    }

    @ViewBuilder
    private var content: some View {
        if beaconManager.isLoadingProducts, beaconManager.allProducts.isEmpty {
            loadingView
        } else if let error = beaconManager.productLoadingError, beaconManager.allProducts.isEmpty {
            errorView(error)
        } else {
            categoriesList
        }
    }

    private var loadingView: some View {
        ProgressView("Kategorien werden geladen …")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
    }

    private func errorView(_ error: String) -> some View {
        ContentUnavailableView(
            "Kategorien konnten nicht geladen werden",
            systemImage: "wifi.exclamationmark",
            description: Text(error)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var categoriesList: some View {
        List(categorySections) { section in
            NavigationLink {
                ProductListView(
                    beaconManager: beaconManager,
                    categoryCode: section.code,
                    onSelect: onSelectProduct
                )
            } label: {
                CategoryRow(section: section)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private func toolbarTrailing() -> some View {
        if beaconManager.isLoadingProducts {
            ProgressView()
                .controlSize(.small)
        } else {
            Button {
                beaconManager.loadAllProducts(forceReload: true)
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
    }

    private var categorySections: [ProductCategorySection] {
        let grouped = Dictionary(grouping: beaconManager.allProducts, by: \.categoryCode)
        let sortedCodes = grouped.keys.sorted { lhs, rhs in
            let leftValue = Int(lhs) ?? Int.max
            let rightValue = Int(rhs) ?? Int.max
            return leftValue < rightValue
        }

        return sortedCodes.map { code in
            let products = grouped[code] ?? []
            return ProductCategorySection(
                code: code,
                name: products.first?.categoryName ?? "Kategorie \(code)",
                symbol: products.first?.categorySymbol ?? "shippingbox",
                count: products.count
            )
        }
    }
}

private struct ProductCategorySection: Identifiable {
    let code: String
    let name: String
    let symbol: String
    let count: Int

    var id: String { code }
}

private struct CategoryRow: View {
    let section: ProductCategorySection

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.accentColor.opacity(0.14))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: section.symbol)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(section.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Kategorie \(section.code)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(section.count)")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Produkte")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    ProductsCategoriesView(beaconManager: BeaconManager()) { _ in }
}
