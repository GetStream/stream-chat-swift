//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

///
/// # SimpleChannelImageAttachmentsListController
///
/// A `UITableViewController` subclass that displays and manages the list of image attachments sent to a channel.
/// It uses the `ChatMessageSearchController`  class to make API calls to the Stream Chat API
/// and listens to events by conforming to `ChatMessageSearchControllerDelegate`.
///
final class SimpleChannelImageAttachmentsListController: UITableViewController, ChatMessageSearchControllerDelegate {
    ///
    /// # messageSearchController
    ///
    /// The property below holds the `ChatMessageSearchController` object.
    /// It is used to make calls to the Stream Chat API and to listen to the search query changes.
    ///
    /// `messageSearchController.client` holds a reference to the `ChatClient`
    /// which created this instance. It can be used to create other controllers.
    ///
    var messageSearchController: ChatMessageSearchController!
    
    /// The channel identifier used in message search query to filter only messages from a specifci
    /// channel
    var cid: ChannelId!
    
    /// The image attachments taken from messages loaded via a search query.
    private var imageAttachments: [ChatMessageImageAttachment] = [] {
        didSet { tableView.reloadData() }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ImageAttachmentCell.self, forCellReuseIdentifier: ImageAttachmentCell.reuseIdentifier)
        
        // When new messages are loaded, the message search controller
        // notifies the delegate about search results changes.
        messageSearchController.delegate = self
        
        // The message seach query is created. Search results will contain
        // only messags related to the channel with the given `cid`
        // and only those ones that contain image attachments.
        let query = MessageSearchQuery(
            channelFilter: .equal(.cid, to: cid),
            messageFilter: .withAttachments([.image]),
            pageSize: 5
        )
        
        // The controller starts searching the query and loads
        // the first page of results.
        messageSearchController.search(query: query)
    }
    
    // MARK: - UITableViewDelegate, UITableViewDatasource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        imageAttachments.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ImageAttachmentCell.reuseIdentifier,
            for: indexPath
        ) as! ImageAttachmentCell
        cell.imageAttachment = imageAttachments[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row == imageAttachments.count - 1 else { return }
        
        messageSearchController.loadNextMessages()
    }
    
    // MARK: - ChatMessageSearchControllerDelegate
    
    ///
    /// The methods below are part of the `ChatMessageSearchControllerDelegate` protocol and
    /// get's called when search results change (e.g. when new message page is loaded)
    ///
    /// # didChangeUsers
    ///
    /// The method below receives the `changes` that happen in the searcg results.
    /// It updates the `imageAttachments` accordingly and triggers reload of `UITableView`.
    ///
    func controller(_ controller: ChatMessageSearchController, didChangeMessages changes: [ListChange<ChatMessage>]) {
        imageAttachments = controller.messages.flatMap(\.imageAttachments)
    }
}
