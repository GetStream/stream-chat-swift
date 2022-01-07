//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

final class JumpView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = Colors.background
        
        layer.masksToBounds = true
        layer.cornerRadius = 10
        layer.borderColor = Colors.border.cgColor
        layer.borderWidth = 1
        
        let label = UILabel()
        label.textColor = Colors.text
        label.text = "Jump to..."
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
