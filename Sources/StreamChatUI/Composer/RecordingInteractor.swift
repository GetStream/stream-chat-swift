//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

public enum RecordingState {
    case notRecording
    case possibleRecording
    case recording
    case stopped
    case locked
    case replaying
    case paused
}

open class RecordingAdapter: AudioRecordingDelegate, AudioPlayingDelegate {
    private let composerView: ComposerView
    private let serialDispatchQueue: DispatchQueue = .init(label: "com.stream.recording.adapter", qos: .userInteractive)
    private let addFloatingViewHandler: (UIView) -> Void
    private let updateContentHandler: (URL) -> Void
    private let clearMessageHandler: () -> Void

    open private(set) lazy var audioRecorder: AudioRecording = composerView
        .components
        .audioRecorder
        .build()

    open private(set) lazy var audioPlayer: AudioPlaying = StreamRemoteAudioPlayer.build()

    open private(set) lazy var biDirectionalPanGestureRecognizer: BiDirectionalPanGestureRecognizer = .init()

    open private(set) lazy var floatingContainer: UIStackView = .init()
        .withoutAutoresizingMaskConstraints
    open private(set) lazy var notLongTapView: NotLongRecordButtonTap = .init()
        .withoutAutoresizingMaskConstraints
    open private(set) lazy var recordingView: RecordingView = .init()
        .withoutAutoresizingMaskConstraints
    open private(set) lazy var recordingWithPlaybackView: RecordingAndPlaybackView = .init()
        .withoutAutoresizingMaskConstraints
    open private(set) lazy var slideToCancelView: SlideToCancelView = .init()
        .withoutAutoresizingMaskConstraints
    open private(set) lazy var resumeButton: ResumeRecordingButton = .init()
        .withoutAutoresizingMaskConstraints
    open private(set) lazy var pauseButton: StopRecordingButton = .init()
        .withoutAutoresizingMaskConstraints
    open private(set) lazy var stopButton: StopRecordingButton = .init()
        .withoutAutoresizingMaskConstraints
    open private(set) lazy var discardButton: DiscardRecordingButton = .init()
        .withoutAutoresizingMaskConstraints
    open private(set) lazy var lockView: LockView = .init()
        .withoutAutoresizingMaskConstraints
    open private(set) lazy var spacer: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open private(set) var state: RecordingState = .notRecording {
        didSet {
            guard state != oldValue else { return }
            let newValue = state
            serialDispatchQueue.async { [weak self] in
                self?.didUpdateState(oldState: oldValue, newState: newValue)
            }
        }
    }

    public init(
        composerView: ComposerView,
        addFloatingViewHandler: @escaping (UIView) -> Void,
        updateContentHandler: @escaping (URL) -> Void,
        clearMessageHandler: @escaping () -> Void
    ) {
        self.composerView = composerView
        self.addFloatingViewHandler = addFloatingViewHandler
        self.updateContentHandler = updateContentHandler
        self.clearMessageHandler = clearMessageHandler

        setUp()
    }

