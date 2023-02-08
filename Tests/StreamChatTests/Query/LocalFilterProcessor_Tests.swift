//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class LocalFilterProcessor_Tests: XCTestCase {
    // MARK: - Operator: Equal

    func test_operatorEqual_returnsExpectedResults() {
        [
            Scenario(filter: .equal(.testKey, to: "a"), inputItems: ["a", "b", "c"], expectedItems: ["a"]),
            Scenario(filter: .equal(.testKeyInt, to: 10), inputItems: [10, 20, 30], expectedItems: [10]),
            Scenario(filter: .equal(.testKeyDouble, to: 11.0), inputItems: [10.0, 11.0, 12.0], expectedItems: [11.0]),
            Scenario(filter: .equal(.testKeyDate, to: Date(timeIntervalSince1970: 10)), inputItems: [3, 6, 10].map { Date(timeIntervalSince1970: $0) }, expectedItems: [Date(timeIntervalSince1970: 10)]),
            Scenario(filter: .equal(.testKeyBool, to: true), inputItems: [true, false, false, true], expectedItems: [true, true])
        ].forEach { assert($0) }
    }

    // MARK: - Operator: Not Equal

    func test_operatorNotEqual_returnsExpectedResults() {
        [
            Scenario(filter: .notEqual(.testKey, to: "a"), inputItems: ["a", "b", "c"], expectedItems: ["b", "c"]),
            Scenario(filter: .notEqual(.testKeyInt, to: 10), inputItems: [10, 20, 30], expectedItems: [20, 30]),
            Scenario(filter: .notEqual(.testKeyDouble, to: 11.0), inputItems: [10.0, 11.0, 12.0], expectedItems: [10.0, 12.0]),
            Scenario(filter: .notEqual(.testKeyDate, to: Date(timeIntervalSince1970: 10)), inputItems: [3, 6, 10].map { Date(timeIntervalSince1970: $0) }, expectedItems: [Date(timeIntervalSince1970: 3), Date(timeIntervalSince1970: 6)]),
            Scenario(filter: .notEqual(.testKeyBool, to: true), inputItems: [true, false, false, true], expectedItems: [false, false])
        ].forEach { assert($0) }
    }

    // MARK: - Operator: Greater

    func test_operatorGreater_returnsExpectedResults() {
        [
            Scenario(filter: .greater(.testKey, than: "b"), inputItems: ["a", "b", "c"], expectedItems: ["c"]),
            Scenario(filter: .greater(.testKeyInt, than: 20), inputItems: [10, 20, 30], expectedItems: [30]),
            Scenario(filter: .greater(.testKeyDouble, than: 11.0), inputItems: [10.0, 11.0, 12.0], expectedItems: [12.0]),
            Scenario(filter: .greater(.testKeyDate, than: Date(timeIntervalSince1970: 6)), inputItems: [3, 6, 10].map { Date(timeIntervalSince1970: $0) }, expectedItems: [Date(timeIntervalSince1970: 10)])
        ].forEach { assert($0) }
    }

    // MARK: - Operator: GreaterOrEqual

    func test_operatorGreaterOrEqual_returnsExpectedResults() {
        [
            Scenario(filter: .greaterOrEqual(.testKey, than: "b"), inputItems: ["a", "b", "c"], expectedItems: ["b", "c"]),
            Scenario(filter: .greaterOrEqual(.testKeyInt, than: 20), inputItems: [10, 20, 30], expectedItems: [20, 30]),
            Scenario(filter: .greaterOrEqual(.testKeyDouble, than: 11.0), inputItems: [10.0, 11.0, 12.0], expectedItems: [11.0, 12.0]),
            Scenario(filter: .greaterOrEqual(.testKeyDate, than: Date(timeIntervalSince1970: 6)), inputItems: [3, 6, 10].map { Date(timeIntervalSince1970: $0) }, expectedItems: [Date(timeIntervalSince1970: 6), Date(timeIntervalSince1970: 10)])
        ].forEach { assert($0) }
    }

    // MARK: - Operator: Less

    func test_operatorLess_returnsExpectedResults() {
        [
            Scenario(filter: .less(.testKey, than: "b"), inputItems: ["a", "b", "c"], expectedItems: ["a"]),
            Scenario(filter: .less(.testKeyInt, than: 20), inputItems: [10, 20, 30], expectedItems: [10]),
            Scenario(filter: .less(.testKeyDouble, than: 11.0), inputItems: [10.0, 11.0, 12.0], expectedItems: [10.0]),
            Scenario(filter: .less(.testKeyDate, than: Date(timeIntervalSince1970: 6)), inputItems: [3, 6, 10].map { Date(timeIntervalSince1970: $0) }, expectedItems: [Date(timeIntervalSince1970: 3)])
        ].forEach { assert($0) }
    }

    // MARK: - Operator: LessOrEqual

    func test_operatorLessOrEqual_returnsExpectedResults() {
        [
            Scenario(filter: .lessOrEqual(.testKey, than: "b"), inputItems: ["a", "b", "c"], expectedItems: ["a", "b"]),
            Scenario(filter: .lessOrEqual(.testKeyInt, than: 20), inputItems: [10, 20, 30], expectedItems: [10, 20]),
            Scenario(filter: .lessOrEqual(.testKeyDouble, than: 11.0), inputItems: [10.0, 11.0, 12.0], expectedItems: [10.0, 11.0]),
            Scenario(filter: .lessOrEqual(.testKeyDate, than: Date(timeIntervalSince1970: 6)), inputItems: [3, 6, 10].map { Date(timeIntervalSince1970: $0) }, expectedItems: [Date(timeIntervalSince1970: 3), Date(timeIntervalSince1970: 6)])
        ].forEach { assert($0) }
    }

    // MARK: - Operator: In

    func test_operatorIn_returnsExpectedResults() {
        [
            Scenario(filter: .in(.testKeyArrayString, values: ["b", "c"]), inputItems: [["a", "b"], ["a", "b", "c"]], expectedItems: [["a", "b", "c"]]),
            Scenario(filter: .in(.testKeyArrayInt, values: [10, 30]), inputItems: [[20, 30], [10, 20, 30]], expectedItems: [[10, 20, 30]]),
            Scenario(filter: .in(.testKeyArrayDouble, values: [10.0, 30.0]), inputItems: [[20.0, 30.0], [10.0, 20.0, 30.0]], expectedItems: [[10.0, 20.0, 30.0]])
        ].forEach { assert($0) }
    }

    // MARK: - Operator: NotIn

    func test_operatorNotIn_returnsExpectedResults() {
        [
            Scenario(filter: .notIn(.testKeyArrayString, values: ["b", "c"]), inputItems: [["a", "d"], ["a", "b", "c"]], expectedItems: [["a", "d"]]),
            Scenario(filter: .notIn(.testKeyArrayInt, values: [10, 30]), inputItems: [[20, 40], [10, 20, 30]], expectedItems: [[20, 40]]),
            Scenario(filter: .notIn(.testKeyArrayDouble, values: [10.0, 30.0]), inputItems: [[20.0, 40.0], [10.0, 20.0, 30.0]], expectedItems: [[20.0, 40.0]])
        ].forEach { assert($0) }
    }

    // MARK: - Operator: Contains

    func test_operatorContains_returnsExpectedResults() {
        [
            Scenario(filter: .contains(.testKey, value: "value"), inputItems: ["Custom", "Value", "value", "Custom value 2"], expectedItems: ["value", "Custom value 2"])
        ].forEach { assert($0) }
    }

    // MARK: - Operator: Autocomplete

    func test_operatorAutocomplete_returnsExpectedResults() {
        [
            Scenario(filter: .contains(.testKey, value: "Cust"), inputItems: ["Custom", "Value", "value", "Custom value 2"], expectedItems: ["Custom", "Custom value 2"])
        ].forEach { assert($0) }
    }

    // MARK: - Operator: And

    func test_operatorAnd_returnsExpectedResults() {
        [
            Scenario(filter: .and([
                .contains(.testKey, value: "value"),
                .autocomplete(.testKey, text: "My")
            ]), inputItems: [
                "Custom",
                "value",
                "My",
                "My custom value"
            ], expectedItems: [
                "My custom value"
            ])
        ].forEach { assert($0) }
    }

    // MARK: - Operator: Or

    func test_operatorOr_returnsExpectedResults() {
        [
            Scenario(filter: .or([
                .contains(.testKey, value: "value"),
                .autocomplete(.testKey, text: "My")
            ]), inputItems: [
                "Custom",
                "value",
                "My",
                "My custom value"
            ], expectedItems: [
                "value",
                "My",
                "My custom value"
            ])
        ].forEach { assert($0) }
    }

    // MARK: - Operator: Nor

    func test_operatorNor_returnsExpectedResults() {
        [
            Scenario(filter: .nor([
                .contains(.testKey, value: "value"),
                .autocomplete(.testKey, text: "My")
            ]), inputItems: [
                "Custom",
                "value",
                "My",
                "My custom value"
            ], expectedItems: [
                "Custom",
                "value",
                "My"
            ])
        ].forEach { assert($0) }
    }

    private func assert(
        _ scenario: Scenario,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expected = Set(scenario.expectedItems)

        let actual = Set(
            Matcher(filter: scenario.filter)
                .execute(scenario.inputItems)
        )

        XCTAssertEqual(actual, expected, file: scenario.file, line: scenario.line)
    }
}

private struct Scenario {
    var filter: Filter<FilterTestScope>
    var inputItems: [AnyHashable]
    var expectedItems: [AnyHashable]
    var file: StaticString
    var line: UInt

    init<ResultType: Hashable>(
        filter: Filter<FilterTestScope>,
        inputItems: [ResultType],
        expectedItems: [ResultType],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.filter = filter
        self.inputItems = inputItems.map { AnyHashable($0) }
        self.expectedItems = expectedItems.map { AnyHashable($0) }
        self.file = file
        self.line = line
    }
}
