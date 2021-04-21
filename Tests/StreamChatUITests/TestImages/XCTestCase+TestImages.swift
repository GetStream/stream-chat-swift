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

        static let r2: (url: URL, image: UIImage) = {
            getImage(withName: "r2")
        }()

        static let chewbacca: (url: URL, image: UIImage) = {
            getImage(withName: "chewbacca")
        }()
        
        private static func getImage(withName name: String, fileExtension: String = "jpg") -> (url: URL, image: UIImage) {
            let bundle = Bundle(for: ThisBundle.self)
            let imageURL = bundle.url(forResource: name, withExtension: fileExtension)!
            let image = UIImage(contentsOfFile: imageURL.path)!
            return (imageURL, image)
        }
    }
    
    class ThisBundle {}
}
