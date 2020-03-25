//
//  ChatViewController+TableFooterView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 04/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import StreamChatCore

// MARK: - Table Footer View

extension ChatViewController {
    
    func updateFooterView() {
        guard let footerView = tableView.tableFooterView as? ChatFooterView, let presenter = presenter else {
            return
        }
        
        footerView.hide()
        
        guard InternetConnection.shared.state == .available else {
            footerView.isHidden = false
            footerView.textLabel.text = "Waiting for network..."
            return
        }
        
        guard Client.shared.isConnected else {
            footerView.isHidden = false
            footerView.textLabel.text = "Connecting..."
            footerView.activityIndicatorView.startAnimating()
            return
        }
        
        guard !presenter.typingUsers.isEmpty, let user = presenter.typingUsers.first?.user else {
            return
        }
        
        footerView.isHidden = false
        footerView.textLabel.text = presenter.typingUsersText()
        footerView.avatarView.update(with: user.avatarURL, name: user.name, baseColor: style.incomingMessage.chatBackgroundColor)
        footerView.hide(after: TypingUser.timeout)
    }
}
