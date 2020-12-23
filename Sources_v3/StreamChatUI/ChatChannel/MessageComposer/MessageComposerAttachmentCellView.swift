//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

open class MessageComposerAttachmentsCellView: UIView {
    var deleteClosure: (() -> Void)?
    
    public private(set) lazy var imageView: UIImageView = .init()

    public private(set) lazy var closeButton: UIButton = {
        let button = UIButton()
        button.pin(anchors: [.width, .height], to: 15)
        button.layer.cornerRadius = 7.5
        button.backgroundColor = .init(red: 0, green: 0, blue: 0, alpha: 0.4)
        button.setTitle("𝗑", for: .normal)
        button.addTarget(self, action: #selector(deleteAttachmentTapped), for: .touchUpInside)
        return button
    }()

    public required init(image: UIImage, deleteClosure: @escaping () -> Void) {
        super.init(frame: .zero)
        commonInit(with: image)
        self.deleteClosure = deleteClosure
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit(with: UIImage())
    }

    func commonInit(with image: UIImage) {
        pin(anchors: [.width, .height], to: 50)
        layer.masksToBounds = true
        layer.cornerRadius = 5

        addSubview(imageView)
        addSubview(closeButton)
        imageView.pin(to: self)
        closeButton.pin(anchors: [.top, .right], to: self)
        imageView.image = image
    }

    @objc func deleteAttachmentTapped() {
        deleteClosure?()
    }
}
