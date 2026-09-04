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
    ///
    /// Use it for presets which are not covered by the provided qualities, for example
    /// `AVAssetExportPreset960x540` for smaller files, or `AVAssetExportPresetHEVC1920x1080`
    /// for keeping more detail at the same file size where HEVC playback is acceptable.
    public init(exportPreset: String) {
        self.exportPreset = exportPreset
    }

    /// The videos are uploaded as they are, without being compressed.
    public static let original = Self(exportPreset: AVAssetExportPresetPassthrough)

    /// The videos are scaled down to at most 720p. This is the default.
    ///
    /// It is the only quality which reliably makes a recording from a modern phone smaller,
    /// because both 1080p and 4K recordings are scaled down.
    public static let hd720p = Self(exportPreset: AVAssetExportPreset1280x720)

    /// The videos are scaled down to at most 1080p.
    ///
    /// A 1080p recording keeps its resolution, so it is only transcoded to H.264. That can
    /// make it bigger than the original when the original is HEVC, in which case the original
    /// is uploaded instead.
    public static let hd1080p = Self(exportPreset: AVAssetExportPreset1920x1080)
}

/// The errors which can occur while a video is being compressed.
enum VideoCompressionError: Error {
    /// The video cannot be compressed with the requested quality.
    case unsupportedQuality(VideoCompressionQuality)
}

/// A type which compresses the videos that are added as attachments to the composer.
///
/// It is not public yet, so that only `Components.videoCompressionQuality` has to be
/// supported as configuration. It exists to keep the compression testable.
protocol VideoCompressing: Sendable {
    /// - Parameter maximumFileSize: The size the result should stay below, when known. It is
    /// only a hint to `AVAssetExportSession`, which can still exceed it.
    @MainActor
    func compressVideo(
        at url: URL,
        quality: VideoCompressionQuality,
        maximumFileSize: Int64?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL
}

/// Compresses videos by transcoding them with `AVAssetExportSession`.
struct StreamVideoCompressor: VideoCompressing {
    /// How often the progress of the compression is reported.
    private let progressUpdateInterval: TimeInterval

    /// The container format of the compressed video.
    private let outputFileType: AVFileType = .mp4

    init(progressUpdateInterval: TimeInterval = 0.1) {
        self.progressUpdateInterval = progressUpdateInterval
    }

    @MainActor
    func compressVideo(
        at url: URL,
        quality: VideoCompressionQuality,
        maximumFileSize: Int64?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        let asset = AVURLAsset(url: url)
        guard let session = AVAssetExportSession(asset: asset, presetName: quality.exportPreset) else {
            throw VideoCompressionError.unsupportedQuality(quality)
        }
        session.shouldOptimizeForNetworkUse = true
        if let maximumFileSize = maximumFileSize, maximumFileSize > 0 {
            // Scaling the resolution down does not bound the file size of a long video, so the
            // export is additionally asked to aim for a size which can still be uploaded. The
            // limit is documented as one the export may exceed, hence the headroom.
            session.fileLengthLimit = Int64(Double(maximumFileSize) * 0.9)
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

    private func makeOutputURL(for inputURL: URL) throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = inputURL.deletingPathExtension().lastPathComponent
        return directory
            .appendingPathComponent(fileName.isEmpty ? UUID().uuidString : fileName)
            .appendingPathExtension("mp4")
    }
}
