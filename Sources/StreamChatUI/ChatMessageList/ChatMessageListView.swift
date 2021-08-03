//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Custom view type used to show the message list.
open class ChatMessageListView: UITableView, Customizable, ComponentsProvider {
    private var identifiers: Set<String> = .init()
    private var isInitialized: Bool = false
    /// Used for mapping `ListChanges` to sets of `IndexPath` and verifying possible conflicts
    private let collectionUpdatesMapper = CollectionUpdatesMapper()
    
    // In some cases updates coming one by one might require scrolling to bottom.
    //
    // Scheduling the action and canceling the previous one ensures the scroll to bottom
    // is done only once.
    //
    // Having a delay gives layout a chance to calculate the correct size for bottom cells
    // so they are fully visible when scroll to bottom happens.
    private var scrollToBottomAction: DispatchWorkItem? {
        didSet {
            oldValue?.cancel()
            if let action = scrollToBottomAction {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + .milliseconds(200),
                    execute: action
                )
            }
        }
    }

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
        estimatedRowHeight = 150
        separatorStyle = .none
        transform = .mirrorY
    }
    
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() { /* default empty implementation */ }
    open func updateContent() { /* default empty implementation */ }
    
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
            String(layoutOptions.rawValue),
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

        let cell = dequeueReusableCell(
            withIdentifier: reuseIdentifier,
            for: indexPath
        ) as! ChatMessageCell

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

        if
            rectForRow(at: prevMessageIndexPath).minY < contentOffset.y,
            rowsRange.contains(prevMessageIndexPath.row) {
            scrollToRow(at: prevMessageIndexPath, at: .top, animated: false)
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
        var shouldScrollToBottom = false
        
        guard let _ = collectionUpdatesMapper.mapToSetsOfIndexPaths(
            changes: changes,
            onConflict: {
                reloadData()
            }
        ) else { return }
                
        performBatchUpdates({
            changes.forEach {
                switch $0 {
                case let .insert(message, index: index):
                    if message.isSentByCurrentUser, index == IndexPath(item: 0, section: 0) {
                        // When the message from current user comes we should scroll to bottom
                        shouldScrollToBottom = true
                    }
                    if index.row < self.numberOfRows(inSection: 0) {
                        // Reload previous cell if exists
                        self.reloadRows(at: [index], with: .automatic)
                    }
                    self.insertRows(at: [index], with: .none)
                case let .move(_, fromIndex: fromIndex, toIndex: toIndex):
                    self.moveRow(at: fromIndex, to: toIndex)

                case let .update(_, index: index):
                    self.reloadRows(at: [index], with: .automatic)

                case let .remove(_, index: index):
                    let indexPathToReload = IndexPath(row: index.row + 1, section: index.section)
                    if self.numberOfRows(inSection: 0) > indexPathToReload.row {
                        // Reload previous cell if exists
                        self.reloadRows(at: [indexPathToReload], with: .automatic)
                    }
                    self.deleteRows(at: [index], with: .fade)
                }
            }
        }, completion: { _ in
            if shouldScrollToBottom {
                self.scrollToBottomAction = .init { [weak self] in
                    self?.scrollToMostRecentMessage()
                }
            }
            
            completion?()
        })
    }
    
    override open func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        let visibleCells = getVisibleCells()
        
        var indexPathToReload: [IndexPath] = []
        
        indexPaths.forEach { indexPath in
            // Get currently shown cell at index path
            let cellBeforeUpdate = visibleCells[indexPath]
            let cellBeforeUpdateReuseIdentifier = reuseIdentifier(for: cellBeforeUpdate)
            let cellBeforeUpdateMessage = cellBeforeUpdate?.messageContentView?.content
            
            // Get the cell that will be shown if reload happens
            let cellAfterUpdate = dataSource?.tableView(self, cellForRowAt: indexPath) as? ChatMessageCell
            let cellAfterUpdateReuseIdentifier = reuseIdentifier(for: cellAfterUpdate)
            let cellAfterUpdateMessage = cellAfterUpdate?.messageContentView?.content
            
            if
                cellBeforeUpdateReuseIdentifier == cellAfterUpdateReuseIdentifier,
                cellBeforeUpdateMessage?.id == cellAfterUpdateMessage?.id {
                // If identifiers and messages match we can simply update the current cell with new content
                cellBeforeUpdate?.messageContentView?.content = cellAfterUpdateMessage
            } else {
                // If identifiers does not match we do a reload to let the table view dequeue another cell
                // with the layout fitting the updated message.
                indexPathToReload.append(indexPath)
            }
        }
        
        if !indexPathToReload.isEmpty {
            super.reloadRows(at: indexPathToReload, with: animation)
        }
    }

    private func getVisibleCells() -> [IndexPath: ChatMessageCell] {
        visibleCells.reduce(into: [:]) { result, cell in
            guard
                let cell = cell as? ChatMessageCell,
                let indexPath = cell.messageContentView?.indexPath?()
            else { return }
            
            result[indexPath] = cell
        }
    }
}

private extension CGAffineTransform {
    static let mirrorY = Self(scaleX: 1, y: -1)
}
