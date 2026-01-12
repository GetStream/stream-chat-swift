//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class MockAppStateObserver: AppStateObserving, Spy {
    public let spyState = SpyState()

    public private(set) var subscribeWasCalledWithSubscriber: AppStateObserverDelegate?
    public private(set) var unsubscribeWasCalledWithSubscriber: AppStateObserverDelegate?

    public init() {}

    public func subscribe(_ subscriber: AppStateObserverDelegate) {
        record()
        subscribeWasCalledWithSubscriber = subscriber
    }

    public func unsubscribe(_ subscriber: AppStateObserverDelegate) {
        record()
        unsubscribeWasCalledWithSubscriber = subscriber
    }
}
