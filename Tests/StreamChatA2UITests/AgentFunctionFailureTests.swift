//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import SwiftUI
import Testing
@MainActor
@Suite("Agent function failures")
struct AgentFunctionFailureTests {
    @Test("test_agent_routing_agent_error_is_expression_error: an error answer is reported with its call")
    func errorAnswer() throws {
        let harness = ProcessorHarness()
        harness.createSurface()
        _ = try harness.processor.agentFunctionValue(for: "fetchFxRate", catalogId: nil, arguments: [:], surfaceId: "main")
        let call = try #require(harness.agentCalls.first)

        harness.processor.handle(.agentFunctionResponse(FunctionResponse(
            functionCallId: call.functionCallId,
            error: FunctionResponse.Failure(code: "UNKNOWN_FUNCTION", message: "No such function: fetchFxRate")
        )))

        let error = try #require(harness.errors.first)
        #expect(error.code == RendererError.Code.expressionError)
        #expect(error.message == "No such function: fetchFxRate")
        #expect(error.functionCallId == call.functionCallId)
        #expect(error.surfaceId == nil)
    }

    @Test("A failed call is reported once, and isn't kept once it is")
    func failuresAreNotKept() throws {
        let harness = ProcessorHarness()
        harness.createSurface()
        for _ in 0..<2 {
            _ = try harness.processor.agentFunctionValue(for: "estimate", catalogId: nil, arguments: [:], surfaceId: "main", userActivated: true)
        }
        let failure = FunctionResponse.Failure(code: "UNKNOWN_FUNCTION", message: "No such function: estimate")
        for call in harness.agentCalls {
            harness.processor.handle(.agentFunctionResponse(FunctionResponse(functionCallId: call.functionCallId, error: failure)))
            harness.processor.handle(.agentFunctionResponse(FunctionResponse(functionCallId: call.functionCallId, error: failure)))
        }

        #expect(harness.agentCalls.count == 2)
        #expect(harness.errors.map(\.functionCallId) == harness.agentCalls.map { Optional($0.functionCallId) })
        #expect(harness.processor.reportedErrors[""] == nil)
    }

    @Test("A call the agent doesn't answer in time is reported")
    func timeout() async throws {
        let harness = ProcessorHarness(agentFunctionTimeout: 0.01)
        harness.createSurface()
        _ = try harness.processor.agentFunctionValue(for: "estimate", catalogId: nil, arguments: [:], surfaceId: "main")
        let call = try #require(harness.agentCalls.first)

        await waitUntil("the timeout's report") { !harness.errors.isEmpty }

        #expect(harness.errors.map(\.code) == [RendererError.Code.expressionError])
        #expect(harness.errors.first?.functionCallId == call.functionCallId)
    }

    @Test("A surface created again reports the problems its earlier one reported")
    func dedupeIsPerSurface() {
        let harness = ProcessorHarness()
        let unknown = [Component(id: "root", type: "Nope")]
        harness.createSurface(components: unknown)
        harness.processor.handle(.deleteSurface(DeleteSurfaceMessage(surfaceId: "main")))
        harness.createSurface(components: unknown)

        #expect(harness.errors.map(\.code) == [RendererError.Code.validationFailed, RendererError.Code.validationFailed])
    }
}
