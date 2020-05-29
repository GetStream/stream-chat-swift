//
// UserDTO.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(UserDTO)
public class UserDTO: NSManagedObject {
  static let entityName = "UserDTO"

  @NSManaged var id: String
  @NSManaged var extraData: Data?

  static func load(id: String, context: NSManagedObjectContext) -> UserDTO? {
    let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
    request.predicate = NSPredicate(format: "id == %@", id)
    return try? context.fetch(request).first
  }

  /// If a User with the given id exists in the context, fetches and returns it. Otherwise create a new
  /// `UserDTO` with the given id.
  ///
  /// - Parameters:
  ///   - id: The id of the user to fetch
  ///   - context: The context used to fetch/create `UserDTO`
  ///
  static func loadOrCreate(id: String, context: NSManagedObjectContext) -> UserDTO {
    if let existing = Self.load(id: id, context: context) {
      return existing
    }

    let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! UserDTO
    new.id = id
    return new
  }
}

extension NSManagedObjectContext {
  func saveUser<ExtraUserData: Codable & Hashable>(_ user: UserModel<ExtraUserData>) {
    let _: UserDTO = saveUser(user)
  }

  func saveUser<ExtraUserData: Codable & Hashable>(_ user: UserModel<ExtraUserData>) -> UserDTO {
    let dto = UserDTO.loadOrCreate(id: user.id, context: self)

    if let extraData = user.extraData {
      dto.extraData = try? JSONEncoder.default.encode(extraData)
    }

    return dto
  }

  func saveUser<ExtraUserData: Codable & Hashable>(endpointResponse response: UserEndpointReponse<ExtraUserData>) {
    let _: UserDTO = saveUser(endpointResponse: response)
  }

  func saveUser<ExtraUserData: Codable & Hashable>(endpointResponse response: UserEndpointReponse<ExtraUserData>) -> UserDTO {
    let dto = UserDTO.loadOrCreate(id: response.id, context: self)
    if let extraData = response.extraData {
      dto.extraData = try? JSONEncoder.default.encode(extraData)
    }
    return dto
  }

  func loadUser<ExtraUserData: Codable & Hashable>(id: String) -> UserModel<ExtraUserData>? {
    guard let dto = UserDTO.load(id: id, context: self) else { return nil }
    var user = UserModel<ExtraUserData>(id: dto.id)
    var extraData: ExtraUserData?
    if let dtoExtraData = dto.extraData {
      extraData = try? JSONDecoder.default.decode(ExtraUserData.self, from: dtoExtraData)
    }
    user.extraData = extraData
    return user
  }
}

extension UserModel: LoadableEntity {
  init(fromDTO entity: UserDTO) {
    self.id = entity.id
    self.extraData = try? JSONDecoder.default
      .decode(ExtraData.self, from: entity.extraData!) // how to handle failure here?
  }
}
