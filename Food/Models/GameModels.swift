import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case whichHasMore = "Which Has More?"
    case guessCountry = "Guess the Country"
    case guessBrand = "Guess the Brand"
    case guessCalories = "Guess Calories"
    case orderByCalories = "Order by Calories"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .whichHasMore: return "scalemass"
        case .guessCountry: return "globe"
        case .guessBrand: return "tag"
        case .guessCalories: return "flame"
        case .orderByCalories: return "arrow.up.arrow.down"
        }
    }

    var color: String {
        switch self {
        case .whichHasMore: return "blue"
        case .guessCountry: return "green"
        case .guessBrand: return "orange"
        case .guessCalories: return "red"
        case .orderByCalories: return "purple"
        }
    }
}

enum NutrientType: String, CaseIterable {
    case protein = "Protein"
    case calories = "Calories"
    case fat = "Fat"
    case carbohydrates = "Carbohydrates"
    case sugar = "Sugar"
    case fiber = "Fiber"

    var unit: String {
        switch self {
        case .calories: return "kcal"
        default: return "g"
        }
    }

    func value(from nutrition: NutritionFacts) -> Double? {
        switch self {
        case .protein: return nutrition.protein
        case .calories: return nutrition.calories
        case .fat: return nutrition.fat
        case .carbohydrates: return nutrition.carbohydrates
        case .sugar: return nutrition.sugar
        case .fiber: return nutrition.fiber
        }
    }
}
