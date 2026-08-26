import SwiftUI

actor ImageCacheService {
    nonisolated static let shared = ImageCacheService()
    private let memoryCache = NSCache<NSString, UIImage>()
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]
    private let diskCacheURL: URL?

    private init() {
        memoryCache.countLimit = 300
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        diskCacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("ImageCache", isDirectory: true)
        if let dir = diskCacheURL {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    func image(for url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString

        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        if let diskImage = loadFromDisk(key: url.absoluteString) {
            memoryCache.setObject(diskImage, forKey: key, cost: diskImage.pngData()?.count ?? 0)
            return diskImage
        }

        if let existing = inFlight[url] {
            return await existing.value
        }

        let task = Task<UIImage?, Never> {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return nil }
                memoryCache.setObject(image, forKey: key, cost: data.count)
                saveToDisk(data: data, key: url.absoluteString)
                return image
            } catch {
                return nil
            }
        }

        inFlight[url] = task
        let result = await task.value
        inFlight.removeValue(forKey: url)
        return result
    }

    private nonisolated func diskPath(for key: String) -> URL? {
        guard let dir = diskCacheURL else { return nil }
        let filename = key.data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .prefix(120)
        return dir.appendingPathComponent(String(filename))
    }

    private nonisolated func loadFromDisk(key: String) -> UIImage? {
        guard let path = diskPath(for: key),
              let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }

    private nonisolated func saveToDisk(data: Data, key: String) {
        guard let path = diskPath(for: key) else { return }
        try? data.write(to: path)
    }
}
