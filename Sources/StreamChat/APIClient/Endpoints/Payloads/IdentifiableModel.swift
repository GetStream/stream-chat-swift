//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

typealias PreWarmedCache = [String: [String: NSManagedObjectID]]

extension PreWarmedCache {
    func model<T: NSManagedObject & IdentifiableModel>(for id: String, context: NSManagedObjectContext, type: T.Type) -> T? {
        guard let objectId = self[T.className]?[id] else { return nil }
        return try? context.existingObject(with: objectId) as? T
    }
}

protocol IdentifiableModel {
    static var idKeyPath: KeyPath<Self, String> { get }
}

extension IdentifiableModel {
    static var className: String { String(describing: self) }
    
    var id: String { self[keyPath: Self.idKeyPath] }
}

extension ChannelDTO: IdentifiableModel {
    static var idKeyPath: KeyPath<ChannelDTO, String> { \.cid }
}

extension UserDTO: IdentifiableModel {
    static var idKeyPath: KeyPath<UserDTO, String> { \.id }
}

extension MessageDTO: IdentifiableModel {
    static var idKeyPath: KeyPath<MessageDTO, String> { \.id }
}

extension MessageReactionDTO: IdentifiableModel {
    static var idKeyPath: KeyPath<MessageReactionDTO, String> { \.id }
}

extension MemberDTO: IdentifiableModel {
    static var idKeyPath: KeyPath<MemberDTO, String> { \.id }
}
