//
//  UITableViewCell+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit.UITableViewCell
import UIKit.UICollectionViewCell

extension UITableViewCell {
    /// A shortcut of an unused `UITableViewCell`.
    public static let unused = UITableViewCell(style: .default, reuseIdentifier: "unused")
}

extension UICollectionViewCell {
    /// A shortcut of an unused `UICollectionViewCell`.
    public static let unused = UICollectionViewCell(frame: .zero)
}
