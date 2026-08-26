import SwiftUI

struct GamesView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(GameMode.allCases) { mode in
                    NavigationLink(destination: gameDestination(for: mode)) {
                        HStack(spacing: 16) {
                            Image(systemName: mode.icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(modeColor(mode).opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(modeColor(mode))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.rawValue)
                                    .font(.headline)
                                Text(modeDescription(mode))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Games")
        }
    }

    @ViewBuilder
    private func gameDestination(for mode: GameMode) -> some View {
        switch mode {
        case .whichHasMore: WhichHasMoreView()
        case .guessCountry: GuessCountryView()
        case .guessBrand: GuessBrandView()
        case .guessCalories: GuessCaloriesView()
        case .orderByCalories: OrderByCaloriesView()
        }
    }

    private func modeColor(_ mode: GameMode) -> Color {
        switch mode {
        case .whichHasMore: return .blue
        case .guessCountry: return .green
        case .guessBrand: return .orange
        case .guessCalories: return .red
        case .orderByCalories: return .purple
        }
    }

    private func modeDescription(_ mode: GameMode) -> String {
        switch mode {
        case .whichHasMore: return "Compare nutrients between products"
        case .guessCountry: return "Identify the product's origin country"
        case .guessBrand: return "Name the brand from the image"
        case .guessCalories: return "Estimate calories per 100g"
        case .orderByCalories: return "Sort products by calorie count"
        }
    }
}
