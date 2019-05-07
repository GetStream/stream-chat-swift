//
//  ReactionsView.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 06/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxGesture

final class ReactionsView: UIView {
    
    private let disposeBag = DisposeBag()
    
    private lazy var avatarsStackView = createAvatarsStackView()
    private lazy var emojiesStackView = cerateEmojiesStackView()
    private lazy var labelsStackView = createLabelsStackView()

    
    private(set) lazy var reactionsView: UIView = {
        let view = UIView(frame: .zero)
        view.layer.cornerRadius = .reactionsPickerCornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: .reactionsPickerShadowOffsetY)
        view.layer.shadowRadius = .reactionsPickerShadowRadius
        view.layer.shadowOpacity = Float(CGFloat.reactionsPickerShdowOpacity)
        
        return view
    }()
    
    func show(at y: CGFloat, for message: Message, dismiss: @escaping () -> Void) {
        addSubview(reactionsView)
        reactionsView.frame = CGRect(x: (UIScreen.main.bounds.width - .messageTextMaxWidth) / 2,
                                     y: y + .reactionsHeight / 2 - .reactionsPickerCornerRadius,
                                     width: .messageTextMaxWidth,
                                     height: .reactionsPickerCornerHeight)
        
        reactionsView.transform = .init(scaleX: 0.2, y: 0.2)
        reactionsView.alpha = 0
        alpha = 0
        
        Reaction.emojiKeys.enumerated().forEach { index, key in
            let users = message.latestReactions.filter({ $0.type == key }).compactMap({ $0.user })
            avatarsStackView.addArrangedSubview(createAvatarView(users))
            emojiesStackView.addArrangedSubview(createEmojiView(emoji: Reaction.emoji[index]))
            labelsStackView.addArrangedSubview(createLabel(message.reactionCounts?.counts[key] ?? 0))
        }
        
        UIView.animateSmooth(withDuration: 0.3, usingSpringWithDamping: 0.7) {
            self.alpha = 1
            self.reactionsView.transform = .identity
            self.reactionsView.alpha = 1
        }
        
        rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.dismiss()
                dismiss()
            })
            .disposed(by: disposeBag)
    }
    
    func update(with message: Message) {
        avatarsStackView.removeAllArrangedSubviews()
        labelsStackView.removeAllArrangedSubviews()
        
        Reaction.emojiKeys.enumerated().forEach { index, key in
            let users = message.latestReactions.filter({ $0.type == key }).compactMap({ $0.user })
            avatarsStackView.addArrangedSubview(createAvatarView(users))
            labelsStackView.addArrangedSubview(createLabel(message.reactionCounts?.counts[key] ?? 0))
        }
    }
    
    func dismiss() {
        UIView.animateSmooth(withDuration: 0.25, animations: {
            self.alpha = 0
            self.reactionsView.transform = .init(scaleX: 0.1, y: 0.1)
            self.reactionsView.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    private func createStackView() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        reactionsView.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(CGFloat.reactionsPickerCornerRadius / 2)
            make.right.equalToSuperview().offset(CGFloat.reactionsPickerCornerRadius / -2)
        }
        
        return stackView
    }
    
    // MARK: - Emojies
    
    private func cerateEmojiesStackView() -> UIStackView {
        let stackView = createStackView()
        stackView.snp.makeConstraints { $0.centerY.equalToSuperview() }
        return stackView
    }
    
    private func createEmojiView(emoji: String) -> UIView {
        let button = UIButton(type: .custom)
        button.setTitle(emoji, for: .normal)
        button.titleLabel?.font = .reactionsEmoji
        button.snp.makeConstraints { $0.width.height.equalTo(CGFloat.reactionsPickerButtonWidth).priority(999) }
        return button
    }
    
    // MARK: - Avatars
    
    private func createAvatarsStackView() -> UIStackView {
        let stackView = createStackView()
        stackView.snp.makeConstraints { $0.centerY.equalTo(reactionsView.snp.top) }
        return stackView
    }
    
    private func createAvatarView(_ users: [User]?) -> UIView {
        let viewContainer = UIView(frame: .zero)
        viewContainer.snp.makeConstraints { $0.width.height.equalTo(CGFloat.reactionsPickerButtonWidth).priority(999) }
        
        guard let user = users?.first else {
            return viewContainer
        }
        
        let labelBackgroundColor = backgroundColor?.withAlphaComponent(1)
        let avatarView = AvatarView(cornerRadius: .reactionsPickerAvatarRadius)
        avatarView.update(with: user.avatarURL, name: user.name, baseColor: labelBackgroundColor)
        viewContainer.addSubview(avatarView)
        avatarView.snp.makeConstraints { $0.center.equalToSuperview() }
        
        return viewContainer
    }
    
    // MARK: - Labels
    
    private func createLabelsStackView() -> UIStackView {
        let stackView = createStackView()
        stackView.snp.makeConstraints { $0.top.equalTo(reactionsView.snp.centerY).offset(2) }
        return stackView
    }
    
    private func createLabel(_ count: Int) -> UIView {
        let viewContainer = UIView(frame: .zero)
        viewContainer.snp.makeConstraints { $0.width.height.equalTo(CGFloat.reactionsPickerButtonWidth).priority(999) }
        
        guard count > 0 else {
            return viewContainer
        }
        
        let label = UILabel(frame: .zero)
        label.text = count.shortString()
        label.font = .chatSmall
        label.textColor = reactionsView.backgroundColor?.oppositeBlackAndWhite
        viewContainer.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        
        return viewContainer
    }
}