    open func setUp() {
        floatingContainer.axis = .vertical
        floatingContainer.addArrangedSubview(notLongTapView)
        notLongTapView.isHidden = true
        floatingContainer.addArrangedSubview(lockView)
        lockView.isHidden = true
        floatingContainer.isHidden = true

        composerView.recordButton.possibleLongPressHandler = { [weak self] in
            self?.state = .possibleRecording
        }

        composerView.recordButton.nonCompletedLongPressHandler = { [weak self] in
            self?.state = .notRecording
        }

        composerView.recordButton.activeLongPressHandler = { [weak self] in
            self?.state = .recording
        }

        composerView.recordButton.completedLongPressHandler = { [weak self] in
            guard self?.state != .locked else { return }
            self?.state = .notRecording
        }

        biDirectionalPanGestureRecognizer.horizontalMovementHandler = { [weak self] in self?.didMoveTouchHorizontal(at: $0) }
        biDirectionalPanGestureRecognizer.verticalMovementHandler = { [weak self] in self?.didMoveTouchVertically(at: $0) }
        composerView.addGestureRecognizer(biDirectionalPanGestureRecognizer)

        discardButton.didTapHandler = { [weak self] in
            self?.clearMessageHandler()
            self?.state = .notRecording
        }

        composerView.sendButton.addTarget(
            self,
            action: #selector(didTapSend),
            for: .touchUpInside
        )

        audioRecorder.delegate = self

        stopButton.didTapHandler = { [weak self] in
            self?.state = .stopped
        }

        resumeButton.didTapHandler = { [weak self] in
            self?.state = .locked
        }

        recordingWithPlaybackView.playPauseButton.didTapHandler = { [weak recordingWithPlaybackView, weak self] in
            if recordingWithPlaybackView?.playPauseButton.content == true {
                self?.state = .paused
            } else {
                self?.state = .replaying
            }
        }

        recordingWithPlaybackView.waveformView.addTarget(self, action: #selector(didScrub), for: .valueChanged)
    }

    // MARK: - Action Handlers

    open func didMoveTouchHorizontal(
        at point: CGFloat
    ) {
        guard state != .notRecording else {
            return
        }

        debugPrint("[\(type(of: self)) Current horizontal position in composerView is \(point)]")
        let diff = composerView.bounds.size.width - point

        guard diff > 75 else {
            slideToCancelView.alpha = 1 - (diff / 75)
            return
        }

        state = .notRecording
    }

    open func didMoveTouchVertically(
        at point: CGFloat
    ) {
        guard state != .notRecording else {
            return
        }

        debugPrint("[\(type(of: self)) Current vertical position in composerView is \(point)]")
        let diff = composerView.bounds.size.height - point

        guard diff > 50 else {
            lockView.bottomPaddingConstraint.constant = diff
            return
        }

        state = .locked
    }

    @objc open func didTapSend(_ sender: UIButton) {
        state = .notRecording
    }

    @objc private func didScrub(_ slider: UISlider) {
        audioPlayer.seek(to: TimeInterval(slider.value))
    }

    // MARK: - State updates

    open func didUpdateState(
        oldState: RecordingState,
        newState: RecordingState
    ) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.didUpdateState(oldState: oldState, newState: newState)
            }
            return
        }

        debugPrint("[\(type(of: self)) \(#function) \(oldState) -> \(newState)]")
        switch (oldState, newState) {
        case (.possibleRecording, .notRecording):
            addFloatingViewHandler(floatingContainer)
            notLongTapView.isHidden = false
            Animate { [floatingContainer] in
                floatingContainer.isHidden = false
            } completion: { [weak self] _ in
                Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
                    self?.floatingContainer.removeFromSuperview()
                    self?.floatingContainer.isHidden = true
                    self?.notLongTapView.isHidden = true
                }
            }

        case (_, .notRecording):
            audioRecorder.stopRecording()
            audioRecorder.deleteRecording()
            recordingWithPlaybackView.content = .init(inPlaybackMode: false, isPlaying: false, interval: 0)
            recordingView.content = 0

            Animate { [weak self] in
                guard let self = self else { return }

                [
                    self.recordingView,
                    self.slideToCancelView,
                    self.discardButton,
                    self.spacer,
                    self.stopButton,
                    self.resumeButton
                ].forEach { subview in
                    subview.superview.map { _ in self.composerView.centerContainer.removeArrangedSubview(subview) }
                }

                self.recordingWithPlaybackView.removeFromSuperview()
                self.composerView.headerView.isHidden = true
                self.composerView.recordButton.isHidden = false
                self.composerView.sendButton.isHidden = false
                self.composerView.leadingContainer.isHidden = false
                self.composerView.inputMessageView.isHidden = false
                self.notLongTapView.isHidden = true
                self.lockView.isHidden = true
                self.floatingContainer.isHidden = true
                self.recordingView.durationLabel.isHidden = false
                self.lockView.content = false
                self.composerView.sendButton.isEnabled = false
                self.audioPlayer.clearUpQueue()
            }

        case (.notRecording, .possibleRecording):
            break

        case (.possibleRecording, .recording):
            addFloatingViewHandler(floatingContainer)
            lockView.isHidden = false
            Animate { [composerView, recordingView, slideToCancelView, floatingContainer] in
                composerView.centerContainer.insertArrangedSubview(recordingView, at: 0)
                composerView.centerContainer.insertArrangedSubview(slideToCancelView, at: 1)
                composerView.leadingContainer.isHidden = true
                composerView.inputMessageView.isHidden = true
                composerView.sendButton.isHidden = true
                floatingContainer.isHidden = false
            }
            audioRecorder.beginRecording()

        case (.recording, .locked):
            composerView.headerView.embed(recordingWithPlaybackView)
            Animate { [slideToCancelView, stopButton, recordingView, composerView, lockView] in
                composerView.centerContainer.insertArrangedSubview(stopButton, at: 1)
                lockView.content = true
                slideToCancelView.removeFromSuperview()
                recordingView.durationLabel.isHidden = true
                composerView.sendButton.isHidden = false
                composerView.recordButton.isHidden = true
                composerView.headerView.isHidden = false
                composerView.sendButton.isEnabled = true
                lockView.bottomPaddingConstraint.constant = 5
            }

        case (.locked, .stopped):
            audioRecorder.stopRecording()
            Animate { [spacer, stopButton, composerView, recordingWithPlaybackView, recordingView, discardButton] in
                composerView.centerContainer.removeArrangedSubview(stopButton)
                composerView.centerContainer.removeArrangedSubview(recordingView)
                composerView.centerContainer.insertArrangedSubview(discardButton, at: 0)
                composerView.centerContainer.insertArrangedSubview(spacer, at: 1)
                recordingWithPlaybackView.content = .init(
                    inPlaybackMode: true,
                    isPlaying: false,
                    interval: recordingWithPlaybackView.content.interval
                )
            }

        case (.stopped, .replaying):
            audioPlayer.clearUpQueue()
            audioPlayer.loadAsset(from: audioRecorder.storageURL.standardizedFileURL, andConnectDelegate: self)
        case (.paused, .replaying):
            audioPlayer.play()
        case (.replaying, .paused):
            audioPlayer.pause()
        case (.replaying, .stopped):
            audioPlayer.stop()
        default:
            break
        }
    }

    // MARK: - AudioRecordingDelegate

    open func audioRecorderDidBeginRecording(_ audioRecorder: AudioRecording) {
        state = .recording
    }

    open func audioRecorder(_ audioRecorder: AudioRecording, didFailRecording error: Error) {
        debugPrint("[\(type(of: self)) \(#function)] error: \(error)")
    }

    open func audioRecorderDidPauseRecording(_ audioRecorder: AudioRecording) {
        debugPrint("[\(type(of: self)) \(#function)]")
    }

    open func audioRecorderDidResumeRecording(_ audioRecorder: AudioRecording) {
        debugPrint("[\(type(of: self)) \(#function)]")
    }

    open func audioRecorderDidFinishRecording(_ audioRecorder: AudioRecording, url: URL?) {
        debugPrint("[\(type(of: self)) \(#function)] url :\(url)")
        if let url = url {
            updateContentHandler(url.standardizedFileURL)
        }
    }

    open func audioRecorderDidUpdate(_ audioRecorder: AudioRecording, currentTime: TimeInterval) {
        recordingView.content = currentTime
        recordingWithPlaybackView.content = .init(
            inPlaybackMode: false,
            isPlaying: false,
            interval: currentTime
        )
    }

    open func audioRecorderDeletedRecording(_ audioRecorder: AudioRecording, error: Error?) {
        debugPrint("[\(type(of: self)) \(#function)] error: \(error)")
    }

    open func audioRecorderBeginInterruption(_ audioRecorder: AudioRecording) {
        debugPrint("[\(type(of: self)) \(#function)]")
    }

    open func audioRecorderEndInterruption(_ audioRecorder: AudioRecording) {
        debugPrint("[\(type(of: self)) \(#function)]")
    }

    open func audioRecorderEncodingFailed(_ audioRecorder: AudioRecording, error: Error?) {
        debugPrint("[\(type(of: self)) \(#function)] error: \(error)")
    }

    // MARK: - AudioPlayingDelegate

    public func audioPlayer(
        _ audioPlayer: AudioPlaying,
        didUpdateContext context: AudioPlaybackContext
    ) {
        guard state == .paused || state == .replaying || state == .stopped else {
            return
        }

        switch (state, context.state) {
        case (.replaying, .paused):
            state = .paused
        case (.replaying, .stopped):
            state = .stopped
        case (.paused, .playing), (.stopped, .playing):
            state = .replaying
        default:
            break
        }

        recordingWithPlaybackView.waveformView.maximumValue = Float(context.duration)
        recordingWithPlaybackView.content = .init(
            inPlaybackMode: true,
            isPlaying: state == .replaying,
            interval: state == .stopped ? context.duration : context.currentTime
        )
    }
}

