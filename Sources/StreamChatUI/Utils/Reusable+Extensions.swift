//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

protocol Reusable {
    static var reuseIdentifier: String { get }
}

extension Reusable {
    static var reuseIdentifier: String {
        String(describing: self)
    }
}

// swiftlint:disable force_cast
extension UITableViewCell: Reusable {}

extension UITableView {
    /// Registers a `UITableViewCell` from a supplied type
    /// The identifier is used from the reuseIdentifier parameter
    /// - Parameter type: A generic cell type
    func register<Cell: UITableViewCell>(_ type: Cell.Type) {
        register(type, forCellReuseIdentifier: type.reuseIdentifier)
    }
    
    /// Dequeues a `UITableView` cell with a generic type and indexPath
    /// - Parameters:
    ///   - type: A generic cell type
    ///   - indexPath: The indexPath of the row in the UITableView
    /// - Returns: A cell from the type passed through
    public func dequeueReusableCell<Cell: UITableViewCell>(with type: Cell.Type, for indexPath: IndexPath) -> Cell {
        dequeueReusableCell(withIdentifier: type.reuseIdentifier, for: indexPath) as! Cell
    }
}

extension UICollectionViewCell: Reusable {}

extension UICollectionView {
    /// Registers a UICollectionViewCell from a supplied type
    /// The identifier is used from the reuseIdentifier parameter
    /// - Parameter type: A generic type
    func register<Cell: UICollectionViewCell>(_ type: Cell.Type) {
        register(type, forCellWithReuseIdentifier: type.reuseIdentifier)
    }
    
    /// Dequeues a UICollectionView Cell with a generic type and indexPath
    /// - Parameters:
    ///   - type: A generic cell type
    ///   - indexPath: The indexPath of the row in the UICollectionView
    /// - Returns: A Cell from the type passed through
    public func dequeueReusableCell<Cell: UICollectionViewCell>(with type: Cell.Type, for indexPath: IndexPath) -> Cell {
        dequeueReusableCell(withReuseIdentifier: type.reuseIdentifier, for: indexPath) as! Cell
    }
}

// swiftlint:enable force_cast
