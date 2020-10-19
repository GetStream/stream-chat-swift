//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import CoreData

protocol Model {
    associatedtype DTO: NSManagedObject
}

extension _ChatChannel: Model {
    typealias DTO = ChannelDTO
}

extension _ChatUser: Model {
    typealias DTO = UserDTO
}

extension _ChatMessage: Model {
    typealias DTO = MessageDTO
}

extension _ChatChannelMember: Model {
    typealias DTO = MemberDTO
}

extension _CurrentChatUser: Model {
    typealias DTO = CurrentUserDTO
}
