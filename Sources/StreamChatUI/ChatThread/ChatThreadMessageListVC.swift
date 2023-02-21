//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

open class ChatThreadMessageListVC: ChatMessageListVC {
    /// Check if the current message being displayed should show the thread replies separator.
    /// - Parameters:
    ///   - message: The message being displayed.
    ///   - indexPath: The indexPath of the message.
    /// - Returns: A Boolean value depending if it should show the date separator or not.
    override open func shouldShowThreadRepliesSeparator(
        forMessage message: ChatMessage,
        at indexPath: IndexPath
    ) -> Bool {
        guard let datasource = dataSource else {
            return false
        }

        /// We check if the message that is currently being decorated is the source
        /// message of the thread.
        return message == datasource.messages.last
    }
}
