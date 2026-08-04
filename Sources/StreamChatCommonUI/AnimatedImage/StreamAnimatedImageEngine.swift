//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ImageIO
import StreamChat
import UIKit
import UniformTypeIdentifiers

/// Plays GIFs with ImageIO's own animation driver.
///
/// ImageIO owns the decoding, the frame timing and the loop counting: the engine only forwards
/// the frames it hands out and switches the playback off again.
@MainActor
final class StreamAnimatedImageEngine: AnimatedImageEngine {
    /// One per playback session.
    ///
    /// ImageIO retains its block until the block asks it to stop, so stopping means flipping
    /// this flag and letting the next callback tear the session down.
    private final class PlaybackToken: Sendable {
        let shouldStop = AllocatedUnfairLock(false)
    }

    var onFrame: ((UIImage) -> Void)?

    private(set) var isPlaying = false

    private var data: Data?
    private var currentToken: PlaybackToken?
    private var lastDeliveredIndex = 0

    @discardableResult
    func load(data: Data, targetPixelSize: CGSize?) -> Bool {
        stop()
        self.data = nil
        lastDeliveredIndex = 0
        guard Self.isAnimatableGIF(data) else { return false }
        self.data = data
        return true
    }

    func play() {
        guard !isPlaying, let data else { return }
        let token = PlaybackToken()
        currentToken = token
        isPlaying = true

        var options: [CFString: Any] = [kCGImageAnimationLoopCount: Double.infinity]
        if lastDeliveredIndex > 0 {
            options[kCGImageAnimationStartIndex] = lastDeliveredIndex
        }

        let status = CGAnimateImageDataWithBlock(
            data as CFData,
            options as CFDictionary
        ) { @Sendable [weak self] index, cgImage, stop in
            guard let self, !token.shouldStop.value else {
                stop.pointee = true
                return
            }
            let frame = UIImage(cgImage: cgImage)
            Self.onMain {
                self.deliver(frame, at: index, token: token)
            }
        }

        guard status == noErr else {
            log.error("Failed to animate image data, status: \(status)")
            currentToken = nil
            isPlaying = false
            return
        }
    }

    func stop() {
        currentToken?.shouldStop.value = true
        currentToken = nil
        isPlaying = false
    }

    // MARK: - Private

    private func deliver(_ frame: UIImage, at index: Int, token: PlaybackToken) {
        guard isPlaying, currentToken === token else { return }
        lastDeliveredIndex = index
        onFrame?(frame)
    }

    private static func isAnimatableGIF(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let uti = CGImageSourceGetType(source) as String? else { return false }
        let isGIF: Bool
        if #available(iOS 14, *) {
            isGIF = uti == UTType.gif.identifier
        } else {
            isGIF = uti == "com.compuserve.gif"
        }
        return isGIF && CGImageSourceGetCount(source) > 1
    }

    /// ImageIO documents the animation block to run on the main queue; the hop keeps the frame
    /// delivery on the main actor even if it ever does not.
    private nonisolated static func onMain(_ body: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(body)
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated(body)
            }
        }
    }
}
