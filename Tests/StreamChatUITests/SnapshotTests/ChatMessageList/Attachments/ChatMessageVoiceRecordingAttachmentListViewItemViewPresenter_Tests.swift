//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import UIKit
import XCTest

final class ChatMessageVoiceRecordingAttachmentListViewItemViewPresenter_Tests: XCTestCase {
    private lazy var view: ChatMessageVoiceRecordingAttachmentListView.ItemView! = .init()
    private lazy var spyView: SpyChatMessageVoiceRecordingAttachmentListViewItemView! = .init()
    private lazy var delegate: MockVoiceRecordingAttachmentPresentationViewDelegate! = .init()
    private lazy var audioPlayer: MockAudioPlayer! = .init()
    private lazy var subject: ChatMessageVoiceRecordingAttachmentListView.ItemViewPresenter! = .init(view)

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        var components = Components.mock
        components.isVoiceRecordingEnabled = true
        view.components = components
        spyView.components = components

        subject.delegate = delegate
    }

    override func tearDown() {
        view = nil
        spyView = nil
        delegate = nil
        audioPlayer = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - setUp

    func test_setUp_voiceRecordingAttachmentPresentationViewConnectWasCalled() {
        subject.setUp()

        XCTAssertTrue(delegate.voiceRecordingAttachmentPresentationViewConnectWasCalledWithDelegate === subject)
    }

    func test_setUp_playPauseButtonTargetWasConfiguredCorrectly() {
        subject.setUp()

        XCTAssertEqual(
            view.playPauseButton.actions(forTarget: subject, forControlEvent: .touchUpInside),
            ["didTapOnPlayPauseButton:"]
        )
    }

    func test_setUp_playbackRateButtonTargetWasConfiguredCorrectly() {
        subject.setUp()

        XCTAssertEqual(
            view.playbackRateButton.actions(forTarget: subject, forControlEvent: .touchUpInside),
            ["didTapOnPlaybackRateButton:"]
        )
    }

    func test_setUp_waveformSliderSlideTargetWasConfiguredCorrectly() {
        subject.setUp()

        XCTAssertEqual(
            view.waveformView.slider.actions(forTarget: subject, forControlEvent: .valueChanged),
            ["didSlide:"]
        )
    }

    func test_setUp_waveformSliderTouchUpTargetWasConfiguredCorrectly() {
        subject.setUp()

        XCTAssertEqual(
            view.waveformView.slider.actions(forTarget: subject, forControlEvent: .touchUpInside),
            ["didTouchUpSlider:"]
        )
    }

    // MARK: - play

    func test_play_viewContentIsNil_voiceRecordingAttachmentPresentationViewBeginPaybackWasNotCalled() {
        subject.play()

        XCTAssertNil(delegate.voiceRecordingAttachmentPresentationViewBeginPaybackWasCalledWithAttachment)
    }

    func test_play_viewContentIsNotNil_voiceRecordingAttachmentPresentationViewBeginPaybackWasCalled() {
        let attachment = ChatMessageVoiceRecordingAttachment.mock(id: .unique)
        view.content = attachment

        subject.play()

        XCTAssertEqual(attachment, delegate.voiceRecordingAttachmentPresentationViewBeginPaybackWasCalledWithAttachment)
    }

    // MARK: - pause
    
    func test_pause_voiceRecordingAttachmentPresentationViewPausePaybackWasCalled() {
        subject.pause()

        XCTAssertTrue(delegate.voiceRecordingAttachmentPresentationViewPausePaybackWasCalled)
    }

    // MARK: - didTapOnPlayPauseButton

    func test_didTapOnPlayPauseButton_senderIsSelected_voiceRecordingAttachmentPresentationViewPausePaybackWasCalled() {
        view.content = .mock(id: .unique)
        view.playPauseButton.isSelected = true

        subject.didTapOnPlayPauseButton(view.playPauseButton)

        XCTAssertTrue(delegate.voiceRecordingAttachmentPresentationViewPausePaybackWasCalled)
    }

    func test_didTapOnPlayPauseButton_senderIsNotSelected_voiceRecordingAttachmentPresentationViewBeginPaybackWasCalled() {
        let attachment = ChatMessageVoiceRecordingAttachment.mock(id: .unique)
        view.content = attachment
        view.playPauseButton.isSelected = false

        subject.didTapOnPlayPauseButton(view.playPauseButton)

        XCTAssertEqual(attachment, delegate.voiceRecordingAttachmentPresentationViewBeginPaybackWasCalledWithAttachment)
    }

    // MARK: - didTapOnPlaybackRateButton

    func test_didTapOnPlaybackRateButton_currentPlaybackRateIsNormal_voiceRecordingAttachmentPresentationViewUpdatePlaybackRateWasCalled() {
        assertDidTapOnPlaybackRateButton(
            currentPlaybackRate: .normal,
            expectedPlaybackRate: .double
        )
    }

    func test_didTapOnPlaybackRateButton_currentPlaybackRateIsHalf_voiceRecordingAttachmentPresentationViewUpdatePlaybackRateWasCalled() {
        assertDidTapOnPlaybackRateButton(
            currentPlaybackRate: .half,
            expectedPlaybackRate: .normal
        )
    }

    func test_didTapOnPlaybackRateButton_currentPlaybackRateIsDouble_voiceRecordingAttachmentPresentationViewUpdatePlaybackRateWasCalled() {
        assertDidTapOnPlaybackRateButton(
            currentPlaybackRate: .double,
            expectedPlaybackRate: .half
        )
    }

    func test_didTapOnPlaybackRateButton_currentPlaybackRateIsZero_voiceRecordingAttachmentPresentationViewUpdatePlaybackRateWasCalled() {
        assertDidTapOnPlaybackRateButton(
            currentPlaybackRate: .zero,
            expectedPlaybackRate: .normal
        )
    }

    func test_didTapOnPlaybackRateButton_currentPlaybackRateIsACustomValue_voiceRecordingAttachmentPresentationViewUpdatePlaybackRateWasCalled() {
        assertDidTapOnPlaybackRateButton(
            currentPlaybackRate: .init(rawValue: 2.5),
            expectedPlaybackRate: .zero
        )
    }

    // MARK: - didSlide

    func test_didSlide_voiceRecordingAttachmentPresentationViewSeekWasCalled() {
        view.waveformView.slider.maximumValue = 20
        view.waveformView.slider.value = 15

        subject.didSlide(view.waveformView.slider)

        XCTAssertEqual(delegate.voiceRecordingAttachmentPresentationViewSeekWasCalledWithTimeInterval, 15)
    }

    // MARK: - didTouchUpSlider

    func test_didTouchUpSlider_voiceRecordingAttachmentPresentationViewBeginPaybackWasCalled() {
        let attachment = ChatMessageVoiceRecordingAttachment.mock(id: .unique)
        view.content = attachment

        subject.didTouchUpSlider(view.waveformView.slider)

        XCTAssertEqual(attachment, delegate.voiceRecordingAttachmentPresentationViewBeginPaybackWasCalledWithAttachment)
    }

    // MARK: - audioPlayer(_:didUpdateContext:)

    func test_audioPlayerDidUpdateContext_isCurrentItem_updatePlayPauseButtonWasCalled() {
        simulateAudioPlayerDidUpdateContext(state: .playing, isCurrentItem: true)

        XCTAssertEqual(spyView.updatePlayPauseButtonWasCalledWithState, .playing)
    }

    func test_audioPlayerDidUpdateContext_isCurrentItem_updateFileIconImageViewWasCalled() {
        simulateAudioPlayerDidUpdateContext(state: .playing, isCurrentItem: true)

        XCTAssertEqual(spyView.updateFileIconImageViewWasCalledWithState, .playing)
    }

    func test_audioPlayerDidUpdateContext_isCurrentItemDurationInExtraDataIsNotNil_updateWaveformViewWasCalled() {
        simulateAudioPlayerDidUpdateContext(
            state: .playing,
            isCurrentItem: true,
            duration: 89,
            currentTime: 15
        )

        XCTAssertEqual(spyView.updateWaveformViewWasCalledWithState, .playing)
        XCTAssertEqual(spyView.updateWaveformViewWasCalledWithDuration, 89)
        XCTAssertEqual(spyView.updateWaveformViewWasCalledWithCurrentTime, 15)
    }

    func test_audioPlayerDidUpdateContext_isCurrentItemDurationInExtraDataIsNil_updateWaveformViewWasCalled() {
        simulateAudioPlayerDidUpdateContext(
            state: .playing,
            isCurrentItem: true,
            currentTime: 15
        )

        XCTAssertEqual(spyView.updateWaveformViewWasCalledWithState, .playing)
        XCTAssertEqual(spyView.updateWaveformViewWasCalledWithDuration, 100)
        XCTAssertEqual(spyView.updateWaveformViewWasCalledWithCurrentTime, 15)
    }

    func test_audioPlayerDidUpdateContext_isCurrentItemStateIsPlayingContextRateIsZero_updatePlaybackRateButtonWasCalled() {
        simulateAudioPlayerDidUpdateContext(
            state: .playing,
            rate: .zero,
            initialPlaybackRate: .half,
            isCurrentItem: true
        )

        XCTAssertEqual(spyView.updatePlaybackRateButtonWasCalledWithState, .playing)
        XCTAssertEqual(spyView.updatePlaybackRateButtonWasCalledWithValue, 0.5)
    }

    func test_audioPlayerDidUpdateContext_isCurrentItemStateIsPausedContextRateIsZero_updatePlaybackRateButtonWasCalled() {
        simulateAudioPlayerDidUpdateContext(
            state: .paused,
            rate: .zero,
            initialPlaybackRate: .half,
            isCurrentItem: true
        )

        XCTAssertEqual(spyView.updatePlaybackRateButtonWasCalledWithState, .paused)
        XCTAssertEqual(spyView.updatePlaybackRateButtonWasCalledWithValue, 0.5)
    }

    func test_audioPlayerDidUpdateContext_isCurrentItemStateIsLoadingContextRateIsZero_updatePlaybackRateButtonWasCalled() {
        simulateAudioPlayerDidUpdateContext(
            state: .loading,
            rate: .zero,
            initialPlaybackRate: .half,
            isCurrentItem: true
        )

        XCTAssertEqual(spyView.updatePlaybackRateButtonWasCalledWithState, .loading)
        XCTAssertEqual(spyView.updatePlaybackRateButtonWasCalledWithValue, 0)
    }

    func test_audioPlayerDidUpdateContext_isCurrentItemStateIsPlayingContextRateIsNotZero_updatePlaybackRateButtonWasCalled() {
        simulateAudioPlayerDidUpdateContext(
            state: .playing,
            rate: .double,
            initialPlaybackRate: .half,
            isCurrentItem: true
        )

        XCTAssertEqual(spyView.updatePlaybackRateButtonWasCalledWithState, .playing)
        XCTAssertEqual(spyView.updatePlaybackRateButtonWasCalledWithValue, 2)
    }

    func test_audioPlayerDidUpdateContext_isCurrentItemStateIsPausedContextRateIsNotZero_updatePlaybackRateButtonWasCalled() {
        simulateAudioPlayerDidUpdateContext(
            state: .paused,
            rate: .double,
            initialPlaybackRate: .half,
            isCurrentItem: true
        )

        XCTAssertEqual(spyView.updatePlaybackRateButtonWasCalledWithState, .paused)
        XCTAssertEqual(spyView.updatePlaybackRateButtonWasCalledWithValue, 2)
    }

    func test_audioPlayerDidUpdateContext_isCurrentItemStateIsLoading_updatePlaybackLoadingIndicatorAndUpdateDurationLabelCalledAfterInterval() {
        simulateAudioPlayerDidUpdateContext(
            state: .loading,
            isCurrentItem: true
        )

        XCTAssertNil(spyView.updatePlaybackLoadingIndicatorWasCalledWithState)
        XCTAssertNil(spyView.updateDurationLabelWasCalledWithState)
        XCTAssertNil(spyView.updateDurationLabelWasCalledWithDuration)
        XCTAssertNil(spyView.updateDurationLabelWasCalledWithCurrentTime)

        let waitExpectation = expectation(description: "Dummy expectation")
        waitExpectation.isInverted = true

        wait(for: [waitExpectation], timeout: defaultTimeout)

        XCTAssertEqual(spyView.updatePlaybackLoadingIndicatorWasCalledWithState, .loading)
        XCTAssertEqual(spyView.updateDurationLabelWasCalledWithState, .loading)
        XCTAssertEqual(spyView.updateDurationLabelWasCalledWithDuration, 100)
        XCTAssertEqual(spyView.updateDurationLabelWasCalledWithCurrentTime, 0)
    }

    func test_audioPlayerDidUpdateContext_isCurrentItemStateIsPlaying_updatePlaybackLoadingIndicatorAndUpdateDurationLabelWereCalled() {
        simulateAudioPlayerDidUpdateContext(
            state: .playing,
            isCurrentItem: true
        )

        XCTAssertEqual(spyView.updatePlaybackLoadingIndicatorWasCalledWithState, .playing)
        XCTAssertEqual(spyView.updateDurationLabelWasCalledWithState, .playing)
        XCTAssertEqual(spyView.updateDurationLabelWasCalledWithDuration, 100)
        XCTAssertEqual(spyView.updateDurationLabelWasCalledWithCurrentTime, 0)
    }

    func test_audioPlayerDidUpdateContext_isCurrentItemStateIsPaused_updatePlaybackLoadingIndicatorAndUpdateDurationLabelWereCalled() {
        simulateAudioPlayerDidUpdateContext(
            state: .paused,
            isCurrentItem: true
        )

        XCTAssertEqual(spyView.updatePlaybackLoadingIndicatorWasCalledWithState, .paused)
        XCTAssertEqual(spyView.updateDurationLabelWasCalledWithState, .paused)
        XCTAssertEqual(spyView.updateDurationLabelWasCalledWithDuration, 100)
        XCTAssertEqual(spyView.updateDurationLabelWasCalledWithCurrentTime, 0)
    }

    // MARK: - Private Helpers

    private func assertDidTapOnPlaybackRateButton(
        currentPlaybackRate: @autoclosure () -> AudioPlaybackRate,
        expectedPlaybackRate: @autoclosure () -> AudioPlaybackRate,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        view.content = .mock(id: .unique, assetURL: .unique())
        subject.audioPlayer(
            audioPlayer,
            didUpdateContext: .init(
                assetLocation: view.content?.voiceRecordingURL,
                duration: 100,
                currentTime: 0,
                state: .notLoaded,
                rate: currentPlaybackRate(),
                isSeeking: false
            )
        )

        subject.didTapOnPlaybackRateButton(view.playbackRateButton)

        XCTAssertEqual(
            expectedPlaybackRate(),
            delegate.voiceRecordingAttachmentPresentationViewUpdatePlaybackRateWasCalledWithAudioPlaybackRate,
            file: file,
            line: line
        )
    }

    private func simulateAudioPlayerDidUpdateContext(
        state: AudioPlaybackState = .notLoaded,
        rate: AudioPlaybackRate = .normal,
        initialPlaybackRate: AudioPlaybackRate = .zero,
        isCurrentItem: Bool,
        duration: TimeInterval? = nil,
        currentTime: TimeInterval? = nil
    ) {
        subject = .init(spyView)

        let context = AudioPlaybackContext(
            assetLocation: .unique(),
            duration: 100,
            currentTime: currentTime ?? 0,
            state: state,
            rate: rate,
            isSeeking: false
        )
        spyView.content = .mock(
            id: .unique,
            assetURL: isCurrentItem ? context.assetLocation! : .unique(),
            duration: duration
        )

        subject.audioPlayer(
            audioPlayer,
            didUpdateContext: .init(
                assetLocation: context.assetLocation,
                duration: context.duration,
                currentTime: context.currentTime,
                state: .notLoaded,
                rate: initialPlaybackRate,
                isSeeking: false
            )
        )

        spyView.reset()

        subject.audioPlayer(audioPlayer, didUpdateContext: context)
    }
}

