//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Prefetches and caches images to eliminate delays when requesting the same
/// images later.
///
/// The prefetcher cancels all of the outstanding tasks when deallocated.
///
/// All ``ImagePrefetcher`` methods are thread-safe and are optimized to be used
/// even from the main thread during scrolling.
final class ImagePrefetcher: @unchecked Sendable {
    /// Pauses the prefetching.
    ///
    /// - note: When you pause, the prefetcher will finish outstanding tasks
    /// (by default, there are only 2 at a time), and pause the rest.
    var isPaused: Bool = false {
        didSet { queue.isSuspended = isPaused }
    }

    /// The priority of the requests. By default, ``ImageRequest/Priority-swift.enum/low``.
    ///
    /// Changing the priority also changes the priority of all of the outstanding
    /// tasks managed by the prefetcher.
    var priority: ImageRequest.Priority = .low {
        didSet {
            let newValue = priority
            pipeline.queue.async { self.didUpdatePriority(to: newValue) }
        }
    }

    /// Prefetching destination.
    enum Destination: Sendable {
        /// Prefetches the image and stores it in both the memory and the disk
        /// cache (make sure to enable it).
        case memoryCache

        /// Prefetches the image data and stores it in disk caches. It does not
        /// require decoding the image data and therefore requires less CPU.
        ///
        /// - important: This option is incompatible with ``ImagePipeline/DataCachePolicy/automatic``
        /// (for requests with processors) and ``ImagePipeline/DataCachePolicy/storeEncodedImages``.
        case diskCache
    }

    /// The closure that gets called when the prefetching completes for all the
    /// scheduled requests. The closure is always called on completion,
    /// regardless of whether the requests succeed or some fail.
    ///
    /// - note: The closure is called on the main queue.
    var didComplete: (@MainActor() -> Void)?

    private let pipeline: ImagePipeline
    private var tasks = [TaskLoadImageKey: Task]()
    private let destination: Destination
    private var _priority: ImageRequest.Priority = .low
    let queue = OperationQueue() // internal for testing

    /// Initializes the ``ImagePrefetcher`` instance.
    ///
    /// - parameters:
    ///   - pipeline: The pipeline used for loading images.
    ///   - destination: By default load images in all cache layers.
    ///   - maxConcurrentRequestCount: 2 by default.
    init(
        pipeline: ImagePipeline = ImagePipeline.shared,
        destination: Destination = .memoryCache,
        maxConcurrentRequestCount: Int = 2
    ) {
        self.pipeline = pipeline
        self.destination = destination
        queue.maxConcurrentOperationCount = maxConcurrentRequestCount
        queue.underlyingQueue = pipeline.queue
    }

    deinit {
        let tasks = self.tasks.values // Make sure we don't retain self
        self.tasks.removeAll()

        pipeline.queue.async {
            for task in tasks {
                task.cancel()
            }
        }
    }

    /// Starts prefetching images for the given URL.
    ///
    /// See also ``startPrefetching(with:)-718dg`` that works with ``ImageRequest``.
    func startPrefetching(with urls: [URL]) {
        startPrefetching(with: urls.map { ImageRequest(url: $0) })
    }

    /// Starts prefetching images for the given requests.
    ///
    /// When you need to display the same image later, use the ``ImagePipeline``
    /// or the view extensions to load it as usual. The pipeline will take care
    /// of coalescing the requests to avoid any duplicate work.
    ///
    /// The priority of the requests is set to the priority of the prefetcher
    /// (`.low` by default).
    ///
    /// See also ``startPrefetching(with:)-1jef2`` that works with `URL`.
    func startPrefetching(with requests: [ImageRequest]) {
        pipeline.queue.async {
            self._startPrefetching(with: requests)
        }
    }

    func _startPrefetching(with requests: [ImageRequest]) {
        for request in requests {
            var request = request
            if _priority != request.priority {
                request.priority = _priority
            }
            _startPrefetching(with: request)
        }
        sendCompletionIfNeeded()
    }

    private func _startPrefetching(with request: ImageRequest) {
        guard pipeline.cache[request] == nil else {
            return
        }
        let key = TaskLoadImageKey(request)
        guard tasks[key] == nil else {
            return
        }
        let task = Task(request: request, key: key)
        task.operation = queue.add { [weak self] finish in
            guard let self else { return finish() }
            self.loadImage(task: task, finish: finish)
        }
        tasks[key] = task
        return
    }

    private func loadImage(task: Task, finish: @escaping () -> Void) {
        task.imageTask = pipeline._loadImage(with: task.request, isDataTask: destination == .diskCache, queue: pipeline.queue, progress: nil) { [weak self] _ in
            self?._remove(task)
            finish()
        }
        task.onCancelled = finish
    }

    private func _remove(_ task: Task) {
        guard tasks[task.key] === task else { return } // Should never happen
        tasks[task.key] = nil
        sendCompletionIfNeeded()
    }

    private func sendCompletionIfNeeded() {
        guard tasks.isEmpty, let callback = didComplete else {
            return
        }
        DispatchQueue.main.async(execute: callback)
    }

    /// Stops prefetching images for the given URLs and cancels outstanding
    /// requests.
    ///
    /// See also ``stopPrefetching(with:)-8cdam`` that works with ``ImageRequest``.
    func stopPrefetching(with urls: [URL]) {
        stopPrefetching(with: urls.map { ImageRequest(url: $0) })
    }

    /// Stops prefetching images for the given requests and cancels outstanding
    /// requests.
    ///
    /// You don't need to balance the number of `start` and `stop` requests.
    /// If you have multiple screens with prefetching, create multiple instances
    /// of ``ImagePrefetcher``.
    ///
    /// See also ``stopPrefetching(with:)-2tcyq`` that works with `URL`.
    func stopPrefetching(with requests: [ImageRequest]) {
        pipeline.queue.async {
            for request in requests {
                self._stopPrefetching(with: request)
            }
        }
    }

    private func _stopPrefetching(with request: ImageRequest) {
        if let task = tasks.removeValue(forKey: TaskLoadImageKey(request)) {
            task.cancel()
        }
    }

    /// Stops all prefetching tasks.
    func stopPrefetching() {
        pipeline.queue.async {
            self.tasks.values.forEach { $0.cancel() }
            self.tasks.removeAll()
        }
    }

    private func didUpdatePriority(to priority: ImageRequest.Priority) {
        guard _priority != priority else { return }
        _priority = priority
        for task in tasks.values {
            task.imageTask?.priority = priority
        }
    }

    private final class Task: @unchecked Sendable {
        let key: TaskLoadImageKey
        let request: ImageRequest
        weak var imageTask: ImageTask?
        weak var operation: Operation?
        var onCancelled: (() -> Void)?

        init(request: ImageRequest, key: TaskLoadImageKey) {
            self.request = request
            self.key = key
        }

        // When task is cancelled, it is removed from the prefetcher and can
        // never get cancelled twice.
        func cancel() {
            operation?.cancel()
            imageTask?.cancel()
            onCancelled?()
        }
    }
}
