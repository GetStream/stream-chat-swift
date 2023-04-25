//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

open class RecordingViewManager: AudioRecordingDelegate, AudioPlayingDelegate {
    struct RecordingSession: Equatable {
        var isRecording: Bool
        var previousComposerContent: ComposerVC.Content
        var duration: TimeInterval
        var location: URL?
        var waveform: [Float]

        static let empty = RecordingSession(
            isRecording: false,
            previousComposerContent: .initial(),
            duration: 0,
            location: nil,
            waveform: []
        )
    }

    public weak var composerVC: ComposerVC?
    public let composerView: ComposerView

    open lazy var recordingTipView: RecordingTipView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var slideToCancelView: SlideToCancelView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var recordingIndicatorView: RecordingIndicatorView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var lockIndicatorView: LockIndicatorView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var recordingPlaybackIndicatorView: RecordingPlaybackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var discardRecordingButton: UIButton = .init(type: .system)
        .withoutAutoresizingMaskConstraints

    open lazy var stopRecordingButton: UIButton = .init(type: .system)
        .withoutAutoresizingMaskConstraints

    open lazy var stopRecordingButtonContainer: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var sendButton: UIButton = composerView.components
        .sendButton
        .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "sendButton")

    public lazy var confirmButton: UIButton = composerView.components
        .confirmButton.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "confirmButton")

    open lazy var biDirectionalPanGestureRecognizer: BiDirectionalPanGestureRecognizer = .init()

    open lazy var audioRecorder: AudioRecording = composerView.components
        .audioRecorder
        .build()

    open var audioPlayer: AudioPlaying? {
        didSet { audioPlayer?.connect(delegate: self) }
    }

    open lazy var audioSessionFeedbackGenerator: AudioSessionFeedbackGenerator = composerView
        .components
        .audioSessionFeedbackGenerator
        .init()

    open lazy var audioAnalysisFactory: AudioAnalysisFactory = .init(
        assetPropertiesLoader: StreamAssetPropertyLoader()
    )

    private var recordingSession: RecordingSession = .empty
    private var sendImmediately = false

    // MARK: - Lifecycle

    init(
        _ composerVC: ComposerVC
    ) {
        self.composerVC = composerVC
        composerView = composerVC.composerView
    }

    // MARK: - UI Lifecycle

    func setUp() {
        guard
            let components = composerVC?.components,
            components.asyncMessagesEnabled
        else { return }

        biDirectionalPanGestureRecognizer.shouldReceiveEventHandler = { true }
        biDirectionalPanGestureRecognizer.touchesBeganHandler = { [weak self] in self?.didTapRecord() }
        biDirectionalPanGestureRecognizer.completionHandler = { [weak self] in self?.didTouchUp() }
        biDirectionalPanGestureRecognizer.horizontalMovementHandler = { [weak self] in self?.didPanHorizontally($0) }
        biDirectionalPanGestureRecognizer.verticalMovementHandler = { [weak self] in self?.didPanVertically($0) }
        composerView.addGestureRecognizer(biDirectionalPanGestureRecognizer)

        composerView.recordButton.incompleteHandler = { [weak self] in self?.showRecordingTip() }
        composerView.recordButton.completedHandler = { [weak self] in self?.beginRecording() }

        discardRecordingButton.setImage(
            composerView.appearance.images.trash.tinted(
                with: composerView.appearance.colorPalette.accentPrimary
            ),
            for: .normal
        )

        discardRecordingButton.addTarget(
            self,
            action: #selector(didTapDiscard(_sender:)),
            for: .touchUpInside
        )

        stopRecordingButton.setImage(composerView.appearance.images.stop, for: .normal)
        stopRecordingButton.tintColor = composerView.appearance.colorPalette.alert

        stopRecordingButton.addTarget(
            self,
            action: #selector(didTapStop(_sender:)),
            for: .touchUpInside
        )

        stopRecordingButtonContainer.axis = .horizontal
        let spacerA = UIStackView().withoutAutoresizingMaskConstraints
        let spacerB = UIStackView().withoutAutoresizingMaskConstraints
        stopRecordingButtonContainer.addArrangedSubview(spacerA)
        stopRecordingButtonContainer.addArrangedSubview(stopRecordingButton)
        stopRecordingButtonContainer.addArrangedSubview(spacerB)
        spacerB.widthAnchor.pin(equalTo: spacerA.widthAnchor).isActive = true

        sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)
        sendButton.isEnabled = true

        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        confirmButton.isEnabled = true

        [stopRecordingButton, discardRecordingButton, sendButton, confirmButton].forEach { button in
            button.pin(anchors: [.width], to: 35)
            button.pin(anchors: [.height], to: 40)
        }

        audioRecorder.subscribe(self)

        recordingPlaybackIndicatorView.playbackButton.addTarget(
            self,
            action: #selector(didTapPlayPause),
            for: .touchUpInside
        )

        recordingPlaybackIndicatorView.waveformView.slider.addTarget(
            self,
            action: #selector(didSeekTime),
            for: .valueChanged
        )
    }

    // MARK: - AudioRecordingDelegate

    public func audioRecorder(
        _ audioRecorder: AudioRecording,
        didUpdateContext context: AudioRecordingContext
    ) {
        recordingSession = .init(
            isRecording: true,
            previousComposerContent: recordingSession.previousComposerContent,
            duration: context.duration,
            location: nil,
            waveform: recordingSession.waveform
        )
        waveformDataForCurrentRecordingSession(averagePower: context.averagePower)
        recordingIndicatorView.content = context.duration
        recordingPlaybackIndicatorView.content = .init(
            isRecording: true,
            isPlaying: false,
            duration: context.duration,
            currentTime: context.duration,
            waveform: recordingSession.waveform
        )
    }

    public func audioRecorder(
        _ audioRecorder: AudioRecording,
        didFinishRecordingAtURL location: URL
    ) {
        guard recordingSession != .empty else {
            return
        }

        waveformDataForCurrentRecordingSession(location: location)

        recordingSession = .init(
            isRecording: false,
            previousComposerContent: recordingSession.previousComposerContent,
            duration: recordingSession.duration,
            location: location,
            waveform: recordingSession.waveform
        )
        recordingPlaybackIndicatorView.content = .init(
            isRecording: false,
            isPlaying: false,
            duration: recordingSession.duration,
            currentTime: 0,
            waveform: recordingSession.waveform
        )
        stopRecordingButton.isHidden = true

        if sendImmediately {
            handleSendImmediately()
            sendImmediately = false
        }
    }

    public func audioRecorder(
        _ audioRecorder: AudioRecording,
        didFailWithError error: Error
    ) {
        log.error(error)
        recordingSession = .empty
        setUpViewForCancel()
    }

    public func audioRecorderDeletedRecording(_ audioRecorder: AudioRecording) {
        debugPrint(#function)
    }

    // MARK: - AudioPlayingDelegate

    public func audioPlayer(
        _ audioPlayer: AudioPlaying,
        didUpdateContext context: AudioPlaybackContext
    ) {
        let isActive = context.assetLocation == recordingSession.location

        switch (isActive, context.state) {
        case (true, .playing), (true, .paused):
            recordingPlaybackIndicatorView.content = .init(
                isRecording: false,
                isPlaying: context.state == .playing,
                duration: context.duration,
                currentTime: context.currentTime,
                waveform: recordingPlaybackIndicatorView.content.waveform
            )
        case (true, .stopped):
            recordingPlaybackIndicatorView.content = .init(
                isRecording: false,
                isPlaying: false,
                duration: context.duration,
                currentTime: 0,
                waveform: recordingPlaybackIndicatorView.content.waveform
            )
        case (false, _):
            recordingPlaybackIndicatorView.content = .init(
                isRecording: false,
                isPlaying: false,
                duration: recordingSession.duration,
                currentTime: 0,
                waveform: recordingPlaybackIndicatorView.content.waveform
            )
        default:
            break
        }
    }

    // MARK: - Action Handlers

    open func showRecordingTip() {
        guard composerVC?.content.state != .recording else { return }

        recordingTipView.alpha = 1
        Animate { [weak self, recordingTipView] in
            self?.showFloatingView(recordingTipView)
        } completion: { _ in
            Animate(delay: 2) { [weak self] in
                self?.recordingTipView.alpha = 0
            } completion: { [weak self] _ in
                self?.recordingTipView.removeFromSuperview()
            }
        }
    }

    open func beginRecording() {
        guard composerVC?.content.state != .recording else { return }

        audioSessionFeedbackGenerator.feedbackForBeginRecording()

        if let previousComposerContent = composerVC?.content {
            recordingSession = .init(
                isRecording: true,
                previousComposerContent: previousComposerContent,
                duration: 0,
                waveform: []
            )
        }
        audioPlayer?.stop()
        composerVC?.content.recording()
        setUpViewForRecording()

        audioRecorder.beginRecording()
    }

    open func didPanHorizontally(_ point: CGFloat) {
        guard composerVC?.content.state == .recording else {
            return
        }

        let diff = composerView.bounds.size.width - point

        guard diff > composerView.components.asyncMessageSlideToCancelDistance else {
            slideToCancelView.alpha = (composerView.components.asyncMessageSlideToCancelDistance - diff) / composerView.components.asyncMessageSlideToCancelDistance
            return
        }

        audioSessionFeedbackGenerator.feedbackForCancelRecording()
        didTapStop(_sender: stopRecordingButton)
        setUpViewForCancel()
    }

    open func didPanVertically(_ point: CGFloat) {
        guard composerVC?.content.state == .recording else {
            return
        }

        let diff = composerView.bounds.size.height - point

        guard diff > composerView.components.asyncMessageLockDistance else {
            lockIndicatorView.bottomPaddingConstraint.constant = max(diff, lockIndicatorView.minimumBottomPadding)
            lockIndicatorView.chevronImageView.alpha = (composerView.components.asyncMessageLockDistance - diff) / composerView.components.asyncMessageLockDistance
            return
        }

        setUpViewForLocked()
        composerVC?.content.recordingLocked()
    }

    open func didTouchUp() {
        guard composerVC?.content.state == .recording else {
            return
        }
        sendImmediately = true
        audioRecorder.stopRecording()
    }

    open func handleSendImmediately() {
        guard let location = recordingSession.location else {
            setUpViewForCancel()
            return
        }

        publishMessage(location: location) { error in
            if let error = error {
                log.error(error)
                self.didTapDiscard(_sender: self.discardRecordingButton)
            } else {
                self.recordingSession = .empty
                if !self.composerView.components.asyncMessagesMultiSendEnabled {
                    self.composerVC?.publishMessage(sender: self.composerView.sendButton)
                }
                self.setUpViewForSendImmediately()
                self.setUpViewForConfirmOrSend()
            }
        }
    }

    @objc open func didTapRecord() {
        audioSessionFeedbackGenerator.feedbackForBeginRecording()
        setUpViewForInteractionStarted()
    }

    @objc open func didTapDiscard(_sender: UIButton) {
        audioRecorder.stopRecording()
        audioPlayer?.stop()
        setUpViewForDiscard()
        audioSessionFeedbackGenerator.feedbackForDiscardRecording()
    }

    @objc open func didTapStop(_sender: UIButton) {
        audioRecorder.stopRecording()
        audioSessionFeedbackGenerator.feedbackForStop()
    }

    @objc open func didTapPlayPause(_ sender: UIButton) {
        guard let location = recordingSession.location else {
            return
        }

        if sender.isSelected {
            audioPlayer?.pause()
            audioSessionFeedbackGenerator.feedbackForPause()
        } else {
            audioPlayer?.loadAsset(from: location)
            audioSessionFeedbackGenerator.feedbackForPlay()
        }
    }

    @objc open func didTapSend(_ sender: UIButton) {
        if recordingSession.isRecording {
            sendImmediately = true
            audioRecorder.stopRecording()
            return
        }

        guard let location = recordingSession.location else {
            didTapDiscard(_sender: discardRecordingButton)
            return
        }

        publishMessage(location: location) { error in
            if let error = error {
                log.error(error)
                self.didTapDiscard(_sender: self.discardRecordingButton)
            } else {
                self.recordingSession = .empty
                self.composerVC?.publishMessage(sender: self.composerView.sendButton)
                self.setUpViewForConfirmOrSend()
            }
        }
    }

    @objc open func didTapConfirm(_ sender: UIButton) {
        if recordingSession.isRecording {
            sendImmediately = true
            audioRecorder.stopRecording()
            return
        }

        guard let location = recordingSession.location else {
            didTapDiscard(_sender: discardRecordingButton)
            return
        }

        publishMessage(location: location) { error in
            if let error = error {
                log.error(error)
                self.didTapDiscard(_sender: self.discardRecordingButton)
            } else {
                self.recordingSession = .empty
                self.setUpViewForConfirmOrSend()
            }
        }
    }

    @objc open func didSeekTime(_ sender: UISlider) {
        audioPlayer?.seek(to: TimeInterval(sender.value))
        audioSessionFeedbackGenerator.feedbackForSeeking()
    }

    // MARK: - Helpers

    open func showFloatingView(_ floatingView: UIView) {
        if let parent = composerVC?.parent {
            floatingView.translatesAutoresizingMaskIntoConstraints = false
            parent.view.addSubview(floatingView)
            NSLayoutConstraint.activate([
                floatingView.leadingAnchor.pin(equalTo: parent.view.leadingAnchor),
                floatingView.trailingAnchor.pin(equalTo: parent.view.trailingAnchor),
                composerView.topAnchor.pin(equalTo: floatingView.bottomAnchor),
                floatingView.topAnchor.pin(greaterThanOrEqualTo: parent.view.safeAreaLayoutGuide.topAnchor)
            ])
        }
    }

    open func setUpViewForInteractionStarted() {
        guard recordingTipView.superview != nil else { return }
        Animate(delay: 2) { [weak self] in
            self?.recordingTipView.alpha = 0
        } completion: { [weak self] _ in
            self?.recordingTipView.removeFromSuperview()
        }
    }

    open func setUpViewForRecording() {
        lockIndicatorView.isHidden = true
        lockIndicatorView.alpha = 1
        showFloatingView(lockIndicatorView)
        lockIndicatorView.setNeedsLayout()

        Animate { [lockIndicatorView, composerView, slideToCancelView, recordingIndicatorView] in
            lockIndicatorView.isHidden = false
            lockIndicatorView.layoutIfNeeded()
            composerView.centerContainer.insertArrangedSubview(recordingIndicatorView, at: 0)
            composerView.centerContainer.insertArrangedSubview(slideToCancelView, at: 1)
        }
    }

    open func setUpViewForCancel() {
        resetLockView()
        Animate { [recordingIndicatorView, slideToCancelView, composerView, weak self] in
            composerView.centerContainer.removeArrangedSubview(recordingIndicatorView)
            composerView.centerContainer.removeArrangedSubview(slideToCancelView)
            if let recordingSession = self?.recordingSession, recordingSession != .empty {
                self?.composerVC?.content = recordingSession.previousComposerContent
                self?.recordingSession = .empty
            } else {
                self?.composerVC?.content.clear()
            }
        }
    }

    open func setUpViewForSendImmediately() {
        resetLockView()
        Animate { [recordingIndicatorView, slideToCancelView, composerView] in
            composerView.centerContainer.removeArrangedSubview(recordingIndicatorView)
            composerView.centerContainer.removeArrangedSubview(slideToCancelView)
        }
    }

    open func setUpViewForLocked() {
        Animate {
            self.stopRecordingButton.isHidden = false
            self.lockIndicatorView.content = true
            self.composerView.headerView.embed(self.recordingPlaybackIndicatorView)
            self.composerView.centerContainer.removeArrangedSubview(self.recordingIndicatorView)
            self.composerView.centerContainer.removeArrangedSubview(self.slideToCancelView)
            self.composerView.centerContainer.insertArrangedSubview(self.discardRecordingButton, at: 0)
            self.composerView.centerContainer.insertArrangedSubview(self.stopRecordingButtonContainer, at: 1)
            if self.composerView.components.asyncMessagesMultiSendEnabled {
                self.composerView.trailingContainer.addArrangedSubview(self.confirmButton)
            } else {
                self.composerView.trailingContainer.addArrangedSubview(self.sendButton)
            }
        } completion: { completed in
            guard completed else { return }
            Animate(delay: 2) {
                self.lockIndicatorView.alpha = 0
            } completion: { completed in
                guard completed else { return }
                self.lockIndicatorView.isHidden = true
                self.lockIndicatorView.alpha = 1
                self.lockIndicatorView.content = false
                self.lockIndicatorView.removeFromSuperview()
                self.lockIndicatorView.isHidden = false
            }
        }
    }

    open func setUpViewForDiscard() {
        resetLockView()
        Animate {
            self.composerView.centerContainer.removeArrangedSubview(self.discardRecordingButton)
            self.composerView.centerContainer.removeArrangedSubview(self.stopRecordingButtonContainer)

            [self.sendButton, self.confirmButton].forEach { button in
                if button.superview != nil {
                    self.composerView.trailingContainer.removeArrangedSubview(button)
                }
            }

            if self.recordingSession != .empty {
                self.composerVC?.content = self.recordingSession.previousComposerContent
                self.recordingSession = .empty
            } else {
                self.composerVC?.content.clear()
            }
        }
    }

    open func setUpViewForConfirmOrSend() {
        resetLockView()
        Animate {
            self.composerView.centerContainer.removeArrangedSubview(self.discardRecordingButton)
            self.composerView.centerContainer.removeArrangedSubview(self.stopRecordingButtonContainer)
            self.recordingPlaybackIndicatorView.removeFromSuperview()

            [self.sendButton, self.confirmButton].forEach { button in
                if button.superview != nil {
                    self.composerView.trailingContainer.removeArrangedSubview(button)
                }
            }
        }
    }

    open func resetLockView() {
        Animate {
            self.lockIndicatorView.alpha = 0
        } completion: { completed in
            guard completed else { return }
            self.lockIndicatorView.content = false
            self.lockIndicatorView.removeFromSuperview()
            self.lockIndicatorView.bottomPaddingConstraint.constant = self.lockIndicatorView.minimumBottomPadding
            self.lockIndicatorView.alpha = 1
        }
    }

    open func waveformDataForCurrentRecordingSession(
        location: URL? = nil,
        averagePower: Float? = nil
    ) {
        if let location = location {
            let rendererResult = audioAnalysisFactory
                .buildAudioRenderer(fromLiveAudioURL: location)

            switch rendererResult {
            case let .success(renderer):
                let waveform = renderer.render(targetSamples: 100)
                recordingSession.waveform = waveform
            case let .failure(error):
                log.error(error)
            }
        } else if let averagePower = averagePower {
            recordingSession.waveform.append(averagePower)
        }
    }

    open func publishMessage(
        location: URL,
        _ completionHandler: ((Error?) -> Void)?
    ) {
        audioPlayer?.stop()

        do {
            composerVC?.content = recordingSession.previousComposerContent
            let extraData: [String: RawJSON] = [
                "duration": .number(recordingSession.duration),
                "waveform": .array(recordingSession.waveform.map { .number(Double($0)) })
            ]

            try composerVC?.addAttachmentToContent(
                from: location,
                type: .voiceRecording,
                info: [:],
                extraData: extraData
            )

            completionHandler?(nil)
        } catch {
            didTapDiscard(_sender: discardRecordingButton)
            completionHandler?(error)
        }
    }
}
