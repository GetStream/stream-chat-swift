//
//  UIView+InstantiateFromNib.swift
//  StreamChatClient
//
//  Created by Matheus Cardoso on 24/08/20.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIView {
    static func instantiateFromNib() -> Self? {
        func instanceFromNib<T: UIView>() -> T? {
            return UINib(nibName: "\(self)", bundle: nil).instantiate(withOwner: nil, options: nil).first as? T
        }

        return instanceFromNib()
    }
}
