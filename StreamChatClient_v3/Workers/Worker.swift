//
// Worker.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

typealias WorkerBuilder = (
  _ database: DatabaseContainer,
  _ webSocketClient: WebSocketClient,
  _ apiClient: APIClient
) -> Worker

// This is a super-class instead of protocol because we need to be sure, `unowned` is used for socket client and api client
class Worker: NSObject { // TODO: remove NSObject
  unowned let database: DatabaseContainer
  unowned let webSocketClient: WebSocketClient
  unowned let apiClient: APIClient

  init(database: DatabaseContainer, webSocketClient: WebSocketClient, apiClient: APIClient) {
    self.database = database
    self.webSocketClient = webSocketClient
    self.apiClient = apiClient
    super.init()
  }
}

/// A convenience superclass for all event-based workers. Not meant to be used directly. Override `handleNewEvent(event: Event)`
/// and provide your custom logic there.
class EventHandlerWorker<ExtraData: ExtraDataTypes>: Worker {
  override init(database: DatabaseContainer, webSocketClient: WebSocketClient, apiClient: APIClient) {
    super.init(database: database, webSocketClient: webSocketClient, apiClient: apiClient)

    webSocketClient.notificationCenter
      .addObserver(self, selector: #selector(handleNewEventNotification), name: .NewEventReceived, object: nil)
  }

  @objc
  private func handleNewEventNotification(_ notification: Notification) {
    guard let event = notification.event else {
      print("Error: NewEventNotification without an Event.")
      return
    }
    handleNewEvent(event: event)
  }

  func handleNewEvent(event: Event) {
    fatalError("handleNewEvent needs to be overriden")
  }
}