private final class SpyChatMessageVoiceRecordingAttachmentListViewItemView: ChatMessageVoiceRecordingAttachmentListView.ItemView {
    private(set) var updatePlayPauseButtonWasCalledWithState: AudioPlaybackState?

    private(set) var updateFileIconImageViewWasCalledWithState: AudioPlaybackState?

    private(set) var updatePlaybackLoadingIndicatorWasCalledWithState: AudioPlaybackState?

    private(set) var updateWaveformViewWasCalledWithState: AudioPlaybackState?
    private(set) var updateWaveformViewWasCalledWithDuration: TimeInterval?
    private(set) var updateWaveformViewWasCalledWithCurrentTime: TimeInterval?

    private(set) var updatePlaybackRateButtonWasCalledWithState: AudioPlaybackState?
    private(set) var updatePlaybackRateButtonWasCalledWithValue: Float?

    private(set) var updateDurationLabelWasCalledWithState: AudioPlaybackState?
    private(set) var updateDurationLabelWasCalledWithDuration: TimeInterval?
    private(set) var updateDurationLabelWasCalledWithCurrentTime: TimeInterval?

    func reset() {
        updatePlayPauseButtonWasCalledWithState = nil
        updateFileIconImageViewWasCalledWithState = nil
        updatePlaybackLoadingIndicatorWasCalledWithState = nil
        updateWaveformViewWasCalledWithState = nil
        updateWaveformViewWasCalledWithDuration = nil
        updateWaveformViewWasCalledWithCurrentTime = nil
        updatePlaybackRateButtonWasCalledWithState = nil
        updatePlaybackRateButtonWasCalledWithValue = nil
        updateDurationLabelWasCalledWithState = nil
        updateDurationLabelWasCalledWithDuration = nil
        updateDurationLabelWasCalledWithCurrentTime = nil
    }

