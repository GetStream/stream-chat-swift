//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// /// The composer view that layouts all the components to create a new message.
///
/// High level overview of the composer layout:
/// ```
/// |---------------------------------------------------------|
/// |                       headerView                        |
/// |---------------------------------------------------------|--|
/// | leadingContainer | inputMessageView | trailingContainer |  | = centerContainer
/// |---------------------------------------------------------|--|
/// |                     bottomContainer                     |
/// |---------------------------------------------------------|
/// ```
public typealias ComposerView = _ComposerView<NoExtraData>

/// /// The composer view that layouts all the components to create a new message.
///
/// High level overview of the composer layout:
/// ```
/// |---------------------------------------------------------|
/// |                       headerView                        |
/// |---------------------------------------------------------|--|
/// | leadingContainer | inputMessageView | trailingContainer |  | = centerContainer
/// |---------------------------------------------------------|--|
/// |                     bottomContainer                     |
/// |---------------------------------------------------------|
/// ```
open class _ComposerView<ExtraData: ExtraDataTypes>: _View, ThemeProvider {
    /// The main container of the composer that layouts all the other containers around the message input view.
    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The header view that displays components above the message input view.
    public private(set) lazy var headerView = UIView()
        .withoutAutoresizingMaskConstraints

    /// The container that displays the components below the message input view.
    public private(set) lazy var bottomContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The container that layouts the message input view and the leading/trailing containers around it.
    public private(set) lazy var centerContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The container that displays the components in the leading side of the message input view.
    public private(set) lazy var leadingContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The container that displays the components in the trailing side of the message input view.
    public private(set) lazy var trailingContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// A view to to input content of the new message.
    public private(set) lazy var inputMessageView: _InputChatMessageView<ExtraData> = components
        .inputMessageView.init()
        .withoutAutoresizingMaskConstraints

    /// A button to send the message.
    public private(set) lazy var sendButton: UIButton = components
        .sendButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to confirm when editing a message.
    public private(set) lazy var confirmButton: UIButton = components
        .confirmButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to open the user attachments.
    public private(set) lazy var attachmentButton: UIButton = components
        .attachmentButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to open the available commands.
    public private(set) lazy var commandsButton: UIButton = components
        .commandsButton.init()
        .withoutAutoresizingMaskConstraints

    /// A Button for shrinking the input view to allow more space for other actions.
    public private(set) lazy var shrinkInputButton: UIButton = components
        .shrinkInputButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to dismiss the current state (quoting, editing, etc..).
    public private(set) lazy var dismissButton: UIButton = components
        .closeButton.init()
        .withoutAutoresizingMaskConstraints

    /// A label part of the header view to display the current state (quoting, editing, etc..).
    public private(set) lazy var titleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory

    /// A checkbox to check/uncheck if the message should also
    /// be sent to the channel while replying in a thread.
    public private(set) lazy var checkboxControl: CheckboxControl = components
        .checkmarkControl.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        backgroundColor = appearance.colorPalette.background
        layer.shadowColor = UIColor.systemGray.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        layer.shadowRadius = 0.5

        titleLabel.textAlignment = .center
        titleLabel.textColor = appearance.colorPalette.text
        titleLabel.font = appearance.fonts.bodyBold
        titleLabel.adjustsFontForContentSizeCategory = true
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        embed(container)

        container.isLayoutMarginsRelativeArrangement = true
        container.axis = .vertical
        container.alignment = .fill
        container.addArrangedSubview(headerView)
        container.addArrangedSubview(centerContainer)
        container.addArrangedSubview(bottomContainer)
        bottomContainer.isHidden = true
        headerView.isHidden = true

        bottomContainer.addArrangedSubview(checkboxControl)
        headerView.addSubview(titleLabel)
        headerView.addSubview(dismissButton)

        centerContainer.axis = .horizontal
        centerContainer.alignment = .bottom
        centerContainer.spacing = .auto
        centerContainer.addArrangedSubview(leadingContainer)
        centerContainer.addArrangedSubview(inputMessageView)
        centerContainer.addArrangedSubview(trailingContainer)
        
        trailingContainer.alignment = .center
        trailingContainer.spacing = .auto
        trailingContainer.distribution = .equal
        trailingContainer.isLayoutMarginsRelativeArrangement = true
        trailingContainer.directionalLayoutMargins = .zero
        trailingContainer.addArrangedSubview(sendButton)
        trailingContainer.addArrangedSubview(confirmButton)
        confirmButton.isHidden = true

        leadingContainer.axis = .horizontal
        leadingContainer.alignment = .center
        leadingContainer.spacing = .auto
        leadingContainer.distribution = .equal
        leadingContainer.isLayoutMarginsRelativeArrangement = true
        leadingContainer.directionalLayoutMargins = .zero
        leadingContainer.addArrangedSubview(attachmentButton)
        leadingContainer.addArrangedSubview(commandsButton)
        leadingContainer.addArrangedSubview(shrinkInputButton)
        shrinkInputButton.isHidden = true

        dismissButton.widthAnchor.pin(equalToConstant: 24).isActive = true
        dismissButton.heightAnchor.pin(equalToConstant: 24).isActive = true
        dismissButton.trailingAnchor.pin(equalTo: trailingContainer.trailingAnchor).isActive = true
        titleLabel.centerXAnchor.pin(equalTo: centerXAnchor).isActive = true
        titleLabel.pin(anchors: [.top, .bottom], to: headerView)

        [shrinkInputButton, attachmentButton, commandsButton, sendButton, confirmButton]
            .forEach { button in
                button.pin(anchors: [.width], to: 20)
                button.pin(anchors: [.height], to: 38)
            }
    }
}
