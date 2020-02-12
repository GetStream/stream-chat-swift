//
//  AttachmentFileType+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 23/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import StreamChatCore

extension AttachmentFileType {
    var icon: UIImage { UIImage.chat(named: rawValue.lowercased()) }
}
