//
//  AppDelegate.swift
//  V3SampleApp
//
//  Created by Vojta on 28/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
@testable import StreamChatClient

var chatClient: ChatClient = {
    var config = ChatClientConfig(apiKey: APIKey("qk4nn7rpcn75"))
    config.isLocalStorageEnabled = false
    return ChatClient(config: config)
}()

func logIn(apiKey: String, userId: String, userName: String, token: Token?, completion: @escaping () -> Void) {
    var config = ChatClientConfig(apiKey: APIKey("qk4nn7rpcn75"))
    config.isLocalStorageEnabled = false
    chatClient = ChatClient(config: config)
    
    let extraData = NameAndImageExtraData(name: userName, imageURL: nil)
    
    if let token = token {
        chatClient.setUser(userId: userId, userExtraData: extraData, token: token) { _ in
            completion()
        }
    } else {
        chatClient.setGuestUser(userId: userId, extraData: extraData) { _ in
            completion()
        }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        LogConfig.formatters = [PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"]),
                                PingPongEmojiFormatter()]
        
        LogConfig.showThreadName = false
        LogConfig.showDate = false
        LogConfig.showFunctionName = false
        
        LogConfig.level = .info
        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
