//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageInteractiveAttachmentView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public var content: AttachmentListViewData<ExtraData>.ItemData? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var preview = uiConfig
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .giphyAttachmentView
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline).italic
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label.withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var separator = UIView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var actionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 1
        return stack.withoutAutoresizingMaskConstraints
    }()

    // MARK: - Overrides

    override public func defaultAppearance() {
        preview.layer.cornerRadius = 8
        preview.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        preview.clipsToBounds = true

        separator.backgroundColor = uiConfig.colorPalette.messageInteractiveAttachmentActionsBorder
    }

    override open func setUpLayout() {
        addSubview(preview)
        addSubview(titleLabel)
        addSubview(separator)
        addSubview(actionsStackView)

        NSLayoutConstraint.activate([
            preview.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            preview.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            preview.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            preview.heightAnchor.constraint(equalTo: preview.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalToSystemSpacingBelow: preview.bottomAnchor, multiplier: 1),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            separator.topAnchor.constraint(equalToSystemSpacingBelow: titleLabel.bottomAnchor, multiplier: 1),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            
            actionsStackView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            actionsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            actionsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            actionsStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override open func updateContent() {
        preview.content = content?.attachment

        titleLabel.text = "\"" + (content?.attachment.title ?? "") + "\""

        actionsStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        content?.attachment.actions
            .map(createActionButton)
            .forEach(actionsStackView.addArrangedSubview)
    }

    // MARK: - Private

    private func createActionButton(for action: AttachmentAction) -> ActionButton {
        let button = uiConfig
            .messageList
            .messageContentSubviews
            .attachmentSubviews
            .interactiveAttachmentActionButton
            .init()

        button.content = .init(action: action) { [weak self] in
            self?.content?.didTapOnAttachmentAction(action)
        }

        return button
    }
}
