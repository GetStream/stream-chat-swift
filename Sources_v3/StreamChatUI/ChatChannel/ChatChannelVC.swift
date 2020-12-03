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
        
    public private(set) lazy var collectionView: UICollectionView = {
        let layout = uiConfig.messageList.collectionLayout.init()
        layout.delegate = self
        let collection = uiConfig.messageList.collectionView.init(layout: layout)
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

    let cellSizer = СhatMessageCollectionViewCellLayoutManager<ExtraData>()

    private var navbarListener: ChatChannelNavigationBarListener<ExtraData>?
    private var activePopup: ChatMessagePopupViewController<ExtraData>?
    
    // MARK: - Life Cycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        controller.setDelegate(self)
        controller.synchronize()
        navigationItem.largeTitleDisplayMode = .never

        installLongPress()
        setupMessageComposer()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let rect = CGRect(x: 0, y: collectionView.contentSize.height - 1, width: 1, height: 1)
        collectionView.scrollRectToVisible(rect, animated: false)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(collectionView)
        collectionView.pin(to: view.safeAreaLayoutGuide)
    }

    override public func defaultAppearance() {
        super.defaultAppearance()

        view.backgroundColor = .chatBackground
        collectionView.backgroundColor = .clear

        let title = UILabel()
        title.textAlignment = .center
        title.font = .preferredFont(forTextStyle: .headline)

        let subtitle = UILabel()
        subtitle.textAlignment = .center
        subtitle.font = .preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = .lightGray

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
    
    func setupMessageComposer() {
        composerView.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        composerView.imagePicker.delegate = self
    }

    // MARK: - Actions

    @objc func didLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let location = gesture.location(in: collectionView)
        guard let ip = collectionView.indexPathForItem(at: location) else { return }
        guard let cell = collectionView.cellForItem(at: ip) as? СhatMessageCollectionViewCell<ExtraData> else { return }
        guard let cid = controller.cid else { return }

        activePopup = ChatMessagePopupViewController(
            cell.messageView,
            for: controller.messages[ip.row],
            in: cid,
            with: controller.client
        ) { [weak self] in
            self?.activePopup = nil
        }
    }
    
    @objc func sendMessage(_ sender: Any) {
        guard let text = composerView.messageInputView.textView.text else {
            return
        }
        
        controller?.createNewMessage(text: text)
        
        composerView.messageInputView.textView.text = ""
    }
    
    // MARK: - ChatChannelMessageComposerView
    
    override open var canBecomeFirstResponder: Bool { true }
    
    var composerView = ChatChannelMessageComposerView<DefaultUIExtraData>(uiConfig: .default)

    override open var inputAccessoryView: UIView? {
        guard presentedViewController?.isBeingDismissed != false else {
            return nil
        }
        
        composerView.translatesAutoresizingMaskIntoConstraints = false
        composerView.layoutMargins = view.layoutMargins
        composerView.directionalLayoutMargins = systemMinimumLayoutMargins
        
        composerView.owningVC = self
        composerView.suggestionsViewController.owningViewController = self
        
        composerView.messageInputView.textViewDidChange = { [weak self] text in
            self?.controller.sendKeystrokeEvent()
            if text?.first == "\\" || text?.first == "@" {
                self?.composerView.suggestionsViewController.show()
            } else {
                self?.composerView.suggestionsViewController.dismiss()
            }
        }
        
        composerView.messageInputView.textViewDidEndEditing = { [weak self] _ in
            self?.controller.sendStopTypingEvent()
        }
        
        return composerView
    }
    
    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        
        composerView.attachmentsView.insertNewItem(with: selectedImage)
        picker.dismiss(animated: true) {
            self.composerView.attachmentsView.isHidden = false
        }
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

        cell.layout = cellSizer.layoutForCell(with: message, limitedBy: collectionView.bounds.width)
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
        guard scrollView.contentOffset.y <= 0 else { return }
        
        controller.loadNextMessages()
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
            isLastInGroup: isLastInGroup
        )
    }
}

// MARK: - ChatChannelCollectionViewLayoutDelegate

extension ChatChannelVC: ChatChannelCollectionViewLayoutDelegate {
    public func createLayoutModel() -> ChatChannelCollectionViewLayoutModel {
        let width = collectionView.bounds.width
        let data = (0..<controller.messages.count)
            .map { messageGroupPart(at: IndexPath(item: $0, section: 0)) }
            .map { (
                height: cellSizer.heightForCell(with: $0, limitedBy: width),
                bottomMargin: $0.isLastInGroup ? CGFloat(8) : CGFloat(2)
            ) }
        return ChatChannelCollectionViewLayoutModel(forWidth: width, itemsData: data)
    }
}

// MARK: - _ChatChannelControllerDelegate

extension ChatChannelVC: _ChatChannelControllerDelegate {
    public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        // in ideal world, we would recalculate layoutModel for new data right here
        // and set layoutModel inside batchUpdates. But right now let's roll with what we got
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
