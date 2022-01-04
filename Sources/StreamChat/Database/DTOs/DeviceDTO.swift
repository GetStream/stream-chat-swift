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
        let request = NSFetchRequest<DeviceDTO>(entityName: DeviceDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return try? context.fetch(request).first
    }
    
    /// If a Device with the given id exists in the context, fetches and returns it. Otherwise creates a new
    /// `DeviceDTO` with the given id.
    ///
    /// - Parameters:
    ///   - id: The id of the device to fetch
    ///   - context: The context used to fetch/create `UserDTO`
    ///
    static func loadOrCreate(id: String, context: NSManagedObjectContext) -> DeviceDTO {
        if let existing = Self.load(id: id, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! DeviceDTO
        new.id = id
        return new
    }
}

extension DeviceDTO {
    func asModel() -> Device {
        Device(id, createdAt: createdAt)
    }
}
