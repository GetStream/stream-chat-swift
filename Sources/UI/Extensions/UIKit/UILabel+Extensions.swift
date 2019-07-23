//
//  UILabel+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 28/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: - Text

extension UILabel {
    var textOrEmpty: String {
        return text ?? ""
    }
}
