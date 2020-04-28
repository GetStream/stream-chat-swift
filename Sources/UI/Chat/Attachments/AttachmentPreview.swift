//
//  AttachmentPreviewProtocol.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 12/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient

protocol AttachmentPreview where Self: UIView {
    typealias Completion = (AttachmentPreview, Error?) -> Void
    
    /// An index in the message stack view.
    var index: Int { get set }
    /// An attachment.
    var attachment: Attachment? { get }
    
    /// Setup a message style.
    func setup(attachment: Attachment, style: MessageViewStyle)
    
    /// Update image mask.
    func apply(imageMask: UIImage?)
    
    /// Update attachment preview with a given attachment.
    func update(_ completion: Completion?)
}

extension AttachmentPreview {
    func update(_ completion: Completion? = nil) {
        update(completion)
    }
}
