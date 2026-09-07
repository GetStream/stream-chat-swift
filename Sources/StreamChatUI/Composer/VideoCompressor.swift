//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// The quality which is used when the videos added to the composer are compressed.
public struct VideoCompressionQuality: Equatable, Sendable {
    /// The `AVAssetExportSession` preset which is used for the compression.
    public let exportPreset: String

    /// Creates a compression quality which is backed by the given `AVAssetExportSession` preset.
    public init(exportPreset: String) {
        self.exportPreset = exportPreset
    }

    /// The videos are uploaded as they are, without being compressed.
    public static let original = Self(exportPreset: AVAssetExportPresetPassthrough)

    /// The videos are compressed to the smallest file size.
    public static let low = Self(exportPreset: AVAssetExportPresetLowQuality)

    /// The videos are compressed to a size which is suitable for sharing in a chat.
    public static let medium = Self(exportPreset: AVAssetExportPresetMediumQuality)

    /// The videos keep a quality close to the original one, but are still transcoded to H.264.
    public static let high = Self(exportPreset: AVAssetExportPresetHighestQuality)
}

/// The errors which can occur while a video is being compressed.
public enum VideoCompressionError: Error {
    /// The video cannot be compressed with the requested quality.
    case unsupportedQuality(VideoCompressionQuality)
}

/// A type which compresses the videos that are added as attachments to the composer.
public protocol VideoCompressor: Sendable {
    /// Compresses the video at the given location.
    ///
    /// - Parameters:
    ///   - url: The local file URL of the video which should be compressed.
    ///   - quality: The quality which the compressed video should have.
    ///   - progressHandler: Called with the progress of the compression, a value between 0 and 1.
    /// - Returns: The local file URL of the compressed video.
    @MainActor
    func compressVideo(
        at url: URL,
        quality: VideoCompressionQuality,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL

    /// Predicts the file size of the video after compressing it with the given quality.
    ///
    /// Returns `nil` when the size cannot be estimated.
    func estimateCompressedFileSize(
        at url: URL,
        quality: VideoCompressionQuality
    ) async -> Int64?
}

public extension VideoCompressor {
    func estimateCompressedFileSize(
        at url: URL,
        quality: VideoCompressionQuality
    ) async -> Int64? {
        nil
    }
}

/// The default video compressor, which transcodes videos with `AVAssetExportSession`.
public struct StreamVideoCompressor: VideoCompressor {
    /// How often the progress of the compression is reported.
    public var progressUpdateInterval: TimeInterval

    /// The container format of the compressed video.
    public var outputFileType: AVFileType

    public init(
        progressUpdateInterval: TimeInterval = 0.1,
        outputFileType: AVFileType = .mp4
    ) {
        self.progressUpdateInterval = progressUpdateInterval
        self.outputFileType = outputFileType
    }

    @MainActor
    public func compressVideo(
        at url: URL,
        quality: VideoCompressionQuality,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let asset = AVURLAsset(url: url)
        guard let session = AVAssetExportSession(asset: asset, presetName: quality.exportPreset) else {
            throw VideoCompressionError.unsupportedQuality(quality)
        }
        session.shouldOptimizeForNetworkUse = true

        let outputURL = try makeOutputURL(for: url)
        let progressTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(progressUpdateInterval * 1_000_000_000))
                guard !Task.isCancelled else { return }
                progressHandler(Double(session.progress))
            }
        }
        defer { progressTask.cancel() }

        do {
            try await session.export(to: outputURL, as: outputFileType)
        } catch {
            try? FileManager.default.removeItem(at: outputURL.deletingLastPathComponent())
            throw error
        }
        progressHandler(1)
        return outputURL
    }

    public func estimateCompressedFileSize(
        at url: URL,
        quality: VideoCompressionQuality
    ) async -> Int64? {
        if quality == .original {
            return (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value
        }
        let asset = AVURLAsset(url: url)
        guard let session = AVAssetExportSession(asset: asset, presetName: quality.exportPreset) else {
            return estimatedSizeFromDuration(of: asset, quality: quality)
        }
        session.shouldOptimizeForNetworkUse = true
        session.outputFileType = outputFileType
        let duration = asset.duration
        if duration.isNumeric, duration.seconds > 0 {
            session.timeRange = CMTimeRange(start: .zero, duration: duration)
        }
        let estimatedLength: Int64 = await withCheckedContinuation { continuation in
            session.estimateOutputFileLength { length, error in
                continuation.resume(returning: error == nil ? length : 0)
            }
        }
        if estimatedLength > 0 {
            return estimatedLength
        }
        return estimatedSizeFromDuration(of: asset, quality: quality)
    }

    private func estimatedSizeFromDuration(
        of asset: AVAsset,
        quality: VideoCompressionQuality
    ) -> Int64? {
        let seconds = CMTimeGetSeconds(asset.duration)
        guard seconds.isFinite, seconds > 0 else { return nil }
        return Int64(seconds * typicalBitRate(for: quality, pixelCount: videoPixelCount(of: asset)) / 8)
    }

    /// Pixel count of the first video track, used to scale the highest-quality bitrate.
    private func videoPixelCount(of asset: AVAsset) -> Int {
        guard let track = asset.tracks(withMediaType: .video).first else {
            return 1920 * 1080
        }
        let size = track.naturalSize
        return max(1, Int(abs(size.width * size.height)))
    }

    /// Typical output bitrates for Apple's export presets.
    ///
    /// Low and medium map to fairly fixed resolutions, so they stay constant.
    /// Highest quality keeps the source resolution, so the bitrate scales with it.
    private func typicalBitRate(for quality: VideoCompressionQuality, pixelCount: Int) -> Double {
        switch quality.exportPreset {
        case AVAssetExportPresetLowQuality:
            return 500_000
        case AVAssetExportPresetMediumQuality:
            return 3_000_000
        case AVAssetExportPresetHighestQuality:
            let scale = max(0.5, min(4.0, Double(pixelCount) / Double(1920 * 1080)))
            return 12_000_000 * scale
        default:
            return 6_000_000
        }
    }

    private func makeOutputURL(for inputURL: URL) throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = inputURL.deletingPathExtension().lastPathComponent
        return directory
            .appendingPathComponent(fileName.isEmpty ? UUID().uuidString : fileName)
            .appendingPathExtension(outputFileType.fileExtension)
    }
}

private extension AVFileType {
    var fileExtension: String {
        switch self {
        case .mov:
            return "mov"
        case .m4v:
            return "m4v"
        default:
            return "mp4"
        }
    }
}
