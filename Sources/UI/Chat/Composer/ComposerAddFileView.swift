//
//  ComposerAddFileView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 29/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxGesture

/// A composer add file view.
public final class ComposerAddFileView: UIView {
    /// An action to add a file.
    public typealias Action = (_ sourceType: SourceType) -> Void
    
    private let iconImageView: UIImageView?
    private let titleLabel: UILabel
    private let disposeBag = DisposeBag()
    private let action: Action
    
    /// A source type.
    public let sourceType: SourceType
    
    override public var backgroundColor: UIColor? {
        didSet {
            titleLabel.textColor = backgroundColor?.oppositeBlackAndWhite ?? .black
            iconImageView?.tintColor = titleLabel.textColor
            iconImageView?.backgroundColor = titleLabel.textColor.withAlphaComponent(0.1)
        }
    }
    
    /// Init a composer add file view.
    ///
    /// - Parameters:
    ///   - icon: an image icon.
    ///   - title: a title.
    ///   - sourceType: a source type of the file.
    ///   - action: an action when tap to the view.
    public init(icon: UIImage?, title: String, sourceType: SourceType, action: @escaping Action) {
        titleLabel = UILabel(frame: .zero)
        titleLabel.font = .chatMedium
        titleLabel.text = title
        self.sourceType = sourceType
        self.action = action
        
        if let icon = icon {
            iconImageView = UIImageView(image: icon)
        } else {
            iconImageView = nil
        }
        
        super.init(frame: .zero)
        
        // Set the general height.
        snp.makeConstraints { $0.height.equalTo(CGFloat.composerHelperIconSize + 2 * .messageSpacing).priority(999) }
        
        if let iconImageView = iconImageView {
            iconImageView.contentMode = .center
            iconImageView.layer.cornerRadius = .composerHelperIconCornerRadius
            
            addSubview(iconImageView)
            
            iconImageView.snp.makeConstraints { make in
                make.width.height.equalTo(CGFloat.composerHelperIconSize)
                make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
                make.centerY.equalToSuperview()
            }
        }
        
        addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            make.centerY.equalToSuperview()

            if let iconImageView = iconImageView {
                make.left.equalTo(iconImageView.snp.right).offset(CGFloat.composerHelperButtonEdgePadding)
            } else {
                make.left.equalToSuperview().offset(CGFloat.composerHelperTitleEdgePadding)
            }
        }
        
        rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in action(sourceType) })
            .disposed(by: disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        iconImageView = nil
        titleLabel = UILabel(frame: .zero)
        sourceType = .file
        action = { _ in }
        super.init(coder: aDecoder)
    }
    
    /// Call an action on tap.
    public func tap() {
        action(sourceType)
    }
}

public extension ComposerAddFileView {
    /// A composer add file source type.
    ///
    /// - photo: a photo.
    /// - file: a file.
    /// - custom: a custom type with some id.
    enum SourceType {
        /// A photo.
        case photo(_ sourceType: UIImagePickerController.SourceType)
        /// A file.
        case file
        /// A custom type with some id.
        case custom(ComposerAddFileCustomSourceIdType)
    }
}

/// A protocol for a custom source id type for adding files to a composer view.
public protocol ComposerAddFileCustomSourceIdType {}

extension String: ComposerAddFileCustomSourceIdType {}
extension Int: ComposerAddFileCustomSourceIdType {}
