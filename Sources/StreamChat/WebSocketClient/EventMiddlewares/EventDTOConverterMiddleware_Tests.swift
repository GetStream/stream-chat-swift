//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class EventDTOConverterMiddleware_Tests: XCTestCase {
    var middleware: EventDTOConverterMiddleware!
    var database: DatabaseContainerMock!

    override func setUp() {
        middleware = .init()
        database = try! DatabaseContainerMock(kind: .inMemory)
        super.setUp()
    }
    
    override func tearDown() {
        middleware = nil
        database = nil
        super.tearDown()
    }
    
    func test_handle_whenEventDTOComes_toDomainResultIsReturned() throws {
        class EventDTOMock: EventDTO {
            let payload = EventPayload(eventType: .channelDeleted)
            
            var toDomainEvent_session: DatabaseSession?
            var toDomainEvent_returnValue: Event?
            
            func toDomainEvent(session: DatabaseSession) -> Event? {
                toDomainEvent_session = session
                return toDomainEvent_returnValue
            }
        }
        
        // Create mock event DTO
        let eventDTO = EventDTOMock()
        
        // Hook up the value returned from `toDomainEvent`
        eventDTO.toDomainEvent_returnValue = EventDTOMock()
        
        // Feed event DTO to middleware
        let result = middleware.handle(event: eventDTO, session: database.viewContext)
        
        // Assert the session is forwarded to `toDomainEvent` func
        XCTAssertEqual(eventDTO.toDomainEvent_session as! NSManagedObjectContext, database.viewContext)
        
        // Assert
        XCTAssertTrue(result as! EventDTOMock === eventDTO.toDomainEvent_returnValue as! EventDTOMock)
    }
    
    func test_handle_whenNotEventDTOComes_eventIsForwardedAsIs() throws {
        // Create event
        let event = UnknownChannelEvent(
            type: .reactionNew,
            cid: .unique,
            userId: .unique,
            createdAt: .unique,
            payload: [:]
        )
        
        // Feed event to middleware
        let result = middleware.handle(event: event, session: database.viewContext)
        
        // Assert
        XCTAssertEqual(result as! UnknownChannelEvent, event)
    }
}
