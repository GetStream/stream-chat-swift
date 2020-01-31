//
//  ComposerView+Files.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 04/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import RxSwift

extension ComposerView {
    
    func setupFilesStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.isHidden = true
        return stackView
    }
    
    /// Add a file upload item for message attachments.
    ///
    /// - Parameter item: a file upload item.
    public func addFileUploaderItem(_ item: UploaderItem) {
        guard let uploader = uploader else {
            return
        }
        
        filesStackView.isHidden = false
        let fileView = ComposerFileView(frame: .zero)
        filesStackView.addArrangedSubview(fileView)
        fileView.iconView.image = item.fileType.icon
        fileView.backgroundColor = style?.backgroundColor
        fileView.fileNameLabel.textColor = style?.textColor
        fileView.fileNameLabel.text = item.fileName
        fileView.fileSize = item.fileSize
        
        fileView.updateRemoveButton(tintColor: style?.textColor) { [weak self, weak item, weak fileView] in
            if let self = self, let item = item, let fileView = fileView {
                self.uploader?.remove(item)
                self.filesStackView.removeArrangedSubview(fileView)
                fileView.removeFromSuperview()
                self.updateFilesStackView()
            }
        }
        
        if item.attachment == nil, item.error == nil {
            fileView.updateForProgress(item.lastProgress)
            
            item.uploading
                .observeOn(MainScheduler.instance)
                .do(onError: { [weak fileView] error in fileView?.updateForError("\(error)") },
                    onCompleted: { [weak self, weak fileView] in
                        fileView?.updateForProgress(1)
                        self?.updateSendButton()
                    },
                    onDispose: { [weak fileView, weak item] in
                        if let error = item?.error {
                            fileView?.updateForError("\(error)")
                        } else {
                            fileView?.updateForProgress(1)
                        }
                })
                .map { $0.progress }
                .catchErrorJustReturn(0)
                .bind(to: fileView.progressView.rx.progress)
                .disposed(by: fileView.disposeBag)
            
        } else if let error = item.error {
            fileView.updateForError("\(error)")
        }
        
        uploader.upload(item: item)
        updateFilesStackView()
    }
    
    var isUploaderFilesEmpty: Bool {
        return (uploader?.items.firstIndex(where: { $0.type == .file })) == nil
    }
    
    func updateFilesStackView() {
        filesStackView.isHidden = isUploaderFilesEmpty
        
        if filesStackView.isHidden {
           filesStackView.removeAllArrangedSubviews()
        }
        
        updateTextHeightIfNeeded()
        updateSendButton()
        updateStyleState()
        updateToolbarIfNeeded()
    }
}
