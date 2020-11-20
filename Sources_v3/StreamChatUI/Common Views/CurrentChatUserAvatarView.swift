//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class CurrentChatUserAvatarView<ExtraData: UIExtraDataTypes>: UIControl {
    // MARK: - Properties
        
    public var controller: _CurrentChatUserController<ExtraData>? {
        didSet {
            controller?.setDelegate(self)
            updateContent()
        }
    }
    
    // MARK: - Subviews
    
    public private(set) lazy var avatarView: AvatarView = {
        let avatar = uiConfig(ExtraData.self).currentUser.avatarView.init()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        return avatar
    }()
    
    // MARK: - Overrides
    
    open var defaultIntrinsicContentSize: CGSize?
    override open var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? super.intrinsicContentSize
    }
    
    override open var isEnabled: Bool {
        get { super.isEnabled }
        set { super.isEnabled = newValue; updateContent() }
    }
    
    override open var isHighlighted: Bool {
        get { super.isHighlighted }
        set { super.isHighlighted = newValue; updateContent() }
    }
    
    override open var isSelected: Bool {
        get { super.isSelected }
        set { super.isSelected = newValue; updateContent() }
    }
    
    // MARK: - Init
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        applyDefaultAppearance()
        setupAppearance()
        setupLayout()
        updateContent()
    }

    // MARK: - Content
    
    open func setupAppearance() {
        avatarView.isUserInteractionEnabled = false
    }
    
    open func setupLayout() {
        widthAnchor.constraint(equalTo: heightAnchor).isActive = true
        avatarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        avatarView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        embed(avatarView)
    }
    
    @objc open func updateContent() {
        guard superview != nil else { return }

        if let imageURL = controller?.currentUser?.imageURL {
            avatarView.imageView.setImage(from: imageURL)
        } else {
            avatarView.imageView.image = nil
        }
        
        alpha = state == .normal ? 1 : 0.5
    }
}

// MARK: - AppearanceSetting

extension CurrentChatUserAvatarView: AppearanceSetting {
    public static func initialAppearanceSetup(_ view: CurrentChatUserAvatarView<ExtraData>) {
        view.defaultIntrinsicContentSize = .init(width: 28, height: 28)
    }
}

// MARK: - _CurrentChatUserControllerDelegate

extension CurrentChatUserAvatarView: _CurrentChatUserControllerDelegate {
    public func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser: EntityChange<_CurrentChatUser<ExtraData.User>>
    ) {
        updateContent()
    }
}
