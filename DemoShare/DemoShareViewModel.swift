//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import CoreServices
import UIKit
import StreamChat
import Social

@MainActor
class DemoShareViewModel: ObservableObject, ChatChannelControllerDelegate {
    
    private let chatClient: ChatClient
    private let userCredentials: UserCredentials
    private var channelListController: ChatChannelListController?
    private var channelController: ChatChannelController?
    private var messageId: MessageId?
    private var extensionContext: NSExtensionContext?
    private var imageURLs = [URL]() {
        didSet {
            images = imageURLs.compactMap { url in
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    return image
                }
                return nil
            }
        }
    }
    
    var currentUserId: UserId? {
        chatClient.currentUserId
    }
    
    @Published var channels = LazyCachedMapCollection<ChatChannel>()
    @Published var text = ""
    @Published var images = [UIImage]()
    @Published var selectedChannel: ChatChannel?
    @Published var loading = false
    
    init(
        userCredentials: UserCredentials,
        extensionContext: NSExtensionContext?
    ) {
        var config = ChatClientConfig(apiKey: .init(apiKeyString))
        config.isClientInActiveMode = true
        config.applicationGroupIdentifier = applicationGroupIdentifier
        
        let client = ChatClient(config: config)
        client.setToken(token: Token(stringLiteral: userCredentials.token.rawValue))

        self.chatClient = client
        self.userCredentials = userCredentials
        self.extensionContext = extensionContext
        self.loadChannels()
        self.loadImages()
    }
    
    func sendMessage() async throws {
        guard let cid = selectedChannel?.cid else {
            throw ClientError.Unexpected("No channel selected")
        }
        self.channelController = chatClient.channelController(for: cid)
        guard let channelController = channelController else {
            throw ClientError.Unexpected("Can't upload attachment")
        }
        channelController.delegate = self
        loading = true
        try await channelController.synchronize()
        let remoteUrls = await withThrowingTaskGroup(of: URL.self) { taskGroup in
            for url in imageURLs {
                taskGroup.addTask {
                    let uploaded = try await channelController.uploadAttachment(
                        localFileURL: url,
                        type: .image
                    )
                    return uploaded.remoteURL
                }
            }
            
            var results = [URL]()
            while let result = await taskGroup.nextResult() {
                if let url = try? result.get() {
                    results.append(url)
                }
            }
            return results
        }
        
        var attachmentPayloads = [AnyAttachmentPayload]()
        for remoteUrl in remoteUrls {
            let attachment = ImageAttachmentPayload(title: nil, imageRemoteURL: remoteUrl)
            attachmentPayloads.append(AnyAttachmentPayload(payload: attachment))
        }
        
        messageId = try await channelController.createNewMessage(
            text: text,
            attachments: attachmentPayloads
        )
    }
    
    func channelTapped(_ channel: ChatChannel) {
        if selectedChannel == channel {
            selectedChannel = nil
        } else {
            selectedChannel = channel
        }
    }
    
    func dismissShareSheet() {
        loading = false
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    nonisolated func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        Task {
            await MainActor.run {
                for change in changes {
                    if case .update(let item, _) = change {
                        if messageId == item.id, item.localState == nil {
                            dismissShareSheet()
                            return
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - private
    
    private func loadItem(from itemProvider: NSItemProvider, type: String) async throws -> NSSecureCoding {
        return try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadItem(forTypeIdentifier: type) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let item = item {
                    continuation.resume(returning: item)
                } else {
                    continuation.resume(throwing: ClientError.Unknown())
                }
            }
        }
    }
    
    private func loadImages() {
        Task {
            let inputItems = extensionContext?.inputItems
            var urls = [URL]()
            for inputItem in (inputItems ?? []) {
                if let extensionItem = inputItem as? NSExtensionItem {
                    for itemProvider in (extensionItem.attachments ?? []) {
                        if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                            let item = try await loadItem(from: itemProvider, type: kUTTypeImage as String)
                            if let item = item as? URL {
                                urls.append(item)
                            }
                        }
                    }
                }
            }
            self.imageURLs = urls
        }
    }
    
    private func loadChannels() {
        Task {
            try await chatClient.connect(
                userInfo: userCredentials.userInfo,
                token: userCredentials.token
            )
            let channelListQuery: ChannelListQuery = .init(
                filter: .containMembers(userIds: [chatClient.currentUserId ?? ""])
            )
            self.channelListController = chatClient.channelListController(query: channelListQuery)
            channelListController?.synchronize { [weak self] error in
                guard let self, error == nil else { return }
                channels = channelListController?.channels ?? []
            }
        }
    }
}
