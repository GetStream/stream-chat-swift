//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public extension FileManager {
    /// Removes temporary files created with ``URL.newTemporaryFileURL``.
    static func removeAllTemporaryFiles() {
        let urls = try? FileManager.default.contentsOfDirectory(
            at: URL.temporaryDirectoryRoot,
            includingPropertiesForKeys: nil
        )
        guard let urls else { return }
        let urlsToDelete = urls.filter({ $0.lastPathComponent == URL.temporaryFileName })
        guard urlsToDelete.count > 0 else { return }
        urlsToDelete.forEach { url in
            try? FileManager.default.removeItem(at: url)
        }
        print("Deleted \(urlsToDelete.count) files in the temporary directory")
    }
}
