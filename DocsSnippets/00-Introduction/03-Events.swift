// LINK: https://getstream.io/chat/docs/ios-swift/?language=swift#events

import UIKit
import StreamChat

func snippet_introduction_events() {
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
        .sink { changes in
           // animate the changes to the message list
        }
        .store(in: &cancellables)
}
