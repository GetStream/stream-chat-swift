//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CryptoKit
import StreamChat
import UIKit

/// The default image loading pipeline used by the Stream UI SDKs.
///
/// Downloads images over `URLSession`, downscales them to the requested size, and caches
/// the decoded result in a least-recently-used in-memory cache. The original image data is
/// cached on disk by the session's `URLCache`, which honors the HTTP caching headers of the
/// response, so expired images are revalidated instead of being served indefinitely.
/// Concurrent requests for the same image are coalesced into a single download.
public final class StreamImageDownloader: ImageDownloading, Sendable {
    private typealias SourceCompletion = @Sendable (Result<Data, Error>) -> Void

    private let memoryCache: ImageMemoryCache
    let urlSession: URLSession
    private let coalescedImageTasks = RequestCoalescer<DownloadedImage>()
    private let coalescedDataTasks = RequestCoalescer<Data>()

    static let displayScale: CGFloat = UITraitCollection.current.displayScale
    private static let decodeQueue = DispatchQueue.global(qos: .userInitiated)

    /// Creates an image loader with the given in-memory and on-disk cache capacities.
    ///
    /// - Parameters:
    ///   - memoryCacheSize: The in-memory cache capacity in bytes. Values less than or
    ///     equal to zero disable in-memory caching. The default capacity is 50 MB.
    ///   - diskCacheSize: The disk cache capacity in bytes. Values less than or equal to
    ///     zero disable disk caching. The default capacity is 150 MB.
    public convenience init(
        memoryCacheSize: Int = 50 * 1024 * 1024,
        diskCacheSize: Int = 150 * 1024 * 1024
    ) {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = {
            guard diskCacheSize > 0 else { return nil }
            let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            return URLCache(
                memoryCapacity: 0,
                diskCapacity: diskCacheSize,
                directory: base.appendingPathComponent("io.getstream.StreamImageDownloader", isDirectory: true)
            )
        }()
        self.init(
            memoryCostLimit: max(0, memoryCacheSize),
            urlSession: URLSession(configuration: configuration)
        )
    }

    init(
        memoryCostLimit: Int,
        urlSession: URLSession
    ) {
        memoryCache = ImageMemoryCache(maxSizeInBytes: memoryCostLimit)
        self.urlSession = urlSession
    }

    // MARK: - ImageDownloading

    public func downloadImage(
        url: URL,
        options: ImageDownloadingOptions,
        completion: @escaping @MainActor (Result<DownloadedImage, Error>) -> Void
    ) {
        downloadImageTask(url: url, options: options, completion: completion)
    }

