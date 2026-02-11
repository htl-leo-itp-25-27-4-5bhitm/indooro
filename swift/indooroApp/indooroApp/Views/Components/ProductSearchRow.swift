import SwiftUI

struct ProductSearchRow: View {
    let product: Product
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Regal: \(product.layoutCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(String(format: "%.2f", product.price))€")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
