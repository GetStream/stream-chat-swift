//
//  Notifications.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 27/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import UserNotifications
import RxSwift
import RxAppState

/// A notifications manager.
public final class Notifications: NSObject {
    enum NotificationUserInfoKeys: String {
        case channelId
        case messageId
    }
    
    /// A callback type to open a chat view controller with a given message id and channel id.
    public typealias OpenNewMessageCallback = (_ messageId: String, _ channelId: String) -> Void
    
    /// A shared instance of notifications manager.
    public static let shared = Notifications()
    
    let disposeBag = DisposeBag()
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var iconBadgeNumber: Int = 0
    
    /// A callback to open a chat view controller with a given message id and channel id.
    public var openNewMessage: OpenNewMessageCallback?
    
    var logger: ClientLogger?
    
    /// Enable logs for Notifications.
    public var logsEnabled: Bool = false {
        didSet {
            logger = logsEnabled ? ClientLogger(icon: "🗞") : nil
        }
    }
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self

        DispatchQueue.main.async {
            self.clear()
            
            UIApplication.shared.rx.appState
                .filter { $0 == .active }
                .subscribe(onNext: { [weak self] _ in self?.clear() })
                .disposed(by: self.disposeBag)
        }
    }
    
    func clear() {
        iconBadgeNumber = 0
        UIApplication.shared.applicationIconBadgeNumber = 0
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// Ask for permissions for notifications.
    public func askForPermissionsIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.authorizationStatus = settings.authorizationStatus
            
            if settings.authorizationStatus == .notDetermined {
                self.askForPermissions()
            } else if settings.authorizationStatus == .denied {
                self.logger?.log("❌ Notifications denied")
            } else {
                self.registerForPushNotifications()
                self.logger?.log("👍 Notifications authorized (\(settings.authorizationStatus.rawValue))")
            }
        }
    }
    
    /// Ask permissions to make notifications work.
    public func askForPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { didAllow, error in
            if didAllow {
                self.authorizationStatus = .authorized
                self.registerForPushNotifications()
                self.logger?.log("👍 User has accepted notifications")
            } else if let error = error {
                self.logger?.log("❌ User has declined notifications \(error)")
            } else {
                self.logger?.log("❌ User has declined notifications: unknown reason")
            }
        }
    }
    
    private func registerForPushNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        logger?.log("Register for remote notifications")
    }
}

// MARK: - Message

extension Notifications {
    
    /// Show a notification with a given message from a channel if the app in the background.
    ///
    /// - Parameters:
    ///   - message: a message.
    ///   - channel: a channel.
    public func showIfNeeded(newMessage message: Message, in channel: Channel) {
        DispatchQueue.main.async {
            if UIApplication.shared.appState == .background {
                self.show(newMessage: message, in: channel)
            }
        }
    }
    
    /// Show a notification with a given message from a channel.
    ///
    /// - Parameters:
    ///   - message: a message.
    ///   - channel: a channel.
    public func show(newMessage message: Message, in channel: Channel) {
        guard authorizationStatus == .authorized else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = channel.name
        content.body = message.textOrArgs
        content.sound = UNNotificationSound.default
        iconBadgeNumber += 1
        content.badge = iconBadgeNumber as NSNumber
        
        content.userInfo = [NotificationUserInfoKeys.messageId.rawValue: message.id,
                            NotificationUserInfoKeys.channelId.rawValue: channel.id]
        
        // TODO: Add attchament image or video. The url should refer to a file.
        //  1. Download image.
        //  2. Save to NSTemporaryDirectory() + "notifications" + message id
        //  3. Create attachment
        //  4. When a notification opened, remove all tmp images from NSTemporaryDirectory() + "notifications"
        //    if let attachment = message.attachments.first,
        //        attachment.isImage,
        //        let url = attachment.imageURL,
        //        !url.absoluteString.contains(".gif"),
        //        let notificationAttachment = try? UNNotificationAttachment(identifier: attachment.title, url: url) {
        //         content.attachments = [notificationAttachment]
        //    }
        
        let request = UNNotificationRequest(identifier: message.id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Handle Actions

extension Notifications: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        if let userInfo = response.notification.request.content.userInfo as? [String: String],
            let messageId = userInfo[NotificationUserInfoKeys.messageId.rawValue],
            let chanellId = userInfo[NotificationUserInfoKeys.channelId.rawValue] {
            openNewMessage?(messageId, chanellId)
        }
        
        completionHandler()
    }
}
