//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import CoreServices
import Social
import StreamChat
import UIKit

@MainActor
class DemoShareViewModel: ObservableObject {
    private let chatClient: ChatClient
    private let userCredentials: UserCredentials
    private var channelList: ChannelList?
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

    @Published var channels: [ChatChannel] = []
    @Published var text = ""
    @Published var images = [UIImage]()
    @Published var selectedChannel: ChatChannel?
    @Published var loading = false

    init(
        userCredentials: UserCredentials,
        extensionContext: NSExtensionContext?
    ) {
        var config = ChatClientConfig(apiKeyString: apiKeyString)
        config.isClientInActiveMode = true
        config.applicationGroupIdentifier = applicationGroupIdentifier

        chatClient = ChatClient(config: config)
        self.userCredentials = userCredentials
        self.extensionContext = extensionContext
        loadChannels()
        loadImages()
    }

    func sendMessage() async throws {
        guard let cid = selectedChannel?.cid else {
            throw ClientError.Unexpected("No channel selected")
        }
        loading = true
        let chat = chatClient.makeChat(for: cid)
        try await chat.get(watch: false)

        let attachmentPayloads = try await withThrowingTaskGroup(of: AnyAttachmentPayload.self) { group in
            for url in imageURLs {
                group.addTask {
                    let uploaded = try await chat.uploadAttachment(with: url, type: .image)
                    let file = try AttachmentFile(url: url)
                    return AnyAttachmentPayload(payload: ImageAttachmentPayload(
                        title: nil,
                        imageRemoteURL: uploaded.remoteURL,
                        file: file
                    ))
                }
            }
            var results = [AnyAttachmentPayload]()
            for try await payload in group {
                results.append(payload)
            }
            return results
        }

        try await chat.sendMessage(with: text, attachments: attachmentPayloads)
        dismissShareSheet()
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
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    // MARK: - private

    private func loadItem(from itemProvider: NSItemProvider, type: String) async throws -> NSSecureCoding {
        try await withCheckedThrowingContinuation { continuation in
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
            try await chatClient.connectUser(
                userInfo: userCredentials.userInfo,
                token: userCredentials.token
            )
            let query = ChannelListQuery(
                filter: .containMembers(userIds: [chatClient.currentUserId ?? ""])
            )
            let list = chatClient.makeChannelList(with: query)
            self.channelList = list
            try await list.get()
            channels = list.state.channels
        }
    }
}
