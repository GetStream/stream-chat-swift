//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

@MainActor
final class AITurnPositions_Tests: XCTestCase {
    private let positions = AITurnPositions()

    override func setUp() {
        super.setUp()
        positions.expect(above: "q1")
        positions.update([
            "q0": CGRect(x: 0, y: -500, width: 300, height: 300),
            "q1": CGRect(x: 0, y: -100, width: 300, height: 400),
            "q2": CGRect(x: 0, y: 300, width: 300, height: 400)
        ])
        positions.expect(above: "older")
    }

    func test_heldTurn_isTheTurnAtTheTopOfWhatIsVisible() {
        XCTAssertEqual(positions.heldTurn(among: ["q0", "q1", "q2"])?.id, "q1")
    }

    func test_heldTurn_whenTheTopTurnJoinedTheOneAboveIt_isTheNextTurnInView() {
        let held = positions.heldTurn(among: ["older", "q2"])

        XCTAssertEqual(held?.id, "q2", "a turn that starts with a reply joins its question's when older messages bring it")
        XCTAssertEqual(held?.frame.minY, 300)
    }

    func test_update_whileWaitingForTheTurnToGoBack_keepsWhereItWas() {
        positions.update(["q2": CGRect(x: 0, y: 900, width: 300, height: 400)])

        XCTAssertEqual(positions.heldTurn(among: ["q2"])?.frame.minY, 300)
    }
}
