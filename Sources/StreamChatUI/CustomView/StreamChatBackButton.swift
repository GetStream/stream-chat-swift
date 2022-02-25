//
//  StreamChatBackButton.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 23/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class StreamChatBackButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -15, dy: -15).contains(point)
    }
}
