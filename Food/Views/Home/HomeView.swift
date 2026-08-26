import SwiftUI

struct HomeView: View {
    @AppStorage("recentGameModes") private var recentModesData: Data = Data()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    VStack(spacing: 12) {
                        NavigationLink(destination: GamesView()) {
                            HomeButton(title: "Play Game", icon: "gamecontroller.fill", color: .blue)
                        }
                        NavigationLink(destination: ScannerView()) {
                            HomeButton(title: "Scan Barcode", icon: "barcode.viewfinder", color: .orange)
                        }
                        NavigationLink(destination: SearchView()) {
                            HomeButton(title: "Search Products", icon: "magnifyingglass", color: .green)
                        }
                    }
                    .padding(.horizontal)

                    if !recentModes.isEmpty {
                        recentSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Food Quiz")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Test your food knowledge!")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.top)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.title3.weight(.semibold))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentModes) { mode in
                        NavigationLink(destination: gameDestination(for: mode)) {
                            VStack(spacing: 8) {
                                Image(systemName: mode.icon)
                                    .font(.title2)
                                Text(mode.rawValue)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 100, height: 80)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var recentModes: [GameMode] {
        guard let decoded = try? JSONDecoder().decode([String].self, from: recentModesData) else { return [] }
        return decoded.compactMap { GameMode(rawValue: $0) }
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
}

struct HomeButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15), in: Circle())
                .foregroundStyle(color)

            Text(title)
                .font(.headline)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
