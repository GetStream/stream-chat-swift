//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import XCTest

final class AnyComparable_Tests: XCTestCase {
    // MARK: - isComparable

    func test_enum_isComparable_returnsExpectedResults() {
        let itemA = AnyComparable(TestTypeEnum.value(10))
        let itemB = AnyComparable(TestTypeEnum.value(10))
        let itemC = AnyComparable(TestTypeEnum.value(11))

        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
        XCTAssertTrue(itemA < itemC)
        XCTAssertTrue(itemA <= itemC)
        XCTAssertTrue(itemC != itemA)
        XCTAssertTrue(itemC >= itemA)
        XCTAssertTrue(itemB == itemA)
    }

    func test_struct_isComparable_returnsExpectedResults() {
        let itemA = AnyComparable(TestTypeStruct(value: 10))
        let itemB = AnyComparable(TestTypeStruct(value: 10))
        let itemC = AnyComparable(TestTypeStruct(value: 11))

        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
        XCTAssertTrue(itemA < itemC)
        XCTAssertTrue(itemA <= itemC)
        XCTAssertTrue(itemC != itemA)
        XCTAssertTrue(itemC >= itemA)
        XCTAssertTrue(itemB == itemA)
    }

    func test_class_isComparable_returnsExpectedResults() {
        let itemA = AnyComparable(TestTypeClass(value: 10))
        let itemB = AnyComparable(TestTypeClass(value: 10))
        let itemC = AnyComparable(TestTypeClass(value: 11))

        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
        XCTAssertTrue(itemA < itemC)
        XCTAssertTrue(itemA <= itemC)
        XCTAssertTrue(itemC != itemA)
        XCTAssertTrue(itemC >= itemA)
        XCTAssertTrue(itemB == itemA)
    }

    func test_classNSObject_isEquatable_returnsExpectedResults() {
        let itemA = AnyComparable(TestTypeClassNSObject(value: 10))
        let itemB = AnyComparable(TestTypeClassNSObject(value: 10))
        let itemC = AnyComparable(TestTypeClassNSObject(value: 11))

        XCTAssertEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
        XCTAssertTrue(itemA < itemC)
        XCTAssertTrue(itemA <= itemC)
        XCTAssertTrue(itemC != itemA)
        XCTAssertTrue(itemC >= itemA)
        XCTAssertTrue(itemB == itemA)
    }

    // MARK: - isNotComparable

    func test_enum_isNotComparable_returnsExpectedResults() {
        let itemA = AnyComparable(TestNotTypeEnum.value(10))
        let itemB = AnyComparable(TestNotTypeEnum.value(10))
        let itemC = AnyComparable(TestNotTypeEnum.value(11))

        XCTAssertNotEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
        XCTAssertFalse(itemA < itemC)
        XCTAssertTrue(itemA <= itemC)
        XCTAssertTrue(itemC != itemA)
        XCTAssertTrue(itemC >= itemA)
        XCTAssertFalse(itemB == itemA)
    }

    func test_struct_isNotComparable_returnsExpectedResults() {
        let itemA = AnyComparable(TestNotTypeStruct(value: 10))
        let itemB = AnyComparable(TestNotTypeStruct(value: 10))
        let itemC = AnyComparable(TestNotTypeStruct(value: 11))

        XCTAssertNotEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
        XCTAssertFalse(itemA < itemC)
        XCTAssertTrue(itemA <= itemC)
        XCTAssertTrue(itemC != itemA)
        XCTAssertTrue(itemC >= itemA)
        XCTAssertFalse(itemB == itemA)
    }

    func test_class_isNotComparable_returnsExpectedResults() {
        let itemA = AnyComparable(TestNotTypeClass(value: 10))
        let itemB = AnyComparable(TestNotTypeClass(value: 10))
        let itemC = AnyComparable(TestNotTypeClass(value: 11))

        XCTAssertNotEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
        XCTAssertFalse(itemA < itemC)
        XCTAssertTrue(itemA <= itemC)
        XCTAssertTrue(itemC != itemA)
        XCTAssertTrue(itemC >= itemA)
        XCTAssertFalse(itemB == itemA)
    }

    func test_classNSObject_isNotComparable_returnsExpectedResults() {
        let itemA = AnyComparable(TestNotTypeClassNSObject(value: 10))
        let itemB = AnyComparable(TestNotTypeClassNSObject(value: 10))
        let itemC = AnyComparable(TestNotTypeClassNSObject(value: 11))

        XCTAssertNotEqual(itemA, itemB)
        XCTAssertNotEqual(itemA, itemC)
        XCTAssertFalse(itemA < itemC)
        XCTAssertTrue(itemA <= itemC)
        XCTAssertTrue(itemC != itemA)
        XCTAssertTrue(itemC >= itemA)
        XCTAssertFalse(itemB == itemA)
    }
}

extension AnyComparable_Tests {
    private enum TestTypeEnum: Comparable { case value(Int) }
    private enum TestNotTypeEnum { case value(Int) }

    private struct TestTypeStruct: Comparable {
        var value: Int

        static func < (
            lhs: TestTypeStruct,
            rhs: TestTypeStruct
        ) -> Bool { lhs.value < rhs.value }
    }

    private struct TestNotTypeStruct { var value: Int }

    private final class TestTypeClass: Comparable {
        var value: Int

        init(value: Int) {
            self.value = value
        }

        static func < (
            lhs: TestTypeClass,
            rhs: TestTypeClass
        ) -> Bool { lhs.value < rhs.value }

        static func == (
            lhs: TestTypeClass,
            rhs: TestTypeClass
        ) -> Bool { lhs.value == rhs.value }
    }

    private final class TestNotTypeClass {
        var value: Int
        init(value: Int) { self.value = value }
    }

    private final class TestTypeClassNSObject: NSObject, Comparable {
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

        static func < (
            lhs: AnyComparable_Tests.TestTypeClassNSObject,
            rhs: AnyComparable_Tests.TestTypeClassNSObject
        ) -> Bool {
            lhs.value < rhs.value
        }
    }

    private final class TestNotTypeClassNSObject: NSObject {
        var value: Int
        init(value: Int) { self.value = value }
    }
}
