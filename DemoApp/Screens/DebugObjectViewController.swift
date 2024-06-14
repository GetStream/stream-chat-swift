//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

class DebugObjectViewController: UITableViewController {
    let object: Any?

    init(object: Any?) {
        self.object = object
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum DebugValue {
        case raw(String)
        case object(Any?)
    }

    var data: [(label: String?, value: DebugValue)] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let object = self.object else {
            data = []
            return
        }

        data = Mirror(reflecting: object)
            .children
            .filter {
                $0.label?.hasPrefix("_") == false || $0.label == nil
            }
            .map {
                var value: DebugValue
                if let dateValue = $0.value as? Date {
                    if #available(iOS 15.0, *) {
                        value = .raw(dateValue.formatted())
                    } else {
                        value = .raw(dateValue.description)
                    }
                } else if let rawRepresentable = $0.value as? any RawRepresentable,
                          let stringValue = rawRepresentable.rawValue as? LosslessStringConvertible {
                    value = .raw(String(stringValue))
                } else if let stringValue = $0.value as? LosslessStringConvertible {
                    value = .raw(String(stringValue))
                } else if case Optional<Any>.none = $0.value {
                    value = .object(nil)
                } else {
                    value = .object($0.value)
                }
                return ($0.label, value)
            }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = data[indexPath.item]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "debug-cell")
        switch item.value {
        case .raw(let value):
            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = String(value)
            cell.accessoryView = UIImageView(image: UIImage(systemName: "doc.on.doc")!)
        case .object(let object):
            if object == nil {
                cell.textLabel?.text = item.label
                cell.detailTextLabel?.text = "nil"
            } else {
                cell.textLabel?.text = item.label ?? object.debugDescription
                cell.accessoryView = UIImageView(image: UIImage(resource: .iconArrowRight))
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = data[indexPath.item]
        switch item.value {
        case .raw(let value):
            UIPasteboard.general.string = value
            presentAlert(title: "Saved to Clipboard!", message: value)
        case .object(let object):
            guard let object = object else {
                return
            }
            let debugVC = DebugObjectViewController(object: object)
            show(debugVC, sender: self)
        }
    }
}