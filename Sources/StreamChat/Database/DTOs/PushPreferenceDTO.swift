//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(PushPreferenceDTO)
class PushPreferenceDTO: NSManagedObject {
    @NSManaged var chatLevel: String
    @NSManaged var disabledUntil: DBDate?
    
    /// Returns a default fetch request for push preferences.
    static var defaultFetchRequest: NSFetchRequest<PushPreferenceDTO> {
        let request = NSFetchRequest<PushPreferenceDTO>(entityName: PushPreferenceDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PushPreferenceDTO.chatLevel, ascending: true)]
        return request
    }
}

extension PushPreferenceDTO {
    /// Snapshots the current state of `PushPreferenceDTO` and returns an immutable model object from it.
    func asModel() throws -> PushPreference {
        try .create(fromDTO: self)
    }
}

extension PushPreference {
    /// Create a PushPreference model from its DTO
    fileprivate static func create(fromDTO dto: PushPreferenceDTO) throws -> PushPreference {
        try dto.isNotDeleted()
        
        return PushPreference(
            level: PushPreferenceLevel(rawValue: dto.chatLevel),
            disabledUntil: dto.disabledUntil?.bridgeDate
        )
    }
}

// MARK: Saving and loading the data

extension NSManagedObjectContext {
    func savePushPreference(payload: PushPreferencePayload) throws -> PushPreferenceDTO {
        let dto = PushPreferenceDTO.loadOrCreate(context: self)
        
        dto.chatLevel = payload.chatLevel
        dto.disabledUntil = payload.disabledUntil?.bridgeDate
        
        return dto
    }
}

extension PushPreferenceDTO {
    /// If the `PushPreferenceDTO` entity exists in the context, fetches and returns it. Otherwise create a new `PushPreferenceDTO`.
    ///
    /// - Parameter context: The context used to fetch/create `PushPreferenceDTO`
    fileprivate static func loadOrCreate(context: NSManagedObjectContext) -> PushPreferenceDTO {
        let request = NSFetchRequest<PushPreferenceDTO>(entityName: PushPreferenceDTO.entityName)
        let result = load(by: request, context: context)
        
        if let existing = result.first {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        return new
    }
}