// MARK: - Subviews

open class NotLongRecordButtonTap: _View, ThemeProvider {
    var content: String = "Hold to record, release to send" {
        didSet { updateContent() }
    }

    open lazy var container: UIView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var titleLabel: UILabel = .init()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport

    override open func setUpLayout() {
        super.setUpLayout()

        embed(container)
        container.embed(titleLabel, insets: .init(top: 8, leading: 8, bottom: 8, trailing: 8))
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = nil
        container.backgroundColor = appearance.colorPalette.border
        titleLabel.font = appearance.fonts.caption1.bold
        titleLabel.textColor = appearance.colorPalette.text
        titleLabel.textAlignment = .center
    }

    override open func updateContent() {
        super.updateContent()

        titleLabel.text = content
    }
}

open class RecordingView: _View, ThemeProvider {
    var content: TimeInterval = 0 {
        didSet { updateContentIfNeeded() }
    }

    open private(set) lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var recordingButton: RecordButton = components.recordButton
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var durationLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()
        recordingButton.isUserInteractionEnabled = false
    }

    override open func setUpLayout() {
        super.setUpLayout()
        recordingButton.pin(anchors: [.width], to: 28)
        recordingButton.pin(anchors: [.height], to: 40)

        container.axis = .horizontal
        container.spacing = 5
        container.addArrangedSubview(recordingButton)
        container.addArrangedSubview(durationLabel)

        embed(container, insets: .zero)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        recordingButton.tintColor = appearance.colorPalette.alert
        durationLabel.textColor = appearance.colorPalette.textLowEmphasis
        durationLabel.font = appearance.fonts.footnote
    }

    override open func updateContent() {
        durationLabel.text = appearance.formatters.videoDuration.format(content)
    }
}

