//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

@MainActor
final class AIClientToolRunner_Tests: XCTestCase {
    final class CountingTool: AIClientTool {
        let name = "athena_device_location"
        var runs = 0
        func run(_ call: AIToolCallPart) async -> AIClientToolResult {
            runs += 1
            return .completed(["city": "Skopje"], summary: "Shared approximate location")
        }
    }

    private func awaiting(_ id: String = "toolu_01A", user: String = "u_1", client: String = "ios-1", name: String = "athena_device_location") -> [AIMessagePart] {
        let json = #"{"id":"\#(id)","name":"\#(name)","status":"awaiting_client","executor":"client","target_user_id":"\#(user)","target_client_id":"\#(client)"}"#
        return [AIMessagePart(type: "ai_tool_call", payload: Data(json.utf8))!]
    }

    private func settle() async {
        for _ in 0..<20 { await Task.yield() }
    }

    func testACallRunsOnceAndOnlyOnTheDeviceItIsAddressedTo() async {
        let tool = CountingTool()
        let runner = AIClientToolRunner(userID: "u_1", clientID: "ios-1", tools: [tool])
        var sent: [AIClientToolResult] = []
        let send: @MainActor (AIToolCallPart, AIClientToolResult) async throws -> Void = { _, result in sent.append(result) }

        runner.run(awaiting(), send: send)
        runner.run(awaiting(), send: send)
        await settle()
        runner.run(awaiting(), send: send)
        runner.run(awaiting("toolu_02", client: "ios-2"), send: send)
        runner.run(awaiting("toolu_03", user: "u_2"), send: send)
        runner.run(awaiting("toolu_04", name: "unknown_tool"), send: send)
        await settle()

        XCTAssertEqual(tool.runs, 1)
        XCTAssertEqual(sent.count, 1)
        XCTAssertEqual(sent.first?.summary, "Shared approximate location")
    }

    func testAResultThatCouldNotBeSentIsSentAgainWithoutRunningTheToolAgain() async {
        struct Offline: Error {}
        let tool = CountingTool()
        let runner = AIClientToolRunner(userID: "u_1", clientID: "ios-1", tools: [tool])
        var attempts = 0
        let send: @MainActor (AIToolCallPart, AIClientToolResult) async throws -> Void = { _, _ in
            attempts += 1
            if attempts == 1 { throw Offline() }
        }

        runner.run(awaiting(), send: send)
        await settle()
        runner.run(awaiting(), send: send)
        await settle()
        runner.run(awaiting(), send: send)
        await settle()

        XCTAssertEqual(tool.runs, 1)
        XCTAssertEqual(attempts, 2)
    }

    func test_run_whenResultKeepsFailingToSend_givesUpAfterMaxAttempts() async {
        struct Offline: Error {}
        let tool = CountingTool()
        let runner = AIClientToolRunner(userID: "u_1", clientID: "ios-1", tools: [tool])
        runner.maxAttempts = 2
        var attempts = 0
        let send: @MainActor (AIToolCallPart, AIClientToolResult) async throws -> Void = { _, _ in
            attempts += 1
            throw Offline()
        }

        for _ in 0..<4 {
            runner.run(awaiting(), send: send)
            await settle()
        }

        XCTAssertEqual(tool.runs, 1)
        XCTAssertEqual(attempts, 2)
    }

    func test_run_whenRunnerIsReleasedWhileToolRuns_stillSendsTheResult() async {
        final class SlowTool: AIClientTool {
            let name = "athena_device_location"
            var finish: CheckedContinuation<Void, Never>?
            func run(_ call: AIToolCallPart) async -> AIClientToolResult {
                await withCheckedContinuation { finish = $0 }
                return .completed(["city": "Skopje"])
            }
        }
        let tool = SlowTool()
        var runner: AIClientToolRunner? = AIClientToolRunner(userID: "u_1", clientID: "ios-1", tools: [tool])
        weak var released: AIClientToolRunner?
        released = runner
        var sent = 0

        runner?.run(awaiting()) { _, _ in sent += 1 }
        await settle()
        runner = nil
        tool.finish?.resume()
        await settle()

        XCTAssertEqual(sent, 1)
        XCTAssertNil(released, "the runner is released once the result is sent")
    }

    func test_run_whenCallIsFinished_doesNotRunTool() async {
        let tool = CountingTool()
        let runner = AIClientToolRunner(userID: "u_1", clientID: "ios-1", tools: [tool])
        let json = #"{"id":"toolu_01A","name":"athena_device_location","status":"completed","executor":"client","target_user_id":"u_1","target_client_id":"ios-1"}"#

        runner.run([AIMessagePart(type: "ai_tool_call", payload: Data(json.utf8))!]) { _, _ in }
        await settle()

        XCTAssertEqual(tool.runs, 0)
    }

    func test_toolNames_areSortedAndKeepTheFirstToolOfAName() async {
        final class NamedTool: AIClientTool {
            let name: String
            var runs = 0
            init(_ name: String) { self.name = name }
            func run(_ call: AIToolCallPart) async -> AIClientToolResult {
                runs += 1
                return .failed("Not now")
            }
        }
        let first = NamedTool("athena_device_location")
        let duplicate = NamedTool("athena_device_location")
        let runner = AIClientToolRunner(userID: "u_1", clientID: "ios-1", tools: [NamedTool("open_camera"), first, duplicate])

        runner.run(awaiting()) { _, _ in }
        await settle()

        XCTAssertEqual(runner.toolNames, ["athena_device_location", "open_camera"])
        XCTAssertEqual(first.runs, 1)
        XCTAssertEqual(duplicate.runs, 0)
    }
}
