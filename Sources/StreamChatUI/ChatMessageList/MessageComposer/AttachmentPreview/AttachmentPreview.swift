//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// The attachment preview information.
public protocol AttachmentPreview {
    /// The name of the attachment.
    var name: String? { get }
    /// The size of the attachment.
    var size: Int64 { get }
    /// The image preview of the attachment.
    var image: UIImage { get }
}
