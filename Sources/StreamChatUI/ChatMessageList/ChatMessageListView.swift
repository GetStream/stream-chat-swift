//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Custom view type used to show the message list.
open class ChatMessageListView: UITableView, Customizable, ComponentsProvider {
    private var identifiers: Set<String> = .init()
    private var isInitialized: Bool = false

    // MARK: - Difference Kit and Skipping messages Handling

    // The properties below is to handle the DifferenceKit API. Currently it is
    // internal because these should actually be handled in the `ChatMessageListVC` but
    // that would make this class obsolete especially the `updateMessages(changes:)` and
    // it would require a lot of breaking changes. So for now, the Diff logic will live here.

    /// The previous messages snapshot before the next update.
    internal var previousMessagesSnapshot: [ChatMessage] = []
    /// The current messages from the data source, including skipped messages.
    /// This property is especially useful when resetting the skipped messages
    /// since we want to reload the data and insert back the skipped messages, for this,
    /// we update the messages data with the one originally reported by the data controller.
    internal var currentMessagesFromDataSource: LazyCachedMapCollection<ChatMessage> = []

    /// The new messages snapshot reported by the channel or message controller.
    /// If messages are being skipped, this snapshot doesn't include skipped messages.
    internal var newMessagesSnapshot: LazyCachedMapCollection<ChatMessage> = []

    /// When inserting messages at the bottom, if the user is scrolled up,
    /// we skip adding the message to the UI until the user scrolls back
    /// to the bottom. This is to avoid message list jumps.
    internal var skippedMessages: Set<MessageId> = []

    /// This closure is to update the dataSource when DifferenceKit
    /// reports the data source should be updated.
    internal var onNewDataSource: (([ChatMessage]) -> Void)?

    /// Property used for `adjustContentInsetToPositionMessagesAtTheTop()` to avoid
    /// reseting the content inset more than one time.
    private var requiresContentInsetReset = false

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

    override open func layoutSubviews() {
        super.layoutSubviews()

        adjustContentInsetToPositionMessagesAtTheTop()
    }

    // MARK: Public API

    /// Calculates the cell reuse identifier for the given options.
    /// - Parameters:
    ///   - contentViewClass: The type of message content view.
    ///   - attachmentViewInjectorType: The type of attachment injector.
    ///   - layoutOptions: The message content view layout options.
    ///   - message: The message data.
    /// - Returns: The cell reuse identifier.
    open func reuseIdentifier(
        contentViewClass: ChatMessageContentView.Type,
        attachmentViewInjectorType: AttachmentViewInjector.Type?,
        layoutOptions: ChatMessageLayoutOptions,
        message: ChatMessage?
    ) -> String {
        var components = [
            ChatMessageCell.reuseId,
            String(layoutOptions.id),
            String(describing: contentViewClass)
        ]
        
        /// If the message should render mixed attachments, the id should be based on the underlying injectors.
        if let mixedAttachmentInjector = attachmentViewInjectorType as? MixedAttachmentViewInjector.Type {
            let injectors = mixedAttachmentInjector.injectors(for: message)
            components.append(contentsOf: injectors.map(String.init(describing:)))
        } else {
            components.append(String(describing: attachmentViewInjectorType))
        }

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
            layoutOptions: layoutOptions,
            message: messageContentView.content
        )
    }

    /// Dequeues the message cell. Registers the cell for received combination of `contentViewClass + layoutOptions`
    /// if needed.
    /// - Parameters:
    ///   - contentViewClass: The type of content view the cell will be displaying.
    ///   - layoutOptions: The option set describing content view layout.
    ///   - indexPath: The cell index path.
    ///   - message: The message data.
    /// - Returns: The instance of `ChatMessageCollectionViewCell` set up with the
    /// provided `contentViewClass` and `layoutOptions`
    open func dequeueReusableCell(
        contentViewClass: ChatMessageContentView.Type,
        attachmentViewInjectorType: AttachmentViewInjector.Type?,
        layoutOptions: ChatMessageLayoutOptions,
        for indexPath: IndexPath,
        message: ChatMessage?
    ) -> ChatMessageCell {
        let reuseIdentifier = self.reuseIdentifier(
            contentViewClass: contentViewClass,
            attachmentViewInjectorType: attachmentViewInjectorType,
            layoutOptions: layoutOptions,
            message: message
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

    /// Scroll to the bottom of the message list.
    open func scrollToBottom(animated: Bool = true) {
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

    /// Scroll to the top of the message list.
    open func scrollToTop(animated: Bool = true) {
        let numberOfRows = numberOfRows(inSection: 0)
        guard numberOfRows > 0 else { return }
        let indexPath = IndexPath(row: numberOfRows - 1, section: 0)
        scrollToRow(at: indexPath, at: .bottom, animated: animated)
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
        let previousMessagesSnapshot = self.previousMessagesSnapshot
        let newMessagesWithoutSkipped = newMessagesSnapshot.filter {
            !self.skippedMessages.contains($0.id)
        }
        adjustContentInsetToPositionMessagesAtTheTop()
        UIView.performWithoutAnimation {
            reloadMessages(
                previousSnapshot: previousMessagesSnapshot,
                newSnapshot: newMessagesWithoutSkipped,
                with: .fade,
                completion: { [weak self] in
                    completion?()
                    self?.adjustContentInsetToPositionMessagesAtTheTop()
                }
            )
        }
    }

    /// Reset the skipped messages and reload the message list
    /// with the messages originally reported from the data source.
    internal func reloadSkippedMessages() {
        skippedMessages = []
        newMessagesSnapshot = currentMessagesFromDataSource
        onNewDataSource?(Array(newMessagesSnapshot))
        reloadData()
        scrollToBottom()
    }

    /// Adjusts the content inset so that messages are inserted at the top when there are few messages.
    /// This is will be executed if the `Components.shouldMessagesStartAtTheTop` is enabled.
    internal func adjustContentInsetToPositionMessagesAtTheTop() {
        guard components.shouldMessagesStartAtTheTop else {
            return
        }

        // If the height of message list is more than the content height
        // then adjust the content inset so that it fills the remaining height
        // otherwise do not set any content inset.
        let contentSizeHeight = contentSize.height
        let messageListHeight = frame.height
        let newContentInset = messageListHeight - contentSizeHeight
        if newContentInset > 0 {
            contentInset.top = newContentInset
            showsVerticalScrollIndicator = false
            requiresContentInsetReset = true
            // In case  we already removed the content inset, there's
            // no need to do it every time.
        } else if requiresContentInsetReset {
            requiresContentInsetReset = false
            contentInset.top = 0
            showsVerticalScrollIndicator = true
        } else {
            // no-op
        }
    }

    // MARK: - Deprecations

    /// Scrolls to most recent message. (Scrolls to the bottom of the message list).
    @available(*, deprecated, renamed: "scrollToBottom(animated:)")
    open func scrollToMostRecentMessage(animated: Bool = true) {
        scrollToBottom(animated: animated)
    }
}

// MARK: Helpers

private extension CGAffineTransform {
    static let mirrorY = Self(scaleX: 1, y: -1)
}
