//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamChat

public class MockAudioPlayerObserver: AudioPlayerObserving {
    public private(set) var addTimeControlStatusObserverWaCalledWithObject: AVPlayer?
    public private(set) var addTimeControlStatusObserverWaCalledWithBlock: ((AVPlayer.TimeControlStatus?) -> Void)?

    public private(set) var addPeriodicTimeObserverWasCalledWithPlayer: AVPlayer?
    public private(set) var addPeriodicTimeObserverWasCalledWithInterval: CMTime?
    public private(set) var addPeriodicTimeObserverWasCalledWithQueue: DispatchQueue?
    public private(set) var addPeriodicTimeObserverWasCalledWithBlock: (() -> Void)?

    public private(set) var addStoppedPlaybackObserverWasCalledWithQueue: OperationQueue?
    public private(set) var addStoppedPlaybackObserverWasCalledWithBlock: ((AVPlayerItem) -> Void)?

    public init() {}

    public func addTimeControlStatusObserver(
        _ player: AVPlayer,
        using block: @escaping (AVPlayer.TimeControlStatus?) -> Void
    ) {
        addTimeControlStatusObserverWaCalledWithObject = player
        addTimeControlStatusObserverWaCalledWithBlock = block
    }

    public func addPeriodicTimeObserver(
        _ player: AVPlayer,
        forInterval interval: CMTime,
        queue: DispatchQueue?,
        using block: @escaping () -> Void
    ) {
        addPeriodicTimeObserverWasCalledWithPlayer = player
        addPeriodicTimeObserverWasCalledWithInterval = interval
        addPeriodicTimeObserverWasCalledWithQueue = queue
        addPeriodicTimeObserverWasCalledWithBlock = block
    }

    public func addStoppedPlaybackObserver(
        queue: OperationQueue?,
        using block: @escaping (AVPlayerItem) -> Void
    ) {
        addStoppedPlaybackObserverWasCalledWithQueue = queue
        addStoppedPlaybackObserverWasCalledWithBlock = block
    }
}
