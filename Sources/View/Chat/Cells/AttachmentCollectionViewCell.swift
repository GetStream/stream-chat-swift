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

final class AttachmentCollectionViewCell: UICollectionViewCell, Reusable {
    
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
        imageView.image = nil
        disposeBag = DisposeBag()
    }
    
    func updateRemoveButton(tintColor: UIColor?, action: @escaping () -> Void) {
        if let tintColor = tintColor {
            removeButton.tintColor = tintColor
            removeButton.backgroundColor = tintColor.oppositeBlackAndWhite.withAlphaComponent(0.5)
        }
        
        removeButton.rx.tap.subscribe(onNext: action).disposed(by: disposeBag)
    }
}
