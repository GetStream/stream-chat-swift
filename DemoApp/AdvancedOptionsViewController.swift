//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

class MainButton: UIButton {
    override func tintColorDidChange() {
        backgroundColor = tintColor
        setTitleColor(.white, for: .normal)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        layer.cornerRadius = bounds.height / 2.0
    }
}

class AdvancedOptionsViewController: UIViewController {
    @IBOutlet var mainStackView: UIStackView! {
        didSet {
            mainStackView.preservesSuperviewLayoutMargins = true
            mainStackView.isLayoutMarginsRelativeArrangement = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Advanced Options"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
}
