//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

class EdgeCasesSettingsViewController: UITableViewController {
    let coordinator: EdgeCasesCoordinator
    let cases = CaseToCover.allCases

    var selectedCases: [CaseToCover] {
        coordinator.cases
    }

    init(coordinator: EdgeCasesCoordinator) {
        self.coordinator = coordinator
        super.init(style: .grouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellCase = cases[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = cellCase.title
        cell.detailTextLabel?.text = cellCase.subtitle

        let switchButton = SwitchButton()
        switchButton.isOn = selectedCases.contains(cellCase)
        switchButton.didChangeValue = { [weak self] in
            self?.updateValue(for: cellCase, enable: $0)
        }
        cell.accessoryView = switchButton

        return cell
    }

    private func updateValue(for updatedCase: CaseToCover, enable: Bool) {
        if enable {
            coordinator.cases.append(updatedCase)
        } else {
            guard let index = coordinator.cases.firstIndex(of: updatedCase) else { return }
            coordinator.cases.remove(at: index)
        }
    }
}
