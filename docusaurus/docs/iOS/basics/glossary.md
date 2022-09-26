---
title: Glossary
---

A list of names and terms used in the framework and documentation.

---

- **Client** or **ChatClient**: The root object of the SDK representing the chat service. Typically, an app contains just one instance of `ChatClient`. However, it's possible to have multiple instances if your use case requires it (i.e. more than one window with different workspaces in a Slack-like app).

- **User:** A user entity in a chat app. It's uniquely identified by a `UserId`. Users can't be created directly from the Swift SDK. They must be created by your backend service.

- **CurrentUser:** A user entity that is currently signed-in. Users can't be created directly from the Swift SDK. Your backend service which should provide the Swift SDK with a token to authenticate the current user with.

- **Channel:** A channel contains messages, a list of people that are watching the channel, and optionally a list of members (for private channels). In other words - when you open a messaging the app, the various conversations you see there are "channels". A channel can be a private conversation between two users or a public live-stream-like channel with thousands of users watching it.

- **Member:** If a user belongs to a specific channel it becomes its member. A member is an entity representing a user that belongs to a given channel. It contains some additional information about the channel membership. One "user" entity can be represented as multiple "member" entities in various channels.

- **Watcher:** If a channel is public, it's visible to all users. A user that actively observes a channel is called a "watcher". 

- **Controller:** Controller objects are the primary way of interacting with the chat service. Controller objects are lightweight and can be easily created and destroyed as needed. Controllers can be used for both, continuous data observation, and for quick data mutations. It's possible (and very common) that you have multiple controllers representing a single entity.

- **ExtraData:** Extra Data is additional information that can be added to the default data of Stream. It is a dictionary of key-value pairs that can be attached to messages, users, channels, and pretty much almost every domain model in the Stream SDK.