//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(PushPreferenceDTO)
class PushPreferenceDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var chatLevel: String
    @NSManaged var disabledUntil: DBDate?
    @NSManaged var currentUser: CurrentUserDTO?
    @NSManaged var channel: ChannelDTO?

    override func willSave() {
        super.willSave()

        // Trigger currentUser update whenever push preference is updated.
        if let currentUser = self.currentUser, hasPersistentChangedValues, !currentUser.hasChanges {
            currentUser.unreadMessagesCount = currentUser.unreadMessagesCount
        }

        // Trigger currentUser update whenever push preference is updated.
        if let channel = self.channel, hasPersistentChangedValues, !channel.hasChanges {
            channel.id = channel.id
        }
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
    func savePushPreference(id: String, payload: PushPreferencePayload) throws -> PushPreferenceDTO {
        let dto = PushPreferenceDTO.loadOrCreate(id: id, context: self)
        dto.id = id
        dto.chatLevel = payload.chatLevel
        dto.disabledUntil = payload.disabledUntil?.bridgeDate
        return dto
    }
}

extension PushPreferenceDTO {
    static func loadOrCreate(id: String, context: NSManagedObjectContext) -> PushPreferenceDTO {
        if let existing = load(id: id, context: context) {
            return existing
        }

        let request = fetchRequest(id: id)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = id
        return new
    }

    static func load(id: String, context: NSManagedObjectContext) -> PushPreferenceDTO? {
        load(by: id, context: context).first
    }
}
