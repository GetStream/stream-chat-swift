//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

import StreamChat
import StreamChatUI

class LoginViewController: UITableViewController {
    @IBOutlet var uiKitAndDelegatesCell: UITableViewCell!
    @IBOutlet var uiKitAndCombineCell: UITableViewCell!
    @IBOutlet var swiftUICell: UITableViewCell!
    
    @IBOutlet var streamDesignCell: UITableViewCell!
    
    func logIn() -> ChatClient {
        var config = ChatClientConfig(apiKey: APIKey(Configuration.apiKey))
        config.isLocalStorageEnabled = Configuration.isLocalStorageEnabled
        config.shouldFlushLocalStorageOnStart = Configuration.shouldFlushLocalStorageOnStart
        config.baseURL = Configuration.baseURL

        let tokenProvider: TokenProvider = Configuration.token.map { .static($0) } ?? .guest(
            userId: Configuration.userId,
            name: Configuration.userName
        )
        
        let chatClient = ChatClient(
            config: config,
            tokenProvider: tokenProvider,
            completion: {
                guard let error = $0 else { return }
                DispatchQueue.main.async {
                    let viewController = UIApplication.shared.keyWindow?.rootViewController
                    viewController?.alert(title: "Error", message: "Error logging in: \(error)") {
                        viewController?.moveToStoryboard(.main, options: [.transitionFlipFromRight])
                    }
                }
            }
        )
        
        return chatClient
    }
}

// MARK: - Sample Navigation

extension LoginViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let chatClient = logIn()
        
        let channelListController = chatClient.channelListController(
            query: _ChannelListQuery(
                filter: .containMembers(userIds: [chatClient.currentUserId!]),
                pageSize: 25
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
            #if swift(>=5.3)
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
            #else
            alert(title: "Swift 5.3 required", message: "The app needs to be compiled with Swift 5.3 or above.")
            #endif
        case streamDesignCell:
            
            let channelList = ChatChannelListVC<NoExtraData>()
            
            channelList.controller = channelListController
            
            // An example of change default appearance
            ChatChannelListItemView<NoExtraData>.defaultAppearance {
                $0.backgroundColor = .yellow
            }

            ChatChannelListVC<NoExtraData>.defaultAppearance {
                $0.title = "Custom title"
            }
            
            let navigation = UINavigationController(
                navigationBarClass: channelList.uiConfig.navigation.navigationBar.self,
                toolbarClass: nil
            )
            navigation.viewControllers = [channelList]

            UIView.transition(with: view.window!, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                self.view.window?.rootViewController = navigation
            })
        default:
            return
        }
    }
}

final class MyChatChannelListRouter: ChatChannelListRouter<NoExtraData> {
    override func openChat(for channel: _ChatChannel<NoExtraData>) {
        let chatScreen = ChatChannelVC<NoExtraData>()
        chatScreen.channelController = rootViewController.controller.client.channelController(for: channel.cid)
        navigationController?.pushViewController(chatScreen, animated: true)
    }
}
