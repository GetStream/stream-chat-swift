//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class StreamAudioPlayer_Tests: XCTestCase {
    private var audioPlayerDelegate: MockAudioPlayerDelegate!
    private var assetPropertyLoader: MockAssetPropertyLoader!
    private var playerObserver: MockAudioPlayerObserver!
    private var audioSessionConfigurator: MockAudioSessionConfigurator!
    private var appStateObserver: MockAppStateObserver!
    private var player: MockAVPlayer!
    private var subject: StreamAudioPlayer!

    private lazy var assetURL: URL! = .unique()
    private lazy var mockAsset: MockAVURLAsset! = .init(url: assetURL)
    private lazy var assetDuration: CMTime! = CMTime(seconds: 100, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

    override func setUpWithError() throws {
        try super.setUpWithError()
        audioPlayerDelegate = .init()
        assetPropertyLoader = .init()
        audioSessionConfigurator = .init()
        playerObserver = .init()
        appStateObserver = .init()
        player = .init()
        subject = .init(
            assetPropertyLoader: assetPropertyLoader,
            playerObserver: playerObserver,
            player: player,
            audioSessionConfigurator: audioSessionConfigurator,
            appStateObserver: appStateObserver
        )

        player.mockPlayerObserver = playerObserver
    }

    override func tearDownWithError() throws {
        subject = nil
        player = nil
        appStateObserver = nil
        audioSessionConfigurator = nil
        playerObserver = nil
        assetPropertyLoader = nil
        audioPlayerDelegate = nil
        assetDuration = nil
        mockAsset = nil
        assetURL = nil
        try super.tearDownWithError()
    }

    // MARK: - init

    func test_init_addPeriodicTimeObserverWasCalledOnPlayerObserverWithExpectedInterval() {
        let expectedInterval = CMTime(
            seconds: 0.1,
            preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        )

        XCTAssertEqual(
            playerObserver.addPeriodicTimeObserverWasCalledWithInterval,
            expectedInterval
        )
    }

    func test_init_addTimeControlStatusObserverWasCalledOnPlayerObserverWithExpectedValues() {
        XCTAssertEqual(
            playerObserver.addTimeControlStatusObserverWaCalledWithObject,
            player
        )
    }

    func test_init_addStoppedPlaybackObserverWasCalledOnPlayerObserverWithExpectedValues() {
        XCTAssertNotNil(playerObserver.addStoppedPlaybackObserverWasCalledWithBlock)
        XCTAssertNil(playerObserver.addStoppedPlaybackObserverWasCalledWithQueue)
    }

    // MARK: - configureAudioSessionConfigurator

    func test_configureAudioSessionConfigurator_onlyNewInstanceIsInvoked() {
        let newAudioSessionConfigurator = MockAudioSessionConfigurator()
        subject.configure(newAudioSessionConfigurator)

        subject.play()

        XCTAssertEqual(newAudioSessionConfigurator.recordedFunctions, ["activatePlaybackSession()"])
        XCTAssertTrue(audioSessionConfigurator.recordedFunctions.isEmpty)
    }

    // MARK: - periodicTimerObserver

    func test_periodicTimerObserver_isSeekingIsFalse_delegateWasUpdatedWithExpectedContext() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)

        player.rate = 2

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .double,
            isSeeking: false
        ))
    }

    func test_periodicTimerObserver_isSeekingIsTrue_theContextWasNotUpdated() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        player.holdSeekCompletion = true
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)
        subject.seek(to: 10)

        playerObserver.addPeriodicTimeObserverWasCalledWithBlock?()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
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
        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.paused)

        XCTAssertNil(audioPlayerDelegate.didUpdateContextWasCalledWithContext)
    }

    func test_timeControlStatusObserver_newStateIsPausedCurrentStateIsLoading_delegateWasCalledWithExpectedContext() {
        assetPropertyLoader.holdLoadProperties = true
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)

        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.paused)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
            duration: 0,
            currentTime: 0,
            state: .paused,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_timeControlStatusObserver_newStateIsPausedCurrentStateIsPlaying_delegateWasCalledWithExpectedContext() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)

        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.paused)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
            duration: 100,
            currentTime: 0,
            state: .paused,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_timeControlStatusObserver_newStateIsPausedCurrentStateIsStopped_delegateWasNotCalled() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)
        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: assetURL))

        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.paused)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
            duration: 100,
            currentTime: 0,
            state: .stopped,
            rate: .zero,
            isSeeking: false
        ))
    }

    // MARK: newState: .playing

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsNotLoaded_delegateWasNotCalled() {
        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.playing)

        XCTAssertNil(audioPlayerDelegate.didUpdateContextWasCalledWithContext)
    }

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsLoading_delegateWasCalledWithExpectedContext() {
        assetPropertyLoader.holdLoadProperties = true
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)

        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.playing)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
            duration: 0,
            currentTime: 0,
            state: .playing,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsPaused_delegateWasCalledWithExpectedContext() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)
        subject.pause()

        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.playing)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsStopped_delegateWasNotCalled() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)
        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: assetURL))

        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.playing)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .zero,
            isSeeking: false
        ))
    }

    // MARK: - stoppedPlaybackObserver

    func test_stoppedPlaybackObserver_currentItemIsTheSameAsTheStoppedOne_delegateWasCalledWithUpdatedContext() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)

        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: assetURL))

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
            duration: 100,
            currentTime: 0,
            state: .stopped,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_stoppedPlaybackObserver_currentItemIsNotTheSameAsTheStoppedOne_delegateWasNotCalledWithUpdatedContext() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)

        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: .init(string: "http://getstream.io/2")!))

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        ))
    }
    
    // MARK: - loadAsset

    func test_loadAsset_whenURLIsNotNil_assetLoadSucceeds_willCallPauseUpdateTheContextReplaceCurrentItemLoadPropertyAndPlay() {
        subject.play()
        player.playWasCalled = false
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        let expectedContext = AudioPlaybackContext(
            assetLocation: assetURL,
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        )

        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)

        XCTAssertTrue(player.pauseWasCalled)
        XCTAssertEqual(subject.context, expectedContext)
        XCTAssertTrue(player.replaceCurrentItemWasCalled)
        XCTAssertEqual((player.replaceCurrentItemWasCalledWithItem?.asset as? AVURLAsset)?.url, assetURL)
