//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import XCTest

extension XCTestCase {
    /// A set of test images and their URL that can be used for testing. These images are also preloaded in Nuke cache.
    enum TestImages {
        static let vader: (url: URL, image: UIImage) = {
            getImage(withName: "vader")
        }()
        
        static let yoda: (url: URL, image: UIImage) = {
            getImage(withName: "yoda")
        }()
        
        private static func getImage(withName name: String, fileExtension: String = "jpg") -> (url: URL, image: UIImage) {
            let bundle = Bundle(for: ThisBundle.self)
            let imageURL = bundle.url(forResource: name, withExtension: fileExtension)!
            let image = UIImage(contentsOfFile: imageURL.path)!

            // Preload image with Nuke, this makes sure the image is set synchronously
            let request = ImageRequest(url: imageURL)
            ImageCache.shared[request] = ImageContainer(image: image)

            return (imageURL, image)
        }
    }
    
    class ThisBundle {}
}
