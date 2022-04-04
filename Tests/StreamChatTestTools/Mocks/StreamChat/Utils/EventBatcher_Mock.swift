//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class EventBatcher_Mock: EventBatcher {
    var currentBatch: [Event] = []
    
    let handler: ([Event]) -> Void
    
    init(
        period: TimeInterval = 0,
        timerType: StreamChat.Timer.Type = DefaultTimer.self,
        handler: @escaping ([Event]) -> Void
    ) {
        self.handler = handler
    }
    
    lazy var mock_append = MockFunc.mock(for: append)
    
    func append(_ event: Event) {
        mock_append.call(with: (event))
        
        handler([event])
    }
    
    lazy var mock_processImmediately = MockFunc.mock(for: processImmediately)
    
    func processImmediately() {
        mock_processImmediately.call(with: ())
    }
}
