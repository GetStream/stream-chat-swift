//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import UIKit
import XCTest

@MainActor
final class AIPendingMessageTracker_Tests: XCTestCase {
    private struct Message: AIMessage {
        var id: String
        var role: AIMessageRole
        var text = "Text"
        var isGenerating = false
        var uiDocument: AIUIDocument?
    }

    private struct ReadsAnyUI: AIUIDocumentReader {
        func canShow(_ document: AIUIDocument) -> Bool { true }
    }

    private let writingUI = AIUIDocument(format: .openUI, isStreaming: true, content: .string("root = Card([title])"))

    private let tracker = AIPendingMessageTracker()
    private let photo = UIImage()
    private lazy var pending = AIPendingMessage(id: "pending", text: "Plan a trip", attachments: [.image(photo)])

    func test_entries_leaveOutRepliesWithNothingToShowYet() {
        let entries = tracker.entries(
            for: [
                Message(id: "q1", role: .user),
                Message(id: "a1", role: .assistant, text: "", isGenerating: true)
            ],
            pending: nil
        )

        XCTAssertEqual(entries.map(\.id), ["q1"])
    }

    func test_entries_keepAReplyThatShowsOnlyItsUISoFar() {
        let entries = tracker.entries(
            for: [
                Message(id: "q1", role: .user),
                Message(id: "a1", role: .assistant, text: "", isGenerating: true, uiDocument: writingUI)
            ],
            pending: nil,
            ui: ReadsAnyUI()
        )

        XCTAssertEqual(entries.map(\.id), ["q1", "a1"])
    }

    func test_entries_leaveOutAReplyWhoseUINothingShows() {
        let entries = tracker.entries(
            for: [
                Message(id: "q1", role: .user),
                Message(id: "a1", role: .assistant, text: "", isGenerating: true, uiDocument: writingUI)
            ],
            pending: nil
        )

        XCTAssertEqual(entries.map(\.id), ["q1"])
    }

    func test_entries_showThePendingMessageAfterTheMessages() {
        let entries = tracker.entries(for: [Message(id: "q1", role: .user), Message(id: "a1", role: .assistant)], pending: pending)

        XCTAssertEqual(entries.map(\.id), ["q1", "a1", "pending"])
        XCTAssertTrue(entries[2].isFromUser)
    }

    func test_entries_whenTheCopyArrives_itTakesOverThePendingRowWithItsAttachments() {
        let before = [Message(id: "q1", role: .user), Message(id: "a1", role: .assistant)]
        _ = tracker.entries(for: before, pending: pending)

        let entries = tracker.entries(for: before + [Message(id: "q2", role: .user)], pending: pending)

        XCTAssertEqual(entries.map(\.id), ["q1", "a1", "pending"], "so the turn carries on rather than starting again")
        XCTAssertEqual(entries[2].sentAttachments, [.image(photo)], "so the photos show from the phone rather than load again")
    }

    func test_entries_whenThePendingMessageIsNoLongerPassed_theCopyKeepsItsRow() {
        _ = tracker.entries(for: [Message(id: "q1", role: .user)], pending: pending)
        _ = tracker.entries(for: [Message(id: "q1", role: .user), Message(id: "q2", role: .user)], pending: pending)

        let entries = tracker.entries(for: [Message(id: "q1", role: .user), Message(id: "q2", role: .user)], pending: nil)

        XCTAssertEqual(entries.map(\.id), ["q1", "pending"])
    }

    func test_entries_repliesDoNotTakeOverThePendingRow() {
        _ = tracker.entries(for: [Message(id: "q1", role: .user)], pending: pending)

        let entries = tracker.entries(for: [Message(id: "q1", role: .user), Message(id: "a1", role: .assistant)], pending: pending)

        XCTAssertEqual(entries.map(\.id), ["q1", "a1", "pending"])
    }

    func test_entries_olderMessagesLoadingAboveDoNotTakeOverThePendingRow() {
        let shown = [Message(id: "q1", role: .user), Message(id: "a1", role: .assistant)]
        _ = tracker.entries(for: shown, pending: pending)

        let older = [Message(id: "q0", role: .user), Message(id: "a0", role: .assistant)]
        let withOlder = tracker.entries(for: older + shown, pending: pending)
        XCTAssertEqual(withOlder.map(\.id), ["q0", "a0", "q1", "a1", "pending"])

        let entries = tracker.entries(for: older + shown + [Message(id: "q2", role: .user)], pending: pending)
        XCTAssertEqual(entries.map(\.id), ["q0", "a0", "q1", "a1", "pending"], "the copy still takes over the row")
    }

