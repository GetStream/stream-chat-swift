//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

class SwitchButton: UISwitch {
    var didChangeValue: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(didChangeValue(sender:)), for: .valueChanged)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didChangeValue(sender: UISwitch) {
        didChangeValue?(sender.isOn)
    }
}
