//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension _ChatMessageFileAttachmentListView {
    open class ItemView: _View, ThemeProvider {
        public var content: ChatMessageFileAttachment? {
            didSet { updateContentIfNeeded() }
        }

        public var didTapOnAttachment: ((ChatMessageFileAttachment) -> Void)?

        // MARK: - Subviews

        public private(set) lazy var fileNameLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory

        public private(set) lazy var fileSizeLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory

        public private(set) lazy var loadingIndicator = components
            .messageList
            .messageContentSubviews
            .attachmentSubviews
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints

        public private(set) lazy var actionIconImageView = UIImageView()
            .withoutAutoresizingMaskConstraints

        public private(set) lazy var spinnerAndSizeStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [loadingIndicator, fileSizeLabel])
            stack.axis = .horizontal
            stack.spacing = UIStackView.spacingUseSystem
            stack.alignment = .center
            return stack.withoutAutoresizingMaskConstraints
        }()

        public private(set) lazy var fileNameAndSizeStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [fileNameLabel, spinnerAndSizeStack])
            stack.axis = .vertical
            stack.alignment = .leading
            stack.spacing = 3
            return stack.withoutAutoresizingMaskConstraints
        }()

        public private(set) lazy var fileIconImageView = UIImageView()
            .withoutAutoresizingMaskConstraints

        // MARK: - Overrides

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

            addSubview(fileIconImageView)
            addSubview(actionIconImageView)
            addSubview(fileNameAndSizeStack)

            NSLayoutConstraint.activate([
                fileIconImageView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
                fileIconImageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
                fileIconImageView.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor),
                
                actionIconImageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
                actionIconImageView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
                actionIconImageView.leadingAnchor.pin(
                    equalToSystemSpacingAfter: fileNameAndSizeStack.trailingAnchor,
                    multiplier: 1
                ),
                
                fileNameAndSizeStack.leadingAnchor.pin(
                    equalToSystemSpacingAfter: fileIconImageView.trailingAnchor,
                    multiplier: 2
                ),
                fileNameAndSizeStack.centerYAnchor.pin(equalTo: centerYAnchor),
                fileNameAndSizeStack.topAnchor.pin(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
                fileNameAndSizeStack.bottomAnchor.pin(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor)
            ])
        }

        override open func updateContent() {
            super.updateContent()

            fileIconImageView.image = fileIcon
            fileNameLabel.text = content?.type.rawValue

            if case .uploadingFailed = content?.uploadingState?.state {
                fileSizeLabel.text = L10n.Message.Sending.attachmentUploadingFailed
            } else {
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

        // MARK: - Actions

        @objc open func didTapOnAttachment(_ recognizer: UITapGestureRecognizer) {
            guard let attachment = content else { return }

            didTapOnAttachment?(attachment)
        }

        // MARK: - Private

        private var fileIcon: UIImage? {
            guard let file = content?.payload?.file else { return nil }

            return appearance.images.fileIcons[file.type] ?? appearance.images.fileFallback
        }
    }
}
