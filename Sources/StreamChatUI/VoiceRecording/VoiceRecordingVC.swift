//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

open class VoiceRecordingVC: _ViewController, ComponentsProvider, AppearanceProvider, AudioRecordingDelegate, AudioPlayingDelegate {
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
        var state: State
        var duration: TimeInterval
        var location: URL?
        var waveform: [Float]

        static let idle = Content(
            state: .idle,
            duration: 0,
            location: nil,
            waveform: []
        )

        static let beginRecording = Content(
            state: .recording,
            duration: 0,
            location: nil,
            waveform: []
        )

        mutating func lock() {
            state = .locked
        }

        mutating func updatedWithDuration(_ duration: TimeInterval) {
            self.duration = duration
        }

        mutating func updatedWithLocation(_ location: URL) {
            self.location = location
        }

        mutating func updatedWithWaveform(_ dataPoint: Float) {
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

    open var waveformTargetSamples: Int = 100

    // MARK: - Delegate & ComposerView

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

    open lazy var recordingTipView: RecordingTipView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var slideToCancelView: SlideToCancelView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var recordingIndicatorView: RecordingIndicatorView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var lockIndicatorView: LockIndicatorView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var liveRecordingView: LiveRecordingView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var discardRecordingButton: UIButton = .init(type: .system)
        .withoutAutoresizingMaskConstraints

    open lazy var stopRecordingButton: UIButton = .init(type: .system)
        .withoutAutoresizingMaskConstraints

    open lazy var stopRecordingButtonContainer: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var sendButton: UIButton = components
        .sendButton
        .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "sendButton")

    open lazy var confirmButton: UIButton = components
        .confirmButton.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "confirmButton")

    // MARK: - Components

    open lazy var bidirectionalPanGestureRecogniser: BidirectionalPanGestureRecogniser = .init()

    open lazy var audioRecorder: AudioRecording = components
        .audioRecorder
        .init()

    open var audioPlayer: AudioPlaying? {
        didSet { audioPlayer?.subscribe(self) }
    }

    open lazy var audioSessionFeedbackGenerator: AudioSessionFeedbackGenerator = components
        .audioSessionFeedbackGenerator
        .init()

    open lazy var audioAnalysisFactory: AudioAnalysisEngine? = try? .init(
        assetPropertiesLoader: StreamAssetPropertyLoader()
    )

    open lazy var hideViewsDebouncer: Debouncer = .init(2, queue: .main)

    // MARK: - Private Properties

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

        guard components.voiceRecordingEnabled else { return }

        bidirectionalPanGestureRecogniser.touchesBeganHandler = { [weak self] in self?.updateContentByApplyingAction(.tapRecord) }
        bidirectionalPanGestureRecogniser.touchesEndedHandler = { [weak self] in self?.updateContentByApplyingAction(.touchUp) }
        bidirectionalPanGestureRecogniser.horizontalMovementHandler = { [weak self] in self?.didPanHorizontally($0) }
        bidirectionalPanGestureRecogniser.verticalMovementHandler = { [weak self] in self?.didPanVertically($0) }
        view.addGestureRecognizer(bidirectionalPanGestureRecogniser)

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
                if self.components.voiceRecordingConfirmInsteadOfSendEnabled {
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
            if !components.voiceRecordingConfirmInsteadOfSendEnabled {
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
                title: slideToCancelView.content.title,
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
                        if self.components.voiceRecordingConfirmInsteadOfSendEnabled {
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

public protocol VoiceRecordingDelegate: AnyObject {
    func voiceRecording(
        _ voiceRecordingVC: VoiceRecordingVC,
        addAttachmentFromLocation location: URL,
        duration: TimeInterval,
        waveformData: [Float]
    )

    func voiceRecordingPublishMessage(_ voiceRecordingVC: VoiceRecordingVC)

    func voiceRecordingWillBeginRecording(_ voiceRecordingVC: VoiceRecordingVC)

    func voiceRecordingDidBeginRecording(_ voiceRecordingVC: VoiceRecordingVC)

    func voiceRecordingDidLockRecording(_ voiceRecordingVC: VoiceRecordingVC)

    func voiceRecordingDidStopRecording(_ voiceRecordingVC: VoiceRecordingVC)

    func voiceRecording(_ voiceRecordingVC: VoiceRecordingVC, presentFloatingView floatingView: UIView)
}