open class RecordingAndPlaybackView: _View, ThemeProvider {
    struct Content {
        var inPlaybackMode: Bool
        var isPlaying: Bool
        var interval: TimeInterval
    }

    var content: Content = .init(inPlaybackMode: false, isPlaying: false, interval: 0) {
        didSet { updateContentIfNeeded() }
    }

    open lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var playPauseButton: PlayPauseButton = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var durationLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints

    open lazy var waveformView: UISlider = .init()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()
    }

    override open func setUpLayout() {
        super.setUpLayout()

        container.axis = .horizontal
        container.spacing = 5
        container.addArrangedSubview(playPauseButton)
        container.addArrangedSubview(durationLabel)
        container.addArrangedSubview(waveformView)

        embed(container, insets: .init(top: 8, leading: 0, bottom: 8, trailing: 8))
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = appearance.colorPalette.background
        durationLabel.textColor = appearance.colorPalette.textLowEmphasis
        durationLabel.font = appearance.fonts.footnote
    }

    override open func updateContent() {
        durationLabel.text = appearance.formatters.videoDuration.format(content.interval)
        playPauseButton.isHidden = !content.inPlaybackMode
        playPauseButton.content = content.isPlaying
        waveformView.isHidden = playPauseButton.isHidden
        waveformView.minimumValue = 0
        waveformView.value = Float(content.interval)
        container.setNeedsLayout()
        container.layoutIfNeeded()
    }
}

open class SlideToCancelView: _View, ThemeProvider {
    var content: String = "slide to cancel" {
        didSet { updateContent() }
    }

    open lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var titleLabel: UILabel = .init()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport

    open lazy var chevronImageView: UIImageView = .init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(chevronImageView)
        chevronImageView.contentMode = .center

        container.axis = .horizontal
        container.spacing = 8

        addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            container.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = nil
        titleLabel.font = appearance.fonts.body
        titleLabel.textColor = appearance.colorPalette.textLowEmphasis
        if #available(iOS 13.0, *) {
            chevronImageView.image = UIImage(systemName: "chevron.left")
        }
        chevronImageView.tintColor = titleLabel.textColor
    }

    override open func updateContent() {
        super.updateContent()
        titleLabel.text = content
    }
}

