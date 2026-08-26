import SwiftUI

struct GuessCaloriesView: View {
    @State private var vm = GameViewModel()
    @State private var choices: [Int] = []
    @State private var correctAnswer = 0
    @State private var selectedAnswer: Int?

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
            } else if let product = vm.products.first {
                CachedAsyncImage(url: product.imageURL, thumbnailURL: product.thumbnailURL)
                    .frame(height: 160)

                Text(product.name)
                    .font(.headline)

                Text("How many kcal per 100g?")
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
                                Text("\(choice) kcal").font(.body.weight(.medium))
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
                            .background(calBackground(choice), in: RoundedRectangle(cornerRadius: 12))
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
            }
        }
        .padding()
        .navigationTitle("Guess Calories")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.saveRecentMode(.guessCalories)
            await loadQuestion()
        }
    }

    private func calBackground(_ choice: Int) -> some ShapeStyle {
        guard let selected = selectedAnswer else { return AnyShapeStyle(.ultraThinMaterial) }
        if choice == correctAnswer { return AnyShapeStyle(Color.green.opacity(0.2)) }
        if choice == selected { return AnyShapeStyle(Color.red.opacity(0.2)) }
        return AnyShapeStyle(.ultraThinMaterial)
    }

    private func loadQuestion() async {
        selectedAnswer = nil
        await vm.loadProducts(count: 1)
        guard let product = vm.products.first, let cal = product.nutrition?.calories else {
            await vm.loadProducts(count: 1)
            return
        }
        correctAnswer = Int(cal)
        var options = Set([correctAnswer])
        let range = max(30, correctAnswer / 3)
        while options.count < 4 {
            let offset = Int.random(in: -range...range)
            let option = max(0, correctAnswer + offset)
            if option != correctAnswer { options.insert(option) }
        }
        choices = Array(options).sorted()
    }
}
