//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(PushPreferenceDTO)
class PushPreferenceDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var chatLevel: String?
    @NSManaged var disabledUntil: DBDate?
    @NSManaged var chatPreferences: ChatPreferencesDTO?
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
            chatLevel: dto.chatLevel.map { PushPreferenceLevel(rawValue: $0) },
            chatPreferences: dto.chatPreferences.map { ChatPreferences(fromDTO: $0) },
            disabledUntil: dto.disabledUntil?.bridgeDate
        )
    }
}

// MARK: Saving and loading the data

extension NSManagedObjectContext {
    func savePushPreference(id: String, payload: PushPreference) throws -> PushPreferenceDTO {
        let dto = PushPreferenceDTO.loadOrCreate(id: id, context: self)
        dto.id = id
        dto.chatLevel = payload.chatLevel.rawValue
        dto.disabledUntil = payload.disabledUntil?.bridgeDate
        dto.chatPreferences = try payload.chatPreferences.map { try saveChatPreferences(id: id, payload: $0) }
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
        load(by: id, context: context).first as? Self
    }
}
