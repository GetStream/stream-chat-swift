//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import UIKit

class ChatMessageListView_Mock: ChatMessageListView {
    var mockIsLastCellFullyVisible = false
    override var isLastCellFullyVisible: Bool {
        mockIsLastCellFullyVisible
    }

    var reloadSkippedMessagesCallCount = 0
    override func reloadSkippedMessages() {
        reloadSkippedMessagesCallCount += 1
    }

    var reloadRowsCallCount = 0
    var reloadRowsCalledWith: [IndexPath] = []
    override func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        reloadRowsCallCount += 1
        reloadRowsCalledWith += indexPaths
    }

    var mockedCellForRow: ChatMessageCell_Mock?
    override func cellForRow(at indexPath: IndexPath) -> UITableViewCell? {
        mockedCellForRow
    }

    var mockedIndexPathsForVisibleRows: [IndexPath]?
    override var indexPathsForVisibleRows: [IndexPath]? {
        mockedIndexPathsForVisibleRows ?? super.indexPathsForVisibleRows
    }

    var scrollToRowCallCount = 0
    var scrollToRowCalledWith: IndexPath?
    override func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        scrollToRowCalledWith = indexPath
        scrollToRowCallCount += 1
    }

    var mockMoreContentThanOnePage = false {
        didSet {
            if mockMoreContentThanOnePage {
                contentSize.height = 100
                bounds = .init(origin: .zero, size: .init(width: 0, height: 10))
            } else {
                contentSize.height = 10
                bounds = .init(origin: .zero, size: .init(width: 0, height: 100))
            }
        }
    }

    var scrollToTopCallCount = 0
    override func scrollToTop(animated: Bool = true) {
        scrollToTopCallCount += 1
    }

    var scrollToBottomCallCount = 0
    override func scrollToBottom(animated: Bool = true) {
        scrollToBottomCallCount += 1
    }

    var updateMessagesCompletion: (() -> Void)?
    override func updateMessages(with changes: [ListChange<ChatMessage>], completion: (() -> Void)? = nil) {
        updateMessagesCompletion = completion
    }
}
