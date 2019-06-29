//
//  UIImage+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: - Modes

extension UIImage {
    /// The image always draw the original image, without treating it as a template
    public var original: UIImage {
        return withRenderingMode(.alwaysOriginal)
    }
    
    /// The image always draw the image as a template image, ignoring its color information
    public var template: UIImage {
        return withRenderingMode(.alwaysTemplate)
    }
}

// MARK: - Create an Image with a color

extension UIImage {
    private static var colorsCGImages: [UIColor: CGImage] = [:]
    
    /// Create an Image 1x1 with a given color.
    ///
    /// - Parameter color: a `UIColor`. If the color has alpha 1, the image would be opaque.
    public convenience init(color: UIColor) {
        if let cgImage = UIImage.colorsCGImages[color] {
            self.init(cgImage: cgImage)
            return
        }
        
        // Get an alpha value from the color.
        var alpha: CGFloat = 0
        color.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        
        let rect = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContextWithOptions(rect.size, alpha == 1, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let cgImage = image?.cgImage {
            UIImage.colorsCGImages[color] = cgImage
            self.init(cgImage: cgImage)
        } else {
            self.init()
        }
    }
}

// MARK: - Edit

extension UIImage {
    func flip(orientation: Orientation) -> UIImage? {
        if let cgImage = cgImage {
            return UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        }
        
        return nil
    }
}

// MARK: - Check

extension UIImage {
    var hasAlpha: Bool {
        guard let alpha = cgImage?.alphaInfo else {
            return false
        }
        
        return alpha == .first || alpha == .last || alpha == .premultipliedFirst || alpha == .premultipliedLast
    }
}
