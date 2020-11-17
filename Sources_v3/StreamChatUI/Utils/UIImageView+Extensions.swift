//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Nuke
import UIKit

extension UIImageView {
    func setImage(from url: URL, placeholder: UIImage? = nil) {
        let options = ImageLoadingOptions(placeholder: placeholder)
        Nuke.loadImage(with: url, options: options, into: self)
    }
}
