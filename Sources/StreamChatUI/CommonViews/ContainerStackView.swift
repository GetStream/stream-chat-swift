//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

internal class ContainerStackView: UIStackView {
    // MARK: - Subviews
    
    internal let topStackView = UIStackView()
    internal let bottomStackView = UIStackView()
    internal let leftStackView = UIStackView()
    internal let rightStackView = UIStackView()
    internal let centerStackView = UIStackView()
    
    internal let centerContainerStackView = UIStackView()
        
    // MARK: - Init

    override internal init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    internal required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        distribution = .fill
        axis = .vertical
        alignment = .fill
        translatesAutoresizingMaskIntoConstraints = false
        
        centerContainerStackView.distribution = .fill
        centerContainerStackView.axis = .horizontal
        centerContainerStackView.alignment = .fill
        centerContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        centerContainerStackView.addArrangedSubview(leftStackView)
        centerContainerStackView.addArrangedSubview(centerStackView)
        centerContainerStackView.addArrangedSubview(rightStackView)
        
        addArrangedSubview(topStackView)
        addArrangedSubview(centerContainerStackView)
        addArrangedSubview(bottomStackView)
        
        [topStackView, bottomStackView, leftStackView, rightStackView, centerStackView].forEach {
            $0.isHidden = true
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
}
