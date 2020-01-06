//
//  SeparatorStyle.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 06/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

/// A separator style.
public struct SeparatorStyle: Hashable {
    
    public static let none = SeparatorStyle(tableStyle: .none)
    
    /// The color of separator rows in the table view.
    public let color: UIColor?
    /// The default inset of cell separators.
    public let inset: UIEdgeInsets
    /// The style for table cells used as separators (see `TableView.separatorStyle`).
    public let tableStyle: UITableViewCell.SeparatorStyle
    
    /// Init a separator style.
    /// - Parameters:
    ///   - color: a color of separator rows in the table view.
    ///   - inset: a default inset of cell separators.
    ///   - tableStyle: a style for table cells used as separators (see `TableView.separatorStyle`).
    public init(color: UIColor? = nil, inset: UIEdgeInsets = .zero, tableStyle: UITableViewCell.SeparatorStyle = .singleLine) {
        self.color = color
        self.inset = inset
        self.tableStyle = tableStyle
    }
    
    public static func == (lhs: SeparatorStyle, rhs: SeparatorStyle) -> Bool {
        return lhs.color == rhs.color
            && lhs.inset == rhs.inset
            && lhs.tableStyle == rhs.tableStyle
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(color)
        hasher.combine(inset.top)
        hasher.combine(inset.left)
        hasher.combine(inset.bottom)
        hasher.combine(inset.right)
        hasher.combine(tableStyle)
    }
}
