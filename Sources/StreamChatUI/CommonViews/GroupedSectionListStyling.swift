//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// Helper to create a grouped section list styling in a table view.
///
/// The default `UITableViewStye.insetGrouped` is not enough because
/// it does not group sections or footers.
protocol GroupedSectionListStyling {
    /// Whether the grouped section styling is enabled.
    /// It is useful to easily disable the grouped section styling.
    var isGroupedSectionStylingEnabled: Bool { get }
    /// The background color of the table view.
    var listBackgroundColor: UIColor { get }
    /// The background color for each section.
    var sectionBackgroundColor: UIColor { get }
    /// The corner radius amount of each section group.
    var sectionCornerRadius: CGFloat { get }
}

extension GroupedSectionListStyling {
    /// Styles each cell of the table view.
    /// - Parameters:
    ///   - cell: The actual table view cell.
    ///   - contentView: The main view of the table view cell.
    ///   - isLastItem: Whether it is the last item in the section or not.
    func style(cell: UITableViewCell, contentView: UIView, isLastItem: Bool) {
        guard isGroupedSectionStylingEnabled else {
            return
        }

        cell.backgroundColor = listBackgroundColor
        contentView.backgroundColor = sectionBackgroundColor
        if isLastItem {
            contentView.layer.cornerRadius = sectionCornerRadius
            contentView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        } else {
            contentView.layer.cornerRadius = 0
            contentView.layer.maskedCorners = []
        }
    }

    /// Styles the table header view.
    /// - Parameters:
    ///   - tableHeaderView: The `tableView.tableHeaderView`.
    ///   - contentView: The content view that of the table header view.
    func style(tableHeaderView: UIView, contentView: UIView) {
        guard isGroupedSectionStylingEnabled else {
            return
        }

        tableHeaderView.backgroundColor = listBackgroundColor
        contentView.backgroundColor = sectionBackgroundColor
        contentView.layer.cornerRadius = sectionCornerRadius
    }

    /// Styles the header view of each section
    /// - Parameters:
    ///   - sectionHeaderView: The actual `UITableViewHeaderFooterView`.
    ///   - contentView: The content view of the header.
    ///   - isEmptySection: Whether the section has empty data or not.
    func style(sectionHeaderView: UITableViewHeaderFooterView, contentView: UIView, isEmptySection: Bool) {
        guard isGroupedSectionStylingEnabled else {
            return
        }

        sectionHeaderView.backgroundColor = listBackgroundColor
        contentView.backgroundColor = sectionBackgroundColor
        contentView.layer.cornerRadius = sectionCornerRadius
        if isEmptySection {
            contentView.layer.maskedCorners = .all
        } else {
            contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
    }

    /// Styles the footer view of each section
    /// - Parameters:
    ///   - sectionFooterView: The actual `UITableViewHeaderFooterView`.
    ///   - contentView: The content view of the footer.
    func style(sectionFooterView: UITableViewHeaderFooterView, contentView: UIView) {
        guard isGroupedSectionStylingEnabled else {
            return
        }

        sectionFooterView.backgroundColor = listBackgroundColor
        contentView.backgroundColor = sectionBackgroundColor
        contentView.layer.cornerRadius = sectionCornerRadius
        contentView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
    }
}
