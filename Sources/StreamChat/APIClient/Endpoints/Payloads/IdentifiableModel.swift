//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

typealias IDToObjectIDCache = [String: [String: NSManagedObjectID]]

extension IDToObjectIDCache {
    func model<T: NSManagedObject & IdentifiableModel>(for id: String, context: NSManagedObjectContext, type: T.Type) -> T? {
        guard let objectId = self[T.className]?[id] else { return nil }
        return try? context.existingObject(with: objectId) as? T
    }
}

protocol IdentifiableModel {
    static var className: String { get }
    static var idKeyPath: String? { get }
    static func id(for model: NSManagedObject) -> String?
}

private extension IdentifiableModel {
    static var _className: String { String(describing: self) }
}

extension ChannelDTO: IdentifiableModel {
    static let className: String = _className
    static let idKeyPath: String? = "cid"
    static func id(for model: NSManagedObject) -> String? { (model as? Self)?.cid }
}

extension UserDTO: IdentifiableModel {
    static let className: String = _className
    static let idKeyPath: String? = "id"
    static func id(for model: NSManagedObject) -> String? { (model as? Self)?.id }
}

extension MessageDTO: IdentifiableModel {
    static let className: String = _className
    static let idKeyPath: String? = "id"
    static func id(for model: NSManagedObject) -> String? { (model as? Self)?.id }
}

extension MessageReactionDTO: IdentifiableModel {
    static let className: String = _className
    static let idKeyPath: String? = "id"
    static func id(for model: NSManagedObject) -> String? { (model as? Self)?.id }
}

extension MemberDTO: IdentifiableModel {
    static let className: String = _className
    static let idKeyPath: String? = "id"
    static func id(for model: NSManagedObject) -> String? { (model as? Self)?.id }
}

extension ChannelReadDTO: IdentifiableModel {
    static let className: String = _className
    static let idKeyPath: String? = nil
    static func id(for model: NSManagedObject) -> String? { nil } // Does not have id
}
