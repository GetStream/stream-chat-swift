//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelDetailCollectionHeaderView<ExtraData: ExtraDataTypes>: UICollectionReusableView, UIConfigProvider {
    class var reuseId: String { String(describing: self) }
    
    var channel: _ChatChannel<ExtraData>?
    
    open lazy var avatarView: ChatChannelAvatarView<ExtraData> = {
        let avatar = ChatChannelAvatarView<ExtraData>(frame: CGRect(x: 0, y: 0, width: 72, height: 72))
        avatar.channelAndUserId = (channel, nil)
        return avatar
    }()
    
    open lazy var nameView: UILabel = {
        let nameView = UILabel()
        nameView.textAlignment = .center
        nameView.font = .preferredFont(forTextStyle: .headline)
        nameView.text = "User" // TODO: Real Data
        return nameView
    }()
    
    open lazy var onlineIndicatorView: OnlineIndicatorView<ExtraData> = {
        OnlineIndicatorView<ExtraData>(
            frame: CGRect(x: 0, y: 0, width: 4, height: 4)
        )
    }()
    
    open lazy var onlineTimeLabel: UILabel = {
        let onlineTimeLabel = UILabel()
        onlineTimeLabel.textAlignment = .center
        onlineTimeLabel.font = .preferredFont(forTextStyle: .subheadline)
        onlineTimeLabel.textColor = uiConfig.colorPalette.subtitleText
        onlineTimeLabel.text = "Online for 5 mins" // TODO: Real Data
        return onlineTimeLabel
    }()
    
    open lazy var onlineView: UIStackView = {
        let onlineView = UIStackView(arrangedSubviews: [onlineIndicatorView, onlineTimeLabel])
        onlineView.axis = .horizontal
        onlineView.distribution = .equalCentering
        onlineView.alignment = .center
        onlineView.spacing = 5
        return onlineView
    }()
    
    open lazy var userView: UIStackView = {
        let userView = UIStackView(arrangedSubviews: [nameView, onlineView])
        userView.axis = .vertical
        userView.alignment = .center
        userView.spacing = 4
        return userView
    }()
    
    open lazy var containerView: UIStackView = {
        let containerView = UIStackView(arrangedSubviews: [avatarView, userView])
        containerView.axis = .vertical
        containerView.alignment = .center
        containerView.distribution = .equalSpacing
        containerView.spacing = 3
        return containerView
    }()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = uiConfig.colorPalette.generalBackground
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        addSeperatorLine()
        embed(containerView, insets: .init(top: 10, leading: 0, bottom: 10, trailing: 0))
        onlineIndicatorView.widthAnchor.pin(equalToConstant: 10).isActive = true
    }
    
    private func addSeperatorLine() {
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 0, height: -1)
        layer.shadowRadius = 1
        layer.shadowOpacity = 1
        layer.shadowColor = UIColor.black.cgColor
    }
}