    @discardableResult
    public func downloadImageTask(
        url: URL,
        options: ImageDownloadingOptions,
        completion: @escaping @MainActor (Result<DownloadedImage, Error>) -> Void
    ) -> ImageLoadingTask {
        let key = cacheKey(url: url, options: options)

        // A warm memory cache completes synchronously, avoiding a flicker when the image
        // is already available on the main thread.
        if let cached = memoryCache.image(forKey: key) {
            StreamConcurrency.onMain { completion(.success(cached)) }
            return ImageLoadingTask()
        }

        // Coalesce concurrent requests for the same key into a single download.
        return coalescedImageTasks.coalesce(
            by: key,
            sharedFetch: { fetchFinishedHandler in
                self.load(url: url, key: key, options: options, completion: fetchFinishedHandler)
            },
            completion: { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        )
    }

    // MARK: - Cache Management

    /// Evicts least-recently-used images from the in-memory cache until its total cost
    /// drops to the given limit in bytes.
    public func trimMemoryCache(toCost limit: Int) {
        memoryCache.trim(toCost: limit)
    }

    /// Removes every image from the in-memory cache. The disk cache is left intact.
    public func removeAllImagesFromMemoryCache() {
        memoryCache.removeAll()
    }

    /// Removes every image from the on-disk cache. The in-memory cache is left intact.
    public func removeAllImagesFromDiskCache() {
        urlSession.configuration.urlCache?.removeAllCachedResponses()
    }

    // MARK: - Internal

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
    ) -> ImageLoadingTask {
        let resize = options.resize
        let sourceKey = sourceKey(url: url, options: options)
        return loadSourceData(url: url, sourceKey: sourceKey, headers: options.headers) { result in
            switch result {
            case let .success(data):
                self.decode(data, resize: resize, key: key) { image in
                    if let image {
                        completion(.success(image))
                    } else {
                        completion(.failure(ClientError.ImageDecodingFailed()))
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
            guard let image = Self.makeImage(from: data, resize: resize, scale: Self.displayScale) else {
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
    ) -> ImageLoadingTask {
        // Coalesce concurrent requests for the same source data into a single fetch.
        return coalescedDataTasks.coalesce(
            by: sourceKey,
            sharedFetch: { completion in
                self.fetch(url: url, headers: headers, completion: completion)
            },
            completion: completion
        )
    }

    private func fetch(
        url: URL,
        headers: [String: String]?,
        completion: @escaping SourceCompletion
    ) -> ImageLoadingTask {
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
        let loadingTask = ImageLoadingTask()
        loadingTask.addCancellationHandler { task.cancel() }
        return loadingTask
    }

    private func cacheKey(url: URL, options: ImageDownloadingOptions) -> String {
        let base = sourceKey(url: url, options: options)
        guard let resize = options.resize, resize != .zero else {
            return base
        }
        let width = String(Double(resize.width * Self.displayScale).bitPattern, radix: 16)
        let height = String(Double(resize.height * Self.displayScale).bitPattern, radix: 16)
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
        switch ImageDownsampler.decode(data, resize: resize, scale: scale) {
        case let .image(image):
            return DownloadedImage(image: image)
        case .animated:
            // Animated data is passed through untouched; SwiftyGif renders it in the UI SDKs.
            guard let image = UIImage(data: data) else { return nil }
            return DownloadedImage(image: image, animatedImageData: data)
        case nil:
            return nil
        }
    }
}

private final class RequestCoalescer<Value>: Sendable where Value: Sendable {
    typealias Completion = @Sendable (Result<Value, Error>) -> Void

    private struct Request: Sendable {
        let id = UUID()
        var completions: [UUID: Completion] = [:]
        var sharedFetch: ImageLoadingTask?
    }

    private let requests = AllocatedUnfairLock<[String: Request]>([:])

    /// Coalesces requests by key and runs a shared fetch for all of them while
    /// allowing to cancel individual tasks.
    func coalesce(
        by key: String,
        sharedFetch: (@escaping Completion) -> ImageLoadingTask,
        completion: @escaping Completion
    ) -> ImageLoadingTask {
        let perRequestTask = ImageLoadingTask()
        let perRequestTaskID = UUID()
        let (requestID, isFirst) = requests.withLock { requests -> (UUID, Bool) in
            let isFirst = requests[key] == nil
            var request = requests[key] ?? Request()
            request.completions[perRequestTaskID] = completion
            requests[key] = request
            return (request.id, isFirst)
        }
        if isFirst {
            let sharedFetchTask = sharedFetch { result in
                let completions = self.requests.withLock { requests -> [Completion] in
                    // A cancelled request may be replaced by a new one for the same key before
                    // the fetch finishes, so the key alone does not identify the request.
                    guard let request = requests[key], request.id == requestID else { return [] }
                    requests[key] = nil
                    return Array(request.completions.values)
                }
                completions.forEach { $0(result) }
            }
            let isRequestActive = requests.withLock { requests -> Bool in
                guard requests[key]?.id == requestID else { return false }
                requests[key]?.sharedFetch = sharedFetchTask
                return true
            }
            if !isRequestActive {
                sharedFetchTask.cancel()
            }
        }
        perRequestTask.addCancellationHandler {
            let (completion, fetchTask) = self.requests.withLock { requests -> (Completion?, ImageLoadingTask?) in
                guard var request = requests[key], request.id == requestID,
                      let completion = request.completions.removeValue(forKey: perRequestTaskID) else { return (nil, nil) }
                guard request.completions.isEmpty else {
                    requests[key] = request
                    return (completion, nil)
                }
                requests[key] = nil
                return (completion, request.sharedFetch)
            }
            fetchTask?.cancel()
            completion?(.failure(URLError(.cancelled)))
        }
        return perRequestTask
    }
}

extension ClientError {
    final class ImageDecodingFailed: ClientError, @unchecked Sendable {}
    final class ImageDownloadEmptyResponse: ClientError, @unchecked Sendable {}
    final class ImageDownloadInvalidHTTPStatus: ClientError, @unchecked Sendable {}
}
