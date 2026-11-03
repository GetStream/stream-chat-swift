//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

@MainActor
final class OlderMessagesLoadingView_Tests: XCTestCase {
    func test_loadsAgainLaterAndLater_whileTheFirstTurnStaysTheSame() async {
        var loads = 0
        var waits: [UInt64] = []

        await OlderMessagesLoadingView.keepLoading({ loads += 1 }, wait: { delay in
            waits.append(delay)
            if waits.count == 8 {
                throw CancellationError()
            }
        })

        XCTAssertEqual(loads, 7, "such as after loads that failed")
        XCTAssertEqual(
            waits,
            [300_000_000, 1_000_000_000, 2_000_000_000, 4_000_000_000, 8_000_000_000, 16_000_000_000, 30_000_000_000, 30_000_000_000]
        )
    }

    func test_loadsNothing_whenTheSpinnerLeavesBeforeItsFirstWait() async {
        var loads = 0

        await OlderMessagesLoadingView.keepLoading({ loads += 1 }, wait: { _ in throw CancellationError() })

        XCTAssertEqual(loads, 0)
    }
}
