//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension ChatMessageFileAttachmentListView {
    open class ItemView: _View, ThemeProvider {
        /// Content of the attachment `ChatMessageFileAttachment`
        public var content: ChatMessageFileAttachment? {
            didSet { updateContentIfNeeded() }
        }
        
        /// Closure what should happen on tapping the given attachment.
        open var didTapOnAttachment: ((ChatMessageFileAttachment) -> Void)?
        
        /// Label which shows name of the file, usually with extension (file.pdf)
        open private(set) lazy var fileNameLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
        
        /// Label indicating size of the file.
        open private(set) lazy var fileSizeLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
        
        /// Animated indicator showing progress of uploading of a file.
        open private(set) lazy var loadingIndicator = components
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints
        
        /// imageView indicating action for the file attachment. (Download / Retry upload...)
        open private(set) lazy var actionIconImageView = UIImageView().withoutAutoresizingMaskConstraints

        open private(set) lazy var mainContainerStackView: ContainerStackView = ContainerStackView()
            .withoutAutoresizingMaskConstraints
        
        /// Stack containing loading indicator and label with fileSize.
        open private(set) lazy var spinnerAndSizeStack: ContainerStackView = ContainerStackView()
            .withoutAutoresizingMaskConstraints

        /// Stack containing file name and and the size of the file.
        open private(set) lazy var fileNameAndSizeStack: ContainerStackView = ContainerStackView()
            .withoutAutoresizingMaskConstraints

        open private(set) lazy var fileIconImageView = UIImageView().withoutAutoresizingMaskConstraints

        override open func setUp() {
            super.setUp()

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnAttachment(_:)))
            addGestureRecognizer(tapRecognizer)
        }

        override open func setUpAppearance() {
            super.setUpAppearance()

            fileSizeLabel.textColor = appearance.colorPalette.subtitleText
            fileSizeLabel.font = appearance.fonts.subheadlineBold
            fileNameLabel.font = appearance.fonts.bodyBold
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

            switch content?.uploadingState?.state {
            case .uploaded:
                fileSizeLabel.text = content?.payload.file.sizeString
            case .uploadingFailed:
                fileSizeLabel.text = L10n.Message.Sending.attachmentUploadingFailed
            default:
                fileSizeLabel.text = content?.uploadingState?.fileUploadingProgress
            }
        
            if let state = content?.uploadingState?.state {
                actionIconImageView.image = appearance.fileAttachmentActionIcon(for: state)
            } else {
                actionIconImageView.image = nil
            }

            switch content?.uploadingState?.state {
            case .pendingUpload, .uploading:
                loadingIndicator.isVisible = true
            default:
                loadingIndicator.isVisible = false
            }
        }

        @objc open func didTapOnAttachment(_ recognizer: UITapGestureRecognizer) {
            guard let attachment = content else { return }
            didTapOnAttachment?(attachment)
        }

        private var fileIcon: UIImage? {
            guard let file = content?.payload.file else { return nil }
            return appearance.images.fileIcons[file.type] ?? appearance.images.fileFallback
        }
    }
}
