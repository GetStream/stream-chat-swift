//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import UIKit

final class ImageAttachmentCell: UITableViewCell {
    static let reuseIdentifier = "ImageAttachmentCell"
    
    private(set) lazy var activityInicator: UIActivityIndicatorView = {
        let style: UIActivityIndicatorView.Style
        if #available(iOS 13.0, *) {
            style = .medium
        } else {
            style = .gray
        }
        let spinner = UIActivityIndicatorView(style: style)
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    private(set) lazy var attachmentImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    var imageAttachment: ChatMessageImageAttachment? {
        didSet { updateContent() }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        attachmentImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(attachmentImageView)
        
        activityInicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(activityInicator)
        
        NSLayoutConstraint.activate([
            attachmentImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            attachmentImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            attachmentImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            attachmentImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            activityInicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityInicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageAttachment = nil
    }
    
    func updateContent() {
        guard let imageAttachment = imageAttachment else {
            Nuke.cancelRequest(for: attachmentImageView)
            activityInicator.stopAnimating()
            return
        }
        
        activityInicator.startAnimating()
        Nuke.loadImage(
            with: imageAttachment.imagePreviewURL,
            into: attachmentImageView,
            completion: { [weak self] _ in
                self?.activityInicator.stopAnimating()
            }
        )
    }
}
