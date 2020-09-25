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

    func logIn() -> ChatClient {
        let extraData = NameAndImageExtraData(name: userName, imageURL: nil)
        let chatClient = ChatClient(config: ChatClientConfig(apiKeyString: apiKey))
        
        func setUserCompletion(_ error: Error?) {
            guard let error = error else { return }
            alert(title: "Error", message: "Error logging in: \(error)")
            navigationController?.popToRootViewController(animated: true)
        }
        
        let currentUserController = chatClient.currentUserController()
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
        let chatClient = logIn()
        
        let channelListController = chatClient.channelListController(
            query: ChannelListQuery(
                filter: .in("members", [chatClient.currentUserId]),
                pagination: [.limit(25)],
                options: [.watch]
            )
        )
        
        switch indexPath {
        case .simpleChatIndexPath:
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
        case .swiftUISimpleChatIndexPath:
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
        case .combineUIKitSimpleChatIndexPath:
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
        default:
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - IndexPath

private extension IndexPath {
    static let jwtIndexPath = IndexPath(row: 4, section: 0)
    static let simpleChatIndexPath = IndexPath(row: 0, section: 1)
    static let swiftUISimpleChatIndexPath = IndexPath(row: 1, section: 1)
    static let combineUIKitSimpleChatIndexPath = IndexPath(row: 2, section: 1)
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
            return nil
        case 2:
            return .development
        default:
            return jwtTextField.text ?? ""
        }
    }
}
