//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Custom view type used to show the message list.
open class ChatMessageListView: UITableView, Customizable, ComponentsProvider {
    private var identifiers: Set<String> = .init()
    private var isInitialized: Bool = false

    // MARK: - Difference Kit Snapshot Handling

    // The internal properties below is to handle the DifferenceKit API. Currently it is
    // internal because these should actually be handled in the `ChatMessageListVC` but
    // that would make this class obsolete especially the `updateMessages(changes:)` and
    // it would require a lot of breaking changes. So for now, the Diff logic will live here.

    /// When inserting messages at the bottom, if the user is scrolled up,
    /// we skip adding the message to the UI until the user scrolls back
    /// to the bottom. This is to avoid message list jumps.
    internal var skippedMessages: Set<MessageId> = [] {
        didSet {
            if skippedMessages.isEmpty {
                newMessagesSnapshot = _newMessagesSnapshotWithSkipped
            }
        }
    }

    /// The previous messages snapshot before the next update.
    internal var previousMessagesSnapshot: [ChatMessage] = [] {
        didSet {
            let isNotSkippedMessage: (ChatMessage) -> Bool = {
                !self.skippedMessages.contains($0.id)
            }
            previousMessagesSnapshot = previousMessagesSnapshot.filter(isNotSkippedMessage)
        }
    }

    /// The new messages snapshot reported by the channel or message controller.
    private var _newMessagesSnapshotWithSkipped: [ChatMessage] = []
    internal var newMessagesSnapshot: [ChatMessage] = [] {
        didSet {
            _newMessagesSnapshotWithSkipped = newMessagesSnapshot
            let isNotSkippedMessage: (ChatMessage) -> Bool = {
                !self.skippedMessages.contains($0.id)
            }
            newMessagesSnapshot = newMessagesSnapshot.filter(isNotSkippedMessage)
        }
    }

    /// This closure is to update the dataSource when DifferenceKit
    /// reports the data source should be updated.
    internal var onNewDataSource: (([ChatMessage]) -> Void)?

    // MARK: Lifecycle

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard !isInitialized, superview != nil else { return }

        isInitialized = true

