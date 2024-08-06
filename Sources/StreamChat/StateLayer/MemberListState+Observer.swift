//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension MemberListState {
    struct Observer {
        private let memberListObserver: StateLayerDatabaseObserver<ListResult, ChatChannelMember, MemberDTO>
        
        init(query: ChannelMemberListQuery, database: DatabaseContainer) {
            memberListObserver = StateLayerDatabaseObserver(
                database: database,
                fetchRequest: MemberDTO.members(matching: query),
                itemCreator: { try $0.asModel() },
                itemReuseKeyPaths: (\ChatChannelMember.id, \MemberDTO.id)
            )
        }
        
        struct Handlers {
            let membersDidChange: @MainActor(StreamCollection<ChatChannelMember>) async -> Void
        }
        
        func start(with handlers: Handlers) -> StreamCollection<ChatChannelMember> {
            do {
                return try memberListObserver.startObserving(didChange: handlers.membersDidChange)
            } catch {
                log.error("Failed to start the member list observer with error \(error)")
                return StreamCollection([])
            }
        }
    }
}
