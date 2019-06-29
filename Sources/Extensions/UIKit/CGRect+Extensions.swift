//
//  CGRect+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 07/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension CGRect {
    
    init(edge: CGFloat) {
        self.init(x: 0, y: 0, width: edge, height: edge)
    }
    
    init(width: CGFloat, height: CGFloat = 0) {
        self.init(x: 0, y: 0, width: width, height: height > 0 ? height : width)
    }
}
