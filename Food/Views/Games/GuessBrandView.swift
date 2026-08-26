import SwiftUI

struct GuessBrandView: View {
    @State private var vm = GameViewModel()
    @State private var choices: [String] = []
    @State private var correctAnswer = ""
    @State private var selectedAnswer: String?

    private let decoyBrands = ["Nestlé", "Coca-Cola", "PepsiCo", "Unilever", "Danone", "Mars", "Mondelez", "Kellogg's", "Heinz", "Barilla", "Dr. Oetker", "Haribo", "Lindt", "Ferrero", "Milka", "Knorr", "Maggi", "Pringles", "Lay's", "Oreo"]

    var body: some View {
        VStack(spacing: 20) {
            if vm.isLoading {
                Spacer()
                ProgressView("Loading product...")
                Spacer()
            } else if let error = vm.errorMessage {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(.orange)
                    Text(error)
                    Button("Retry") { Task { await loadQuestion() } }.buttonStyle(.borderedProminent)
                    Spacer()
                }
            } else if let product = vm.products.first, !choices.isEmpty {
                CachedAsyncImage(url: product.imageURL, thumbnailURL: product.thumbnailURL)
                    .frame(height: 180)

                Text("Which brand is this?")
                    .font(.title3)

                VStack(spacing: 10) {
                    ForEach(choices, id: \.self) { choice in
                        Button {
                            guard selectedAnswer == nil else { return }
                            selectedAnswer = choice
                            if choice == correctAnswer { HapticService.success() }
                            else { HapticService.error() }
                        } label: {
                            HStack {
                                Text(choice).font(.body.weight(.medium))
                                Spacer()
                                if selectedAnswer != nil {
                                    if choice == correctAnswer {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                    } else if choice == selectedAnswer {
                                        Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                                    }
                                }
                            }
                            .padding()
                            .background(brandBackground(choice), in: RoundedRectangle(cornerRadius: 12))
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
                }

                Spacer()
            } else {
                Spacer()
                ProgressView("Loading product...")
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Guess the Brand")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.saveRecentMode(.guessBrand)
            await loadQuestion()
        }
    }

    private func brandBackground(_ choice: String) -> some ShapeStyle {
        guard let selected = selectedAnswer else { return AnyShapeStyle(.ultraThinMaterial) }
        if choice == correctAnswer { return AnyShapeStyle(Color.green.opacity(0.2)) }
        if choice == selected { return AnyShapeStyle(Color.red.opacity(0.2)) }
        return AnyShapeStyle(.ultraThinMaterial)
    }

    private func loadQuestion() async {
        selectedAnswer = nil
        choices = []
        vm.errorMessage = nil

        for _ in 0..<5 {
            await vm.loadProducts(count: 1, requireNutrition: false, requireBrand: true)
            guard vm.errorMessage == nil,
                  let product = vm.products.first,
                  let brand = product.primaryBrand else {
                continue
            }

            correctAnswer = brand
            var options = Set([brand])
            while options.count < 4 {
                if let decoy = decoyBrands.randomElement(), decoy != brand {
                    options.insert(decoy)
                }
            }
            choices = Array(options).shuffled()
            return
        }

        vm.errorMessage = "Could not find a product with brand info"
    }
}
