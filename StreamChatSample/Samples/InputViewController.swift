//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

class InputViewController<InputType: LosslessStringConvertible>: UITableViewController {
    private lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.addTarget(self, action: #selector(textFieldDidChangeValue), for: .editingChanged)
        textField.keyboardType = self.initialValue is String ? .alphabet : .numberPad
        textField.text = String(self.currentTextValue)
        textField.textAlignment = .left
        textField.clearButtonMode = .whileEditing
        return textField
    }()
    
    private var initialValue: InputType
    private var currentTextValue: String
    
    var onChange: ((InputType) -> Void)?
    
    init(title: String, initialValue: InputType) {
        self.initialValue = initialValue
        currentTextValue = String(initialValue)
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        save()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value2, reuseIdentifier: nil)
        inputTextField.frame = cell.frame
        cell.accessoryView = inputTextField
        return cell
    }
    
    @objc func textFieldDidChangeValue(sender: UITextField) {
        if let newValue = sender.text {
            currentTextValue = newValue
        }
    }
    
    private func save() {
        guard let newValue = InputType(currentTextValue) else {
            alert(title: "Invalid Input!", message: "\(currentTextValue) is not a valid value.")
            return
        }
        onChange?(newValue)
        inputTextField.resignFirstResponder()
    }
}
