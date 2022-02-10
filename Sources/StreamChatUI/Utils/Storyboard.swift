//
//  Storyboard.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 30/12/21.
//

import UIKit

/// Storyboards
public enum StreamChatStoryboard: String {
    case wallet = "Wallet"
    case PrivateGroup = "PrivateGroup"
    case GroupChat = "GroupChat"
}

///// Instantiate View Controller
public extension UIViewController {
    open class func instantiateController<T: UIViewController>(storyboard: StreamChatStoryboard) -> T? {
        let storyboard = UIStoryboard(name: storyboard.rawValue, bundle: nil)
        let identifier = String(describing: self)
        return storyboard.instantiateViewController(withIdentifier: identifier) as? T
    }
}
