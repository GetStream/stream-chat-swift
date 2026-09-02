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
    /// `AVAssetExportPreset1280x720` for downscaling the videos to a fixed resolution.
    public init(exportPreset: String) {
        self.exportPreset = exportPreset
    }

    /// The videos are uploaded as they are, without being compressed.
    public static let original = Self(exportPreset: AVAssetExportPresetPassthrough)

    /// The videos are compressed to the smallest file size.
    public static let low = Self(exportPreset: AVAssetExportPresetLowQuality)

    /// The videos are compressed to a lower resolution, which results in a smaller file.
    public static let medium = Self(exportPreset: AVAssetExportPresetMediumQuality)

    /// The videos keep their resolution and are only transcoded to H.264. This is the default.
    public static let high = Self(exportPreset: AVAssetExportPresetHighestQuality)
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
    @MainActor
    func compressVideo(
        at url: URL,
        quality: VideoCompressionQuality,
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
