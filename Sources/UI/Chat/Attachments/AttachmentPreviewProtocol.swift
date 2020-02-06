//
//  AttachmentPreviewProtocol.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 12/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import RxSwift

protocol AttachmentPreviewProtocol where Self: UIView {
    typealias Completion = (Self, Error?) -> Void
    
    var disposeBag: DisposeBag { get }
    
    /// An attachment.
    var attachment: Attachment? { get set }
    
    /// Update attachment preview with a given attachment and image mask.
    func update(maskImage: UIImage?, _ completion: @escaping Completion)
}