    func test_entries_whenOlderMessagesArriveWithTheCopy_theCopyTakesOverThePendingRow() {
        _ = tracker.entries(for: [Message](), pending: pending)

        let entries = tracker.entries(
            for: [
                Message(id: "q0", role: .user),
                Message(id: "a0", role: .assistant),
                Message(id: "q1", role: .user, text: "Plan a trip")
            ],
            pending: pending
        )

        XCTAssertEqual(entries.map(\.id), ["q0", "a0", "pending"])
    }

    func test_entries_whenOnlyOlderMessagesArrive_theyDoNotTakeOverThePendingRow() {
        _ = tracker.entries(for: [Message](), pending: pending)

        let entries = tracker.entries(
            for: [Message(id: "q0", role: .user), Message(id: "a0", role: .assistant), Message(id: "q1", role: .user)],
            pending: pending
        )

        XCTAssertEqual(entries.map(\.id), ["q0", "a0", "q1", "pending"])
    }

    func test_entries_whenTheCopyHasThePendingMessagesID_itTakesOverWhereverItLands() {
        let identified = AIPendingMessage(id: "q1", text: "Plan a trip")
        _ = tracker.entries(for: [Message](), pending: identified)

        let entries = tracker.entries(
            for: [Message(id: "q1", role: .user), Message(id: "q0", role: .user)],
            pending: identified
        )

        XCTAssertEqual(entries.map(\.id), ["q1", "q0"])
    }

    func test_entries_aMessageSentAfterTheCopyDoesNotTakeOverTheRowToo() {
        _ = tracker.entries(for: [Message(id: "q1", role: .user)], pending: pending)
        _ = tracker.entries(for: [Message(id: "q1", role: .user), Message(id: "q2", role: .user)], pending: pending)

        let entries = tracker.entries(
            for: [Message(id: "q1", role: .user), Message(id: "q2", role: .user), Message(id: "q3", role: .user)],
            pending: pending
        )

        XCTAssertEqual(entries.map(\.id), ["q1", "pending", "q3"])
    }

    func test_entries_whenTheCopyIsAlreadyThereTheFirstTimeThePendingMessageIs_itTakesOverTheRow() {
        let before = [Message(id: "q1", role: .user), Message(id: "a1", role: .assistant)]
        _ = tracker.entries(for: before, pending: nil)

        let entries = tracker.entries(for: before + [Message(id: "q2", role: .user)], pending: pending)

        XCTAssertEqual(entries.map(\.id), ["q1", "a1", "pending"], "the message shows once")
    }

    func test_entries_editingAMessageAgain_itsCopyTakesTheLatestEditsRow() {
        let first = AIPendingMessage(id: "edit1", text: "Plan a trip", attachments: [.image(photo)])
        let second = AIPendingMessage(id: "edit2", text: "Plan a long trip", attachments: [.image(UIImage())])
        let conversation = [Message(id: "q1", role: .user), Message(id: "a1", role: .assistant)]
        _ = tracker.entries(for: conversation, pending: nil)

        // While an edit waits, the message it edits and its reply are left out.
        _ = tracker.entries(for: [Message](), pending: first)
        let edited = tracker.entries(for: conversation, pending: nil)
        XCTAssertEqual(edited.map(\.id), ["edit1", "a1"])

        _ = tracker.entries(for: [Message](), pending: second)
        // The transport changes the message to say what the edit does.
        let editedAgain = tracker.entries(
            for: [Message(id: "q1", role: .user, text: "Plan a long trip"), Message(id: "a1", role: .assistant)],
            pending: nil
        )

        XCTAssertEqual(editedAgain.map(\.id), ["edit2", "a1"], "the row it had while it waited")
        XCTAssertEqual(editedAgain[0].sentAttachments, second.attachments)
    }

    func test_entries_whenAnEditAgainFails_theMessageKeepsTheRowOfTheEditBefore() {
        let first = AIPendingMessage(id: "edit1", text: "Plan a trip", attachments: [.image(photo)])
        let second = AIPendingMessage(id: "edit2", text: "Plan a long trip", attachments: [.image(UIImage())])
        let edited = [Message(id: "q1", role: .user, text: "Plan a trip"), Message(id: "a1", role: .assistant)]
        _ = tracker.entries(for: [Message(id: "q1", role: .user), Message(id: "a1", role: .assistant)], pending: nil)
        _ = tracker.entries(for: [Message](), pending: first)
        _ = tracker.entries(for: edited, pending: nil)

        _ = tracker.entries(for: [Message](), pending: second)
        // The edit failed, so the conversation brings the message back as it was.
        let rolledBack = tracker.entries(for: edited, pending: nil)

        XCTAssertEqual(rolledBack.map(\.id), ["edit1", "a1"])
        XCTAssertEqual(rolledBack[0].sentAttachments, first.attachments, "not the photos of the edit that wasn't sent")
    }

