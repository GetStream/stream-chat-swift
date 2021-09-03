//
//  MessageSearchController.swift
//  StreamChat
//
//  Created by Bahadir Oncel on 02/09/2021.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    func messageSearchController(
}

public class ChatMessageSearchController: DataController, DelegateCallable, DataStoreProvider {
    public let client: ChatClient
    
    public var messages: LazyCachedMapCollection<ChatMessage> {
        startObserversIfNeeded()
        return messagesObserver?.items ?? []
    }
    
    @Cached private var messagesObserver: ListDatabaseObserver<ChatMessage, MessageDTO>?
    
    private let environment: Environment
    
    private func startObserversIfNeeded() {
        guard state == .initialized else { return }
        do {
            try messagesObserver?.startObserving()
            
            state = .localDataFetched
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            state = .localDataFetchFailed(ClientError(with: error))
        }
    }
}

extension ChatMessageSearchController {
    struct Environment {
        var messageUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> MessageUpdater = MessageUpdater.init
    }
}
