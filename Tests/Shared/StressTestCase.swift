//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import XCTest

/// Base class for stress tests
///
/// - runs 100 times if `TestRunnerEnvironment.isStressTest`
/// - removes all files in `NSTemporaryDirectory()` and `Documents` directory when test suite completes
/// - by default ends test when test failure occurs
class StressTestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
    }
    
    override class func tearDown() {
        do {
            // After running test suite cleanup `NSTemporaryDirectory()` and `Documents` directory
            let fileManager = FileManager.default
            let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            
            let tempFileURLs = try fileManager.contentsOfDirectory(
                at: tempDirectoryURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            try tempFileURLs.forEach {
                try fileManager.removeItem(at: $0)
            }
        } catch {
            XCTFail("Failed to clean up after tests: \(error)")
        }
        
        super.tearDown()
    }
    
    override func invokeTest() {
        for _ in 0..<TestRunnerEnvironment.testInvocations {
            autoreleasepool {
                super.invokeTest()
            }
        }
    }
}
