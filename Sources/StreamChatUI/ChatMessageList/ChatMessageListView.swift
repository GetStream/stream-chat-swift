//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Custom view type used to show the message list.
open class ChatMessageListView: UITableView, Customizable, ComponentsProvider {
    private var identifiers: Set<String> = .init()
    private var isInitialized: Bool = false
    /// Used for mapping `ListChanges` to sets of `IndexPath` and verifying possible conflicts
    private let collectionUpdatesMapper = CollectionUpdatesMapper()

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
        if #available(iOS 13, *), components._messageListDiffingEnabled {
            estimatedRowHeight = UITableView.automaticDimension
        } else {
            estimatedRowHeight = 150
        }
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
        let lastMessageInserted = changes.first(where: { $0.isInsertion && $0.indexPath.row == 0 })?.item
        let scrollToBottomIfNeeded = {
            if lastMessageInserted?.isSentByCurrentUser == true {
                self.scrollToMostRecentMessage()
            }
        }

        guard let indices = collectionUpdatesMapper.mapToSetsOfIndexPaths(
            changes: changes
        ) else {
            reloadData()
            scrollToBottomIfNeeded()
            completion?()
            return
        }

        UIView.performWithoutAnimation {
            performBatchUpdates({
                deleteRows(at: Array(indices.remove), with: .none)
                insertRows(at: Array(indices.insert), with: .none)
                reloadRows(at: Array(indices.update), with: .none)
                indices.move.forEach {
                    moveRow(at: $0.fromIndex, to: $0.toIndex)
                }
            }, completion: { _ in
                // Move changes from NSFetchController also can mean an update of the content.
                // Since a `moveItem` in collections do not update the content of the cell, we need to reload those cells.
                let moveIndexes = Array(indices.move.map(\.toIndex))
                if !moveIndexes.isEmpty {
                    self.reloadRows(at: moveIndexes, with: .none)
                }

                scrollToBottomIfNeeded()
                completion?()
            })
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

private extension ListChange {
    var isInsertion: Bool {
        switch self {
        case .insert:
            return true
        default:
            return false
        }
    }

    var indexPath: IndexPath {
        switch self {
        case let .insert(_, index):
            return index
        case let .move(_, _, toIndex):
            return toIndex
        case let .update(_, index):
            return index
        case let .remove(_, index):
            return index
        }
    }
}
