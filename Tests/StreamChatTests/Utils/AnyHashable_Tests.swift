//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import XCTest

final class AnyHashable_Tests: XCTestCase {
    // MARK: - isHashable

    func test_enum_isHashable_returnsExpectedResults() {
        let itemA = AnyHashable(TestTypeEnum.value(10))
        let itemB = AnyHashable(TestTypeEnum.value(10))
        let itemC = AnyHashable(TestTypeEnum.value(11))

        XCTAssertEqual(itemA.hashValue, itemB.hashValue)
        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA.hashValue, itemC.hashValue)
        XCTAssertNotEqual(itemA, itemC)
    }

    func test_struct_isHashable_returnsExpectedResults() {
        let itemA = AnyHashable(TestTypeStruct(value: 10))
        let itemB = AnyHashable(TestTypeStruct(value: 10))
        let itemC = AnyHashable(TestTypeStruct(value: 11))

        XCTAssertEqual(itemA.hashValue, itemB.hashValue)
        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA.hashValue, itemC.hashValue)
        XCTAssertNotEqual(itemA, itemC)
    }

    func test_class_isHashable_returnsExpectedResults() {
        let itemA = AnyHashable(TestTypeClass(value: 10))
        let itemB = AnyHashable(TestTypeClass(value: 10))
        let itemC = AnyHashable(TestTypeClass(value: 11))

        XCTAssertEqual(itemA.hashValue, itemB.hashValue)
        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA.hashValue, itemC.hashValue)
        XCTAssertNotEqual(itemA, itemC)
    }

    func test_classNSObject_isEquatable_returnsExpectedResults() {
        let itemA = AnyHashable(TestTypeClassNSObject(value: 10))
        let itemB = AnyHashable(TestTypeClassNSObject(value: 10))
        let itemC = AnyHashable(TestTypeClassNSObject(value: 11))

        XCTAssertEqual(itemA.hashValue, itemB.hashValue)
        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA.hashValue, itemC.hashValue)
        XCTAssertNotEqual(itemA, itemC)
    }

    // MARK: - isNotHashable

    func test_enum_isNotHashable_returnsExpectedResults() {
        let itemA = AnyHashable(TestNotTypeEnum.value(10))
        let itemB = AnyHashable(TestNotTypeEnum.value(10))
        let itemC = AnyHashable(TestNotTypeEnum.value(11))

        XCTAssertNotEqual(itemA.hashValue, itemB.hashValue)
        XCTAssertNotEqual(itemA, itemB)
        XCTAssertNotEqual(itemA.hashValue, itemC.hashValue)
        XCTAssertNotEqual(itemA, itemC)
    }

    func test_struct_isNotHashable_returnsExpectedResults() {
        let itemA = AnyHashable(TestNotTypeStruct(value: 10))
        let itemB = AnyHashable(TestNotTypeStruct(value: 10))
        let itemC = AnyHashable(TestNotTypeStruct(value: 11))

        XCTAssertNotEqual(itemA.hashValue, itemB.hashValue)
        XCTAssertNotEqual(itemA, itemB)
        XCTAssertNotEqual(itemA.hashValue, itemC.hashValue)
        XCTAssertNotEqual(itemA, itemC)
    }

    func test_class_isNotHashable_returnsExpectedResults() {
        let itemA = AnyHashable(TestNotTypeClass(value: 10))
        let itemB = AnyHashable(TestNotTypeClass(value: 10))
        let itemC = AnyHashable(TestNotTypeClass(value: 11))

        XCTAssertNotEqual(itemA.hashValue, itemB.hashValue)
        XCTAssertNotEqual(itemA, itemB)
        XCTAssertNotEqual(itemA.hashValue, itemC.hashValue)
        XCTAssertNotEqual(itemA, itemC)
    }

    func test_classNSObject_isNotHashable_returnsExpectedResults() {
        let itemA = AnyHashable(TestNotTypeClassNSObject(value: 10))
        let itemB = AnyHashable(TestNotTypeClassNSObject(value: 10))
        let itemC = AnyHashable(TestNotTypeClassNSObject(value: 11))

        XCTAssertNotEqual(itemA.hashValue, itemB.hashValue)
        XCTAssertNotEqual(itemA, itemB)
        XCTAssertNotEqual(itemA.hashValue, itemC.hashValue)
        XCTAssertNotEqual(itemA, itemC)
    }
}

extension AnyHashable_Tests {
    private enum TestTypeEnum: Hashable { case value(Int) }
    private enum TestNotTypeEnum { case value(Int) }

    private struct TestTypeStruct: Hashable { var value: Int }
    private struct TestNotTypeStruct { var value: Int }

    private final class TestTypeClass: Hashable {
        var value: Int

        init(value: Int) {
            self.value = value
        }

        func hash(
            into hasher: inout Hasher
        ) {
            hasher.combine(value)
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

        override var hash: Int { value.hashValue }

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
