//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class VoiceRecordingVC_Tests: XCTestCase {
    private lazy var composerView: ComposerView! = .init()
    private lazy var assetPropertiesLoader: MockAssetPropertyLoader! = .init()
    private lazy var audioAnalyser: MockAudioAnalyser! = .init()
    private lazy var delegate: MockVoiceRecordingDelegate! = .init()
    private lazy var audioSessionFeedbackGenerator: MockAudioSessionFeedbackGenerator! = .init()
    private lazy var audioPlayer: MockAudioPlayer! = .init()
    private lazy var audioRecorder: MockAudioRecorder! = .init()
    private lazy var subject: VoiceRecordingVC! = .init(composerView: composerView)
    private lazy var spySubject: SpyVoiceRecordingVC! = .init(composerView: .init())

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()

        UIView.setAnimationsEnabled(false)

        var components = subject.components
        components.isVoiceRecordingEnabled = true
        subject.components = components
        composerView.components = components
        spySubject.components = components

        subject.audioPlayer = audioPlayer
        subject.audioRecorder = audioRecorder
        subject.audioSessionFeedbackGenerator = audioSessionFeedbackGenerator
        subject.delegate = delegate
        subject.audioAnalysisFactory = .init(
            assetPropertiesLoader: assetPropertiesLoader,
            audioAnalyser: audioAnalyser
        )

        subject.setUp()
        subject.setUpLayout()
        subject.setUpAppearance()
    }

    override func tearDown() {
        subject = nil
        audioRecorder = nil
        audioAnalyser = nil
        assetPropertiesLoader = nil
        audioPlayer = nil
        audioSessionFeedbackGenerator = nil
        delegate = nil
        composerView = nil
        spySubject = nil

        UIView.setAnimationsEnabled(true)

        super.tearDown()
    }

    // MARK: - setUp

    func test_setUp_bidirectionalPanGestureRecogniserWasConfiguredCorrectly() {
        spySubject.setUp()
        spySubject.content = .beginRecording

        spySubject.bidirectionalPanGestureRecogniser.touchesEndedHandler?()
        XCTAssertEqual(spySubject.updateContentByApplyingActionWasCalledWithAction, .touchUp)
        XCTAssertNotNil(spySubject.bidirectionalPanGestureRecogniser.horizontalMovementHandler)
        XCTAssertNotNil(spySubject.bidirectionalPanGestureRecogniser.verticalMovementHandler)
    }

    func test_setUp_recordButtonWasConfiguredCorrectly() {
        spySubject.setUp()

        spySubject.recordButton.incompleteHandler?()
        XCTAssertEqual(spySubject.updateContentByApplyingActionWasCalledWithAction, .showTip)
        spySubject.recordButton.completedHandler?()
        XCTAssertEqual(spySubject.updateContentByApplyingActionWasCalledWithAction, .beginRecording)
    }

    func test_setUp_discardRecordingButtonWasConfiguredCorrectly() {
        spySubject.setUp()

        XCTAssertEqual(
            spySubject.discardRecordingButton.image(for: .normal)?.pngData(),
            spySubject.appearance.images.trash.tinted(
                with: spySubject.appearance.colorPalette.accentPrimary
            )?.pngData()
        )
        XCTAssertEqual(
            spySubject.discardRecordingButton.actions(forTarget: spySubject, forControlEvent: .touchUpInside),
            ["didTapDiscard:"]
        )
    }

    func test_setUp_stopRecordingButtonWasConfiguredCorrectly() {
        spySubject.setUp()

        XCTAssertEqual(
            spySubject.stopRecordingButton.image(for: .normal),
            spySubject.appearance.images.stop
        )
        XCTAssertEqual(
            spySubject.stopRecordingButton.tintColor,
            spySubject.appearance.colorPalette.alert
        )
        XCTAssertEqual(
            spySubject.stopRecordingButton.actions(forTarget: spySubject, forControlEvent: .touchUpInside),
            ["didTapStop:"]
        )
    }

    func test_setUp_sendButtonWasConfiguredCorrectly() {
        spySubject.setUp()

        XCTAssertTrue(spySubject.sendButton.isEnabled)
        XCTAssertEqual(
            spySubject.sendButton.actions(forTarget: spySubject, forControlEvent: .touchUpInside),
            ["didTapSend:"]
        )
    }

    func test_setUp_confirmButtonWasConfiguredCorrectly() {
        spySubject.setUp()

        XCTAssertTrue(spySubject.confirmButton.isEnabled)
        XCTAssertEqual(
            spySubject.confirmButton.actions(forTarget: spySubject, forControlEvent: .touchUpInside),
            ["didTapConfirm:"]
        )
    }

    func test_setUp_liveRecordingViewWasConfiguredCorrectly() {
        spySubject.setUp()

        XCTAssertEqual(
            spySubject.liveRecordingView.playbackButton.actions(forTarget: spySubject, forControlEvent: .touchUpInside),
            ["didTapPlayPause:"]
        )

        XCTAssertEqual(
            spySubject.liveRecordingView.waveformView.slider.actions(forTarget: spySubject, forControlEvent: .valueChanged),
            ["didSeekTime:"]
        )
    }

    // MARK: - updateContentByApplyingAction

    // MARK: action - tapRecord

    func test_updateContentByApplyingAction_tapRecord_stateIsIdle_wasConfiguredAsExpected() {
        subject.updateContentByApplyingAction(.tapRecord)

        XCTAssertEqual(audioSessionFeedbackGenerator.recordedFunctions, ["feedbackForPreparingRecording()"])
        XCTAssertEqual(subject.content, .idle)
    }

    func test_updateContentByApplyingAction_tapRecord_stateIsShowingTip_wasConfiguredAsExpected() {
        var content = subject.content
        content.state = .showingTip
        subject.content = content

        subject.updateContentByApplyingAction(.tapRecord)

        XCTAssertEqual(audioSessionFeedbackGenerator.recordedFunctions, ["feedbackForPreparingRecording()"])
        XCTAssertEqual(subject.content, .idle)
    }

    // MARK: action - showTip

    func test_updateContentByApplyingAction_showTip_stateIsIdle_wasConfiguredAsExpected() {
        subject.updateContentByApplyingAction(.showTip)

        XCTAssertEqual(subject.content.state, .showingTip)
    }

    // MARK: action - beginRecording

    func test_updateContentByApplyingAction_beginRecording_wasConfiguredAsExpected() {
        subject.updateContentByApplyingAction(.beginRecording)
        audioRecorder.beginRecordingWasCalledWithCompletionHandler?()

        XCTAssertEqual(audioSessionFeedbackGenerator.recordedFunctions, ["feedbackForBeginRecording()"])
        XCTAssertTrue(delegate.voiceRecordingWillBeginRecordingWasCalledWithVC === subject)
        XCTAssertTrue(audioPlayer.stopWasCalled)
        XCTAssertNotNil(audioRecorder.beginRecordingWasCalledWithCompletionHandler)
        XCTAssertEqual(subject.content, .beginRecording)
    }

    // MARK: action - touchUp

    func test_updateContentByApplyingAction_touchUp_stateIsIdle_wasConfiguredAsExpected() {
        subject.content = .idle

        subject.updateContentByApplyingAction(.touchUp)

        XCTAssertFalse(audioRecorder.stopRecordingWasCalled)
    }

    func test_updateContentByApplyingAction_touchUp_stateIsRecording_wasConfiguredAsExpected() {
        subject.content = .beginRecording

        subject.updateContentByApplyingAction(.touchUp)

        XCTAssertTrue(audioRecorder.stopRecordingWasCalled)
    }

    // MARK: action - cancel

    func test_updateContentByApplyingAction_cancel_wasConfiguredAsExpected() {
        subject.updateContentByApplyingAction(.cancel)

        XCTAssertEqual(audioSessionFeedbackGenerator.recordedFunctions, ["feedbackForCancelRecording()"])
        XCTAssertTrue(audioRecorder.stopRecordingWasCalled)
        XCTAssertEqual(subject.content, .idle)
    }

    // MARK: action - lock

    func test_updateContentByApplyingAction_lock_wasConfiguredAsExpected() {
        subject.updateContentByApplyingAction(.lock)

        XCTAssertEqual(subject.content.state, .locked)
    }

    // MARK: action - discard

    func test_updateContentByApplyingAction_discard_wasConfiguredAsExpected() {
        subject.updateContentByApplyingAction(.discard)

        XCTAssertEqual(audioSessionFeedbackGenerator.recordedFunctions, ["feedbackForDiscardRecording()"])
        XCTAssertTrue(audioRecorder.stopRecordingWasCalled)
        XCTAssertTrue(audioPlayer.stopWasCalled)
        XCTAssertTrue(delegate.voiceRecordingDidStopRecordingWasCalledWithVC === subject)
        XCTAssertEqual(subject.content, .idle)
    }

    // MARK: action - stop

    func test_updateContentByApplyingAction_stop_wasConfiguredAsExpected() {
        subject.updateContentByApplyingAction(.stop)

        XCTAssertEqual(audioSessionFeedbackGenerator.recordedFunctions, ["feedbackForStop()"])
        XCTAssertTrue(audioRecorder.stopRecordingWasCalled)
    }

    // MARK: action - send

    func test_updateContentByApplyingAction_send_contentLocationIsNil_wasConfiguredAsExpected() {
        subject.updateContentByApplyingAction(.send)

        XCTAssertTrue(audioRecorder.stopRecordingWasCalled)
        XCTAssertEqual(subject.content, .idle)
    }

    func test_updateContentByApplyingAction_send_contentLocationIsNotNilAndVoiceRecordingConfirmInsteadOfSendDisabled_wasConfiguredAsExpected() {
        var components = subject.components
        components.isVoiceRecordingConfirmationRequiredEnabled = false
        subject.components = components
        var content = subject.content
        content.location = .unique()
        subject.content = content

        subject.updateContentByApplyingAction(.send)

        XCTAssertTrue(audioPlayer.stopWasCalled)
        XCTAssertTrue(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithVC === subject)
        XCTAssertTrue(delegate.voiceRecordingDidStopRecordingWasCalledWithVC === subject)
        XCTAssertTrue(delegate.voiceRecordingPublishMessageWasCalledWithVC === subject)
        XCTAssertEqual(subject.content, .idle)
    }

    func test_updateContentByApplyingAction_send_contentLocationIsNotNilAndisVoiceRecordingConfirmationRequiredEnabled_wasConfiguredAsExpected() {
        var components = subject.components
        components.isVoiceRecordingConfirmationRequiredEnabled = true
        subject.components = components
        var content = subject.content
        content.location = .unique()
        subject.content = content

        subject.updateContentByApplyingAction(.send)

        XCTAssertTrue(audioPlayer.stopWasCalled)
        XCTAssertTrue(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithVC === subject)
        XCTAssertTrue(delegate.voiceRecordingDidStopRecordingWasCalledWithVC === subject)
        XCTAssertFalse(delegate.voiceRecordingPublishMessageWasCalledWithVC === subject)
        XCTAssertEqual(subject.content, .idle)
    }

    // MARK: action - confirm

    func test_updateContentByApplyingAction_confirm_contentLocationIsNil_wasConfiguredAsExpected() {
        subject.updateContentByApplyingAction(.confirm)

        XCTAssertTrue(audioRecorder.stopRecordingWasCalled)
        XCTAssertEqual(subject.content, .idle)
    }

    func test_updateContentByApplyingAction_confirm_contentLocationIsNotNilAndVoiceRecordingConfirmInsteadOfSendDisabled_wasConfiguredAsExpected() {
        var components = subject.components
        components.isVoiceRecordingConfirmationRequiredEnabled = false
        subject.components = components
        var content = subject.content
        content.location = .unique()
        subject.content = content

        subject.updateContentByApplyingAction(.confirm)

        XCTAssertTrue(audioPlayer.stopWasCalled)
        XCTAssertTrue(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithVC === subject)
        XCTAssertTrue(delegate.voiceRecordingDidStopRecordingWasCalledWithVC === subject)
        XCTAssertTrue(delegate.voiceRecordingPublishMessageWasCalledWithVC === subject)
        XCTAssertEqual(subject.content, .idle)
    }

    func test_updateContentByApplyingAction_confirm_contentLocationIsNotNilAndisVoiceRecordingConfirmationRequiredEnabled_wasConfiguredAsExpected() {
        var components = subject.components
        components.isVoiceRecordingConfirmationRequiredEnabled = true
        subject.components = components
        var content = subject.content
        content.location = .unique()
        subject.content = content

        subject.updateContentByApplyingAction(.confirm)

        XCTAssertTrue(audioPlayer.stopWasCalled)
        XCTAssertTrue(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithVC === subject)
        XCTAssertTrue(delegate.voiceRecordingDidStopRecordingWasCalledWithVC === subject)
        XCTAssertFalse(delegate.voiceRecordingPublishMessageWasCalledWithVC === subject)
        XCTAssertEqual(subject.content, .idle)
    }

    // MARK: action - publishMessage

    func test_updateContentByApplyingAction_publishMessage_contentLocationIsNotNilAndVoiceRecordingConfirmInsteadOfSendDisabled_wasConfiguredAsExpected() {
        var components = subject.components
        components.isVoiceRecordingConfirmationRequiredEnabled = false
        subject.components = components
        var content = subject.content
        content.location = .unique()
        subject.content = content

        subject.updateContentByApplyingAction(.publishMessage)

        XCTAssertTrue(audioPlayer.stopWasCalled)
        XCTAssertTrue(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithVC === subject)
        XCTAssertTrue(delegate.voiceRecordingDidStopRecordingWasCalledWithVC === subject)
        XCTAssertTrue(delegate.voiceRecordingPublishMessageWasCalledWithVC === subject)
        XCTAssertEqual(subject.content, .idle)
    }

    func test_updateContentByApplyingAction_publishMessage_contentLocationIsNotNilAndisVoiceRecordingConfirmationRequiredEnabled_wasConfiguredAsExpected() {
        var components = subject.components
        components.isVoiceRecordingConfirmationRequiredEnabled = true
        subject.components = components
        var content = subject.content
        content.location = .unique()
        subject.content = content

        subject.updateContentByApplyingAction(.publishMessage)

        XCTAssertTrue(audioPlayer.stopWasCalled)
        XCTAssertTrue(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithVC === subject)
        XCTAssertTrue(delegate.voiceRecordingDidStopRecordingWasCalledWithVC === subject)
        XCTAssertFalse(delegate.voiceRecordingPublishMessageWasCalledWithVC === subject)
        XCTAssertEqual(subject.content, .idle)
    }

    // MARK: action - play

    func test_updateContentByApplyingAction_play_contentLocationIsNilAndIsPlaying_wasConfiguredAsExpected() {
        subject.content = .idle
        subject.liveRecordingView.content = .init(isRecording: false, isPlaying: true, duration: 0, currentTime: 0, waveform: [])

        subject.updateContentByApplyingAction(.play)

        XCTAssertTrue(audioSessionFeedbackGenerator.recordedFunctions.isEmpty)
        XCTAssertNil(audioPlayer.loadAssetWasCalledWithURL)
    }

    func test_updateContentByApplyingAction_play_contentLocationIsNotNilAndIsPlaying_wasConfiguredAsExpected() {
        var content = subject.content
        content.location = .unique()
        subject.content = content
        subject.liveRecordingView.content = .init(isRecording: false, isPlaying: true, duration: 0, currentTime: 0, waveform: [])

        subject.updateContentByApplyingAction(.play)

        XCTAssertTrue(audioSessionFeedbackGenerator.recordedFunctions.isEmpty)
        XCTAssertNil(audioPlayer.loadAssetWasCalledWithURL)
    }

    func test_updateContentByApplyingAction_play_contentLocationIsNilAndIsNotPlaying_wasConfiguredAsExpected() {
        subject.content = .idle
        subject.liveRecordingView.content = .init(isRecording: false, isPlaying: false, duration: 0, currentTime: 0, waveform: [])

        subject.updateContentByApplyingAction(.play)

        XCTAssertTrue(audioSessionFeedbackGenerator.recordedFunctions.isEmpty)
        XCTAssertNil(audioPlayer.loadAssetWasCalledWithURL)
    }

    func test_updateContentByApplyingAction_play_contentLocationIsNotNilAndIsNotPlaying_wasConfiguredAsExpected() {
        var content = subject.content
        content.location = .unique()
        subject.content = content
        subject.liveRecordingView.content = .init(isRecording: false, isPlaying: false, duration: 0, currentTime: 0, waveform: [])

        subject.updateContentByApplyingAction(.play)

        XCTAssertEqual(audioSessionFeedbackGenerator.recordedFunctions, ["feedbackForPlay()"])
        XCTAssertEqual(audioPlayer.loadAssetWasCalledWithURL, subject.content.location)
    }

    // MARK: action - pause

    func test_updateContentByApplyingAction_pause_contentLocationIsNilAndIsPlaying_wasConfiguredAsExpected() {
        subject.content = .idle
        subject.liveRecordingView.content = .init(isRecording: false, isPlaying: true, duration: 0, currentTime: 0, waveform: [])

        subject.updateContentByApplyingAction(.pause)

        XCTAssertTrue(audioSessionFeedbackGenerator.recordedFunctions.isEmpty)
        XCTAssertFalse(audioPlayer.pauseWasCalled)
    }

    func test_updateContentByApplyingAction_pause_contentLocationIsNotNilAndIsPlaying_wasConfiguredAsExpected() {
        var content = subject.content
        content.location = .unique()
        subject.content = content
        subject.liveRecordingView.content = .init(isRecording: false, isPlaying: true, duration: 0, currentTime: 0, waveform: [])

        subject.updateContentByApplyingAction(.pause)

        XCTAssertEqual(audioSessionFeedbackGenerator.recordedFunctions, ["feedbackForPause()"])
        XCTAssertTrue(audioPlayer.pauseWasCalled)
    }

    func test_updateContentByApplyingAction_pause_contentLocationIsNilAndIsNotPlaying_wasConfiguredAsExpected() {
        subject.content = .idle
        subject.liveRecordingView.content = .init(isRecording: false, isPlaying: false, duration: 0, currentTime: 0, waveform: [])

        subject.updateContentByApplyingAction(.pause)

        XCTAssertTrue(audioSessionFeedbackGenerator.recordedFunctions.isEmpty)
        XCTAssertFalse(audioPlayer.pauseWasCalled)
    }

    func test_updateContentByApplyingAction_pause_contentLocationIsNotNilAndIsNotPlaying_wasConfiguredAsExpected() {
        var content = subject.content
        content.location = .unique()
        subject.content = content
        subject.liveRecordingView.content = .init(isRecording: false, isPlaying: false, duration: 0, currentTime: 0, waveform: [])

        subject.updateContentByApplyingAction(.pause)

        XCTAssertTrue(audioSessionFeedbackGenerator.recordedFunctions.isEmpty)
        XCTAssertFalse(audioPlayer.pauseWasCalled)
    }

    // MARK: - didPanHorizontally

    func test_didPanHorizontally_noDistanceCovered_slideToCancelViewWasConfiguredCorrectly() {
        subject.view.frame = .init(x: 0, y: 0, width: 200, height: 0)
        subject.slideToCancelDistance = 100
        subject.content = .beginRecording

        subject.didPanHorizontally(0)

        XCTAssertEqual(subject.slideToCancelView.content, .init(alpha: 1))
    }

    func test_didPanHorizontally_halfDistanceCovered_slideToCancelViewWasConfiguredCorrectly() {
        subject.view.frame = .init(x: 0, y: 0, width: 200, height: 0)
        subject.slideToCancelDistance = 100
        subject.content = .beginRecording

        subject.didPanHorizontally(150)

        XCTAssertEqual(subject.slideToCancelView.content, .init(alpha: 0.5))
    }

    func test_didPanHorizontally_distanceCovered_slideToCancelViewWasConfiguredCorrectly() {
        subject.view.frame = .init(x: 0, y: 0, width: 200, height: 0)
        subject.slideToCancelDistance = 100
        subject.content = .beginRecording

        subject.didPanHorizontally(100)

        XCTAssertEqual(subject.slideToCancelView.content, .init(alpha: 0))
    }

    func test_didPanHorizontally_distanceGreaterThanMinimum_updateContentByApplyingActionCancelWascalled() {
        subject.view.frame = .init(x: 0, y: 0, width: 200, height: 0)
        subject.slideToCancelDistance = 100
        subject.content = .beginRecording

        subject.didPanHorizontally(50)

        XCTAssertEqual(audioSessionFeedbackGenerator.recordedFunctions, ["feedbackForCancelRecording()"])
        XCTAssertTrue(audioRecorder.stopRecordingWasCalled)
        XCTAssertEqual(subject.content, .idle)
    }

    // MARK: - didPanVertically

    func test_didPanVertically_noDistanceCovered_lockIndicatorViewWasConfiguredCorrectly() {
        subject.view.frame = .init(x: 0, y: 0, width: 0, height: 200)
        subject.lockDistance = 100
        subject.content = .beginRecording

        subject.didPanVertically(0)

        XCTAssertEqual(subject.lockIndicatorView.bottomPaddingConstraint.constant, subject.lockIndicatorView.minimumBottomPadding)
        XCTAssertEqual(subject.lockIndicatorView.chevronImageView.alpha, 1)
    }

    func test_didPanVertically_halfDistanceCovered_lockIndicatorViewWasConfiguredCorrectly() {
        subject.view.frame = .init(x: 0, y: 0, width: 0, height: 200)
        subject.lockDistance = 100
        subject.content = .beginRecording

        subject.didPanVertically(150)

        XCTAssertEqual(subject.lockIndicatorView.bottomPaddingConstraint.constant, 50)
        XCTAssertEqual(subject.lockIndicatorView.chevronImageView.alpha, 0.5)
    }

    func test_didPanVertically_distanceCovered_lockIndicatorViewWasConfiguredCorrectly() {
        subject.view.frame = .init(x: 0, y: 0, width: 0, height: 200)
        subject.lockDistance = 100
        subject.content = .beginRecording

        subject.didPanVertically(100)

        XCTAssertEqual(subject.lockIndicatorView.bottomPaddingConstraint.constant, 100)
        XCTAssertEqual(subject.lockIndicatorView.chevronImageView.alpha, 0.0)
    }

    func test_didPanVertically_distanceGreaterThanMinimum_updateContentByApplyingActionCancelWascalled() {
        composerView.frame = .init(x: 0, y: 0, width: 0, height: 200)
        subject.lockDistance = 100
        subject.content = .beginRecording

        subject.didPanVertically(50)

        XCTAssertEqual(subject.content.state, .locked)
    }

    // MARK: - didSeekTime

    func test_didSeekTime_feedbackForSeekingWasCalled() {
        subject.didSeekTime(subject.liveRecordingView.waveformView.slider)

        XCTAssertEqual(audioSessionFeedbackGenerator.recordedFunctions, ["feedbackForSeeking()"])
    }

    func test_didSeekTime_seekWasCalledOnAudioPlayer() {
        subject.liveRecordingView.waveformView.slider.maximumValue = 10
        subject.liveRecordingView.waveformView.slider.value = 3

        subject.didSeekTime(subject.liveRecordingView.waveformView.slider)

        XCTAssertEqual(audioPlayer.seekWasCalledWithTime, 3)
    }

    // MARK: - audioRecorder(_:didUpdateContext:)

    func test_audioRecorderDidUpdateContext_contentWasUpdatedAsExpected() {
        subject.content = .beginRecording

        subject.audioRecorder(
            audioRecorder,
            didUpdateContext: .init(
                state: .recording,
                duration: 10,
                averagePower: 4
            )
        )

        XCTAssertEqual(
            subject.content,
            .init(
                state: .recording,
                duration: 10,
                waveform: [4]
            )
        )
    }

    func test_audioRecorderDidUpdateContext_recordingIndicatorViewWasUpdatedAsExpected() {
        subject.content = .beginRecording

        subject.audioRecorder(
            audioRecorder,
            didUpdateContext: .init(
                state: .recording,
                duration: 10,
                averagePower: 4
            )
        )

        XCTAssertEqual(subject.recordingIndicatorView.content, 10)
    }

    func test_audioRecorderDidUpdateContext_liveRecordingViewWasUpdatedAsExpected() {
        subject.content = .beginRecording

        subject.audioRecorder(
            audioRecorder,
            didUpdateContext: .init(
                state: .recording,
                duration: 10,
                averagePower: 4
            )
        )

        XCTAssertEqual(subject.liveRecordingView.content, .init(
            isRecording: true,
            isPlaying: false,
            duration: 10,
            currentTime: 10,
            waveform: [4]
        ))
    }

    // MARK: - audioRecorder(_:didFinishRecordingAtURL:)

    func test_audioRecorderDidFinishRecordingAtURL_waveformVisualisationWasCalled() {
        subject.content = .beginRecording
        let location = URL.unique()
        assetPropertiesLoader.loadPropertiesResult = .success(.init(url: location))

        subject.audioRecorder(audioRecorder, didFinishRecordingAtURL: location)

        XCTAssertEqual((assetPropertiesLoader.loadPropertiesWasCalledWithAsset as? AVURLAsset)?.url, location)
        XCTAssertEqual(audioAnalyser.analyseWasCalledWithAudioAnalysisContext?.audioURL, location)
        XCTAssertEqual(audioAnalyser.analyseWasCalledWithTargetSamples, 100)
    }

    func test_audioRecorderDidFinishRecordingAtURL_waveformVisualisationSucceeds_contentWasUpadedAsExpected() {
        subject.content = .beginRecording
        let location = URL.unique()
        assetPropertiesLoader.loadPropertiesResult = .success(.init(url: location))
        audioAnalyser.analyseResult = .success([1, 2, 3])

        subject.audioRecorder(audioRecorder, didFinishRecordingAtURL: location)

        wait()

        XCTAssertEqual(subject.content.waveform, [1, 2, 3])
        XCTAssertEqual(subject.content.location, location)
    }

    func test_audioRecorderDidFinishRecordingAtURL_waveformVisualisationSucceeds_liveRecordingViewWasUpdatedAsExpected() {
        subject.content = .beginRecording
        assetPropertiesLoader.loadPropertiesResult = .success(.init(url: .unique()))
        audioAnalyser.analyseResult = .success([1, 2, 3])
        subject.audioRecorder(audioRecorder, didUpdateContext: .init(state: .recording, duration: 10, averagePower: 0))

        subject.audioRecorder(audioRecorder, didFinishRecordingAtURL: .unique())

        wait()

        XCTAssertEqual(subject.liveRecordingView.content, .init(
            isRecording: false,
            isPlaying: false,
            duration: 10,
            currentTime: 0,
            waveform: [1, 2, 3]
        ))
    }

    func test_audioRecorderDidFinishRecordingAtURL_waveformVisualisationSucceeds_stopRecordingButtonWasUpdatedAsExpected() {
        subject.content = .beginRecording
        assetPropertiesLoader.loadPropertiesResult = .success(.init(url: .unique()))
        audioAnalyser.analyseResult = .success([1, 2, 3])

        subject.audioRecorder(audioRecorder, didFinishRecordingAtURL: .unique())

        wait()

        XCTAssertTrue(subject.stopRecordingButton.isHidden)
    }

    func test_audioRecorderDidFinishRecordingAtURL_waveformVisualisationSucceedsSendImmediatelyIsTrueAndisVoiceRecordingConfirmationRequiredEnabled_updateContentByApplyingActionWasCalledAsExpected() {
        let location = URL.unique()
        var components = subject.components
        components.isVoiceRecordingConfirmationRequiredEnabled = true
        subject.components = components
        subject.content = .beginRecording
        subject.updateContentByApplyingAction(.touchUp)
        assetPropertiesLoader.loadPropertiesResult = .success(.init(url: location))
        audioAnalyser.analyseResult = .success([1, 2, 3])
        subject.audioRecorder(audioRecorder, didUpdateContext: .init(state: .recording, duration: 10, averagePower: 0))

        subject.audioRecorder(audioRecorder, didFinishRecordingAtURL: location)

        wait()

        XCTAssertTrue(audioPlayer.stopWasCalled)
        XCTAssertTrue(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithVC === subject)
        XCTAssertEqual(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithLocation, location)
        XCTAssertEqual(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithDuration, 10)
        XCTAssertEqual(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithWaveformData, [1, 2, 3])
        XCTAssertTrue(delegate.voiceRecordingDidStopRecordingWasCalledWithVC === subject)
        XCTAssertEqual(subject.content, .idle)
    }

    func test_audioRecorderDidFinishRecordingAtURL_waveformVisualisationSucceedsSendImmediatelyIsTrueAndVoiceRecordingConfirmInsteadOfSendDisabled_updateContentByApplyingActionWasCalledAsExpected() {
        let location = URL.unique()
        var components = subject.components
        components.isVoiceRecordingConfirmationRequiredEnabled = false
        subject.components = components
        subject.content = .beginRecording
        subject.updateContentByApplyingAction(.touchUp)
        assetPropertiesLoader.loadPropertiesResult = .success(.init(url: location))
        audioAnalyser.analyseResult = .success([1, 2, 3])
        subject.audioRecorder(audioRecorder, didUpdateContext: .init(state: .recording, duration: 10, averagePower: 0))

        subject.audioRecorder(audioRecorder, didFinishRecordingAtURL: location)

        wait()

        XCTAssertTrue(audioPlayer.stopWasCalled)
        XCTAssertTrue(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithVC === subject)
        XCTAssertEqual(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithLocation, location)
        XCTAssertEqual(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithDuration, 10)
        XCTAssertEqual(delegate.voiceRecordingAddAttachmentFromLocationWasCalledWithWaveformData, [1, 2, 3])
        XCTAssertTrue(delegate.voiceRecordingDidStopRecordingWasCalledWithVC === subject)
        XCTAssertTrue(delegate.voiceRecordingPublishMessageWasCalledWithVC === subject)
        XCTAssertEqual(subject.content, .idle)
    }

    // MARK: - audioRecorder(_:didFailWithError:)

    func test_audioRecorderDidFailWithError_contentWasSetToIdle() {
        subject.content = .beginRecording

        subject.audioRecorder(audioRecorder, didFailWithError: NSError(domain: "Test", code: -109))

        XCTAssertEqual(.idle, subject.content)
    }

    // MARK: - audioPlayer(_:didUpdateContext:)

    func test_audioPlayerDidUpdateContext_contentAndContextLocationsAreDifferent_liveRecordingViewWasConfiguredAsExpected() {
        subject.liveRecordingView.content = .init(isRecording: false, isPlaying: false, duration: 0, currentTime: 0, waveform: [1, 2, 3])
        subject.content = .init(
            state: .idle,
            duration: 10,
            location: .unique(),
            waveform: []
        )

        subject.audioPlayer(
            audioPlayer,
            didUpdateContext: .init(
                assetLocation: .unique(),
                duration: 0,
                currentTime: 0,
                state: .loading,
                rate: .normal,
                isSeeking: false
            )
        )

        XCTAssertEqual(
            subject.liveRecordingView.content,
            .init(isRecording: false, isPlaying: false, duration: 10, currentTime: 0, waveform: [1, 2, 3])
        )
    }

    func test_audioPlayerDidUpdateContext_contentAndContextLocationsAreTheSame_playerStateIsPlaying_liveRecordingViewWasConfiguredAsExpected() {
        subject.liveRecordingView.content = .init(isRecording: false, isPlaying: false, duration: 0, currentTime: 0, waveform: [1, 2, 3])
        subject.content = .init(
            state: .idle,
            duration: 10,
            location: .unique(),
            waveform: []
        )

        subject.audioPlayer(
            audioPlayer,
            didUpdateContext: .init(
                assetLocation: subject.content.location,
                duration: 15,
                currentTime: 2,
                state: .playing,
                rate: .normal,
                isSeeking: false
            )
        )

        XCTAssertEqual(
            subject.liveRecordingView.content,
            .init(isRecording: false, isPlaying: true, duration: 15, currentTime: 2, waveform: [1, 2, 3])
        )
    }

    func test_audioPlayerDidUpdateContext_contentAndContextLocationsAreTheSame_playerStateIsPaused_liveRecordingViewWasConfiguredAsExpected() {
        subject.liveRecordingView.content = .init(isRecording: false, isPlaying: false, duration: 0, currentTime: 0, waveform: [1, 2, 3])
        subject.content = .init(
            state: .idle,
            duration: 10,
            location: .unique(),
            waveform: []
        )

        subject.audioPlayer(
            audioPlayer,
            didUpdateContext: .init(
                assetLocation: subject.content.location,
                duration: 15,
                currentTime: 2,
                state: .paused,
                rate: .normal,
                isSeeking: false
            )
        )

        XCTAssertEqual(
            subject.liveRecordingView.content,
            .init(isRecording: false, isPlaying: false, duration: 15, currentTime: 2, waveform: [1, 2, 3])
        )
    }

    func test_audioPlayerDidUpdateContext_contentAndContextLocationsAreTheSame_playerStateIsStopped_liveRecordingViewWasConfiguredAsExpected() {
        subject.liveRecordingView.content = .init(isRecording: false, isPlaying: false, duration: 0, currentTime: 0, waveform: [1, 2, 3])
        subject.content = .init(
            state: .idle,
            duration: 10,
            location: .unique(),
            waveform: []
        )

        subject.audioPlayer(
            audioPlayer,
            didUpdateContext: .init(
                assetLocation: subject.content.location,
                duration: 15,
                currentTime: 2,
                state: .stopped,
                rate: .normal,
                isSeeking: false
            )
        )

        XCTAssertEqual(
            subject.liveRecordingView.content,
            .init(isRecording: false, isPlaying: false, duration: 15, currentTime: 0, waveform: [1, 2, 3])
        )
    }

    // MARK: - updateContent

    func test_updateContent_idle_viewIsConfiguredAsExpected() {
        assertViewController(for: .idle)
    }

    func test_updateContent_showingTip_viewIsConfiguredAsExpected() {
        subject.hideViewsDebouncer = .init(20, queue: .main)
        
        assertViewController(for: .showingTip)
    }

    func test_updateContent_recording_viewIsConfiguredAsExpected() {
        assertViewController(for: .recording)
    }

    func test_updateContent_locked_viewIsConfiguredAsExpected() {
        subject.hideViewsDebouncer = .init(20, queue: .main)
        
        assertViewController(for: .locked, initialContentStates: [.recording])
    }

    func test_updateContent_preview_viewIsConfiguredAsExpected() {
        subject.hideViewsDebouncer = .init(20, queue: .main)
        
        assertViewController(for: .preview, initialContentStates: [.recording, .locked])
    }

    func test_updateContent_preview_afterHideViewsDebouncerExecution_viewIsConfiguredAsExpected() {
        subject.hideViewsDebouncer = .init(0, queue: .main)

        assertViewController(for: .preview, initialContentStates: [.recording, .locked])
    }

    // MARK: - Private Helpers

    private func assertViewController(
        for contentState: VoiceRecordingVC.State,
        initialContentStates: [VoiceRecordingVC.State] = [.idle],
        record: Bool = false,
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        let viewController = ChatChannelVC()
        viewController.components = subject.components
        viewController.messageComposerVC.components = subject.components
        viewController.messageComposerVC.voiceRecordingVC.audioRecorder = audioRecorder
        viewController.messageComposerVC.voiceRecordingVC.components = subject.components
        viewController.messageComposerVC.voiceRecordingVC.hideViewsDebouncer = subject.hideViewsDebouncer
        let mock = ChatChannelController_Mock(
            channelQuery: .init(cid: .unique),
            channelListQuery: nil,
            client: .mock,
            isChannelAlreadyCreated: true
        )
        mock.channel_mock = .mock(cid: .unique, config: .mock(commands: []), ownCapabilities: [.sendMessage, .uploadFile])
        viewController.channelController = mock
        viewController.messageComposerVC.channelController = mock
        viewController.setUp()
        viewController.setUpLayout()
        viewController.setUpAppearance()

        if initialContentStates != [.idle] {
            for initialContentState in initialContentStates {
                // Setup initial state
                var content = viewController.messageComposerVC.voiceRecordingVC.content
                content.state = initialContentState
                viewController.messageComposerVC.voiceRecordingVC.content = content
            }
        }

        var content = viewController.messageComposerVC.voiceRecordingVC.content
        content.state = contentState
        viewController.messageComposerVC.voiceRecordingVC.content = content

        (0..<10).forEach { _ in
            audioRecorder.subscribeWasCalledWithSubscriber?.audioRecorder(audioRecorder, didUpdateContext: .init(
                state: .recording,
                duration: 10,
                averagePower: 0
            ))
        }

        audioRecorder.subscribeWasCalledWithSubscriber?.audioRecorder(audioRecorder, didUpdateContext: .init(
            state: .stopped,
            duration: 10,
            averagePower: 0
        ))

        wait()

        AssertSnapshot(
            viewController.view,
            variants: .onlyUserInterfaceStyles,
            record: record,
            line: line,
            file: file,
            function: function
        )
    }

    private func wait(for timeout: TimeInterval = defaultTimeout) {
        let waitExpectation = expectation(description: "Wait expectation")
        waitExpectation.isInverted = true
        wait(for: [waitExpectation], timeout: timeout)
    }
}

