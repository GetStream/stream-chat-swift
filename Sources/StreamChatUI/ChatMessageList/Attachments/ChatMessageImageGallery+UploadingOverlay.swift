//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension _ChatMessageImageGallery {
    open class UploadingOverlay: _View, ThemeProvider {
        public var content: ChatMessageImageAttachment? {
            didSet { updateContentIfNeeded() }
        }

        public var didTapOnAttachment: ((ChatMessageImageAttachment) -> Void)?

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

        public private(set) lazy var fileSizeContainer = UIView()
            .withoutAutoresizingMaskConstraints

        // MARK: - Overrides

        override open func layoutSubviews() {
            super.layoutSubviews()

            fileSizeContainer.layer.cornerRadius = fileSizeContainer.bounds.height / 2
        }

        override open func setUp() {
            super.setUp()

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnAttachment(_:)))
            addGestureRecognizer(tapRecognizer)
        }

        override open func setUpAppearance() {
            super.setUpAppearance()
            
            backgroundColor = appearance.colorPalette.background4

            fileNameLabel.font = appearance.fonts.bodyBold
            fileSizeLabel.font = appearance.fonts.subheadlineBold
            fileSizeLabel.textColor = .white
            fileSizeContainer.backgroundColor = appearance.colorPalette.popoverBackground
            fileSizeContainer.layer.masksToBounds = true
            fileIconImageView.contentMode = .center
        }

        override open func setUpLayout() {
            fileSizeContainer.addSubview(spinnerAndSizeStack)
            spinnerAndSizeStack.pin(to: fileSizeContainer.layoutMarginsGuide)
            
            addSubview(fileSizeContainer)
            addSubview(actionIconImageView)

            NSLayoutConstraint.activate([
                actionIconImageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
                actionIconImageView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
                
                fileSizeContainer.topAnchor.pin(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
                fileSizeContainer.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
                fileSizeContainer.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
                fileSizeContainer.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor),
                
                loadingIndicator.widthAnchor.pin(equalToConstant: 16)
            ])
        }

        override open func updateContent() {
            super.updateContent()

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

            fileSizeContainer.isVisible = loadingIndicator.isVisible
        }

        // MARK: - Actions

        @objc open func didTapOnAttachment(_ recognizer: UITapGestureRecognizer) {
            guard let attachment = content else { return }

            didTapOnAttachment?(attachment)
        }
    }
}

extension Appearance {
    func fileAttachmentActionIcon(for state: LocalAttachmentState) -> UIImage? {
        images.fileAttachmentActionIcons[state]
    }
}

extension AttachmentUploadingState {
    var fileUploadingProgress: String {
        switch state {
        case let .uploading(progress):
            let uploadedByteCount = Int64(Double(file.size) * progress)
            let uploadedSize = AttachmentFile.sizeFormatter.string(fromByteCount: uploadedByteCount)
            return "\(uploadedSize)/\(file.sizeString)"
        case .pendingUpload:
            return "0/\(file.sizeString)"
        case .uploaded, .uploadingFailed:
            return file.sizeString
        }
    }
}
