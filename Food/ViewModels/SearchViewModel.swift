import SwiftUI
import Observation

@Observable
class SearchViewModel {
    var query = ""
    var results: [Product] = []
    var isLoading = false
    var errorMessage: String?
    var hasSearched = false

    private let service = OpenFoodFactsService.shared
    private var searchTask: Task<Void, Never>?

    func search() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        searchTask?.cancel()
        searchTask = Task {
            isLoading = true
            errorMessage = nil
            hasSearched = true
            do {
                if trimmed.allSatisfy(\.isNumber) && trimmed.count >= 8 {
                    let product = try await service.fetchProduct(barcode: trimmed)
                    results = [product]
                } else {
                    results = try await service.search(query: trimmed)
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
            isLoading = false
        }
    }
}
