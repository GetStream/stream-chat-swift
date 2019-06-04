//
//  UIEdgeInsets+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 07/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIEdgeInsets {
    init(all value: CGFloat) {
        self.init(top: value, left: value, bottom: value, right: value)
    }
    
    static func all(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(all: value)
    }
}
