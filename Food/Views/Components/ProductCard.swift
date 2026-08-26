import SwiftUI

struct ProductCard: View {
    let product: Product
    var showNutrition: Bool = false
    var highlight: CardHighlight = .none
    var highlightedNutrient: NutrientType?

    enum CardHighlight {
        case none, correct, wrong
    }

    var body: some View {
        VStack(spacing: 8) {
            CachedAsyncImage(url: product.imageURL, thumbnailURL: product.thumbnailURL)
                .frame(height: 120)

            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let brand = product.brand {
                Text(brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if showNutrition, let n = product.nutrition {
                nutritionGrid(n)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(highlightColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(highlightColor.opacity(highlight == .none ? 0.2 : 1), lineWidth: highlight == .none ? 1 : 3)
                )
        }
    }

    private var highlightColor: Color {
        switch highlight {
        case .none: return .primary
        case .correct: return .green
        case .wrong: return .red
        }
    }

    @ViewBuilder
    private func nutritionGrid(_ n: NutritionFacts) -> some View {
        let rows: [(NutrientType, String, String)] = [
            (.calories, "Calories", "\(Int(n.calories ?? 0)) kcal"),
            (.protein, "Protein", String(format: "%.1fg", n.protein ?? 0)),
            (.fat, "Fat", String(format: "%.1fg", n.fat ?? 0)),
            (.carbohydrates, "Carbs", String(format: "%.1fg", n.carbohydrates ?? 0)),
            (.sugar, "Sugar", String(format: "%.1fg", n.sugar ?? 0)),
            (.fiber, "Fiber", String(format: "%.1fg", n.fiber ?? 0)),
        ]

        let sorted: [(NutrientType, String, String)] = {
            guard let hn = highlightedNutrient else { return rows }
            var result = rows
            if let idx = result.firstIndex(where: { $0.0 == hn }) {
                let item = result.remove(at: idx)
                result.insert(item, at: 0)
            }
            return result
        }()

        VStack(spacing: 4) {
            ForEach(sorted, id: \.0) { type, label, value in
                let isHighlighted = type == highlightedNutrient
                nutrientRow(label, value, bold: isHighlighted)
            }
        }
        .font(.caption2)
    }

    private func nutrientRow(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(bold ? .primary : .secondary)
                .fontWeight(bold ? .bold : .regular)
            Spacer()
            Text(value)
                .fontWeight(bold ? .bold : .medium)
        }
        .font(bold ? .caption : .caption2)
    }
}
