//
//  AppDelegate.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 29/03/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatCore
import RxSwift
import RxCocoa

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let disposeBag = DisposeBag()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        DateFormatter.log = nil
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("🗞📱", "App did register for remote notifications with DeviceToken")
        
        Client.shared.addDevice(deviceToken: deviceToken)
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("🗞❌", error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("🗞📮", userInfo)
    }
}
