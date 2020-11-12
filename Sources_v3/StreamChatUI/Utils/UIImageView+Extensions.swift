//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIImageView {
    private enum AssociatedKeys {
        static var loadImageTask: UInt8 = 0
    }
    
    private var loadImageTask: URLSessionTask? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.loadImageTask) as? URLSessionTask }
        set {
            loadImageTask?.cancel()
            objc_setAssociatedObject(self, &AssociatedKeys.loadImageTask, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            loadImageTask?.resume()
        }
    }
    
    func setImage(from url: URL, session: URLSession = .shared, placeholder: UIImage? = nil) {
        image = placeholder
        loadImageTask = session.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                self?.image = data.flatMap(UIImage.init)
                self?.loadImageTask = nil
            }
        }
    }
}
