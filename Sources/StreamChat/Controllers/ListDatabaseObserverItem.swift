//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

protocol ListDatabaseObserverItem {
    static func mapChanges<T>(_ changes: [ListChange<T>], initialItems: [T], newItems: [T]) -> [ListChange<T>]
}

extension ListDatabaseObserverItem {
    static func mapChanges<T>(_ changes: [ListChange<T>], initialItems: [T], newItems: [T]) -> [ListChange<T>] {
        changes
    }
}

extension AttachmentDTO: ListDatabaseObserverItem {}
extension ChatMessage: ListDatabaseObserverItem {}
extension ChatUser: ListDatabaseObserverItem {}
extension UserDTO: ListDatabaseObserverItem {}
extension MessageDTO: ListDatabaseObserverItem {}
extension UserListQueryDTO: ListDatabaseObserverItem {}

extension ChatChannel: ListDatabaseObserverItem {
    static func mapChanges<T>(_ changes: [ListChange<T>], initialItems: [T], newItems: [T]) -> [ListChange<T>] {
        guard let changes = changes as? [ListChange<ChatChannel>],
              let initialItems = initialItems as? [ChatChannel],
              let newItems = newItems as? [ChatChannel],
              let result = mapChanges(changes, initialItems: initialItems, newItems: newItems) as? [ListChange<T>] else {
            return changes
        }

        return result
    }

    private static func mapChanges(_ changes: [ListChange<ChatChannel>], initialItems: [ChatChannel], newItems: [ChatChannel]) -> [ListChange<ChatChannel>] {
        let changes = StagedChangeset(source: initialItems, target: newItems)

        return changes.changesets.flatMap { changeset -> [ListChange<ChatChannel>] in
            var changes: [ListChange<ChatChannel>] = []

            changeset.elementDeleted.forEach {
                changes.append(.remove(initialItems[$0.element], index: IndexPath(item: $0.element, section: $0.section)))
            }

            changeset.elementInserted.forEach {
                changes.append(.insert(newItems[$0.element], index: IndexPath(item: $0.element, section: $0.section)))
            }

            changeset.elementUpdated.forEach {
                changes.append(.update(initialItems[$0.element], index: IndexPath(item: $0.element, section: $0.section)))
            }

            changeset.elementMoved.forEach { source, target in
                changes.append(.move(
                    initialItems[source.element],
                    fromIndex: IndexPath(item: source.element, section: source.section),
                    toIndex: IndexPath(item: target.element, section: target.section)
                ))
            }

            return changes
        }
    }
}

extension ChatChannel: Differentiable {
    public func isContentEqual(to source: ChatChannel) -> Bool {
        cid == source.cid &&
            name == source.name &&
            imageURL == source.imageURL &&
            lastMessageAt == source.lastMessageAt &&
            createdAt == source.createdAt &&
            updatedAt == source.updatedAt &&
            deletedAt == source.deletedAt &&
            truncatedAt == source.truncatedAt &&
            isHidden == source.isHidden &&
            createdBy == source.createdBy &&
            ownCapabilities == source.ownCapabilities &&
            isFrozen == source.isFrozen &&
            memberCount == source.memberCount &&
            membership == source.membership &&
            watcherCount == source.watcherCount &&
            team == source.team &&
            reads == source.reads &&
            muteDetails == source.muteDetails &&
            cooldownDuration == source.cooldownDuration &&
            extraData == source.extraData
    }
}
