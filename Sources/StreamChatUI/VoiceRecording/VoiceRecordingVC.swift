//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// A ViewController that manages all aspects of the voice recording from the ComposerVC.
///
/// The VoiceRecordingVC even though it's a ViewController (as it manages a view) it doesn't
/// manage its own view. Instead, the view property of the ViewController has been overridden and returns
/// the ComposerView.
/// - Important: Avoid adding the ViewController's view in view hierarchy.
open class VoiceRecordingVC: _ViewController, ComponentsProvider, AppearanceProvider, AudioRecordingDelegate, AudioPlayingDelegate, UIGestureRecognizerDelegate {
    // MARK: - Nested Types

    public struct State: RawRepresentable, Equatable {
        public typealias RawValue = String
        public let rawValue: String
        public var description: String { rawValue.uppercased() }
        public init(rawValue: RawValue) { self.rawValue = rawValue }

        public static var idle = State(rawValue: "idle")
        public static var showingTip = State(rawValue: "showingTip")
        public static var recording = State(rawValue: "recording")
        public static var locked = State(rawValue: "locked")
        public static var preview = State(rawValue: "preview")
    }

    public struct Action: RawRepresentable, Equatable {
        public typealias RawValue = String
        public let rawValue: String
        public var description: String { rawValue.uppercased() }
        public init(rawValue: RawValue) { self.rawValue = rawValue }

        public static var tapRecord = Action(rawValue: "tapRecord")
        public static var showTip = Action(rawValue: "showTip")
        public static var beginRecording = Action(rawValue: "beginRecording")
        public static var touchUp = Action(rawValue: "touchUp")
        public static var cancel = Action(rawValue: "cancel")
        public static var lock = Action(rawValue: "lock")
        public static var stop = Action(rawValue: "stop")
        public static var discard = Action(rawValue: "discard")
        public static var send = Action(rawValue: "send")
        public static var confirm = Action(rawValue: "confirm")
        public static var publishMessage = Action(rawValue: "publishMessage")
        public static var play = Action(rawValue: "play")
        public static var pause = Action(rawValue: "pause")
    }

    public struct Content: Equatable {
        /// The current state of the recording flow.
        public var state: State

        /// The duration of the current (active or in preview) recording.
        public var duration: TimeInterval

        /// If the recording is in preview or has been stopped, this URL will be the location of the
        /// audio file on the device.
        public var location: URL?

        /// The data that we can use to render a waveform visualisation of the recording.
        public var waveform: [Float]

        public init(
            state: State,
            duration: TimeInterval,
            location: URL? = nil,
            waveform: [Float]
        ) {
            self.state = state
            self.duration = duration
            self.location = location
            self.waveform = waveform
        }

        /// The content the VoiceRecordingVC will have when is `idle` (no active recording or in preview.)
        public static let idle = Content(
            state: .idle,
            duration: 0,
            location: nil,
            waveform: []
        )

        /// The content the VoiceRecordingVC will have when we have an unlocked active recording.
        public static let beginRecording = Content(
            state: .recording,
            duration: 0,
            location: nil,
            waveform: []
        )

        /// A helper method to call when the user locks the currently active recording.
        public mutating func lock() {
            state = .locked
        }

        /// A helper method to update the current Content's duration
        public mutating func updatedWithDuration(_ duration: TimeInterval) {
            self.duration = duration
        }

        /// A helper method to update the current Content's location
        public mutating func updatedWithLocation(_ location: URL) {
            self.location = location
        }

        /// A helper method to update the current Content's waveform
        public mutating func updatedWithWaveform(_ dataPoint: Float) {
            waveform.append(dataPoint)
        }
    }

    // MARK: - Content

    open var content: Content = .idle {
        didSet {
            if oldValue.state != content.state {
                updateContent()
            }
        }
    }

    // MARK: - Configuration Properties

    /// The distance (in pixels) the user needs to slide to the leading side of the view to cancel a recording.
    open var slideToCancelDistance: CGFloat = 75

