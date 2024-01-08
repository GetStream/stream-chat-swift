//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamChat

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

    public override var rate: Float {
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
        replaceCurrentItemWasCalled = true
        replaceCurrentItemWasCalledWithItem = item
        super.replaceCurrentItem(with: item)
    }

    override public func seek(
        to time: CMTime,
        toleranceBefore: CMTime,
        toleranceAfter: CMTime,
        completionHandler: @escaping (Bool) -> Void
    ) {
        seekWasCalledWithTime = time
        seekWasCalledWithToleranceBefore = toleranceBefore
        seekWasCalledWithToleranceAfter = toleranceAfter
        super.seek(
            to: time,
            toleranceBefore: toleranceBefore,
            toleranceAfter: toleranceAfter,
            completionHandler: { _ in completionHandler(!self.holdSeekCompletion) }
        )
    }
}
