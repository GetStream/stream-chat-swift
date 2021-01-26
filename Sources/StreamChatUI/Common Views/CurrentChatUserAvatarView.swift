//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias CurrentChatUserAvatarView = _CurrentChatUserAvatarView<NoExtraData>

open class _CurrentChatUserAvatarView<ExtraData: ExtraDataTypes>: Control, UIConfigProvider {
    // MARK: - Properties
    
    public var controller: _CurrentChatUserController<ExtraData>? {
        didSet {
            controller?.setDelegate(self)
            updateContentIfNeeded()
        }
    }
    
    // MARK: - Subviews
    
    public private(set) lazy var avatarView = uiConfig
        .currentUser
        .avatarView.init()
        .withoutAutoresizingMaskConstraints
    
    // MARK: - Overrides
    
    override public func defaultAppearance() {
        defaultIntrinsicContentSize = .init(width: 32, height: 32)
    }
    
    open var defaultIntrinsicContentSize: CGSize?
    override open var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? super.intrinsicContentSize
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

    // MARK: - Content

    override open func setUp() {
        super.setUp()
        avatarView.isUserInteractionEnabled = false
    }

    override open func setUpLayout() {
        super.setUpLayout()

        widthAnchor.pin(equalTo: heightAnchor).isActive = true
        avatarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        avatarView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        embed(avatarView)
    }
    
    @objc override open func updateContent() {
        if let imageURL = controller?.currentUser?.imageURL {
            avatarView.imageView.setImage(from: imageURL)
        } else {
            avatarView.imageView.image = nil
        }
        
        alpha = state == .normal ? 1 : 0.5
    }
}

// MARK: - CurrentChatUserControllerDelegate

extension _CurrentChatUserAvatarView: _CurrentChatUserControllerDelegate {
    public func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser: EntityChange<_CurrentChatUser<ExtraData.User>>
    ) {
        updateContentIfNeeded()
    }
}
