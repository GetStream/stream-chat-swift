//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

public extension XCTestCase {
    /// A set of test images and their URL that can be used for testing. These images are also preloaded in Nuke cache.
    enum TestImages {
        public static let vader: (url: URL, image: UIImage) = {
            getImage(withName: "vader")
        }()
        
        public static let yoda: (url: URL, image: UIImage) = {
            getImage(withName: "yoda")
        }()

        public static let r2: (url: URL, image: UIImage) = {
            getImage(withName: "r2")
        }()

        public static let chewbacca: (url: URL, image: UIImage) = {
            getImage(withName: "chewbacca")
        }()
        
        private static func getImage(withName name: String, fileExtension: String = "jpg") -> (url: URL, image: UIImage) {
            let imageURL = Bundle.testTools.url(forResource: "\(Bundle.testTools.pathToImagesFolder)\(name)", withExtension: fileExtension)!
            let image = UIImage(contentsOfFile: imageURL.path)!
            return (imageURL, image)
        }
    }
}

public extension URL {
    static let localYodaImage = Bundle.testTools
        .url(forResource: "\(Bundle.testTools.pathToImagesFolder)yoda", withExtension: "jpg")!

    static let localYodaQuote = Bundle.testTools
        .url(forResource: "\(Bundle.testTools.pathToOtherFolder)yoda", withExtension: "txt")!

    static let localYodaQuoteLongFileName = Bundle.testTools
        .url(forResource: "\(Bundle.testTools.pathToOtherFolder)yoda_with_long_file_name", withExtension: "txt")!
}
