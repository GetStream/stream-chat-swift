//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CryptoKit
import StreamChat
import UIKit

/// The default image loading pipeline used by the Stream UI SDKs.
///
/// Downloads images over `URLSession`, downscales them to the requested size, and caches
/// the result both in memory and on disk (both least-recently-used). Concurrent requests
/// for the same image are coalesced into a single download. Conforms to ``ImageDownloading``
/// so it can back ``StreamMediaLoader``.
public final class StreamImageDownloader: ImageDownloading, Sendable {
    private typealias ImageCompletion = @MainActor (Result<DownloadedImage, Error>) -> Void
    private typealias SourceCompletion = @Sendable (Result<Data, Error>) -> Void

    private let memoryCache: ImageMemoryCache
    private let diskCache: LRUDiskCache
    private let urlSession: URLSession
    private let displayScale: CGFloat
    private let inFlightImages: AllocatedUnfairLock<[String: [ImageCompletion]]>
    private let inFlightSources: AllocatedUnfairLock<[String: [SourceCompletion]]>

    /// Decoding runs on a concurrent queue because disk cache completions arrive on a
    /// shared serial queue; decoding there would serialize decodes and block file I/O.
    private static let decodeQueue = DispatchQueue.global(qos: .userInitiated)

    /// Creates an image loader with the given on-disk cache capacity.
    ///
    /// - Parameter diskCacheSize: The disk cache capacity in bytes. Values less than
    ///   or equal to zero disable disk caching. The default capacity is 150 MB.
    public convenience init(diskCacheSize: Int = 150 * 1024 * 1024) {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.init(
            memoryCostLimit: Self.defaultMemoryCostLimit(),
            diskSizeLimit: max(0, diskCacheSize),
            diskDirectory: Self.defaultDiskDirectory(),
            urlSession: URLSession(configuration: configuration),
            displayScale: StreamConcurrency.onMain { UITraitCollection.current.displayScale }
        )
    }

    init(
        memoryCostLimit: Int,
        diskSizeLimit: Int,
        diskDirectory: URL,
        urlSession: URLSession,
        displayScale: CGFloat
    ) {
        memoryCache = ImageMemoryCache(costLimit: memoryCostLimit)
        diskCache = LRUDiskCache(directory: diskDirectory, maxSizeInBytes: diskSizeLimit)
        self.urlSession = urlSession
        self.displayScale = max(1, displayScale)
        inFlightImages = AllocatedUnfairLock([:])
        inFlightSources = AllocatedUnfairLock([:])
    }

    // MARK: - ImageDownloading

    public func downloadImage(
        url: URL,
        options: ImageDownloadingOptions,
        completion: @escaping @MainActor (Result<DownloadedImage, Error>) -> Void
    ) {
        let key = cacheKey(url: url, options: options)

        // A warm memory cache completes synchronously, avoiding a flicker when the image
        // is already available on the main thread.
        if let cached = memoryCache.image(forKey: key) {
            StreamConcurrency.onMain { completion(.success(cached)) }
            return
        }

        // Coalesce concurrent requests for the same key into a single download.
        let isFirstRequest = inFlightImages.withLock { requests -> Bool in
            if requests[key] != nil {
                requests[key]?.append(completion)
                return false
            }
            requests[key] = [completion]
            return true
        }
        guard isFirstRequest else { return }

        load(url: url, key: key, options: options) { result in
            let completions = self.inFlightImages.withLock { $0.removeValue(forKey: key) ?? [] }
            StreamConcurrency.onMain {
                for completion in completions {
                    completion(result)
                }
            }
        }
    }

    // MARK: - Cache Management

    /// Removes every image from the in-memory cache. The disk cache is left intact.
    public func removeAllImagesFromMemoryCache() {
        memoryCache.removeAll()
    }

    /// Evicts least-recently-used images from the in-memory cache until its total cost
    /// drops to the given limit in bytes.
    public func trimMemoryCache(toCost limit: Int) {
        memoryCache.trim(toCost: limit)
    }

    /// Removes every image from the on-disk cache. The in-memory cache is left intact.
    ///
    /// - Parameter completion: Called on the main actor after the cache has been cleared.
    public func removeAllImagesFromDiskCache(completion: (@MainActor @Sendable () -> Void)? = nil) {
        diskCache.removeAll {
            guard let completion else { return }
            StreamConcurrency.onMain { completion() }
        }
    }

    // MARK: - Internal (test seam)

    func store(_ image: DownloadedImage, for url: URL, options: ImageDownloadingOptions) {
        memoryCache.store(image, forKey: cacheKey(url: url, options: options))
    }

    func cachedImage(for url: URL, options: ImageDownloadingOptions) -> DownloadedImage? {
        memoryCache.image(forKey: cacheKey(url: url, options: options))
    }

    // MARK: - Private

