import SwiftUI

struct ProductListView: View {
    @ObservedObject var beaconManager: BeaconManager
    let categoryCode: String
    let onSelect: (Product) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        Group {
            if visibleProducts.isEmpty {
                emptyState
            } else {
                productsList
            }
        }
        .navigationTitle(categoryTitle)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Produkte filtern")
    }

    private var productsList: some View {
        List(visibleProducts) { product in
            ProductRow(product: product) {
                onSelect(product)
                dismiss()
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Keine Produkte",
            systemImage: "shippingbox",
            description: Text("Für diese Suche sind keine Produkte vorhanden.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var categoryProducts: [Product] {
        beaconManager.allProducts
            .filter { $0.categoryCode == categoryCode }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private var visibleProducts: [Product] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return categoryProducts }
        return categoryProducts.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed) || $0.layoutCode.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var categoryTitle: String {
        categoryProducts.first?.categoryName ?? "Kategorie \(categoryCode)"
    }
}

private struct ProductRow: View {
    let product: Product
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                icon
                details
                Spacer()
                trailing
            }
            .padding(12)
            .background(rowBackground)
            .overlay(rowBorder)
        }
        .buttonStyle(.plain)
    }

    private var icon: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.accentColor.opacity(0.14))
            .frame(width: 52, height: 52)
            .overlay(
                Image(systemName: product.categorySymbol)
                    .font(.title3)
                    .foregroundColor(.accentColor)
            )
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)

            Label(product.layoutCode, systemImage: "shippingbox")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var trailing: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(priceText)
                .font(.headline)
                .foregroundColor(.primary)

            Image(systemName: "location.fill")
                .font(.caption.bold())
                .foregroundColor(.accentColor)
        }
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
    }

    private var priceText: String {
        String(format: "%.2f €", product.price)
    }
}

#Preview {
    NavigationStack {
        ProductListView(beaconManager: BeaconManager(), categoryCode: "310") { _ in }
    }
}
