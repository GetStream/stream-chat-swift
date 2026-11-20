//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

@MainActor
@Suite("Action components")
struct ActionComponentTests {
    nonisolated static let actions: [(OpenUIValue, Bool)] = [
        (.null, true),
        (["steps": [["type": "continue_conversation"]]], true),
        (["steps": [["type": "run", "refType": "mutation"]]], true),
        (["steps": [["type": "run", "refType": "query"]]], false),
        (["steps": [["type": "open_url"]]], false)
    ]

    @Test(arguments: actions)
    func primaryButtonsValidateBeforeActionsThatSendTheForm(_ action: OpenUIValue, _ validates: Bool) {
        #expect(ButtonComponentView.needsValidation(action) == validates)
    }

    @Test func aCustomActionTheModelCalledValidatesBeforeItRuns() throws {
        let runtime = OpenUIRuntime(library: OpenUI1RuntimeTests.library)
        runtime.update(response: #"root = Card([Buttons([Button("Copy", @CopyToClipboard("abc"))])])"#, isStreaming: false)
        let buttons = try #require(runtime.root?.props["children"]?.arrayValue?.first?.elementValue)
        let action = try #require(buttons.props["buttons"]?.arrayValue?.first?.elementValue?.props["action"])

        let steps = ActionPlan.steps(of: action)
        #expect(steps.count == 1)
        #expect(steps.first?["type"]?.stringValue == ActionStepType.customAction)
        #expect(ButtonComponentView.needsValidation(action))
    }

    @Test func aCardTapKeepsTheActionsOwnContext() {
        let item: OpenUIObject = ["itemIndex": 0]
        let suffix = "Selected item: " + OpenUIJSON.stringify(.object(item))
        func context(_ value: OpenUIValue?) -> OpenUIValue? {
            var step: OpenUIObject = ["type": "continue_conversation"]
            if let value { step["context"] = value }
            let merged = ItemActionContext.merge(["steps": [.object(step)]], item: item)
            return merged["steps"]?.arrayValue?.first?["context"]
        }

        #expect(context(["sku": "A1"]) == .string(#"{"sku":"A1"}"# + "\n" + suffix))
        #expect(context(42) == .string("42\n" + suffix))
        #expect(context("Compare") == .string("Compare\n" + suffix))
        #expect(context(nil) == .string(suffix))
        #expect(context(.null) == .string(suffix))
    }
}
