//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamChat

public class MockAVPlayer: AVPlayer {
    public var playWasCalled = false

    public private(set) var pauseWasCalled = false

    public var replaceCurrentItemWasCalled = false
    public var replaceCurrentItemWasCalledWithItem: AVPlayerItem?

    public private(set) var rateWasUpdatedTo: Float?

    public private(set) var seekWasCalledWithTime: CMTime?
    public private(set) var seekWasCalledWithToleranceBefore: CMTime?
    public private(set) var seekWasCalledWithToleranceAfter: CMTime?
    public var holdSeekCompletion = false

    override public var rate: Float {
        didSet {
            rateWasUpdatedTo = rate
            mockPlayerObserver?.addPeriodicTimeObserverWasCalledWithBlock?()
        }
    }

    public var mockPlayerObserver: MockAudioPlayerObserver?

    override public func play() {
        playWasCalled = true
        super.play()
        mockPlayerObserver?.addTimeControlStatusObserverWaCalledWithBlock?(.playing)
    }

    override public func pause() {
        pauseWasCalled = true
        super.pause()
        mockPlayerObserver?.addTimeControlStatusObserverWaCalledWithBlock?(.paused)
    }

    override public func replaceCurrentItem(
        with item: AVPlayerItem?
    ) {
        StreamConcurrency.onMain {
            replaceCurrentItemWasCalled = true
            replaceCurrentItemWasCalledWithItem = item
        }
        super.replaceCurrentItem(with: item)
    }

    override public func seek(
        to time: CMTime,
        toleranceBefore: CMTime,
        toleranceAfter: CMTime,
        completionHandler: @escaping @Sendable(Bool) -> Void
    ) {
        StreamConcurrency.onMain {
            seekWasCalledWithTime = time
            seekWasCalledWithToleranceBefore = toleranceBefore
            seekWasCalledWithToleranceAfter = toleranceAfter
        }
        super.seek(
            to: time,
            toleranceBefore: toleranceBefore,
            toleranceAfter: toleranceAfter,
            completionHandler: { _ in
                StreamConcurrency.onMain {
                    completionHandler(!self.holdSeekCompletion)
                }
            }
        )
    }
}
