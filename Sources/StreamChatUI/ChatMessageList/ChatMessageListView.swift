//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import ChatLayout
import StreamChat
import UIKit

/// Custom view type used to show the message list.
open class ChatMessageListView: UITableView, Customizable, ComponentsProvider {
    private var identifiers: Set<String> = .init()
    private var isInitialized: Bool = false
    /// Component responsible to process an array of `[ListChange<Item>]`'s and apply those changes to a view.
    private lazy var listChangeUpdater: ListChangeUpdater = TableViewListChangeUpdater(
        tableView: self
    )

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
        listChangeUpdater.performUpdate(with: changes) { _ in
            completion?()
        }
    }
}

private extension CGAffineTransform {
    static let mirrorY = Self(scaleX: 1, y: -1)
}

public class ChatMessageListCollectionView: UICollectionView, Customizable, ComponentsProvider, ChatLayoutDelegate {
    private var identifiers: Set<String> = .init()
    private var isInitialized: Bool = false
    /// Component responsible to process an array of `[ListChange<Item>]`'s and apply those changes to a view.
    private lazy var collectionChangeUpdater: ListChangeUpdater = CollectionViewListChangeUpdater(
        collectionView: self
    )

    private var flowLayout: CollectionViewChatLayout!
    private var animator: ManualAnimator?

    convenience init() {
        let flowLayout = CollectionViewChatLayout()
        flowLayout.keepContentOffsetAtBottomOnBatchUpdates = true
        self.init(frame: .zero, collectionViewLayout: flowLayout)
        self.flowLayout = flowLayout
        self.flowLayout.delegate = self
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
        alwaysBounceVertical = true
        contentInsetAdjustmentBehavior = .always
        if #available(iOS 13.0, *) {
            automaticallyAdjustsScrollIndicatorInsets = true
        }

        /// https://openradar.appspot.com/40926834
        isPrefetchingEnabled = false

        showsHorizontalScrollIndicator = false
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
            ChatMessageCollectionCell.reuseId,
            String(layoutOptions.id),
            String(describing: contentViewClass),
            String(describing: attachmentViewInjectorType)
        ]
        return components.joined(separator: "_")
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
    ) -> ChatMessageCollectionCell {
        let reuseIdentifier = self.reuseIdentifier(
            contentViewClass: contentViewClass,
            attachmentViewInjectorType: attachmentViewInjectorType,
            layoutOptions: layoutOptions
        )

        // There is no public API to find out
        // if the given `identifier` is registered.
        if !identifiers.contains(reuseIdentifier) {
            identifiers.insert(reuseIdentifier)

            register(ChatMessageCollectionCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        }

        let cell = dequeueReusableCell(with: ChatMessageCollectionCell.self, for: indexPath, reuseIdentifier: reuseIdentifier)

        cell.setMessageContentIfNeeded(
            contentViewClass: contentViewClass,
            attachmentViewInjectorType: attachmentViewInjectorType,
            options: layoutOptions
        )

        cell.messageContentView?.indexPath = { [weak cell, weak self] in
            guard let cell = cell else { return nil }
            return self?.indexPath(for: cell)
        }

        return cell
    }

    /// Scrolls to most recent message
    open func scrollToMostRecentMessage(animated: Bool = true) {
        let numberOfItems = numberOfItems(inSection: 0)
        let rowsRange = 0..<numberOfItems
        let lastMessageIndexPath = IndexPath(row: numberOfItems - 1, section: 0)
        let prevMessageIndexPath = IndexPath(row: numberOfItems - 2, section: 0)

        if let prevMessageCellFrame = cellForItem(at: prevMessageIndexPath)?.frame,
           prevMessageCellFrame.minY < contentOffset.y,
           rowsRange.contains(prevMessageIndexPath.row) {
            scrollToItem(at: prevMessageIndexPath, at: .top, animated: animated)
        }

        if rowsRange.contains(lastMessageIndexPath.row) {
            scrollToItem(at: lastMessageIndexPath, at: .top, animated: animated)
        }
    }

    /// A Boolean that returns true if the bottom cell is fully visible.
    /// Which is also means that the collection view is fully scrolled to the boom.
    open var isLastCellFullyVisible: Bool {
        let numberOfItems = numberOfItems(inSection: 0)
        guard numberOfItems > 0 else { return false }

        guard let cellRect = cellForItem(at: .init(row: numberOfItems - 1, section: 0))?.frame else {
            return false
        }

        return cellRect.minY >= contentOffset.y
    }

    /// Updates the table view data with given `changes`.
    open func updateMessages(
        with changes: [ListChange<ChatMessage>],
        completion: (() -> Void)? = nil
    ) {
        collectionChangeUpdater.performUpdate(with: changes) { _ in
            completion?()
        }
    }

    func scrollToBottom(completion: (() -> Void)? = nil) {
        // I ask content size from the layout because on IOs 12 collection view contains not updated one
        let contentOffsetAtBottom = CGPoint(
            x: contentOffset.x,
            y: flowLayout.collectionViewContentSize.height - frame.height + adjustedContentInset.bottom
        )

        guard contentOffsetAtBottom.y > contentOffset.y else {
            completion?()
            return
        }

        let initialOffset = contentOffset.y
        let delta = contentOffsetAtBottom.y - initialOffset
        if abs(delta) > flowLayout.visibleBounds.height {
            // See: https://dasdom.dev/posts/scrolling-a-collection-view-with-custom-duration/
            animator = ManualAnimator()
            animator?.animate(duration: TimeInterval(0.25), curve: .easeInOut) { [weak self] percentage in
                guard let self = self else {
                    return
                }
                self.contentOffset = CGPoint(x: self.contentOffset.x, y: initialOffset + (delta * percentage))
                if percentage == 1.0 {
                    self.animator = nil
                    let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: 0), kind: .footer, edge: .bottom)
                    self.flowLayout.restoreContentOffset(with: positionSnapshot)
                    completion?()
                }
            }
        } else {
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                self?.setContentOffset(contentOffsetAtBottom, animated: true)
            }, completion: { _ in
                completion?()
            })
        }
    }
}

