//
//  Reusable.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 08/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

protocol Reusable {
    /// The reuse identifier to use when registering and later dequeuing a reusable cell.
    static var reuseIdentifier: String { get }
    
    /// Performs any clean up necessary to prepare the view for use again.
    func reset()
}

extension Reusable {
    /// By default, use the name of the class as String for its reuseIdentifier.
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
