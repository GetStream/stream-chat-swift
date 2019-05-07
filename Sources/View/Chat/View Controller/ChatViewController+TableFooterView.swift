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
    
    func updateFooterView(_ isUsersTyping: Bool, _ startWatchingUser: User?, _ stoptWatchingUser: User?) {
        if isUsersTyping {
            updateFooterForUsersTyping()
        }
        
        if let startWatchingUser = startWatchingUser {
            addStartWatchingUser(startWatchingUser)
        }
        
        updateFooterView()
    }
    
    func updateFooterView() {
        guard let footerView = tableView.tableFooterView as? ChatTableFooterView else {
            return
        }
        
        if footerView.isEmpty {
            UIView.animateSmooth(withDuration: 0.3) { self.tableView.layoutFooterView() }
        } else {
            let needsToScroll = tableView.bottomContentOffset < .chatBottomThreshold
            tableView.layoutFooterView()
            
            if scrollEnabled, needsToScroll {
                tableView.scrollToBottom()
            }
        }
    }
    
    private func updateFooterForUsersTyping() {
        guard let presenter = channelPresenter, let footerView = tableView.tableFooterView as? ChatTableFooterView else {
            return
        }
        
        if presenter.typingUsers.isEmpty {
            footerView.removeMessageFooterView(by: 1)
            
        } else if let user = presenter.typingUsers.first {
            let messageFooterView: MessageFooterView
            
            if let existsMessageFooterView = footerView.messageFooterView(by: 1) {
                messageFooterView = existsMessageFooterView
                existsMessageFooterView.restartHidingTimer()
            } else {
                messageFooterView = MessageFooterView(frame: .zero)
                messageFooterView.tag = 1
                footerView.add(messageFooterView: messageFooterView, timeout: 30) { [weak self] in self?.updateFooterView() }
            }
            
            messageFooterView.textLabel.text = presenter.typingUsersText()
            messageFooterView.avatarView.update(with: user.avatarURL, name: user.name)
        }
    }
    
    private func addStartWatchingUser(_ user: User) {
        guard let footerView = tableView.tableFooterView as? ChatTableFooterView else {
            return
        }
        
        let messageFooterView = MessageFooterView(frame: .zero)
        messageFooterView.textLabel.text = "\(user.name) joined the chat."
        messageFooterView.avatarView.update(with: user.avatarURL, name: user.name)
        
        footerView.add(messageFooterView: messageFooterView, timeout: 3) { [weak self] in
            self?.updateFooterView()
        }
    }
}
