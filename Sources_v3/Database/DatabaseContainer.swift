//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Convenience subclass of `NSPersistentContainer` allowing easier setup of the database stack.
class DatabaseContainer: NSPersistentContainer {
    enum Kind: Equatable {
        /// The database lives only in memory. This option is used typically for anonymous users, when the local
        /// persistence is not enabled, or in tests.
        case inMemory
        
        /// The database file is stored on the disk and is persisted between application launches.
        case onDisk(databaseFileURL: URL)
    }
    
    lazy var writableContext: NSManagedObjectContext = {
        let context = newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    lazy var backgroundReadOnlyContext: NSManagedObjectContext = {
        let context = newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    private var loggerNotificationObserver: NSObjectProtocol?
    
    /// Creates a new `DatabaseContainer` instance.
    ///
    /// The full initialization of the container is asynchronous. Use `completion` to be notified when the container
    /// finishes its initialization.
    ///
    /// - Parameters:
    ///   - kind: The kind of `DatabaseContainer` that should be created.
    ///   - modelName: The name of the model the container loads.
    ///   - completion: Called when the container finishes its initialization. If the initialization fails, called
    ///   with an error.
    ///
    init(kind: Kind, modelName: String = "StreamChatModel", bundle: Bundle? = nil) throws {
        // It's safe to unwrap the following values because this is not settable by users and it's always a programmer error.
        let bundle = bundle ?? Bundle(for: DatabaseContainer.self)
        let modelURL = bundle.url(forResource: modelName, withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        
        super.init(name: modelName, managedObjectModel: model)
        
        let description = NSPersistentStoreDescription()
        
        switch kind {
        case .inMemory:
            description.url = URL(fileURLWithPath: "/dev/null")
        case let .onDisk(databaseFileURL: databaseFileURL):
            description.url = databaseFileURL
        }
        
        persistentStoreDescriptions = [description]
        
        var storeLoadingError: Error?
        
        loadPersistentStores { _, error in
            storeLoadingError = error
        }
        
        if let error = storeLoadingError {
            throw error
        }
        
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.automaticallyMergesChangesFromParent = true
        
        setupLoggerForDatabaseChanges()
    }
    
    deinit {
        if let observer = loggerNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /// Use this method to safely mutate the content of the database.
    ///
    /// - Parameter actions: A block that performs the actual mutation.
    func write(_ actions: @escaping (DatabaseSession) throws -> Void) {
        write(actions, completion: { _ in })
    }
    
    // This 👆 overload shouldn't be needed, but when a default parameter for completion 👇 is used,
    // the compiler gets confused and incorrectly evaluates `write { /* changes */ }`.
    
    /// Use this method to safely mutate the content of the database.
    ///
    /// - Parameters:
    ///   - actions: A block that performs the actual mutation.
    ///   - completion: Called when the changes are saved to the DB. If the changes can't be saved, called with an error.
    func write(_ actions: @escaping (DatabaseSession) throws -> Void, completion: @escaping (Error?) -> Void) {
        writableContext.perform {
            log.debug("Starting a database session.")
            do {
                try actions(self.writableContext)
                
                if self.writableContext.hasChanges {
                    log.debug("Context has changes. Saving.")
                    try self.writableContext.save()
                } else {
                    log.debug("Context has no changes. Skipping save.")
                }
                
                log.debug("Database session succesfully saved.")
                completion(nil)
                
            } catch {
                log.error("Failed to save data to DB. Error: \(error)")
                completion(error)
            }
        }
    }
    
    /// Removes all data from the local storage.
    ///
    /// - Warning: ⚠️ This is a non-recoverable operation. All data will be lost after calling this method.
    ///
    /// - Parameters:
    ///   - force: If sets to `false`, the method fails if there are unsynced data in to local storage, for example
    /// messages pedning sent. You can use this option to warn a user about potential data loss.
    ///   - completion: Called when the operation is completed. If the error is present, the operation failed.
    func removeAllData(force: Bool, completion: ((Error?) -> Void)? = nil) {
        if !force {
            fatalError("Non-force flush is not implemented.")
        }
        
        write({ session in
            let session = session as! NSManagedObjectContext
            
            try self.managedObjectModel.entities.forEach { entityDescription in
                guard let entityName = entityDescription.name else { return }
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try session.execute(deleteRequest)
            }
            
        }, completion: { completion?($0) })
    }
    
    /// Set up listener to changes in the writable context and logs the changes.
    private func setupLoggerForDatabaseChanges() {
        loggerNotificationObserver = NotificationCenter.default
            .addObserver(forName: Notification.Name.NSManagedObjectContextDidSave,
                         object: writableContext,
                         queue: nil) { log.debug("Data saved to DB: \(String(describing: $0.userInfo))") }
    }
}

// WIP

class ReadOnlyContext: NSManagedObjectContext {
    override func save() throws {
        fatalError("This context is read only!")
    }
}
