//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension ChatFileAttachmentListView {
    open class ItemView: View, UIConfigProvider {
        public var content: _ChatMessageAttachment<ExtraData>? {
            didSet { updateContentIfNeeded() }
        }

        public var tapHandler: () -> Void = {}

        // MARK: - Subviews

        public private(set) lazy var fileIconImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            return imageView.withoutAutoresizingMaskConstraints
        }()

        public private(set) lazy var fileNameLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .body).bold
            label.adjustsFontForContentSizeCategory = true
            return label.withoutAutoresizingMaskConstraints
        }()

        public private(set) lazy var fileSizeLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .footnote)
            label.adjustsFontForContentSizeCategory = true
            return label.withoutAutoresizingMaskConstraints
        }()

        public private(set) lazy var activityIndicator: UIActivityIndicatorView = {
            let indicator = UIActivityIndicatorView()
            indicator.hidesWhenStopped = true
            return indicator.withoutAutoresizingMaskConstraints
        }()

        public private(set) lazy var actionIconImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            return imageView.withoutAutoresizingMaskConstraints
        }()

        public private(set) lazy var spinnerAndSizeStack: UIStackView = {
            let stack = UIStackView()
            stack.axis = .horizontal
            return stack.withoutAutoresizingMaskConstraints
        }()

        public private(set) lazy var fileNameAndSizeStack: UIStackView = {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.alignment = .leading
            return stack.withoutAutoresizingMaskConstraints
        }()

        // MARK: - Overrides

        override public func defaultAppearance() {
            backgroundColor = .white
            layer.cornerRadius = 12
            layer.masksToBounds = true
            layer.borderWidth = 1 / UIScreen.main.scale
            layer.borderColor = uiConfig.colorPalette.incomingMessageBubbleBorder.cgColor
            fileSizeLabel.textColor = uiConfig.colorPalette.subtitleText
            spinnerAndSizeStack.spacing = UIStackView.spacingUseSystem
            fileNameAndSizeStack.spacing = 3
            activityIndicator.style = .gray
        }

        override open func setUp() {
            super.setUp()

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnAttachment(_:)))
            addGestureRecognizer(tapRecognizer)
        }

        override open func setUpLayout() {
            spinnerAndSizeStack.addArrangedSubview(activityIndicator)
            spinnerAndSizeStack.addArrangedSubview(fileSizeLabel)

            fileNameAndSizeStack.addArrangedSubview(fileNameLabel)
            fileNameAndSizeStack.addArrangedSubview(spinnerAndSizeStack)

            addSubview(fileNameAndSizeStack)
            addSubview(fileIconImageView)
            addSubview(actionIconImageView)

            NSLayoutConstraint.activate([
                fileIconImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                fileIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                fileIconImageView.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
                fileIconImageView.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor),
                
                actionIconImageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                actionIconImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                actionIconImageView.leadingAnchor.constraint(
                    equalToSystemSpacingAfter: fileNameAndSizeStack.trailingAnchor,
                    multiplier: 1
                ),
                
                fileNameAndSizeStack.leadingAnchor.constraint(
                    equalToSystemSpacingAfter: fileIconImageView.trailingAnchor,
                    multiplier: 2
                ),
                fileNameAndSizeStack.centerYAnchor.constraint(equalTo: centerYAnchor),
                fileNameAndSizeStack.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
                fileNameAndSizeStack.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor)
            ])
        }

        override open func updateContent() {
            fileNameLabel.text = content?.title
            fileIconImageView.image = fileIcon
            fileSizeLabel.text = content?.fileSize
            actionIconImageView.image = fileAttachmentActionIcon

            if case .uploading = content?.localState {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }

        // MARK: - Actions

        @objc open func didTapOnAttachment(_ recognizer: UITapGestureRecognizer) {
            tapHandler()
        }

        // MARK: - Private

        private var fileIcon: UIImage? {
            guard let file = content?.file else { return nil }

            let config = uiConfig
                .messageList
                .messageContentSubviews
                .attachmentSubviews

            return config.fileIcons[file.type] ?? config.fileFallbackIcon
        }

        private var fileAttachmentActionIcon: UIImage? {
            guard let attachment = content else { return nil }

            return uiConfig
                .messageList
                .messageContentSubviews
                .attachmentSubviews
                .fileAttachmentActionIcons[attachment.localState]
        }
    }
}

// MARK: - Private

private extension _ChatMessageAttachment {
    var fileSize: String? {
        guard let file = file else { return nil }

        switch localState {
        case let .uploading(progress):
            let uploadedByteCount = Int64(Double(file.size) * progress)
            let uploadedSize = AttachmentFile.sizeFormatter.string(fromByteCount: uploadedByteCount)
            return "\(uploadedSize)/\(file.sizeString)"
        case .pendingUpload:
            return "0/\(file.sizeString)"
        case .uploaded, .uploadingFailed, nil:
            return file.sizeString
        }
    }
}
