//
//  VerticalAlignment.swift
//  StreamChat
//
//  Created by Bahadir Oncel on 28.02.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

/// The element vertical alignment.
public enum VerticalAlignment {
    /// The name/avatar aligned from the top with `edgeInsets.top` top offset.
    /// The message aligned after the name with `spacing.vertical` top offset.
    case top
    /// The avatar aligned in the center of the cell.
    /// The name aligned from the center of the cell with `spacing.vertical / 2` bottom offset.
    /// The message aligned from the center of the cell with `spacing.vertical / 2` top offset.
    case center
}
