//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

import StreamChat
import StreamChatUI

class ChannelList<ExtraData: ExtraDataTypes>: ChatChannelListViewController<ExtraData>
    where ExtraData.Channel: NameAndImageProviding
{}

enum SecretExtraData: ExtraDataTypes {
    typealias Channel = Secret
}

struct Secret: ChannelExtraData, NameAndImageProviding {
    var displayName: String { "Channel name from extra data" }
    
    var imageURL: URL? = nil
    
    static var defaultValue: Secret = .init(isSecret: false)
    
    var isSecret: Bool
}

class SecretUnreadIndicator: UnreadIndicatorView<DefaultExtraData> {
    lazy var lockLabel: UILabel = {
        let label = UILabel()
        
        label.text = "🔒"
        
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: self.topAnchor),
            label.rightAnchor.constraint(equalTo: self.rightAnchor),
            label.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            label.leftAnchor.constraint(equalTo: self.leftAnchor)
        ])
        
        return label
    }()
    
    override func load(_ channel: _ChatChannel<DefaultExtraData>) {
        if channel.isUnread {
            lockLabel.text = "🔒"
        } else {
            lockLabel.text = "🔓"
        }
    }
}
