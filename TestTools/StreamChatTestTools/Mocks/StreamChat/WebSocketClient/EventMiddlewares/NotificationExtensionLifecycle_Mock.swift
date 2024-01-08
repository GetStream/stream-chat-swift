//
//  NotificationExtensionLifecycle_Mock.swift
//  StreamChatTests
//
//  Created by Pol Quintana on 7/2/23.
//  Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class NotificationExtensionLifecycle_Mock: NotificationExtensionLifecycle {

    var mockIsAppReceivingWebSocketEvents: Bool?
    var receivedIsReceivingEvents: Bool?

    override var isAppReceivingWebSocketEvents: Bool {
        mockIsAppReceivingWebSocketEvents ?? false
    }

    override func setAppState(isReceivingEvents: Bool) {
        receivedIsReceivingEvents = isReceivingEvents
    }
}
