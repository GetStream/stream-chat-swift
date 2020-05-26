//
// Worker.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

typealias WorkerBuilder = (
  _ storageContext: NSManagedObjectContext,
  _ webSocketClient: WebSocketClient,
  _ apiClient: APIClient
) -> Worker

// Do we need this?
protocol Worker {
  init(storageContext: NSManagedObjectContext, webSocketClient: WebSocketClient, apiClient: APIClient)
}
