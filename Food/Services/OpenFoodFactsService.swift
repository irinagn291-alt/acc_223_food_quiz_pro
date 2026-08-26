import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .decodingError: return "Failed to parse data"
        case .networkError(let error): return error.localizedDescription
        case .productNotFound: return "Product not found"
        }
    }
}

actor OpenFoodFactsService {
    nonisolated static let shared = OpenFoodFactsService()
    private let baseURL = "https://world.openfoodfacts.org"
    private let session: URLSession
    private let fields = "code,product_name,brands,image_url,image_small_url,categories,countries,countries_tags,ingredients_text,allergens,nutriscore_grade,nova_group,nutriments"
    private let categories = ["snacks", "beverages", "cereals", "dairy", "chocolates", "biscuits", "chips", "candy", "juice", "yogurt", "cheese", "pasta", "bread", "cookies", "ice-cream", "pizza", "sauces", "soups", "fruits", "vegetables"]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.httpMaximumConnectionsPerHost = 4
        self.session = URLSession(configuration: config)
    }

    func fetchProduct(barcode: String) async throws -> Product {
        guard let normalized = BarcodeNormalizer.normalize(barcode) else {
            throw APIError.productNotFound
        }
        let url = URL(string: "\(baseURL)/api/v2/product/\(normalized).json")!
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(ProductResponse.self, from: data)
        guard response.status == 1 else { throw APIError.productNotFound }
        return Product(from: response)
    }

    func search(query: String, page: Int = 1) async throws -> [Product] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/cgi/search.pl?search_terms=\(encoded)&page=\(page)&page_size=24&json=1&fields=\(fields)") else {
            throw APIError.invalidURL
        }
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        return response.products?.map { Product(from: $0) } ?? []
    }

    func fetchRandomProducts(
        count: Int,
        requireNutrition: Bool = true,
        requireCountries: Bool = false,
        requireBrand: Bool = false,
        maxRetries: Int = 3
    ) async throws -> [Product] {
        for attempt in 0..<maxRetries {
            let products = try await fetchRandomBatch(
                count: count,
                requireNutrition: requireNutrition,
                requireCountries: requireCountries,
                requireBrand: requireBrand
            )
            if products.count >= count {
                return Array(products.prefix(count))
            }
            if attempt < maxRetries - 1 {
                try await Task.sleep(for: .milliseconds(500))
            }
        }
        throw APIError.noData
    }

    private func fetchRandomBatch(
        count: Int,
        requireNutrition: Bool,
        requireCountries: Bool,
        requireBrand: Bool
    ) async throws -> [Product] {
        let shuffled = categories.shuffled()
        let batchCount = min(count + 3, shuffled.count)
        let batchCategories = Array(shuffled.prefix(batchCount))

        let allCandidates: [Product] = await withTaskGroup(of: [Product].self) { group in
            for category in batchCategories {
                group.addTask {
                    await self.fetchCategoryBatch(
                        category: category,
                        requireNutrition: requireNutrition,
                        requireCountries: requireCountries,
                        requireBrand: requireBrand
                    )
                }
            }
            var results: [Product] = []
            for await batch in group {
                results.append(contentsOf: batch)
            }
            return results
        }

        var seen = Set<String>()
        return allCandidates.filter { seen.insert($0.id).inserted }.shuffled()
    }

    private func fetchCategoryBatch(
        category: String,
        requireNutrition: Bool,
        requireCountries: Bool,
        requireBrand: Bool
    ) async -> [Product] {
        let page = Int.random(in: 1...3)
        guard let url = URL(string: "\(baseURL)/cgi/search.pl?action=process&tagtype_0=categories&tag_contains_0=contains&tag_0=\(category)&page=\(page)&page_size=50&json=1&fields=\(fields)") else { return [] }

        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(SearchResponse.self, from: data)
            return (response.products ?? [])
                .map { Product(from: $0) }
                .filter { product in
                    guard product.name != "Unknown" else { return false }
                    if requireNutrition, product.nutrition?.calories == nil { return false }
                    if requireCountries, product.primaryCountry == nil { return false }
                    if requireBrand, product.primaryBrand == nil { return false }
                    return true
                }
        } catch {
            return []
        }
    }
}
