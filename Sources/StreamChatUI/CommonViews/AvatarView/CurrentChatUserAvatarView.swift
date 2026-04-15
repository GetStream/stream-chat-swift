//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import UIKit

/// A UIControl subclass that is designed to show the avatar of the currently logged in user.
///
/// It uses `CurrentChatUserController` for its input data and is able to update the avatar automatically based
/// on the currently logged-in user.
///
open class CurrentChatUserAvatarView: _Control, ThemeProvider {
    /// `StreamChat`'s controller that observe the currently logged-in user.
    open var controller: CurrentChatUserController? {
        didSet {
            controller?.delegate = self
            controller?.synchronize()
            updateContentIfNeeded()
        }
    }

    /// The view that shows the current user's avatar.
    open private(set) lazy var avatarView: ChatUserAvatarView = {
        let view = components
            .userAvatarView.init()
            .withoutAutoresizingMaskConstraints
        view.shouldShowOnlineIndicator = false
        return view
    }()

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = .clear
        avatarView.presenceAvatarView.avatarView.imageView.backgroundColor = appearance.colorPalette.backgroundCoreApp
    }

    override open var isEnabled: Bool {
        get { super.isEnabled }
        set { super.isEnabled = newValue; updateContentIfNeeded() }
    }

    override open var isHighlighted: Bool {
        get { super.isHighlighted }
        set { super.isHighlighted = newValue; updateContentIfNeeded() }
    }

    override open var isSelected: Bool {
        get { super.isSelected }
        set { super.isSelected = newValue; updateContentIfNeeded() }
    }

    override open func setUp() {
        super.setUp()
        avatarView.isUserInteractionEnabled = false
    }

    override open func setUpLayout() {
        super.setUpLayout()

        heightAnchor.pin(equalToConstant: 32).isActive = true
        widthAnchor.pin(equalTo: heightAnchor).isActive = true

        embed(avatarView)
        avatarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        avatarView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    @objc override open func updateContent() {
        if let currentUser = controller?.currentUser {
            avatarView.content = currentUser
        } else {
            avatarView.content = nil
        }

        alpha = state == .normal ? 1 : 0.5
    }
}

// MARK: - CurrentChatUserControllerDelegate

extension CurrentChatUserAvatarView: CurrentChatUserControllerDelegate {
    public func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUser: EntityChange<CurrentChatUser>
    ) {
        updateContentIfNeeded()
    }
}
