//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view to input content of a message.
public typealias ChatMessageInputView = _ChatMessageInputView<NoExtraData>

/// A view to input content of a message.
open class _ChatMessageInputView<ExtraData: ExtraDataTypes>: _View, ComponentsProvider, AppearanceProvider {
    /// The container stack view that layouts the command label, text view and the clean button.
    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The input text view to type a new message or command.
    public private(set) lazy var inputTextView: ChatInputTextView = components
        .inputTextView.init()
        .withoutAutoresizingMaskConstraints

    /// The command label that display the command info if a new command is being typed.
    public private(set) lazy var commandLabel: _ChatCommandLabel<ExtraData> = components
        .commandLabel.init()
        .withoutAutoresizingMaskConstraints

    /// A button to clean the current typing information
    public private(set) lazy var cleanButton: UIButton = UIButton()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()

        let cleanButtonImage = appearance.images.close1.tinted(with: appearance.colorPalette.inactiveTint)
        cleanButton.setImage(cleanButtonImage, for: .normal)
    }
    
    override open func setUpLayout() {
        addSubview(container)
        container.pin(to: layoutMarginsGuide)
        directionalLayoutMargins.leading = 8
        directionalLayoutMargins.top = 1
        directionalLayoutMargins.trailing = 8
        directionalLayoutMargins.bottom = 1

        container.preservesSuperviewLayoutMargins = false
        container.alignment = .center
        container.spacing = 4

        container.addArrangedSubview(commandLabel)
        container.addArrangedSubview(inputTextView)
        container.addArrangedSubview(cleanButton)

        commandLabel.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
        inputTextView.setContentCompressionResistancePriority(.streamLow, for: .horizontal)

        NSLayoutConstraint.activate([
            cleanButton.heightAnchor.pin(equalToConstant: 24),
            cleanButton.widthAnchor.pin(equalTo: cleanButton.heightAnchor, multiplier: 1)
        ])
    }

    public func setSlashCommandViews(hidden: Bool) {
        commandLabel.isHidden = hidden
        cleanButton.isHidden = hidden
    }
}
