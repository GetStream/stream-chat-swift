//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class PhotoRequest_Tests: XCTestCase {
    func test_resume_whenCalledAgain_keepsTheFirstValue() async {
        let value = await withCheckedContinuation { continuation in
            let request = PhotoRequest<Int>(continuation)
            request.resume(1)
            request.resume(2)
        }

        XCTAssertEqual(value, 1)
    }

    func test_resume_whenCalledFromManyQueues_resumesOnce() async {
        let value = await withCheckedContinuation { continuation in
            let request = PhotoRequest<Int>(continuation)
            DispatchQueue.concurrentPerform(iterations: 100) { request.resume($0) }
        }

        XCTAssertTrue((0..<100).contains(value))
    }

    func test_startFallback_startsOnlyOnce() async {
        let starts = await withCheckedContinuation { continuation in
            let request = PhotoRequest<[Bool]>(continuation)
            request.resume([request.startFallback(), request.startFallback()])
        }

        XCTAssertEqual(starts, [true, false])
    }
}
