//
//  ComposerView+Files.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 04/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift

extension ComposerView {
    
    func setupFilesStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.isHidden = true
        return stackView
    }
    
    func addFile(_ item: UploaderItem) {
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
            
            item.uploadingCompletion
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak fileView] error in fileView?.updateForError(error.localizedDescription) },
                           onCompleted: { [weak fileView] in fileView?.updateForProgress(1) })
                .disposed(by: fileView.disposeBag)
            
            item.uploadingProgress
                .do(onError: { [weak fileView] error in fileView?.updateForError(error.localizedDescription) },
                    onDispose: { [weak fileView, weak item] in
                        if let error = item?.error {
                            fileView?.updateForError(error.localizedDescription)
                        } else {
                            fileView?.updateForProgress(1)
                        }
                })
                .bind(to: fileView.progressView.rx.progress)
                .disposed(by: fileView.disposeBag)
            
        } else if let error = item.error {
            fileView.updateForError(error.localizedDescription)
        }
        
        uploader.upload(item: item)
        updateFilesStackView()
    }
    
    var isUploaderFilesEmpty: Bool {
        return (uploader?.items.firstIndex(where: { $0.isFileUploading })) == nil
    }
    
    func updateFilesStackView() {
        filesStackView.isHidden = isUploaderFilesEmpty
        
        if filesStackView.isHidden {
           filesStackView.removeAllArrangedSubviews()
        }
        
        updateTextHeightIfNeeded()
        updateSendButton()
        updateStyleState()
        updateToolBarHeight()
    }
}
