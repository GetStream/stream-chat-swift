//
// MessageSender.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Observers the storage for messages pending send and sends them.
class MessageSender: Worker {
  unowned let context: NSManagedObjectContext
  unowned let webSocketClient: WebSocketClient
  unowned let apiClient: APIClient

  required init(storageContext: NSManagedObjectContext, webSocketClient: WebSocketClient, apiClient: APIClient) {
    self.context = storageContext
    self.webSocketClient = webSocketClient
    self.apiClient = apiClient
  }
}
