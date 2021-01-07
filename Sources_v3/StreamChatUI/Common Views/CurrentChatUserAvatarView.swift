//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class CurrentChatUserAvatarView<ExtraData: ExtraDataTypes>: Control, UIConfigProvider {
    // MARK: - Properties
    
    public var controller: _CurrentChatUserController<ExtraData>? {
        didSet {
            controller?.setDelegate(self)
            updateContent()
        }
    }
    
    // MARK: - Subviews
    
    public private(set) lazy var avatarView: AvatarView = {
        let avatar = uiConfig.currentUser.avatarView.init()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        return avatar
    }()
    
    // MARK: - Overrides
    
    override public func defaultAppearance() {
        defaultIntrinsicContentSize = .init(width: 28, height: 28)
    }
    
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
    
    public required init(uiConfig: UIConfig<ExtraData> = .default) {
        super.init(frame: .zero)
        self.uiConfig = uiConfig
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Content
    
    override open func setUpAppearance() {
        avatarView.isUserInteractionEnabled = false
    }
    
    override open func setUpLayout() {
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

// MARK: - _CurrentChatUserControllerDelegate

extension CurrentChatUserAvatarView: _CurrentChatUserControllerDelegate {
    public func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser: EntityChange<_CurrentChatUser<ExtraData.User>>
    ) {
        updateContent()
    }
}
