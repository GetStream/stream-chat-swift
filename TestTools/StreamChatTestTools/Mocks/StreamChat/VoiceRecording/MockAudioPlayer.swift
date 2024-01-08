//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public class MockAudioPlayer: AudioPlaying {

    public private(set) var subscribeWasCalledWithSubscriber: AudioPlayingDelegate?

    public private(set) var loadAssetWasCalledWithURL: URL?

    public private(set) var playWasCalled = false

    public private(set) var pauseWasCalled = false

    public private(set) var stopWasCalled = false

    public private(set) var updateRateWasCalledWithRate: AudioPlaybackRate?

    public private(set) var seekWasCalledWithTime: TimeInterval?

    public required init() {}

    public func subscribe(_ subscriber: AudioPlayingDelegate) {
        subscribeWasCalledWithSubscriber = subscriber
    }

    public func loadAsset(from url: URL) {
        loadAssetWasCalledWithURL = url
    }

    public func play() {
        playWasCalled = true
    }

    public func pause() {
        pauseWasCalled = true
    }

    public func stop() {
        stopWasCalled = true
    }

    public func updateRate(_ newRate: AudioPlaybackRate) {
        updateRateWasCalledWithRate = newRate
    }

    public func seek(to time: TimeInterval) {
        seekWasCalledWithTime = time
    }
}
