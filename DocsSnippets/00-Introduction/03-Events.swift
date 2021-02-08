//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

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
    
    if #available(iOS 13, *) {
        channelController.messagesChangesPublisher
            .receive(on: RunLoop.main)
            .sink { _ in
                // animate the changes to the message list
            }
            .store(in: &cancellables)
    }
}