// Read why this class is needed here:
// https://dasdom.dev/posts/scrolling-a-collection-view-with-custom-duration/
class ManualAnimator {
    enum AnimationCurve {
        case linear, parametric, easeInOut, easeIn, easeOut

        func modify(_ x: CGFloat) -> CGFloat {
            switch self {
            case .linear:
                return x
            case .parametric:
                return x.parametric
            case .easeInOut:
                return x.quadraticEaseInOut
            case .easeIn:
                return x.quadraticEaseIn
            case .easeOut:
                return x.quadraticEaseOut
            }
        }
    }

    private var displayLink: CADisplayLink?
    private var start = Date()
    private var total = TimeInterval(0)
    private var closure: ((CGFloat) -> Void)?
    private var animationCurve: AnimationCurve = .linear

    func animate(duration: TimeInterval, curve: AnimationCurve = .linear, _ animations: @escaping (CGFloat) -> Void) {
        guard duration > 0 else {
            animations(1.0); return
        }
        reset()
        start = Date()
        closure = animations
        total = duration
        animationCurve = curve
        let d = CADisplayLink(target: self, selector: #selector(tick))
        d.add(to: .current, forMode: .common)
        displayLink = d
    }

    @objc private func tick() {
        let delta = Date().timeIntervalSince(start)
        var percentage = animationCurve.modify(CGFloat(delta) / CGFloat(total))
        if percentage < 0.0 {
            percentage = 0.0
        } else if percentage >= 1.0 {
            percentage = 1.0
            reset()
        }
        closure?(percentage)
    }

    private func reset() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

private extension CGFloat {
    var parametric: CGFloat {
        guard self > 0.0 else {
            return 0.0
        }
        guard self < 1.0 else {
            return 1.0
        }
        return ((self * self) / (2.0 * ((self * self) - self) + 1.0))
    }

    var quadraticEaseInOut: CGFloat {
        guard self > 0.0 else {
            return 0.0
        }
        guard self < 1.0 else {
            return 1.0
        }
        if self < 0.5 {
            return 2 * self * self
        }
        return (-2 * self * self) + (4 * self) - 1
    }

    var quadraticEaseOut: CGFloat {
        guard self > 0.0 else {
            return 0.0
        }
        guard self < 1.0 else {
            return 1.0
        }
        return -self * (self - 2)
    }

    var quadraticEaseIn: CGFloat {
        guard self > 0.0 else {
            return 0.0
        }
        guard self < 1.0 else {
            return 1.0
        }
        return self * self
    }
}
