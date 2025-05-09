//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import XCTest

/// This is a workaround for a bug when Xcode ignores `@available()` marks at XCTestCase classes and runs them anyway. This causes
/// version-specific tests to crash on older iOS versions.
///
/// If you make you tests class a subclass of this class, it will still be visible to Xcode but the test won't be executed.
///
/// Stack overflow: https://stackoverflow.com/questions/59645536/available-attribute-does-not-work-with-xctest-classes-or-methods
open class iOS13TestCase: XCTestCase {
    override public func invokeTest() {
        return super.invokeTest()
    }
}
