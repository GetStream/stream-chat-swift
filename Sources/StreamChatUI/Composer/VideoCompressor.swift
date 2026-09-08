//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamChat

/// The quality which is used when the videos added to the composer are compressed.
public struct VideoCompressionQuality: Equatable, Sendable {
    /// The `AVAssetExportSession` preset which is used for the compression.
    public let exportPreset: String

    /// Creates a compression quality which is backed by the given `AVAssetExportSession` preset.
    public init(exportPreset: String) {
        self.exportPreset = exportPreset
    }

    /// The videos are scaled down to 480p H.264.
    ///
    /// A 16:9 video becomes 640x360.
    public static let low = Self(exportPreset: AVAssetExportPreset640x480)

    /// The videos are scaled down to 720p H.264.
    public static let medium = Self(exportPreset: AVAssetExportPreset1280x720)

    /// The videos are scaled down to 1080p H.264.
    public static let high = Self(exportPreset: AVAssetExportPreset1920x1080)
}

/// The errors which can occur while a video is being compressed.
enum VideoCompressionError: Error {
    /// The video cannot be compressed with the requested quality.
    case unsupportedQuality(VideoCompressionQuality)
    /// The export finished without producing a compressed video.
    case exportFailed
}

/// A type which compresses the videos that are added as attachments to the composer.
protocol VideoCompressor: Sendable {
    /// Compresses the video at the given location.
    ///
    /// - Parameters:
    ///   - url: The local file URL of the video which should be compressed.
    ///   - quality: The quality which the compressed video should have.
    ///   - progressHandler: Called with the progress of the compression, a value between 0 and 1.
    ///     May be invoked off the main actor.
    /// - Returns: The local file URL of the compressed video.
    func compressVideo(
        at url: URL,
        quality: VideoCompressionQuality,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL
}

/// The default video compressor, which transcodes videos with `AVAssetExportSession`.
struct StreamVideoCompressor: VideoCompressor {
    /// How often the progress of the compression is reported.
    var progressUpdateInterval: TimeInterval

    /// The container format of the compressed video.
    var outputFileType: AVFileType

    init(
        progressUpdateInterval: TimeInterval = 0.1,
        outputFileType: AVFileType = .mp4
    ) {
        self.progressUpdateInterval = progressUpdateInterval
        self.outputFileType = outputFileType
    }

    func compressVideo(
        at url: URL,
        quality: VideoCompressionQuality,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let asset = AVURLAsset(url: url)
        guard let session = AVAssetExportSession(asset: asset, presetName: quality.exportPreset) else {
            throw VideoCompressionError.unsupportedQuality(quality)
        }
        session.shouldOptimizeForNetworkUse = true
        // `fileLengthLimit` is deliberately not set. The export stops writing as soon as the
        // limit is reached, which silently shortens the video instead of lowering its bitrate.
        // The size of the compressed file is validated once it is on disk instead.

        let outputURL = try makeOutputURL(for: url)
        let export = ExportSession(session)
        let progressTask = Task { [progressUpdateInterval] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(progressUpdateInterval * 1_000_000_000))
                guard !Task.isCancelled else { return }
                progressHandler(export.progress)
            }
        }
        defer { progressTask.cancel() }

        do {
            try await export.run(to: outputURL, as: outputFileType)
        } catch {
            try? FileManager.default.removeItem(at: outputURL.deletingLastPathComponent())
            throw error
        }
        progressHandler(1)
        return outputURL
    }

    /// Total bitrate used to estimate a 1080p H.264 export.
    static let highQualityBitRate: Double = 5_000_000

    /// Total bitrate used to estimate a 720p H.264 export.
    static let mediumQualityBitRate: Double = 2_700_000

    /// Total bitrate used to estimate a 480p H.264 export.
    static let lowQualityBitRate: Double = 1_000_000

    /// The expected size of the compressed video, based on duration and the
    /// bitrate of the given quality. Returns `nil` when the duration is unknown
    /// or the quality has no known bitrate.
    static func estimatedFileLength(for duration: CMTime, quality: VideoCompressionQuality) -> Int64? {
        guard let bitRate = bitRate(for: quality) else { return nil }
        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isFinite, seconds > 0 else { return nil }
        return Int64((seconds * bitRate / 8).rounded())
    }

    /// The duration is loaded asynchronously, so that reading it does not block the
    /// caller, which is usually the main actor.
    static func estimatedFileLength(at url: URL, quality: VideoCompressionQuality) async -> Int64? {
        let duration: CMTime? = await withCheckedContinuation { continuation in
            StreamAssetPropertyLoader().loadProperties(
                [AssetProperty(\AVURLAsset.duration)],
                of: AVURLAsset(url: url)
            ) { result in
                guard case .success(let asset) = result else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: asset.duration)
            }
        }
        guard let duration else { return nil }
        return estimatedFileLength(for: duration, quality: quality)
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

/// Runs an export session and reports its progress from another task.
///
/// `AVAssetExportSession` is not `Sendable`, but the export runs on its own
/// queue and only `progress` is read while it is in flight.
private final class ExportSession: @unchecked Sendable {
    private let session: AVAssetExportSession

    init(_ session: AVAssetExportSession) {
        self.session = session
    }

    var progress: Double {
        Double(session.progress)
    }

    func run(to outputURL: URL, as fileType: AVFileType) async throws {
        if #available(iOS 18.0, *) {
            // Passing no isolation lets several videos compress at the same
            // time instead of taking turns on the main actor.
            try await session.export(to: outputURL, as: fileType, isolation: nil)
            return
        }
        session.outputURL = outputURL
        session.outputFileType = fileType
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            session.exportAsynchronously { continuation.resume() }
        }
        switch session.status {
        case .completed:
            return
        case .cancelled:
            throw CancellationError()
        default:
            throw session.error ?? VideoCompressionError.exportFailed
        }
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
