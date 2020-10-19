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

protocol Query: Model {
    associatedtype QueryItem: Model
}

extension ChannelMemberListQuery: Query {
    typealias DTO = ChannelMemberListQueryDTO
    typealias QueryItem = _ChatChannelMember<ExtraData>
}

extension UserListQuery: Query {
    typealias DTO = UserListQueryDTO
    typealias QueryItem = _ChatUser<ExtraData>
}

extension ChannelListQuery: Query {
    typealias DTO = ChannelListQueryDTO
    typealias QueryItem = _ChatChannel<ExtraData>
}
