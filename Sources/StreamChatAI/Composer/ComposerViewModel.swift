//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import SwiftUI

@MainActor
public class ComposerViewModel: ObservableObject {
    @Published public var text = ""
    @Published public var sheetShown = false
    @Published public var attachments: [URL] = [] {
        didSet {
            if attachments.isEmpty {
                selectedAssetURLs.removeAll()
                cleanupTemporaryAttachmentFiles(at: Array(temporaryAttachmentURLs))
                temporaryAttachmentURLs.removeAll()
            }
        }
    }

    @Published public var selectedAssetURLs: [String: URL] = [:]
    @Published public var temporaryAttachmentURLs: Set<URL> = []
    @Published public var selectedChatOption: ChatOption?
    @Published public var isTextFieldFocused: Bool
    @Published public var chatOptions: [ChatOption]

    public init(
        sheetShown: Bool = false,
        attachments: [URL] = [],
        selectedAssetURLs: [String: URL] = [:],
        temporaryAttachmentURLs: Set<URL> = [],
        selectedChatOption: ChatOption? = nil,
        isTextFieldFocused: Bool = false,
        chatOptions: [ChatOption] = []
    ) {
        self.sheetShown = sheetShown
        self.attachments = attachments
        self.selectedAssetURLs = selectedAssetURLs
        self.temporaryAttachmentURLs = temporaryAttachmentURLs
        self.selectedChatOption = selectedChatOption
        self.isTextFieldFocused = isTextFieldFocused
        self.chatOptions = chatOptions
    }
    
    public func removeAttachment(_ url: URL) {
        if let assetEntry = selectedAssetURLs.first(where: { $0.value == url }) {
            selectedAssetURLs.removeValue(forKey: assetEntry.key)
        }
        
        if temporaryAttachmentURLs.contains(url) {
            cleanupTemporaryAttachmentFiles(at: [url])
            temporaryAttachmentURLs.remove(url)
        }
        
        attachments.removeAll(where: { $0 == url })
    }
    
    public func cleanUpData() {
        cleanupTemporaryAttachmentFiles(at: Array(temporaryAttachmentURLs))
        temporaryAttachmentURLs.removeAll()
        attachments.removeAll()
        selectedAssetURLs.removeAll()
        text = ""
    }
    
    public func selectAsset(assetID: String, attachment: AttachmentLocation) {
        guard selectedAssetURLs[assetID] == nil else { return }
        selectedAssetURLs[assetID] = attachment.url
        appendAttachment(attachment)
    }
    
    public func deselectAsset(assetID: String) {
        guard let removed = selectedAssetURLs.removeValue(forKey: assetID) else { return }
        if temporaryAttachmentURLs.contains(removed) {
            cleanupTemporaryAttachmentFiles(at: [removed])
            temporaryAttachmentURLs.remove(removed)
        }
        if let index = attachments.firstIndex(of: removed) {
            attachments.remove(at: index)
        }
    }
    
    public func appendAttachment(_ attachment: AttachmentLocation) {
        attachments.append(attachment.url)
        if attachment.isTemporary {
            temporaryAttachmentURLs.insert(attachment.url)
        } else {
            temporaryAttachmentURLs.remove(attachment.url)
        }
    }
    
    private func cleanupTemporaryAttachmentFiles(at urls: [URL]) {
        let fileManager = FileManager.default
        let uniqueURLs = Set(urls.filter { $0.isFileURL })
        
        for url in uniqueURLs {
            do {
                try fileManager.removeItem(at: url)
            } catch let error as NSError {
                if error.domain == NSCocoaErrorDomain,
                   error.code == NSFileNoSuchFileError {
                    continue
                }
                print("ComposerView attachment cleanup error: \(error.localizedDescription)")
            }
        }
    }
}

public final class AttachmentLocation {
    public let url: URL
    public let isTemporary: Bool

    init(url: URL, isTemporary: Bool) {
        self.url = url
        self.isTemporary = isTemporary
    }
}
