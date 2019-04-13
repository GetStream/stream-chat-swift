//
//  StatusTableViewCell.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 12/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

final class StatusTableViewCell: UITableViewCell, Reusable {
    
    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatBoldXSmall
        label.textColor = .chatGray
        return label
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatXSmall
        label.textColor = .chatGray
        titleLabel.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
        }
        
        return label
    }()
    
    override func prepareForReuse() {
        reset()
        super.prepareForReuse()
    }
    
    public func reset() {
        titleLabel.text = nil
        dateLabel.text = nil
    }
    
    func setup() {
        let line1 = createLineView()
        let line2 = createLineView()
        
        let stackView = UIStackView(arrangedSubviews: [line1, titleLabel, line2])
        stackView.axis = .horizontal
        stackView.spacing = .messageStatusSpacing
        stackView.alignment = .center
        
        addSubview(stackView)
        line1.snp.makeConstraints { $0.width.equalTo(line2) }

        stackView.snp.makeConstraints { make in
            let edgePadding: CGFloat = .messageEdgePadding + .messageCornerRadius
            make.left.equalToSuperview().offset(edgePadding)
            make.top.equalToSuperview().offset(CGFloat.messageEdgePadding)
            make.right.equalToSuperview().offset(-edgePadding)
            make.bottom.equalToSuperview().offset(-2 * CGFloat.messageEdgePadding)
        }
    }
    
    private func createLineView() -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = (backgroundColor?.isDark ?? false) ? .chatDarkGray : .chatSuperLightGray
        view.snp.makeConstraints { $0.height.equalTo(CGFloat.messageStatusLineWidth).priority(999) }
        return view
    }
    
    public func update(status: String, date: Date? = nil) {
        if titleLabel.superview == nil {
            setup()
        }
        
        titleLabel.text = status.uppercased()
        
        if let date = date {
            dateLabel.text = date.relative.uppercased()
        }
    }
}
