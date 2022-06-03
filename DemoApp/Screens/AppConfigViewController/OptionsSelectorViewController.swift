//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

class OptionsSelectorViewController<OptionType: Hashable>: UITableViewController {
    var didChangeSelectedOptions: (([OptionType]) -> Void)?
    var cellType = UITableViewCell.CellStyle.default

    private(set) var options: [OptionType]
    private(set) var selectedOptions: [OptionType] = [] {
        didSet {
            didChangeSelectedOptions?(selectedOptions)
        }
    }

    init(
        options: [OptionType],
        initialSelectedOptions: [OptionType],
        allowsMultipleSelection: Bool
    ) {
        self.options = options
        if allowsMultipleSelection {
            selectedOptions = initialSelectedOptions
        } else if let initialOption = initialSelectedOptions.first {
            selectedOptions = [initialOption]
        }
        super.init(nibName: nil, bundle: nil)
        tableView.allowsMultipleSelection = allowsMultipleSelection
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = options[indexPath.row]
        let cell = UITableViewCell(style: cellType, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.text = "\(option)"

        if selectedOptions.contains(option) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            cell.accessoryType = .checkmark
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        didUpdateSelections()
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .none
        didUpdateSelections()
    }

    private func didUpdateSelections() {
        let selectedRows = tableView.indexPathsForSelectedRows?.map(\.row) ?? []
        selectedOptions = options
            .enumerated()
            .filter { selectedRows.contains($0.offset) }
            .map(\.element)
    }
}
