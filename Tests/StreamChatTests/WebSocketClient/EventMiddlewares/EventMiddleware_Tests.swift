//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class EventMiddleware_Tests: XCTestCase {
    /// A test event holding an `Int` value.
    struct IntBasedEvent: Event, Equatable {
        let value: Int
    }
    
    func test_middlewareEvaluation() throws {
        var database: DatabaseContainer! = DatabaseContainer_Spy()
        let usedSession = database.viewContext
        
        let chain: [EventMiddleware] = [
            // Adds `1` to the event synchronously
            EventMiddleware_Mock { event, session in
                // Assert the correct session is used
                XCTAssertEqual(session as! NSManagedObjectContext, usedSession)
                
                let event = event as! IntBasedEvent
                return IntBasedEvent(value: event.value + 1)
            },
            
            // Adds `2` to the event synchronously
            EventMiddleware_Mock { event, session in
                // Assert the correct session is used
                XCTAssertEqual(session as! NSManagedObjectContext, usedSession)
                
                let event = event as! IntBasedEvent
                return IntBasedEvent(value: event.value + 2)
            }
        ]
        
        // Evaluate the middlewares and record the event
        let result = chain.process(event: IntBasedEvent(value: 0), session: usedSession)
        
        // Check the evaluation result is correct
        XCTAssertEqual(result as! IntBasedEvent, IntBasedEvent(value: 3))
        
        AssertAsync.canBeReleased(&database)
    }
}
