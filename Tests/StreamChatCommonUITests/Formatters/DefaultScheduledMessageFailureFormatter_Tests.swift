//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatCommonUI
import XCTest

final class DefaultScheduledMessageFailureFormatter_Tests: XCTestCase {
    private let subject = DefaultScheduledMessageFailureFormatter()

    func test_format_localFailures() {
        XCTAssertEqual(
            subject.format(.localDeviceFailedScheduling(.init(reason: .attachmentUploadFailed))),
            "Couldn't upload attachment"
        )
        XCTAssertEqual(
            subject.format(.localDeviceFailedScheduling(.init(reason: .requestFailed))),
            "Couldn't send. Try again"
        )
    }

    func test_format_publishingFailures() {
        let expected: [(ScheduledMessageFailureReason, String)] = [
            (.banned, "You can't send messages in this channel."),
            (.channelDeleted, "This channel was deleted"),
            (.channelFrozen, "This channel is frozen."),
            (.expired, "Not sent: the service was delayed."),
            (.hookRejected, "Rejected by the app."),
            (.internalError, "Something went wrong. Try again"),
            (.invalidMessage, "The message no longer meets the app's limits. Edit it."),
            (.moderationBlocked, "Blocked by moderation."),
            (.noPermission, "You're no longer allowed to post here."),
            (.pendingNotSupported, "This channel now needs approval. Schedule it again."),
            (.userDeleted, "Something went wrong. Try again")
        ]
        for (reason, text) in expected {
            XCTAssertEqual(subject.format(.serverFailedPublishing(.init(reason: reason))), text, reason.rawValue)
        }
    }

    func test_format_rejections() {
        let expected: [(ScheduledMessageFailure.ServerRejection.Reason?, String)] = [
            (.scheduledAtTooFar, "That's further ahead than your app allows"),
            (.scheduledAtTooSoon, "Pick a later time"),
            (.scheduledLimitChannel, "You've reached the limit of scheduled messages in this channel."),
            (.scheduledLimitUser, "You've reached your limit of scheduled messages."),
            (.rateLimited, "Something went wrong. Try again"),
            (nil, "Something went wrong. Try again")
        ]
        for (reason, text) in expected {
            XCTAssertEqual(
                subject.format(.serverRejectedScheduling(.init(reason: reason, message: "Server message"))),
                text,
                reason?.rawValue ?? "nil"
            )
        }
    }

    func test_format_withoutAFailure_returnsTheGenericText() {
        XCTAssertEqual(subject.format(nil), "Something went wrong. Try again")
        XCTAssertEqual(subject.format(.serverFailedPublishing(.init(reason: nil))), "Something went wrong. Try again")
    }
}