        setUp()
        setUpLayout()
        setUpAppearance()
    }
    
    open func setUp() {
        keyboardDismissMode = .onDrag
        rowHeight = UITableView.automaticDimension
        separatorStyle = .none
        transform = .mirrorY
    }
    
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }

    // MARK: Public API
    
    /// Calculates the cell reuse identifier for the given options.
    /// - Parameters:
    ///   - contentViewClass: The type of message content view.
    ///   - attachmentViewInjectorType: The type of attachment injector.
    ///   - layoutOptions: The message content view layout options.
    /// - Returns: The cell reuse identifier.
    open func reuseIdentifier(
        contentViewClass: ChatMessageContentView.Type,
        attachmentViewInjectorType: AttachmentViewInjector.Type?,
        layoutOptions: ChatMessageLayoutOptions
    ) -> String {
        let components = [
            ChatMessageCell.reuseId,
            String(layoutOptions.id),
            String(describing: contentViewClass),
            String(describing: attachmentViewInjectorType)
        ]
        return components.joined(separator: "_")
    }
    
    /// Returns the reuse identifier of the given cell.
    /// - Parameter cell: The cell to calculate reuse identifier for.
    /// - Returns: The reuse identifier.
    open func reuseIdentifier(for cell: ChatMessageCell?) -> String? {
        guard
            let cell = cell,
            let messageContentView = cell.messageContentView,
            let layoutOptions = messageContentView.layoutOptions
        else { return nil }
        
        return reuseIdentifier(
            contentViewClass: type(of: messageContentView),
            attachmentViewInjectorType: messageContentView.attachmentViewInjector.map { type(of: $0) },
            layoutOptions: layoutOptions
        )
    }

    /// Dequeues the message cell. Registers the cell for received combination of `contentViewClass + layoutOptions`
    /// if needed.
    /// - Parameters:
    ///   - contentViewClass: The type of content view the cell will be displaying.
    ///   - layoutOptions: The option set describing content view layout.
    ///   - indexPath: The cell index path.
    /// - Returns: The instance of `ChatMessageCollectionViewCell` set up with the
    /// provided `contentViewClass` and `layoutOptions`
    open func dequeueReusableCell(
        contentViewClass: ChatMessageContentView.Type,
        attachmentViewInjectorType: AttachmentViewInjector.Type?,
        layoutOptions: ChatMessageLayoutOptions,
        for indexPath: IndexPath
    ) -> ChatMessageCell {
        let reuseIdentifier = self.reuseIdentifier(
            contentViewClass: contentViewClass,
            attachmentViewInjectorType: attachmentViewInjectorType,
            layoutOptions: layoutOptions
        )
        
        // There is no public API to find out
        // if the given `identifier` is registered.
        if !identifiers.contains(reuseIdentifier) {
            identifiers.insert(reuseIdentifier)

            register(ChatMessageCell.self, forCellReuseIdentifier: reuseIdentifier)
        }
        
        let cell = dequeueReusableCell(with: ChatMessageCell.self, for: indexPath, reuseIdentifier: reuseIdentifier)

        cell.setMessageContentIfNeeded(
            contentViewClass: contentViewClass,
            attachmentViewInjectorType: attachmentViewInjectorType,
            options: layoutOptions
        )
        
        cell.messageContentView?.indexPath = { [weak cell, weak self] in
            guard let cell = cell else { return nil }
            return self?.indexPath(for: cell)
        }
        
        cell.contentView.transform = .mirrorY

        return cell
    }
    
    /// Scrolls to most recent message
    open func scrollToMostRecentMessage(animated: Bool = true) {
        let rowsRange = 0..<numberOfRows(inSection: 0)
        let lastMessageIndexPath = IndexPath(row: 0, section: 0)
        let prevMessageIndexPath = IndexPath(row: 1, section: 0)

        if rectForRow(at: prevMessageIndexPath).minY < contentOffset.y,
           rowsRange.contains(prevMessageIndexPath.row) {
            scrollToRow(at: prevMessageIndexPath, at: .top, animated: animated)
        }
        
        if rowsRange.contains(lastMessageIndexPath.row) {
            scrollToRow(at: lastMessageIndexPath, at: .top, animated: animated)
        }
    }
    
    /// A Boolean that returns true if the bottom cell is fully visible.
    /// Which is also means that the collection view is fully scrolled to the boom.
    open var isLastCellFullyVisible: Bool {
        guard numberOfRows(inSection: 0) > 0 else { return false }
        
        let cellRect = rectForRow(at: .init(row: 0, section: 0))
        
        return cellRect.minY >= contentOffset.y
    }
    
    /// Updates the table view data with given `changes`.
    open func updateMessages(
        with changes: [ListChange<ChatMessage>],
        completion: (() -> Void)? = nil
    ) {
        let bottomChange = changes.first(where: { $0.indexPath.item == 0 })
        if !isLastCellFullyVisible && bottomChange?.isInsertion == true && bottomChange?.item.isSentByCurrentUser == false {
            changes.filter(\.isInsertion).forEach {
                skippedMessages.insert($0.item.id)
            }
            // Don't update UI if we are skipping the inserted messages
            return
        }

        UIView.performWithoutAnimation {
            reloadMessages(
                previousSnapshot: previousMessagesSnapshot,
                newSnapshot: newMessagesSnapshot,
                with: .fade,
                completion: { [weak self] in
                    let bottomChangeIsInsertionOrMove = bottomChange?.isInsertion == true || bottomChange?.isMove == true
                    if bottomChangeIsInsertionOrMove, let newMessage = bottomChange?.item {
                        // Scroll to the bottom if the new message was sent by
                        // the current user, or moved by the current user
                        if newMessage.isSentByCurrentUser {
                            self?.scrollToMostRecentMessage()
                        }

                        // When a Giphy moves to the bottom, we need to also trigger a reload
                        // Since a move doesn't trigger a reload of the cell.
                        if bottomChange?.isMove == true {
                            let movedIndexPath = IndexPath(item: 0, section: 0)
                            self?.reloadRows(at: [movedIndexPath], with: .none)
                        }
                    }
                    completion?()
                }
            )

            // If we are inserting messages at the bottom, update the previous cell
            // to hide the timestamp of the previous message if needed.
            if self.isLastCellFullyVisible {
                let previousMessageIndexPath = IndexPath(item: 1, section: 0)
                self.reloadRows(at: [previousMessageIndexPath], with: .none)
            }
        }
    }
}

// MARK: Helpers

private extension CGAffineTransform {
    static let mirrorY = Self(scaleX: 1, y: -1)
}
