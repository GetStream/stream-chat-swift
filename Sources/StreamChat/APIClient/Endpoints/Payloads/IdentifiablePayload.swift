//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

protocol IdentifiablePayload {
    var className: String { get }
    func keyPathId() -> (keyPath: String, value: String)?
}

extension IdentifiablePayload {
    var className: String {
        "\(Self.self)"
    }
}

extension ChannelListPayload: IdentifiablePayload {
    func keyPathId() -> (keyPath: String, value: String)? {
        nil // Proxy
    }
}

extension ChannelPayload: IdentifiablePayload {
    func keyPathId() -> (keyPath: String, value: String)? {
        nil // Proxy
    }
}

extension ChannelDetailPayload: IdentifiablePayload {
    func keyPathId() -> (keyPath: String, value: String)? {
        let stringKeyPath = (\ChannelDTO.cid).stringValue
        return (stringKeyPath, cid.rawValue)
    }
}

extension UserPayload: IdentifiablePayload {
    func keyPathId() -> (keyPath: String, value: String)? {
        let stringKeyPath = (\UserDTO.id).stringValue
        return (stringKeyPath, id)
    }
}

extension MessagePayload: IdentifiablePayload {
    func keyPathId() -> (keyPath: String, value: String)? {
        let stringKeyPath = (\MessageDTO.id).stringValue
        return (stringKeyPath, id)
    }
}

extension MessageReactionPayload: IdentifiablePayload {
    func keyPathId() -> (keyPath: String, value: String)? {
        let stringKeyPath = (\MessageReactionDTO.id).stringValue
        return (stringKeyPath, MessageReactionDTO.createId(userId: user.id, messageId: messageId, type: type))
    }
}

extension MemberPayload: IdentifiablePayload {
    func keyPathId() -> (keyPath: String, value: String)? {
        nil // Cannot build id without channel id
    }
}

extension ChannelReadPayload: IdentifiablePayload {
    func keyPathId() -> (keyPath: String, value: String)? {
        nil // Needs a composed predicate 'channel.cid == %@ && user.id == %@'
    }
}

extension Array where Element: IdentifiablePayload {
    func extractIds() -> [(keyPath: String, value: String)] {
        compactMap { $0.keyPathId() }
    }
}

func recursivelyGetAllIds(for element: Any) -> [String: Set<String>] {
    var cache: [String: Set<String>] = [:]

    if let identifiable = element as? IdentifiablePayload {
        updateCache(with: identifiable, cache: &cache)
    }

    let mirror = Mirror(reflecting: element)
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
    guard let (keyPath, id) = element.keyPathId() else { return }
    var set = (cache[element.className] ?? Set<String>())
    set.insert(id)
    cache[element.className] = set
}

extension KeyPath where Root: NSObject {
    var stringValue: String {
        NSExpression(forKeyPath: self).keyPath
    }
}
