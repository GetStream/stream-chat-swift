//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import UIKit

extension UIImageView {
    func loadImage(from url: URL?, placeholder: UIImage? = nil) {
        guard !SystemEnvironment.isTests else {
            // When running tests, we load the images synchronously
            image = url.flatMap { UIImage(data: try! Data(contentsOf: $0)) }
            return
        }
        guard let url = url else { image = nil; return }
        let options = ImageLoadingOptions(placeholder: placeholder)
        Nuke.loadImage(with: url, options: options, into: self)
    }
}
