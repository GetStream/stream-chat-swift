//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageInteractiveAttachmentView: _View, ThemeProvider {
    public var content: ChatMessageGiphyAttachment? {
        didSet { updateContentIfNeeded() }
    }

    public var didTapOnAction: ((AttachmentAction) -> Void)?

    // MARK: - Subviews

    public private(set) lazy var preview = components
        .giphyView
        .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "preview")

    public private(set) lazy var separator = UIView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "separator")

    public private(set) lazy var actionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 1
        return stack
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "actionsStackView")
    }()

    // MARK: - Overrides

    override open func setUpAppearance() {
        super.setUpAppearance()
        preview.layer.cornerRadius = 8
        preview.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        preview.clipsToBounds = true

        separator.backgroundColor = appearance.colorPalette.border
    }

    override open func setUpLayout() {
        addSubview(preview)
        addSubview(separator)
        addSubview(actionsStackView)

        NSLayoutConstraint.activate([
            preview.leadingAnchor.pin(equalTo: leadingAnchor),
            preview.trailingAnchor.pin(equalTo: trailingAnchor),
            preview.topAnchor.pin(equalTo: topAnchor),
            preview.heightAnchor.pin(equalTo: preview.widthAnchor),
            
            separator.topAnchor.pin(equalTo: preview.bottomAnchor),
            separator.leadingAnchor.pin(equalTo: leadingAnchor),
            separator.trailingAnchor.pin(equalTo: trailingAnchor),
            separator.heightAnchor.pin(equalToConstant: 1),
            
            actionsStackView.topAnchor.pin(equalTo: separator.bottomAnchor),
            actionsStackView.leadingAnchor.pin(equalTo: leadingAnchor),
            actionsStackView.trailingAnchor.pin(equalTo: trailingAnchor),
            actionsStackView.bottomAnchor.pin(equalTo: bottomAnchor)
        ])
    }

    override open func updateContent() {
        preview.content = content

        actionsStackView.removeAllArrangedSubviews()
        
        (content?.actions ?? [])
            .map(createActionButton)
            .forEach(actionsStackView.addArrangedSubview)
    }

    // MARK: - Private

    private func createActionButton(for action: AttachmentAction) -> ActionButton {
        let button = components
            .giphyActionButton
            .init()

        button.didTap = { [weak self] in
            self?.didTapOnAction?(action)
        }

        button.content = action

        return button
    }
}
