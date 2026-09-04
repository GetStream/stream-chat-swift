//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import ImageIO
import StreamChat
import UIKit

/// Loads the media which was selected in the composer's photos picker.
///
/// The picker hands over item providers, not files, so every item is first copied to a
/// location owned by the composer. Videos are then compressed, because the picker provides
/// the original recording which is often too large to upload. Both steps are reported as a
/// single progress value, since they are one wait from the user's point of view.
@MainActor
final class ComposerMediaLoader {
    /// A media item which is ready to be added to the composer's content.
    struct Item {
        /// The local file URL, owned by the loader until the attachment is created.
        let url: URL
        /// Either `.image` or `.video`.
        let type: AttachmentType
        /// The metadata which is needed for rendering the attachment before it is uploaded.
        let info: [LocalAttachmentInfoKey: Any]
    }

    private let compressor: VideoCompressing
    private let quality: VideoCompressionQuality
    private let maximumVideoFileSize: Int64
    private let progressUpdateInterval: TimeInterval

    /// The share of an item's progress which is spent on loading it, when it is also compressed.
    private static let loadingShareOfProgress = 0.5
    private static let videoTypeIdentifier = "public.movie"
    private static let imageTypeIdentifier = "public.image"

    init(
        compressor: VideoCompressing,
        quality: VideoCompressionQuality,
        maximumVideoFileSize: Int64,
        progressUpdateInterval: TimeInterval = 0.1
    ) {
        self.compressor = compressor
        self.quality = quality
        self.maximumVideoFileSize = maximumVideoFileSize
        self.progressUpdateInterval = progressUpdateInterval
    }

    /// How many of the given items are videos which will be compressed.
    func numberOfVideosToCompress(in itemProviders: [NSItemProvider]) -> Int {
        guard quality != .original else { return 0 }
        return itemProviders.filter { $0.hasItemConformingToTypeIdentifier(Self.videoTypeIdentifier) }.count
    }

