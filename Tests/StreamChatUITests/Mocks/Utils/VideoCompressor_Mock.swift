//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatUI

final class VideoCompressor_Mock: VideoCompressor, @unchecked Sendable {
    /// The URL which is returned instead of the compressed video. When nil, the input URL is returned.
    var compressedURL: URL?

    /// The error which is thrown instead of compressing the video.
    var error: Error?

    /// The progress values which are reported before the compression finishes.
    var reportedProgress: [Double] = [0.5, 1]

    private(set) var compressVideoCallCount = 0
    private(set) var compressVideoCalledWithURLs: [URL] = []

    /// Called on the main actor just before the mock starts compressing.
    var onCompress: (() -> Void)?

    /// Suspends compression so other pending items can finish first.
    var compressionGate: (@MainActor () async -> Void)?

    /// The size reported by `estimatedFileLength(at:)`. `nil` keeps the default of unknown.
    var estimatedFileLengthResult: Int64?

    func estimatedFileLength(at url: URL) async -> Int64? {
        estimatedFileLengthResult
    }

    @MainActor
    func compressVideo(
        at url: URL,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        compressVideoCallCount += 1
        compressVideoCalledWithURLs.append(url)
        onCompress?()
        if let compressionGate {
            await compressionGate()
        }
        reportedProgress.forEach { progressHandler($0) }
        if let error = error {
            throw error
        }
        return compressedURL ?? url
    }
}
