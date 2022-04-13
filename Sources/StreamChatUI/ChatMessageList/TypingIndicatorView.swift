//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// An `UIView` subclass indicating that user or multiple users are currently typing.
open class TypingIndicatorView: _View, ThemeProvider {
    /// The string which will be shown next to animated indication that user is typing.
    open var content: String? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The animated view with three dots indicating that someone is typing.
    open private(set) lazy var typingAnimationView: TypingAnimationView = components
        .typingAnimationView
        .init()
        .withoutAutoresizingMaskConstraints

    /// Label describing who is currently typing
    /// `User is typing`
    /// `User and 1 more is typing`
    /// `User and 3 more are typing`
    open private(set) lazy var informationLabel = UILabel().withoutAutoresizingMaskConstraints

    /// StackView holding `typingIndicatorView` and `informationLabel`
    open private(set) lazy var componentContainerView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "componentContainerView")

    override open func setUp() {
        super.setUp()
        
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
        
        backgroundColor = appearance.colorPalette.overlayBackground
        informationLabel.textColor = appearance.colorPalette.subtitleText
        informationLabel.font = appearance.fonts.body
    }

    override open func updateContent() {
        super.updateContent()
        
        informationLabel.text = content
    }
}
