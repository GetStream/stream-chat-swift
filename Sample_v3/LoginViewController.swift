//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

import StreamChatClient

class LoginViewController: UITableViewController {
    @IBOutlet var tokenTypeSegmentedControl: UISegmentedControl!
    @IBOutlet var jwtCell: UITableViewCell!
    @IBOutlet var apiKeyTextField: UITextField!
    @IBOutlet var userIdTextField: UITextField!
    @IBOutlet var userNameTextField: UITextField!
    @IBOutlet var jwtTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tokenTypeSegmentedControl.addTarget(self, action: #selector(tokenTypeSegmentedControlDidChangeValue), for: .valueChanged)
    }
    
    @objc
    func tokenTypeSegmentedControlDidChangeValue() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}

// MARK: - UITableView

extension LoginViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case .jwtIndexPath:
            return heightForJwtCell()
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    func heightForJwtCell() -> CGFloat {
        if tokenTypeSegmentedControl.selectedSegmentIndex != 0 {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAt: .jwtIndexPath)
        }
    }
}

// MARK: - Sample Navigation

extension LoginViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case .simpleChatIndexPath:
            logIn(apiKey: apiKey, userId: userId, userName: userName, token: token) {
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "SimpleChat", bundle: nil)
                    let initial = storyboard.instantiateInitialViewController()
                    UIView.transition(with: self.view.window!, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                        self.view.window?.rootViewController = initial
                    })
                }
            }
        case .swiftUISimpleChatIndexPath:
            if #available(iOS 13, *) {
                logIn(apiKey: apiKey, userId: userId, userName: userName, token: token) {
                    DispatchQueue.main.async {
                        UIView.transition(with: self.view.window!, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                            self.view.window?.rootViewController = UIHostingController(
                                rootView:
                                NavigationView {
                                    ChannelListView()
                                }
                            )
                        })
                    }
                }
            }
        default:
            return
        }
    }
}

// MARK: - IndexPath

private extension IndexPath {
    static let jwtIndexPath = IndexPath(row: 4, section: 0)
    static let simpleChatIndexPath = IndexPath(row: 0, section: 1)
    static let swiftUISimpleChatIndexPath = IndexPath(row: 1, section: 1)
}

// MARK: - Inputs

extension LoginViewController {
    var apiKey: String {
        apiKeyTextField.text ?? ""
    }
    
    var userId: String {
        userIdTextField.text ?? ""
    }
    
    var userName: String {
        userNameTextField.text ?? ""
    }
    
    var token: Token? {
        switch tokenTypeSegmentedControl.selectedSegmentIndex {
        case 0:
            return jwtTextField.text ?? ""
        case 1:
            return .development
        case 2:
            return nil
        default:
            return jwtTextField.text ?? ""
        }
    }
}