    override func updatePlayPauseButton(for state: AudioPlaybackState) {
        updatePlayPauseButtonWasCalledWithState = state
    }

    override func updateFileIconImageView(for state: AudioPlaybackState) {
        updateFileIconImageViewWasCalledWithState = state
    }

    override func updateWaveformView(
        for state: AudioPlaybackState,
        duration: TimeInterval,
        currentTime: TimeInterval
    ) {
        updateWaveformViewWasCalledWithState = state
        updateWaveformViewWasCalledWithDuration = duration
        updateWaveformViewWasCalledWithCurrentTime = currentTime
    }

    override func updatePlaybackRateButton(
        for state: AudioPlaybackState,
        value: Float
    ) {
        updatePlaybackRateButtonWasCalledWithState = state
        updatePlaybackRateButtonWasCalledWithValue = value
    }

    override func updatePlaybackLoadingIndicator(for state: AudioPlaybackState) {
        updatePlaybackLoadingIndicatorWasCalledWithState = state
    }

    override func updateDurationLabel(
        for state: AudioPlaybackState,
        duration: TimeInterval,
        currentTime: TimeInterval
    ) {
        updateDurationLabelWasCalledWithState = state
        updateDurationLabelWasCalledWithDuration = duration
        updateDurationLabelWasCalledWithCurrentTime = currentTime
    }
}
