//
//  Notifications.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 27/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import UserNotifications
import RxSwift
import RxAppState

final class Notifications {
    
    static let shared = Notifications()
    
    let disposeBag = DisposeBag()
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var iconBadgeNumber: Int = 0
    
    init() {
        clear()
        
        UIApplication.shared.rx.appState.subscribe(onNext: { [weak self] state in
            if state == .active {
                self?.clear()
            }
        })
        .disposed(by: disposeBag)
    }
    
    func clear() {
        iconBadgeNumber = 0
        UIApplication.shared.applicationIconBadgeNumber = 0
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func askForPermissionsIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.authorizationStatus = settings.authorizationStatus
            
            if settings.authorizationStatus == .notDetermined {
                self.askForPermissions()
            } else if settings.authorizationStatus == .denied {
                print("🗞❌ Notifications denied")
            } else {
                print("🗞👍 Notifications authorized (\(settings.authorizationStatus.rawValue))")
            }
        }
        
    }
    
    func askForPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { didAllow, error in
            if didAllow {
                self.authorizationStatus = .authorized
                print("🗞👍 User has accepter notifications")
            } else if let error = error {
                print("🗞❌ User has declined notifications \(error)")
            } else {
                print("🗞❌ User has declined notifications: unknown reason")
            }
        }
    }
}

// MARK: - Message

extension Notifications {
    
    func showIfNeeded(newMessage message: Message, in channel: Channel) {
        DispatchQueue.main.async {
            if UIApplication.shared.appState == .background {
                self.show(newMessage: message, in: channel)
            }
        }
    }
    
    func show(newMessage message: Message, in channel: Channel) {
        guard authorizationStatus == .authorized else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = channel.name
        content.body = message.textOrArgs
        content.sound = UNNotificationSound.default
        iconBadgeNumber += 1
        content.badge = iconBadgeNumber as NSNumber
        
        let request = UNNotificationRequest(identifier: message.id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
