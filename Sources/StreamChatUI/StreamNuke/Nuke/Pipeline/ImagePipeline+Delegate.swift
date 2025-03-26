// The MIT License (MIT)
//
// Copyright (c) 2015-2024 Alexander Grebenyuk (github.com/kean).

import Foundation

/// A delegate that allows you to customize the pipeline dynamically on a per-request basis.
///
/// - important: The delegate methods are performed on the pipeline queue in the
/// background.
protocol ImagePipelineDelegate: AnyObject, Sendable {
    // MARK: Configuration

    /// Returns data loader for the given request.
    func dataLoader(for request: ImageRequest, pipeline: ImagePipeline) -> any DataLoading

    /// Returns image decoder for the given context.
    func imageDecoder(for context: ImageDecodingContext, pipeline: ImagePipeline) -> (any ImageDecoding)?

    /// Returns image encoder for the given context.
    func imageEncoder(for context: ImageEncodingContext, pipeline: ImagePipeline) -> any ImageEncoding

    // MARK: Caching

    /// Returns in-memory image cache for the given request. Return `nil` to prevent cache reads and writes.
    func imageCache(for request: ImageRequest, pipeline: ImagePipeline) -> (any ImageCaching)?

    /// Returns disk cache for the given request. Return `nil` to prevent cache
    /// reads and writes.
    func dataCache(for request: ImageRequest, pipeline: ImagePipeline) -> (any DataCaching)?

    /// Returns a cache key identifying the image produced for the given request
    /// (including image processors). The key is used for both in-memory and
    /// on-disk caches.
    ///
    /// Return `nil` to use a default key.
    func cacheKey(for request: ImageRequest, pipeline: ImagePipeline) -> String?

    /// Gets called when the pipeline is about to save data for the given request.
    /// The implementation must call the completion closure passing `non-nil` data
    /// to enable caching or `nil` to prevent it.
    ///
    /// This method calls only if the request parameters and data caching policy
    /// of the pipeline already allow caching.
    ///
    /// - parameters:
    ///   - data: Either the original data or the encoded image in case of storing
    ///   a processed or re-encoded image.
    ///   - image: Non-nil in case storing an encoded image.
    ///   - request: The request for which image is being stored.
    ///   - completion: The implementation must call the completion closure
    ///   passing `non-nil` data to enable caching or `nil` to prevent it. You can
    ///   safely call it synchronously. The callback gets called on the background
    ///   thread.
    func willCache(data: Data, image: ImageContainer?, for request: ImageRequest, pipeline: ImagePipeline, completion: @escaping (Data?) -> Void)

    // MARK: Decompression

    func shouldDecompress(response: ImageResponse, for request: ImageRequest, pipeline: ImagePipeline) -> Bool

    func decompress(response: ImageResponse, request: ImageRequest, pipeline: ImagePipeline) -> ImageResponse

    // MARK: ImageTask

    /// Gets called when the task is created. Unlike other methods, it is called
    /// immediately on the caller's queue.
    func imageTaskCreated(_ task: ImageTask, pipeline: ImagePipeline)

    /// Gets called when the task receives an event.
    func imageTask(_ task: ImageTask, didReceiveEvent event: ImageTask.Event, pipeline: ImagePipeline)

    /// - warning: Soft-deprecated in Nuke 12.7.
    func imageTaskDidStart(_ task: ImageTask, pipeline: ImagePipeline)

    /// - warning: Soft-deprecated in Nuke 12.7.
    func imageTask(_ task: ImageTask, didUpdateProgress progress: ImageTask.Progress, pipeline: ImagePipeline)

    /// - warning: Soft-deprecated in Nuke 12.7.
    func imageTask(_ task: ImageTask, didReceivePreview response: ImageResponse, pipeline: ImagePipeline)

    /// - warning: Soft-deprecated in Nuke 12.7.
    func imageTaskDidCancel(_ task: ImageTask, pipeline: ImagePipeline)

    /// - warning: Soft-deprecated in Nuke 12.7.
    func imageTask(_ task: ImageTask, didCompleteWithResult result: Result<ImageResponse, ImagePipeline.Error>, pipeline: ImagePipeline)
}

extension ImagePipelineDelegate {
    func imageCache(for request: ImageRequest, pipeline: ImagePipeline) -> (any ImageCaching)? {
        pipeline.configuration.imageCache
    }

    func dataLoader(for request: ImageRequest, pipeline: ImagePipeline) -> any DataLoading {
        pipeline.configuration.dataLoader
    }

    func dataCache(for request: ImageRequest, pipeline: ImagePipeline) -> (any DataCaching)? {
        pipeline.configuration.dataCache
    }

    func imageDecoder(for context: ImageDecodingContext, pipeline: ImagePipeline) -> (any ImageDecoding)? {
        pipeline.configuration.makeImageDecoder(context)
    }

    func imageEncoder(for context: ImageEncodingContext, pipeline: ImagePipeline) -> any ImageEncoding {
        pipeline.configuration.makeImageEncoder(context)
    }

    func cacheKey(for request: ImageRequest, pipeline: ImagePipeline) -> String? {
        nil
    }

    func willCache(data: Data, image: ImageContainer?, for request: ImageRequest, pipeline: ImagePipeline, completion: @escaping (Data?) -> Void) {
        completion(data)
    }

    func shouldDecompress(response: ImageResponse, for request: ImageRequest, pipeline: ImagePipeline) -> Bool {
        pipeline.configuration.isDecompressionEnabled
    }

    func decompress(response: ImageResponse, request: ImageRequest, pipeline: ImagePipeline) -> ImageResponse {
        var response = response
        response.container.image = ImageDecompression.decompress(image: response.image, isUsingPrepareForDisplay: pipeline.configuration.isUsingPrepareForDisplay)
        return response
    }

    func imageTaskCreated(_ task: ImageTask, pipeline: ImagePipeline) {}

    func imageTask(_ task: ImageTask, didReceiveEvent event: ImageTask.Event, pipeline: ImagePipeline) {}

    func imageTaskDidStart(_ task: ImageTask, pipeline: ImagePipeline) {}

    func imageTask(_ task: ImageTask, didUpdateProgress progress: ImageTask.Progress, pipeline: ImagePipeline) {}

    func imageTask(_ task: ImageTask, didReceivePreview response: ImageResponse, pipeline: ImagePipeline) {}

    func imageTaskDidCancel(_ task: ImageTask, pipeline: ImagePipeline) {}

    func imageTask(_ task: ImageTask, didCompleteWithResult result: Result<ImageResponse, ImagePipeline.Error>, pipeline: ImagePipeline) {}
}

final class ImagePipelineDefaultDelegate: ImagePipelineDelegate {}