    func test_entries_whenTheCopyArrivesWithThePendingMessagesID_itTakesTheRowFromAMessageThatTookItFirst() {
        let identified = AIPendingMessage(id: "q3", text: "Plan a trip", attachments: [.image(photo)])
        _ = tracker.entries(for: [Message(id: "q1", role: .user)], pending: nil)
        // Another device's message arrives as the person sends theirs, so it takes their row.
        _ = tracker.entries(for: [Message(id: "q1", role: .user), Message(id: "q2", role: .user)], pending: identified)

        let entries = tracker.entries(
            for: [Message(id: "q1", role: .user), Message(id: "q2", role: .user), Message(id: "q3", role: .user)],
            pending: identified
        )

        XCTAssertEqual(entries.map(\.id), ["q1", "q2", "q3"], "each row once")
        XCTAssertEqual(entries[1].sentAttachments, [])
        XCTAssertEqual(entries[2].sentAttachments, [.image(photo)])
    }

    func test_entries_aMessageStoppedBeforeItArrived_doesNotTakeTheRowOfTheNextOne() {
        let stopped = AIPendingMessage(id: "q2", text: "Hi")
        let next = AIPendingMessage(id: "q3", text: "Porto?")
        _ = tracker.entries(for: [Message(id: "q1", role: .user)], pending: stopped)
        _ = tracker.entries(for: [Message(id: "q1", role: .user)], pending: next)

        let entries = tracker.entries(for: [Message(id: "q1", role: .user), Message(id: "q2", role: .user)], pending: next)

        XCTAssertEqual(entries.map(\.id), ["q1", "q2", "q3"], "the next message is still on its way")
    }

    func test_isAwaitingReply_whileThePendingMessageWaitsForItsCopy() {
        let messages = [Message(id: "q1", role: .user), Message(id: "a1", role: .assistant)]
        _ = tracker.entries(for: messages, pending: pending)

        XCTAssertTrue(tracker.isAwaitingReply(in: messages, pending: pending))
    }

    func test_isAwaitingReply_whenTheCopyIsTheLatestMessage() {
        _ = tracker.entries(for: [Message(id: "q1", role: .user)], pending: pending)
        let messages = [Message(id: "q1", role: .user), Message(id: "q2", role: .user)]
        _ = tracker.entries(for: messages, pending: pending)

        XCTAssertTrue(tracker.isAwaitingReply(in: messages, pending: pending))
        XCTAssertFalse(tracker.isAwaitingReply(in: messages, pending: nil), "once the app stops passing it, the app says")
    }

    func test_isAwaitingReply_whileTheReplyIsWrittenButShowsNothing() {
        let messages = [Message(id: "q1", role: .user), Message(id: "a1", role: .assistant, text: "", isGenerating: true)]

        XCTAssertTrue(tracker.isAwaitingReply(in: messages, pending: nil))
    }

    func test_isAwaitingReply_onceTheReplyShowsSomething_isFalse() {
        let messages = [Message(id: "q1", role: .user), Message(id: "a1", role: .assistant, text: "Sure", isGenerating: true)]

        XCTAssertFalse(tracker.isAwaitingReply(in: messages, pending: nil))
    }

    func test_isAwaitingReply_onceTheReplysUIShows_isFalse() {
        let messages = [
            Message(id: "q1", role: .user),
            Message(id: "a1", role: .assistant, text: "", isGenerating: true, uiDocument: writingUI)
        ]

        XCTAssertFalse(tracker.isAwaitingReply(in: messages, pending: nil, ui: ReadsAnyUI()))
    }

    func test_isAwaitingReply_whileTheReplysUINothingShows_isTrue() {
        let messages = [
            Message(id: "q1", role: .user),
            Message(id: "a1", role: .assistant, text: "", isGenerating: true, uiDocument: writingUI)
        ]

        XCTAssertTrue(tracker.isAwaitingReply(in: messages, pending: nil))
    }

    func test_isAwaitingReply_whenTheLatestMessageIsThePersonsOwn_isLeftToTheApp() {
        XCTAssertFalse(tracker.isAwaitingReply(in: [Message(id: "q1", role: .user)], pending: nil))
    }
}
