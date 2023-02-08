//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import XCTest

final class AnyEquatable_Tests: XCTestCase {
    // MARK: - isEquatable

    func test_enum_isEquatable_returnsExpectedResults() {
        let itemA = AnyEquatable(TestTypeEnum.value(10))
        let itemB = AnyEquatable(TestTypeEnum.value(10))
        let itemC = AnyEquatable(TestTypeEnum.value(11))

        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
    }

    func test_struct_isEquatable_returnsExpectedResults() {
        let itemA = AnyEquatable(TestTypeStruct(value: 10))
        let itemB = AnyEquatable(TestTypeStruct(value: 10))
        let itemC = AnyEquatable(TestTypeStruct(value: 11))

        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
    }

    func test_class_isEquatable_returnsExpectedResults() {
        let itemA = AnyEquatable(TestTypeClass(value: 10))
        let itemB = AnyEquatable(TestTypeClass(value: 10))
        let itemC = AnyEquatable(TestTypeClass(value: 11))

        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
    }

    func test_classNSObject_isEquatable_returnsExpectedResults() {
        let itemA = AnyEquatable(TestTypeClassNSObject(value: 10))
        let itemB = AnyEquatable(TestTypeClassNSObject(value: 10))
        let itemC = AnyEquatable(TestTypeClassNSObject(value: 11))

        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
    }

    // MARK: - isNotEquatable

    func test_enum_isNotEquatable_returnsExpectedResults() {
        let itemA = AnyEquatable(TestNotTypeEnum.value(10))
        let itemB = AnyEquatable(TestNotTypeEnum.value(10))
        let itemC = AnyEquatable(TestNotTypeEnum.value(11))

        XCTAssertNotEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
    }

    func test_struct_isNotEquatable_returnsExpectedResults() {
        let itemA = AnyEquatable(TestNotTypeStruct(value: 10))
        let itemB = AnyEquatable(TestNotTypeStruct(value: 10))
        let itemC = AnyEquatable(TestNotTypeStruct(value: 11))

        XCTAssertNotEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
    }

    func test_class_isNotEquatable_returnsExpectedResults() {
        let itemA = AnyEquatable(TestNotTypeClass(value: 10))
        let itemB = AnyEquatable(TestNotTypeClass(value: 10))
        let itemC = AnyEquatable(TestNotTypeClass(value: 11))

        XCTAssertNotEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
    }

    func test_classNSObject_isNotEquatable_returnsExpectedResults() {
        let itemA = AnyEquatable(TestNotTypeClassNSObject(value: 10))
        let itemB = AnyEquatable(TestNotTypeClassNSObject(value: 10))
        let itemC = AnyEquatable(TestNotTypeClassNSObject(value: 11))

        XCTAssertNotEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
    }
}

extension AnyEquatable_Tests {
    private enum TestTypeEnum: Equatable { case value(Int) }
    private enum TestNotTypeEnum { case value(Int) }

    private struct TestTypeStruct: Equatable { var value: Int }
    private struct TestNotTypeStruct { var value: Int }

    private final class TestTypeClass: Equatable {
        var value: Int

        init(value: Int) {
            self.value = value
        }

        static func == (
            lhs: TestTypeClass,
            rhs: TestTypeClass
        ) -> Bool { lhs.value == rhs.value }
    }

    private final class TestNotTypeClass {
        var value: Int
        init(value: Int) { self.value = value }
    }

    private final class TestTypeClassNSObject: NSObject {
        var value: Int

        init(value: Int) {
            self.value = value
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let typedObject = object as? TestTypeClassNSObject else {
                return false
            }
            return value == typedObject.value
        }
    }

    private final class TestNotTypeClassNSObject: NSObject {
        var value: Int
        init(value: Int) { self.value = value }
    }
}
