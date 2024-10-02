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
    
    /// An immediately reacting NSManagedObjectContext for the chat state layer.
    ///
    /// Chat state layer requires that the context is refreshed when a write happens. Otherwise database observers are too slow to react.
    ///
    /// For example, here the state.messages needs to react before loadMessages finishes.
    /// ```swift
    /// try await chat.loadMessages()
    /// let messages = chat.state.messages
    /// ```
    private(set) lazy var stateLayerContext: NSManagedObjectContext = {
        let context = newBackgroundContext()
        // Context is merged manually since automatically is too slow for reacting to changes needed by the state layer
        context.automaticallyMergesChangesFromParent = false
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.perform { [localCachingSettings, deletedMessageVisibility, shouldShowShadowedMessages] in
            context.localCachingSettings = localCachingSettings
            context.deletedMessagesVisibility = deletedMessageVisibility
            context.shouldShowShadowedMessages = shouldShowShadowedMessages
        }
        stateLayerContextRefreshObservers = [
            context.observeChanges(in: writableContext),
            context.observeChanges(in: viewContext)
        ]
        return context
    }()

    private var stateLayerContextRefreshObservers = [NSObjectProtocol]()
    private var loggerNotificationObserver: NSObjectProtocol?
    private let localCachingSettings: ChatClientConfig.LocalCaching?
    private let deletedMessageVisibility: ChatClientConfig.DeletedMessageVisibility?
    private let shouldShowShadowedMessages: Bool?

    static var cachedModels = [String: NSManagedObjectModel]()

    /// All `NSManagedObjectContext`s this container owns.
    private(set) lazy var allContext: [NSManagedObjectContext] = [viewContext, backgroundReadOnlyContext, stateLayerContext, writableContext]

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
        if let cachedModel = Self.cachedModels[modelName] {
            managedObjectModel = cachedModel
        } else {
            // It's safe to unwrap the following values because this is not settable by users and it's always a programmer error.
            let bundle = bundle ?? Bundle(for: DatabaseContainer.self)
            let modelURL = bundle.url(forResource: modelName, withExtension: "momd")!
            let model = NSManagedObjectModel(contentsOf: modelURL)!
            managedObjectModel = model
            Self.cachedModels[modelName] = model
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
        stateLayerContextRefreshObservers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = loggerNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setUpPersistentStoreDescription(with kind: Kind) {
        let description = NSPersistentStoreDescription()

        switch kind {
        case .inMemory:
            description.url = URL(fileURLWithPath: "/dev/null")

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

                // Refresh the state by merging persistent state and local state for avoiding optimistic locking failure
                for object in self.writableContext.updatedObjects {
                    self.writableContext.refresh(object, mergeChanges: true)
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
                self.writableContext.reset()
                FetchCache.clear()
                completion(error)
            }
        }
    }
    
    func write(_ actions: @escaping (DatabaseSession) throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            write(actions) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
        
    private func read<T>(
        from context: NSManagedObjectContext,
        _ actions: @escaping (DatabaseSession) throws -> T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        context.perform {
            do {
                let changeCounts = context.currentChangeCounts()
                let results = try actions(context)
                if changeCounts != context.currentChangeCounts() {
                    assertionFailure("Context is read only, but actions created changes: (updated=\(context.updatedObjects), inserted=\(context.insertedObjects), deleted=\(context.deletedObjects)")
                }
                completion(.success(results))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func read<T>(_ actions: @escaping (DatabaseSession) throws -> T, completion: @escaping (Result<T, Error>) -> Void) {
        read(from: backgroundReadOnlyContext, actions, completion: completion)
    }
    
    func read<T>(_ actions: @escaping (DatabaseSession) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            read(from: stateLayerContext, actions) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Removes all data from the local storage.
    func removeAllData(completion: ((Error?) -> Void)? = nil) {
        let entityNames = managedObjectModel.entities.compactMap(\.name)
        writableContext.perform { [weak self] in
            let requests = entityNames
                .map { NSFetchRequest<NSFetchRequestResult>(entityName: $0) }
                .map { fetchRequest in
                    let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    batchDelete.resultType = .resultTypeObjectIDs
                    return batchDelete
                }
            var lastEncounteredError: Error?
            var deletedObjectIds = [NSManagedObjectID]()
            for request in requests {
                do {
                    let result = try self?.writableContext.execute(request) as? NSBatchDeleteResult
                    if let objectIds = result?.result as? [NSManagedObjectID] {
                        deletedObjectIds.append(contentsOf: objectIds)
                    }
                } catch {
                    log.error("Batch delete request failed with error \(error)")
                    lastEncounteredError = error
                }
            }
            if !deletedObjectIds.isEmpty, let contexts = self?.allContext {
                log.debug("Merging \(deletedObjectIds.count) deletions to contexts", subsystems: .database)
                // Merging changes triggers DB observers to react to deletions which clears the state
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: deletedObjectIds],
                    into: contexts
                )
            }
            // Finally reset states of all the contexts after batch delete and deletion propagation.
            if let writableContext = self?.writableContext, let allContext = self?.allContext {
                writableContext.invalidateCurrentUserCache()
                writableContext.reset()
                
                for context in allContext where context != writableContext {
                    context.performAndWait {
                        context.invalidateCurrentUserCache()
                        context.reset()
                    }
                }
                
                if FileManager.default.fileExists(atPath: URL.streamAttachmentDownloadsDirectory.path) {
                    do {
                        try FileManager.default.removeItem(at: .streamAttachmentDownloadsDirectory)
                    } catch {
                        log.debug("Failed to remove local downloads", subsystems: .database)
                    }
                }
            }
            completion?(lastEncounteredError)
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
    
    fileprivate func currentChangeCounts() -> [String: Int] {
        [
            "inserted": insertedObjects.count,
            "updated": updatedObjects.count,
            "deleted": deletedObjects.count
        ]
    }
    
    func observeChanges(in otherContext: NSManagedObjectContext) -> NSObjectProtocol {
        assert(!automaticallyMergesChangesFromParent, "Duplicate change handling")
        return NotificationCenter.default
            .addObserver(
                forName: Notification.Name.NSManagedObjectContextDidSave,
                object: otherContext,
                queue: nil
            ) { [weak self] notification in
                guard let self else { return }
                self.performAndWait {
                    self.mergeChanges(fromContextDidSave: notification)
                    // Keep the state clean after merging changes
                    guard self.hasChanges else { return }
                    self.perform {
                        do {
                            try self.save()
                        } catch {
                            log.debug("Failed to save merged changes", subsystems: .database)
                        }
                    }
                }
            }
    }
}
