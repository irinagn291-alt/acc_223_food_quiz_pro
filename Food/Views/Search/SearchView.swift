import SwiftUI

struct SearchView: View {
    @State private var vm = SearchViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = vm.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(error)
                        Button("Retry") { vm.search() }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.results.isEmpty && vm.hasSearched {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("Try a different search term"))
                } else if vm.results.isEmpty {
                    ContentUnavailableView("Search Products", systemImage: "magnifyingglass", description: Text("Search by name, brand, or barcode"))
                } else {
                    List(vm.results) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            HStack(spacing: 12) {
                                CachedAsyncImage(url: product.imageURL)
                                    .frame(width: 60, height: 60)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.name)
                                        .font(.subheadline.weight(.medium))
                                        .lineLimit(2)
                                    if let brand = product.brand {
                                        Text(brand)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $vm.query, prompt: "Name, brand, or barcode")
            .onSubmit(of: .search) { vm.search() }
        }
    }
}