    private func load(
        url: URL,
        key: String,
        options: ImageDownloadingOptions,
        completion: @escaping @Sendable (Result<DownloadedImage, Error>) -> Void
    ) {
        let resize = options.resize
        let sourceKey = sourceKey(url: url, options: options)

        diskCache.data(forKey: sourceKey) { data in
            guard let data else {
                self.download(url: url, key: key, sourceKey: sourceKey, resize: resize, headers: options.headers, completion: completion)
                return
            }
            self.decode(data, resize: resize, key: key) { image in
                if let image {
                    completion(.success(image))
                } else {
                    self.diskCache.remove(forKey: sourceKey) {
                        self.download(url: url, key: key, sourceKey: sourceKey, resize: resize, headers: options.headers, completion: completion)
                    }
                }
            }
        }
    }

    private func download(
        url: URL,
        key: String,
        sourceKey: String,
        resize: CGSize?,
        headers: [String: String]?,
        completion: @escaping @Sendable (Result<DownloadedImage, Error>) -> Void
    ) {
        loadSourceData(url: url, sourceKey: sourceKey, headers: headers) { result in
            switch result {
            case let .success(data):
                self.decode(data, resize: resize, key: key) { image in
                    if let image {
                        completion(.success(image))
                    } else {
                        self.diskCache.remove(forKey: sourceKey) {
                            completion(.failure(ClientError.ImageDecodingFailed()))
                        }
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func decode(
        _ data: Data,
        resize: CGSize?,
        key: String,
        completion: @escaping @Sendable (DownloadedImage?) -> Void
    ) {
        Self.decodeQueue.async {
            guard let image = Self.makeImage(from: data, resize: resize, scale: self.displayScale) else {
                completion(nil)
                return
            }
            self.memoryCache.store(image, forKey: key)
            completion(image)
        }
    }

    private func loadSourceData(
        url: URL,
        sourceKey: String,
        headers: [String: String]?,
        completion: @escaping SourceCompletion
    ) {
        // Coalesce concurrent requests for the same source data into a single fetch.
        let isFirstRequest = inFlightSources.withLock { requests -> Bool in
            if requests[sourceKey] != nil {
                requests[sourceKey]?.append(completion)
                return false
            }
            requests[sourceKey] = [completion]
            return true
        }
        guard isFirstRequest else { return }

        fetch(url: url, headers: headers) { result in
            let deliver: @Sendable () -> Void = {
                let completions = self.inFlightSources.withLock { $0.removeValue(forKey: sourceKey) ?? [] }
                for completion in completions {
                    completion(result)
                }
            }
            switch result {
            case let .success(data):
                // Persist before delivering so a reload finds the data on disk.
                self.diskCache.store(data, forKey: sourceKey) { _ in deliver() }
            case .failure:
                deliver()
            }
        }
    }

    private func fetch(
        url: URL,
        headers: [String: String]?,
        completion: @escaping SourceCompletion
    ) {
        var request = URLRequest(url: url)
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
                completion(.failure(ClientError.ImageDownloadInvalidHTTPStatus("HTTP status code \(response.statusCode)")))
                return
            }
            guard let data, !data.isEmpty else {
                completion(.failure(ClientError.ImageDownloadEmptyResponse()))
                return
            }
            completion(.success(data))
        }
        task.resume()
    }

    private func cacheKey(url: URL, options: ImageDownloadingOptions) -> String {
        let base = sourceKey(url: url, options: options)
        guard let resize = options.resize, resize != .zero else {
            return base
        }
        let width = String(Double(resize.width * displayScale).bitPattern, radix: 16)
        let height = String(Double(resize.height * displayScale).bitPattern, radix: 16)
        return "\(base)#stream-resize-v1=\(width)x\(height)"
    }

    private func sourceKey(url: URL, options: ImageDownloadingOptions) -> String {
        if let cachingKey = options.cachingKey {
            return cachingKey
        }
        guard let headers = options.headers, !headers.isEmpty else {
            return url.absoluteString
        }
        let normalizedHeaders = headers
            .map { "\($0.key.lowercased()):\($0.value)" }
            .sorted()
            .joined(separator: "\n")
        let digest = SHA256.hash(data: Data(normalizedHeaders.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return "\(url.absoluteString)#stream-headers=\(digest)"
    }

    private static func makeImage(from data: Data, resize: CGSize?, scale: CGFloat) -> DownloadedImage? {
        if ImageDownsampler.isGIF(data) {
            guard let image = UIImage(data: data) else { return nil }
            return DownloadedImage(image: image, animatedImageData: data)
        }
        guard let image = ImageDownsampler.decode(data, resize: resize, scale: scale) else { return nil }
        return DownloadedImage(image: image)
    }

    // MARK: - Defaults

    /// A memory cost limit based on the device's physical memory, capped at 512 MB.
    private static func defaultMemoryCostLimit() -> Int {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let ratio = physicalMemory <= 536_870_912 /* 512 MB */ ? 0.1 : 0.2
        let limit = min(536_870_912, physicalMemory / UInt64(1 / ratio))
        return Int(limit)
    }

    private static func defaultDiskDirectory() -> URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("io.getstream.StreamImageDownloader", isDirectory: true)
    }
}

extension ClientError {
    final class ImageDecodingFailed: ClientError, @unchecked Sendable {}
    final class ImageDownloadEmptyResponse: ClientError, @unchecked Sendable {}
    final class ImageDownloadInvalidHTTPStatus: ClientError, @unchecked Sendable {}
}
