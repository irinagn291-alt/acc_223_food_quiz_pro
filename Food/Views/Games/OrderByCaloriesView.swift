import SwiftUI

struct OrderByCaloriesView: View {
    @State private var vm = GameViewModel()
    @State private var orderedProducts: [Product] = []
    @State private var submitted = false
    @State private var isCorrect = false

    var body: some View {
        VStack(spacing: 16) {
            if vm.isLoading {
                Spacer()
                ProgressView("Loading products...")
                Spacer()
            } else if let error = vm.errorMessage {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(.orange)
                    Text(error)
                    Button("Retry") { Task { await loadRound() } }.buttonStyle(.borderedProminent)
                    Spacer()
                }
            } else if !orderedProducts.isEmpty {
                Text("Order from **highest** to **lowest** calories")
                    .font(.title3)
                    .multilineTextAlignment(.center)

                List {
                    ForEach(orderedProducts) { product in
                        HStack(spacing: 12) {
                            CachedAsyncImage(url: product.imageURL, thumbnailURL: product.thumbnailURL)
                                .frame(width: 50, height: 50)

                            VStack(alignment: .leading) {
                                Text(product.name)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                if submitted, let cal = product.nutrition?.calories {
                                    Text("\(Int(cal)) kcal")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if submitted {
                                let correctOrder = vm.products.sorted { ($0.nutrition?.calories ?? 0) > ($1.nutrition?.calories ?? 0) }
                                let correctIdx = correctOrder.firstIndex(where: { $0.id == product.id })
                                let currentIdx = orderedProducts.firstIndex(where: { $0.id == product.id })
                                if correctIdx == currentIdx {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                } else {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    .onMove { from, to in
                        guard !submitted else { return }
                        orderedProducts.move(fromOffsets: from, toOffset: to)
                        HapticService.selection()
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(submitted ? .inactive : .active))

                if !submitted {
                    Button {
                        submit()
                    } label: {
                        Text("Submit")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                } else {
                    VStack(spacing: 8) {
                        Text(isCorrect ? "Correct!" : "Not quite!")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(isCorrect ? .green : .red)

                        Button {
                            Task { await loadRound() }
                        } label: {
                            Text("Next Round")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Order by Calories")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.saveRecentMode(.orderByCalories)
            await loadRound()
        }
    }

    private func loadRound() async {
        submitted = false
        isCorrect = false
        await vm.loadProducts(count: 4)
        orderedProducts = vm.products.shuffled()
    }

    private func submit() {
        submitted = true
        let correctOrder = vm.products.sorted { ($0.nutrition?.calories ?? 0) > ($1.nutrition?.calories ?? 0) }
        isCorrect = orderedProducts.map(\.id) == correctOrder.map(\.id)
        if isCorrect { HapticService.success() }
        else { HapticService.error() }
    }
}
