# 📲 Stream Chat UI Demo App

This folder contains the source code for Stream Chat UI's official demo app. You can use it to get a preview of the features and for other testing purposes. This demo app shows a standard implementation using the **StreamChatUI** dependency which includes fully-featured UIKit components.

## 👩‍🏫 Instructions

<img align="right" src="https://i.imgur.com/8vhoAT8.png" width="33%" />

### 1. Installation

1. Clone this repository.
2. Open `StreamChat.xcodeproj` on Xcode.
3. Wait for Swift Package Manager to install dependencies.
4. Select the `DemoApp` target and run in your preferred device.

### 2. Login

The login screen is the initial screen. It displays a list of pre-configured users that you can choose from to access our test server and interact with it using the default UI components. At the very bottom of the list, you can tap "Advanced options" to log in to a different server using custom user credentials. To generate a user token (JWT), you need your app's secret and one of the server-side SDKs or this [JWT generator](https://getstream.io/chat/docs/token_generator/?language=js).

### 3. Chat

After logging in with a user, you'll be directed to the first screen which is the `ChatChannelListViewController`. It will display the channels that your test user is a part of. By tapping any of the channels, you'll access the actual chat screen which is the `ChatChannelViewController`.

#### UI Overview

This demo app is built on top of StreamChatUI. It provides local database logic and API calls, provided by the StreamChat dependency, as well as UIKit components. Use StreamChatUI if you want a ready-made
fully-featured UI with some customizability options.

<img align="left" src="https://i.imgur.com/SaVCtkc.png" width="33%" />

##### Channel List Screen

The channel list screen (`ChatChannelListViewController`) provides an inifinite scrolling list of channels based on a query. It includes avatars, unread indicators, last message previews and timestamps. It's also possible to create channels from the top right button and delete channel by swiping left on it.

##### Channel Screen

The channel screen (`ChatChannelViewController`) provides an inifite scrolling list of messages in a channel. It includes a header with information on the channel, rich media support including GIF and a message composer with file attachment support. It's also possible to react on messages by long pressing on them.

<img align="right" src="https://i.imgur.com/AFcKhNx.png" width="33%" />

<br />

#### Dark Mode

All UI components are compatible with the operating system's Dark Mode setting. Make sure to give it a look by enabling Dark Mode in your test device (Settings > Developer in simulator)!

#### Dynamic Font Sizes

All UI components are compatible with the system's Dynamic Type setting to allow for larger texts for visually impaired users.
