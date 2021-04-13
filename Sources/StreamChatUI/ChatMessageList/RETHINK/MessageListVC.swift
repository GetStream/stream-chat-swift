//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

class MessageListVC<ExtraData: ExtraDataTypes>: _ViewController, UICollectionViewDelegate, UICollectionViewDataSource,
    UIConfigProvider {
    var channelController: _ChatChannelController<ExtraData>!
    
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
    
    private var timer: Timer?
    
    private lazy var keyboardObserver = ChatMessageListKeyboardObserver(
        containerView: view,
        scrollView: collectionView,
        composerBottomConstraint: messageComposerBottomConstraint
    )

    public lazy var userSuggestionSearchController: _ChatUserSearchController<ExtraData> = {
        channelController.client.userSearchController()
    }()
    
    // Load from UIConfig
    public lazy var titleView = ChatMessageListTitleView<ExtraData>()
    
    public lazy var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

//    public lazy var router = uiConfig.navigation.messageListRouter.init(rootViewController: self)
    public lazy var router = MessageListRouter(rootViewController: self)
    
    override func setUp() {
        super.setUp()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        longPress.minimumPressDuration = 0.33
        collectionView.addGestureRecognizer(longPress)
        
        messageComposerViewController.delegate = .wrap(self)
        messageComposerViewController.controller = channelController
        messageComposerViewController.userSuggestionSearchController = userSuggestionSearchController

        userSuggestionSearchController.search(term: nil)
        
        channelController.setDelegate(self)
        channelController.synchronize()
        
        if channelController.channel?.isDirectMessageChannel == true {
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.updateNavigationTitle()
            }
        }
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

    override func setUpAppearance() {
        super.setUpAppearance()
        
        view.backgroundColor = .white
        
        collectionView.backgroundColor = .white
        
        navigationItem.titleView = titleView
    }
    
    private func updateNavigationTitle() {
        let title = channelController.channel
            .flatMap { uiConfig.channelList.channelNamer($0, channelController.client.currentUserId) }
        
        let subtitle: String? = {
            if channelController.channel?.isDirectMessageChannel == true {
                guard let member = channelController.channel?.lastActiveMembers.first else { return nil }
                
                if member.isOnline {
                    // ReallyNotATODO: Missing API GroupA.m1
                    // need to specify how long user have been online
                    return "Online"
                } else if let minutes = member.lastActiveAt
                    .flatMap({ DateComponentsFormatter.minutes.string(from: $0, to: Date()) }) {
                    return "Seen \(minutes) ago"
                } else {
                    return "Offline"
                }
            } else {
                return channelController.channel.map { "\($0.memberCount) members, \($0.watcherCount) online" }
            }
        }()
        
        titleView.title = title
        titleView.subtitle = subtitle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    func cellReuseIdentifier(for message: _ChatMessage<ExtraData>) -> String {
        MessageCell<ExtraData>.reuseId
    }
    
    func cellLayoutOptionsForMessage(at indexPath: IndexPath) -> ChatMessageLayoutOptions {
        uiConfig.messageList.layoutOptionsResolver(indexPath, AnyRandomAccessCollection(channelController.messages))
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        channelController.messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = channelController.messages[indexPath.item]
        
        let cell: MessageCell<ExtraData> = self.collectionView.dequeueReusableCell(
            withReuseIdentifier: cellReuseIdentifier(for: message),
            layoutOptions: cellLayoutOptionsForMessage(at: indexPath),
            for: indexPath
        )

        cell.messageContentView.delegate = .init(
            didTapOnErrorIndicator: { [weak self] in
                self?.handleTapOnErrorIndicator(forCellAt: indexPath)
            },
            didTapOnThread: { [weak self] in
                self?.handleTapOnThread(forCellAt: indexPath)
            },
            didTapOnAttachment: { [weak self] in
                self?.handleTapOnAttachment($0, forCellAt: indexPath)
            },
            didTapOnAttachmentAction: { [weak self] attachment, action in
                self?.handleTapOnAttachmentAction(action, for: attachment, forCellAt: indexPath)
            },
            didTapOnQuotedMessage: { [weak self] in
                self?.handleTapOnQuotedMessage($0, forCellAt: indexPath)
            }
        )
        cell.messageContentView.content = message
        
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

    @objc
    private func didLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: collectionView)

        guard
            gesture.state == .began,
            let ip = collectionView.indexPathForItem(at: location)
        else { return }
        
        didSelectMessageCell(at: ip)
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
    
    private func presentReactionsControllerAnimated(
        for cell: MessageCell<ExtraData>,
        with messageData: _ChatMessageGroupPart<ExtraData>,
        actionsController: _ChatMessageActionsVC<ExtraData>,
        reactionsController: _ChatMessageReactionsVC<ExtraData>?
    ) {
        // TODO: for PR: This should be doable via:
        // 1. options: [.autoreverse, .repeat] and
        // 2. `UIView.setAnimationRepeatCount(0)` inside the animation block...
        //
        // and then just set completion to the animation to transform this back. aka `cell.messageView.transform = .identity`
        // however, this doesn't work as after the animation is done, it clips back to the value set in animation block
        // and then on completion goes back to `.identity`... This is really strange, but I was fighting it for some time
        // and couldn't find proper solution...
        // Also there are some limitations to the current solution ->
        // According to my debug view hiearchy, the content inside `messageView.messageBubbleView` is not constrainted to the
        // bubble view itself, meaning right now if we want to scale the view of incoming message, we scale the avatarView
        // of the sender as well...
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                cell.messageContentView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            },
            completion: { _ in
                self.impactFeedbackGenerator.impactOccurred()

                UIView.animate(
                    withDuration: 0.1,
                    delay: 0,
                    options: [.curveEaseOut],
                    animations: {
                        cell.messageContentView.transform = .identity
                    }
                )
                
                self.router.showMessageActionsPopUp(
                    messageContentFrame: cell.messageContentView.superview!.convert(cell.messageContentView.frame, to: nil),
                    messageData: messageData,
                    messageActionsController: actionsController,
                    messageReactionsController: reactionsController
                )
            }
        )
    }

    private func didSelectMessageCell(at indexPath: IndexPath) {
        let message = channelController.messages[indexPath.item]
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? MessageCell<ExtraData> else { return }
        guard message.isInteractionEnabled else { return }
        
        let messageController = channelController.client.messageController(
            cid: channelController.cid!,
            messageId: message.id
        )

        let actionsController = _ChatMessageActionsVC<ExtraData>()
        actionsController.messageController = messageController
        actionsController.delegate = .init(delegate: self)

        var reactionsController: _ChatMessageReactionsVC<ExtraData>? {
            guard message.localState == nil else { return nil }

            let controller = _ChatMessageReactionsVC<ExtraData>()
            controller.messageController = messageController
            return controller
        }

        presentReactionsControllerAnimated(
            for: cell,
            // only `message` is used but I don't want to break current implementation
            with: _ChatMessageGroupPart(
                message: message,
                quotedMessage: nil,
                isFirstInGroup: true,
                isLastInGroup: true,
                didTapOnAttachment: nil,
                didTapOnAttachmentAction: nil
            ),
            actionsController: actionsController,
            reactionsController: reactionsController
        )
    }

    open func restartUploading(for attachment: ChatMessageDefaultAttachment) {
        guard let id = attachment.id else {
            assertionFailure("Uploading cannot be restarted for attachment without `id`")
            return
        }

        let messageController = channelController.client.messageController(cid: id.cid, messageId: id.messageId)
        messageController.restartFailedAttachmentUploading(with: id)
    }

    // MARK: Cell action handlers

    open func handleTapOnAttachment(_ attachment: ChatMessageAttachment, forCellAt indexPath: IndexPath) {
        guard let attachment = attachment as? ChatMessageDefaultAttachment else {
            return
        }

        guard attachment.localState != .uploadingFailed else {
            restartUploading(for: attachment)
            return
        }

        switch attachment.type {
        case .image, .file:
            router.showPreview(for: attachment)
        case .link:
            router.openLink(attachment)
        default:
            break
        }
    }

    open func handleTapOnAttachmentAction(
        _ action: AttachmentAction,
        for attachment: ChatMessageAttachment,
        forCellAt indexPath: IndexPath
    ) {
        // Can we have a helper on `ChannelController` returning a `messageController` for the provided message id?
        let messageController = channelController.client.messageController(
            cid: channelController.cid!,
            messageId: channelController.messages[indexPath.row].id
        )
        messageController.dispatchEphemeralMessageAction(action)
    }

    open func handleTapOnQuotedMessage(_ quotedMessage: _ChatMessage<ExtraData>, forCellAt indexPath: IndexPath) {
        didSelectMessageCell(at: indexPath)
    }

    open func handleTapOnErrorIndicator(forCellAt indexPath: IndexPath) {
        didSelectMessageCell(at: indexPath)
    }

    open func handleTapOnThread(forCellAt indexPath: IndexPath) {
        guard let channel = channelController.channel else { return }
        
        let controller = MessageThreadVC<ExtraData>()
        controller.channelController = channelController
        controller.messageController = channelController.client.messageController(
            cid: channel.cid,
            messageId: channelController.messages[indexPath.item].id
        )
        navigationController?.show(controller, sender: self)
    }
}

extension MessageListVC: _ChatMessageComposerViewControllerDelegate {
    public func messageComposerViewControllerDidSendMessage(_ vc: _ChatMessageComposerVC<ExtraData>) {
        setNeedsScrollToMostRecentMessage()
    }
}

extension MessageListVC: _ChatChannelControllerDelegate {
    public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        updateMessages(with: changes)
    }
    
    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {
        updateNavigationTitle()
    }
}

extension MessageListVC: _ChatMessageActionsVCDelegate {
    func chatMessageActionsVC(
        _ vc: _ChatMessageActionsVC<ExtraData>,
        message: _ChatMessage<ExtraData>,
        didTapOnActionItem actionItem: ChatMessageActionItem
    ) {
        dismiss(animated: true) { [weak self] in
            switch actionItem {
            case is EditActionItem:
                self?.messageComposerViewController.state = .edit(message)
            case is InlineReplyActionItem:
                self?.messageComposerViewController.state = .quote(message)
            default:
                return
            }
        }
    }

    open func chatMessageActionsVCDidFinish(_ vc: _ChatMessageActionsVC<ExtraData>) {
        dismiss(animated: true)
    }
}
