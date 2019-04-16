//
//  UITableViewCell+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit.UITableViewCell

extension UITableViewCell {
    /// A shortcut of an unused `UITableViewCell`.
    public static let unused: UITableViewCell = {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "unused")
        cell.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        return cell
    }()
}
