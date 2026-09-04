//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatUI

final class VideoCompressor_Mock: VideoCompressing, @unchecked Sendable {
    /// The URL which is returned instead of the compressed video. When nil, the input URL is returned.
    var compressedURL: URL?

    /// The error which is thrown instead of compressing the video.
    var error: Error?

    /// The progress values which are reported before the compression finishes.
    var reportedProgress: [Double] = [0.5, 1]

    private(set) var compressVideoCallCount = 0
    private(set) var compressVideoCalledWith: [(url: URL, quality: VideoCompressionQuality, maximumFileSize: Int64?)] = []

    @MainActor
    func compressVideo(
        at url: URL,
        quality: VideoCompressionQuality,
        maximumFileSize: Int64?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        compressVideoCallCount += 1
        compressVideoCalledWith.append((url: url, quality: quality, maximumFileSize: maximumFileSize))
        reportedProgress.forEach { progressHandler($0) }
        if let error = error {
            throw error
        }
        return compressedURL ?? url
    }
}
