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
        case channelId = "channel_id"
        case channelType = "channel_type"
        case messageId = "message_id"
    }
    
    /// A message reference: channel id + message id.
    public typealias MessageReference = (channelId: String, channelType: ChannelType, messageId: String)
    /// A custom local notification content.
    public typealias LocalNotificationContent = (Message, Channel) -> UNNotificationContent
    /// A callback type to open a chat view controller with a given message reference.
    public typealias ShowNewMessageCallback = (MessageReference) -> Void
    
    /// A callback to create a custom local notification for a new message when the app in the background.
    public var localNotificationContent: LocalNotificationContent?
    
    /// A shared instance of notifications manager.
    public static let shared = Notifications()
    
    var disposeBag = DisposeBag()
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    /// A callback to open a chat view controller with a given message id and channel id.
    public var showNewMessage: ShowNewMessageCallback?
    
    /// Enablde clearing application icon badge number when app become active.
    public var clearApplicationIconBadgeNumberOnAppActive = false {
        didSet {
            if clearApplicationIconBadgeNumberOnAppActive {
                observeActiveAppStateForClearing()
            } else {
                disposeBag = DisposeBag()
            }
        }
    }
    
    var logger: ClientLogger?
    
    /// Enable logs for Notifications.
    public var logsEnabled: Bool = false {
        didSet {
            logger = logsEnabled ? ClientLogger(icon: "🗞") : nil
        }
    }
    
    override init() {
        super.init()
        
        if UNUserNotificationCenter.current().delegate == nil {
            UNUserNotificationCenter.current().delegate = self
        }
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
        
        let content = createLocalNotificationContent(newMessage: message, in: channel)
        let request = UNNotificationRequest(identifier: message.id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func createLocalNotificationContent(newMessage message: Message, in channel: Channel) -> UNNotificationContent {
        if let localNotificationContent = localNotificationContent {
            return localNotificationContent(message, channel)
        }
        
        var body = message.textOrArgs
        
        if body.isEmpty, let attachment = message.attachments.first {
            body = attachment.title
            
            if body.isEmpty, let text = attachment.text {
                body = text
            }
            
            if body.isEmpty, let file = attachment.file {
                body = "A \(file.type.rawValue) file \(file.sizeString)"
            }
        }
        
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
        
        let content = UNMutableNotificationContent()
        content.title = "\(message.user.name) @ \(channel.name)"
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = (UIApplication.shared.applicationIconBadgeNumber + 1) as NSNumber
        
        content.userInfo = [NotificationUserInfoKeys.channelId.rawValue: channel.id,
                            NotificationUserInfoKeys.channelType.rawValue: channel.type.rawValue,
                            NotificationUserInfoKeys.messageId.rawValue: message.id]
        
        return content
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension Notifications: UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        if let messageReference = Notifications.parseMessageReference(notificationResponse: response) {
            showNewMessage?(messageReference)
        }
        
        completionHandler()
    }
    
    /// Parse a notification response user info for a message reference.
    ///
    /// - Parameter response: a message reference (see `MessageReference`).
    public static func parseMessageReference(notificationResponse response: UNNotificationResponse) -> MessageReference? {
        let userInfo = response.notification.request.content.userInfo
        
        guard let channelId = userInfo[NotificationUserInfoKeys.channelId.rawValue] as? String,
            let channelTypeString = userInfo[NotificationUserInfoKeys.channelType.rawValue] as? String,
            let messageId = userInfo[NotificationUserInfoKeys.messageId.rawValue] as? String,
            let channelType = ChannelType(rawValue: channelTypeString) else {
                return nil
        }
        
        return (channelId, channelType, messageId)
    }
}

// MARK: - Clearing App Icon Badge Number

extension Notifications {
    
    func observeActiveAppStateForClearing() {
        DispatchQueue.main.async {
            self.clear()
            
            UIApplication.shared.rx.appState
                .filter { $0 == .active }
                .subscribe(onNext: { [weak self] _ in self?.clear() })
                .disposed(by: self.disposeBag)
        }
    }
    
    func clear() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
