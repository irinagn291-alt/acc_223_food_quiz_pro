import SwiftUI

struct CachedAsyncImage: View {
    let url: URL?
    var thumbnailURL: URL?
    var cornerRadius: CGFloat = 12

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                Rectangle()
                    .fill(.quaternary)
                    .overlay { ProgressView() }
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        // Load thumbnail first for fast preview, then full image
        if let thumb = thumbnailURL {
            if let thumbImg = await ImageCacheService.shared.image(for: thumb) {
                self.image = thumbImg
                isLoading = false
            }
        }

        guard let url else {
            isLoading = false
            return
        }
        if let full = await ImageCacheService.shared.image(for: url) {
            self.image = full
        }
        isLoading = false
    }
}
