//
//  NSMutableParagraphStyle+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension NSParagraphStyle {
    static let `default`: NSParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.1
        return paragraphStyle
    }()
}
