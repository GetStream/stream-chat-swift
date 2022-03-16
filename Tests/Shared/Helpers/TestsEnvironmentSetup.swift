//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// Class encapsulating one-time setup code for all the tests of `StreamChatTests`.
final class TestsEnvironmentSetup: NSObject {
    override init() {
        super.init()
        cleanUpTempFolder()
    }
    
    func cleanUpTempFolder() {
        do {
            // Before running the test suite cleanup the `NSTemporaryDirectory()` directory
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
            var shouldFail = true
            #if os(macOS)
            // On macOS NSTemporaryDirectory contains all kinds of temporary files we
            // don't have access to, so .removeItem will fail for them with 513 error code
            shouldFail = (error as NSError).code != 513
            #endif
            if shouldFail {
                fatalError("Failed to clean up before tests: \(error)")
            }
        }
    }
}
