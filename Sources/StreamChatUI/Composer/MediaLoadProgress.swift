//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Holds the progress of loading a media item, which is only known once the loading started.
@MainActor final class MediaLoadProgress {
    var progress: Progress?
    private(set) var isCloudDownload = false

    func observedFractionCompleted() -> Double? {
        guard let progress else { return nil }
        // Only a download file operation is an iCloud fetch. Local copies can
        // also report incremental progress.
        if !isCloudDownload {
            isCloudDownload = progress.fileOperationKind == .downloading
        }
        return progress.fractionCompleted
    }
}
