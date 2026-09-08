//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import StreamChat
import UIKit

private let composerMediaProgressUpdateInterval: TimeInterval = 0.1
private let composerMediaPreviewMaxPixelSize = 300

// Loads photos-picker files, previews, and metadata for the composer.
@MainActor
protocol ComposerMediaLoading: AnyObject {
    var videoTypeIdentifier: String { get }

    func loadMedia(
        from itemProvider: NSItemProvider,
        progressHandler: @escaping (_ progress: Double, _ isCloudDownload: Bool) -> Void
    ) async -> SelectedMediaItem?

    func loadPreviewImage(from itemProvider: NSItemProvider) async -> UIImage?

    func imageThumbnail(at url: URL) async -> UIImage?
    func videoThumbnail(at url: URL) async -> UIImage?
    func loadVideoMetadata(at url: URL) async -> VideoMetadata
    func imageDimensions(at url: URL) -> (width: Double, height: Double)?
    func removeTemporaryMedia(at url: URL)
}

// The default loader, which copies picker files, builds previews, and reads metadata.
@MainActor
final class ComposerMediaLoader: ComposerMediaLoading {
    let videoTypeIdentifier = "public.movie"
    let imageTypeIdentifier = "public.image"

    func loadMedia(
        from itemProvider: NSItemProvider,
        progressHandler: @escaping (_ progress: Double, _ isCloudDownload: Bool) -> Void
    ) async -> SelectedMediaItem? {
        let isVideo = itemProvider.hasItemConformingToTypeIdentifier(videoTypeIdentifier)
        let typeIdentifier = isVideo ? videoTypeIdentifier : imageTypeIdentifier
        let loadProgress = MediaLoadProgress()
        let progressTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(composerMediaProgressUpdateInterval * 1_000_000_000))
                guard !Task.isCancelled else { return }
                guard let fractionCompleted = loadProgress.observedFractionCompleted() else { continue }
                progressHandler(fractionCompleted, loadProgress.isCloudDownload)
            }
        }
        defer { progressTask.cancel() }

        let media: SelectedMediaItem? = await withCheckedContinuation { continuation in
            loadProgress.progress = itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                guard let url = url else {
                    log.error("Failed to load the media selected in the photos picker: \(error?.localizedDescription ?? "unknown error")")
                    continuation.resume(returning: nil)
                    return
                }
                do {
                    // The provided file is deleted as soon as this closure returns, so it needs
                    // to be copied to a location which is owned by the composer.
                    let localURL = try Self.copyToTemporaryLocation(url)
                    continuation.resume(returning: SelectedMediaItem(url: localURL, type: isVideo ? .video : .image))
                } catch {
                    log.error("Failed to copy the media selected in the photos picker: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
        guard let media else { return nil }
        if loadProgress.isCloudDownload {
            progressHandler(1, true)
        }
        return media
    }

    func loadPreviewImage(from itemProvider: NSItemProvider) async -> UIImage? {
        if itemProvider.hasItemConformingToTypeIdentifier(videoTypeIdentifier) {
            return await loadVideoPreviewImage(from: itemProvider)
        }
        if let preview = await loadSystemPreviewImage(
            from: itemProvider,
            options: [NSItemProviderPreferredImageSizeKey: NSValue(cgSize: CGSize(
                width: composerMediaPreviewMaxPixelSize,
                height: composerMediaPreviewMaxPixelSize
            ))],
            toneMap: true
        ) {
            return preview
        }
        if itemProvider.canLoadObject(ofClass: UIImage.self),
           let image = await loadObjectImage(from: itemProvider) {
            return Self.sdrPreviewImage(from: image)
        }
        guard itemProvider.hasItemConformingToTypeIdentifier(imageTypeIdentifier) else { return nil }
        return await loadImageDataThumbnail(from: itemProvider)
    }

    // Decoding a full-size photo is expensive, so it happens off the main actor.
    // The file is read by ImageIO instead of being loaded into memory as a whole.
    func imageThumbnail(at url: URL) async -> UIImage? {
        await Self.makeImageThumbnail(at: url)
    }

    func videoThumbnail(at url: URL) async -> UIImage? {
        await Self.makeVideoThumbnail(at: url)
    }

    func loadVideoMetadata(at url: URL) async -> VideoMetadata {
        await Self.makeVideoMetadata(at: url)
    }

    // Reads the dimensions from the image's metadata, without decoding the whole image.
    func imageDimensions(at url: URL) -> (width: Double, height: Double)? {
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

    func removeTemporaryMedia(at url: URL) {
        Self.removeTemporaryMedia(at: url)
    }

    private func loadVideoPreviewImage(from itemProvider: NSItemProvider) async -> UIImage? {
        if let preview = await loadSystemPreviewImage(from: itemProvider, options: [:], toneMap: false) {
            return preview
        }
        return await loadSystemPreviewImage(
            from: itemProvider,
            options: [NSItemProviderPreferredImageSizeKey: NSValue(cgSize: CGSize(
                width: composerMediaPreviewMaxPixelSize,
                height: composerMediaPreviewMaxPixelSize
            ))],
            toneMap: false
        )
    }

    private func loadSystemPreviewImage(
        from itemProvider: NSItemProvider,
        options: [AnyHashable: Any],
        toneMap: Bool
    ) async -> UIImage? {
        await withCheckedContinuation { continuation in
            itemProvider.loadPreviewImage(options: options) { object, _ in
                continuation.resume(returning: Self.uiImage(fromPreview: object, toneMap: toneMap))
            }
        }
    }

    private func loadObjectImage(from itemProvider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { continuation in
            itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                continuation.resume(returning: image as? UIImage)
            }
        }
    }

    private func loadImageDataThumbnail(from itemProvider: NSItemProvider) async -> UIImage? {
        let typeIdentifier = imageTypeIdentifier
        return await withCheckedContinuation { continuation in
            itemProvider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
                continuation.resume(returning: data.flatMap { Self.thumbnail(fromImageData: $0) })
            }
        }
    }

    private nonisolated static func makeImageThumbnail(at url: URL) async -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else { return nil }
        return thumbnail(from: source, maxPixelSize: composerMediaPreviewMaxPixelSize)
    }

    private nonisolated static func makeVideoThumbnail(at url: URL) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(
                width: composerMediaPreviewMaxPixelSize,
                height: composerMediaPreviewMaxPixelSize
            )
            generator.generateCGImagesAsynchronously(
                forTimes: [NSValue(time: .zero)]
            ) { _, image, _, _, _ in
                continuation.resume(returning: image.map { UIImage(cgImage: $0) })
            }
        }
    }

    private nonisolated static func makeVideoMetadata(at url: URL) async -> VideoMetadata {
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
                    let (width, height) = videoDimensions(from: track)
                    metadata.width = width
                    metadata.height = height
                }
                continuation.resume(returning: metadata)
            }
        }
    }

    private nonisolated static func copyToTemporaryLocation(_ url: URL) throws -> URL {
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

    private nonisolated static func removeTemporaryMedia(at url: URL) {
        let directory = url.deletingLastPathComponent()
        if UUID(uuidString: directory.lastPathComponent) != nil {
            try? FileManager.default.removeItem(at: directory)
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // Video posters are not tone-mapped, because redrawing them often produces a black frame.
    private nonisolated static func uiImage(fromPreview object: NSSecureCoding?, toneMap: Bool) -> UIImage? {
        let image: UIImage?
        if let preview = object as? UIImage {
            image = preview
        } else if let data = object as? Data {
            image = thumbnail(fromImageData: data)
        } else if let object {
            let anyObject = object as AnyObject
            guard CFGetTypeID(anyObject) == CGImage.typeID else { return nil }
            image = UIImage(cgImage: unsafeDowncast(anyObject, to: CGImage.self))
        } else {
            return nil
        }
        guard let image else { return nil }
        return toneMap ? sdrPreviewImage(from: image) : image
    }

    private nonisolated static func thumbnail(
        fromImageData data: Data,
        maxPixelSize: Int = composerMediaPreviewMaxPixelSize
    ) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        return thumbnail(from: source, maxPixelSize: maxPixelSize)
            ?? UIImage(data: data).map { sdrPreviewImage(from: $0) }
    }

    private nonisolated static func thumbnail(from source: CGImageSource, maxPixelSize: Int) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private nonisolated static func sdrPreviewImage(from image: UIImage) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        guard pixelWidth > 0, pixelHeight > 0 else { return image }
        let maxDimension = CGFloat(composerMediaPreviewMaxPixelSize)
        let scale = min(maxDimension / pixelWidth, maxDimension / pixelHeight, 1)
        let target = CGSize(
            width: max(1, (pixelWidth * scale).rounded()),
            height: max(1, (pixelHeight * scale).rounded())
        )
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = true
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private nonisolated static func videoDimensions(from track: AVAssetTrack) -> (Double, Double) {
        let size = track.naturalSize
        let transform = track.preferredTransform
        if transform.a == 0 && abs(transform.b) == 1 && abs(transform.c) == 1 && transform.d == 0 {
            return (Double(size.height), Double(size.width))
        }
        return (Double(size.width), Double(size.height))
    }
}

// The properties of a video which the backend needs for rendering it.
struct VideoMetadata: Sendable {
    var duration: TimeInterval?
    var width: Double?
    var height: Double?
}
