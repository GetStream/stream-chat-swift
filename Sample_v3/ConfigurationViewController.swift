//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tokenTypeSegmentedControl.addTarget(self, action: #selector(tokenTypeSegmentedControlDidChangeValue), for: .valueChanged)
    }
    
    @objc func tokenTypeSegmentedControlDidChangeValue() {
        tableView.beginUpdates()
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
        let users = [
            (
                name: "Broken Waterfall",
                id: "broken-waterfall-5",
                jwt: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg"
            ),
            (
                name: "Suspicious Coyote",
                id: "suspicious-coyote-3",
                jwt: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoic3VzcGljaW91cy1jb3lvdGUtMyJ9.xVaBHFTexlYPEymPmlgIYCM5M_iQVHrygaGS1QhkaEE"
            ),
            (
                name: "Steep Moon",
                id: "steep-moon-9",
                jwt: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoic3RlZXAtbW9vbi05In0.xwGjOwnTy3r4o2owevNTyzZLWMsMh_bK7e5s1OQ2zXU"
            )
        ]
        
        if let user = users.randomElement() {
            userId = user.id
            userName = user.name
            token = user.jwt
        }
    }
    
    @IBAction func donePressed(_ sender: Any) {
        dismiss(animated: true)
    }
}

// MARK: - UITableView

extension ConfigurationViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView.cellForRow(at: indexPath) {
        case jwtCell:
            return heightForJwtCell()
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    func heightForJwtCell() -> CGFloat {
        if tokenTypeSegmentedControl.selectedSegmentIndex != 0 {
            return 0
        } else {
            return jwtCell.intrinsicContentSize.height
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
        get {
            switch tokenTypeSegmentedControl.selectedSegmentIndex {
            case 0:
                return jwtTextField.text ?? ""
            case 1:
                return nil
            case 2:
                return .development
            default:
                fatalError("Segmented Control out of bounds")
            }
        }
        
        set {
            switch newValue {
            case nil:
                tokenTypeSegmentedControl.selectedSegmentIndex = 1
            case Token.development:
                tokenTypeSegmentedControl.selectedSegmentIndex = 2
            default:
                tokenTypeSegmentedControl.selectedSegmentIndex = 0
                jwtTextField.text = newValue
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
        }
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
