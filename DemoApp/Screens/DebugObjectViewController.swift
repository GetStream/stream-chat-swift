//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A debug view that recursively inspects an object.
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

        // swiftlint:disable syntactic_sugar

        data = Mirror(reflecting: object)
            .children
            .filter {
                // - ignore private methods (label starting with "_")
                // - do NOT ignore arrays or dictionaries (no labels)
                $0.label?.hasPrefix("_") == false || $0.label == nil
            }
            .map {
                var value: DebugValue
                
                if let url = $0.value as? URL {
                    /// URLs are not easily lossless convertible, so we need to treat this special case.
                    value = .raw(url.absoluteString)
                } else if let dateValue = $0.value as? Date {
                    /// Dates are by default present as Integers, so we format them.
                    if #available(iOS 15.0, *) {
                        value = .raw(dateValue.formatted())
                    } else {
                        value = .raw(dateValue.description)
                    }
                } else if let rawRepresentable = $0.value as? any RawRepresentable,
                          let stringValue = rawRepresentable.rawValue as? LosslessStringConvertible {
                    /// If a value is raw representable it won't be convertible
                    /// to string so we first get the rawValue.
                    value = .raw(String(stringValue))
                } else if let stringValue = $0.value as? LosslessStringConvertible {
                    /// All values that are LosslessStringConvertible are usually raw values.
                    value = .raw(String(stringValue))
                } else if case Optional<Any>.none = $0.value {
                    /// We need extract the Optional type from `Any` to check if it is nil or not.
                    value = .object(nil)
                } else if case Optional<Any>.some = $0.value {
                    /// Unwrap the value from Optional type from `Any`.
                    value = .object($0.value)
                } else {
                    /// Otherwise, it is an object that needs to inspected.
                    value = .object($0.value)
                }

                return ($0.label, value)
            }

        // swiftlint:enable syntactic_sugar
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
                if let labelText = item.label {
                    cell.textLabel?.text = labelText
                } else if let objectValue = object {
                    cell.textLabel?.text = String(describing: objectValue)
                }
                cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.right")!)
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
