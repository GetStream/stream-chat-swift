//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

/// Simulates participant behavior
final class ParticipantRobot: Robot {

    private var server: StreamMockServer
    
    init(_ server: StreamMockServer) {
        self.server = server
    }
    
    @discardableResult
    func startTyping() -> Self {
        server.websocketEvent(.userStartTyping, user: participant())
        return self
    }
    
    @discardableResult
    func stopTyping() -> Self {
        server.websocketEvent(.userStopTyping, user: participant())
        return self
    }
    
    @discardableResult
    func readMessage() -> Self {
        server.websocketEvent(.messageRead, user: participant())
        return self
    }
    
    @discardableResult
    func sendMessage(_ text: String) -> Self {
        server.websocketMessage(text, eventType: .messageNew, user: participant())
        return self
    }
    
    @discardableResult
    func editMessage(_ text: String) -> Self {
        server.websocketMessage(text, eventType: .messageUpdated, user: participant())
        return self
    }
    
    @discardableResult
    func deleteMessage() -> Self {
        server.websocketMessage(eventType: .messageDeleted, user: participant())
        return self
    }
    
    @discardableResult
    func addReaction(type: TestData.Reactions) -> Self {
        server.websocketDelay {
            self.server.websocketReaction(
                type: type,
                eventType: .reactionNew,
                user: self.participant()
            )
        }
        
        return self
    }
    
    @discardableResult
    func deleteReaction(type: TestData.Reactions) -> Self {
        server.websocketDelay {
            self.server.websocketReaction(
                type: type,
                eventType: .reactionDeleted,
                user: self.participant()
            )
        }
        return self
    }
    
    // TODO: CIS-1685
    @discardableResult
    func replyToMessage(_ text: String) -> Self {
        return self
    }
    
    // TODO: CIS-1685
    @discardableResult
    func replyToMessageInThread(_ text: String, alsoSendInChannel: Bool = false) -> Self {
        return self
    }
    
    private func participant() -> [String: Any] {
        let json = TestData.toJson(.wsMessage)
        let message = json[TopLevelKey.message] as! [String: Any]
        let user = server.setUpUser(
            message[MessagePayloadsCodingKeys.user.rawValue] as! [String: Any],
            userDetails: UserDetails.hanSolo
        )
        return user
    }
}
