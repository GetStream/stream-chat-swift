//
//  UIRectCorner+Extensions.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 08/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIRectCorner: Hashable {
    public static let leftSide: UIRectCorner = [.topLeft, .bottomLeft]
    public static let rightSide: UIRectCorner = [.topRight, .bottomRight]
    public static let pointedLeftBottom: UIRectCorner = [.topLeft, .topRight, .bottomRight]
    public static let pointedRightBottom: UIRectCorner = [.topLeft, .topRight, .bottomLeft]
}
