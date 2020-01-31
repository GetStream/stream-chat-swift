//
//  AttachmentCollectionViewCell.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 10/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxGesture
import SwiftyGif

/// An image attachment collection view cell.
public final class AttachmentCollectionViewCell: UICollectionViewCell, Reusable {
    /// An action for a plus button.
    public typealias TapAction = (_ gestureRecognizer: UIGestureRecognizer) -> Void
    
    private(set) var disposeBag = DisposeBag()
    let imageView = UIImageView(frame: .zero)
    
    let removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.Icons.close, for: .normal)
        button.layer.cornerRadius = UIImage.Icons.close.size.width / 2
        return button
    }()
    
    private(set) lazy var progressView = UIProgressView(progressViewStyle: .default)
    
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
    
    override public func prepareForReuse() {
        reset()
        super.prepareForReuse()
    }
    
    private func setup() {
        let cornerRadius = removeButton.layer.cornerRadius
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.makeEdgesEqualToSuperview(superview: contentView)
        contentView.addSubview(removeButton)
        
        removeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(-2)
        }
        
        contentView.addSubview(progressView)
        
        progressView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(cornerRadius)
            make.right.equalToSuperview().offset(-cornerRadius)
            make.bottom.equalToSuperview().offset(-cornerRadius)
        }
    }
    
    func reset() {
        backgroundColor = .clear
        removeButton.isHidden = false
        imageView.alpha = 1
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        imageView.isUserInteractionEnabled = false
        progressView.isHidden = true
        progressView.progress = 0
        disposeBag = DisposeBag()
        removeGifAnimation()
    }
    
    func startGifAnimation(with gifData: Data) {
        if let animatedImage = try? UIImage(gifData: gifData, levelOfIntegrity: 0.4) {
            imageView.setGifImage(animatedImage)
        }
    }
    
    func removeGifAnimation() {
        imageView.stopAnimating()
        imageView.gifImage = nil
    }
    
    func updateForProgress(_ progress: Float) {
        guard progress < 1 else {
            progressView.isHidden = true
            imageView.alpha = 1
            backgroundColor = .clear
            return
        }
        
        progressView.isHidden = false
        progressView.progress = progress
        imageView.alpha = 0.7
    }
    
    func updateForError() {
        progressView.isHidden = true
        backgroundColor = .red
        imageView.alpha = 0.7
    }
    
    func updateRemoveButton(tintColor: UIColor?, action: @escaping () -> Void) {
        if let tintColor = tintColor {
            removeButton.tintColor = tintColor
            removeButton.backgroundColor = tintColor.oppositeBlackAndWhite.withAlphaComponent(0.4)
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
        
        imageView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: action)
            .disposed(by: disposeBag)
    }
}
