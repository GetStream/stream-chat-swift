//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

class ComposerView: UIView {
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var textView: UITextView! {
        didSet {
            if #available(iOS 13.0, *) {
                textView.layer.borderColor = UIColor.opaqueSeparator.cgColor
            }

            textView.textContainerInset.right = 48
            textView.textContainerInset.left = 10
            textView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        }
    }

    var calculatedHeight: CGFloat {
        textView.contentSize.height + safeAreaInsets.bottom + 20
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: super.intrinsicContentSize.width, height: calculatedHeight)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
        
        addObserver(self, forKeyPath: "safeAreaInsets", options: .new, context: nil)
    }
    
    // swiftlint:disable block_based_kvo
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if object as AnyObject? === textView, keyPath == "contentSize" {
            invalidateIntrinsicContentSize()
        } else if object as AnyObject? === self, keyPath == "safeAreaInsets" {
            invalidateIntrinsicContentSize()
        }
    }
    
    // swiftlint:enable block_based_kvo
}
