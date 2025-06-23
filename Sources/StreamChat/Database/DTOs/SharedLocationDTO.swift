//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(SharedLocationDTO)
class SharedLocationDTO: NSManagedObject {
    @NSManaged var messageId: String
    @NSManaged var channelId: String
    @NSManaged var userId: String
    @NSManaged var deviceId: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var updatedAt: DBDate
    @NSManaged var createdAt: DBDate
    @NSManaged var endAt: DBDate?
    @NSManaged var message: MessageDTO

    override func willSave() {
        super.willSave()

        guard !isDeleted && !message.isDeleted else {
            return
        }

        // When location changed, we need to propagate this change up to holding message
        if hasPersistentChangedValues, !message.hasChanges {
            // this will not change object, but mark it as dirty, triggering updates
            message.id = message.id
        }
    }

    static func loadOrCreate(
        messageId: String,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> SharedLocationDTO {
        if let cachedObject = cache?.model(for: messageId, context: context, type: SharedLocationDTO.self) {
            return cachedObject
        }

        let request = fetchRequest(for: messageId)
        if let existing = load(by: request, context: context).first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.messageId = messageId
        return new
    }

    static func load(messageId: String, context: NSManagedObjectContext) -> SharedLocationDTO? {
        let request = fetchRequest(for: messageId)
        return load(by: request, context: context).first
    }

    static func fetchRequest(for messageId: String) -> NSFetchRequest<SharedLocationDTO> {
        let request = NSFetchRequest<SharedLocationDTO>(entityName: SharedLocationDTO.entityName)
        SharedLocationDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SharedLocationDTO.message.createdAt, ascending: false)]
        request.predicate = NSPredicate(format: "messageId == %@", messageId)
        return request
    }
}

extension SharedLocationDTO {
    func asModel() throws -> SharedLocation {
        try isNotDeleted()

        return SharedLocation(
            messageId: messageId,
            channelId: try ChannelId(cid: channelId),
            userId: userId,
            createdByDeviceId: deviceId,
            latitude: latitude,
            longitude: longitude,
            updatedAt: updatedAt.bridgeDate,
            createdAt: createdAt.bridgeDate,
            endAt: endAt?.bridgeDate
        )
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func saveLocation(payload: SharedLocationPayload, cache: PreWarmedCache?) throws -> SharedLocationDTO {
        let locationDTO = SharedLocationDTO.loadOrCreate(
            messageId: payload.messageId,
            context: self,
            cache: cache
        )

        locationDTO.messageId = payload.messageId
        locationDTO.channelId = payload.channelId
        locationDTO.deviceId = payload.createdByDeviceId
        locationDTO.latitude = payload.latitude
        locationDTO.longitude = payload.longitude
        locationDTO.endAt = payload.endAt?.bridgeDate
        locationDTO.userId = payload.userId
        locationDTO.updatedAt = payload.updatedAt.bridgeDate
        locationDTO.createdAt = payload.createdAt.bridgeDate
        return locationDTO
    }
}
