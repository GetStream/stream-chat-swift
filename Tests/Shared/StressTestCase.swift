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
        // After running test suite cleanup `NSTemporaryDirectory()` and `Documents` directory
        let fileManager = FileManager.default
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let tempFileURLs = (try? fileManager.contentsOfDirectory(
            at: tempDirectoryURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []
        let documentsFileURLs = documentsURL.flatMap { try? FileManager.default.contentsOfDirectory(
            at: $0,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) } ?? []
        
        for fileURL in tempFileURLs + documentsFileURLs {
            try? fileManager.removeItem(at: fileURL)
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
