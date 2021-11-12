//
//  SendMoneyButton.swift
//  StreamChat
//
//  Created by Ajay Ghodadra on 12/11/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class SendMoneyButton: _Button, AppearanceProvider {

    override open func setUpAppearance() {
        super.setUpAppearance()
        let moneyTransaction = appearance.images.moneyTransaction
            .tinted(with: appearance.colorPalette.inactiveTint)
        setImage(moneyTransaction, for: .normal)

        let buttonColor: UIColor = appearance.colorPalette.alternativeInactiveTint
        let disabledStateImage = appearance.images.moneyTransaction.tinted(with: buttonColor)
        setImage(disabledStateImage, for: .disabled)
    }
}
