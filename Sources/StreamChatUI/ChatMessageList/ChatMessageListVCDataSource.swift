//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// The object that acts as the data source of the message list.
public protocol ChatMessageListVCDataSource: AnyObject {
    /// Asks the data source to return the channel for the given message list.
    /// - Parameter vc: The message list requesting the channel.
    func channel(for vc: ChatMessageListVC) -> ChatChannel?

    /// Asks the data source to return the number of messages in the message list.
    /// - Parameter vc: The message list requesting the number of messages.
    func numberOfMessages(in vc: ChatMessageListVC) -> Int

    /// Asks the data source for the message in a particular location of the message list.
    /// - Parameters:
    ///   - vc: The message list requesting the message.
    ///   - indexPath: An index path locating the row in the message list.
    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageAt indexPath: IndexPath
    ) -> ChatMessage?

    /// Asks the data source for the message layout options in a particular location of the message list.
    /// - Parameters:
    ///   - vc: The message list requesting the layout options.
    ///   - indexPath: An index path locating the row in the message list.
    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions
}