    /// The distance (in pixels) the user needs to slide to the top side of the view to lock the recording view.
    open var lockDistance: CGFloat = 50

    /// The number of samples (dataPoints) we want to extract from a recording in order to render a
    /// waveform visualisation of it.
    open var waveformTargetSamples: Int = 100

    // MARK: - Delegate & ComposerView

    /// The delegate which the `VoiceRecordingVC` will ask for support on presenting views and
    /// communicating the state of  the recording flow to its parent controller.
    public weak var delegate: VoiceRecordingDelegate?

    private let composerView: ComposerView
    public var centerContainer: ContainerStackView { composerView.centerContainer }
    public var trailingContainer: ContainerStackView { composerView.trailingContainer }
    public var recordButton: RecordButton { composerView.recordButton }
    public var headerView: UIView { composerView.headerView }

    override open var view: UIView! {
        get { composerView }
        set { _ = newValue }
    }

    // MARK: - Subviews

    /// A view that is being used to display a tip to user when the tap duration on the recording button wasn't
    /// long enough (the display of this view relates to `RecordButton.minimumPressDuration`).
    open lazy var recordingTipView: RecordingTipView = .init()
        .withoutAutoresizingMaskConstraints

    /// A view that during an unlocked recording, displays information on how to cancel the active recording.
    open lazy var slideToCancelView: SlideToCancelView = .init()
        .withoutAutoresizingMaskConstraints

    /// A view that indicates to the user that we are currently recording audio.
    open lazy var recordingIndicatorView: RecordingIndicatorView = .init()
        .withoutAutoresizingMaskConstraints

    /// A view that indicates to the user if the currently active recording is locked or not.
    open lazy var lockIndicatorView: LockIndicatorView = .init()
        .withoutAutoresizingMaskConstraints

    /// A view that during a locked recording, displays information about the active recording or its preview.
    open lazy var liveRecordingView: LiveRecordingView = .init()
        .withoutAutoresizingMaskConstraints

    /// A button that when tapped will discard the current recording.
    open lazy var discardRecordingButton: UIButton = .init(type: .system)
        .withoutAutoresizingMaskConstraints

    /// A button that when tapped will stop the currently active recording.
    open lazy var stopRecordingButton: UIButton = .init(type: .system)
        .withoutAutoresizingMaskConstraints

