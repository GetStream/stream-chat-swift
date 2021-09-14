---
title: Channel
---

import Digraph  from '../common-content/digraph.jsx'
import SingletonNote from '../common-content/chat-client.md'
import ComponentsNote from '../common-content/components-note.md'

The `ChatChannelVC` is the component presented when a channel is selected from the channel list. This component is responsible to display the messages from the channel, as well as creating new messages through the composer.

The following diagram shows the components hierarchy of `ChatChannelVC`:

<Digraph>{ `
    ChatChannelVC -> ChatChannelHeaderView
    ChatChannelVC -> ChatMessageListVC
    ChatChannelVC -> ChatMessageComposerVC
    ChatChannelHeaderView [href="../channel-header-view"]
    ChatMessageListVC [href="../message-list"]
    ChatMessageComposerVC [href="../message-composer"]
` }</Digraph>

### Overview

- [`ChatChannelHeaderView`](../channel-header-view) is responsible to display the channel information in the `navigationItem.titleView`.
- [`ChatMessageListVC`](../message-list) is the component that handles the rendering of the messages and delegates the data providing and events to the `ChatChannelVC` component.
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

You can customize how the `ChatChannelVC` looks by subclassing it and swap the component in `Components` config in case you are using the `ChatChannelListVC`:

```swift
Components.default.channelVC = CustomChatChannelVC.self
```

<ComponentsNote />

Keep in mind this component is only responsible for composing the `ChatChannelHeaderView`, `ChatMessageListVC` and `ChatMessageComposerVC` components together. In case you want to customize the rendering of the messages, you should read the [Message List](../message-list) documentation and the [Message](../message) documentation.

### Channel avatar size 
It is really easy to change the channel avatar size displayed, by default, in the `navigationItem.rightBarButtonItem`. The only think that is needed is to override the `channelAvatarSize` property, like this:

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

### Message List Data Source

The `ChatChannelVC` component is responsible to provide the data to the `ChatMessageListVC` component by implementing the `ChatMessageListVCDataSource` protocol. You can customize how the data is provided by subclassing the `ChatChannelVC` and overriding the functions from the protocol.

### Message List Delegate

### Channel Events

## Channel Query

### Filter

### Sorting

### Page Size

## Properties
