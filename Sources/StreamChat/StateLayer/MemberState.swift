//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An observable object for the specified channel member.
///
/// - Note: All the properties of the represented ``ChatChannelMember`` can be accessed directly on the ``MemberState`` object (e.g. `state.name` returns ``ChatChannelMember.name``).
@available(iOS 13.0, *)
@dynamicMemberLookup
public final class MemberState: ObservableObject {
    private let observer: Observer
    
    init(member: ChatChannelMember, cid: ChannelId, database: DatabaseContainer) {
        self.member = member
        observer = Observer(userId: member.id, cid: cid, database: database)
        observer.start(
            with: .init(
                memberDidChange: { [weak self] change in await self?.setValue(change, for: \.member) }
            )
        )
    }
    
    /// The represented channel member.
    ///
    /// - Note: This property is automatically updated when properties of the member change.
    @Published public private(set) var member: ChatChannelMember
    
    // MARK: - Accessing the Member's Data
    
    /// Accesses the represented ``ChatChannelMember`` data.
    public subscript<T>(dynamicMember keyPath: KeyPath<ChatChannelMember, T>) -> T {
        member[keyPath: keyPath]
    }
    
    // MARK: - Mutating the State
    
    @MainActor func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<MemberState, Value>) {
        self[keyPath: keyPath] = value
    }
}

// MARK: - Observing the Local State

@available(iOS 13.0, *)
extension MemberState {
    struct Observer {
        private let memberObserver: BackgroundEntityDatabaseObserver<ChatChannelMember, MemberDTO>
        private let userId: UserId
        
        init(userId: UserId, cid: ChannelId, database: DatabaseContainer) {
            memberObserver = BackgroundEntityDatabaseObserver(
                context: database.backgroundReadOnlyContext,
                fetchRequest: MemberDTO.member(userId, in: cid),
                itemCreator: { try $0.asModel() as ChatChannelMember }
            )
            self.userId = userId
        }
        
        struct Handlers {
            let memberDidChange: (ChatChannelMember) async -> Void
        }
        
        func start(with handlers: Handlers) {
            do {
                try memberObserver.startObserving()
            } catch {
                log.error("Failed to start the member observer for member: \(userId)")
            }
        }
    }
}
