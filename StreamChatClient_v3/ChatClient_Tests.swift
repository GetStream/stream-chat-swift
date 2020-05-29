//
// ChatClient_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient_v3
import XCTest

class ChatClientTests: XCTestCase {
  var user: User!
  var queue: DispatchQueue!

  override func setUp() {
    super.setUp()
    user = User(id: UUID().uuidString)
    queue = DispatchQueue(label: "test_queue")
  }

  // MARK: - Database stack tests

  func test_clientDatabaseStackInitialization_whenLocalStorageEnabled_respectsConfigValues() {
    let storeFolderURL = URL.newTemporaryDirectoryURL()
    var config = ChatClientConfig()
    config.isLocalStorageEnabled = true
    config.localStorageFolderURL = storeFolderURL

    var usedDatabaseKind: DatabaseContainer.Kind?

    var env = ChatClient.Environment()
    env.databaseContainerBuilder = { kind in
      usedDatabaseKind = kind
      return DatabaseContainerMock()
    }

    _ = ChatClient(currentUser: user, config: config, workerBuilders: [], callbackQueue: queue, environment: env)
      .persistentContainer

    XCTAssertEqual(usedDatabaseKind, .onDisk(databaseFileURL: storeFolderURL.appendingPathComponent(user.id)))
  }

  func test_clientDatabaseStackInitialization_whenLocalStorageDisabled() {
    var config = ChatClientConfig()
    config.isLocalStorageEnabled = false

    var usedDatabaseKind: DatabaseContainer.Kind?

    var env = ChatClient.Environment()
    env.databaseContainerBuilder = { kind in
      usedDatabaseKind = kind
      return DatabaseContainerMock()
    }

    _ = ChatClient(currentUser: user, config: config, workerBuilders: [], callbackQueue: queue, environment: env)
      .persistentContainer

    XCTAssertEqual(usedDatabaseKind, .inMemory)
  }

  /// When the initialization of a local DB fails for some reason (i.e. incorrect URL),
  /// use a DB in the in-memory configuration
  func test_clientDatabaseStackInitialization_useInMemoryWhenOnDiskFails() {
    let storeFolderURL = URL.newTemporaryDirectoryURL()
    var config = ChatClientConfig()
    config.isLocalStorageEnabled = true
    config.localStorageFolderURL = storeFolderURL

    var usedDatabaseKinds: [DatabaseContainer.Kind] = []
    var errorsToReturn = Queue(TestError())

    var env = ChatClient.Environment()

    env.databaseContainerBuilder = { kind in
      usedDatabaseKinds.append(kind)
      // Return error for the first time
      if let error = errorsToReturn.pop() {
        throw error
      }
      // Return a new container the second time
      return DatabaseContainerMock()
    }

    _ = ChatClient(currentUser: user, config: config, workerBuilders: [], callbackQueue: queue, environment: env)
      .persistentContainer

    XCTAssertEqual(
      usedDatabaseKinds,
      [.onDisk(databaseFileURL: storeFolderURL.appendingPathComponent(user.id)), .inMemory]
    )
  }
}

// MARK: - Local helpers

private class DatabaseContainerMock: DatabaseContainer {
  init() {
    try! super.init(kind: .inMemory)
  }
}

private struct Queue<Element> {
  init(_ elements: Element...) {
    self.storage = elements
  }

  private var storage = [Element]()
  mutating func push(_ element: Element) {
    storage.append(element)
  }

  mutating func pop() -> Element? {
    let first = storage.first
    storage = Array(storage.dropFirst())
    return first
  }
}

private extension ChatClientConfig {
  init() {
    self = .init(apiKey: "test_api_key")
  }
}
