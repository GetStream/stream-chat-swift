//
//  MessagesPaginationStateHandler_Mock.swift
//  StreamChatTestTools
//
//  Created by Nuno Vieira on 05/05/2023.
//  Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class MessagesPaginationStateHandler_Mock: MessagesPaginationStateHandling, @unchecked Sendable {

    @Atomic var mockState: MessagesPaginationState = .initial

    @Atomic var beginCallCount = 0
    @Atomic var beginCalledWith: MessagesPagination?

    @Atomic var endCallCount = 0
    @Atomic var endCalledWith: (MessagesPagination, Result<[MessagePayload], Error>)?

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
