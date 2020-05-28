//
//  SharedClient.swift
//  StreamChatClientTests
//
//  Created by Bahadir Oncel on 12.05.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient

// This needs to be used in unit tests instead of Client.shared
// since we can't configure the shared more than once
let sharedClient: Client = {
    Client.configureShared(.init(apiKey: "test-shared-client"))
    return Client.shared
}()
