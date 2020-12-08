//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelVC<ExtraData: UIExtraDataTypes>: ViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIConfigProvider {
    // MARK: - Properties
    
    public var controller: _ChatChannelController<ExtraData>!

    public private(set) lazy var messageInputAccessoryViewController: MessageComposerInputAccessoryViewController<ExtraData> = {
        .init()
    }()

    public private(set) lazy var collectionViewLayout: ChatChannelCollectionViewLayout = uiConfig
        .messageList
        .collectionLayout
        .init()
    public private(set) lazy var collectionView: UICollectionView = {
        let collection = uiConfig.messageList.collectionView.init(layout: collectionViewLayout)
        collection.register(
            СhatIncomingMessageCollectionViewCell<ExtraData>.self,
            forCellWithReuseIdentifier: СhatIncomingMessageCollectionViewCell<ExtraData>.reuseId
        )
        collection.register(
            СhatOutgoingMessageCollectionViewCell<ExtraData>.self,
            forCellWithReuseIdentifier: СhatOutgoingMessageCollectionViewCell<ExtraData>.reuseId
        )
        collection.showsHorizontalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        
        return collection
    }()

    private var navbarListener: ChatChannelNavigationBarListener<ExtraData>?

    public private(set) lazy var router = uiConfig.navigation.channelDetailRouter.init(rootViewController: self)
    
    // MARK: - Life Cycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        controller.setDelegate(self)
        controller.synchronize()
        navigationItem.largeTitleDisplayMode = .never

        installLongPress()
        messageInputAccessoryViewController.controller = controller
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

        let title = UILabel()
        title.textAlignment = .center
        title.font = .preferredFont(forTextStyle: .headline)

        let subtitle = UILabel()
        subtitle.textAlignment = .center
        subtitle.font = .preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = uiConfig.colorPalette.subtitleText

        let titleView = UIStackView(arrangedSubviews: [title, subtitle])
        titleView.axis = .vertical
        navigationItem.titleView = titleView

        guard let channel = controller.channel else { return }
        navbarListener = ChatChannelNavigationBarListener.make(for: channel.cid, in: controller.client)
        navbarListener?.onDataChange = { data in
            title.text = data.title
            subtitle.text = data.subtitle
        }

        let avatar = ChatChannelAvatarView<ExtraData>()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.heightAnchor.constraint(equalToConstant: 32).isActive = true
        avatar.channelAndUserId = (channel, controller.client.currentUserId)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: avatar)
        navigationItem.largeTitleDisplayMode = .never
    }

    func installLongPress() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        collectionView.addGestureRecognizer(longPress)
    }

    // MARK: - Actions

    @objc func didLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: collectionView)

        guard gesture.state == .began else { return }
        guard let ip = collectionView.indexPathForItem(at: location) else { return }
        guard let cell = collectionView.cellForItem(at: ip) as? СhatMessageCollectionViewCell<ExtraData> else { return }
        guard let cid = controller.cid, let messageData = cell.message else { return }

        let messageController = controller.client.messageController(
            cid: cid,
            messageId: messageData.message.id
        )

        router.showMessageActionsPopUp(
            messageContentFrame: cell.messageView.superview!.convert(cell.messageView.frame, to: nil),
            messageData: messageData,
            messageController: messageController,
            messageActions: messageActions(
                for: messageData,
                messageController: messageController
            )
        )
    }
    
    // MARK: - ChatChannelMessageComposerView
    
    override open var canBecomeFirstResponder: Bool { true }
    
    override open var inputAccessoryViewController: UIInputViewController? {
        messageInputAccessoryViewController
    }
    
    // MARK: - UICollectionViewDataSource
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        controller.messages.count
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let message = messageGroupPart(at: indexPath)

        let cell: СhatMessageCollectionViewCell<ExtraData>
        if message.isSentByCurrentUser {
            cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: СhatOutgoingMessageCollectionViewCell<ExtraData>.reuseId,
                for: indexPath
            ) as! СhatOutgoingMessageCollectionViewCell<ExtraData>
        } else {
            cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: СhatIncomingMessageCollectionViewCell<ExtraData>.reuseId,
                for: indexPath
            ) as! СhatIncomingMessageCollectionViewCell<ExtraData>
        }

        cell.message = message

        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedMessage = controller.messages[indexPath.row]
        debugPrint(selectedMessage)
    }
    
    // MARK: - UIScrollViewDelegate

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let realOffset = collectionView.contentOffset.y - collectionViewLayout.zeroOffset.y
        if realOffset < uiConfig.messageList.offsetToPreloadMoreMessages {
            controller.loadNextMessages()
        }
    }
    
    // MARK: - Private

    private func messageGroupPart(at indexPath: IndexPath) -> _ChatMessageGroupPart<ExtraData> {
        let message = controller.messages[indexPath.row]
        
        var isLastInGroup: Bool {
            guard
                // next message exists
                let nextMessage = controller.messages[safe: indexPath.row - 1],
                // next message author is the same as for current
                nextMessage.author == message.author
            else { return true }
            
            let delay = nextMessage.createdAt.timeIntervalSince(message.createdAt)
            
            return delay > uiConfig.messageList.minTimeInvteralBetweenMessagesInGroup
        }
        
        var parentMessageState: _ChatMessageGroupPart<ExtraData>.ParentMessageState?
        
        if let parentMessageId = message.parentMessageId {
            let messageController = controller.client.messageController(
                cid: controller.cid!,
                messageId: parentMessageId
            )
            
            if let parentMessage = messageController.message {
                parentMessageState = .loaded(parentMessage)
            } else {
                parentMessageState = .loading
                messageController.synchronize { [weak self, messageController] _ in
                    guard let self = self, let parentMessage = messageController.message else { return }
                    self.channelController(self.controller, didUpdateMessages: [.update(parentMessage, index: indexPath)])
                }
            }
        }
        
        return .init(
            message: message,
            parentMessageState: parentMessageState,
            isLastInGroup: isLastInGroup,
            didTapOnAttachment: { attachment in
                debugPrint(attachment)
            }
        )
    }

    private func messageActions(
        for message: _ChatMessageGroupPart<ExtraData>,
        messageController: _ChatMessageController<ExtraData>
    ) -> [ChatMessageActionItem] {
        guard
            let message = messageController.message,
            let currentUser = messageController.client.currentUserController().currentUser
        else { return [] }

        var actions: [ChatMessageActionItem] = []

        actions.append(.inlineReply { [weak self] in
            debugPrint("inline reply")
            self?.dismiss(animated: true)
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

// MARK: - _ChatChannelControllerDelegate

extension ChatChannelVC: _ChatChannelControllerDelegate {
    public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
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
        }, completion: nil)
    }
}