// MARK: - Mocks

private final class MockVoiceRecordingDelegate: VoiceRecordingDelegate {
    private(set) var voiceRecordingAddAttachmentFromLocationWasCalledWithVC: VoiceRecordingVC?
    private(set) var voiceRecordingAddAttachmentFromLocationWasCalledWithLocation: URL?
    private(set) var voiceRecordingAddAttachmentFromLocationWasCalledWithDuration: TimeInterval?
    private(set) var voiceRecordingAddAttachmentFromLocationWasCalledWithWaveformData: [Float]?

    private(set) var voiceRecordingPublishMessageWasCalledWithVC: VoiceRecordingVC?

    private(set) var voiceRecordingWillBeginRecordingWasCalledWithVC: VoiceRecordingVC?

    private(set) var voiceRecordingDidBeginRecordingWasCalledWithVC: VoiceRecordingVC?

    private(set) var voiceRecordingDidLockRecordingWasCalledWithVC: VoiceRecordingVC?

    private(set) var voiceRecordingDidStopRecordingWasCalledWithVC: VoiceRecordingVC?

    private(set) var voiceRecordingPresentFloatingViewWasCalledWithVC: VoiceRecordingVC?
    private(set) var voiceRecordingPresentFloatingViewWasCalledWithFloatingView: UIView?

