//
//  TableView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 24/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A custom chat table view.
public final class TableView: UITableView {
    
    /// Tracking classes consist of: (Identifier: Class)
    /// You should fill this array with the classes you want to track *before* registering your classes.
    var trackingClasses = [(identifier: String, class: AnyClass)]()
    /// Registered classes consist of: (TrackingReuseIdentifier: (RegisteredReuseIdentifier: RegisteredSubclass))
    /// You can use the info from this dictionary to dequeue cells.
    private(set) var registeredClasses = [String: (identifier: String, subclass: AnyClass)]()
    
    override public func register(_ cellClass: AnyClass?, forCellReuseIdentifier identifier: String) {
        if let cellClass = cellClass {
            for trackingClass in trackingClasses {
                if cellClass.isSubclass(of: trackingClass.class) {
                    registeredClasses[trackingClass.identifier] = (identifier, cellClass)
                    break
                }
            }
        }
        
        super.register(cellClass, forCellReuseIdentifier: identifier)
    }
}
