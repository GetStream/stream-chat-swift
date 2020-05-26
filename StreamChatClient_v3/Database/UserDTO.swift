//
// UserDTO.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(UserDTO)
public class UserDTO: NSManagedObject {
  @NSManaged fileprivate var id: String
  @NSManaged fileprivate var name: String
}

// extension User {
//
//    static func usersFetchRequest(query: UserListReference.Query) -> NSFetchRequest<UserDTO> {
//        let request = NSFetchRequest<UserDTO>(entityName: "UserDTO")
//        request.sortDescriptors = [.init(key: "name", ascending: true)]
////        request.predicate = nil // TODO: Filter -> NSPredicate
//        return request
//    }
//
//    /// Save the current data to context
//    @discardableResult
//    func save(to context: NSManagedObjectContext) -> UserDTO {
//        let dto = UserDTO(context: context)
//        dto.id = id
//        dto.name = name
//        return dto
//    }
//
//    init(from dto: UserDTO) {
//        self.init(name: dto.name, id: dto.id)
//    }
// }
