//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension MemberListState {
    struct Observer {
        private let memberListObserver: BackgroundListDatabaseObserver<ChatChannelMember, MemberDTO>
        
        init(query: ChannelMemberListQuery, database: DatabaseContainer) {
            memberListObserver = BackgroundListDatabaseObserver(
                context: database.backgroundReadOnlyContext,
                fetchRequest: MemberDTO.members(matching: query),
                itemCreator: { try $0.asModel() as ChatChannelMember },
                sorting: []
            )
        }
        
        struct Handlers {
            let membersDidChange: (StreamCollection<ChatChannelMember>) async -> Void
        }
        
        func start(with handlers: Handlers) {
            memberListObserver.onDidChange = { [weak memberListObserver] _ in
                guard let items = memberListObserver?.items else { return }
                let collection = StreamCollection(items)
                Task { await handlers.membersDidChange(collection) }
            }
            do {
                try memberListObserver.startObserving()
            } catch {
                log.error("Failed to start the member list observer with error \(error)")
            }
        }
    }
}
