//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A UIControl subclass that is designed to show the avatar of the currently logged in user.
///
/// It uses `CurrentChatUserController` for its input data and is able to update the avatar automatically based
/// on the currently logged-in user.
///
internal typealias CurrentChatUserAvatarView = _CurrentChatUserAvatarView<NoExtraData>

/// A UIControl subclass that is designed to show the avatar of the currently logged in user.
///
/// It uses `CurrentChatUserController` for its input data and is able to update the avatar automatically based
/// on the currently logged-in user.
///
internal class _CurrentChatUserAvatarView<ExtraData: ExtraDataTypes>: _Control, UIConfigProvider {
    /// `StreamChat`'s controller that observe the currently logged-in user.
    internal var controller: _CurrentChatUserController<ExtraData>? {
        didSet {
            controller?.setDelegate(self)
            controller?.synchronize()
            updateContentIfNeeded()
        }
    }
    
    /// The view that shows the current user's avatar.
    internal private(set) lazy var avatarView: ChatAvatarView = uiConfig
        .currentUser
        .avatarView.init()
        .withoutAutoresizingMaskConstraints
    
    override internal func defaultAppearance() {
        super.defaultAppearance()
        
        backgroundColor = .clear
        avatarView.imageView.backgroundColor = uiConfig.colorPalette.background
    }

    override internal var isEnabled: Bool {
        get { super.isEnabled }
        set { super.isEnabled = newValue; updateContentIfNeeded() }
    }
    
    override internal var isHighlighted: Bool {
        get { super.isHighlighted }
        set { super.isHighlighted = newValue; updateContentIfNeeded() }
    }
    
    override internal var isSelected: Bool {
        get { super.isSelected }
        set { super.isSelected = newValue; updateContentIfNeeded() }
    }

    override internal func setUp() {
        super.setUp()
        avatarView.isUserInteractionEnabled = false
    }

    override internal func setUpLayout() {
        super.setUpLayout()

        heightAnchor.pin(equalToConstant: 32).isActive = true
        widthAnchor.pin(equalTo: heightAnchor).isActive = true

        embed(avatarView)
        avatarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        avatarView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }
    
    @objc override internal func updateContent() {
        if let imageURL = controller?.currentUser?.imageURL {
            avatarView.imageView.loadImage(from: imageURL)
        } else {
            avatarView.imageView.image = nil
        }
        
        alpha = state == .normal ? 1 : 0.5
    }
}

// MARK: - CurrentChatUserControllerDelegate

extension _CurrentChatUserAvatarView: _CurrentChatUserControllerDelegate {
    internal func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser: EntityChange<_CurrentChatUser<ExtraData>>
    ) {
        updateContentIfNeeded()
    }
}
