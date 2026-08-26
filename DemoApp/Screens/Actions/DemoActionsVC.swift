//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// A modally presented, hierarchical list of demo actions.
///
/// Submenus are pushed on the same navigation stack, and selecting an action
/// dismisses the whole modal before running the action handler.
final class DemoActionsVC: UITableViewController {
    private let group: DemoActionGroup
    private let isSearchEnabled: Bool
    private var displayedSections: [DemoActionSection]

    private lazy var searchableItems = group.searchableItems()
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search actions"
        return searchController
    }()

    init(group: DemoActionGroup, isSearchEnabled: Bool = false) {
        self.group = group
        self.isSearchEnabled = isSearchEnabled
        displayedSections = group.sections
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func present(_ group: DemoActionGroup, from presenter: UIViewController) {
        let actionsVC = DemoActionsVC(group: group, isSearchEnabled: true)
        let navigationVC = UINavigationController(rootViewController: actionsVC)
        navigationVC.modalPresentationStyle = .pageSheet
        navigationVC.sheetPresentationController?.detents = [.large()]
        navigationVC.sheetPresentationController?.prefersGrabberVisible = true
        presenter.present(navigationVC, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = group.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        tableView.register(DemoActionCell.self, forCellReuseIdentifier: DemoActionCell.reuseIdentifier)

        if isSearchEnabled {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            // Without this, on iOS 26 the search field docks to the bottom of the
            // sheet and floats on top of the last rows instead of being tappable.
            if #available(iOS 16.0, *) {
                navigationItem.preferredSearchBarPlacement = .stacked
            }
            definesPresentationContext = true
        }
    }

    @objc private func closeTapped() {
        dismissModal()
    }

    private func dismissModal(completion: (() -> Void)? = nil) {
        let presenter = presentingViewController ?? self
        presenter.dismiss(animated: true, completion: completion)
    }

    // MARK: - Table view

    override func numberOfSections(in tableView: UITableView) -> Int {
        displayedSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedSections[section].items.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        displayedSections[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DemoActionCell.reuseIdentifier, for: indexPath)
        guard let actionCell = cell as? DemoActionCell else { return cell }
        actionCell.configure(with: displayedSections[indexPath.section].items[indexPath.row])
        return actionCell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch displayedSections[indexPath.section].items[indexPath.row] {
        case .group(let group):
            navigationController?.pushViewController(DemoActionsVC(group: group), animated: true)
        case .action(let item):
            guard item.isEnabled else { return }
            let handler = item.handler
            dismissModal(completion: handler)
        }
    }
}

// MARK: - Search

extension DemoActionsVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !query.isEmpty else {
            displayedSections = group.sections
            tableView.reloadData()
            return
        }

        let matches = searchableItems.filter {
            $0.item.title.range(of: query, options: .caseInsensitive) != nil
                || $0.breadcrumb.range(of: query, options: .caseInsensitive) != nil
        }
        displayedSections = [
            DemoActionSection(
                matches.isEmpty ? "No results" : "\(matches.count) results",
                items: matches.map { .action($0.item.replacingSubtitle($0.breadcrumb)) }
            )
        ]
        tableView.reloadData()
    }
}

// MARK: - Cell

private final class DemoActionCell: UITableViewCell {
    static let reuseIdentifier = "DemoActionCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with action: DemoAction) {
        detailTextLabel?.numberOfLines = 0
        detailTextLabel?.textColor = .secondaryLabel
        textLabel?.numberOfLines = 0

        switch action {
        case .group(let group):
            textLabel?.text = group.title
            textLabel?.textColor = .label
            detailTextLabel?.text = group.subtitle ?? "\(group.numberOfActions) actions"
            imageView?.image = group.icon.flatMap { UIImage(systemName: $0) }
            accessoryType = .disclosureIndicator
            selectionStyle = .default

        case .action(let item):
            textLabel?.text = item.title
            textLabel?.textColor = actionTextColor(for: item)
            detailTextLabel?.text = item.subtitle
            imageView?.image = nil
            accessoryType = .none
            selectionStyle = item.isEnabled ? .default : .none
        }
    }

    private func actionTextColor(for item: DemoActionItem) -> UIColor {
        guard item.isEnabled else { return .tertiaryLabel }
        return item.isDestructive ? .systemRed : .label
    }
}
