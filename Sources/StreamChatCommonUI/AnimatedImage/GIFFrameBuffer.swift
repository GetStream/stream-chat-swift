//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Decodes GIF frames off the main thread and keeps them ready for playback.
///
/// Small animations are cached in full. Once they no longer fit the byte budget, only a
/// sliding window of upcoming frames is kept, with the first frame pinned so looping never
/// starves. Lookups never decode: a frame that is not cached yet is simply missing, and the
/// caller holds the previous one.
final class GIFFrameBuffer: Sendable {
    private enum Mode {
        case cacheAll
        case window
    }

    private struct State {
        var frames: [Int: UIImage] = [:]
        var pending: Set<Int> = []
        var generation = 0
        var mode: Mode
        var playbackIndex = 0
    }

    /// The number of decoded bytes a single animation may occupy before switching to a window.
    static let defaultByteBudget = 16 * 1024 * 1024

    /// The number of frames kept ready ahead of the one being displayed.
    private static let windowLength = 4

    private let source: GIFFrameSource
    private let queue = DispatchQueue(label: "io.getstream.StreamChatCommonUI.GIFFrameBuffer", qos: .userInitiated)
    private let state: AllocatedUnfairLock<State>

    init(source: GIFFrameSource, byteBudget: Int = GIFFrameBuffer.defaultByteBudget) {
        self.source = source
        let totalBytes = source.frameCount * source.bytesPerFrame
        state = AllocatedUnfairLock(State(mode: totalBytes <= byteBudget ? .cacheAll : .window))
    }

    /// The already decoded frame at the given index, if any.
    func cachedFrame(at index: Int) -> UIImage? {
        state.withLock { $0.frames[index] }
    }

    /// Records the frame being displayed and schedules decoding of the frames needed next.
    func updatePlaybackIndex(_ index: Int) {
        let (missing, generation): ([Int], Int) = state.withLock { state in
            state.playbackIndex = index
            let needed = neededIndices(around: index, mode: state.mode)
            if state.mode == .window {
                state.frames = state.frames.filter { needed.contains($0.key) }
            }
            let missing = needed.filter { state.frames[$0] == nil && !state.pending.contains($0) }
            state.pending.formUnion(missing)
            return (missing.sorted(), state.generation)
        }
        for index in missing {
            scheduleDecoding(of: index, generation: generation)
        }
    }

    /// Drops every decoded frame except the given one and stops caching the whole animation.
    ///
    /// In-flight decoding results are discarded, so a purge cannot be undone by work that
    /// was already scheduled.
    func purge(keeping index: Int) {
        state.withLock { state in
            state.generation += 1
            state.pending.removeAll()
            state.mode = .window
            state.frames = state.frames.filter { $0.key == index }
        }
    }

    // MARK: - Private

    private func neededIndices(around index: Int, mode: Mode) -> Set<Int> {
        guard mode == .window else { return Set(0..<source.frameCount) }
        var indices: Set<Int> = [0]
        for offset in 0..<Self.windowLength {
            indices.insert((index + offset) % source.frameCount)
        }
        return indices
    }

    private func scheduleDecoding(of index: Int, generation: Int) {
        queue.async { [weak self] in
            guard let self else { return }
            let frame = source.decodeFrame(at: index)
            state.withLock { state in
                state.pending.remove(index)
                guard state.generation == generation, let frame else { return }
                guard neededIndices(around: state.playbackIndex, mode: state.mode).contains(index) else { return }
                state.frames[index] = frame
            }
        }
    }
}
