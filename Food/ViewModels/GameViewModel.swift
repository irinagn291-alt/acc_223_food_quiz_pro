import SwiftUI
import Observation

@Observable
class GameViewModel {
    var products: [Product] = []
    var isLoading = false
    var errorMessage: String?
    var answered = false
    var selectedIndex: Int?

    private let service = OpenFoodFactsService.shared

    func loadProducts(
        count: Int,
        requireNutrition: Bool = true,
        requireCountries: Bool = false,
        requireBrand: Bool = false
    ) async {
        isLoading = true
        errorMessage = nil
        do {
            products = try await service.fetchRandomProducts(
                count: count,
                requireNutrition: requireNutrition,
                requireCountries: requireCountries,
                requireBrand: requireBrand,
                maxRetries: 3
            )
            answered = false
            selectedIndex = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func nextQuestion(count: Int) async {
        answered = false
        selectedIndex = nil
        await loadProducts(count: count)
    }

    func saveRecentMode(_ mode: GameMode) {
        var recent: [String] = (try? JSONDecoder().decode([String].self, from: UserDefaults.standard.data(forKey: "recentGameModes") ?? Data())) ?? []
        recent.removeAll { $0 == mode.rawValue }
        recent.insert(mode.rawValue, at: 0)
        if recent.count > 5 { recent = Array(recent.prefix(5)) }
        if let data = try? JSONEncoder().encode(recent) {
            UserDefaults.standard.set(data, forKey: "recentGameModes")
        }
    }
}
