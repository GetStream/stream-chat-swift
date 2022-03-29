//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    open private(set) lazy var informationLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints

    /// StackView holding `typingIndicatorView` and `informationLabel`
    open private(set) lazy var componentContainerView: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()
        
        typingAnimationView.startAnimating()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    override open func setUpLayout() {
        super.setUpLayout()
        
        addSubview(componentContainerView)
        componentContainerView.pin(anchors: [.centerY, .centerX], to: layoutMarginsGuide)
        componentContainerView.pin(anchors: [.top, .bottom], to: self)
        componentContainerView.addArrangedSubview(informationLabel)
        componentContainerView.addArrangedSubview(typingAnimationView)
        componentContainerView.alignment = .bottom
        componentContainerView.spacing = 4
        typingAnimationView.heightAnchor.pin(equalToConstant: 7).isActive = true
        typingAnimationView.bottomAnchor.pin(equalTo: bottomAnchor, constant: 4).isActive = true
        informationLabel.centerYAnchor.pin(equalTo: centerYAnchor).isActive = true
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        informationLabel.textAlignment = .center
        informationLabel.font = appearance.fonts.caption1
        informationLabel.textColor = appearance.colorPalette.chatNavigationTitleColor
    }

    override open func updateContent() {
        super.updateContent()
        
        informationLabel.text = content?.trimStringBy(count: 30)
    }

    // Restart Animation 
    @objc func handleAppDidBecomeActive() {
        typingAnimationView.startAnimating()
    }
}
