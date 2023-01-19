//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// A component that can be used to change an attachment which was successfully uploaded.
public protocol UploadedAttachmentPostProcessor {
    func process(uploadedAttachment: UploadedAttachment) -> UploadedAttachment
}
