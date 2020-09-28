# 📲 Stream Chat Sample

This folder contains the source code for Stream Chat's official sample app. You can use it to get a preview of the features and for other testing purposes. It contains multiple samples for different design patterns and use cases in one project using
both **StreamChat** and **StreamChatUI** (coming soon).

## 👩‍🏫 Instructions

<img align="right" src="https://i.imgur.com/WpYeSGh.png" width="33%" />

### 1. Installation

To use the sample, clone this repository, run `carthage bootstrap` in the terminal, and open `StreamChat_v3.xcodeproj` on Xcode. Select the `Sample` target and run in your preferred device. To access every feature, use Xcode 12 and iOS 14. Due to a bug in carthage on Xcode 12, you may need to [use this workaround](https://github.com/Carthage/Carthage/issues/3019#issuecomment-665136323).

### 2. Login

You can use the login to configure the authentication, other user details, and select which sample to enter. It comes pre-configured with a test API Key and a pre-existing user, which you can change by editing the text fields. On the top right, you can press ↻ to get a different pre-existing user. You can also choose between authenticating with a JWT, as a guest, or with a development token. The latter must be allowed in the Stream Chat dashboard. To generate a JWT, you need your app's secret and one of the server-side SDKs or this [JWT generator](https://getstream.io/chat/docs/token_generator/?language=js).

### 3. Select Sample

After setting your user details, you can choose any of the listed samples. Each of them is built with a different design pattern or use case in mind.

#### StreamChat Samples

These samples are built on top of StreamChat. It provides local database logic and API calls, but no UI components. Use StreamChat if you want to build a 
completely custom UI from scratch. We kept the UI simple to focus on the StreamChat usage.

#### StreamChatUI Samples (Coming Soon)

These samples are built on top of StreamChatUI. It provides UIKit components that run on top of StreamChat. Use StreamChatUI if you want a ready-made
fully-featured UI with some customizability options.

### 4. Additional Options

<img align="left" src="https://i.imgur.com/20Ul3ZM_d.webp?maxwidth=728&fidelity=grand" width="33%" />

On the bottom of the login screen, you can find additional options to initialize the chat client. You can choose whether to use the local storage, flush it on start, and select which region your app is in.
