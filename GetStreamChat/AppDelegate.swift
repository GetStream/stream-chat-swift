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
        
        Client.config = .init(apiKey: "qk4nn7rpcn75", logOptions: .webSocket)
        
        Client.shared.set(user: User(id: "broken-waterfall-5", name: "Jon Snow", avatarURL: URL(string: "https://bit.ly/2u9Vc0r")),
                          token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg")
        
        let channel = Channel(id: "general",
                              name: "Talk about Go",
                              imageURL: URL(string: "https://cdn.chrisshort.net/testing-certificate-chains-in-go/GOPHER_MIC_DROP.png"))
        
        if let chatViewController = window?.rootViewController as? ChatViewController {
            chatViewController.channelPresenter = ChannelPresenter(channel: channel)
        }
        
        return true
    }
}
