//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// Decodes frames off the main thread. A GIF that fits the per-GIF and shared byte budgets is
// cached in full. Otherwise only a window of upcoming frames is kept, with frame 0 pinned so
// looping never starves. Lookups never decode: a missing frame makes the caller hold the
// previous one.
final class GIFFrameBuffer: Sendable {
    private enum Mode {
        case cacheAll
        case window
    }

    private struct State {
        var frames: [Int: UIImage] = [:]
        var pending: Set<Int> = []
        var failed: Set<Int> = []
        var generation = 0
        var mode: Mode
        var playbackIndex = 0
        var reservedBytes: Int
    }

    static let defaultByteBudget = 16 * 1024 * 1024
    // Caps the decoded bytes that all fully cached GIFs hold together.
    static let sharedByteBudget = 50 * 1024 * 1024
    static let sharedReservedBytes = AllocatedUnfairLock(0)

    private static let windowLength = 4

    private let source: GIFFrameSource
    private let sharedReservedBytes: AllocatedUnfairLock<Int>
    private let queue = DispatchQueue(label: "io.getstream.StreamChatCommonUI.GIFFrameBuffer", qos: .userInitiated)
    private let state: AllocatedUnfairLock<State>

    init(
        source: GIFFrameSource,
        byteBudget: Int = GIFFrameBuffer.defaultByteBudget,
        sharedByteBudget: Int = GIFFrameBuffer.sharedByteBudget,
        sharedReservedBytes: AllocatedUnfairLock<Int> = GIFFrameBuffer.sharedReservedBytes
    ) {
        self.source = source
        self.sharedReservedBytes = sharedReservedBytes
        let totalBytes = source.frameCount * source.bytesPerFrame
        let cachesAll = totalBytes <= byteBudget && sharedReservedBytes.withLock { reservedBytes in
            guard reservedBytes + totalBytes <= sharedByteBudget else { return false }
            reservedBytes += totalBytes
            return true
        }
        state = AllocatedUnfairLock(State(mode: cachesAll ? .cacheAll : .window, reservedBytes: cachesAll ? totalBytes : 0))
    }

    deinit {
        let releasedBytes = state.withLock { $0.reservedBytes }
        sharedReservedBytes.withLock { $0 -= releasedBytes }
    }

    func cachedFrame(at index: Int) -> UIImage? {
        state.withLock { $0.frames[index] }
    }

    // Records the frame being displayed and schedules decoding of the missing frames, the
    // ones needed soonest first.
    func updatePlaybackIndex(_ index: Int) {
        let frameCount = source.frameCount
        let (missing, generation): ([Int], Int) = state.withLock { state in
            state.playbackIndex = index
            let candidates: [Int]
            switch state.mode {
            case .cacheAll:
                guard state.frames.count + state.pending.count + state.failed.count < frameCount else {
                    return ([], state.generation)
                }
                candidates = (0..<frameCount).map { (index + $0) % frameCount }
            case .window:
                state.frames = state.frames.filter { Self.isInWindow($0.key, around: index, frameCount: frameCount) }
                candidates = Self.windowIndices(around: index, frameCount: frameCount)
            }
            let missing = candidates.filter {
                state.frames[$0] == nil && !state.pending.contains($0) && !state.failed.contains($0)
            }
            state.pending.formUnion(missing)
            return (missing, state.generation)
        }
        for index in missing {
            scheduleDecoding(of: index, generation: generation)
        }
    }

    // Skips queued decoding and discards results still in flight. Decoded frames are kept.
    func cancelPendingDecoding() {
        state.withLock { state in
            state.generation += 1
            state.pending.removeAll()
        }
    }

    // Drops every decoded frame except the given one and stops caching the whole animation.
    func purge(keeping index: Int) {
        let releasedBytes = state.withLock { state in
            state.generation += 1
            state.pending.removeAll()
            state.mode = .window
            state.frames = state.frames.filter { $0.key == index }
            defer { state.reservedBytes = 0 }
            return state.reservedBytes
        }
        sharedReservedBytes.withLock { $0 -= releasedBytes }
    }

    static func windowIndices(around index: Int, frameCount: Int) -> [Int] {
        var indices = (0..<min(windowLength, frameCount)).map { (index + $0) % frameCount }
        if !indices.contains(0) {
            indices.append(0)
        }
        return indices
    }

    // MARK: - Private

    private static func isInWindow(_ index: Int, around playbackIndex: Int, frameCount: Int) -> Bool {
        index == 0 || (index - playbackIndex + frameCount) % frameCount < windowLength
    }

    private func scheduleDecoding(of index: Int, generation: Int) {
        queue.async { [weak self] in
            guard let self, state.withLock({ $0.generation == generation }) else { return }
            let frame = source.decodeFrame(at: index)
            state.withLock { state in
                guard state.generation == generation else { return }
                state.pending.remove(index)
                guard let frame else {
                    state.failed.insert(index)
                    return
                }
                guard state.mode == .cacheAll
                    || Self.isInWindow(index, around: state.playbackIndex, frameCount: source.frameCount) else { return }
                state.frames[index] = frame
            }
        }
    }
}
