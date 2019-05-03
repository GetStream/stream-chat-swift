//
//  ChatViewController.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxKeyboard
import Nuke

public final class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    public var style = ChatViewStyle()
    private let disposeBag = DisposeBag()
    
    public private(set) lazy var composerView: ComposerView = {
        let composerView = ComposerView(frame: .zero)
        composerView.style = style.composer
        return composerView
    }()
    
    public private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerMessageCell(style: style.incomingMessage)
        tableView.registerMessageCell(style: style.outgoingMessage)
        tableView.register(cellType: StatusTableViewCell.self)
        tableView.tableFooterView = ChatTableFooterView()
        
        tableView.contentInset = UIEdgeInsets(top: 0,
                                              left: 0,
                                              bottom: CGFloat.messagesToComposerPadding,
                                              right: 0)
        
        view.insertSubview(tableView, at: 0)
        return tableView
    }()
    
    public var channelPresenter: ChannelPresenter? {
        didSet {
            if let channelPresenter = channelPresenter {
                Driver.merge(channelPresenter.changes,
                             channelPresenter.loading)
                    .drive(onNext: { [weak self] in self?.updateTableView(with: $0) })
                    .disposed(by: disposeBag)
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupComposerView()
        setupTableView()
        channelPresenter?.load()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let presenter = channelPresenter, presenter.items.count > 0 else {
            return
        }
        
        tableView.setContentOffset(tableView.contentOffset, animated: false)
        let needsToScroll = tableView.bottomContentOffset < .chatBottomThreshold
        tableView.reloadData()
        
        if needsToScroll {
            tableView.scrollToRow(at: IndexPath(row: presenter.items.count - 1, section: 0),
                                  at: .top,
                                  animated: animated)
        }
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return style.backgroundColor.isDark ? .lightContent : .default
    }
}

// MARK: - Composer

extension ChatViewController {
    
    private func setupComposerView() {
        composerView.addToSuperview(view)
        
        composerView.sendButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.send() })
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.visibleHeight
            .skip(1)
            .drive(onNext: { [weak self] height in
                guard let tableView = self?.tableView else {
                    return
                }
                
                let bottom: CGFloat = height + .messagesToComposerPadding - (height > 0
                    ? tableView.adjustedContentInset.bottom - .messagesToComposerPadding
                    : 0)
                
                tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
            })
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.willShowVisibleHeight
            .drive(onNext: { [weak self] height in
                if let self = self {
                    var contentOffset = self.tableView.contentOffset
                    contentOffset.y += height - self.view.safeAreaBottomOffset
                    self.tableView.contentOffset = contentOffset
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func send() {
        let text = composerView.text
        composerView.reset()
        channelPresenter?.send(text: text)
    }
}

// MARK: - Table View

extension ChatViewController {
    
    private func setupTableView() {
        tableView.backgroundColor = style.backgroundColor
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    private func updateTableView(with changes: ChannelChanges) {
        // Check if view is loaded nad visible.
        guard isVisible else {
            return
        }
        
        if case let .updated(row, position) = changes {
            tableView.setContentOffset(tableView.contentOffset, animated: false)
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: position, animated: false)
        }
        
        if case let .itemAdded(row, reloadRow, forceToScroll) = changes {
            let indexPath = IndexPath(row: row, section: 0)
            let needsToScroll = tableView.bottomContentOffset < .chatBottomThreshold
            
            tableView.update {
                tableView.insertRows(at: [indexPath], with: .none)
                
                if let reloadRow = reloadRow {
                    tableView.reloadRows(at: [IndexPath(row: reloadRow, section: 0)], with: .none)
                }
            }
            
            if forceToScroll || needsToScroll {
                tableView.setContentOffset(tableView.contentOffset, animated: false)
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
        
        if case let .updateFooter(isUsersTyping, startWatchingUser, stopWatchingUser) = changes {
            updateFooterView(isUsersTyping, startWatchingUser, stopWatchingUser)
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelPresenter?.items.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let presenter = channelPresenter, indexPath.row < presenter.items.count else {
            return .unused
        }
        
        switch presenter.items[indexPath.row] {
        case .loading:
            return loadingCell(at: indexPath)
        case let .status(title, subtitle):
            return statusCell(at: indexPath, title: title, subtitle: subtitle)
        case .message(let message):
            return messageCell(at: indexPath, message: message)
        case .error:
            return .unused
        }
    }
    
    private func loadingCell(at indexPath: IndexPath) -> UITableViewCell {
        channelPresenter?.loadNext()
        return statusCell(at: indexPath, title: "Loading...")
    }
    
    private func messageCell(at indexPath: IndexPath, message: Message) -> UITableViewCell {
        guard let presenter = channelPresenter else {
            return .unused
        }
        
        let isIncoming = message.user != Client.shared.user
        let cell = tableView.dequeueMessageCell(for: indexPath, style: isIncoming ? style.incomingMessage : style.outgoingMessage)
        
        if message.isDeleted {
            cell.update(info: "This message was deleted.", date: message.deleted)
        } else {
            cell.update(message: message.text)
            
            if !message.mentionedUsers.isEmpty {
                cell.update(mentionedUsersNames: message.mentionedUsers.map({ $0.name }))
            }
        }
        
        var showAvatar = true
        
        if indexPath.row < (presenter.items.count - 1), case .message(let nextMessage) = presenter.items[indexPath.row + 1] {
            showAvatar = nextMessage.user != message.user
            
            if !showAvatar {
                cell.paddingType = .small
            }
        }
        
        var isContinueMessage = false
        
        if indexPath.row > 0,
            case .message(let prevMessage) = presenter.items[indexPath.row - 1],
            prevMessage.user == message.user,
            !prevMessage.text.messageContainsOnlyEmoji {
            isContinueMessage = true
        }
        
        cell.updateBackground(isContinueMessage: isContinueMessage)
        
        if showAvatar {
            cell.update(name: message.user.name, date: message.created)
            cell.avatarView.update(with: message.user.avatarURL, name: message.user.name)
        }
        
        addAttchaments(message: message, to: cell, at: indexPath)
        
        return cell
    }
    
    private func addAttchaments(message: Message, to cell: MessageTableViewCell, at indexPath: IndexPath) {
        guard !message.isDeleted, !message.attachments.isEmpty else {
            return
        }
        
        cell.add(attachments: message.attachments,
                 userName: message.user.name,
                 tap: { [weak self] in self?.show(attachment: $0, at: $1, from: $2) }) { [weak self] in
                    if let self = self {
                        self.tableView.update {
                            self.tableView.reloadRows(at: [indexPath], with: .none)
                        }
                    }
        }
    }
    
    private func show(attachment: Attachment, at index: Int, from attachments: [Attachment]) {
        if attachment.isImage {
            showMediaGallery(with: attachments.compactMap { MediaGalleryItem(title: $0.title, url: $0.imageURL) },
                             selectedIndex: index)
            return
        }
        
        showWebView(url: attachment.url, title: attachment.title)
    }
    
    private func userActivityCell(at indexPath: IndexPath, user: User, _ text: String) -> UITableViewCell {
        let cell = tableView.dequeueMessageCell(for: indexPath, style: style.incomingMessage)
        cell.update(info: text)
        cell.update(date: Date())
        cell.avatarView.update(with: user.avatarURL, name: user.name)
        return cell
    }
    
    private func statusCell(at indexPath: IndexPath, title: String, subtitle: String? = nil) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: StatusTableViewCell.self) as StatusTableViewCell
        cell.backgroundColor = style.backgroundColor
        cell.update(title: title, subtitle: subtitle)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? MessageTableViewCell {
            cell.free()
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

// MARK: - Footer

extension ChatViewController {
    private func updateFooterView(_ isUsersTyping: Bool, _ startWatchingUser: User?, _ stoptWatchingUser: User?) {
        if isUsersTyping {
            updateFooterForUsersTyping()
        }
        
        if let startWatchingUser = startWatchingUser {
            addStartWatchingUser(startWatchingUser)
        }
        
        updateFooterView()
    }
    
    private func updateFooterView() {
        guard let footerView = tableView.tableFooterView as? ChatTableFooterView else {
            return
        }
        
        if footerView.isEmpty {
            UIView.animateSmooth(withDuration: 0.3) { self.tableView.layoutFooterView() }
        } else {
            let needsToScroll = tableView.bottomContentOffset < .chatBottomThreshold
            tableView.layoutFooterView()
            
            if needsToScroll {
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