    /// As the stop button is being presented in the centre, between the discard and the confirm/send
    /// buttons, the container ensures that it will be centered.
    open lazy var stopRecordingButtonContainer: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    /// A button that when tapped will add the current recording in the composer's message and
    /// send(publish) it.
    open lazy var sendButton: UIButton = components
        .sendButton
        .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "sendButton")

    /// A button that when tapped will add the current recording in the composer's message and
    /// will move the user to the Composer's attachment preview of the message.
    open lazy var confirmButton: UIButton = components
        .confirmButton.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "confirmButton")

    // MARK: - Components

    /// The gestureRecogniser used to identify touch movements in the horizontal or vertical axis.
    open lazy var bidirectionalPanGestureRecogniser: BidirectionalPanGestureRecogniser = .init()

    /// The audioRecorder that will be used to record new VoiceRecordings.
    open lazy var audioRecorder: AudioRecording = components
        .audioRecorder
        .init()

    /// The audioPlayer that will be used, during the preview of a VoiceRecording, for the playback of the
    /// audio file.
    open var audioPlayer: AudioPlaying? {
        didSet { audioPlayer?.subscribe(self) }
    }

    /// The object will be asked to provide haptic feedback when actions occur during the recording process.
    open lazy var audioSessionFeedbackGenerator: AudioSessionFeedbackGenerator = components
        .audioSessionFeedbackGenerator
        .init()

    /// An object responsible for extracting the required number of samples from an audio file, that can be
    /// used to render a waveform visualisation.
    open lazy var audioAnalysisFactory: AudioAnalysisEngine? = try? .init(
        assetPropertiesLoader: StreamAssetPropertyLoader()
    )

    /// An object that is being used to hide views (recordingTipView and lockIndicatorView) on the specified
    /// interval, after their presentation to the user.
    open lazy var hideViewsDebouncer: Debouncer = .init(2, queue: .main)

    // MARK: - Private Properties

    /// A property used to track if after the successful (async) creation of a recording, we should proceed
    /// on sending/confirming immediately. The value will be true in the following 2 scenarios:
    /// 1. During an unlocked recording, the user lift their finger off the screen.
    /// 2. During a locked recording, the user taps the send/confirm button.
    private var sendImmediately = false

    // MARK: - Lifecycle

    public required init(
        composerView: ComposerView
    ) {
        self.composerView = composerView
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UI Lifecycle

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayer?.pause()
        audioRecorder.stopRecording()
    }

    override open func setUp() {
        super.setUp()

        guard components.isVoiceRecordingEnabled else { return }

        bidirectionalPanGestureRecogniser.touchesEndedHandler = { [weak self] in
            guard self?.content != .idle else { return }
            self?.updateContentByApplyingAction(.touchUp)
        }
        bidirectionalPanGestureRecogniser.horizontalMovementHandler = { [weak self] in self?.didPanHorizontally($0) }
        bidirectionalPanGestureRecogniser.verticalMovementHandler = { [weak self] in self?.didPanVertically($0) }
        view.addGestureRecognizer(bidirectionalPanGestureRecogniser)
        bidirectionalPanGestureRecogniser.delegate = self

        recordButton.touchDownHandler = { [weak self] in self?.updateContentByApplyingAction(.tapRecord) }
        recordButton.incompleteHandler = { [weak self] in self?.updateContentByApplyingAction(.showTip) }
        recordButton.completedHandler = { [weak self] in self?.updateContentByApplyingAction(.beginRecording) }

        discardRecordingButton.setImage(
            appearance.images.trash.tinted(
                with: appearance.colorPalette.accentPrimary
            ),
            for: .normal
        )

        discardRecordingButton.addTarget(
            self,
            action: #selector(didTapDiscard(_:)),
            for: .touchUpInside
        )

        stopRecordingButton.setImage(appearance.images.stop, for: .normal)
        stopRecordingButton.tintColor = appearance.colorPalette.alert
        stopRecordingButton.addTarget(
            self,
            action: #selector(didTapStop(_:)),
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

        liveRecordingView.playbackButton.addTarget(
            self,
            action: #selector(didTapPlayPause),
            for: .touchUpInside
        )
        liveRecordingView.waveformView.slider.addTarget(
            self,
            action: #selector(didSeekTime),
            for: .valueChanged
        )
    }

    override open func updateContent() {
        switch content.state {
        case .idle:
            delegate?.voiceRecordingDidStopRecording(self)
            hideViewsDebouncer.invalidate()
            Animate { [weak self] in
                guard let self = self else { return }

                self.lockIndicatorView.alpha = 0

                [
                    self.discardRecordingButton,
                    self.stopRecordingButtonContainer,
                    self.recordingIndicatorView,
                    self.slideToCancelView
                ].forEach {
                    if $0.superview == self.centerContainer {
                        self.centerContainer.removeArrangedSubview($0)
                    }
                }

                [self.sendButton, self.confirmButton].forEach {
                    if $0.superview == self.trailingContainer {
                        self.trailingContainer.removeArrangedSubview($0)
                    }
                }

                self.liveRecordingView.removeFromSuperview()

                self.recordingTipView.alpha = 0
            } completion: { [weak self] completed in
                guard completed, let self = self else { return }
                self.lockIndicatorView.removeFromSuperview()
                self.lockIndicatorView.bottomPaddingConstraint.constant = self.lockIndicatorView.minimumBottomPadding
                self.lockIndicatorView.alpha = 1
                self.recordingTipView.removeFromSuperview()
            }

        case .showingTip:
            recordingTipView.alpha = 1
            Animate { [weak self] in
                guard let self = self else { return }
                self.delegate?.voiceRecording(self, presentFloatingView: self.recordingTipView)
            } completion: { [weak self] completed in
                guard completed else { return }
                self?.hideViewsDebouncer.execute { [weak self] in
                    Animate { [weak self] in
                        self?.recordingTipView.alpha = 0
                    } completion: { [weak self] completed in
                        guard completed else { return }
                        self?.recordingTipView.removeFromSuperview()
                    }
                }
            }

        case .recording:
            delegate?.voiceRecordingDidBeginRecording(self)

            lockIndicatorView.isHidden = true
            lockIndicatorView.alpha = 1
            delegate?.voiceRecording(self, presentFloatingView: lockIndicatorView)
            lockIndicatorView.content = false
            lockIndicatorView.setNeedsLayout()

            Animate { [weak self] in
                guard let self = self else { return }
                self.lockIndicatorView.isHidden = false
                self.lockIndicatorView.layoutIfNeeded()
                self.centerContainer.insertArrangedSubview(self.recordingIndicatorView, at: 0)
                self.centerContainer.insertArrangedSubview(self.slideToCancelView, at: 1)
            }

        case .locked:
            delegate?.voiceRecordingDidLockRecording(self)

            Animate { [weak self] in
                guard let self = self else { return }
                self.stopRecordingButton.isHidden = false
                self.lockIndicatorView.content = true
                self.headerView.embed(self.liveRecordingView)
                self.centerContainer.removeArrangedSubview(self.recordingIndicatorView)
                self.centerContainer.removeArrangedSubview(self.slideToCancelView)
                self.centerContainer.insertArrangedSubview(self.discardRecordingButton, at: 0)
                self.centerContainer.insertArrangedSubview(self.stopRecordingButtonContainer, at: 1)
                if self.components.isVoiceRecordingConfirmationRequiredEnabled {
                    self.trailingContainer.addArrangedSubview(self.confirmButton)
                } else {
                    self.trailingContainer.addArrangedSubview(self.sendButton)
                }
            } completion: { [weak self] completed in
                guard completed else { return }
                self?.hideViewsDebouncer.execute { [weak self] in
                    Animate {
                        self?.lockIndicatorView.alpha = 0
                    } completion: { [weak self] completed in
                        guard completed else { return }
                        self?.lockIndicatorView.isHidden = true
                        self?.lockIndicatorView.alpha = 1
                        self?.lockIndicatorView.content = false
                        self?.lockIndicatorView.removeFromSuperview()
                        self?.lockIndicatorView.isHidden = false
                    }
                }
            }

        case .preview:
            audioRecorder.stopRecording()
            audioSessionFeedbackGenerator.feedbackForStop()
        default:
            break
        }
    }

    // MARK: - Open Action Handlers

    open func updateContentByApplyingAction(_ action: Action) {
        switch action {
        case .tapRecord where content.state == .idle || content.state == .showingTip:
            audioSessionFeedbackGenerator.feedbackForPreparingRecording()
            content = .idle

        case .showTip where content == .idle:
            var content = content
            content.state = .showingTip
            self.content = content

        case .beginRecording:
            audioSessionFeedbackGenerator.feedbackForBeginRecording()
            delegate?.voiceRecordingWillBeginRecording(self)
            audioPlayer?.stop()
            audioRecorder.beginRecording { [weak self] in self?.content = .beginRecording }

        case .touchUp where content.state == .recording:
            sendImmediately = true
            audioRecorder.stopRecording()

        case .cancel:
            audioSessionFeedbackGenerator.feedbackForCancelRecording()
            audioRecorder.stopRecording()
            content = .idle

        case .lock:
            content.lock()

        case .discard:
            audioSessionFeedbackGenerator.feedbackForDiscardRecording()
            audioRecorder.stopRecording()
            audioPlayer?.stop()
            delegate?.voiceRecordingDidStopRecording(self)
            content = .idle

        case .stop:
            audioRecorder.stopRecording()
            audioSessionFeedbackGenerator.feedbackForStop()

        case .send where content.location == nil,
             .confirm where content.location == nil:

            sendImmediately = true
            audioRecorder.stopRecording()

        case .send where content.location != nil,
             .confirm where content.location != nil:
            updateContentByApplyingAction(.publishMessage)

        case .publishMessage where content.location != nil:
            audioPlayer?.stop()
            delegate?.voiceRecording(
                self,
                addAttachmentFromLocation: content.location!,
                duration: content.duration,
                waveformData: content.waveform
            )
            delegate?.voiceRecordingDidStopRecording(self)
            if !components.isVoiceRecordingConfirmationRequiredEnabled {
                delegate?.voiceRecordingPublishMessage(self)
            }
            content = .idle

        case .play where content.location != nil && liveRecordingView.content.isPlaying == false:
            audioSessionFeedbackGenerator.feedbackForPlay()
            audioPlayer?.loadAsset(from: content.location!)

        case .pause where content.location != nil && liveRecordingView.content.isPlaying:
            audioSessionFeedbackGenerator.feedbackForPause()
            audioPlayer?.pause()

        default:
            log.error("\(type(of: self)) \(action) won't be executed. Current content \(content)")
        }
    }

    open func didPanHorizontally(_ point: CGFloat) {
        guard content.state == .recording else {
            return
        }

        let diff = view.bounds.size.width - point

        guard diff > slideToCancelDistance else {
            slideToCancelView.content = .init(
                alpha: (slideToCancelDistance - diff) / slideToCancelDistance
            )
            return
        }

        updateContentByApplyingAction(.cancel)
    }

    open func didPanVertically(_ point: CGFloat) {
        guard content.state == .recording else {
            return
        }

        let diff = view.bounds.size.height - point

        guard diff > lockDistance else {
            lockIndicatorView.bottomPaddingConstraint.constant = max(diff, lockIndicatorView.minimumBottomPadding)
            lockIndicatorView.chevronImageView.alpha = (lockDistance - diff) / lockDistance
            return
        }

        updateContentByApplyingAction(.lock)
    }

    @objc open func didSeekTime(_ sender: UISlider) {
        audioSessionFeedbackGenerator.feedbackForSeeking()
        audioPlayer?.seek(to: TimeInterval(sender.value))
    }

    // MARK: - AudioRecordingDelegate

    open func audioRecorder(
        _ audioRecorder: AudioRecording,
        didUpdateContext context: AudioRecordingContext
    ) {
        content.updatedWithDuration(context.duration)
        content.updatedWithWaveform(context.averagePower)

        recordingIndicatorView.content = context.duration

        liveRecordingView.content = .init(
            isRecording: true,
            isPlaying: false,
            duration: context.duration,
            currentTime: context.duration,
            waveform: content.waveform
        )
    }

    open func audioRecorder(
        _ audioRecorder: AudioRecording,
        didFinishRecordingAtURL location: URL
    ) {
        guard content != .idle else { return }

        audioAnalysisFactory?.waveformVisualisation(
            fromAudioURL: location,
            for: waveformTargetSamples
        ) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch result {
                case let .success(waveform):
                    self.content.waveform = waveform
                    self.content.updatedWithLocation(location)

                    self.liveRecordingView.content = .init(
                        isRecording: false,
                        isPlaying: false,
                        duration: self.content.duration,
                        currentTime: 0,
                        waveform: self.content.waveform
                    )
                    self.stopRecordingButton.isHidden = true

                    if self.sendImmediately {
                        if self.components.isVoiceRecordingConfirmationRequiredEnabled {
                            self.updateContentByApplyingAction(.confirm)
                        } else {
                            self.updateContentByApplyingAction(.send)
                        }
                        self.sendImmediately = false
                        self.content = .idle
                    }
                case let .failure(error):
                    log.error(error)
                }
            }
        }
    }

    open func audioRecorder(
        _ audioRecorder: AudioRecording,
        didFailWithError error: Error
    ) {
        log.error(error)
        content = .idle
    }

    // MARK: - AudioPlayingDelegate

    open func audioPlayer(
        _ audioPlayer: AudioPlaying,
        didUpdateContext context: AudioPlaybackContext
    ) {
        let isActive = context.assetLocation == content.location

        switch (isActive, context.state) {
        case (true, .playing), (true, .paused):
            liveRecordingView.content = .init(
                isRecording: false,
                isPlaying: context.state == .playing,
                duration: context.duration,
                currentTime: context.currentTime,
                waveform: liveRecordingView.content.waveform
            )
        case (true, .stopped):
            liveRecordingView.content = .init(
                isRecording: false,
                isPlaying: false,
                duration: context.duration,
                currentTime: 0,
                waveform: liveRecordingView.content.waveform
            )
        case (false, _):
            liveRecordingView.content = .init(
                isRecording: false,
                isPlaying: false,
                duration: content.duration,
                currentTime: 0,
                waveform: liveRecordingView.content.waveform
            )
        default:
            break
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        content != .idle
    }

    // MARK: - Private Action Handlers

    @objc private func didTapDiscard(_ sender: UIButton) {
        updateContentByApplyingAction(.discard)
    }

    @objc private func didTapStop(_ sender: UIButton) {
        updateContentByApplyingAction(.stop)
    }

    @objc private func didTapPlayPause(_ sender: UIButton) {
        if sender.isSelected {
            updateContentByApplyingAction(.pause)
        } else {
            updateContentByApplyingAction(.play)
        }
    }

    @objc private func didTapSend(_ sender: UIButton) {
        updateContentByApplyingAction(.send)
    }

    @objc private func didTapConfirm(_ sender: UIButton) {
        updateContentByApplyingAction(.confirm)
    }
}

