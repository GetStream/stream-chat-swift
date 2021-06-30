//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A protocol for `ChatMessageListView` delegate.
public protocol ChatMessageListViewDataSource: UITableViewDataSource {
    /// Get date for item at given index path
    /// - Parameters:
    ///   - listView: A view requesting date
    ///   - indexPath: An index path that should be used to get the date
    func messageListView(_ listView: UITableView, scrollOverlayTextForItemAt indexPath: IndexPath) -> String?
}

/// Custom view type used to show the message list.
public typealias ChatMessageListView = _ChatMessageListView<NoExtraData>

/// Custom view type used to show the message list.
open class _ChatMessageListView<ExtraData: ExtraDataTypes>: UITableView, Customizable, ComponentsProvider {
    private var identifiers: Set<String> = .init()
    private var isInitialized: Bool = false
    private var contentOffsetObservation: NSKeyValueObservation?
    
    private var chatDataSource: ChatMessageListViewDataSource? {
        dataSource as? ChatMessageListViewDataSource
    }
    
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
    
    /// View used to display date of currently displayed messages
    open lazy var scrollOverlayView: ChatMessageListScrollOverlayView = {
        let scrollOverlayView = components.messageListScrollOverlayView.init()
        scrollOverlayView.isHidden = true
        return scrollOverlayView.withoutAutoresizingMaskConstraints
    }()

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
        scrollOverlayView.transform = .mirrorY
            
        // Setup `contentOffset` observation so `delegate` is free for anyone that wants to use it
        contentOffsetObservation = observe(\.contentOffset) { tb, _ in
            /// To display correct date we use bottom edge of `dateView` (we use `cv.layoutMargins.top` for both vertical offsets of `dateView`
            let dateViewRefPoint = CGPoint(
                x: tb.scrollOverlayView.center.x,
                y: tb.scrollOverlayView.frame.minY
            )
            
            // If we cannot find any indexPath for `cell` we try to use max visible indexPath (we have bottom to top) layout
            guard let indexPath = tb.indexPathForRow(at: dateViewRefPoint) ?? tb.indexPathsForVisibleRows?.max() else { return }
            
            let overlayText = tb.chatDataSource?.messageListView(tb, scrollOverlayTextForItemAt: indexPath)
            
            // As cells can overlay our `dateView` we need to keep it above them
            tb.bringSubviewToFront(tb.scrollOverlayView)
            
            // If we have no date we have no reason to display `dateView`
            tb.scrollOverlayView.isHidden = (overlayText ?? "").isEmpty
            tb.scrollOverlayView.content = overlayText
            
            // Apple's naming is quite weird as actually this property should rather be named `isScrolling`
            // as it stays true when user stops dragging and scrollView is decelerating and becomes false
            // when scrollView stops decelerating
            //
            // But this case doesn't cover situation when user drags scrollView to a certain `contentOffset`
            // leaves the finger there for a while and then just lifts it, it doesn't change `contentOffset`
            // so this handler is not called, this is handled by `scrollStateChanged`
            // that reacts on `panGestureRecognizer` states and can handle this case properly
            if !tb.isDragging {
                tb.setOverlayViewAlpha(0)
            }
        }
        
        panGestureRecognizer.addTarget(self, action: #selector(scrollStateChanged))
    }
    
    open func setUpAppearance() { /* default empty implementation */ }
    open func setUpLayout() {
        addSubview(scrollOverlayView)
        scrollOverlayView.pin(anchors: [.bottom, .centerX], to: layoutMarginsGuide)
    }
    
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
    
    /// Is invoked when a pan gesture state is changed.
    @objc
    open func scrollStateChanged(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            setOverlayViewAlpha(1)
        case .ended, .cancelled, .failed:
            // This case handles situation when user pans to certain `contentOffset`, leaves the finger there
            // and then lifts it without `contentOffset` change, so `scrollView` will not decelerate, if it does,
            // it is handled by `contentOffset` observation
            if !isDecelerating {
                setOverlayViewAlpha(0)
            }
        default: break
        }
    }
    
    /// Updates the alpha of the overlay.
    open func setOverlayViewAlpha(_ alpha: CGFloat, animated: Bool = true) {
        Animate(isAnimated: animated) { [scrollOverlayView] in
            scrollOverlayView.alpha = alpha
        }
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
