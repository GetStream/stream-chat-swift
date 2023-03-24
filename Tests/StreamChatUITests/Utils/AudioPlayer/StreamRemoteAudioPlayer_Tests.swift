//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class StreamRemoteAudioPlayer_Tests: XCTestCase {
    private var audioPlayerDelegate: MockAudioPlayerDelegate!
    private var syncDebouncer: SyncDebouncer!
    private var assetPropertyLoader: MockAssetPropertyLoader!
    private var playerObserver: MockAudioPlayerObserver!
    private var player: MockAVPlayer!
    private var subject: StreamRemoteAudioPlayer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        audioPlayerDelegate = .init()
        syncDebouncer = .init()
        assetPropertyLoader = .init()
        playerObserver = .init()
        player = .init()
        subject = .init(
            debouncer: syncDebouncer,
            assetPropertyLoader: assetPropertyLoader,
            playerObserver: playerObserver,
            player: player
        )

        player.mockPlayerObserver = playerObserver
    }

    override func tearDownWithError() throws {
        subject = nil
        player = nil
        playerObserver = nil
        assetPropertyLoader = nil
        syncDebouncer = nil
        audioPlayerDelegate = nil
        try super.tearDownWithError()
    }

    // MARK: - init

    func test_init_addPeriodicTimeObserverWasCalledOnPlayerObserverWithExpectedInterval() {
        let expectedInterval = CMTime(
            seconds: 0.1,
            preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        )

        XCTAssertEqual(
            playerObserver.addPeriodicTimeObserverWasCalledWith?.interval,
            expectedInterval
        )
    }

    func test_init_addTimeControlStatusObserverWasCalledOnPlayerObserverWithExpectedValues() {
        XCTAssertEqual(
            playerObserver.addTimeControlStatusObserverWaCalledWith?.object,
            player
        )
    }

    func test_init_addStoppedPlaybackObserverWasCalledOnPlayerObserverWithExpectedValues() {
        XCTAssertNotNil(playerObserver.addStoppedPlaybackObserverWasCalledWith)
        XCTAssertNil(playerObserver.addStoppedPlaybackObserverWasCalledWith?.queue)
    }

    // MARK: - periodicTimerObserver

    func test_periodicTimerObserver_isSeekingIsFalse_delegateWasUpdatedWithExpectedContext() {
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(
            from: .init(string: "http://getstream.io"),
            andConnectDelegate: audioPlayerDelegate
        )

        player.rate = 2

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .double,
            isSeeking: false
        ))
    }

    func test_periodicTimerObserver_isSeekingIsTrue_theContextWasNotUpdated() {
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(
            from: .init(string: "http://getstream.io"),
            andConnectDelegate: audioPlayerDelegate
        )
        syncDebouncer.holdExecution = true
        subject.seek(to: 10)

        playerObserver.addPeriodicTimeObserverWasCalledWith?.block()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 100,
            currentTime: 10,
            state: .paused,
            rate: .zero,
            isSeeking: true
        ))
    }

    // MARK: - timeControlStatusObserver

    // MARK: newState: .paused

    func test_timeControlStatusObserver_newStateIsPausedCurrentStateIsNotLoaded_delegateWasNotCalled() {
        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.paused)

        XCTAssertNil(audioPlayerDelegate.didUpdateContextWasCalled?.context)
    }

    func test_timeControlStatusObserver_newStateIsPausedCurrentStateIsLoading_delegateWasCalledWithExpectedContext() {
        assetPropertyLoader.holdLoadProperty = true
        subject.loadAsset(
            from: URL(string: "http://getstream.io")!,
            andConnectDelegate: audioPlayerDelegate
        )

        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.paused)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 0,
            currentTime: 0,
            state: .paused,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_timeControlStatusObserver_newStateIsPausedCurrentStateIsPlaying_delegateWasCalledWithExpectedContext() {
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(
            from: URL(string: "http://getstream.io")!,
            andConnectDelegate: audioPlayerDelegate
        )

        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.paused)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 100,
            currentTime: 0,
            state: .paused,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_timeControlStatusObserver_newStateIsPausedCurrentStateIsStopped_delegateWasNotCalled() {
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(
            from: URL(string: "http://getstream.io")!,
            andConnectDelegate: audioPlayerDelegate
        )
        playerObserver.addStoppedPlaybackObserverWasCalledWith?.block(.init(url: URL(string: "http://getstream.io")!))

        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.paused)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 100,
            currentTime: 0,
            state: .stopped,
            rate: .zero,
            isSeeking: false
        ))
    }

    // MARK: newState: .playing

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsNotLoaded_delegateWasNotCalled() {
        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.playing)

        XCTAssertNil(audioPlayerDelegate.didUpdateContextWasCalled?.context)
    }

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsLoading_delegateWasCalledWithExpectedContext() {
        assetPropertyLoader.holdLoadProperty = true
        subject.loadAsset(
            from: URL(string: "http://getstream.io")!,
            andConnectDelegate: audioPlayerDelegate
        )

        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.playing)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 0,
            currentTime: 0,
            state: .playing,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsPaused_delegateWasCalledWithExpectedContext() {
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(
            from: URL(string: "http://getstream.io")!,
            andConnectDelegate: audioPlayerDelegate
        )
        subject.pause()

        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.playing)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsStopped_delegateWasNotCalled() {
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(
            from: URL(string: "http://getstream.io")!,
            andConnectDelegate: audioPlayerDelegate
        )
        playerObserver.addStoppedPlaybackObserverWasCalledWith?.block(.init(url: URL(string: "http://getstream.io")!))

        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.playing)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .zero,
            isSeeking: false
        ))
    }

    // MARK: - stoppedPlaybackObserver

    func test_stoppedPlaybackObserver_currentItemIsTheSameAsTheStoppedOne_delegateWasCalledWithUpdatedContext() {
        let url = URL(string: "http://getstream.io")!
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(
            from: url,
            andConnectDelegate: audioPlayerDelegate
        )

        playerObserver.addStoppedPlaybackObserverWasCalledWith?.block(.init(url: url))

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 100,
            currentTime: 0,
            state: .stopped,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_stoppedPlaybackObserver_currentItemIsNotTheSameAsTheStoppedOne_delegateWasNotCalledWithUpdatedContext() {
        let url = URL(string: "http://getstream.io")!
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(
            from: url,
            andConnectDelegate: audioPlayerDelegate
        )

        playerObserver.addStoppedPlaybackObserverWasCalledWith?.block(.init(url: .init(string: "http://getstream.io/2")!))

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        ))
    }

    // MARK: - playbackContext

    func test_playbackContext_URLMatchesCurrentItemsURL_returnsExpectedResult() {
        let url = URL(string: "http://getstream.io")!
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)

        XCTAssertEqual(
            subject.playbackContext(for: url),
            .init(
                duration: 100,
                currentTime: 0,
                state: .playing,
                rate: .normal,
                isSeeking: false
            )
        )
    }

    func test_playbackContext_URLDoesNotMatchCurrentItemsURL_returnsNotLoaded() {
        XCTAssertEqual(
            subject.playbackContext(for: .init(string: "http://getstream.io")!),
            .notLoaded
        )
    }

    // MARK: - loadAsset

    func test_loadAsset_whenURLIsNil_willCallPauseUpdateTheContextReplaceCurrentItemButWillNotCallLoadProperty() {
        subject.loadAsset(from: nil, andConnectDelegate: audioPlayerDelegate)

        XCTAssertTrue(player.pauseWasCalled)
        XCTAssertEqual(subject.context, .init(
            duration: 0,
            currentTime: 0,
            state: .stopped,
            rate: .zero,
            isSeeking: false
        ))
        XCTAssertTrue(player.replaceCurrentItemWasCalled)
        XCTAssertNil(player.replaceCurrentItemWasCalledWithItem)
        XCTAssertNil(subject.delegate)
    }

    func test_loadAsset_whenURLIsNotNil_assetLoadSucceeds_willCallPauseUpdateTheContextReplaceCurrentItemLoadPropertyAndPlay() {
        let url = URL(string: "http://getstream.io")!
        subject.play()
        player.playWasCalled = false
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        let expectedContext = AudioPlaybackContext(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        )

        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)

        XCTAssertTrue(player.pauseWasCalled)
        XCTAssertEqual(subject.context, expectedContext)
        XCTAssertTrue(player.replaceCurrentItemWasCalled)
        XCTAssertEqual((player.replaceCurrentItemWasCalledWithItem?.asset as? AVURLAsset)?.url, url)
        XCTAssertTrue(subject.delegate === audioPlayerDelegate)
        XCTAssertEqual(assetPropertyLoader.loadPropertyWasCalledWith?.property, .duration)
        XCTAssertEqual(assetPropertyLoader.loadPropertyWasCalledWith?.asset.url, url)
        XCTAssertTrue(player.playWasCalled)
        XCTAssertTrue((audioPlayerDelegate.didUpdateContextWasCalled?.player as? StreamRemoteAudioPlayer) === subject)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, expectedContext)
    }

    func test_loadAsset_whenURLIsNotNil_assetLoadFail_willCallPauseUpdateTheContextReplaceCurrentItemLoadPropertyAndPlay() {
        let url = URL(string: "http://getstream.io")!
        subject.play()
        player.playWasCalled = false
        assetPropertyLoader.loadPropertyResult = .failure(NSError())

        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)

        XCTAssertTrue(player.pauseWasCalled)
        XCTAssertEqual(subject.context, .init(
            duration: 0,
            currentTime: 0,
            state: .notLoaded,
            rate: .zero,
            isSeeking: false
        ))
        XCTAssertTrue(player.replaceCurrentItemWasCalled)
        XCTAssertNil(player.replaceCurrentItemWasCalledWithItem)
        XCTAssertTrue(subject.delegate === audioPlayerDelegate)
        XCTAssertEqual(assetPropertyLoader.loadPropertyWasCalledWith?.property, .duration)
        XCTAssertEqual(assetPropertyLoader.loadPropertyWasCalledWith?.asset.url, url)
        XCTAssertFalse(player.playWasCalled)
    }

    func test_loadAsset_whenURLSameAsCurrentItemURLAndContextStateIsPaused_willNotCallAssetLoaderWillCallPlayUpdatesStateAndDelegate() {
        let url = URL(string: "http://getstream.io")!
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)
        subject.pause()
        assetPropertyLoader.loadPropertyWasCalledWith = nil
        let secondDelegate = MockAudioPlayerDelegate()

        subject.loadAsset(from: url, andConnectDelegate: secondDelegate)

        XCTAssertNil(assetPropertyLoader.loadPropertyWasCalledWith)
        XCTAssertEqual(secondDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        ))
    }

    func test_loadAsset_whenURLSameAsCurrentItemURLAndContextStateIsStopped_willNotCallAssetLoaderWillCallPlayUpdatesStateAndDelegate() {
        let url = URL(string: "http://getstream.io")!
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)
        playerObserver.addStoppedPlaybackObserverWasCalledWith?.block(.init(url: url))
        assetPropertyLoader.loadPropertyWasCalledWith = nil
        player.replaceCurrentItemWasCalledWithItem = nil
        let secondDelegate = MockAudioPlayerDelegate()

        subject.loadAsset(from: url, andConnectDelegate: secondDelegate)

        XCTAssertNil(assetPropertyLoader.loadPropertyWasCalledWith)
        XCTAssertEqual((player.replaceCurrentItemWasCalledWithItem?.asset as? AVURLAsset)?.url, url)
        XCTAssertEqual(secondDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        ))
    }

    func test_loadAsset_whenURLSameAsCurrentItemURLAndContextStateIsPlaying_willNotCallAssetLoaderWillCallPlayUpdatesStateAndDelegate() {
        let url = URL(string: "http://getstream.io")!
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)
        player.playWasCalled = false
        assetPropertyLoader.loadPropertyWasCalledWith = nil
        player.replaceCurrentItemWasCalledWithItem = nil
        let secondDelegate = MockAudioPlayerDelegate()

        subject.loadAsset(from: url, andConnectDelegate: secondDelegate)

        XCTAssertNil(assetPropertyLoader.loadPropertyWasCalledWith)
        XCTAssertNil(player.replaceCurrentItemWasCalledWithItem)
        XCTAssertFalse(player.playWasCalled)
        XCTAssertEqual(secondDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        ))
    }

    // MARK: - play

    func test_play_callsPlayOnPlayerAndUpdatesContextAndDelegate() {
        let url = URL(string: "http://getstream.io")!
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)
        player.pause()
        player.playWasCalled = false

        subject.play()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.state, .playing)
        XCTAssertTrue(player.playWasCalled)
    }

    // MARK: - pause

    func test_pause_callsPauseOnPlayerAndUpdatesContextAndDelegate() {
        let url = URL(string: "http://getstream.io")!
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)

        subject.pause()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.state, .paused)
        XCTAssertTrue(player.pauseWasCalled)
    }

    // MARK: - stop

    func test_stop_callsPauseOnPlayerAndUpdatesContextAndDelegate() {
        let url = URL(string: "http://getstream.io")!
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)

        subject.stop()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.state, .stopped)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.duration, TimeInterval(100))
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.currentTime, 0)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.rate, .zero)
        XCTAssertFalse(audioPlayerDelegate.didUpdateContextWasCalled?.context.isSeeking ?? true)
        XCTAssertTrue(player.pauseWasCalled)
    }

    // MARK: - updateRate

    func test_updateRate_updatesPlayerRate() {
        let url = URL(string: "http://getstream.io")!
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)

        subject.updateRate() // This call will change the rate to 2
        XCTAssertEqual(player.rateWasUpdatedTo, 2)

        subject.updateRate() // This call will change the rate to 0.5
        XCTAssertEqual(player.rateWasUpdatedTo, 0.5)

        subject.updateRate() // This call will change the rate to 1
        XCTAssertEqual(player.rateWasUpdatedTo, 1)

        subject.updateRate() // This call will change the rate to 2
        XCTAssertEqual(player.rateWasUpdatedTo, 2)
    }

    // MARK: - seek(to:)

    func test_seek_willCallPauseAndUpdateTheContextAsExpectedDebounceWillBeCalled() {
        subject = .init(
            debouncer: Debouncer(interval: 1),
            assetPropertyLoader: assetPropertyLoader,
            playerObserver: playerObserver,
            player: player
        )

        let url = URL(string: "http://getstream.io")!
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)

        subject.seek(to: 50)

        XCTAssertTrue(player.playWasCalled)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.state, .paused)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.currentTime, 50)
        XCTAssertTrue(audioPlayerDelegate.didUpdateContextWasCalled?.context.isSeeking ?? false)
    }

    func test_seek_seekWasCalledAndTheRequestWasExecuted_seekWasCalledOnPlayerAndContextWasUpdatedSuccessfully() {
        let url = URL(string: "http://getstream.io")!
        assetPropertyLoader.loadPropertyResult = .success(TimeInterval(100))
        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)

        subject.seek(to: 50)

        XCTAssertTrue(player.playWasCalled)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.state, .playing)
        XCTAssertFalse(audioPlayerDelegate.didUpdateContextWasCalled?.context.isSeeking ?? true)
        XCTAssertTrue(syncDebouncer.debounceWasCalled)
        XCTAssertEqual(player.seekWasCalledWith?.time, CMTimeMakeWithSeconds(50, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        XCTAssertEqual(player.seekWasCalledWith?.toleranceBefore, .zero)
        XCTAssertEqual(player.seekWasCalledWith?.toleranceAfter, .zero)
    }
}

