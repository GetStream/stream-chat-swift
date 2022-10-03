//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class SlackReactionsItemView: UIButton {
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel?.font = UIFont.boldSystemFont(ofSize: 11)
        titleLabel?.textAlignment = .center
        titleLabel?.numberOfLines = 1
        setTitleColor(.gray, for: .normal)

        layer.cornerRadius = 4
        layer.borderWidth = 1
        layer.borderColor = UIColor.blue.cgColor
        backgroundColor = UIColor.gray.withAlphaComponent(0.2)

        titleEdgeInsets = .init(top: 4, left: 4, bottom: 4, right: 7)
        imageEdgeInsets = .init(top: 5, left: 0, bottom: 5, right: 7)
        imageView?.contentMode = .scaleAspectFit

        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError()
    }

    @objc func didTap() {
        onTap?()
    }

    override var intrinsicContentSize: CGSize {
        let labelSize = titleLabel?.sizeThatFits(CGSize(
            width: frame.width,
            height: .greatestFiniteMagnitude
        )
        ) ?? .zero
        let desiredButtonSize = CGSize(width: labelSize.width + 33, height: 26.0)
        return desiredButtonSize
    }
}
