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
    
    @IBOutlet var regionSegmentedControl: UISegmentedControl!
    @IBOutlet var localStorageEnabledSwitch: UISwitch!
    @IBOutlet var flushLocalStorageSwitch: UISwitch!
    
    @IBOutlet var uiKitAndDelegatesCell: UITableViewCell!
    @IBOutlet var uiKitAndCombineCell: UITableViewCell!
    @IBOutlet var swiftUICell: UITableViewCell!
    
    func logIn() -> ChatClient {
        var config = ChatClientConfig(apiKey: APIKey(apiKey))
        
        config.isLocalStorageEnabled = localStorageEnabledSwitch.isOn
        config.shouldFlushLocalStorageOnStart = flushLocalStorageSwitch.isOn
        config.baseURL = baseURL
        
        let chatClient = ChatClient(config: config)
        
        let currentUserController = chatClient.currentUserController()
        let extraData = NameAndImageExtraData(name: userName, imageURL: nil)
        
        func setUserCompletion(_ error: Error?) {
            guard let error = error else { return }
            
            DispatchQueue.main.async {
                self.alert(title: "Error", message: "Error logging in: \(error)")
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
        
        if let token = token {
            currentUserController.setUser(
                userId: userId,
                userExtraData: extraData,
                token: token,
                completion: setUserCompletion
            )
        } else {
            currentUserController.setGuestUser(
                userId: userId,
                extraData: extraData,
                completion: setUserCompletion
            )
        }
        
        return chatClient
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tokenTypeSegmentedControl.addTarget(self, action: #selector(tokenTypeSegmentedControlDidChangeValue), for: .valueChanged)
    }
    
    @objc
    func tokenTypeSegmentedControlDidChangeValue() {
        tableView.beginUpdates()
        tableView.endUpdates()
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
            userIdTextField.text = user.id
            userNameTextField.text = user.name
            jwtTextField.text = user.jwt
        }
    }
}

// MARK: - UITableView

extension LoginViewController {
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

// MARK: - Sample Navigation

extension LoginViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section == 1 else { return }

        let chatClient = logIn()
        
        let channelListController = chatClient.channelListController(
            query: ChannelListQuery(
                filter: .in("members", [chatClient.currentUserId]),
                pagination: [.limit(25)],
                options: [.watch]
            )
        )
        
        switch tableView.cellForRow(at: indexPath) {
        case uiKitAndDelegatesCell:
            let storyboard = UIStoryboard(name: "SimpleChat", bundle: nil)
            
            guard
                let initial = storyboard.instantiateInitialViewController() as? SplitViewController,
                let navigation = initial.viewControllers.first as? UINavigationController,
                let channels = navigation.children.first as? SimpleChannelsViewController
            else {
                return
            }
            
            channels.channelListController = channelListController

            UIView.transition(with: view.window!, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                self.view.window?.rootViewController = initial
            })
        case uiKitAndCombineCell:
            if #available(iOS 13, *) {
                let storyboard = UIStoryboard(name: "CombineSimpleChat", bundle: nil)
                
                guard
                    let initial = storyboard.instantiateInitialViewController() as? SplitViewController,
                    let navigation = initial.viewControllers.first as? UINavigationController,
                    let channels = navigation.children.first as? CombineSimpleChannelsViewController
                else {
                    return
                }
                
                channels.channelListController = channelListController

                UIView.transition(with: view.window!, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                    self.view.window?.rootViewController = initial
                })
            } else {
                alert(title: "iOS 13 required", message: "You need iOS 13 to run this sample.")
            }
        case swiftUICell:
            if #available(iOS 14, *) {
                // Ideally, we'd pass the `Client` instance as the environment object and create the list controller later.
                UIView.transition(with: self.view.window!, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                    self.view.window?.rootViewController = UIHostingController(
                        rootView:
                        NavigationView {
                            ChannelListView(channelList: channelListController.observableObject)
                        }
                    )
                })
            } else {
                alert(title: "iOS 14 required", message: "You need iOS 14 to run this sample.")
            }
        default:
            return
        }
    }
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
    
    var baseURL: BaseURL {
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

    var token: Token? {
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
}
