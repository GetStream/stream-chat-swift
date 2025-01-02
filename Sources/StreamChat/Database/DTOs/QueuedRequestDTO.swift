//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(QueuedRequestDTO)
class QueuedRequestDTO: NSManagedObject {
    @NSManaged private(set) var id: String
    @NSManaged private(set) var date: DBDate
    @NSManaged private(set) var endpoint: Data

    @discardableResult
    static func createRequest(
        id: String = .newUniqueId,
        date: Date,
        endpoint: Data,
        context: NSManagedObjectContext
    ) -> QueuedRequestDTO {
        let request = fetchRequest(id: id)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = id
        new.date = date.bridgeDate
        new.endpoint = endpoint
        return new
    }

    static func loadAllPendingRequests(context: NSManagedObjectContext) -> [QueuedRequestDTO] {
        let request = NSFetchRequest<QueuedRequestDTO>(entityName: QueuedRequestDTO.entityName)
        QueuedRequestDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \QueuedRequestDTO.date, ascending: true)]
        return load(by: request, context: context)
    }

    static func load(id: String, context: NSManagedObjectContext) -> QueuedRequestDTO? {
        let request = NSFetchRequest<QueuedRequestDTO>(entityName: entityName)
        QueuedRequestDTO.applyPrefetchingState(to: request)
        request.predicate = NSPredicate(format: "id == %@", id)
        return load(by: request, context: context).first
    }
}

extension NSManagedObjectContext: QueuedRequestDatabaseSession {
    func allQueuedRequests() -> [QueuedRequestDTO] {
        QueuedRequestDTO.loadAllPendingRequests(context: self)
    }
    
    func deleteQueuedRequest(id: String) {
        guard let request = QueuedRequestDTO.load(id: id, context: self) else { return }
        delete(request)
    }
}
