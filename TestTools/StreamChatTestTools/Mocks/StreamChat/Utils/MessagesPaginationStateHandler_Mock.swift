//
//  MessagesPaginationStateHandler_Mock.swift
//  StreamChatTestTools
//
//  Created by Nuno Vieira on 05/05/2023.
//  Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class MessagesPaginationStateHandler_Mock: MessagesPaginationStateHandling {

    var mockState: MessagesPaginationState = .initial

    var beginCallCount = 0
    var beginCalledWith: MessagesPagination?

    var endCallCount = 0
    var endCalledWith: (MessagesPagination, Result<[MessagePayload], Error>)?

    var state: MessagesPaginationState {
        mockState
    }

    func begin(pagination: MessagesPagination) {
        beginCallCount += 1
        beginCalledWith = pagination
    }

    func end(pagination: MessagesPagination, with result: Result<[MessagePayload], Error>) {
        endCallCount += 1
        endCalledWith = (pagination, result)
    }

}
