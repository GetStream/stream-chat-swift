//
//  ReactionsView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 06/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import SnapKit
import RxSwift
import RxCocoa
import RxGesture

final class ReactionsView: UIView {
    typealias Completion = (_ selectedEmoji: String) -> Bool?
    
    private let disposeBag = DisposeBag()
    
    private lazy var avatarsStackView = createAvatarsStackView()
    private lazy var emojiesStackView = cerateEmojiesStackView()
    private lazy var labelsStackView = createLabelsStackView()
    private var reactionCounts: [String: Int]?
    
    private(set) lazy var reactionsView: UIView = {
        let view = UIView(frame: .zero)
        view.layer.cornerRadius = .reactionsPickerCornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: .reactionsPickerShadowOffsetY)
        view.layer.shadowRadius = .reactionsPickerShadowRadius
        view.layer.shadowOpacity = Float(CGFloat.reactionsPickerShdowOpacity)
        return view
    }()
    
    func show(atY y: CGFloat, for message: Message, completion: @escaping Completion) {
        addSubview(reactionsView)
        let x = (UIScreen.main.bounds.width - .messageTextMaxWidth) / 2
        let y = max(safeAreaTopOffset + .reactionsPickerAvatarRadius + .messageEdgePadding, y - .reactionsPickerCornerRadius)
        reactionsView.frame = CGRect(x: x, y: y, width: .messageTextMaxWidth, height: .reactionsPickerCornerHeight)
        reactionsView.transform = .init(scaleX: 0.5, y: 0.5)
        reactionCounts = message.reactionCounts?.counts
        alpha = 0
        
        Reaction.emojiTypes.enumerated().forEach { index, type in
            let users = message.latestReactions.filter({ $0.type == type }).compactMap({ $0.user })
            avatarsStackView.addArrangedSubview(createAvatarView(users))
            emojiesStackView.addArrangedSubview(createEmojiView(emoji: Reaction.emoji[index], emojiType: type, completion: completion))
            labelsStackView.addArrangedSubview(createLabel(message.reactionCounts?.counts[type] ?? 0))
        }
        
        UIView.animateSmoothly(withDuration: 0.3, usingSpringWithDamping: 0.65) {
            self.alpha = 1
            self.reactionsView.transform = .identity
        }
        
        let view  = UIView(frame: .zero)
        insertSubview(view, at: 0)
        view.makeEdgesEqualToSuperview()
        
        view.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in self?.dismiss() })
            .disposed(by: disposeBag)
    }
    
    func update(with message: Message) {
        avatarsStackView.removeAllArrangedSubviews()
        labelsStackView.removeAllArrangedSubviews()
        
        Reaction.emojiTypes.enumerated().forEach { index, key in
            let users = message.latestReactions.filter({ $0.type == key }).compactMap({ $0.user })
            avatarsStackView.addArrangedSubview(createAvatarView(users))
            labelsStackView.addArrangedSubview(createLabel(message.reactionCounts?.counts[key] ?? 0))
        }
    }
    
    private func updateLabel(emojiType: String, increment: Int) {
        if let index = Reaction.emojiTypes.firstIndex(of: emojiType),
            let label = labelsStackView.subviews[index].subviews.first as? UILabel {
            let count = (reactionCounts?[emojiType] ?? 0) + increment
            label.text = count > 0 ? count.shortString() : nil
            
            if increment > 0 {
                if let avatarView = avatarsStackView.subviews[index].subviews.first as? AvatarView {
                    avatarView.update(with: User.current?.avatarURL,
                                      name: User.current?.name,
                                      baseColor: backgroundColor?.withAlphaComponent(1))
                }
            } else {
                avatarsStackView.subviews[index].subviews.first?.removeFromSuperview()
            }
        }
    }
    
    func dismiss() {
        UIView.animateSmoothly(withDuration: 0.25, animations: {
            self.alpha = 0
            self.reactionsView.transform = .init(scaleX: 0.2, y: 0.2)
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
    
    private func createEmojiView(emoji: String, emojiType: String, completion: @escaping Completion) -> UIView {
        let label = UILabel()
        label.text = emoji
        label.textAlignment = .center
        label.font = .reactionsEmoji
        label.snp.makeConstraints { $0.width.height.equalTo(CGFloat.reactionsPickerButtonWidth).priority(999) }
        
        label.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self, weak label] _ in
                self?.isUserInteractionEnabled = false
                
                if let add = completion(emojiType) {
                    self?.updateLabel(emojiType: emojiType, increment: add ? 1 : -1)
                }
                
                label?.transform = .init(scaleX: 0.3, y: 0.3)
                
                UIView.animateSmoothly(withDuration: 0.3,
                                     usingSpringWithDamping: 0.4,
                                     initialSpringVelocity: 10,
                                     animations: { label?.transform = .identity },
                                     completion: { [weak self] _ in self?.dismiss() })
            })
            .disposed(by: disposeBag)
        
        return label
    }
    
    // MARK: - Avatars
    
    private func createAvatarsStackView() -> UIStackView {
        let stackView = createStackView()
        stackView.isUserInteractionEnabled = false
        stackView.snp.makeConstraints { $0.centerY.equalTo(reactionsView.snp.top) }
        return stackView
    }
    
    private func createAvatarView(_ users: [User]?) -> UIView {
        let viewContainer = UIView(frame: .zero)
        viewContainer.snp.makeConstraints { $0.width.height.equalTo(CGFloat.reactionsPickerButtonWidth).priority(999) }
        
        let avatarView = AvatarView(cornerRadius: .reactionsPickerAvatarRadius)
        avatarView.makeCenterEqualToSuperview(superview: viewContainer)
        
        if let user = users?.first {
            let baseColor = backgroundColor?.withAlphaComponent(1)
            avatarView.update(with: user.avatarURL, name: user.name, baseColor: baseColor)
        } else {
            avatarView.isHidden = true
        }
        
        return viewContainer
    }
    
    // MARK: - Labels
    
    private func createLabelsStackView() -> UIStackView {
        let stackView = createStackView()
        stackView.isUserInteractionEnabled = false
        stackView.snp.makeConstraints { $0.top.equalTo(reactionsView.snp.centerY).offset(2) }
        return stackView
    }
    
    private func createLabel(_ count: Int) -> UIView {
        let viewContainer = UIView(frame: .zero)
        viewContainer.snp.makeConstraints { $0.width.height.equalTo(CGFloat.reactionsPickerButtonWidth).priority(999) }
        
        let label = UILabel(frame: .zero)
        label.text = count > 0 ? count.shortString() : nil
        label.font = .chatSmall
        label.textColor = reactionsView.backgroundColor?.oppositeBlackAndWhite
        label.makeCenterEqualToSuperview(superview: viewContainer)
        
        return viewContainer
    }
}
