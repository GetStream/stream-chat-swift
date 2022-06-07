//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

protocol IdentifiablePayload {
    static var keyPath: String? { get }
    var databaseId: String? { get }
    static var modelClass: NSManagedObject.Type? { get }
    static func id(for model: NSManagedObject) -> String?
}

extension IdentifiablePayload {
    fileprivate static var className: String {
        "\(Self.self)"
    }

    private var className: String {
        type(of: self).className
    }

    func getPayloadToModelIdMappings(context: NSManagedObjectContext) -> [String: [String: NSManagedObjectID]] {
        let payloadIdsMappings = recursivelyGetAllIds()

        var modelToIdMappings: [String: [String: NSManagedObjectID]] = [:]

        for (className, identifiableValues) in payloadIdsMappings {
            let aClass: IdentifiablePayload.Type? = {
                switch className {
                case ChannelDetailPayload.className:
                    return ChannelDetailPayload.self
                case UserPayload.className:
                    return UserPayload.self
                case MessagePayload.className:
                    return MessagePayload.self
                case MessageReactionPayload.className:
                    return MessageReactionPayload.self
                case MemberPayload.className:
                    return MemberPayload.self
                case ChannelReadPayload.className:
                    return ChannelReadPayload.self
                default:
                    return nil
                }
            }()

            guard let aClass = aClass, let modelClass = aClass.modelClass, let keyPath = aClass.keyPath else { continue }

            let values = Array(identifiableValues)
            var results: [NSManagedObject]?
            context.performAndWait {
                results = modelClass.batchFetch(keyPath: keyPath, equalTo: values, context: context)
            }
            guard let results = results else { continue }

            var modelMapping: [String: NSManagedObjectID] = [:]
            results.forEach {
                if let id = aClass.id(for: $0) {
                    modelMapping[id] = $0.objectID
                }
            }
            modelToIdMappings["\(modelClass)"] = modelMapping
        }

        return modelToIdMappings
    }

    func recursivelyGetAllIds() -> [String: Set<String>] {
        var cache: [String: Set<String>] = [:]

        updateCache(with: self, cache: &cache)

        let mirror = Mirror(reflecting: self)
        recursiveIdentifiable(elements: mirror.children.map(\.value), cache: &cache, depth: 0)
        return cache
    }

    private func recursiveIdentifiable(elements: [Any], cache: inout [String: Set<String>], depth: Int) {
        if depth == 30 {
            log.assertionFailure("Preventing a stack overflow. Chances are that there's a cyclic dependency between the elements")
            return
        }

        for element in elements {
            if let identifiable = element as? IdentifiablePayload {
                updateCache(with: identifiable, cache: &cache)
                let mirror = Mirror(reflecting: element)
                recursiveIdentifiable(elements: mirror.children.map(\.value), cache: &cache, depth: depth + 1)
            } else if let identifiableCollection = element as? [IdentifiablePayload] {
                recursiveIdentifiable(elements: identifiableCollection, cache: &cache, depth: depth + 1)
            }
        }
    }

    private func updateCache(with element: IdentifiablePayload, cache: inout [String: Set<String>]) {
        guard let id = element.databaseId else { return }
        var set = (cache[element.className] ?? Set<String>())
        set.insert(id)
        cache[element.className] = set
    }
}

extension ChannelListPayload: IdentifiablePayload {
    // Proxy
    var databaseId: String? { nil }
    static let keyPath: String? = nil
    static let modelClass: NSManagedObject.Type? = nil
    static func id(for model: NSManagedObject) -> String? { nil }
}

extension ChannelPayload: IdentifiablePayload {
    // Proxy
    var databaseId: String? { nil }
    static let keyPath: String? = nil
    static let modelClass: NSManagedObject.Type? = nil
    static func id(for model: NSManagedObject) -> String? { nil }
}

extension ChannelDetailPayload: IdentifiablePayload {
    var databaseId: String? { cid.rawValue }
    private static let _keyPath: KeyPath<ChannelDTO, String> = \ChannelDTO.cid
    static let keyPath: String? = _keyPath.stringValue
    static let modelClass: NSManagedObject.Type? = ChannelDTO.self
    static func id(for model: NSManagedObject) -> String? { (model as? ChannelDTO)?[keyPath: _keyPath] }
}

extension UserPayload: IdentifiablePayload {
    var databaseId: String? { id }
    private static let _keyPath: KeyPath<UserDTO, String> = \UserDTO.id
    static let keyPath: String? = _keyPath.stringValue
    static let modelClass: NSManagedObject.Type? = UserDTO.self
    static func id(for model: NSManagedObject) -> String? { (model as? UserDTO)?[keyPath: _keyPath] }
}

extension MessagePayload: IdentifiablePayload {
    var databaseId: String? { id }
    private static let _keyPath: KeyPath<MessageDTO, String> = \MessageDTO.id
    static let keyPath: String? = _keyPath.stringValue
    static let modelClass: NSManagedObject.Type? = MemberDTO.self
    static func id(for model: NSManagedObject) -> String? { (model as? MessageDTO)?[keyPath: _keyPath] }
}

extension MessageReactionPayload: IdentifiablePayload {
    var databaseId: String? {
        MessageReactionDTO.createId(userId: user.id, messageId: messageId, type: type)
    }

    private static let _keyPath: KeyPath<MessageReactionDTO, String> = \MessageReactionDTO.id
    static let keyPath: String? = _keyPath.stringValue
    static let modelClass: NSManagedObject.Type? = MessageReactionDTO.self
    static func id(for model: NSManagedObject) -> String? { (model as? MessageReactionDTO)?[keyPath: _keyPath] }
}

extension MemberPayload: IdentifiablePayload {
    var databaseId: String? {
        nil // Cannot build id without channel id
    }

    private static let _keyPath: KeyPath<MemberDTO, String> = \MemberDTO.id
    static let keyPath: String? = _keyPath.stringValue
    static let modelClass: NSManagedObject.Type? = MemberDTO.self
    static func id(for model: NSManagedObject) -> String? { (model as? MemberDTO)?[keyPath: _keyPath] }
}

extension ChannelReadPayload: IdentifiablePayload {
    var databaseId: String? {
        nil // Needs a composed predicate 'channel.cid == %@ && user.id == %@'
    }

    static let keyPath: String? = nil // Fetched by user.id
    static let modelClass: NSManagedObject.Type? = ChannelReadDTO.self
    static func id(for model: NSManagedObject) -> String? { nil }
}

private extension KeyPath where Root: NSObject {
    var stringValue: String {
        NSExpression(forKeyPath: self).keyPath
    }
}

private extension NSManagedObject {
    static func batchFetch(keyPath: String, equalTo values: [String], context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K IN %@", keyPath, values)
        return load(by: request, context: context)
    }
}
