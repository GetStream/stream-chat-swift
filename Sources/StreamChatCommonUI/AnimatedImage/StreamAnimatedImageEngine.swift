//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import QuartzCore
import UIKit

/// Plays GIFs by decoding frames ahead of time and driving them with a display link.
///
/// One display link per engine: frames are advanced from the real elapsed time, so playback
/// keeps the timing of the file instead of quantizing it to a shared tick.
@MainActor
final class StreamAnimatedImageEngine: AnimatedImageEngine {
    var onFrame: ((UIImage) -> Void)?

    private(set) var isPlaying = false

    /// The largest time step a single tick may advance, so a stall does not fast-forward
    /// through the whole animation.
    private static let maximumTickDelta: TimeInterval = 1

    private var source: GIFFrameSource?
    private var buffer: GIFFrameBuffer?
    private var displayLink: CADisplayLink?
    private var proxy: DisplayLinkProxy?
    private var currentIndex = 0
    private var accumulator: TimeInterval = 0
    private var hasDeliveredFirstFrame = false

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @discardableResult
    func load(data: Data, targetPixelSize: CGSize?) -> Bool {
        stop()
        source = nil
        buffer = nil
        currentIndex = 0
        accumulator = 0
        hasDeliveredFirstFrame = false

        guard let source = GIFFrameSource(data: data, targetPixelSize: targetPixelSize), source.frameCount > 1 else {
            return false
        }
        let buffer = GIFFrameBuffer(source: source)
        self.source = source
        self.buffer = buffer
        buffer.updatePlaybackIndex(0)
        return true
    }

    func play() {
        guard !isPlaying, let source, let buffer else { return }
        isPlaying = true
        let proxy = DisplayLinkProxy(listener: self)
        let displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.handleTick(_:)))
        displayLink.preferredFramesPerSecond = Self.preferredFramesPerSecond(frameDelays: source.frameDelays)
        displayLink.add(to: .main, forMode: .common)
        self.proxy = proxy
        self.displayLink = displayLink
        buffer.updatePlaybackIndex(currentIndex)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        proxy = nil
        isPlaying = false
    }

    /// Advances playback by the elapsed time and delivers the frame that should be visible.
    ///
    /// Only frames that are already decoded are shown: when the next one is not ready the
    /// current frame is held and decoding is scheduled again.
    func advance(by delta: TimeInterval) {
        guard isPlaying, let source, let buffer else { return }
        guard hasDeliveredFirstFrame else {
            guard let frame = buffer.cachedFrame(at: currentIndex) else {
                buffer.updatePlaybackIndex(currentIndex)
                return
            }
            hasDeliveredFirstFrame = true
            accumulator = 0
            buffer.updatePlaybackIndex(currentIndex)
            onFrame?(frame)
            return
        }

        accumulator += min(max(delta, 0), Self.maximumTickDelta)
        var frameToDeliver: UIImage?
        var isWaitingForNextFrame = false
        while accumulator >= source.frameDelays[currentIndex] {
            let nextIndex = (currentIndex + 1) % source.frameCount
            guard let nextFrame = buffer.cachedFrame(at: nextIndex) else {
                accumulator = min(accumulator, source.frameDelays[currentIndex])
                isWaitingForNextFrame = true
                break
            }
            accumulator -= source.frameDelays[currentIndex]
            currentIndex = nextIndex
            frameToDeliver = nextFrame
        }

        if frameToDeliver != nil || isWaitingForNextFrame {
            buffer.updatePlaybackIndex(currentIndex)
        }
        if let frameToDeliver {
            onFrame?(frameToDeliver)
        }
    }

    // MARK: - Private

    /// Caps the tick rate to what the animation actually needs, so a 10 fps GIF does not wake
    /// the display link 120 times a second.
    private static func preferredFramesPerSecond(frameDelays: [TimeInterval]) -> Int {
        guard let shortestDelay = frameDelays.filter({ $0 > 0 }).min() else { return 10 }
        return min(60, max(10, Int((1 / shortestDelay).rounded(.up))))
    }

    @objc private func handleMemoryWarning() {
        buffer?.purge(keeping: currentIndex)
    }
}

/// Keeps the display link from retaining the engine: the link retains its target, so the
/// engine is only reachable weakly and a leaked link tears itself down on the next tick.
@MainActor
private final class DisplayLinkProxy: NSObject {
    private weak var listener: StreamAnimatedImageEngine?

    init(listener: StreamAnimatedImageEngine) {
        self.listener = listener
        super.init()
    }

    @objc func handleTick(_ displayLink: CADisplayLink) {
        guard let listener else {
            displayLink.invalidate()
            return
        }
        listener.advance(by: displayLink.targetTimestamp - displayLink.timestamp)
    }
}
