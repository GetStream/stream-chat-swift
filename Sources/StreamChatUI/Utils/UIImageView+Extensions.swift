//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import UIKit

extension UIImageView {
    func loadImage(from url: URL?, placeholder: UIImage? = nil) {
        guard let url = url else { image = nil; return }
        let options = ImageLoadingOptions(placeholder: placeholder)
        Nuke.loadImage(with: url, options: options, into: self)
    }
}
