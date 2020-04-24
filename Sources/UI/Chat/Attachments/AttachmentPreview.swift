//
//  AttachmentPreviewProtocol.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 12/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import StreamChatCore
import RxSwift

protocol AttachmentPreview where Self: UIView {
    typealias Completion = (AttachmentPreview, Error?) -> Void
    
    /// An index in the message stack view.
    var index: Int { get set }
    /// An attachment.
    var attachment: Attachment? { get }
    var disposeBag: DisposeBag { get }
    
    /// Setup a message style.
    func setup(attachment: Attachment, style: MessageViewStyle)
    
    /// Update image mask.
    func update(imageMask: UIImage?)
    
    /// Update attachment preview with a given attachment.
    func update(_ completion: @escaping Completion)
}
