//
//  Storyboard.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 30/12/21.
//

import UIKit

/// Storyboards
enum Storyboard: String {
    case wallet = "Wallet"
}

///// Instantiate View Controller
extension UIViewController {
    class func instantiate<T: UIViewController>(appStoryboard: Storyboard) -> T? {
        let storyboard = UIStoryboard(name: appStoryboard.rawValue, bundle: nil)
        let identifier = String(describing: self)
        return storyboard.instantiateViewController(withIdentifier: identifier) as? T
    }
}
