//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol ChatMessageListVCDataSource: AnyObject {
    associatedtype ExtraData: ExtraDataTypes

    func numberOfMessagesInChatMessageListVC(_ vc: ChatMessageListVC<ExtraData>) -> Int
    func chatMessageListVC(_ vc: ChatMessageListVC<ExtraData>, messageAt index: Int) -> _ChatMessage<ExtraData>
    func loadMoreMessagesForChatMessageListVC(_ vc: ChatMessageListVC<ExtraData>)
    func chatMessageListVC(
        _ vc: ChatMessageListVC<ExtraData>,
        replyMessageFor message: _ChatMessage<ExtraData>,
        at index: Int
    ) -> _ChatMessage<ExtraData>?
    func chatMessageListVC(
        _ vc: ChatMessageListVC<ExtraData>,
        controllerFor message: _ChatMessage<ExtraData>
    ) -> _ChatMessageController<ExtraData>
}

public protocol ChatMessageListVCDelegate: AnyObject {
    associatedtype ExtraData: ExtraDataTypes

    func chatMessageListVC(_ vc: ChatMessageListVC<ExtraData>, didSelectMessageAt index: Int)
    func chatMessageListVC(_ vc: ChatMessageListVC<ExtraData>, didTapOnRepliesFor message: _ChatMessage<ExtraData>)
    func chatMessageListVC(_ vc: ChatMessageListVC<ExtraData>, didTapOn attachment: _ChatMessageAttachment<ExtraData>)
    func chatMessageListVC(_ vc: ChatMessageListVC<ExtraData>, didInlineRepliedTo message: _ChatMessage<ExtraData>)
}

open class ChatMessageListVC<ExtraData: ExtraDataTypes>: ViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIConfigProvider {
    public struct DataSource {
        public var numberOfMessages: (ChatMessageListVC) -> Int
        public var messageAtIndex: (ChatMessageListVC, Int) -> _ChatMessage<ExtraData>
        public var loadMoreMessages: (ChatMessageListVC) -> Void
        public var replyMessageForMessageAtIndex: (ChatMessageListVC, _ChatMessage<ExtraData>, Int) -> _ChatMessage<ExtraData>?
        public var controllerForMessage: (ChatMessageListVC, _ChatMessage<ExtraData>) -> _ChatMessageController<ExtraData>
    }

    public struct Delegate {
        public var didSelectMessageAtIndex: ((ChatMessageListVC, Int) -> Void)?
        public var didTapOnRepliesForMessage: ((ChatMessageListVC, _ChatMessage<ExtraData>) -> Void)?
        public var didTapOnAttachment: ((ChatMessageListVC, _ChatMessageAttachment<ExtraData>) -> Void)?
        public var didInlineRepliedTo: ((ChatMessageListVC, _ChatMessage<ExtraData>) -> Void)?
    }

    public var dataSource: DataSource = .empty()
    public var delegate: Delegate? // swiftlint:disable:this weak_delegate

    public private(set) lazy var router = uiConfig.navigation.messageListRouter.init(rootViewController: self)

    public private(set) lazy var collectionViewLayout: ChatChannelCollectionViewLayout = uiConfig
        .messageList
        .collectionLayout
        .init()
    public private(set) lazy var collectionView: UICollectionView = {
        let collection = uiConfig.messageList.collectionView.init(layout: collectionViewLayout)
        let incomingCell = uiConfig.messageList.incomingMessageCell
        let outgoingCell = uiConfig.messageList.outgoingMessageCell
        collection.register(incomingCell, forCellWithReuseIdentifier: incomingCell.reuseId)
        collection.register(outgoingCell, forCellWithReuseIdentifier: outgoingCell.reuseId)
        collection.showsHorizontalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self

        return collection
    }()

