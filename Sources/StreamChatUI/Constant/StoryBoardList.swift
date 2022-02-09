//
//  StoryBoardList.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 09/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//
import UIKit

struct StoryBoardList {
    static let GROUP = UIStoryboard(name: "GroupChat", bundle: nil)
}

struct ChatColor {
    //
    static let DESCRIPTION = UIColor(red: 0.53, green: 0.55, blue: 0.58, alpha: 1.00)
    static let STATUS = UIColor(red: 0.55, green: 0.70, blue: 0.97, alpha: 1.00)
}


extension UIColor {
    
    static let tabbarBackground = generateColor(0x161616, lightAlpha: 1.0, 0x161616, darkAlpha: 1.0)
    static let viewBackground = generateColor(0x131314, lightAlpha: 1.0, 0x131314, darkAlpha: 1.0)
    static let searchBarBackground = generateColor(0x1C1C1E, lightAlpha: 1.0, 0x1C1C1E, darkAlpha: 1.0)
    
    static func generateColor(_ light: Int, lightAlpha: CGFloat = 1.0, _ dark: Int, darkAlpha: CGFloat = 1.0) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(rgb: dark).withAlphaComponent(darkAlpha)
                    : UIColor(rgb: light).withAlphaComponent(lightAlpha)
            }
        } else {
            return UIColor(rgb: light).withAlphaComponent(lightAlpha)
        }
    }
}
