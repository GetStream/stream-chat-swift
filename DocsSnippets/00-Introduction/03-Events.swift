// LINK: https://getstream.io/chat/docs/ios-swift/?language=swift#events

import Combine
import StreamChat
import UIKit

private var channelController: ChatChannelController!

@available(iOS 13, *)
private var cancellables: Set<AnyCancellable> = []

@available(iOS 13, *)
func snippet_introduction_events() {
    // > import UIKit
    // > import Combine
    // > import StreamChat

    /// * Delegates *

    class ChannelViewController: ChatChannelControllerDelegate {
        func channelController(_ channelController: ChatChannelController, didUpdateMessages changes: [ListChange<ChatMessage>]) {
            // animate the changes to the message list
        }
    }

    let channelViewController = ChannelViewController()

    channelController.delegate = channelViewController

    /// * Combine *

    channelController.messagesChangesPublisher
        .receive(on: RunLoop.main)
        .sink { _ in
            // animate the changes to the message list
        }
        .store(in: &cancellables)
}
