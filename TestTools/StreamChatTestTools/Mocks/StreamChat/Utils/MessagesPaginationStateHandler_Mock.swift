//
//  MessagesPaginationStateHandler_Mock.swift
//  StreamChatTestTools
//
//  Created by Nuno Vieira on 05/05/2023.
//  Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class MessagesPaginationStateHandler_Mock: MessagesPaginationStateHandling {

    var mockState: MessagesPaginationState = .initial

    var startCallCount = 0
    var startCalledWith: MessagesPagination?

    var endCallCount = 0
    var endCalledWith: (MessagesPagination, Result<[MessagePayload], Error>)?

    var state: MessagesPaginationState {
        mockState
    }

    func start(pagination: MessagesPagination) {
        startCallCount += 1
        startCalledWith = pagination
    }

    func end(pagination: MessagesPagination, with result: Result<[MessagePayload], Error>) {
        endCallCount += 1
        endCalledWith = (pagination, result)
    }

}
