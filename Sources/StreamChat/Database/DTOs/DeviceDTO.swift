//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(DeviceDTO)
class DeviceDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var createdAt: Date?
    
    @NSManaged var user: CurrentUserDTO
}

extension DeviceDTO {
    /// Fetches and returns `DeviceDTO` with the given id. Returns `nil` if the entity doesn't exist.
    ///
    /// - Parameters:
    ///   - id: The id of the user to fetch
    ///   - context: The context used to fetch `DeviceDTO`
    ///
    static func load(id: String, context: NSManagedObjectContext) -> DeviceDTO? {
        load(by: id, context: context).first
    }
    
    /// If a Device with the given id exists in the context, fetches and returns it. Otherwise creates a new
    /// `DeviceDTO` with the given id.
    ///
    /// - Parameters:
    ///   - id: The id of the device to fetch
    ///   - context: The context used to fetch/create `UserDTO`
    ///
    static func loadOrCreate(id: String, context: NSManagedObjectContext) -> DeviceDTO {
        let request = fetchRequest(id: id)
        if let existing = load(by: request, context: context).first {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(
            forEntityName: Self.entityName,
            into: context,
            forRequest: request,
            cachingInto: FetchCache.shared
        ) as! DeviceDTO
        new.id = id
        return new
    }
}

extension DeviceDTO {
    func asModel() throws -> Device {
        guard isValid else { throw InvalidModel(self) }
        return Device(id: id, createdAt: createdAt)
    }
}
