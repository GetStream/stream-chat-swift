//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class AttachmentDownloader_Spy: AttachmentDownloader, Spy {
    let spyState = SpyState()
    @Atomic var downloadAttachmentProgress: Double?
    @Atomic var downloadAttachmentResult: Error?

    func download(from remoteURL: URL, to localURL: URL, progress: ((Double) -> Void)?, completion: @escaping ((any Error)?) -> Void) {
        record()
        if let downloadAttachmentProgress {
            progress?(downloadAttachmentProgress)
        }
        
        if let downloadAttachmentResult {
            DispatchQueue.main.async {
                completion(downloadAttachmentResult)
            }
        }
    }
}