    /// Loads one selected item, compressing it when it is a video.
    ///
    /// - Parameter progressHandler: Called with the progress of loading and compressing this
    /// single item, a value between 0 and 1.
    /// - Returns: The loaded item, or `nil` when it could not be loaded.
    /// - Throws: `CancellationError` when the surrounding task was cancelled.
    func loadItem(
        from itemProvider: NSItemProvider,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> Item? {
        let isVideo = itemProvider.hasItemConformingToTypeIdentifier(Self.videoTypeIdentifier)
        let willCompress = isVideo && quality != .original
        let loadingShare = willCompress ? Self.loadingShareOfProgress : 1

        guard var url = await loadFile(from: itemProvider, isVideo: isVideo, progressHandler: {
            progressHandler($0 * loadingShare)
        }) else { return nil }

        if willCompress {
            do {
                url = try await compressVideo(at: url, progressHandler: {
                    progressHandler(loadingShare + $0 * (1 - loadingShare))
                })
            } catch is CancellationError {
                removeTemporaryFile(at: url)
                throw CancellationError()
            } catch {
                log.error("Failed to compress the selected video, the original video is used instead: \(error)")
            }
        }

        return Item(
            url: url,
            type: isVideo ? .video : .image,
            info: await attachmentInfo(for: url, isVideo: isVideo)
        )
    }

    /// Removes a temporary file which this loader created.
    ///
    /// Only a directory named after a UUID is removed, so a file which the loader does not
    /// own cannot be deleted by mistake.
    func removeTemporaryFile(at url: URL) {
        let directory = url.deletingLastPathComponent()
        if UUID(uuidString: directory.lastPathComponent) != nil {
            try? FileManager.default.removeItem(at: directory)
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Loading

    /// Holds the progress of a load, which is only known once the load started.
    private final class LoadProgress {
        var progress: Progress?
    }

    private func loadFile(
        from itemProvider: NSItemProvider,
        isVideo: Bool,
        progressHandler: @escaping (Double) -> Void
    ) async -> URL? {
        let typeIdentifier = isVideo ? Self.videoTypeIdentifier : Self.imageTypeIdentifier
        let loadProgress = LoadProgress()
        let progressTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(progressUpdateInterval * 1_000_000_000))
                guard !Task.isCancelled else { return }
                guard let fractionCompleted = loadProgress.progress?.fractionCompleted else { continue }
                progressHandler(fractionCompleted)
            }
        }
        defer { progressTask.cancel() }

        return await withCheckedContinuation { continuation in
            loadProgress.progress = itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                guard let url = url else {
                    log.error("Failed to load the media selected in the photos picker: \(error?.localizedDescription ?? "unknown error")")
                    continuation.resume(returning: nil)
                    return
                }
                do {
                    // The provided file is deleted as soon as this closure returns, so it needs
                    // to be copied to a location which is owned by the composer.
                    continuation.resume(returning: try Self.copyToTemporaryLocation(url))
                } catch {
                    log.error("Failed to copy the media selected in the photos picker: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private static func copyToTemporaryLocation(_ url: URL) throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = url.lastPathComponent.isEmpty ? UUID().uuidString : url.lastPathComponent
        let destination = directory.appendingPathComponent(fileName)
        do {
            try FileManager.default.copyItem(at: url, to: destination)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
        return destination
    }

    // MARK: - Compressing

    /// Compresses the video and removes the file it was created from.
    ///
    /// Compressing an already small video can result in a bigger file, in which case the
    /// original is kept, because uploading it is the better of the two.
    private func compressVideo(at url: URL, progressHandler: @escaping (Double) -> Void) async throws -> URL {
        let originalSize = Self.fileSize(at: url)
        let compressedURL = try await compressor.compressVideo(
            at: url,
            quality: quality,
            maximumFileSize: maximumVideoFileSize,
            progressHandler: progressHandler
        )
        let compressedSize = Self.fileSize(at: compressedURL)
        log.info(
            "Compressed the selected video from \(originalSize?.description ?? "unknown") to "
                + "\(compressedSize?.description ?? "unknown") bytes, the maximum attachment size is \(maximumVideoFileSize)"
        )
        if let originalSize = originalSize, let compressedSize = compressedSize, compressedSize >= originalSize {
            removeTemporaryFile(at: compressedURL)
            return url
        }
        removeTemporaryFile(at: url)
        return compressedURL
    }

    private static func fileSize(at url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else { return nil }
        return (attributes[.size] as? NSNumber)?.int64Value
    }

    // MARK: - Metadata

    private func attachmentInfo(for url: URL, isVideo: Bool) async -> [LocalAttachmentInfoKey: Any] {
        var info: [LocalAttachmentInfoKey: Any] = [:]
        if isVideo {
            let metadata = await Self.loadVideoMetadata(at: url)
            if let duration = metadata.duration {
                info[.duration] = duration
            }
            if let width = metadata.width, let height = metadata.height {
                info[.originalWidth] = width
                info[.originalHeight] = height
            }
        } else if let dimensions = Self.imageDimensions(at: url) {
            info[.originalWidth] = dimensions.width
            info[.originalHeight] = dimensions.height
        }
        return info
    }

    /// The properties of a video which the backend needs for rendering it.
    private struct VideoMetadata: Sendable {
        var duration: TimeInterval?
        var width: Double?
        var height: Double?
    }

    private static func loadVideoMetadata(at url: URL) async -> VideoMetadata {
        await withCheckedContinuation { continuation in
            StreamAssetPropertyLoader().loadProperties(
                [AssetProperty(\.duration), AssetProperty(\.tracks)],
                of: AVURLAsset(url: url)
            ) { result in
                guard case .success(let asset) = result else {
                    continuation.resume(returning: VideoMetadata())
                    return
                }
                var metadata = VideoMetadata()
                let durationSeconds = CMTimeGetSeconds(asset.duration)
                if durationSeconds.isFinite && !durationSeconds.isNaN {
                    metadata.duration = durationSeconds
                }
                if let track = asset.tracks(withMediaType: .video).first {
                    let size = track.naturalSize
                    let transform = track.preferredTransform
                    let isRotated = transform.a == 0 && abs(transform.b) == 1
                        && abs(transform.c) == 1 && transform.d == 0
                    metadata.width = Double(isRotated ? size.height : size.width)
                    metadata.height = Double(isRotated ? size.width : size.height)
                }
                continuation.resume(returning: metadata)
            }
        }
    }

    /// Reads the dimensions from the image's metadata, without decoding the whole image.
    private static func imageDimensions(at url: URL) -> (width: Double, height: Double)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let width = (properties[kCGImagePropertyPixelWidth as String] as? NSNumber)?.doubleValue,
              let height = (properties[kCGImagePropertyPixelHeight as String] as? NSNumber)?.doubleValue
        else { return nil }
        let rawOrientation = (properties[kCGImagePropertyOrientation as String] as? NSNumber)?.uint32Value
        let orientation = rawOrientation.flatMap(CGImagePropertyOrientation.init(rawValue:)) ?? .up
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return (width: height, height: width)
        default:
            return (width: width, height: height)
        }
    }
}
