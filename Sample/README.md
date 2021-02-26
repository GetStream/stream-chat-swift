# 📲 Stream Chat Sample

This folder contains the source code for Stream Chat's official sample app. You can use it to get a preview of the features and for other testing purposes. It contains multiple samples for different design patterns and use cases in one project using
both **StreamChat** and **StreamChatUI**.

## 👩‍🏫 Instructions

<img align="right" src="https://i.imgur.com/WpYeSGh.png" width="33%" />

### 1. Installation

1. Close this repository.
2. Open `StreamChat.xcodeproj` on Xcode.
3. Wait for Swift Package Manager to install dependencies.
4. Select the `Sample` target and run in your preferred device.

### 2. Login

You can use the login to configure the authentication, other user details, and select which sample to enter. It comes pre-configured with a test API Key and a pre-existing user, which you can change by editing the text fields. On the top right, you can press ↻ to get a different pre-existing user. You can also choose between authenticating with a JWT, as a guest, or with a development token. The latter must be allowed in the Stream Chat dashboard. To generate a JWT, you need your app's secret and one of the server-side SDKs or this [JWT generator](https://getstream.io/chat/docs/token_generator/?language=js).

### 3. Select Sample

After setting your user details, you can choose any of the listed samples. Each of them is built with a different design pattern or use case in mind.

### 4. Additional Options

<img align="left" src="https://i.imgur.com/20Ul3ZM.png" width="33%" />

On the bottom of the login screen, you can find additional options to initialize the chat client. You can choose whether to use the local storage, flush it on start, and select which region your app is in.

&nbsp;

## StreamChat Samples

These samples are built on top of StreamChat. It provides local database logic and API calls, but no UI components. Use StreamChat if you want to build a 
completely custom UI from scratch. We kept the UI simple to focus on the StreamChat usage.

<img align="left" src="https://i.imgur.com/Hczqbu9.png" width="33%" />

### UIKit & Delegates

This sample uses the traditional delegate pattern to listen to chat events and update the UI, which is built with UIKit.

### UIKit & Combine

This sample uses Apple's new Combine framework to process the chat events and update the UI, which is also built with UIKit.

&nbsp;

### SwiftUI

This sample is built with declarative code by making full use of Apple's SwiftUI framework alongside StreamChat's ObservableObject wrappers.

<br />

## StreamChatUI Samples (Coming Soon)

These samples are built on top of StreamChatUI. It provides UIKit components that run on top of StreamChat. Use StreamChatUI if you want a ready-made
fully-featured UI with some customizability options.

