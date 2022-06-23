//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

protocol IdentifiablePayload {
    associatedtype DatabaseObject: IdentifiableModel & NSManagedObject
    
    var databaseId: String? { get }
}

extension ChannelPayload: IdentifiablePayload {
    typealias DatabaseObject = ChannelDTO
    
    var databaseId: String? { channel.databaseId }
}

extension ChannelDetailPayload: IdentifiablePayload {
    typealias DatabaseObject = ChannelDTO

    var databaseId: String? { cid.rawValue }
}

extension UserPayload: IdentifiablePayload {
    typealias DatabaseObject = UserDTO

    var databaseId: String? { id }
}

extension MessagePayload: IdentifiablePayload {
    typealias DatabaseObject = MessageDTO
    
    var databaseId: String? { id }
}

extension MessageReactionPayload: IdentifiablePayload {
    typealias DatabaseObject = MessageReactionDTO

    var databaseId: String? {
        MessageReactionDTO.createId(userId: user.id, messageId: messageId, type: type)
    }
}

extension MemberPayload: IdentifiablePayload {
    typealias DatabaseObject = MemberDTO

    var databaseId: String? { nil } // Cannot build id without channel id
}

extension Decodable {
    private func recursivelyGetIDs<T: IdentifiablePayload>(for type: T.Type = T.self) -> Set<String> {
        var ids: Set<String> = []
        
        Mirror.reflect(self, matchingType: T.self) { match in
            guard let id = match.databaseId else { return }
            
            ids.insert(id)
        }
        
        return ids
    }
    
    private func getPreWarmedCache<T: IdentifiablePayload>(for type: T.Type = T.self, context: NSManagedObjectContext) -> PreWarmedCache {
        var modelMapping: [String: NSManagedObjectID] = [:]
        context.performAndWait {
            let ids = Array(recursivelyGetIDs(for: type))
            context.batchFetch(type: type.DatabaseObject.self, ids: ids).forEach {
                modelMapping[$0.id] = $0.objectID
            }
        }
        
        return [T.DatabaseObject.className: modelMapping]
    }
    
    func getPayloadToModelIdMappings(context: NSManagedObjectContext) -> PreWarmedCache {
        let caches = [
            getPreWarmedCache(for: ChannelPayload.self, context: context),
            getPreWarmedCache(for: ChannelDetailPayload.self, context: context),
            getPreWarmedCache(for: UserPayload.self, context: context),
            getPreWarmedCache(for: MessagePayload.self, context: context),
            getPreWarmedCache(for: MemberPayload.self, context: context),
            getPreWarmedCache(for: MessageReactionPayload.self, context: context)
        ]
        
        return caches.reduce([:]) {
            $0.merging($1) { m1, m2 in
                m1.merging(m2) { id1, _ in id1 }
            }
        }
    }
}

private extension Mirror {
    static func reflect<T>(
        _ target: Any,
        matchingType type: T.Type = T.self,
        using closure: (T) -> Void
    ) {
        if let match = target as? T {
            closure(match)
        } else if let mathces = target as? [T] {
            mathces.forEach { closure($0) }
        } else {
            let mirror = Mirror(reflecting: target)
            
            for child in mirror.children {
                Mirror.reflect(child.value, using: closure)
            }
        }
    }
}

private extension NSManagedObjectContext {
    func batchFetch<T: NSManagedObject & IdentifiableModel>(type: T.Type = T.self, ids: [String]) -> [T] {
        let request = NSFetchRequest<T>(entityName: T.entityName)
        request.predicate = NSPredicate(format: "%K IN %@", NSExpression(forKeyPath: T.idKeyPath).keyPath, ids)
        return T.load(by: request, context: self)
    }
}
