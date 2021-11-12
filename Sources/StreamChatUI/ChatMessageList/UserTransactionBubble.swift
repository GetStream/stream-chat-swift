//
//  UserTransactionBubble.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 29/10/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

class UserTransactionBubble: UITableViewCell {

    var viewContainer: UIView!
    var giftContainerView: UIView!
    var giftImageView: UIImageView!
    var giftLabel: UILabel!
    var descriptionView: UIView!
    var descriptionLabel: UILabel!
    var tapHereButton: UIButton!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = .white
        viewContainer.layer.cornerRadius = 12
        viewContainer.clipsToBounds = true
        addSubview(viewContainer)
        viewContainer.topAnchor.constraint(equalTo: self.topAnchor, constant: 4).isActive = true
        viewContainer.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4).isActive = true
        viewContainer.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: cellWidth).isActive = true
        viewContainer.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8).isActive = true

        giftContainerView = UIView()
        giftContainerView.translatesAutoresizingMaskIntoConstraints = false
        giftContainerView.layer.cornerRadius = 12
        giftContainerView.clipsToBounds = true
        addSubview(giftContainerView)
        giftContainerView.bottomAnchor.constraint(equalTo: viewContainer.bottomAnchor, constant: -8).isActive = true
        giftContainerView.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 8).isActive = true
        giftContainerView.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: -8).isActive = true
        giftContainerView.heightAnchor.constraint(equalToConstant: 350).isActive = true

        giftImageView = UIImageView()
        giftImageView.image = Appearance.default.images.starbucks
        giftImageView.contentMode = .scaleAspectFill
        giftImageView.translatesAutoresizingMaskIntoConstraints = false
        giftImageView.clipsToBounds = true
        giftContainerView.addSubview(giftImageView)
        giftImageView.bottomAnchor.constraint(equalTo: giftContainerView.bottomAnchor, constant: 0).isActive = true
        giftImageView.leadingAnchor.constraint(equalTo: giftContainerView.leadingAnchor, constant: 0).isActive = true
        giftImageView.trailingAnchor.constraint(equalTo: giftContainerView.trailingAnchor, constant: 0).isActive = true
        giftImageView.heightAnchor.constraint(equalToConstant: 300).isActive = true
        giftImageView.transform = .mirrorY

        giftLabel = UILabel()
        giftLabel.text = "   STARBUCKS"
        giftLabel.textColor = .black
        giftLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        giftLabel.backgroundColor = UIColor(red: 243/255, green: 243/255, blue: 243/255, alpha: 1.0)
        giftLabel.translatesAutoresizingMaskIntoConstraints = false
        giftLabel.clipsToBounds = true
        giftContainerView.addSubview(giftLabel)
        giftLabel.leadingAnchor.constraint(equalTo: giftContainerView.leadingAnchor, constant: 0).isActive = true
        giftLabel.trailingAnchor.constraint(equalTo: giftContainerView.trailingAnchor, constant: 0).isActive = true
        giftLabel.bottomAnchor.constraint(equalTo: giftImageView.topAnchor, constant: 0).isActive = true
        giftLabel.topAnchor.constraint(equalTo: giftContainerView.topAnchor, constant: 0).isActive = true
        giftLabel.transform = .mirrorY

        descriptionView = UIView()
        descriptionView.translatesAutoresizingMaskIntoConstraints = false
        descriptionView.layer.cornerRadius = 12
        descriptionView.backgroundColor = .white
        descriptionView.clipsToBounds = true
        viewContainer.addSubview(descriptionView)
        descriptionView.bottomAnchor.constraint(equalTo: giftContainerView.topAnchor, constant: 18).isActive = true
        descriptionView.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 8).isActive = true
        descriptionView.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: -8).isActive = true
        descriptionView.topAnchor.constraint(equalTo: viewContainer.topAnchor, constant: 18).isActive = true

        descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = .black
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry."
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionView.addSubview(descriptionLabel)
        descriptionLabel.leadingAnchor.constraint(equalTo: descriptionView.leadingAnchor, constant: 8).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: descriptionView.trailingAnchor, constant: -8).isActive = true
        descriptionLabel.bottomAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: -22).isActive = true
        descriptionLabel.transform = .mirrorY

        tapHereButton = UIButton()
        tapHereButton.translatesAutoresizingMaskIntoConstraints = false
        tapHereButton.setTitle("Tap Here", for: .normal)
        tapHereButton.setTitleColor(.black, for: .normal)
        tapHereButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        tapHereButton.backgroundColor = UIColor(red: 243/255, green: 243/255, blue: 243/255, alpha: 1.0)
        tapHereButton.layer.cornerRadius = 4
        tapHereButton.clipsToBounds = true
        descriptionView.addSubview(tapHereButton)
        tapHereButton.leadingAnchor.constraint(equalTo: descriptionView.leadingAnchor, constant: 8).isActive = true
        tapHereButton.trailingAnchor.constraint(equalTo: descriptionView.trailingAnchor, constant: -8).isActive = true
        tapHereButton.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -8).isActive = true
        tapHereButton.topAnchor.constraint(equalTo: descriptionView.topAnchor, constant: 8).isActive = true
        tapHereButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        tapHereButton.transform = .mirrorY
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private var cellWidth: CGFloat {
        return UIScreen.main.bounds.width * 0.3
    }

}