extension StreamRemoteAudioPlayer_Tests {
    private class SyncDebouncer: Debouncing {
        private(set) var debounceWasCalled: Bool = false
        var holdExecution = false

        func debounce(_ handler: @escaping Handler) {
            guard holdExecution == false else {
                return
            }

            debounceWasCalled = true
            handler()
        }

        func cancel() { /* No-op */ }
    }

    private class MockAVPlayer: AVPlayer {
        var playWasCalled = false

        private(set) var pauseWasCalled = false

        private(set) var replaceCurrentItemWasCalled = false
        var replaceCurrentItemWasCalledWithItem: AVPlayerItem?

        private(set) var rateWasUpdatedTo: Float?

        private(set) var seekWasCalledWith: (time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime)?

        override var rate: Float {
            didSet {
                rateWasUpdatedTo = rate
                mockPlayerObserver?.addPeriodicTimeObserverWasCalledWith?.block()
            }
        }

        var mockPlayerObserver: MockAudioPlayerObserver?

        override func play() {
            playWasCalled = true
            super.play()
            mockPlayerObserver?.addTimeControlStatusObserverWaCalledWith?.block(.playing)
        }

        override func pause() {
            pauseWasCalled = true
            super.pause()
            mockPlayerObserver?.addTimeControlStatusObserverWaCalledWith?.block(.paused)
        }

