import SwiftUI
import Foundation

final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let ioQueue = DispatchQueue(label: "com.kikiflarr.imagecache", qos: .utility)
    
    private init() {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesDir.appendingPathComponent("ImageCache", isDirectory: true)
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearMemoryCache()
        }
    }
    
    func image(for url: URL) -> UIImage? {
        let key = cacheKey(for: url)
        
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }
        
        if let diskImage = loadFromDisk(key: key) {
            memoryCache.setObject(diskImage, forKey: key as NSString, cost: diskImage.pngData()?.count ?? 0)
            return diskImage
        }
        
        return nil
    }
    
    func store(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url)
        let cost = image.pngData()?.count ?? 0
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
        
        ioQueue.async { [weak self] in
            self?.saveToDisk(image: image, key: key)
        }
    }
    
    private func cacheKey(for url: URL) -> String {
        url.absoluteString.data(using: .utf8)?.base64EncodedString() ?? url.absoluteString
    }
    
    private func loadFromDisk(key: String) -> UIImage? {
        let filePath = cacheDirectory.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: filePath) else { return nil }
        return UIImage(data: data)
    }
    
    private func saveToDisk(image: UIImage, key: String) {
        let filePath = cacheDirectory.appendingPathComponent(key)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: filePath, options: .atomic)
        }
    }
    
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    func clearDiskCache() {
        ioQueue.async { [weak self] in
            guard let self = self else { return }
            try? self.fileManager.removeItem(at: self.cacheDirectory)
            try? self.fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func clearAll() {
        clearMemoryCache()
        clearDiskCache()
    }
}

@MainActor
final class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    private var url: URL?
    private var loadTask: Task<Void, Never>?
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
        return URLSession(configuration: config)
    }()
    
    func load(url: URL?) {
        guard let url = url else {
            self.image = nil
            return
        }
        
        if self.url == url && image != nil { return }
        
        self.url = url
        
        if let cached = ImageCache.shared.image(for: url) {
            self.image = cached
            return
        }
        
        loadTask?.cancel()
        isLoading = true
        
        loadTask = Task { [weak self] in
            do {
                let (data, _) = try await Self.session.data(from: url)
                
                guard !Task.isCancelled else { return }
                
                if let uiImage = UIImage(data: data) {
                    ImageCache.shared.store(uiImage, for: url)
                    self?.image = uiImage
                }
            } catch {
                // Silently fail - placeholder will show
            }
            self?.isLoading = false
        }
    }
    
    func cancel() {
        loadTask?.cancel()
        loadTask = nil
    }
}

struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder
    
    @StateObject private var loader = ImageLoader()
    
    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if loader.isLoading {
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                }
            } else {
                placeholder()
            }
        }
        .onAppear { loader.load(url: url) }
        .onChange(of: url) { _, newURL in loader.load(url: newURL) }
        .onDisappear { loader.cancel() }
    }
}
