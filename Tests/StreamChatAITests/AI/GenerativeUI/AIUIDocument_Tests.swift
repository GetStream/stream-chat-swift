//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import StreamCore
import XCTest

final class AIUIDocument_Tests: XCTestCase {
    func testADocumentReadsItsFormatVersionStatusAndContent() throws {
        let document = try XCTUnwrap(AIUIDocument(customData: [
            "ai_ui": .dictionary([
                "v": .number(1),
                "format": .string("openui"),
                "version": .string("0.4.0"),
                "status": .string("streaming"),
                "content": .string("root = Card([title])")
            ]),
            "generating": .bool(true)
        ]))

        XCTAssertEqual(document.format, .openUI)
        XCTAssertEqual(document.version, "0.4.0")
        XCTAssertTrue(document.isStreaming)
        XCTAssertEqual(document.text, "root = Card([title])")
    }

    func testAFinishedDocumentInJSONHasNoText() throws {
        let document = try XCTUnwrap(AIUIDocument(customData: [
            "ai_ui": .dictionary([
                "format": .string("a2ui"),
                "status": .string("complete"),
                "content": .array([.dictionary(["deleteSurface": .dictionary(["surfaceId": .string("s1")])])])
            ])
        ]))

        XCTAssertEqual(document.format, .a2ui)
        XCTAssertNil(document.version)
        XCTAssertFalse(document.isStreaming)
        XCTAssertNil(document.text)
    }

    func testAMessageWithoutADocumentItCanReadHasNone() {
        XCTAssertNil(AIUIDocument(customData: [:]))
        XCTAssertNil(AIUIDocument(customData: ["ai_ui": .string("root = Card([])")]))
        XCTAssertNil(AIUIDocument(customData: ["ai_ui": .dictionary(["content": .string("root = Card([])")])]))
        XCTAssertNil(AIUIDocument(customData: ["ai_ui": .dictionary(["format": .string("openui"), "content": .nil])]))
        XCTAssertNil(
            AIUIDocument(customData: ["ai_ui": .dictionary(["v": .number(2), "format": .string("openui"), "content": .string("x")])]),
            "a newer field may mean something else"
        )
    }

    func testAFormatIsAnOpenSet() {
        let cards: AIUIFormat = "acme-cards"
        let document = AIUIDocument(customData: [
            "ai_ui": .dictionary(["format": .string("acme-cards"), "version": .string(""), "content": .dictionary([:])])
        ])

        XCTAssertEqual(cards, AIUIFormat(rawValue: "acme-cards"))
        XCTAssertEqual(cards.description, "acme-cards")
        XCTAssertEqual([AIUIFormat.openUI, .a2ui].map(\.rawValue), ["openui", "a2ui"])
        XCTAssertEqual(document?.format, cards)
        XCTAssertNil(document?.version, "an empty version is none")
        XCTAssertEqual(document?.isStreaming, false, "a document without a status is finished")
    }

    func testAnActionIsTheJSONAnAgentReads() {
        let action = AIUIAction(
            messageID: "m1",
            format: .openUI,
            name: "ask_about",
            label: "Tell me more about St. Naum",
            payload: ["title": .string("Monastery of Saint Naum")]
        )

        XCTAssertEqual(action.json, [
            "v": .number(1),
            "message_id": .string("m1"),
            "format": .string("openui"),
            "name": .string("ask_about"),
            "payload": .dictionary(["title": .string("Monastery of Saint Naum")])
        ])
        XCTAssertEqual(action.customData, ["ai_ui_action": .dictionary(action.json)])
    }

    func testAMessageHasNoDocumentUnlessItSaysSo() {
        struct Reply: AIMessage {
            var id = "r1"
            var role: AIMessageRole = .assistant
            var text = ""
            var uiDocument: AIUIDocument?
        }

        XCTAssertNil(Reply().uiDocument)
        XCTAssertTrue(Reply().showsNothing)
        XCTAssertFalse(Reply(uiDocument: AIUIDocument(format: .openUI, isStreaming: true, content: .string(""))).showsNothing)
    }
}
