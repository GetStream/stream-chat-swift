//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIImage {
    convenience init?(named name: String, in bundle: Bundle) {
        self.init(named: name, in: bundle, compatibleWith: nil)
    }
}

extension UIImage {
    static let circleImage: UIImage = {
        let size: CGSize = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        let circleImage = renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.red.cgColor)

            let rectangle = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            ctx.cgContext.addEllipse(in: rectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
        }
        return circleImage
    }()
}

extension UIImage {
    func tinted(with fillColor: UIColor) -> UIImage? {
        let image = withRenderingMode(.alwaysTemplate)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        fillColor.set()
        image.draw(in: CGRect(origin: .zero, size: size))

        guard let imageColored = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        
        UIGraphicsEndImageContext()
        return imageColored
    }
}

extension UIImage {
    func temporaryLocalFileUrl() throws -> URL? {
        guard let imageData = jpegData(compressionQuality: 1.0) else { return nil }
        let imageName = "\(UUID().uuidString).jpg"
        let documentDirectory = NSTemporaryDirectory()
        let localPath = documentDirectory.appending(imageName)
        let photoURL = URL(fileURLWithPath: localPath)
        try imageData.write(to: photoURL)
        return photoURL
    }
}
