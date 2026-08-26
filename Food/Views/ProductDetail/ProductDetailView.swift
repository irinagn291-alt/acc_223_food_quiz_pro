import SwiftUI

struct ProductDetailView: View {
    let product: Product

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CachedAsyncImage(url: product.imageURL)
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)

                VStack(alignment: .leading, spacing: 8) {
                    Text(product.name)
                        .font(.title2.weight(.bold))

                    if let brand = product.brand {
                        Label(brand, systemImage: "tag")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let category = product.categories {
                        Label(category, systemImage: "folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let countries = product.countries {
                        Label(countries, systemImage: "globe")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let barcode = product.barcode {
                        Label(barcode, systemImage: "barcode")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                badgesSection

                if let nutrition = product.nutrition {
                    nutritionSection(nutrition)
                }

                if let ingredients = product.ingredients, !ingredients.isEmpty {
                    section("Ingredients") {
                        Text(ingredients)
                            .font(.subheadline)
                    }
                }

                if let allergens = product.allergens, !allergens.isEmpty {
                    section("Allergens") {
                        Text(allergens)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var badgesSection: some View {
        HStack(spacing: 16) {
            if let score = product.nutriScore {
                VStack(spacing: 4) {
                    Text("Nutri-Score")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(score.uppercased())
                        .font(.title.weight(.bold))
                        .foregroundStyle(nutriScoreColor(score))
                        .padding(8)
                        .background(nutriScoreColor(score).opacity(0.1), in: Circle())
                }
            }
            if let nova = product.novaGroup {
                VStack(spacing: 4) {
                    Text("NOVA")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(nova)")
                        .font(.title.weight(.bold))
                        .foregroundStyle(novaColor(nova))
                        .padding(8)
                        .background(novaColor(nova).opacity(0.1), in: Circle())
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private func nutritionSection(_ n: NutritionFacts) -> some View {
        section("Nutrition per 100g") {
            VStack(spacing: 0) {
                if let v = n.calories { nutritionRow("Calories", "\(Int(v)) kcal") }
                if let v = n.protein { nutritionRow("Protein", String(format: "%.1f g", v)) }
                if let v = n.fat { nutritionRow("Fat", String(format: "%.1f g", v)) }
                if let v = n.carbohydrates { nutritionRow("Carbohydrates", String(format: "%.1f g", v)) }
                if let v = n.sugar { nutritionRow("Sugar", String(format: "%.1f g", v)) }
                if let v = n.fiber { nutritionRow("Fiber", String(format: "%.1f g", v)) }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func nutritionRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(.horizontal)
    }

    private func nutriScoreColor(_ score: String) -> Color {
        switch score.lowercased() {
        case "a": return .green
        case "b": return .mint
        case "c": return .yellow
        case "d": return .orange
        case "e": return .red
        default: return .gray
        }
    }

    private func novaColor(_ group: Int) -> Color {
        switch group {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }
}
