//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// An `UIView` subclass indicating that user or multiple users are currently typing.
public typealias TypingIndicatorView = _TypingIndicatorView<NoExtraData>

/// An `UIView` subclass indicating that user or multiple users are currently typing.
open class _TypingIndicatorView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    /// The string which will be shown next to animated indication that user is typing.
    var content: String? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The animated view with three dots indicating that someone is typing.
    open private(set) lazy var typingAnimationView: _TypingAnimationView<ExtraData> = uiConfig
        .typingAnimationView
        .init()
        .withoutAutoresizingMaskConstraints

    /// Label describing who is currently typing
    /// `User is typing`
    /// `User and 1 more is typing`
    /// `User and 3 more are typing`
    open private(set) lazy var informationLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints

    /// StackView holding `typingIndicatorView` and `informationLabel`
    open private(set) lazy var componentContainerView: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints

    override open func setUp() {
        typingAnimationView.startAnimating()
    }

    override open func setUpLayout() {
        super.setUpLayout()
        addSubview(componentContainerView)
        componentContainerView.pin(anchors: [.leading, .trailing], to: layoutMarginsGuide)
        componentContainerView.pin(anchors: [.top, .bottom], to: self)
        componentContainerView.addArrangedSubview(typingAnimationView)

        componentContainerView.addArrangedSubview(informationLabel)
        componentContainerView.alignment = .center

        typingAnimationView.heightAnchor.pin(equalToConstant: 5).isActive = true
        typingAnimationView.centerYAnchor.pin(equalTo: centerYAnchor).isActive = true
        informationLabel.centerYAnchor.pin(equalTo: centerYAnchor).isActive = true
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = uiConfig.colorPalette.overlayBackground
        informationLabel.textColor = uiConfig.colorPalette.subtitleText
        informationLabel.font = uiConfig.font.body
    }

    override open func updateContent() {
        informationLabel.text = content
    }
}
