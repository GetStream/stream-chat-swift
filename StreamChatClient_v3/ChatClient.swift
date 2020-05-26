//
// ChatClient.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public final class ChatClient {
  // MARK: - Public

  public let currentUser: User

  public let config: Config

  public convenience init(currentUser: User, config: ChatClient.Config = .init()) {
    // All production workers
    let workers: [WorkerBuilder] = [
      MessageSender.init
    ]

    self.init(
      currentUser: currentUser,
      config: config,
      workers: workers,
      environment: .init()
    )
  }

  // MARK: - Internal

  struct Environment {
    var apiClientBuilder: (_ currentUser: User) -> APIClient = APIClient.init
    var webSocketClientBuilder: (_ currentUser: User) -> WebSocketClient = WebSocketClient.init
  }

  var workers: [Worker]! // TODO: make `let` or `private(set) lazy var`

  private let environment: Environment

  private lazy var apiClient: APIClient = self.environment.apiClientBuilder(self.currentUser)

  private lazy var webSocketClient: WebSocketClient = self.environment.webSocketClientBuilder(self.currentUser)

  private lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "StreamChatModel")

    let description = NSPersistentStoreDescription()
    // TODO: Something like this?
    if currentUser.isAnonymous || config.isLocalStorageEnabled == false {
      // Use only in-memory store
      description.url = URL(fileURLWithPath: "/dev/null")
    } else {
      // TODO: Sanitize ID to be safe for URL
      description.url = config.localStorageFolderURL.appendingPathComponent(currentUser.id)
    }

    container.persistentStoreDescriptions = [description]

    container.loadPersistentStores { _, error in
      if let error = error {
        // TODO: When this happens and how to handle this?
        fatalError("Unable to load persistent stores: \(error)")
      }
      container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
      container.viewContext.automaticallyMergesChangesFromParent = true
    }
    return container
  }()

  init(currentUser: User, config: ChatClient.Config = .init(), workers: [WorkerBuilder], environment: Environment) {
    self.config = config
    self.currentUser = currentUser
    self.environment = environment

    // TODO: This can be expensive. Ideally, we should run this on a background thread
    self.workers = workers.map { builder in
      builder(
        persistentContainer.newBackgroundContext(),
        webSocketClient,
        apiClient
      )
    }
  }
}
