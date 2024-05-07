//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

package typealias DatabaseType = String
package typealias DatabaseId = String
package typealias PreWarmedCache = [DatabaseType: [DatabaseId: NSManagedObjectID]]
package typealias IdentifiableDatabaseObject = NSManagedObject & IdentifiableModel

extension PreWarmedCache {
    func model<T: IdentifiableDatabaseObject>(for id: DatabaseId, context: NSManagedObjectContext, type: T.Type) -> T? {
        guard let objectId = self[T.className]?[id] else { return nil }
        return try? context.existingObject(with: objectId) as? T
    }
}

package protocol IdentifiableModel {
    static var className: DatabaseType { get }
    static var idKeyPath: String? { get }
    static func id(for model: NSManagedObject) -> DatabaseId?
}

private extension IdentifiableModel {
    static var _className: String { String(describing: self) }
}

extension ChannelDTO: IdentifiableModel {
    package static let className: DatabaseType = _className
    package static let idKeyPath: String? = #keyPath(ChannelDTO.cid)
    package static func id(for model: NSManagedObject) -> DatabaseId? { (model as? Self)?.cid }
}

extension UserDTO: IdentifiableModel {
    package static let className: DatabaseType = _className
    package static let idKeyPath: String? = #keyPath(UserDTO.id)
    package static func id(for model: NSManagedObject) -> DatabaseId? { (model as? Self)?.id }
}

extension MessageDTO: IdentifiableModel {
    package static let className: DatabaseType = _className
    package static let idKeyPath: String? = #keyPath(MessageDTO.id)
    package static func id(for model: NSManagedObject) -> DatabaseId? { (model as? Self)?.id }
}

extension MessageReactionDTO: IdentifiableModel {
    package static let className: DatabaseType = _className
    package static let idKeyPath: String? = #keyPath(MessageReactionDTO.id)
    package static func id(for model: NSManagedObject) -> DatabaseId? { (model as? Self)?.id }
}

extension MemberDTO: IdentifiableModel {
    package static let className: DatabaseType = _className
    package static let idKeyPath: String? = #keyPath(MemberDTO.id)
    package static func id(for model: NSManagedObject) -> DatabaseId? { (model as? Self)?.id }
}

extension ChannelReadDTO: IdentifiableModel {
    package static let className: DatabaseType = _className
    package static let idKeyPath: String? = nil
    package static func id(for model: NSManagedObject) -> DatabaseId? { nil } // Does not have id
}

extension ThreadDTO: IdentifiableModel {
    package static var className: DatabaseType { _className }
    package static var idKeyPath: String? { #keyPath(ThreadDTO.parentMessageId) }
    package static func id(for model: NSManagedObject) -> DatabaseId? { (model as? Self)?.parentMessageId }
}

extension ThreadReadDTO: IdentifiableModel {
    package static let className: DatabaseType = _className
    package static let idKeyPath: String? = nil
    package static func id(for model: NSManagedObject) -> DatabaseId? { nil }
}

extension ThreadParticipantDTO: IdentifiableModel {
    package static let className: DatabaseType = _className
    package static let idKeyPath: String? = #keyPath(MemberDTO.id)
    package static func id(for model: NSManagedObject) -> DatabaseId? { (model as? Self)?.user.id }
}
