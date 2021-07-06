//
//  YTMessageLayoutOptionsResolver.swift
//  YouTubeClone
//
//  Created by Sagar Dagdu on 01/07/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI

final class YTMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(at indexPath: IndexPath, in channel: _ChatChannel<NoExtraData>, with messages: AnyRandomAccessCollection<_ChatMessage<NoExtraData>>) -> ChatMessageLayoutOptions {
        
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages)
        
        // Remove the message options that are not needed in our case
        options.remove([.flipped, .bubble, .timestamp, .avatar, .avatarSizePadding, .authorName, .threadInfo, .reactions, .onlyVisibleForYouIndicator, .errorIndicator])
        
        // Insert the message options that are needed
        options.insert([.avatar, .timestamp, .authorName])
        
        return options
    }
}
