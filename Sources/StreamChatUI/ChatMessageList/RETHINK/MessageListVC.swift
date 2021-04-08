//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

class MessageListVC<ExtraData: ExtraDataTypes>: _ViewController, UICollectionViewDelegate, UICollectionViewDataSource {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.embed(collectionView)
        collectionView.backgroundColor = .white
        
        collectionView.register(MessageCell<ExtraData>.self, forCellWithReuseIdentifier: MessageCell<ExtraData>.reuseId)
        
        channelController.synchronize()
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
}