// MARK: - Delegate

/// A delegate that the VoiceRecordingVC will use to post information or ask for support.
public protocol VoiceRecordingDelegate: AnyObject {
    /// Creates and attaches a VoiceRecording attachment on the message.
    /// - Parameters:
    ///   - voiceRecordingVC: The VoiceRecordingVC responsible for this action.
    ///   - location: The location where the audio file is being stored locally.
    ///   - duration: The audio file's duration.
    ///   - waveformData: The waveformData that can be used to render a waveform visualisation
    ///   of the audio file.
    func voiceRecording(
        _ voiceRecordingVC: VoiceRecordingVC,
        addAttachmentFromLocation location: URL,
        duration: TimeInterval,
        waveformData: [Float]
    )

    /// Informs the delegate that the VoiceRecordingVC wants to publish the current message.
    /// - Parameter voiceRecordingVC: The VoiceRecordingVC responsible for this action.
    func voiceRecordingPublishMessage(_ voiceRecordingVC: VoiceRecordingVC)

    /// Informs the delegate that the VoiceRecordingVC will begin recording.
    /// - Parameter voiceRecordingVC: The VoiceRecordingVC responsible for this action.
    func voiceRecordingWillBeginRecording(_ voiceRecordingVC: VoiceRecordingVC)

    /// /// Informs the delegate that the VoiceRecordingVC did begin recording.
    /// - Parameter voiceRecordingVC: The VoiceRecordingVC responsible for this action.
    func voiceRecordingDidBeginRecording(_ voiceRecordingVC: VoiceRecordingVC)

    /// Informs the delegate that the VoiceRecordingVC did lock the recording UI.
    /// - Parameter voiceRecordingVC: The VoiceRecordingVC responsible for this action.
    func voiceRecordingDidLockRecording(_ voiceRecordingVC: VoiceRecordingVC)

    /// Informs the delegate that the VoiceRecordingVC did stop recording.
    /// - Parameter voiceRecordingVC: The VoiceRecordingVC responsible for this action.
    func voiceRecordingDidStopRecording(_ voiceRecordingVC: VoiceRecordingVC)

    /// Informs the delegate that the VoiceRecordingVC wants to present a floatingView outside of its
    /// viewport.
    /// - Parameters:
    ///   - voiceRecordingVC: The VoiceRecordingVC responsible for this action.
    ///   - floatingView: The view that the VoiceRecordingVC wants to present outside of its viewport.
    func voiceRecording(_ voiceRecordingVC: VoiceRecordingVC, presentFloatingView floatingView: UIView)
}
