import SwiftUI

struct ProductSearchRow: View {
    let product: Product
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: product.categorySymbol)
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(product.categoryName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Label(product.layoutCode, systemImage: "shippingbox")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(priceText)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            }
        }
        .buttonStyle(.plain)
    }
    
    private var priceText: String {
        String(format: "%.2f €", product.price)
    }
}
