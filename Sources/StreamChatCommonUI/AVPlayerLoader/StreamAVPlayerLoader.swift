//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamChat
import UniformTypeIdentifiers

@available(iOS 14.0, *)
@MainActor public class StreamAVPlayerLoader {
    private let url: URL
    private let mediaLoader: MediaLoader
    private let avPlayerProvider: AVPlayerProvider
    private let cache: StreamVideoCache?
    private let policy: VideoAttachmentCachingPolicy?

    public init(
        url: URL,
        mediaLoader: MediaLoader,
        avPlayerProvider: AVPlayerProvider,
        cache: StreamVideoCache?,
        policy: VideoAttachmentCachingPolicy?
    ) {
        self.url = url
        self.mediaLoader = mediaLoader
        self.avPlayerProvider = avPlayerProvider
        self.cache = cache
        self.policy = policy
    }

    public func load() async throws -> AVPlayer {
        guard let cache, let policy, policy.maxCacheSize > 0,
              !url.isFileURL, isContentTypeAllowed(url, policy: policy) else {
            return try await loadFromRemote()
        }

        let key = url.path
        let fileExtension = url.pathExtension.isEmpty ? "mp4" : url.pathExtension

        if let localURL = await cache.completedFileURL(forKey: key, fileExtension: fileExtension) {
            if await isPlayable(localURL) {
                return try await loadPlayer(from: MediaLoaderVideoAsset(asset: AVURLAsset(url: localURL)))
            }
            log.debug("Cached video is not playable; evicting and streaming from remote")
            await cache.remove(forKey: key, fileExtension: fileExtension)
        }

        let fileRequest: MediaLoaderFileRequest
        do {
            fileRequest = try await mediaLoader.loadFileRequest(for: url)
        } catch {
            log.debug("Video cache file request failed; streaming without caching: \(error)")
            return try await loadFromRemote()
        }

        let asset = StreamVideoAsset(
            originalURL: url,
            origin: fileRequest.urlRequest,
            fileExtension: fileExtension,
            cache: cache
        )
        return try await loadPlayer(from: MediaLoaderVideoAsset(asset: asset))
    }

    private func isContentTypeAllowed(_ url: URL, policy: VideoAttachmentCachingPolicy) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else { return false }
        return policy.allowedContentTypes.contains { type.conforms(to: $0) }
    }

    func isPlayable(_ url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            let asset = AVURLAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["playable"]) {
                continuation.resume(
                    returning: asset.statusOfValue(forKey: "playable", error: nil) == .loaded && asset.isPlayable
                )
            }
        }
    }

    private func loadFromRemote() async throws -> AVPlayer {
        let videoAsset = try await mediaLoader.loadVideoAsset(at: url)
        return try await loadPlayer(from: videoAsset)
    }

    private func loadPlayer(from videoAsset: MediaLoaderVideoAsset) async throws -> AVPlayer {
        try await withCheckedThrowingContinuation { continuation in
            avPlayerProvider.player(from: videoAsset) {
                continuation.resume(with: $0)
            }
        }
    }
}
