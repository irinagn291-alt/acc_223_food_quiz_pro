import SwiftUI

struct WhichHasMoreView: View {
    @State private var vm = GameViewModel()
    @State private var nutrientType: NutrientType = .calories

    var body: some View {
        VStack(spacing: 16) {
            if vm.isLoading {
                Spacer()
                ProgressView("Loading products...")
                Spacer()
            } else if let error = vm.errorMessage {
                errorView(error)
            } else if vm.products.count >= 2 {
                questionHeader
                productCards
                if vm.answered {
                    nextButton
                }
            }
        }
        .padding()
        .navigationTitle("Which Has More?")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.saveRecentMode(.whichHasMore)
            nutrientType = NutrientType.allCases.randomElement()!
            await vm.loadProducts(count: 2)
        }
    }

    private var questionHeader: some View {
        Text("Which has more **\(nutrientType.rawValue)**?")
            .font(.title3)
            .multilineTextAlignment(.center)
    }

    private var productCards: some View {
        HStack(spacing: 12) {
            ForEach(Array(vm.products.prefix(2).enumerated()), id: \.element.id) { index, product in
                Button {
                    guard !vm.answered else { return }
                    answer(index)
                } label: {
                    ProductCard(
                        product: product,
                        showNutrition: vm.answered,
                        highlight: highlight(for: index),
                        highlightedNutrient: nutrientType
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(vm.answered && vm.selectedIndex == index ? 1.03 : 1)
                .animation(.spring(response: 0.3), value: vm.answered)
            }
        }
    }

    private var nextButton: some View {
        Button {
            Task {
                nutrientType = NutrientType.allCases.randomElement()!
                await vm.nextQuestion(count: 2)
            }
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

    private func answer(_ index: Int) {
        vm.selectedIndex = index
        vm.answered = true

        let correctIndex = correctProductIndex
        if index == correctIndex {
            HapticService.success()
        } else {
            HapticService.error()
        }
    }

    private var correctProductIndex: Int {
        let values = vm.products.prefix(2).map { nutrientType.value(from: $0.nutrition!) ?? 0 }
        return values[0] >= values[1] ? 0 : 1
    }

    private func highlight(for index: Int) -> ProductCard.CardHighlight {
        guard vm.answered else { return .none }
        if index == correctProductIndex { return .correct }
        if index == vm.selectedIndex { return .wrong }
        return .none
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await vm.loadProducts(count: 2) }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
}
