//
//  AttachmentFileType+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 23/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

extension AttachmentFileType {
    var icon: UIImage {
        return UIImage.chat(named: rawValue.lowercased())
    }
}
