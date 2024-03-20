//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of channel members matching to the specified query.
@available(iOS 13.0, *)
public final class MemberListState: ObservableObject {
    private let observer: Observer
    
    init(members: [ChatChannelMember], query: ChannelMemberListQuery, database: DatabaseContainer) {
        self.members = StreamCollection(members)
        observer = Observer(query: query, database: database)
        observer.start(
            with: .init(membersDidChange: { [weak self] members in await self?.setValue(members, for: \.members) })
        )
    }
    
    /// An array of members for the specified ``ChannelMemberListQuery``.
    @Published public private(set) var members = StreamCollection<ChatChannelMember>([])
    
    // MARK: - Mutating the State
    
    @MainActor func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<MemberListState, Value>) {
        self[keyPath: keyPath] = value
    }
}

// MARK: - Observing the Local State

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
