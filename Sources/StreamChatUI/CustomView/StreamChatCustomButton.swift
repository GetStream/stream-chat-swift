//
//  StreamChatCustomButton.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 02/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class StreamChatCustomButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -15, dy: -15).contains(point)
    }
}
