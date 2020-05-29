//
// DatabaseContainer.swift
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
  init(kind: Kind, modelName: String = "StreamChatModel") throws {
    // It's safe to unwrap the following values because this is not settable by users and it's always a programmer error.
    let modelURL = Bundle(for: DatabaseContainer.self).url(forResource: modelName, withExtension: "momd")!
    let model = NSManagedObjectModel(contentsOf: modelURL)!

    super.init(name: modelName, managedObjectModel: model)

    let description = NSPersistentStoreDescription()

    switch kind {
    case .inMemory:
      description.url = URL(fileURLWithPath: "/dev/null")
    case .onDisk(databaseFileURL: let databaseFileURL):
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
  }
}

extension DatabaseContainer {
  /// Use this method to safely mutate the content of the database.
  func write(_ actions: @escaping (DatabaseSession) -> Void) {
    writableContext.perform {
      actions(self.writableContext)

      if self.writableContext.hasChanges {
        do {
          try self.writableContext.save()
          print("Saved")
        } catch {
          fatalError("\(error)")
        }
      }
    }
  }
}

extension NSManagedObjectContext: DatabaseSession {}

protocol DatabaseSession {
  // MARK: -  User model

  func saveUser<ExtraUserData: Codable & Hashable>(_ user: UserModel<ExtraUserData>)
  func saveUser<ExtraUserData: Codable & Hashable>(endpointResponse response: UserEndpointReponse<ExtraUserData>)
  func loadUser<ExtraUserData: Codable & Hashable>(id: String) -> UserModel<ExtraUserData>?

  // MARK: -  Channel model

  func saveChannel<ExtraData: ExtraDataTypes>(_ channel: ChannelModel<ExtraData>)
  func saveChannel<ExtraData: ExtraDataTypes>(endpointResponse response: ChannelEndpointResponse<ExtraData>)
  func loadChannel<ExtraData: ExtraDataTypes>(id: String) -> ChannelModel<ExtraData>?
}

protocol LoadableEntity {
  associatedtype DTOEntity
  init(fromDTO entity: DTOEntity)
}

// WIP

class ReadOnlyContext: NSManagedObjectContext {
  override func save() throws {
    fatalError("This context is read only!")
  }
}