    func voiceRecording(
        _ voiceRecordingVC: VoiceRecordingVC,
        addAttachmentFromLocation location: URL,
        duration: TimeInterval,
        waveformData: [Float]
    ) {
        voiceRecordingAddAttachmentFromLocationWasCalledWithVC = voiceRecordingVC
        voiceRecordingAddAttachmentFromLocationWasCalledWithLocation = location
        voiceRecordingAddAttachmentFromLocationWasCalledWithDuration = duration
        voiceRecordingAddAttachmentFromLocationWasCalledWithWaveformData = waveformData
    }

    func voiceRecordingPublishMessage(_ voiceRecordingVC: VoiceRecordingVC) {
        voiceRecordingPublishMessageWasCalledWithVC = voiceRecordingVC
    }

    func voiceRecordingWillBeginRecording(_ voiceRecordingVC: VoiceRecordingVC) {
        voiceRecordingWillBeginRecordingWasCalledWithVC = voiceRecordingVC
    }

    func voiceRecordingDidBeginRecording(_ voiceRecordingVC: VoiceRecordingVC) {
        voiceRecordingDidBeginRecordingWasCalledWithVC = voiceRecordingVC
    }

    func voiceRecordingDidLockRecording(_ voiceRecordingVC: VoiceRecordingVC) {
        voiceRecordingDidLockRecordingWasCalledWithVC = voiceRecordingVC
    }

    func voiceRecordingDidStopRecording(_ voiceRecordingVC: VoiceRecordingVC) {
        voiceRecordingDidStopRecordingWasCalledWithVC = voiceRecordingVC
    }

    func voiceRecording(
        _ voiceRecordingVC: VoiceRecordingVC,
        presentFloatingView floatingView: UIView
    ) {
        voiceRecordingPresentFloatingViewWasCalledWithVC = voiceRecordingVC
        voiceRecordingPresentFloatingViewWasCalledWithFloatingView = floatingView
    }
}

private final class SpyVoiceRecordingVC: VoiceRecordingVC {
    private(set) var updateContentByApplyingActionWasCalledWithAction: Action?

    override func updateContentByApplyingAction(_ action: Action) {
        updateContentByApplyingActionWasCalledWithAction = action
    }
}
