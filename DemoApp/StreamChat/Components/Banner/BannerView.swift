//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

final class BannerView: UIView {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(text: String) {
        label.text = text
    }
    
    private func commonInit() {
        setUpLayout()
        defaultAppearance()
    }
    
    private func setUpLayout() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                label.trailingAnchor.constraint(equalTo: trailingAnchor),
                label.leadingAnchor.constraint(equalTo: leadingAnchor),
                label.topAnchor.constraint(equalTo: topAnchor),
                label.bottomAnchor.constraint(equalTo: bottomAnchor)
            ]
        )
    }
    
    private func defaultAppearance() {
        backgroundColor = Appearance.default.colorPalette.border2.withAlphaComponent(0.9)
        label.textAlignment = .center
        label.font = Appearance.default.fonts.body
        label.textColor = Appearance.default.colorPalette.popoverBackground
    }
}
