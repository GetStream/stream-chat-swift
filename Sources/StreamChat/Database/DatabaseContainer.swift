//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    static var cachedModel: NSManagedObjectModel?

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
    ) {
        let managedObjectModel: NSManagedObjectModel
        if let cachedModel = Self.cachedModel {
            managedObjectModel = cachedModel
        } else {
            // It's safe to unwrap the following values because this is not settable by users and it's always a programmer error.
            let bundle = bundle ?? Bundle(for: DatabaseContainer.self)
            let modelURL = bundle.url(forResource: modelName, withExtension: "momd")!
            let model = NSManagedObjectModel(contentsOf: modelURL)!
            managedObjectModel = model
            Self.cachedModel = model
        }

        self.localCachingSettings = localCachingSettings
        deletedMessageVisibility = deletedMessagesVisibility
        self.shouldShowShadowedMessages = shouldShowShadowedMessages

        super.init(name: modelName, managedObjectModel: managedObjectModel)

        setUpPersistentStoreDescription(with: kind)

        let persistentStoreCreatedCompletion: (Error?) -> Void = { [weak self] error in
            if let error = error {
                log.error("Failed to initialize the local storage with error: \(error). Falling back to the in-memory option.")
                self?.setUpPersistentStoreDescription(with: .inMemory)
                self?.recreatePersistentStore { error in
                    if let error = error {
                        fatalError(
                            "Failed to initialize the in-memory storage with error: \(error). This is a non-recoverable error."
                        )
                    }
                    if shouldResetEphemeralValuesOnStart {
                        self?.resetEphemeralValues()
                    }
                }
                return
            }
            if shouldResetEphemeralValuesOnStart {
                self?.resetEphemeralValues()
            }
        }

        if shouldFlushOnStart {
            recreatePersistentStore(completion: persistentStoreCreatedCompletion)
        } else {
            setupPersistentStore(completion: persistentStoreCreatedCompletion)
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

        FetchCache.clear()

        setupLoggerForDatabaseChanges()
    }

    deinit {
        if let observer = loggerNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setUpPersistentStoreDescription(with kind: Kind) {
        let description = NSPersistentStoreDescription()

        switch kind {
        case .inMemory:
            // So, it seems that on iOS 13, we have to use SQLite store with /dev/null URL, but on iOS 11 & 12
            // we have to use `NSInMemoryStoreType`.
            if #available(iOS 13, *) {
                description.url = URL(fileURLWithPath: "/dev/null")
            } else {
                description.type = NSInMemoryStoreType
            }

        case let .onDisk(databaseFileURL):
            description.url = databaseFileURL
        }

        persistentStoreDescriptions = [description]
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
                FetchCache.clear()
                try actions(self.writableContext)
                FetchCache.clear()

                for object in self.writableContext.updatedObjects {
                    if object.changedValues().isEmpty {
                        self.writableContext.refresh(object, mergeChanges: true)
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
                FetchCache.clear()
                completion(error)
            }
        }
    }

    /// Removes all data from the local storage.
    func removeAllData(completion: ((Error?) -> Void)? = nil) {
        writableContext.performAndWait { [weak self] in
            self?.writableContext.invalidateCurrentUserCache()
            let entityNames = self?.managedObjectModel.entities.compactMap(\.name)
            var deleteError: Error?
            entityNames?.forEach { [weak self] entityName in
                let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
                do {
                    try self?.writableContext.execute(deleteRequest)
                    try self?.writableContext.save()
                } catch {
                    log.error("Batch delete request failed with error \(error)")
                    deleteError = error
                }
            }
            completion?(deleteError)
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
    ///
    private func setupPersistentStore(completion: ((Error?) -> Void)? = nil) {
        loadPersistentStores { _, error in
            if let error = error {
                log.debug("Persistent store setup failed with \(error). Trying to recreate persistent store")
                self.recreatePersistentStore(completion: completion)
            } else {
                completion?(nil)
            }
        }
    }

    /// Removes the loaded persistent store and tries to recreate it.
    func recreatePersistentStore(completion: ((Error?) -> Void)? = nil) {
        log.assert(
            persistentStoreDescriptions.count == 1,
            "DatabaseContainer always assumes 1 persistent store description. Existing descriptions: \(persistentStoreDescriptions)",
            subsystems: .database
        )

        guard let storeDescription = persistentStoreDescriptions.first else {
            completion?(ClientError("No persistent store descriptions available."))
            return
        }

        log.debug("Removing DB persistent store", subsystems: .database)

        // Remove all loaded persistent stores first
        do {
            try persistentStoreCoordinator.persistentStores.forEach { store in
                try persistentStoreCoordinator.remove(store)
            }
        } catch {
            completion?(error)
            return
        }

        log.debug("Removing DB file", subsystems: .database)

        // If the store was SQLite store, remove the actual DB file
        if storeDescription.type == NSSQLiteStoreType,
           let storeURL = storeDescription.url,
           storeURL.absoluteString.hasSuffix("/dev/null") == false {
            do {
                try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
            } catch {
                completion?(error)
                return
            }
        }

        log.debug("Reloading persistent store", subsystems: .database)

        loadPersistentStores { _, error in
            if let error = error {
                log.error("Persistent store reload error: \(error)")
            } else {
                log.debug("Persistent store reloaded")
            }
            completion?(error)
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
                FetchCache.clear()
                try writableContext.save()
                log.debug("Ephemeral values reset.", subsystems: .database)
            } catch {
                FetchCache.clear()
                log.error("Error resetting ephemeral values: \(error)", subsystems: .database)
            }
        }
    }
}

extension NSManagedObjectContext {
    /// Discards any changes on the passed object that are pending to be saved.
    func discardChanges(for object: NSManagedObject) {
        refresh(object, mergeChanges: false)
    }

    func discardCurrentChanges() {
        insertedObjects.forEach { discardChanges(for: $0) }
        updatedObjects.forEach { discardChanges(for: $0) }
        deletedObjects.forEach { discardChanges(for: $0) }
    }
}
