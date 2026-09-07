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

    /// The videos are compressed to the smallest file size.
    public static let low = Self(exportPreset: AVAssetExportPresetLowQuality)

    /// The videos are compressed to a size which is suitable for sharing in a chat.
    public static let medium = Self(exportPreset: AVAssetExportPresetMediumQuality)

    /// The videos are scaled to 720p H.264, matching the system photos picker.
    public static let high = Self(exportPreset: AVAssetExportPreset1280x720)
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
        if let fileLengthLimit = Self.estimatedFileLength(for: asset.duration, quality: quality) {
            session.fileLengthLimit = fileLengthLimit
        }

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

    /// Total bitrate used by the system photos picker for 720p H.264
    /// (~2.5 Mbps video + AAC), measured from Apple's own picker output.
    static let highQualityBitRate: Double = 2_700_000

    /// Typical bitrate of `AVAssetExportPresetMediumQuality`.
    static let mediumQualityBitRate: Double = 3_000_000

    /// Typical bitrate of `AVAssetExportPresetLowQuality`.
    static let lowQualityBitRate: Double = 500_000

    /// A low size estimate for the compressed video, based on duration and the
    /// bitrate of the given quality. Returns `nil` when the duration is unknown
    /// or the quality has no known bitrate.
    static func estimatedFileLength(for duration: CMTime, quality: VideoCompressionQuality) -> Int64? {
        guard let bitRate = bitRate(for: quality) else { return nil }
        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isFinite, seconds > 0 else { return nil }
        return Int64((seconds * bitRate / 8).rounded())
    }

    static func estimatedFileLength(at url: URL, quality: VideoCompressionQuality) -> Int64? {
        estimatedFileLength(for: AVURLAsset(url: url).duration, quality: quality)
    }

    private static func bitRate(for quality: VideoCompressionQuality) -> Double? {
        if quality == .high { return highQualityBitRate }
        if quality == .medium { return mediumQualityBitRate }
        if quality == .low { return lowQualityBitRate }
        return nil
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
