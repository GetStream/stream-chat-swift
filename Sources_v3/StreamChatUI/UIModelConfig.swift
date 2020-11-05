//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UIModelConfig {
    public static var `default` = UIModelConfig()
    
    var userModelType: ChatUIUser.Type = ChatUIUser.self
    var messageModelType: ChatUIMessage.Type = ChatUIMessage.self
    var channelModelType: ChatUIChannel.Type = ChatUIChannel.self
    var channelMemberModelType: ChatUIChannelMember.Type = ChatUIChannelMember.self
    var channelReadModelType: ChatUIChannelRead.Type = ChatUIChannelRead.self
    var reactionModelType: ChatUIMessageReaction.Type = ChatUIMessageReaction.self
}