//        XCTAssertTrue(subject.delegate === audioPlayerDelegate)
        XCTAssertEqual(assetPropertyLoader.loadPropertiesWasCalledWithProperties?.first?.name, "duration")
        XCTAssertEqual((assetPropertyLoader.loadPropertiesWasCalledWithAsset as? AVURLAsset)?.url, assetURL)
        XCTAssertTrue(player.playWasCalled)
        XCTAssertTrue((audioPlayerDelegate.didUpdateContextWasCalledWithPlayer as? StreamAudioPlayer) === subject)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, expectedContext)
    }

    func test_loadAsset_whenURLIsNotNil_assetLoadFail_willCallPauseUpdateTheContextReplaceCurrentItemLoadPropertyAndPlay() {
        subject.play()
        player.playWasCalled = false
        assetPropertyLoader.loadPropertiesResult = .failure(.init(failedProperties: [], cancelledProperties: []))

        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)

        XCTAssertTrue(player.pauseWasCalled)
        XCTAssertEqual(subject.context, .init(
            assetLocation: assetURL,
            duration: 0,
            currentTime: 0,
            state: .notLoaded,
            rate: .zero,
            isSeeking: false
        ))
        XCTAssertTrue(player.replaceCurrentItemWasCalled)
        XCTAssertNil(player.replaceCurrentItemWasCalledWithItem)
