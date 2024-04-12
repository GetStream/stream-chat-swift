//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of channel members matching to the specified query.
@available(iOS 13.0, *)
@MainActor public final class MemberListState: ObservableObject {
    private let observer: Observer
    
    init(initialMembers: [ChatChannelMember], query: ChannelMemberListQuery, database: DatabaseContainer) {
        members = StreamCollection(initialMembers)
        observer = Observer(query: query, database: database)
        observer.start(
            with: .init(membersDidChange: { [weak self] in self?.members = $0 })
        )
        if initialMembers.isEmpty {
            members = observer.memberListObserver.items
        }
    }
    
    /// An array of members for the specified ``ChannelMemberListQuery``.
    @Published public private(set) var members = StreamCollection<ChatChannelMember>([])
}