open class LockView: _View, ThemeProvider {
    open var content: Bool = false {
        didSet { updateContent() }
    }

    open lazy var horizontalStackView: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var lockViewContainer: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var container: UIView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var stackView: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var lockImageView: UIImageView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var chevronImageView: UIImageView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var bottomPaddingSpacer: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var bottomPaddingConstraint: NSLayoutConstraint = bottomPaddingSpacer.heightAnchor.constraint(equalToConstant: 0)

    override open func setUp() {
        super.setUp()
        container.clipsToBounds = true
    }

    override open func setUpLayout() {
        super.setUpLayout()

        lockViewContainer.axis = .vertical

        stackView.addArrangedSubview(lockImageView)
        stackView.addArrangedSubview(chevronImageView)

        stackView.axis = .vertical
        stackView.spacing = 8

        embed(horizontalStackView, insets: .init(top: 0, leading: 4, bottom: 0, trailing: 4))
        horizontalStackView.addArrangedSubview(.spacer(axis: .horizontal))
        horizontalStackView.addArrangedSubview(lockViewContainer)

        lockViewContainer.addArrangedSubview(container)
        lockViewContainer.addArrangedSubview(bottomPaddingSpacer)
        container.embed(stackView, insets: .init(top: 8, leading: 8, bottom: 8, trailing: 8))

        NSLayoutConstraint.activate([
            bottomPaddingConstraint
        ])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = nil
        container.backgroundColor = appearance.colorPalette.border

        if #available(iOS 13.0, *) {
            lockImageView.image = UIImage(systemName: "lock")
            chevronImageView.image = UIImage(systemName: "chevron.up")
        }
        lockImageView.tintColor = content ? appearance.colorPalette.accentPrimary : appearance.colorPalette.textLowEmphasis
        chevronImageView.tintColor = lockImageView.tintColor
    }

    override open func updateContent() {
        super.updateContent()

        lockImageView.tintColor = content ? appearance.colorPalette.accentPrimary : appearance.colorPalette.textLowEmphasis
        chevronImageView.isHidden = content
        chevronImageView.alpha = chevronImageView.isHidden ? 0 : 1
        chevronImageView.tintColor = lockImageView.tintColor
        bottomPaddingConstraint.constant = content ? bottomPaddingConstraint.constant : 0
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        container.clipsToBounds = true
        container.layer.cornerRadius = container.bounds.width / 2.0
    }
}

open class DeleteButton: _View, ThemeProvider {}

open class WaveFormView: _View, ThemeProvider {
    var content: URL? { didSet { updateContentIfNeeded() } }

    open private(set) lazy var imageView: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        embed(imageView, insets: .init(top: 8, leading: 8, bottom: 8, trailing: 8))
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        imageView.backgroundColor = appearance.colorPalette.background
    }

    override open func updateContent() {
        guard let content = content else { return }
    }
}

// MARK: - Helpers

open class BiDirectionalPanGestureRecognizer: UIPanGestureRecognizer, UIGestureRecognizerDelegate {
    open var horizontalMovementHandler: ((CGFloat) -> Void)?
    open var verticalMovementHandler: ((CGFloat) -> Void)?

    private var horizontalPoint: CGFloat = 0
    private var verticalPoint: CGFloat = 0

    public init() {
        super.init(target: nil, action: nil)
        delegate = self
    }

    override open func reset() {
        super.reset()
        horizontalPoint = view?.bounds.width ?? 0
        verticalPoint = view?.bounds.height ?? 0
    }

    override open func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent
    ) {
        super.touchesBegan(touches, with: event)
        horizontalPoint = view?.bounds.width ?? 0
        verticalPoint = view?.bounds.height ?? 0
    }

    override open func touchesMoved(
        _ touches: Set<UITouch>,
        with event: UIEvent
    ) {
        super.touchesMoved(touches, with: event)
        let velocity = self.velocity(in: view)
        let isHorizontalMovement = abs(velocity.x) >= abs(velocity.y)
        let translation = self.translation(in: view)

        if isHorizontalMovement {
            horizontalPoint += translation.x
            horizontalMovementHandler?(horizontalPoint)
        } else {
            verticalPoint += translation.y
            verticalMovementHandler?(verticalPoint)
        }

        setTranslation(.zero, in: view)
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
