//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageAttachmentInfoView = _ChatMessageAttachmentInfoView<NoExtraData>

open class _ChatMessageAttachmentInfoView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public var content: _ChatMessageAttachmentListViewData<ExtraData>.ItemData? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = uiConfig.font.bodyBold
        label.adjustsFontForContentSizeCategory = true
        return label.withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var fileSizeLabel: UILabel = {
        let label = UILabel()
        label.font = uiConfig.font.footnoteBold
        label.adjustsFontForContentSizeCategory = true
        return label.withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var loadingIndicator = uiConfig
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

    // MARK: - Overrides

    override public func defaultAppearance() {
        fileSizeLabel.textColor = uiConfig.colorPalette.subtitleText
    }

    override open func setUp() {
        super.setUp()

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnAttachment(_:)))
        addGestureRecognizer(tapRecognizer)
    }

    override open func setUpLayout() {
        addSubview(actionIconImageView)
        addSubview(fileNameAndSizeStack)

        fileNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        fileSizeLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            fileNameAndSizeStack.topAnchor.pin(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
            fileNameAndSizeStack.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            fileNameAndSizeStack.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor),
            
            actionIconImageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            actionIconImageView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            actionIconImageView.leadingAnchor.pin(
                greaterThanOrEqualToSystemSpacingAfter: fileNameAndSizeStack.trailingAnchor,
                multiplier: 2
            )
        ])
    }

    override open func updateContent() {
        fileNameLabel.text = content?.attachment.title
        fileSizeLabel.text = fileSize
        actionIconImageView.image = fileAttachmentActionIcon

        switch content?.attachment.localState {
        case .pendingUpload, .uploading:
            loadingIndicator.isVisible = true
        default:
            loadingIndicator.isVisible = false
        }
    }

    // MARK: - Actions

    @objc open func didTapOnAttachment(_ recognizer: UITapGestureRecognizer) {
        content?.didTapOnAttachment()
    }
}

// MARK: - Private

private extension _ChatMessageAttachmentInfoView {
    var fileAttachmentActionIcon: UIImage? {
        guard let attachment = content?.attachment else { return nil }

        return uiConfig
            .messageList
            .messageContentSubviews
            .attachmentSubviews
            .fileAttachmentActionIcons[attachment.localState]
    }

    var fileSize: String? {
        guard let file = content?.attachment.file else { return nil }

        switch content?.attachment.localState {
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
