//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

extension UITableViewHeaderFooterView: Reusable {}

extension UITableView {
    /// Registers a `UITableViewCell` from a supplied type
    /// The identifier is used from the reuseIdentifier parameter.
    /// - Parameter type: A generic cell type.
    func register<Cell: UITableViewCell>(_ type: Cell.Type) {
        register(type, forCellReuseIdentifier: type.reuseIdentifier)
    }

    /// Dequeues a `UITableView` cell with a generic type and indexPath.
    /// - Parameters:
    ///   - type: A generic cell type.
    ///   - indexPath: The indexPath of the row in the UITableView.
    /// - Returns: A cell from the type passed through.
    func dequeueReusableCell<Cell: UITableViewCell>(with type: Cell.Type, for indexPath: IndexPath, reuseIdentifier: String? = nil) -> Cell {
        dequeueReusableCell(withIdentifier: reuseIdentifier ?? type.reuseIdentifier, for: indexPath) as! Cell
    }

    /// Registers a `UITableViewHeaderFooterView` from a supplied type.
    /// The identifier is used from the reuseIdentifier parameter.
    /// - Parameter type: A generic header footer type.
    func register<HeaderFooter: UITableViewHeaderFooterView>(_ type: HeaderFooter.Type) {
        register(type, forHeaderFooterViewReuseIdentifier: type.reuseIdentifier)
    }

    /// Dequeues a `UITableViewHeaderFooterView` cell with a generic type and indexPath.
    /// - Parameters:
    ///   - type: A generic header footer type.
    ///   - indexPath: The indexPath of the row in the UITableView.
    /// - Returns: A header footer type from the type passed through.
    func dequeueReusableHeaderFooter<HeaderFooter: UITableViewHeaderFooterView>(
        with type: HeaderFooter.Type
    ) -> HeaderFooter {
        dequeueReusableHeaderFooterView(withIdentifier: type.reuseIdentifier) as! HeaderFooter
    }
}

extension UICollectionViewCell: Reusable {}

extension UICollectionView {
    /// Registers a UICollectionViewCell from a supplied type.
    /// The identifier is used from the reuseIdentifier parameter.
    /// - Parameter type: A generic type.
    func register<Cell: UICollectionViewCell>(_ type: Cell.Type) {
        register(type, forCellWithReuseIdentifier: type.reuseIdentifier)
    }

    /// Dequeues a UICollectionView Cell with a generic type and indexPath.
    /// - Parameters:
    ///   - type: A generic cell type.
    ///   - indexPath: The indexPath of the row in the UICollectionView.
    /// - Returns: A Cell from the type passed through.
    func dequeueReusableCell<Cell: UICollectionViewCell>(with type: Cell.Type, for indexPath: IndexPath, reuseIdentifier: String? = nil) -> Cell {
        dequeueReusableCell(withReuseIdentifier: reuseIdentifier ?? type.reuseIdentifier, for: indexPath) as! Cell
    }

    func dequeueReusableSupplementaryView<View: UICollectionReusableView>(
        with type: View.Type,
        ofKind kind: String,
        for indexPath: IndexPath
    ) -> View {
        dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: String(describing: type),
            for: indexPath
        ) as! View
    }
}

// swiftlint:enable force_cast
