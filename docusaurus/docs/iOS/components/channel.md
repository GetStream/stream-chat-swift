---
title: Channel
---

import Digraph  from '../common-content/digraph.jsx'
import SingletonNote from '../common-content/chat-client.md'
import ComponentsNote from '../common-content/components-note.md'
//import ChannelProperties from '../common-content/reference-docs/stream-chat-ui/chat-channel/chat-channel-vc-properties.md'

The `ChatChannelVC` is the component presented when a channel is selected from the channel list. This component is responsible to display the messages from a channel, as well as creating new messages for the same channel.

The following diagram shows the components hierarchy of `ChatChannelVC`:

<Digraph>{ `
    ChatChannelVC -> ChatChannelHeaderView
    ChatChannelVC -> ChatMessageListVC
    ChatChannelVC -> ComposerVC
    ChatChannelHeaderView [href="../channel-header-view"]
    ChatMessageListVC [href="../message-list"]
    ComposerVC [href="../message-composer"]
` }</Digraph>

### Overview

- [`ChatChannelHeaderView`](../channel-header-view) is responsible to display the channel information in the `navigationItem.titleView`.
- [`ChatMessageListVC`](../message-list) is the component that handles the rendering of the messages.
- [`ComposerVC`](../message-composer) is the component that handles the creation of new messages.

## Usage
By default, the `ChatChannelVC` is created when a channel is selected in the [`ChatChannelListVC`](../channel-list). But in case you want to create it programmatically, you can use the following code:

```swift
let cid = "channel-id"
let channelVC = ChatChannelVC()
channelVC.channelController = ChatClient.shared.channelController(for: cid)

let navVC = UINavigationController(rootViewController: channelVC)
present(navVC, animated: true, completion: nil)
```

<SingletonNote />

## UI Customization

You can customize how the `ChatChannelVC` looks by subclassing it and swapping the component in `Components` config in case you are using the `ChatChannelListVC`:

```swift
Components.default.channelVC = CustomChatChannelVC.self
```

<ComponentsNote />

Keep in mind this component is only responsible for composing the `ChatChannelHeaderView`, `ChatMessageListVC` and `ChatMessageComposerVC` components together. In case you want to customize the rendering of the messages, you should read the [Message List](../message-list) documentation and the [Message](../message) documentation.

### Channel Avatar Size 
It is really easy to change the channel avatar size displayed by default in the `navigationItem.rightBarButtonItem`. The only thing that is needed is to override the `channelAvatarSize` property, like this:

```swift
class CustomChatChannelVC: ChatChannelVC {
    override var channelAvatarSize: CGSize {
        CGSize(width: 40, height: 40)
    }
}
```

### Layout Customization
Like with any Stream's component, you can customize the layout of the `ChatChannelVC` by overriding the `setUpLayout()` function. In the following example, we add a video player on top of the message list to replicate a live stream event use case.

```swift
import AVFoundation

class CustomChatChannelVC: ChatChannelVC {

    let url = URL(
        string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8"
    )!

    lazy var videoView: UIView = UIView()

    lazy var videoPlayer: AVPlayer = {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        return AVPlayer(playerItem: playerItem)
    }()

    lazy var playerLayer: AVPlayerLayer = {
        AVPlayerLayer(player: videoPlayer)
    }()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        playerLayer.frame = videoView.bounds
        playerLayer.videoGravity = .resizeAspect
    }

    override func setUp() {
        super.setUp()

        videoPlayer.play()
    }

    override func setUpLayout() {
        super.setUpLayout()

        view.addSubview(videoView)
        videoView.layer.addSublayer(playerLayer)
        videoView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            videoView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            videoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: messageListVC.view.topAnchor),
            videoView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 9/16)
        ])
    }
}
```

#### Result:
| Before  | After |
| ------------- | ------------- |
| <img src={require("../assets/channelvc-default.png").default} /> | <img src={require("../assets/channelvc-livestream.png").default} /> |

## Channel Query
When creating a `ChannelController` for the `ChatChannelVC` you can provide `ChannelQuery` different from one used by default. The `ChannelQuery` is the query parameters for fetching the channel from Stream's backend. It has the following initializer:

```swift
public init(
    cid: ChannelId,
    pageSize: Int? = .messagesPageSize,
    paginationParameter: PaginationParameter? = nil,
    membersLimit: Int? = nil,
    watchersLimit: Int? = nil
)
```

### PageSize
The page size is used to specify how many messages the channel will fetch initially and per page. By default the value is `.messagesPageSize` which is `25`.

### PaginationParameter
The pagination parameter can be used to filter specific messages, like for example, to fetch messages only after or before a certain message. Example:

```swift
// Fetch messages after the message with id: "message-id-1"
PaginationParameter.greaterThan("message-id-1")

// Fetch messages before the message with id: "message-id-2"
PaginationParameter.lessThan("message-id-2")
```

### MembersLimit
This argument is used to specify the maximum number of members to be fetched along with the channel info.

### WatchersLimit
This argument is used to specify the maximum number of watchers to be fetched along with the channel info.

## Properties
<!-- <ChannelProperties /> -->
