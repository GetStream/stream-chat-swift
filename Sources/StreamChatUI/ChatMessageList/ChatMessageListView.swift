//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Custom view type used to show the message list.
public typealias ChatMessageListView = _ChatMessageListView<NoExtraData>

/// Custom view type used to show the message list.
open class _ChatMessageListView<ExtraData: ExtraDataTypes>: UITableView, Customizable, ComponentsProvider {
    private var identifiers: Set<String> = .init()
    private var isInitialized: Bool = false
    
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

    /// Dequeues the message cell. Registers the cell for received combination of `contentViewClass + layoutOptions`
    /// if needed.
    /// - Parameters:
    ///   - contentViewClass: The type of content view the cell will be displaying.
    ///   - layoutOptions: The option set describing content view layout.
    ///   - indexPath: The cell index path.
    /// - Returns: The instance of `_ChatMessageCollectionViewCell<ExtraData>` set up with the
    /// provided `contentViewClass` and `layoutOptions`
    open func dequeueReusableCell(
        contentViewClass: _ChatMessageContentView<ExtraData>.Type,
        attachmentViewInjectorType: _AttachmentViewInjector<ExtraData>.Type?,
        layoutOptions: ChatMessageLayoutOptions,
        for indexPath: IndexPath
    ) -> _ChatMessageCell<ExtraData> {
        let reuseIdentifier =
            "\(_ChatMessageCell<ExtraData>.reuseId)_" + "\(layoutOptions.rawValue)_" +
            "\(contentViewClass)_" + String(describing: attachmentViewInjectorType)

        // There is no public API to find out
        // if the given `identifier` is registered.
        if !identifiers.contains(reuseIdentifier) {
            identifiers.insert(reuseIdentifier)

            register(_ChatMessageCell<ExtraData>.self, forCellReuseIdentifier: reuseIdentifier)
        }

        let cell = dequeueReusableCell(
            withIdentifier: reuseIdentifier,
            for: indexPath
        ) as! _ChatMessageCell<ExtraData>

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
        let lastMessageIndexPath = IndexPath(row: 0, section: 0)
        let prevMessageIndexPath = IndexPath(row: 1, section: 0)

        if rectForRow(at: prevMessageIndexPath).minY < contentOffset.y {
            scrollToRow(at: prevMessageIndexPath, at: .top, animated: false)
        }
        
        scrollToRow(at: lastMessageIndexPath, at: .top, animated: animated)
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
        with changes: [ListChange<_ChatMessage<ExtraData>>],
        completion: (() -> Void)? = nil
    ) {
        var shouldScrollToBottom = false
                
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
}

private extension CGAffineTransform {
    static let mirrorY = Self(scaleX: 1, y: -1)
}