//        XCTAssertTrue(subject.delegate === audioPlayerDelegate)
        XCTAssertEqual(assetPropertyLoader.loadPropertiesWasCalledWithProperties?.first?.name, "duration")
        XCTAssertEqual((assetPropertyLoader.loadPropertiesWasCalledWithAsset as? AVURLAsset)?.url, assetURL)
        XCTAssertFalse(player.playWasCalled)
    }

    func test_loadAsset_whenURLSameAsCurrentItemURLAndContextStateIsPaused_willNotCallAssetLoaderWillCallPlayUpdatesStateAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)
        subject.pause()
        assetPropertyLoader.loadPropertiesWasCalledWithProperties = nil
        assetPropertyLoader.loadPropertiesWasCalledWithAsset = nil
        let secondDelegate = MockAudioPlayerDelegate()

        subject.subscribe(secondDelegate)
        subject.loadAsset(from: assetURL)

        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWithProperties)
        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWithAsset)
        XCTAssertEqual(secondDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        ))
    }

    func test_loadAsset_whenURLSameAsCurrentItemURLAndContextStateIsStopped_willNotCallAssetLoaderWillCallPlayUpdatesStateAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)
        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: assetURL))
        assetPropertyLoader.loadPropertiesWasCalledWithProperties = nil
        assetPropertyLoader.loadPropertiesWasCalledWithAsset = nil
        player.replaceCurrentItemWasCalledWithItem = nil
        let secondDelegate = MockAudioPlayerDelegate()

        subject.subscribe(secondDelegate)
        subject.loadAsset(from: assetURL)

        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWithProperties)
        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWithAsset)
        XCTAssertEqual((player.replaceCurrentItemWasCalledWithItem?.asset as? AVURLAsset)?.url, assetURL)
        XCTAssertEqual(secondDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        ))
    }

    func test_loadAsset_whenURLSameAsCurrentItemURLAndContextStateIsPlaying_willNotCallAssetLoaderWillCallPlayUpdatesStateAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)
        player.playWasCalled = false
        assetPropertyLoader.loadPropertiesWasCalledWithProperties = nil
        assetPropertyLoader.loadPropertiesWasCalledWithAsset = nil
        player.replaceCurrentItemWasCalledWithItem = nil
        let secondDelegate = MockAudioPlayerDelegate()

        subject.subscribe(secondDelegate)
        subject.loadAsset(from: assetURL)

        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWithProperties)
        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWithAsset)
        XCTAssertNil(player.replaceCurrentItemWasCalledWithItem)
        XCTAssertFalse(player.playWasCalled)
        XCTAssertEqual(secondDelegate.didUpdateContextWasCalledWithContext, .init(
            assetLocation: assetURL,
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        ))
    }

    // MARK: - play

    func test_play_callsPlayOnPlayerAndUpdatesContextAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)
        player.pause()
        player.playWasCalled = false

        subject.play()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.state, .playing)
        XCTAssertTrue(player.playWasCalled)
    }

    // MARK: - pause

    func test_pause_callsPauseOnPlayerAndUpdatesContextAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)

        subject.pause()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.state, .paused)
        XCTAssertTrue(player.pauseWasCalled)
    }

    // MARK: - stop

    func test_stop_callsPauseOnPlayerAndUpdatesContextAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)

        subject.stop()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.state, .stopped)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.duration, TimeInterval(100))
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.currentTime, 0)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.rate, .zero)
        XCTAssertFalse(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.isSeeking ?? true)
        XCTAssertTrue(player.pauseWasCalled)
    }

    // MARK: - updateRate

    func test_updateRate_updatesPlayerRate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL)

        subject.updateRate(.double) // This call will change the rate to 2
        XCTAssertEqual(player.rateWasUpdatedTo, 2)

        subject.updateRate(.half) // This call will change the rate to 0.5
        XCTAssertEqual(player.rateWasUpdatedTo, 0.5)

        subject.updateRate(.normal) // This call will change the rate to 1
        XCTAssertEqual(player.rateWasUpdatedTo, 1)

        subject.updateRate(.double) // This call will change the rate to 2
        XCTAssertEqual(player.rateWasUpdatedTo, 2)
    }

    // MARK: - seek(to:)

    func test_seek_seekWasInterrupted_willCallPauseAndUpdateTheContextAsExpected() {
        subject = .init(
            assetPropertyLoader: assetPropertyLoader,
            playerObserver: playerObserver,
            player: player,
            audioSessionConfigurator: audioSessionConfigurator,
            appStateObserver: appStateObserver
        )

        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)
        player.holdSeekCompletion = true

        subject.seek(to: 50)
 
        XCTAssertTrue(player.playWasCalled)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.state, .paused)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.currentTime, 50)
        XCTAssertTrue(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.isSeeking ?? false)
    }

    func test_seek_seekWasCalledAndTheRequestWasNotInterrupted_seekWasCalledOnPlayerAndContextWasUpdatedSuccessfully() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.subscribe(audioPlayerDelegate)
        subject.loadAsset(from: assetURL)

        subject.seek(to: 50)

        XCTAssertTrue(player.pauseWasCalled)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.state, .paused)
        XCTAssertFalse(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.isSeeking ?? true)
        XCTAssertEqual(player.seekWasCalledWithTime, CMTimeMakeWithSeconds(50, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        XCTAssertEqual(player.seekWasCalledWithToleranceBefore, .zero)
        XCTAssertEqual(player.seekWasCalledWithToleranceAfter, .zero)
    }
}
