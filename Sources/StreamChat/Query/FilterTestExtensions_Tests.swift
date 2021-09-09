//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

struct FilterTestScope: FilterScope {}

extension FilterKey where Scope == FilterTestScope {
    static var testKey: FilterKey<Scope, String> { "test_key" }
    static var testKeyInt: FilterKey<Scope, Int> { "test_key_Int" }
    static var testKeyDate: FilterKey<Scope, Date> { "test_key_Date" }
    static var testKeyDouble: FilterKey<Scope, Double> { "test_key_Double" }
    static var testKeyBool: FilterKey<Scope, Bool> { "test_key_Bool" }

    static var testKeyArrayString: FilterKey<Scope, String> { "test_key_ArrayString" }
    static var testKeyArrayInt: FilterKey<Scope, Int> { "test_key_ArrayInt" }
    static var testKeyArrayDouble: FilterKey<Scope, Double> { "test_key_ArrayDouble" }
}

extension Filter: Equatable {
    public static func == (lhs: Filter<Scope>, rhs: Filter<Scope>) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}

extension Filter {
    var serialized: String {
        try! serializedThrows()
    }

    func serializedThrows() throws -> String {
        let data = try JSONEncoder.default.encode(self)
        return String(data: data, encoding: .utf8)!
    }
}

extension String {
    func deserializeFilter<Scope: FilterScope>() -> Filter<Scope>? {
        try? deserializeFilterThrows()
    }

    func deserializeFilterThrows<Scope: FilterScope>() throws -> Filter<Scope> {
        try JSONDecoder.default.decode(Filter<Scope>.self, from: data(using: .utf8)!)
    }
}

struct FilterCodingTestPair {
    var json: String
    var filter: Filter<FilterTestScope>

    static var allCases: [FilterCodingTestPair] = [
        .equalInt(),
        .notEqualDate(),
        .greaterDouble(),
        .greaterOrEqualBool(),
        .lessInt(),
        .lessOrEqualDouble(),
        .inArrayInt(),
        .inArrayDouble(),
        .notInArrayString(),
        .query(),
        .autocomplete(),
        .existsTrue(),
        .notExists(),
        .containsAndEqual(),
        .greaterOrLess(),
        .nonEqualNorEqual()
    ]
}

// Note: tests below are designed using a all-pair/pairwise testing approach
// Using carefully chosen test vectors, this can be done much faster
// than an exhaustive search of all combinations of all parameters,
// by "parallelizing" the tests of parameter pairs.
extension FilterCodingTestPair {
    static func equalInt() -> FilterCodingTestPair {
        let json = #"{"test_key_Int":{"$eq":1}}"#
        let filter: Filter<FilterTestScope> = .equal(.testKeyInt, to: 1)
        return FilterCodingTestPair(json: json, filter: filter)
    }

