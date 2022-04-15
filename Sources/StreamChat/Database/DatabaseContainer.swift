//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

    /// A notification with this name is posted by every `NSManagedObjectContext` before all its data is flushed.
    ///
    /// This is needed because flushing all data is done by resetting the persistent store, and it's not reflected in the contexts.
    /// All observers of the context should listen to this notification, and generate a deletion callback when the notification
    /// is received.
    ///
    static let WillRemoveAllDataNotification =
        Notification.Name(rawValue: "co.getStream.iOSChatSDK.DabaseContainer.WillRemoveAllDataNotification")

    /// A notification with this name is posted by every `NSManagedObjectContext` after all its data is flushed.
    ///
    /// This is needed because flushing all data is done by resetting the persistent store, and it's not reflected in the contexts.
    /// All observers of the context should listen to this notification, and reset all NSFetchedResultControllers observing
    /// the contexts.
    ///
    static let DidRemoveAllDataNotification =
        Notification.Name(rawValue: "co.getStream.iOSChatSDK.DabaseContainer.DidRemoveAllDataNotification")

    /// We use `writableContext` for having just one place to save changes
    /// so it’s not possible to have conflicts when saving payloads from various sources.
    /// All writes are happening serially using this context and its `write { }` methods.
    lazy var writableContext: NSManagedObjectContext = {
        let context = newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.perform { [localCachingSettings, deletedMessageVisibility, shouldShowShadowedMessages] in
            context.localCachingSettings = localCachingSettings
            context.deletedMessagesVisibility = deletedMessageVisibility
            context.shouldShowShadowedMessages = shouldShowShadowedMessages
            // Setting the undo manager to nil means that:
            // - You don’t waste effort recording undo actions for changes (such as insertions) that will not be undone;
            // - The undo manager doesn’t maintain strong references to changed objects and so prevent them from being deallocated
            context.undoManager = nil
        }
        return context
    }()
    
    /// This is the same thing as `viewContext` only it doesn’t run on main thread.
    /// It’s just an optimization for removing as much as possible from the main thread.
    ///
    /// Updating DTOs from this context will lead to issues.
    /// Use `writableContext` to mutate database entities.
    ///
    /// Use this context to observe non-time sensitive changes.
    /// If you need a time sensitive context, use `viewContext` instead.
    lazy var backgroundReadOnlyContext: NSManagedObjectContext = {
        let context = newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.perform { [localCachingSettings, deletedMessageVisibility, shouldShowShadowedMessages] in
            context.localCachingSettings = localCachingSettings
            context.deletedMessagesVisibility = deletedMessageVisibility
            context.shouldShowShadowedMessages = shouldShowShadowedMessages
        }
        return context
    }()
    
    private var loggerNotificationObserver: NSObjectProtocol?
    private let localCachingSettings: ChatClientConfig.LocalCaching?
    private let deletedMessageVisibility: ChatClientConfig.DeletedMessageVisibility?
    private let shouldShowShadowedMessages: Bool?
    
    /// All `NSManagedObjectContext`s this container owns.
    private lazy var allContext: [NSManagedObjectContext] = [viewContext, backgroundReadOnlyContext, writableContext]
    
    /// Creates a new `DatabaseContainer` instance.
    ///
    /// The full initialization of the container is asynchronous. Use `completion` to be notified when the container
    /// finishes its initialization.
    ///
    /// - Parameters:
    ///   - kind: The kind of `DatabaseContainer` that should be created.
    ///   - shouldFlushOnStart: Flag indicating that all local data should be deleted on `DatabaseContainer` creation.
    ///   (non-recoverable operation)
    ///   - modelName: The name of the model the container loads.
    ///   - localCachingSettings: The defaults used for model serialization.
    ///
    init(
        kind: Kind,
        shouldFlushOnStart: Bool = false,
        shouldResetEphemeralValuesOnStart: Bool = true,
        modelName: String = "StreamChatModel",
        bundle: Bundle? = .streamChat,
        localCachingSettings: ChatClientConfig.LocalCaching? = nil,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility? = nil,
        shouldShowShadowedMessages: Bool? = nil
    ) throws {
        // It's safe to unwrap the following values because this is not settable by users and it's always a programmer error.
        let bundle = bundle ?? Bundle(for: DatabaseContainer.self)
        let modelURL = bundle.url(forResource: modelName, withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        
        self.localCachingSettings = localCachingSettings
        deletedMessageVisibility = deletedMessagesVisibility
        self.shouldShowShadowedMessages = shouldShowShadowedMessages

        super.init(name: modelName, managedObjectModel: model)
        
        let description = NSPersistentStoreDescription()
        
        switch kind {
        case .inMemory:
            // So, it seems that on iOS 13, we have to use SQLite store with /dev/null URL, but on iOS 11 & 12
            // we have to use `NSInMemoryStoreType`. This is not, of course, documented anywhere because no one in
            // Apple is obviously that crazy, to write tests with CoreData stack.
            if #available(iOS 13, *) {
                description.url = URL(fileURLWithPath: "/dev/null")
            } else {
                description.type = NSInMemoryStoreType
            }
            
        case let .onDisk(databaseFileURL: databaseFileURL):
            description.url = databaseFileURL
        }
        
        persistentStoreDescriptions = [description]
                
        if shouldFlushOnStart {
            try recreatePersistentStore()
        } else {
            try setupPersistentStore()
        }
        
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.automaticallyMergesChangesFromParent = true
        if Thread.current.isMainThread {
            viewContext.localCachingSettings = localCachingSettings
            viewContext.deletedMessagesVisibility = deletedMessagesVisibility
            viewContext.shouldShowShadowedMessages = shouldShowShadowedMessages
        } else {
            viewContext.perform { [viewContext, localCachingSettings, deletedMessagesVisibility, shouldShowShadowedMessages] in
                viewContext.localCachingSettings = localCachingSettings
                viewContext.deletedMessagesVisibility = deletedMessagesVisibility
                viewContext.shouldShowShadowedMessages = shouldShowShadowedMessages
            }
        }
        
        setupLoggerForDatabaseChanges()
        
        if shouldResetEphemeralValuesOnStart {
            resetEphemeralValues()
        }
    }
    
    deinit {
        if let observer = loggerNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /// Use this method to safely mutate the content of the database. This method is asynchronous.
    ///
    /// - Parameter actions: A block that performs the actual mutation.
    func write(_ actions: @escaping (DatabaseSession) throws -> Void) {
        write(actions, completion: { _ in })
    }
    
    // This 👆 overload shouldn't be needed, but when a default parameter for completion 👇 is used,
    // the compiler gets confused and incorrectly evaluates `write { /* changes */ }`.
    
    /// Use this method to safely mutate the content of the database. This method is asynchronous.
    ///
    /// - Parameters:
    ///   - actions: A block that performs the actual mutation.
    ///   - completion: Called when the changes are saved to the DB. If the changes can't be saved, called with an error.
    func write(_ actions: @escaping (DatabaseSession) throws -> Void, completion: @escaping (Error?) -> Void) {
        writableContext.perform {
            log.debug("Starting a database session.", subsystems: .database)
            do {
                self.writableContext.flushCache()
                try actions(self.writableContext)
                // If you touch ManagedObject and update one of it properties to same value
                // Object will be marked as `updated` even it hasn't changed.
                // By reseting such objects we remove updates that are not updates.
                for object in self.writableContext.updatedObjects {
                    if object.changedValues().isEmpty {
                        self.writableContext.refresh(object, mergeChanges: false)
                    }
                }

                if self.writableContext.hasChanges {
                    log.debug("Context has changes. Saving.", subsystems: .database)
                    try self.writableContext.save()
                } else {
                    log.debug("Context has no changes. Skipping save.", subsystems: .database)
                }
                
                log.debug("Database session succesfully saved.", subsystems: .database)
                completion(nil)
                
            } catch {
                log.error("Failed to save data to DB. Error: \(error)", subsystems: .database)
                completion(error)
            }
        }
    }
    
    /// Removes all data from the local storage.
    ///
    /// Invoking this method will cause `WillRemoveAllDataNotification` being send by all contexts of the container.
    ///
    /// - Warning: ⚠️ This is a non-recoverable operation. All data will be lost after calling this method.
    ///
    /// - Parameters:
    ///   - force: If sets to `false`, the method fails if there are unsynced data in to local storage, for example
    /// messages pedning sent. You can use this option to warn a user about potential data loss.
    ///   - completion: Called when the operation is completed. If the error is present, the operation failed.
    ///
    func removeAllData(force: Bool = true) throws {
        if !force {
            fatalError("Non-force flush is not implemented yet.")
        }
        
        sendNotificationForAllContexts(name: Self.WillRemoveAllDataNotification)

        // If the current persistent store is a SQLite store, this method will reset and recreate it.
        try recreatePersistentStore()

        sendNotificationForAllContexts(name: Self.DidRemoveAllDataNotification)
    }
    
    private func sendNotificationForAllContexts(name: Notification.Name) {
        // Make sure the notifications are sent synchronously on the main thread to give enough time to notification
        // listeners to react on it.
        DispatchQueue.performSynchronouslyOnMainQueue {
            allContext.forEach {
                NotificationCenter.default.post(.init(name: name, object: $0, userInfo: nil))
            }
        }
    }

    /// Set up listener to changes in the writable context and logs the changes.
    private func setupLoggerForDatabaseChanges() {
        loggerNotificationObserver = NotificationCenter.default
            .addObserver(
                forName: Notification.Name.NSManagedObjectContextDidSave,
                object: writableContext,
                queue: nil
            ) { log.debug("Data saved to DB: \(String(describing: $0.userInfo))", subsystems: .database) }
    }
    
    /// Tries to load a persistent store.
    ///
    /// If it fails, for example because of non-matching models, it removes the store, recreates is, and tries to load it again.
    /// If the second loading fails, too, it throws an error.
    ///
    private func setupPersistentStore() throws {
        var storeLoadingError: Error?
        
        loadPersistentStores { _, error in
            storeLoadingError = error
        }
        
        if storeLoadingError != nil {
            try recreatePersistentStore()
        }
    }
    
    /// Removes the loaded persistent store and tries to recreate it.
    func recreatePersistentStore() throws {
        log.assert(
            persistentStoreDescriptions.count == 1,
            "DatabaseContainer always assumes 1 persistent store description. Existing descriptions: \(persistentStoreDescriptions)",
            subsystems: .database
        )
        
        guard let storeDescription = persistentStoreDescriptions.first else {
            throw ClientError("No persisten store descriptions available.")
        }

        // Remove all loaded persistent stores first
        try persistentStoreCoordinator.persistentStores.forEach { store in
            try persistentStoreCoordinator.remove(store)
        }
        
        // If the store was SQLite store, remove the actual DB file
        if storeDescription.type == NSSQLiteStoreType,
           let storeURL = storeDescription.url,
           storeURL.absoluteString.hasSuffix("/dev/null") == false {
            try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
            try FileManager.default.removeItem(at: storeURL)
        }
    
        var storeLoadingError: Error?
        
        loadPersistentStores { _, error in
            storeLoadingError = error
        }
        
        if let error = storeLoadingError {
            throw error
        }
    }
    
    /// Iterates over all items and if the DTO conforms to `EphemeralValueContainers` calls `resetEphemeralValues()` on
    /// every object.
    func resetEphemeralValues() {
        writableContext.performAndWait {
            do {
                try self.managedObjectModel.entities.forEach { entityDescription in
                    guard let entityName = entityDescription.name else { return }
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
                    let entities = try writableContext.fetch(fetchRequest) as? [EphemeralValuesContainer]
                    entities?.forEach { $0.resetEphemeralValues() }
                }
                try writableContext.save()
                log.debug("Ephemeral values reset.", subsystems: .database)
            } catch {
                log.error("Error resetting ephemeral values: \(error)", subsystems: .database)
            }
        }
    }
}
