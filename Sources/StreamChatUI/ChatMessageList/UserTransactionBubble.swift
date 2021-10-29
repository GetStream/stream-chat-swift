//
//  UserTransactionBubble.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 29/10/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

class UserTransactionBubble: UITableViewCell {

    var lblPaymentStatic: UILabel!
    var viewContainer: UIView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = Appearance().colorPalette.background6
        self.addSubview(viewContainer)
        viewContainer.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        viewContainer.topAnchor.constraint(equalTo: self.topAnchor, constant: 15).isActive = true
        viewContainer.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        viewContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true
        lblPaymentStatic = UILabel()
        lblPaymentStatic.text = "This is custom payment cell"
        lblPaymentStatic.textAlignment = .right
        lblPaymentStatic.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.addSubview(lblPaymentStatic)
        lblPaymentStatic.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 10).isActive = true
        lblPaymentStatic.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: -10).isActive = true
        lblPaymentStatic.topAnchor.constraint(equalTo: viewContainer.topAnchor, constant: 10).isActive = true
        lblPaymentStatic.bottomAnchor.constraint(equalTo: viewContainer.bottomAnchor, constant: -10).isActive = true
        viewContainer.transform = .mirrorY
        viewContainer.layer.cornerRadius = 12
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}
