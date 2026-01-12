//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A component that can be used to change an attachment which was successfully uploaded.
public protocol UploadedAttachmentPostProcessor: Sendable {
    func process(uploadedAttachment: UploadedAttachment) -> UploadedAttachment
}
