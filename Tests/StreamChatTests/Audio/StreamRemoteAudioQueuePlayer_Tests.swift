//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamChat
import StreamChatTestTools
import XCTest

final class StreamRemoteAudioQueuePlayer_Tests: XCTestCase {
    private var datasource: MockAudioQueuePlayerDatasource!
    private var assetPropertyLoader: MockAssetPropertyLoader!
    private var playerObserver: MockAudioPlayerObserver!
    private var audioSessionConfigurator: MockAudioSessionConfigurator!
    private var appStateObserver: MockAppStateObserver!
    private var player: MockAVPlayer!
    private var subject: StreamRemoteAudioQueuePlayer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        datasource = .init()
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
        subject.datasource = datasource
    }

    override func tearDownWithError() throws {
        subject = nil
        player = nil
        appStateObserver = nil
        audioSessionConfigurator = nil
        playerObserver = nil
        assetPropertyLoader = nil
        datasource = nil
        try super.tearDownWithError()
    }

    // MARK: - playbackWillStop(_:)

    func test_playbackDidStop_datasourceProvidesNoNextTrackURL_stopsPlayback() {
        let currentURL = URL.unique()
        assetPropertyLoader.loadPropertiesResult = .success(.init(url: currentURL))
        subject.loadAsset(from: currentURL)

        /// Simulate playback approaching stop
        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: currentURL))

        XCTAssertTrue((datasource.audioQueuePlayerNextAssetURLWasCalledWithAudioPlayer as? StreamRemoteAudioQueuePlayer) === subject)
        XCTAssertEqual(datasource.audioQueuePlayerNextAssetURLWasCalledWithCurrentAssetURL, currentURL)
        XCTAssertTrue(player.pauseWasCalled)
    }

    func test_playbackDidStop_datasourceProvidesNextTrackURL_loadsAsset() {
        let currentURL = URL.unique()
        let nextTrackURL = URL.unique()
        assetPropertyLoader.loadPropertiesResult = .success(.init(url: currentURL))
        subject.loadAsset(from: currentURL)
        /// Prepare for the second call
        player.replaceCurrentItemWasCalledWithItem = nil
        assetPropertyLoader.loadPropertiesResult = .success(.init(url: nextTrackURL))
        datasource.audioQueuePlayerNextAssetURLResult = nextTrackURL

        /// Simulate playback approaching stop
        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: currentURL))

        XCTAssertTrue((datasource.audioQueuePlayerNextAssetURLWasCalledWithAudioPlayer as? StreamRemoteAudioQueuePlayer) === subject)
        XCTAssertEqual(datasource.audioQueuePlayerNextAssetURLWasCalledWithCurrentAssetURL, currentURL)
        XCTAssertEqual((player.replaceCurrentItemWasCalledWithItem?.asset as? AVURLAsset)?.url, nextTrackURL)
    }
}

private final class MockAudioQueuePlayerDatasource: AudioQueuePlayerDatasource {
    private(set) var audioQueuePlayerNextAssetURLWasCalledWithAudioPlayer: AudioPlaying?
    private(set) var audioQueuePlayerNextAssetURLWasCalledWithCurrentAssetURL: URL?
    var audioQueuePlayerNextAssetURLResult: URL?

    func audioQueuePlayerNextAssetURL(
        _ audioPlayer: AudioPlaying,
        currentAssetURL: URL?
    ) -> URL? {
        audioQueuePlayerNextAssetURLWasCalledWithAudioPlayer = audioPlayer
        audioQueuePlayerNextAssetURLWasCalledWithCurrentAssetURL = currentAssetURL
        return audioQueuePlayerNextAssetURLResult
    }
}
