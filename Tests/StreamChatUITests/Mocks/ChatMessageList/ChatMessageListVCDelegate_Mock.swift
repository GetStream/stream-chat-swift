//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import UIKit

class ChatMessageListVCDelegate_Mock: ChatMessageListVCDelegate {
    var mockedHeaderView: ChatMessageDecorationView?
    var mockedFooterView: ChatMessageDecorationView?
    var mockedShouldShowJumpToUnread: Bool = false

    func chatMessageListVC(_ vc: ChatMessageListVC, willDisplayMessageAt indexPath: IndexPath) {}

    func chatMessageListVC(_ vc: ChatMessageListVC, scrollViewDidScroll scrollView: UIScrollView) {}

    func chatMessageListVC(_ vc: ChatMessageListVC, didTapOnAction actionItem: ChatMessageActionItem, for message: ChatMessage) {}

    func chatMessageListVC(_ vc: ChatMessageListVC, didTapOnMessageListView messageListView: ChatMessageListView, with gestureRecognizer: UITapGestureRecognizer) {}

    var shouldLoadPageAroundMessageCallCount = 0
    var shouldLoadPageAroundMessageResult: Error?

    func chatMessageListVC(_ vc: ChatMessageListVC, shouldLoadPageAroundMessageId messageId: MessageId, _ completion: @escaping ((Error?) -> Void)) {
        shouldLoadPageAroundMessageCallCount += 1
        if let result = shouldLoadPageAroundMessageResult {
            completion(result)
        }
    }

    var shouldLoadFirstPageCallCount = 0
    func chatMessageListVCShouldLoadFirstPage(_ vc: ChatMessageListVC) {
        shouldLoadFirstPageCallCount += 1
    }

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        headerViewForMessage message: ChatMessage,
        at indexPath: IndexPath
    ) -> ChatMessageDecorationView? {
        mockedHeaderView
    }

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        footerViewForMessage message: ChatMessage,
        at indexPath: IndexPath
    ) -> ChatMessageDecorationView? {
        mockedFooterView
    }

    func chatMessageListShouldShowJumpToUnread(_ vc: ChatMessageListVC) -> Bool {
        mockedShouldShowJumpToUnread
    }
}
