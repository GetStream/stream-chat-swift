//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of channel members matching to the specified query.
@available(iOS 13.0, *)
@MainActor public final class MemberListState: ObservableObject {
    private let observer: Observer
    
    init(query: ChannelMemberListQuery, database: DatabaseContainer) {
        observer = Observer(query: query, database: database)
        members = observer.start(
            with: .init(membersDidChange: { [weak self] in self?.members = $0 })
        )
    }
    
    /// An array of members for the specified ``ChannelMemberListQuery``.
    @Published public private(set) var members = StreamCollection<ChatChannelMember>([])
}
