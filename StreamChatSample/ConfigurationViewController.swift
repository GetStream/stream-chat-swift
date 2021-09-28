//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

class ConfigurationViewController: UITableViewController {
    @IBOutlet var jwtCell: UITableViewCell!
    
    @IBOutlet var apiKeyTextField: UITextField!
    @IBOutlet var userIdTextField: UITextField!
    @IBOutlet var userNameTextField: UITextField!
    @IBOutlet var jwtTextField: UITextField!
    
    @IBOutlet var tokenTypeSegmentedControl: UISegmentedControl!
    @IBOutlet var regionSegmentedControl: UISegmentedControl!

    @IBOutlet var localStorageEnabledSwitch: UISwitch!
    @IBOutlet var flushLocalStorageSwitch: UISwitch!
    
    private let jwtCellIndexPath = IndexPath(row: 4, section: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tokenTypeSegmentedControl.addTarget(self, action: #selector(tokenTypeSegmentedControlDidChangeValue), for: .valueChanged)
    }
    
    @objc func tokenTypeSegmentedControlDidChangeValue(_ control: UISegmentedControl) {
        tableView.beginUpdates()
        
        switch control.selectedSegmentIndex {
        case 1:
            tokenTypeSegmentedControl.selectedSegmentIndex = 1
            jwtTextField.isEnabled = false
            if tableView.numberOfRows(inSection: 0) > 4 {
                tableView.deleteRows(at: [jwtCellIndexPath], with: .top)
            }
            token = nil
        case 2:
            tokenTypeSegmentedControl.selectedSegmentIndex = 2
            jwtTextField.isEnabled = false
            if tableView.numberOfRows(inSection: 0) > 4 {
                tableView.deleteRows(at: [jwtCellIndexPath], with: .top)
            }
            token = .development(userId: userId)
        default:
            tokenTypeSegmentedControl.selectedSegmentIndex = 0
            jwtTextField.isEnabled = true
            token = Configuration.TestUser.defaults.first(where: { $0.id == userId })?.token
            tableView.insertRows(at: [jwtCellIndexPath], with: .top)
        }
        
        tableView.endUpdates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        apiKey = Configuration.apiKey
        userId = Configuration.userId
        userName = Configuration.userName
        baseURL = Configuration.baseURL
        token = Configuration.token
        isLocalStorageEnabled = Configuration.isLocalStorageEnabled
        shouldFlushLocalStorageOnStart = Configuration.shouldFlushLocalStorageOnStart
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Configuration.apiKey = apiKey
        Configuration.userId = userId
        Configuration.userName = userName
        Configuration.baseURL = baseURL
        Configuration.token = token
        Configuration.isLocalStorageEnabled = isLocalStorageEnabled
        Configuration.shouldFlushLocalStorageOnStart = shouldFlushLocalStorageOnStart
    }
    
    @IBAction func randomUserPressed(_ sender: Any) {
        if let user = Configuration.TestUser.defaults.shuffled().first(where: { $0.id != userId }) {
            userId = user.id
            userName = user.name
            token = user.token
        }
    }
    
    @IBAction func donePressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func didEndEditing(_ sender: UITextField) {
        sender.resignFirstResponder()
    }
}

extension ConfigurationViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return tokenTypeSegmentedControl.selectedSegmentIndex == 0 ? 5 : 4
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
}

// MARK: - Inputs

extension ConfigurationViewController {
    var apiKey: String {
        get { apiKeyTextField.text ?? "" }
        set { apiKeyTextField.text = newValue }
    }
    
    var userId: String {
        get { userIdTextField.text ?? "" }
        set { userIdTextField.text = newValue }
    }
    
    var userName: String {
        get { userNameTextField.text ?? "" }
        set { userNameTextField.text = newValue }
    }
    
    var baseURL: BaseURL {
        get {
            switch regionSegmentedControl.selectedSegmentIndex {
            case 0:
                return .usEast
            case 1:
                return .dublin
            case 2:
                return .singapore
            case 3:
                return .sydney
            default:
                fatalError("Segmented Control out of bounds")
            }
        }
        
        set {
            switch newValue.description {
            case BaseURL.usEast.description:
                regionSegmentedControl.selectedSegmentIndex = 0
            case BaseURL.dublin.description:
                regionSegmentedControl.selectedSegmentIndex = 1
            case BaseURL.singapore.description:
                regionSegmentedControl.selectedSegmentIndex = 2
            case BaseURL.sydney.description:
                regionSegmentedControl.selectedSegmentIndex = 3
            default:
                fatalError("Unknown BaseURL")
            }
        }
    }

    var token: Token? {
        get { try? Token(rawValue: jwtTextField.text ?? "") }
        set { jwtTextField.text = newValue?.rawValue }
    }
    
    var isLocalStorageEnabled: Bool {
        get { localStorageEnabledSwitch.isOn }
        set { localStorageEnabledSwitch.setOn(newValue, animated: false) }
    }
    
    var shouldFlushLocalStorageOnStart: Bool {
        get { flushLocalStorageSwitch.isOn }
        set { flushLocalStorageSwitch.setOn(newValue, animated: false) }
    }
}