    // MARK: - Life Cycle

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if collectionView.contentOffset.y < collectionView.bounds.height {
            let bottom = collectionView.contentSize.height
            collectionView.scrollRectToVisible(CGRect(x: 0, y: bottom - 1, width: 1, height: 1), animated: false)
        }
    }

    override open func setUp() {
        super.setUp()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        collectionView.addGestureRecognizer(longPress)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(collectionView)
        collectionView.pin(to: view.safeAreaLayoutGuide)
    }

    override public func defaultAppearance() {
        super.defaultAppearance()

        view.backgroundColor = uiConfig.colorPalette.generalBackground
        collectionView.backgroundColor = .clear
    }

    // MARK: - Public API

    public func updateMessages(with changes: [ListChange<_ChatMessage<ExtraData>>], completion: ((Bool) -> Void)? = nil) {
        collectionView.performBatchUpdates({
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
        }, completion: completion)
    }

    // MARK: - Actions

    @objc func didLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: collectionView)

        guard gesture.state == .began else { return }
        guard let ip = collectionView.indexPathForItem(at: location) else { return }
        guard let cell = collectionView.cellForItem(at: ip) as? СhatMessageCollectionViewCell<ExtraData> else { return }
        guard let messageData = cell.message else { return }
        guard messageData.deletedAt == nil else { return }

        let messageController = dataSource.controllerForMessage(self, messageData.message)
        router.showMessageActionsPopUp(
            messageContentFrame: cell.messageView.superview!.convert(cell.messageView.frame, to: nil),
            messageData: messageData,
            messageController: messageController,
            messageActions: messageActions(messageController: messageController)
        )
    }

    // MARK: - UICollectionViewDataSource

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource.numberOfMessages(self)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let message = messageGroupPart(at: indexPath)

        let cell: СhatMessageCollectionViewCell<ExtraData>
        if message.isSentByCurrentUser {
            cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: uiConfig.messageList.outgoingMessageCell.reuseId,
                for: indexPath
            ) as! СhatMessageCollectionViewCell<ExtraData>
        } else {
            cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: uiConfig.messageList.incomingMessageCell.reuseId,
                for: indexPath
            ) as! СhatMessageCollectionViewCell<ExtraData>
        }

        cell.messageView.onThreadTap = { [weak self] in
            guard let self = self, let message = $0?.message else { return }
            self.delegate?.didTapOnRepliesForMessage?(self, message)
        }
        cell.message = message

        return cell
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectMessageAtIndex?(self, indexPath.row)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if indexPath.row + 1 >= collectionView.numberOfItems(inSection: 0) {
            dataSource.loadMoreMessages(self)
        }
    }

    // MARK: - Private

    private func messageGroupPart(at indexPath: IndexPath) -> _ChatMessageGroupPart<ExtraData> {
        let message = dataSource.messageAtIndex(self, indexPath.row)

        var isLastInGroup: Bool {
            guard indexPath.row > 0 else { return true }
            let nextMessage = dataSource.messageAtIndex(self, indexPath.row - 1)
            guard nextMessage.author == message.author else { return true }
            let delay = nextMessage.createdAt.timeIntervalSince(message.createdAt)
            return delay > uiConfig.messageList.minTimeInvteralBetweenMessagesInGroup
        }

        var parentMessageState: _ChatMessageGroupPart<ExtraData>.ParentMessageState?

        // TODO: Waiting for reply support in LLC CIS-505
//        if message.repliesTo != nil {
        if false {
            if let parentMessage = dataSource.replyMessageForMessageAtIndex(self, message, indexPath.row) {
                parentMessageState = .loaded(parentMessage)
            } else {
                parentMessageState = .loading
            }
        }

        return .init(
            message: message,
            parentMessageState: parentMessageState,
            isLastInGroup: isLastInGroup,
            didTapOnAttachment: { [weak self] attachment in
                guard let self = self else { return }
                self.delegate?.didTapOnAttachment?(self, attachment)
            }
        )
    }

    private func messageActions(messageController: _ChatMessageController<ExtraData>) -> [ChatMessageActionItem] {
        guard
            let message = messageController.message,
            let currentUser = messageController.client.currentUserController().currentUser
        else { return [] }

        var actions: [ChatMessageActionItem] = []

        actions.append(.inlineReply { [weak self] in
            self?.dismiss(animated: true)
            guard let self = self else { return }
            self.delegate?.didInlineRepliedTo?(self, message)
        })

        actions.append(.threadReply { [weak self] in
            debugPrint("thread reply")
            self?.dismiss(animated: true)
        })

        actions.append(.copy { [weak self] in
            UIPasteboard.general.string = message.text
            self?.dismiss(animated: true)
        })

        if message.isSentByCurrentUser {
            actions.append(.edit { [weak self] in
                debugPrint("edit")
                self?.dismiss(animated: true)
            })
            actions.append(.delete { [weak self] in
                self?.router.showMessageDeletionConfirmationAlert { confirmed in
                    guard confirmed else { return }

                    messageController.deleteMessage { [messageController] _ in
                        self?.dismiss(animated: true)
                        _ = messageController
                    }
                }
            })
        } else {
            if currentUser.mutedUsers.contains(message.author) {
                actions.append(.unmuteUser { [weak self] in
                    let userController = messageController.client.userController(userId: message.author.id)
                    userController.unmute { [userController] _ in
                        self?.dismiss(animated: true)
                        _ = userController
                    }
                })
            } else {
                actions.append(.muteUser { [weak self] in
                    let userController = messageController.client.userController(userId: message.author.id)
                    userController.mute { [userController] _ in
                        self?.dismiss(animated: true)
                        _ = userController
                    }
                })
            }
        }

        return actions
    }
}

