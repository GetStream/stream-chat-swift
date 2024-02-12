//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

protocol IdentifiablePayload {
    var databaseId: DatabaseId? { get }
    static var modelClass: (IdentifiableDatabaseObject).Type? { get }
    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>])
}

extension IdentifiablePayload {
    func addId(cache: inout [String: Set<String>]) {
        guard let databaseId = databaseId, let modelClassName = Self.modelClass?.className else { return }
        var ids = (cache[modelClassName] ?? Set<String>())
        ids.insert(databaseId)
        cache[modelClassName] = ids
    }

    func recursivelyGetAllIds() -> [String: Set<String>] {
        var cache: [String: Set<String>] = [:]
        fillIds(cache: &cache)
        return cache
    }

    func getPayloadToModelIdMappings(context: NSManagedObjectContext) -> PreWarmedCache {
        let payloadIdsMappings = recursivelyGetAllIds()
        var cache: PreWarmedCache = [:]

        for (className, identifiableValues) in payloadIdsMappings {
            let modelClass: (IdentifiableDatabaseObject).Type? = {
                switch className {
                case ChannelDTO.className:
                    return ChannelDTO.self
                case UserDTO.className:
                    return UserDTO.self
                case MessageDTO.className:
                    return MessageDTO.self
                case MessageReactionDTO.className:
                    return MessageReactionDTO.self
                case MemberDTO.className:
                    return MemberDTO.self
                case ChannelReadDTO.className:
                    return ChannelReadDTO.self
                default:
                    return nil
                }
            }()

            guard let modelClass = modelClass, let keyPath = modelClass.idKeyPath else { continue }

            let values = Array(identifiableValues)
            var results: [NSManagedObject]?
            context.performAndWait {
                results = modelClass.batchFetch(keyPath: keyPath, equalTo: values, context: context)
            }
            guard let results = results else { continue }

            var modelMapping: [DatabaseId: NSManagedObjectID] = [:]
            results.forEach {
                if let id = modelClass.id(for: $0) {
                    modelMapping[id] = $0.objectID
                }
            }
            cache[modelClass.className] = modelMapping
        }

        return cache
    }
}

protocol IdentifiablePayloadProxy: IdentifiablePayload {}

extension IdentifiablePayloadProxy {
    var databaseId: DatabaseId? { nil }
    static var modelClass: (IdentifiableDatabaseObject).Type? { nil }
}

extension Array where Element: IdentifiablePayload {
    var databaseId: DatabaseId? { nil }
    static var modelClass: (IdentifiableDatabaseObject).Type? { nil }

    func fillIds(cache: inout [DatabaseType: Set<DatabaseId>]) {
        forEach {
            $0.fillIds(cache: &cache)
        }
    }
}

private extension NSManagedObject {
    static func batchFetch(keyPath: String, equalTo values: [String], context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K IN %@", keyPath, values)
        return load(by: request, context: context)
    }
}
