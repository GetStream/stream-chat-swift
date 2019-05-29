//
//  AttachmentCollectionViewCell.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 10/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxGesture

final class AttachmentCollectionViewCell: UICollectionViewCell, Reusable {
    typealias TapAction = (_ gestureRecognizer: UIGestureRecognizer) -> Void
    
    private  var disposeBag = DisposeBag()
    public let imageView = UIImageView(frame: .zero)
    
    public let removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.Icons.close, for: .normal)
        button.layer.cornerRadius = UIImage.Icons.close.size.width / 2
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        reset()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
        reset()
    }
    
    override func prepareForReuse() {
        reset()
        super.prepareForReuse()
    }
    
    private func setup() {
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = removeButton.layer.cornerRadius
        imageView.makeEdgesEqualToSuperview(superview: contentView)
        imageView.clipsToBounds = true
        contentView.addSubview(removeButton)
        
        removeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(-2)
        }
    }
    
    func reset() {
        removeButton.isHidden = false
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        imageView.isUserInteractionEnabled = false
        disposeBag = DisposeBag()
    }
    
    func updateRemoveButton(tintColor: UIColor?, action: @escaping () -> Void) {
        if let tintColor = tintColor {
            removeButton.tintColor = tintColor
            removeButton.backgroundColor = tintColor.oppositeBlackAndWhite.withAlphaComponent(0.5)
        }
        
        removeButton.rx.tap.subscribe(onNext: action).disposed(by: disposeBag)
    }
    
    func updatePlusButton(tintColor: UIColor?, action: @escaping TapAction) {
        removeButton.isHidden = true
        imageView.image = UIImage.Icons.plus
        imageView.contentMode = .center
        imageView.tintColor = tintColor
        imageView.backgroundColor = tintColor?.withAlphaComponent(0.1)
        imageView.isUserInteractionEnabled = true
        
        imageView.rx.tapGesture().when(.recognized)
            .subscribe(onNext: action)
            .disposed(by: disposeBag)
    }
}
