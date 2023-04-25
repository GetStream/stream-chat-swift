//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension ChatMessageVoiceRecordingAttachmentListView {
    open class ItemView: _View, ThemeProvider {
        // MARK: - Properties

        /// Content of the attachment `ChatMessageFileAttachment`
        public var content: ChatMessageVoiceRecordingAttachment? {
            didSet { updateContentIfNeeded() }
        }

        open lazy var playbackViewModel: VoiceRecordingViewPlaybackViewModel = .init(self)
        public var indexProvider: (() -> Int)?

        // MARK: - UI Components

        /// Label which shows name of the file, usually with extension (file.pdf)
        open private(set) lazy var fileNameLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
            .withAccessibilityIdentifier(identifier: "fileNameLabel")

        /// Label indicating size of the file.
        open private(set) lazy var fileSizeLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
            .withAccessibilityIdentifier(identifier: "fileSizeLabel")

        open private(set) lazy var durationLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
            .withAccessibilityIdentifier(identifier: "durationLabel")

        open private(set) lazy var waveformView = WaveformView()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "waveform")

        /// Animated indicator showing progress of uploading of a file.
        open private(set) lazy var loadingIndicator = components
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints

        /// Animated indicator showing progress of uploading of a file.
        open private(set) lazy var bufferLoadingIndicator = components
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints

        open private(set) lazy var mainContainerStackView: UIStackView = .init()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "mainContainerStackView")

        /// Stack containing loading indicator and label with fileSize.
        open private(set) lazy var spinnerAndSizeStack: ContainerStackView = .init()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "spinnerAndSizeStack")

        /// Stack containing file name and and the size of the file.
        open private(set) lazy var fileNameAndSizeStack: UIStackView = .init()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "fileNameAndSizeStack")

        open private(set) lazy var fileIconImageView = UIImageView()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "fileIconImageView")

        open private(set) lazy var playPauseButton: PlayPauseButton = .init()
            .withoutAutoresizingMaskConstraints

        open private(set) lazy var playbackRateButton: PillButton = .init()
            .withoutAutoresizingMaskConstraints

        open private(set) lazy var statefulContainer: StatefulView = .init().withoutAutoresizingMaskConstraints
        open private(set) lazy var trailingStatefulContainer: StatefulView = .init().withoutAutoresizingMaskConstraints

        // MARK: - UI Lifecycle

        override open func setUp() {
            super.setUp()

            playPauseButton.addTarget(self, action: #selector(didTapOnPlayPauseButton), for: .touchUpInside)
            playbackRateButton.addTarget(self, action: #selector(didTapOnPlaybackRateButton), for: .touchUpInside)

            waveformView.slider.addTarget(self, action: #selector(didSlide), for: .valueChanged)
            waveformView.slider.addTarget(self, action: #selector(didTouchUpSlider), for: .touchUpInside)

            playbackViewModel.setUp()
        }

        override open func setUpLayout() {
            super.setUpLayout()
            addSubview(mainContainerStackView)
            mainContainerStackView.pin(to: layoutMarginsGuide)

            statefulContainer.addArrangedSubview(bufferLoadingIndicator)
            statefulContainer.addArrangedSubview(durationLabel)

            trailingStatefulContainer.addArrangedSubview(fileIconImageView)
            trailingStatefulContainer.addArrangedSubview(playbackRateButton)

            [
                loadingIndicator,
                fileSizeLabel,
                statefulContainer,
                waveformView
            ]
            .forEach { spinnerAndSizeStack.addArrangedSubview($0) }

            [
                fileNameLabel,
                spinnerAndSizeStack
            ].forEach { fileNameAndSizeStack.addArrangedSubview($0) }

            [
                playPauseButton,
                fileNameAndSizeStack,
                trailingStatefulContainer
            ].forEach { mainContainerStackView.addArrangedSubview($0) }

            mainContainerStackView.axis = .horizontal
            mainContainerStackView.spacing = 8
            mainContainerStackView.alignment = .center

            fileNameAndSizeStack.axis = .vertical
            fileNameAndSizeStack.spacing = 8
            fileNameAndSizeStack.alignment = .fill

            spinnerAndSizeStack.axis = .horizontal
            spinnerAndSizeStack.spacing = 4
            spinnerAndSizeStack.alignment = .center

            durationLabel.setContentHuggingPriority(.streamRequire, for: .vertical)
            waveformView.setContentHuggingPriority(.streamLow, for: .vertical)

            playbackRateButton.isHidden = true

            statefulContainer.axis = .vertical
        }

        override open func setUpAppearance() {
            super.setUpAppearance()

            backgroundColor = appearance.colorPalette.popoverBackground
            layer.cornerRadius = 12
            layer.masksToBounds = true
            layer.borderWidth = 1
            layer.borderColor = appearance.colorPalette.border.cgColor

            fileSizeLabel.textColor = appearance.colorPalette.subtitleText
            fileSizeLabel.font = appearance.fonts.subheadlineBold

            fileNameLabel.font = appearance.fonts.bodyBold
            fileNameLabel.lineBreakMode = .byTruncatingMiddle

            fileIconImageView.contentMode = .center
            fileIconImageView.image = appearance.images.fileAac

            durationLabel.textColor = appearance.colorPalette.textLowEmphasis
            durationLabel.font = .monospacedDigitSystemFont(
                ofSize: appearance.fonts.caption1.pointSize, weight: .medium
            )

            playbackRateButton.setTitleColor(appearance.colorPalette.staticBlackColorText, for: .normal)
            playbackRateButton.titleLabel?.font = appearance.fonts.footnote
        }

        override open func updateContent() {
            super.updateContent()

            // If we cannot fetch filename, let's use only content type.
            fileNameLabel.text = content.map { content in
                appearance.formatters.audioRecordingNameFormatter.title(
                    forItemAtURL: content.voiceRecordingURL,
                    index: indexProvider?() ?? 0
                )
            }

            switch content?.uploadingState?.state {
            case .uploaded:
                fileSizeLabel.text = content?.payload.file.sizeString
            case .uploadingFailed:
                fileSizeLabel.text = L10n.Message.Sending.attachmentUploadingFailed
            default:
                fileSizeLabel.text = content?.uploadingState?.fileUploadingProgress
            }

            switch content?.uploadingState?.state {
            case .pendingUpload, .uploading:
                loadingIndicator.isVisible = true
            default:
                loadingIndicator.isVisible = false
            }

            guard
                let content = content,
                content.uploadingState?.state == .uploaded || content.uploadingState == nil
            else {
                playPauseButton.isHidden = true
                durationLabel.isHidden = true
                fileSizeLabel.isHidden = false
                playbackRateButton.isHidden = true
                waveformView.isHidden = true
                statefulContainer.isHidden = true
                return
            }

            playPauseButton.isHidden = false
            durationLabel.isHidden = false
            fileSizeLabel.isHidden = true
            waveformView.isHidden = false
            statefulContainer.isHidden = false
            bufferLoadingIndicator.isHidden = true

            let duration: TimeInterval = content.extraData?["duration"]?.numberValue ?? 0
            durationLabel.text = appearance.formatters.videoDuration.format(duration)

            let waveform = content
                .extraData?["waveform"]?
                .arrayValue?
                .compactMap { $0.numberValue.map { Float($0) } }
                ?? []
            waveformView.content = .init(
                isRecording: false,
                isPlaying: false,
                duration: duration,
                currentTime: 0,
                waveform: waveform
            )
        }

        // MARK: - Action Handlers

        @objc open func didTapOnPlayPauseButton(
            _ sender: UIButton
        ) {
            if sender.isSelected {
                playbackViewModel.pause()
            } else {
                playbackViewModel.play()
            }
        }

        @objc open func didTapOnPlaybackRateButton(
            _ sender: UIButton
        ) {
            playbackViewModel.updatePlaybackRate()
        }

        @objc open func didSlide(
            _ sender: UISlider
        ) {
            playbackViewModel.seek(to: TimeInterval(sender.value))
        }

        @objc open func didTouchUpSlider(
            _ sender: UISlider
        ) {
            playbackViewModel.play()
        }
    }
}

open class VoiceRecordingViewPlaybackViewModel: AudioPlayingDelegate {
    public weak var delegate: AudioAttachmentPresentationViewDelegate?

    private var currentPlaybackRate: AudioPlaybackRate = .zero
    private weak var view: ChatMessageVoiceRecordingAttachmentListView.ItemView?
    private lazy var viewUpdater: ChatMessageVoiceRecordingViewStateUpdater = .init()
    private lazy var debouncer: Debouncer = .init(0.5)

    public init(
        _ view: ChatMessageVoiceRecordingAttachmentListView.ItemView
    ) {
        self.view = view
    }

    // MARK: - Action Handlers

    open func setUp() {
        delegate?.audioAttachmentPresentationViewConnect(delegate: self)
    }

    open func play() {
        guard let attachment = view?.content else {
            return
        }
        delegate?.audioAttachmentPresentationViewBeginPayback(attachment)
    }

    open func pause() {
        delegate?.audioAttachmentPresentationViewPausePayback()
    }

    open func updatePlaybackRate() {
        switch currentPlaybackRate {
        case .normal:
            delegate?.audioAttachmentPresentationViewUpdatePlaybackRate(.double)
        case .half:
            delegate?.audioAttachmentPresentationViewUpdatePlaybackRate(.normal)
        case .double:
            delegate?.audioAttachmentPresentationViewUpdatePlaybackRate(.half)
        case .zero:
            delegate?.audioAttachmentPresentationViewUpdatePlaybackRate(.normal)
        default:
            delegate?.audioAttachmentPresentationViewUpdatePlaybackRate(.zero)
        }
    }

    open func seek(to timeInterval: TimeInterval) {
        delegate?.audioAttachmentPresentationViewSeek(to: timeInterval)
    }

    // MARK: - AudioPlayingDelegate

    public func audioPlayer(
        _ audioPlayer: AudioPlaying,
        didUpdateContext context: AudioPlaybackContext
    ) {
        guard
            let view = view,
            let content = view.content
        else {
            return
        }

        var context = context.assetLocation == content.voiceRecordingURL ? context : AudioPlaybackContext.notLoaded
        context.state = context.assetLocation == content.voiceRecordingURL ? context.state : .stopped

        viewUpdater.configure(
            leadingButton: view.playPauseButton,
            for: context.state,
            with: view.appearance
        )

        viewUpdater.configure(
            sizeLabel: view.fileSizeLabel,
            for: context.state,
            with: view.appearance,
            value: content.payload.file.sizeString
        )

        let contentDuration = content.extraData?["duration"]?.numberValue ?? context.duration
        let loadingIndicatorAndDurationLabel = { [viewUpdater] in
            viewUpdater.configure(
                loadingIndicator: view.bufferLoadingIndicator,
                for: context.state,
                with: view.appearance
            )

            viewUpdater.configure(
                detailsLabel: view.durationLabel,
                for: context.state,
                with: view.appearance,
                duration: contentDuration,
                currentTime: context.currentTime
            )
            view.durationLabel.isHidden = view.durationLabel.isHidden || !view.bufferLoadingIndicator.isHidden
        }

        if context.state == .loading {
            debouncer.execute {
                DispatchQueue.main.async { loadingIndicatorAndDurationLabel() }
            }
        } else {
            debouncer.invalidate()
            loadingIndicatorAndDurationLabel()
        }

        view.waveformView.content = .init(
            isRecording: false,
            isPlaying: context.state == .paused || context.state == .playing,
            duration: contentDuration,
            currentTime: context.currentTime,
            waveform: view.waveformView.content.waveform
        )

        viewUpdater.configure(
            fileIconImageView: view.fileIconImageView,
            for: context.state,
            with: view.appearance
        )

        viewUpdater.configure(
            trailingButton: view.playbackRateButton,
            for: context.state,
            with: view.appearance,
            value: context.rate.rawValue,
            overrideValue: currentPlaybackRate.rawValue
        )

        currentPlaybackRate = context.rate
    }
}

open class PillButton: _Button, AppearanceProvider {
    open var content: String? {
        didSet { updateContentIfNeeded() }
    }

    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? appearance.colorPalette.highlightedBackground
                : appearance.colorPalette.staticColorText
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        tintColor = appearance.colorPalette.staticBlackColorText
        backgroundColor = appearance.colorPalette.staticColorText
        layer.shadowColor = tintColor.cgColor
    }

    override open func updateContent() {
        super.updateContent()
        setTitle(content, for: .normal)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 2
        layer.shadowOffset = .init(width: 0, height: 2)
    }

    override open func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesBegan(touches, with: event)
        isHighlighted = true
    }

    override open func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesEnded(touches, with: event)
        isHighlighted = false
    }

    override open func touchesCancelled(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesCancelled(touches, with: event)
        isHighlighted = false
    }
}

open class StatefulView: _View, AppearanceProvider {
    open var axis: NSLayoutConstraint.Axis = .horizontal {
        didSet { container.axis = axis }
    }

    open private(set) lazy var container: UIStackView = .init().withoutAutoresizingMaskConstraints

    open func addArrangedSubview(_ view: UIView) {
        container.addArrangedSubview(view.withoutAutoresizingMaskConstraints)
    }

    override open func setUp() {
        super.setUp()
        container.axis = axis
        container.alignment = .center
    }

    override open func setUpLayout() {
        super.setUpLayout()
        embed(container)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = nil
    }

    override open var intrinsicContentSize: CGSize {
        let maxSize = CGSize.zero

        let newSize = container.arrangedSubviews.reduce(maxSize) { partialResult, subview in
            let subviewSize = subview.sizeThatFits(bounds.size)
            return CGSize(width: max(partialResult.width, subviewSize.width), height: max(partialResult.height, subviewSize.height))
        }

        return newSize
    }
}
