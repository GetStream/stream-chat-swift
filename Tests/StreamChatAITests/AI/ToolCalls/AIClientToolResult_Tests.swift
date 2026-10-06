//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AIClientToolResult_Tests: XCTestCase {
    private let installIDKey = "io.getstream.ai.client-id"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: installIDKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: installIDKey)
        super.tearDown()
    }

    func test_completed_encodesOutputAsJSON() throws {
        let result = AIClientToolResult.completed(["city": "Skopje"], summary: "Shared approximate location")

        let output = try JSONDecoder().decode([String: String].self, from: XCTUnwrap(result.output))
        XCTAssertEqual(output, ["city": "Skopje"])
        XCTAssertEqual(result.summary, "Shared approximate location")
        XCTAssertNil(result.failure)
    }

    func test_completed_whenOutputCannotBeEncoded_fails() {
        let result = AIClientToolResult.completed(["accuracy": Double.nan])

        XCTAssertNil(result.output)
        XCTAssertEqual(result.failure, "The result couldn't be read")
    }

    func test_failed_carriesTheReason() {
        let result = AIClientToolResult.failed("Location not shared")

        XCTAssertEqual(result, AIClientToolResult(failure: "Location not shared"))
    }

    func test_installID_isCreatedOnceAndAddressesIOS() {
        let first = AIClientIdentity.installID
        let second = AIClientIdentity.installID

        XCTAssertTrue(first.hasPrefix("ios-"))
        XCTAssertEqual(first, second)
        XCTAssertEqual(UserDefaults.standard.string(forKey: installIDKey), first)
    }
}
