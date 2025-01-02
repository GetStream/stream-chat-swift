//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension ChatMessageFileAttachmentListView {
    open class ItemView: _View, ThemeProvider {
        /// Content of the attachment `ChatMessageFileAttachment`
        public var content: ChatMessageFileAttachment? {
            didSet { updateContentIfNeeded() }
        }

        /// Closure which notifies when the user tapped the attachment.
        open var didTapOnAttachment: ((ChatMessageFileAttachment) -> Void)?

        /// Closure which notifies when the user tapped an attachment action. (Ex: Retry)
        open var didTapActionOnAttachment: ((ChatMessageFileAttachment) -> Void)?

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

        /// Animated indicator showing progress of uploading of a file.
        open private(set) lazy var loadingIndicator = components
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints

        /// imageView indicating action for the file attachment. (Download / Retry upload...)
        open private(set) lazy var actionIconImageView = UIImageView()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "actionIconImageView")

        open private(set) lazy var mainContainerStackView: ContainerStackView = ContainerStackView()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "mainContainerStackView")

        /// Stack containing loading indicator and label with fileSize.
        open private(set) lazy var spinnerAndSizeStack: ContainerStackView = ContainerStackView()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "spinnerAndSizeStack")

        /// Stack containing file name and and the size of the file.
        open private(set) lazy var fileNameAndSizeStack: ContainerStackView = ContainerStackView()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "fileNameAndSizeStack")

        open private(set) lazy var fileIconImageView = UIImageView()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "fileIconImageView")

        override open func setUp() {
            super.setUp()

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnAttachment(_:)))
            mainContainerStackView.addGestureRecognizer(tapRecognizer)

            let actionTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapActionOnAttachment(_:)))
            actionIconImageView.addGestureRecognizer(actionTapRecognizer)
            actionIconImageView.isUserInteractionEnabled = true
        }

        override open func setUpAppearance() {
            super.setUpAppearance()

            fileSizeLabel.textColor = appearance.colorPalette.subtitleText
            fileSizeLabel.font = appearance.fonts.subheadlineBold
            fileNameLabel.font = appearance.fonts.bodyBold
            fileNameLabel.lineBreakMode = .byTruncatingMiddle
            fileIconImageView.contentMode = .center
            backgroundColor = appearance.colorPalette.popoverBackground
            layer.cornerRadius = 12
            layer.masksToBounds = true
            layer.borderWidth = 1
            layer.borderColor = appearance.colorPalette.border.cgColor
        }

        override open func setUpLayout() {
            super.setUpLayout()
            addSubview(mainContainerStackView)
            mainContainerStackView.pin(to: layoutMarginsGuide)

            spinnerAndSizeStack.addArrangedSubviews([loadingIndicator, fileSizeLabel])
            fileNameAndSizeStack.addArrangedSubviews([fileNameLabel, spinnerAndSizeStack])
            mainContainerStackView.addArrangedSubviews([fileIconImageView, fileNameAndSizeStack, actionIconImageView])

            spinnerAndSizeStack.axis = .horizontal
            spinnerAndSizeStack.alignment = .leading

            fileNameAndSizeStack.axis = .vertical
            fileNameAndSizeStack.alignment = .leading
            fileNameAndSizeStack.spacing = 3

            mainContainerStackView.axis = .horizontal
            mainContainerStackView.alignment = .center
        }

        override open func updateContent() {
            super.updateContent()

            fileIconImageView.image = fileIcon
            // If we cannot fetch filename, let's use only content type.
            fileNameLabel.text = content?.payload.title ?? content?.type.rawValue

            let downloadState = content?.downloadingState?.state
            let uploadState = content?.uploadingState?.state
            
            if let downloadState {
                switch downloadState {
                case .downloading:
                    fileSizeLabel.text = content?.downloadingState?.fileProgress
                case .downloaded, .downloadingFailed:
                    fileSizeLabel.text = content?.payload.file.sizeString
                }
            } else if let uploadState {
                switch uploadState {
                case .uploading:
                    fileSizeLabel.text = content?.uploadingState?.fileProgress
                case .uploadingFailed:
                    fileSizeLabel.text = L10n.Message.Sending.attachmentUploadingFailed
                case .pendingUpload, .uploaded, .unknown:
                    fileSizeLabel.text = content?.payload.file.sizeString
                }
            } else {
                fileSizeLabel.text = content?.payload.file.sizeString
            }
            
            actionIconImageView.image = {
                guard let fileSize = content?.file.size, fileSize > 0 else { return nil }
                guard content?.file.type != .unknown else { return nil }
                return appearance.fileAttachmentActionIcon(
                    uploadState: uploadState,
                    downloadState: downloadState,
                    downloadingEnabled: Components.default.isDownloadFileAttachmentsEnabled
                )
            }()

            loadingIndicator.isVisible = {
                if let downloadState, case .downloading = downloadState {
                    return true
                }
                if let uploadState {
                    switch uploadState {
                    case .pendingUpload, .uploading:
                        return true
                    default:
                        return false
                    }
                }
                return false
            }()

            if content?.file.type == .unknown {
                fileNameLabel.text = L10n.Message.unsupportedAttachment
                fileSizeLabel.isHidden = true
            }
        }

        @objc open func didTapOnAttachment(_ recognizer: UITapGestureRecognizer) {
            guard let attachment = content else { return }
            didTapOnAttachment?(attachment)
        }

        @objc open func didTapActionOnAttachment(_ recognizer: UITapGestureRecognizer) {
            guard let attachment = content else { return }
            didTapActionOnAttachment?(attachment)
        }

        private var fileIcon: UIImage? {
            guard let file = content?.payload.file else { return nil }

            /// If the `file.type` is `.aac` (VoiceRecording) but we `VoiceRecordings` feature
            /// is disabled, we don't want to show the `.aac` new icon and instead we are mapping it
            /// to an `.mp3`.
            let fileType: AttachmentFileType = file.type == .aac ? .mp3 : file.type

            return appearance.images.fileIcons[fileType] ?? appearance.images.fileFallback
        }
    }
}
