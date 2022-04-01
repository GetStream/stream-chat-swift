//
//  BottomSafeAreaView.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 23/03/22.
//

import UIKit

open class BottomSafeAreaView: _View {
    
    override open func setUpLayout() {
        super.setUpLayout()
        heightAnchor.pin(equalToConstant: UIView.safeAreaBottom).isActive = true
    }
}
