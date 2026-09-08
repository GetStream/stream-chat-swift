//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// The errors which can occur while a video is being compressed.
enum VideoCompressionError: Error {
    /// The export finished without producing a compressed video.
    case exportFailed
}

/// A type which compresses the videos that are added as attachments to the composer.
protocol VideoCompressor: Sendable {
    /// Compresses the video at the given location.
    ///
    /// - Parameters:
    ///   - url: The local file URL of the video which should be compressed.
    ///   - progressHandler: Called with the progress of the compression, a value between 0 and 1.
    ///     May be invoked off the main actor.
    /// - Returns: The local file URL of the compressed video.
    func compressVideo(
        at url: URL,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL
}

/// The default video compressor, which transcodes videos with `AVAssetExportSession`.
///
/// Uses `AVAssetExportPreset960x540` so camera videos become 540p H.264.
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
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let asset = AVURLAsset(url: url)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset960x540) else {
            throw VideoCompressionError.exportFailed
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
