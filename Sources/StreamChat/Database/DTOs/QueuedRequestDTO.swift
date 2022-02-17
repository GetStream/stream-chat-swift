//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(QueuedRequestDTO)
class QueuedRequestDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var date: Date
    @NSManaged var endpoint: Data

    @discardableResult
    static func createRequest(
        id: String = .newUniqueId,
        date: Date,
        endpoint: Data,
        context: NSManagedObjectContext
    ) -> QueuedRequestDTO {
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! QueuedRequestDTO
        new.id = id
        new.date = date
        new.endpoint = endpoint
        return new
    }

    static func loadAllPendingRequests(context: NSManagedObjectContext) -> [QueuedRequestDTO] {
        let request = NSFetchRequest<QueuedRequestDTO>(entityName: QueuedRequestDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \QueuedRequestDTO.date, ascending: true)]
        return load(by: request, context: context)
    }

    static func load(id: String, context: NSManagedObjectContext) -> QueuedRequestDTO? {
        let request = NSFetchRequest<QueuedRequestDTO>(entityName: entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return load(by: request, context: context).first
    }
}

extension NSManagedObjectContext: QueuedRequestDatabaseSession {
    func deleteQueuedRequest(id: String) {
        guard let request = QueuedRequestDTO.load(id: id, context: self) else { return }
        delete(request)
    }
}
