import Foundation

nonisolated struct ProductResponse: Codable {
    let code: String?
    let product: ProductData?
    let status: Int?
}

nonisolated struct ProductData: Codable {
    let product_name: String?
    let brands: String?
    let image_url: String?
    let image_small_url: String?
    let categories: String?
    let countries: String?
    let countries_tags: [String]?
    let ingredients_text: String?
    let allergens: String?
    let nutriscore_grade: String?
    let nova_group: Int?
    let nutriments: Nutriments?
}

nonisolated struct Nutriments: Codable {
    let energy_kcal_100g: Double?
    let energy_100g: Double?
    let proteins_100g: Double?
    let fat_100g: Double?
    let carbohydrates_100g: Double?
    let sugars_100g: Double?
    let fiber_100g: Double?

    enum CodingKeys: String, CodingKey {
        case energy_kcal_100g = "energy-kcal_100g"
        case energy_100g = "energy_100g"
        case proteins_100g = "proteins_100g"
        case fat_100g = "fat_100g"
        case carbohydrates_100g = "carbohydrates_100g"
        case sugars_100g = "sugars_100g"
        case fiber_100g = "fiber_100g"
    }
}

nonisolated struct SearchResponse: Codable {
    let count: Int?
    let page: Int?
    let page_size: Int?
    let products: [SearchProductItem]?
}

nonisolated struct SearchProductItem: Codable {
    let code: String?
    let product_name: String?
    let brands: String?
    let image_url: String?
    let image_small_url: String?
    let categories: String?
    let countries: String?
    let countries_tags: [String]?
    let ingredients_text: String?
    let allergens: String?
    let nutriscore_grade: String?
    let nova_group: Int?
    let nutriments: Nutriments?
}
