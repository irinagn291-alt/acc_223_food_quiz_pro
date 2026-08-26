import Foundation

struct Product: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let brand: String?
    let imageURL: URL?
    let thumbnailURL: URL?
    let categories: String?
    let countries: String?
    let countryTags: [String]
    let barcode: String?
    let ingredients: String?
    let allergens: String?
    let nutrition: NutritionFacts?
    let nutriScore: String?
    let novaGroup: Int?

    var primaryCountry: String? {
        if let countries, !countries.isEmpty {
            let first = countries
                .components(separatedBy: ",")
                .first?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let first, !first.isEmpty {
                return Self.formatLabel(first)
            }
        }
        if let tag = countryTags.first(where: { !$0.isEmpty }) {
            return Self.formatLabel(tag)
        }
        return nil
    }

    var primaryBrand: String? {
        guard let brand = brand?.trimmingCharacters(in: .whitespacesAndNewlines), !brand.isEmpty else {
            return nil
        }
        return brand
            .components(separatedBy: ",")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(from response: ProductResponse) {
        self.id = response.code ?? UUID().uuidString
        self.name = response.product?.product_name ?? "Unknown"
        self.brand = response.product?.brands
        self.imageURL = URL(string: response.product?.image_url ?? "")
        self.thumbnailURL = URL(string: response.product?.image_small_url ?? "")
        self.categories = response.product?.categories
        self.countries = response.product?.countries
        self.countryTags = response.product?.countries_tags ?? []
        self.barcode = response.code
        self.ingredients = response.product?.ingredients_text
        self.allergens = response.product?.allergens
        self.nutriScore = response.product?.nutriscore_grade
        self.novaGroup = response.product?.nova_group
        self.nutrition = NutritionFacts(from: response.product?.nutriments)
    }

    init(from item: SearchProductItem) {
        self.id = item.code ?? UUID().uuidString
        self.name = item.product_name ?? "Unknown"
        self.brand = item.brands
        self.imageURL = URL(string: item.image_url ?? "")
        self.thumbnailURL = URL(string: item.image_small_url ?? "")
        self.categories = item.categories
        self.countries = item.countries
        self.countryTags = item.countries_tags ?? []
        self.barcode = item.code
        self.ingredients = item.ingredients_text
        self.allergens = item.allergens
        self.nutriScore = item.nutriscore_grade
        self.novaGroup = item.nova_group
        self.nutrition = NutritionFacts(from: item.nutriments)
    }

    private static func formatLabel(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let colon = value.lastIndex(of: ":") {
            value = String(value[value.index(after: colon)...])
        }
        value = value.replacingOccurrences(of: "-", with: " ")
        return value.capitalized
    }
}

struct NutritionFacts: Codable, Hashable {
    let calories: Double?
    let protein: Double?
    let fat: Double?
    let carbohydrates: Double?
    let sugar: Double?
    let fiber: Double?

    init?(from nutriments: Nutriments?) {
        guard let n = nutriments else { return nil }
        self.calories = n.energy_kcal_100g ?? n.energy_100g
        self.protein = n.proteins_100g
        self.fat = n.fat_100g
        self.carbohydrates = n.carbohydrates_100g
        self.sugar = n.sugars_100g
        self.fiber = n.fiber_100g
    }
}
