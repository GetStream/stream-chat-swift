//
//  ChatViewController+TableFooterView.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 04/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: - Table Footer View

extension ChatViewController {
    
    func updateFooterView(_ isUsersTyping: Bool) {
        guard let footerView = tableView.tableFooterView as? ChatFooterView else {
            return
        }
        
        guard let presenter = channelPresenter, !presenter.typingUsers.isEmpty, let user = presenter.typingUsers.first else {
            footerView.isHidden = true
            return
        }
        
        footerView.isHidden = false
        footerView.textLabel.text = presenter.typingUsersText()
        footerView.avatarView.update(with: user.avatarURL, name: user.name, baseColor: style.backgroundColor)
        footerView.hide(after: 5)
    }
}
