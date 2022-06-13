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
    func register<Cell: UITableViewCell>(_ type: Cell.Type) {
        register(type, forCellReuseIdentifier: type.reuseIdentifier)
    }
    
    public func dequeueReusableCell<Cell: UITableViewCell>(with type: Cell.Type, for indexPath: IndexPath) -> Cell {
        dequeueReusableCell(withIdentifier: type.reuseIdentifier, for: indexPath) as! Cell
    }
}

extension UICollectionViewCell: Reusable {}

extension UICollectionView {
    func register<Cell: UICollectionViewCell>(_ type: Cell.Type) {
        register(type, forCellWithReuseIdentifier: type.reuseIdentifier)
    }
    
    public func dequeueReusableCell<Cell: UICollectionViewCell>(with type: Cell.Type, for indexPath: IndexPath) -> Cell {
        dequeueReusableCell(withReuseIdentifier: type.reuseIdentifier, for: indexPath) as! Cell
    }
}

// swiftlint:enable force_cast
