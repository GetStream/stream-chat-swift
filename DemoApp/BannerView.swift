//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

final class BannerView: UIView {
    private let label = UILabel()
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setUpLayout()
        defaultAppearance()
    }
    
    func update(text: String) {
        label.text = text
    }
    
    private func setUpLayout() {
        guard let superview = superview else { return }
        
        addSubview(label)
        
        translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate(
            [
                widthAnchor.constraint(equalTo: superview.widthAnchor),
                heightAnchor.constraint(equalToConstant: 28),
                label.trailingAnchor.constraint(equalTo: trailingAnchor),
                label.leadingAnchor.constraint(equalTo: leadingAnchor),
                label.topAnchor.constraint(equalTo: topAnchor),
                label.bottomAnchor.constraint(equalTo: bottomAnchor)
            ]
        )
    }
    
    private func defaultAppearance() {
        backgroundColor = UIConfig.default.colorPalette.border2.withAlphaComponent(0.9)
        label.textAlignment = .center
        label.font = UIConfig.default.font.body
        label.textColor = UIConfig.default.colorPalette.popoverBackground
    }
}
