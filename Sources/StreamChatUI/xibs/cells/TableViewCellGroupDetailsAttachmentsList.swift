//
//  TableViewCellGroupDetailsAttachmentsList.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 02/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI

class TableViewCellGroupDetailsAttachmentsList: UITableViewCell {
    static var reuseID: String = "TableViewCellGroupDetailsAttachmentsList"
    //MARK: - OUTLETS
    @IBOutlet var filesContainerView: UIView!
    @IBOutlet private var buttonMedia: UIButton!
    @IBOutlet private var buttonFiles: UIButton!
    @IBOutlet private var buttonLinks: UIButton!
    @IBOutlet private var indicatorViewLeadingContraint: NSLayoutConstraint!
    private let scrollViewFiles = UIScrollView()
    private let viewTabIndicator = UIView()
    //MARK: - LIFE CYCEL
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        contentView.backgroundColor = .clear
        configureFilesView()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    //MARK: - ACTIONS
    @IBAction func mediaButtonAction(_ sender: UIButton) {
        self.scrollToPage(page: 0)
    }
    @IBAction func fileButtonAction(_ sender: UIButton) {
        self.scrollToPage(page: 1)
    }
    @IBAction func linkButtonAction(_ sender: UIButton) {
        self.scrollToPage(page: 2)
    }
}
// MARK: - Collection View
extension TableViewCellGroupDetailsAttachmentsList {
    private func configureFilesView() {
        scrollViewFiles.delegate = self
        self.filesContainerView.addSubview(scrollViewFiles)
        scrollViewFiles.frame = filesContainerView.bounds
        var xValue: CGFloat = 0
        let width = UIScreen.main.bounds.width
        let arrAttachmentOptions: [AttachmentType] = [.image, .file, .linkPreview]
        for index in 0..<arrAttachmentOptions.count {
            guard let subView: ChatSharedFilesVC = ChatSharedFilesVC
                    .instantiateController(storyboard: .GroupChat) else {
                continue
            }
            xValue = self.scrollViewFiles.frame.size.width * CGFloat(index)
            scrollViewFiles.addSubview(subView.view)
            subView.view.frame = CGRect.init(x: xValue, y: 0, width: width, height: self.filesContainerView.bounds.height)
            subView.attachmentType = arrAttachmentOptions[index]
            subView.setupUI()
        }
        let widthTotal = self.filesContainerView.bounds.size.width * 3
        self.scrollViewFiles.isPagingEnabled = true
        self.scrollViewFiles.contentSize = CGSize(width: widthTotal, height: self.scrollViewFiles.frame.size.height)
    }
    public func scrollToPage(page: Int) {
        var frame: CGRect = self.scrollViewFiles.frame
        frame.origin.x = frame.size.width * CGFloat(page)
        frame.origin.y = 0
        self.scrollViewFiles.scrollRectToVisible(frame, animated: true)
        self.updateIndicator(page: page)
    }
    public func updateIndicator(page: Int) {
        UIView.animate(withDuration: 0.1) {
            switch page {
            case 0:
                self.indicatorViewLeadingContraint.constant = self.buttonMedia.frame.origin.x
            case 1:
                self.indicatorViewLeadingContraint.constant = self.buttonFiles.frame.origin.x
            case 2:
                self.indicatorViewLeadingContraint.constant = self.buttonLinks.frame.origin.x
            default:
                break
            }
            
        }
    }
}
// MARK: - UIScrollViewDelegate
extension TableViewCellGroupDetailsAttachmentsList: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        self.updateIndicator(page: Int(pageNumber))
    }
}
