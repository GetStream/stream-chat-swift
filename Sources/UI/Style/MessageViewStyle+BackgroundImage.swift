//
//  MessageViewStyle+BackgroundImage.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 08/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension MessageViewStyle {
    struct BackgroundImage: Hashable {
        private let images: [Int: UIImage]
        private let defaultImage: UIImage?
        
        init(cornerRadius: CGFloat,
             pointedCornerRadius: CGFloat,
             corners: UIRectCorner,
             color: UIColor,
             backgroundColor: UIColor = .clear,
             borderWidth: CGFloat = 0,
             borderColor: UIColor = .black) {
            if #available(iOS 13, *) {
                let lightTrait = UITraitCollection(userInterfaceStyle: .light)
                let darkTrait = UITraitCollection(userInterfaceStyle: .dark)
                let lightColor = color.resolvedColor(with: lightTrait)
                let darkColor = color.resolvedColor(with: darkTrait)
                let lightBackgroundColor = backgroundColor.resolvedColor(with: lightTrait)
                let darkBackgroundColor = backgroundColor.resolvedColor(with: darkTrait)
                let lightBorderColor = borderColor.resolvedColor(with: lightTrait)
                let darkBorderColor = borderColor.resolvedColor(with: darkTrait)
                
                if lightColor != darkColor || lightBackgroundColor != darkBackgroundColor || lightBorderColor != darkBorderColor {
                    defaultImage = nil
                    
                    images = [UIUserInterfaceStyle.light.rawValue: .renderRounded(cornerRadius: cornerRadius,
                                                                                  pointedCornerRadius: pointedCornerRadius,
                                                                                  corners: corners,
                                                                                  color: lightColor,
                                                                                  backgroundColor: lightBackgroundColor,
                                                                                  borderWidth: borderWidth,
                                                                                  borderColor: lightBorderColor),
                              
                              UIUserInterfaceStyle.dark.rawValue: .renderRounded(cornerRadius: cornerRadius,
                                                                                 pointedCornerRadius: pointedCornerRadius,
                                                                                 corners: corners,
                                                                                 color: darkColor,
                                                                                 backgroundColor: darkBackgroundColor,
                                                                                 borderWidth: borderWidth,
                                                                                 borderColor: darkBorderColor)]
                    
                    return
                }
            }
            
            images = [:]
            
            defaultImage = .renderRounded(cornerRadius: cornerRadius,
                                          pointedCornerRadius: pointedCornerRadius,
                                          corners: corners,
                                          color: color,
                                          backgroundColor: backgroundColor,
                                          borderWidth: borderWidth,
                                          borderColor: borderColor)
        }
        
        func image(for traitCollection: UITraitCollection) -> UIImage? {
            guard #available(iOS 13, *), !images.isEmpty else {
                return defaultImage
            }
            
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return images[UIUserInterfaceStyle.dark.rawValue]
            default:
                return images[UIUserInterfaceStyle.light.rawValue]
            }
            
        }
    }
}
