//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

final class AttachmentDownloader_Spy: AttachmentDownloader, Spy {
    let spyState = SpyState()
    @Atomic var downloadAttachmentProgress: Double?
    @Atomic var downloadAttachmentResult: Error?

    func download(_ attachment: ChatMessageFileAttachment, to localURL: URL, progress: ((Double) -> Void)?, completion: @escaping ((any Error)?) -> Void) {
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
