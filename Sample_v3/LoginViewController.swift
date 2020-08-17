//
//  LoginViewController.swift
//  StreamChatClient
//
//  Created by Matheus Cardoso on 14/08/20.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import Combine

import StreamChatClient

class LoginViewController: UITableViewController {
    @IBOutlet weak var tokenTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var jwtCell: UITableViewCell!
    @IBOutlet weak var apiKeyTextField: UITextField!
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var jwtTextField: UITextField!
    
    var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tokenTypeSegmentedControl.publisher(for: \.selectedSegmentIndex).sink { _ in
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }.store(in: &cancellables)
    }
}

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
                    let storyboard = UIStoryboard(name: "SimpleChat",   bundle: nil)
                    let initial = storyboard.instantiateInitialViewController()
                    UIView.transition(with: self.view.window!, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                        self.view.window?.rootViewController = initial
                    })
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
}

// MARK: - Inputs
extension LoginViewController {
    var apiKey: String {
        return apiKeyTextField.text ?? ""
    }
    
    var userId: String {
        return userIdTextField.text ?? ""
    }
    
    var userName: String {
        return userNameTextField.text ?? ""
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
