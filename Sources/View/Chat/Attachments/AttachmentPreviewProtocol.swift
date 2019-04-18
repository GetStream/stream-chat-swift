//
//  AttachmentPreviewProtocol.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 12/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public protocol AttachmentPreviewProtocol where Self: UIView {
    /// An attachment.
    var attachment: Attachment? { get set }
    
    /// Update attachment preview with a given attachment and image mask.
    func update(maskImage: UIImage?)
}
