import SwiftUI

struct ProductSearchRow: View {
    let product: Product
    let isInShoppingList: Bool
    let onNavigate: () -> Void
    let onAddToList: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(product.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if isInShoppingList {
                            Text("In Liste")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15), in: Capsule())
                                .foregroundColor(.green)
                        }
                    }

                    Text("Regal: \(product.layoutCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(String(format: "%.2f", product.price)) EUR")
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            HStack {
                Button("Route") {
                    onNavigate()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button(isInShoppingList ? "Noch eins" : "Zur Liste") {
                    onAddToList()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
