//
//  StatusTableViewCell.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 12/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

final class StatusTableViewCell: UITableViewCell, Reusable {
    
    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatXSmallBold
        label.textColor = .chatGray
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
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
    
    private lazy var lineView1 = createLineView()
    private lazy var lineView2 = createLineView()
    
    var title: String? {
        return titleLabel.text
    }
    
    override func prepareForReuse() {
        reset()
        super.prepareForReuse()
    }
    
    func reset() {
        titleLabel.text = nil
        subtitleLabel.text = nil
    }
    
    func setup() {
        let stackView = UIStackView(arrangedSubviews: [lineView1, titleLabel, lineView2])
        stackView.axis = .horizontal
        stackView.spacing = .messageStatusSpacing
        stackView.alignment = .center
        
        contentView.addSubview(stackView)
        lineView1.snp.makeConstraints { $0.width.equalTo(lineView2) }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().priority(999)
            make.height.equalTo(60).priority(999)
        }
    }
    
    private func createLineView() -> UIView {
        let view = UIView(frame: .zero)
        view.snp.makeConstraints { $0.height.equalTo(CGFloat.messageStatusLineWidth).priority(999) }
        return view
    }
    
    func update(title: String, subtitle: String? = nil, textColor: UIColor) {
        if titleLabel.superview == nil {
            setup()
        }
        
        titleLabel.text = title.uppercased()
        titleLabel.textColor = textColor
        lineView1.backgroundColor = textColor.withAlphaComponent(0.5)
        lineView2.backgroundColor = lineView1.backgroundColor
        
        if let subtitle = subtitle {
            subtitleLabel.text = subtitle.uppercased()
        }
    }
}