    static func notEqualDate() -> FilterCodingTestPair {
        let dateComponents = DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2020,
            month: 8,
            day: 12,
            hour: 13,
            minute: 14,
            second: 59
        )
        let date: Date = Calendar.gmtCalendar.date(from: dateComponents)!
        let dateString = "2020-08-12T13:14:59Z"
        let json = "{\"test_key_Date\":{\"$ne\":\"\(dateString)\"}}"
        let filter: Filter<FilterTestScope> = .notEqual(.testKeyDate, to: date)
        return FilterCodingTestPair(json: json, filter: filter)
    }

    // Note: Double encoding strange format:
    // Built-in encoder for Double will output enough decimal
    // digits in the JSON representation to guarantee that it will come out
    // as the exact same IEEE value when decoded later.
    // That is, the decimal number in the JSON might not be an exact representation
    // of the floating point value you started with, but you can be sure
    // it can't be mistaken for any other floating point value.
    // https://forums.swift.org/t/jsonencoder-encodable-floating-point-rounding-error/41390
    static func greaterDouble() -> FilterCodingTestPair {
        let json = #"{"test_key_Double":{"$gt":13.15}}"#
        let filter: Filter<FilterTestScope> = .greater(.testKeyDouble, than: 13.15)
        return FilterCodingTestPair(json: json, filter: filter)
    }

    static func greaterOrEqualBool() -> FilterCodingTestPair {
        let json = #"{"test_key_Bool":{"$gte":true}}"#
        let filter: Filter<FilterTestScope> = .greaterOrEqual(.testKeyBool, than: true)
        return FilterCodingTestPair(json: json, filter: filter)
    }

    static func lessInt() -> FilterCodingTestPair {
        let json = #"{"test_key_Int":{"$lt":100500}}"#
        let filter: Filter<FilterTestScope> = .less(.testKeyInt, than: 100_500)
        return FilterCodingTestPair(json: json, filter: filter)
    }

    static func lessOrEqualDouble() -> FilterCodingTestPair {
        let json = #"{"test_key_Double":{"$lte":67.216999999999999}}"#
        let filter: Filter<FilterTestScope> = .lessOrEqual(.testKeyDouble, than: 67.217)
        return FilterCodingTestPair(json: json, filter: filter)
    }

    static func inArrayInt() -> FilterCodingTestPair {
        let array: [Int] = [1, 2, 3, 4]
        let arrayJSON = #"[1,2,3,4]"#
        let json = "{\"test_key_ArrayInt\":{\"$in\":\(arrayJSON)}}"
        let filter: Filter<FilterTestScope> = .in(.testKeyArrayInt, values: array)
        return FilterCodingTestPair(json: json, filter: filter)
    }

    static func inArrayDouble() -> FilterCodingTestPair {
        let array: [Double] = [1.2, 2.2, 3.2, 4.2]
        let arrayJSON = #"[1.2,2.2000000000000002,3.2000000000000002,4.2000000000000002]"#
        let json = "{\"test_key_ArrayDouble\":{\"$in\":\(arrayJSON)}}"
        let filter: Filter<FilterTestScope> = .in(.testKeyArrayDouble, values: array)
        return FilterCodingTestPair(json: json, filter: filter)
    }

    static func notInArrayString() -> FilterCodingTestPair {
        let array = ["1", "2", "3", "4"]
        let arrayJSON = #"["1","2","3","4"]"#
        let json = "{\"test_key_ArrayString\":{\"$nin\":\(arrayJSON)}}"
        let filter: Filter<FilterTestScope> = .notIn(.testKeyArrayString, values: array)
        return FilterCodingTestPair(json: json, filter: filter)
    }

    static func query() -> FilterCodingTestPair {
        let json = #"{"test_key":{"$q":"Quick brown fox jump over lazy dog"}}"#
        let filter: Filter<FilterTestScope> = .query(.testKey, text: "Quick brown fox jump over lazy dog")
        return FilterCodingTestPair(json: json, filter: filter)
    }

    static func autocomplete() -> FilterCodingTestPair {
        let json = #"{"test_key":{"$autocomplete":"Autocomp"}}"#
        let filter: Filter<FilterTestScope> = .autocomplete(.testKey, text: "Autocomp")
        return FilterCodingTestPair(json: json, filter: filter)
    }

    static func existsTrue() -> FilterCodingTestPair {
        existsFilter(exists: true)
    }

    static func notExists() -> FilterCodingTestPair {
        existsFilter(exists: false)
    }

    static func containsAndEqual() -> FilterCodingTestPair {
        let json = #"{"$and":[{"test_key_ArrayString":{"$contains":"12345"}},{"test_key_Int":{"$eq":54321}}]}"#
        let filter: Filter<FilterTestScope> = .and([
            .contains(.testKeyArrayString, value: "12345"),
            .equal(.testKeyInt, to: 54321)
        ])
        return FilterCodingTestPair(json: json, filter: filter)
    }

    static func greaterOrLess() -> FilterCodingTestPair {
        let json = #"{"$or":[{"test_key_Int":{"$gt":98765}},{"test_key_Double":{"$lt":23.449999999999999}}]}"#
        let filter: Filter<FilterTestScope> = .or([
            .greater(.testKeyInt, than: 98765),
            .less(.testKeyDouble, than: 23.45)
        ])
        return FilterCodingTestPair(json: json, filter: filter)
    }

    static func nonEqualNorEqual() -> FilterCodingTestPair {
        let json = #"{"$nor":[{"test_key_Bool":{"$ne":true}},{"test_key_Double":{"$eq":678.89999999999998}}]}"#
        let filter: Filter<FilterTestScope> = .nor([
            .notEqual(.testKeyBool, to: true),
            .equal(.testKeyDouble, to: 678.9)
        ])
        return FilterCodingTestPair(json: json, filter: filter)
    }

    private static func existsFilter(exists: Bool) -> FilterCodingTestPair {
        let json = "{\"test_key_Int\":{\"$exists\":\(exists)}}"
        let filter: Filter<FilterTestScope> = .exists(.testKeyInt, exists: exists)
        return FilterCodingTestPair(json: json, filter: filter)
    }
}
