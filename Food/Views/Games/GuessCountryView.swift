import SwiftUI

struct GuessCountryView: View {
    @State private var vm = GameViewModel()
    @State private var choices: [String] = []
    @State private var correctAnswer = ""
    @State private var selectedAnswer: String?

    private let decoyCountries = ["Germany", "France", "United States", "United Kingdom", "Italy", "Spain", "Japan", "Brazil", "Canada", "Australia", "Mexico", "India", "China", "Netherlands", "Belgium", "Switzerland", "Sweden", "Poland", "Portugal", "Austria"]

    var body: some View {
        VStack(spacing: 20) {
            if vm.isLoading {
                Spacer()
                ProgressView("Loading product...")
                Spacer()
            } else if let error = vm.errorMessage {
                errorView(error)
            } else if let product = vm.products.first, !choices.isEmpty {
                questionContent(product)
            } else {
                Spacer()
                ProgressView("Loading product...")
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Guess the Country")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.saveRecentMode(.guessCountry)
            await loadQuestion()
        }
    }

    private func questionContent(_ product: Product) -> some View {
        VStack(spacing: 16) {
            CachedAsyncImage(url: product.imageURL, thumbnailURL: product.thumbnailURL)
                .frame(height: 160)

            Text(product.name)
                .font(.headline)

            Text("Which country is this product from?")
                .font(.title3)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(choices, id: \.self) { choice in
                    Button {
                        guard selectedAnswer == nil else { return }
                        select(choice)
                    } label: {
                        HStack {
                            Text(choice)
                                .font(.body.weight(.medium))
                            Spacer()
                            if selectedAnswer != nil {
                                if choice == correctAnswer {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else if choice == selectedAnswer {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding()
                        .background(choiceBackground(choice), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            if selectedAnswer != nil {
                Button {
                    Task { await loadQuestion() }
                } label: {
                    Text("Next Question")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()
        }
    }

    private func choiceBackground(_ choice: String) -> some ShapeStyle {
        guard let selected = selectedAnswer else {
            return AnyShapeStyle(.ultraThinMaterial)
        }
        if choice == correctAnswer {
            return AnyShapeStyle(Color.green.opacity(0.2))
        }
        if choice == selected && choice != correctAnswer {
            return AnyShapeStyle(Color.red.opacity(0.2))
        }
        return AnyShapeStyle(.ultraThinMaterial)
    }

    private func select(_ choice: String) {
        selectedAnswer = choice
        if choice == correctAnswer {
            HapticService.success()
        } else {
            HapticService.error()
        }
    }

    private func loadQuestion() async {
        selectedAnswer = nil
        choices = []
        vm.errorMessage = nil

        for _ in 0..<5 {
            await vm.loadProducts(count: 1, requireNutrition: false, requireCountries: true)
            guard vm.errorMessage == nil,
                  let product = vm.products.first,
                  let country = product.primaryCountry else {
                continue
            }

            correctAnswer = country
            var options = Set([country])
            while options.count < 4 {
                if let decoy = decoyCountries.randomElement(), decoy != country {
                    options.insert(decoy)
                }
            }
            choices = Array(options).shuffled()
            return
        }

        vm.errorMessage = "Could not find a product with country info"
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
            Button("Retry") { Task { await loadQuestion() } }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
}