        override func replaceCurrentItem(
            with item: AVPlayerItem?
        ) {
            replaceCurrentItemWasCalled = true
            replaceCurrentItemWasCalledWithItem = item
            super.replaceCurrentItem(with: item)
        }

        override func seek(
            to time: CMTime,
            toleranceBefore: CMTime,
            toleranceAfter: CMTime
        ) {
            seekWasCalledWith = (time, toleranceBefore, toleranceAfter)
            super.seek(
                to: time,
                toleranceBefore: toleranceBefore,
                toleranceAfter: toleranceAfter
            )
        }
    }

    private class MockAssetPropertyLoader: AssetPropertyLoading {
        var loadPropertyWasCalledWith: (property: AssetProperty, asset: AVURLAsset)?
        var loadPropertyResult: Result<Any, Error>?
        var holdLoadProperty = false

        func loadProperty<Value>(
            _ property: AssetProperty,
            of asset: AVURLAsset,
            onSuccessTransformer: @escaping (AVURLAsset) -> Value,
            completion: @escaping (Result<Value, Error>) -> Void
        ) {
            guard holdLoadProperty == false else {
                return
            }
            loadPropertyWasCalledWith = (property, asset)
            completion(loadPropertyResult!.map { $0 as! Value })
        }
    }

    private class MockAudioPlayerObserver: AudioPlayerObserving {
        private(set) var addTimeControlStatusObserverWaCalledWith: (object: AVPlayer, block: (AVPlayer.TimeControlStatus?) -> Void)?
        private(set) var addPeriodicTimeObserverWasCalledWith: (player: AVPlayer, interval: CMTime, queue: DispatchQueue?, block: () -> Void)?
        private(set) var addStoppedPlaybackObserverWasCalledWith: (queue: OperationQueue?, block: (AVPlayerItem) -> Void)?

        func addTimeControlStatusObserver(
            _ player: AVPlayer,
            using block: @escaping (AVPlayer.TimeControlStatus?) -> Void
        ) {
            addTimeControlStatusObserverWaCalledWith = (player, block)
        }

        func addPeriodicTimeObserver(
            _ player: AVPlayer,
            forInterval interval: CMTime,
            queue: DispatchQueue?,
            using block: @escaping () -> Void
        ) {
            addPeriodicTimeObserverWasCalledWith = (player, interval, queue, block)
        }

        func addStoppedPlaybackObserver(
            queue: OperationQueue?,
            using block: @escaping (AVPlayerItem) -> Void
        ) {
            addStoppedPlaybackObserverWasCalledWith = (queue, block)
        }
    }
}
