//
//  AppDelegate.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 29/03/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Client.config = .init(apiKey: "qk4nn7rpcn75", logOptions: .all)
        
        Client.shared.set(user: User(id: "broken-waterfall-5", name: "Jon Snow", avatarURL: URL(string: "https://bit.ly/2u9Vc0r")),
                          token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg")
        
        let channel = Channel(id: "general",
                              name: "Talk about Go",
                              imageURL: URL(string: "https://cdn.chrisshort.net/testing-certificate-chains-in-go/GOPHER_MIC_DROP.png"))
        
        if let tabBarController = window?.rootViewController as? UITabBarController {
            tabBarController.viewControllers?.enumerated().forEach { index, viewController in
                var chatViewController: ChatViewController?
                
                if let viewController = viewController as? ChatViewController {
                    chatViewController = viewController
                } else if let navigationController = viewController as? UINavigationController {
                    chatViewController = navigationController.viewControllers.first as? ChatViewController
                }
                
                if let chatViewController = chatViewController {
                    chatViewController.channelPresenter = ChannelPresenter(channel: channel)
                    let isDark = index % 2 != 0
                    chatViewController.title = isDark ? "Dark" : "Light"
                    chatViewController.style = isDark ? ChatViewStyle.dark : ChatViewStyle()
                }
            }
        }
        
        return true
    }
}
