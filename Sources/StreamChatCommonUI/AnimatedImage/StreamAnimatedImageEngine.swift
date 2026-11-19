//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import QuartzCore
import UIKit

// Plays GIFs from frames decoded ahead of time, advanced by the time elapsed between display
// link ticks.
@MainActor
final class StreamAnimatedImageEngine: AnimatedImageEngine {
    var onFrame: ((UIImage) -> Void)?
    var visibilityCheck: (() -> Bool)?

    private(set) var isPlaying = false

    // Keeps a stall from fast-forwarding through the whole animation.
    private static let maximumTickDelta: TimeInterval = 1
    // How often an invisible view checks whether it became visible again.
    private static let invisibleFramesPerSecond = 5

    private var source: GIFFrameSource?
    private var buffer: GIFFrameBuffer?
    private var displayLink: CADisplayLink?
    private var proxy: DisplayLinkProxy?
    private var playbackFramesPerSecond = 0
    private var lastTickTimestamp: CFTimeInterval?
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
        unload()
        guard let source = GIFFrameSource(data: data, targetPixelSize: targetPixelSize), source.frameCount > 1 else {
            return false
        }
        self.source = source
        buffer = GIFFrameBuffer(source: source)
        return true
    }

    func play() {
        guard !isPlaying, let source else { return }
        isPlaying = true
        lastTickTimestamp = nil
        playbackFramesPerSecond = Self.preferredFramesPerSecond(frameDelays: source.frameDelays)
        let proxy = DisplayLinkProxy(listener: self)
        let displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.handleTick(_:)))
        displayLink.preferredFramesPerSecond = playbackFramesPerSecond
        displayLink.add(to: .main, forMode: .common)
        self.proxy = proxy
        self.displayLink = displayLink
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        proxy = nil
        isPlaying = false
        buffer?.cancelPendingDecoding()
    }

    func unload() {
        stop()
        source = nil
        buffer = nil
        currentIndex = 0
        accumulator = 0
        hasDeliveredFirstFrame = false
    }

    func handleTick(timestamp: CFTimeInterval) {
        guard visibilityCheck?() ?? true else {
            lastTickTimestamp = nil
            setFramesPerSecond(Self.invisibleFramesPerSecond)
            return
        }
        setFramesPerSecond(playbackFramesPerSecond)
        let delta = lastTickTimestamp.map { timestamp - $0 } ?? 0
        lastTickTimestamp = timestamp
        advance(by: delta)
    }

    // Shows only decoded frames: when the next one is not ready, the current frame is held
    // and its decoding is scheduled again.
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

    // Ticks only as often as the animation needs: a 10 fps GIF does not wake the display
    // link 120 times a second.
    private static func preferredFramesPerSecond(frameDelays: [TimeInterval]) -> Int {
        guard let shortestDelay = frameDelays.filter({ $0 > 0 }).min() else { return 10 }
        return min(60, max(10, Int((1 / shortestDelay).rounded(.up))))
    }

    private func setFramesPerSecond(_ framesPerSecond: Int) {
        guard let displayLink, displayLink.preferredFramesPerSecond != framesPerSecond else { return }
        displayLink.preferredFramesPerSecond = framesPerSecond
    }

    @objc private func handleMemoryWarning() {
        buffer?.purge(keeping: currentIndex)
    }
}

// The display link retains its target, so the engine is held weakly and a leaked link
// invalidates itself on the next tick.
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
        listener.handleTick(timestamp: displayLink.timestamp)
    }
}
