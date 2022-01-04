//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The object that acts as the delegate of the message list.
public protocol ChatMessageListVCDelegate: AnyObject {
    /// Tells the delegate the message list is about to draw a message for a particular row.
    /// - Parameters:
    ///   - vc: The message list informing the delegate of this event.
    ///   - indexPath: An index path locating the row in the message list.
    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    )

    /// Tells the delegate when the user scrolls the content view within the receiver.
    /// - Parameters:
    ///   - vc: The message list informing the delegate of this event.
    ///   - scrollView: The scroll view that belongs to the message list.
    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        scrollViewDidScroll scrollView: UIScrollView
    )

    /// Tells the delegate when the user taps on an action for the given message.
    /// - Parameters:
    ///   - vc: The message list informing the delegate of this event.
    ///   - actionItem: The action performed on the given message.
    ///   - message: The given message.
    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnAction actionItem: ChatMessageActionItem,
        for message: ChatMessage
    )

    /// Tells the delegate when the user taps on the message list view.
    /// - Parameters:
    ///   - vc: The message list  informing the delegate of this event.
    ///   - messageListView: The message list view.
    ///   - gestureRecognizer: The tap gesture recognizer that triggered the event.
    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnMessageListView messageListView: ChatMessageListView,
        with gestureRecognizer: UITapGestureRecognizer
    )
}
