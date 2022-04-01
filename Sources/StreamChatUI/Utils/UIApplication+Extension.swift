//
//  UIApplication+Extension.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 04/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIApplication {

    func getTopViewController() -> UIViewController? {
        let keyWindow = self.windows.first(where: { $0.isKeyWindow })
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return keyWindow?.rootViewController
    }
    
    var keyWindowInConnectedScenes: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.connectedScenes
                .first(where: { $0 is UIWindowScene })
                .flatMap({ $0 as? UIWindowScene })?.windows
                .first(where: \.isKeyWindow)
        } else {
            return nil
        }
    }
}
