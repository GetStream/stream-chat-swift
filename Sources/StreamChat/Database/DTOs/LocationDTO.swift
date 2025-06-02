//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(LocationDTO)
class LocationDTO: NSManagedObject {
    @NSManaged var messageId: String
    @NSManaged var channelId: String
    @NSManaged var deviceId: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var endAt: DBDate?
    @NSManaged var message: MessageDTO

    static func loadOrCreate(
        messageId: String,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> LocationDTO {
        if let cachedObject = cache?.model(for: messageId, context: context, type: LocationDTO.self) {
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

    static func load(messageId: String, context: NSManagedObjectContext) -> LocationDTO? {
        let request = fetchRequest(for: messageId)
        return load(by: request, context: context).first
    }

    static func fetchRequest(for messageId: String) -> NSFetchRequest<LocationDTO> {
        let request = NSFetchRequest<LocationDTO>(entityName: LocationDTO.entityName)
        LocationDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LocationDTO.message.createdAt, ascending: false)]
        request.predicate = NSPredicate(format: "messageId == %@", messageId)
        return request
    }
}

extension LocationDTO {
    func asModel() throws -> SharedLocation {
        try isNotDeleted()

        return SharedLocation(
            messageId: messageId,
            channelId: try ChannelId(cid: channelId),
            latitude: latitude,
            longitude: longitude,
            endAt: endAt?.bridgeDate,
            createdByDeviceId: deviceId
        )
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func saveLocation(payload: SharedLocationPayload, cache: PreWarmedCache?) throws -> LocationDTO {
        let locationDTO = LocationDTO.loadOrCreate(
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
        return locationDTO
    }
}
