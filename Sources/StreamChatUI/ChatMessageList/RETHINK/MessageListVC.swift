//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

class MessageListVC<ExtraData: ExtraDataTypes>: _ViewController, UICollectionViewDelegate, UICollectionViewDataSource,
    UIConfigProvider, _ChatMessageComposerViewControllerDelegate {
    var channelController: _ChatChannelController<ExtraData>!

    var minTimeIntervalBetweenMessagesInGroup: TimeInterval = 10
    
    /// Consider to call `setNeedsScrollToMostRecentMessage(animated:)` instead
    public private(set) var needsToScrollToMostRecentMessage = true
    /// Consider to call `setNeedsScrollToMostRecentMessage(animated:)` instead
    public private(set) var needsToScrollToMostRecentMessageAnimated = false
    
    public private(set) lazy var collectionView: MessageCollectionView = {
        let collection = MessageCollectionView(frame: .zero, collectionViewLayout: ChatMessageListCollectionViewLayout())

        collection.isPrefetchingEnabled = false
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceVertical = true
        collection.keyboardDismissMode = .onDrag
        collection.dataSource = self
        collection.delegate = self

        return collection.withoutAutoresizingMaskConstraints
    }()
    
    public private(set) lazy var messageComposerViewController = uiConfig
        .messageComposer
        .messageComposerViewController
        .init()
    
    private var messageComposerBottomConstraint: NSLayoutConstraint?
    
    private var navbarListener: ChatChannelNavigationBarListener<ExtraData>?
    
    private lazy var keyboardObserver = ChatMessageListKeyboardObserver(
        containerView: view,
        scrollView: collectionView,
        composerBottomConstraint: messageComposerBottomConstraint
    )

    public lazy var userSuggestionSearchController: _ChatUserSearchController<ExtraData> = {
        channelController.client.userSearchController()
    }()
    
    override func setUp() {
        super.setUp()
        
        messageComposerViewController.delegate = .wrap(self)
        messageComposerViewController.controller = channelController
        messageComposerViewController.userSuggestionSearchController = userSuggestionSearchController

        userSuggestionSearchController.search(term: nil)
        
        channelController.setDelegate(self)
        channelController.synchronize()
    }
    
    override func setUpLayout() {
        super.setUpLayout()
        
        view.addSubview(collectionView)
        collectionView.pin(anchors: [.top, .leading, .trailing], to: view.safeAreaLayoutGuide)
        
        messageComposerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageComposerViewController, targetView: view)

        messageComposerViewController.view.topAnchor.pin(equalTo: collectionView.bottomAnchor).isActive = true
        messageComposerViewController.view.leadingAnchor.pin(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        messageComposerViewController.view.trailingAnchor.pin(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        messageComposerBottomConstraint = messageComposerViewController.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true
    }
    
    override func defaultAppearance() {
        super.defaultAppearance()
        
        view.backgroundColor = .white
        
        collectionView.backgroundColor = .white
        
        // Load from UIConfig
        let titleView = ChatMessageListTitleView<ExtraData>()

        navigationItem.titleView = titleView
        
        guard let channel = channelController.channel else { return }
        let navbarListener = ChatChannelNavigationBarListener.make(
            for: channel.cid,
            in: channelController.client,
            using: uiConfig.channelList.channelNamer
        )
        navbarListener.onDataChange = { data in
            titleView.title = data.title
            titleView.subtitle = data.subtitle
        }
        self.navbarListener = navbarListener
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        channelController.synchronize()
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        keyboardObserver.register()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        resignFirstResponder()
        
        keyboardObserver.unregister()
    }

    func isMessageLastInGroup(at indexPath: IndexPath) -> Bool {
        let message = channelController.messages[indexPath.row]

        guard indexPath.row > 0 else { return true }

        let nextMessage = channelController.messages[indexPath.row - 1]

        guard nextMessage.author == message.author else { return true }

        let delay = nextMessage.createdAt.timeIntervalSince(message.createdAt)

        return delay > minTimeIntervalBetweenMessagesInGroup
    }
    
    func cellLayoutOptionsForMessage(at indexPath: IndexPath) -> ChatMessageLayoutOptions {
        let message = channelController.messages[indexPath.row]
        let isLastInGroup = isMessageLastInGroup(at: indexPath)

        var options: ChatMessageLayoutOptions = []

        if message.isSentByCurrentUser {
            options.insert(.flipped)
        }
        if !isLastInGroup {
            options.insert(.continuousBubble)
        }
        if isLastInGroup {
            options.insert(.metadata)
        }
        if !message.textContent.isEmpty {
            options.insert(.text)
        }

        guard message.deletedAt == nil else {
            return options
        }

        if isLastInGroup && !message.isSentByCurrentUser {
            options.insert(.avatar)
        }

        for attachment in message.attachments {
            switch attachment.type {
            case .image:
                options.insert(.photoPreview)
            case .giphy:
                options.insert(.giphy)
            case .file:
                options.insert(.attachment)
            case .link:
                options.insert(.linkPreview)
            default:
                break
            }
        }

        return options
    }
    
    func cellReuseIdentifier(for message: _ChatMessage<ExtraData>) -> String {
        MessageCell<ExtraData>.reuseId
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        channelController.messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = channelController.messages[indexPath.item]
        
        let reuseId = cellReuseIdentifier(for: message)
        let layoutOptions = cellLayoutOptionsForMessage(at: indexPath)
        
        let cell: MessageCell<ExtraData> = self.collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseId,
            layoutOptions: layoutOptions,
            for: indexPath
        )
        
        cell.content = message
        
        return cell
    }
    
    /// Will scroll to most recent message on next `updateMessages` call
    public func setNeedsScrollToMostRecentMessage(animated: Bool = true) {
        needsToScrollToMostRecentMessage = true
        needsToScrollToMostRecentMessageAnimated = animated
    }

    /// Force scroll to most recent message check without waiting for `updateMessages`
    public func scrollToMostRecentMessageIfNeeded() {
        guard needsToScrollToMostRecentMessage else { return }
        
        scrollToMostRecentMessage(animated: needsToScrollToMostRecentMessageAnimated)
    }

    public func scrollToMostRecentMessage(animated: Bool = true) {
        needsToScrollToMostRecentMessage = false

        // our collection is flipped, so (0; 0) item is most recent one
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .bottom, animated: animated)
    }

    public func updateMessages(with changes: [ListChange<_ChatMessage<ExtraData>>], completion: ((Bool) -> Void)? = nil) {
        collectionView.performBatchUpdates {
            for change in changes {
                switch change {
                case let .insert(_, index):
                    collectionView.insertItems(at: [index])
                case let .move(_, fromIndex, toIndex):
                    collectionView.moveItem(at: fromIndex, to: toIndex)
                case let .remove(_, index):
                    collectionView.deleteItems(at: [index])
                case let .update(_, index):
                    collectionView.reloadItems(at: [index])
                }
            }
        } completion: { flag in
            completion?(flag)
            self.scrollToMostRecentMessageIfNeeded()
        }
    }
    
    // MARK: - MessageComposerViewControllerDelegate

    public func messageComposerViewControllerDidSendMessage(_ vc: _ChatMessageComposerVC<ExtraData>) {
        setNeedsScrollToMostRecentMessage()
    }
}

// MARK: - _ChatChannelControllerDelegate

extension MessageListVC: _ChatChannelControllerDelegate {
    public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        updateMessages(with: changes)
    }
}