public extension ChatMessageListVC.DataSource {
    static func wrap<T: ChatMessageListVCDataSource>(_ ds: T) -> ChatMessageListVC.DataSource where T.ExtraData == ExtraData {
        ChatMessageListVC.DataSource(
            numberOfMessages: { [unowned ds] in ds.numberOfMessagesInChatMessageListVC($0) },
            messageAtIndex: { [unowned ds] in ds.chatMessageListVC($0, messageAt: $1) },
            loadMoreMessages: { [unowned ds] in ds.loadMoreMessagesForChatMessageListVC($0) },
            replyMessageForMessageAtIndex: { [unowned ds] in ds.chatMessageListVC($0, replyMessageFor: $1, at: $2) },
            controllerForMessage: { [unowned ds] in ds.chatMessageListVC($0, controllerFor: $1) }
        )
    }

    static func empty() -> ChatMessageListVC.DataSource {
        ChatMessageListVC.DataSource(
            numberOfMessages: { _ in 0 },
            messageAtIndex: { _, _ in
                fatalError("Method shouldn't be called on empty data source")
            },
            loadMoreMessages: { _ in },
            replyMessageForMessageAtIndex: { _, _, _ in nil },
            controllerForMessage: { _, _ in
                fatalError("Method shouldn't be called on empty data source")
            }
        )
    }
}

public extension ChatMessageListVC.Delegate {
    static func wrap<T: ChatMessageListVCDelegate>(_ delegate: T) -> ChatMessageListVC.Delegate where T.ExtraData == ExtraData {
        ChatMessageListVC.Delegate(
            didSelectMessageAtIndex: { [weak delegate] in delegate?.chatMessageListVC($0, didSelectMessageAt: $1) },
            didTapOnRepliesForMessage: { [weak delegate] in delegate?.chatMessageListVC($0, didTapOnRepliesFor: $1) },
            didTapOnAttachment: { [weak delegate] in delegate?.chatMessageListVC($0, didTapOn: $1) },
            didInlineRepliedTo: { [weak delegate] in delegate?.chatMessageListVC($0, didInlineRepliedTo: $1) }
        )
    }
}
