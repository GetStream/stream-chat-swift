---
title: Push Notifications
---

# Setting up basic push notifications
First step on a way to setting up push notifications is authentication.
Stream supports both **Certificate-based provider connection trust (.p12 certificate)** and **Token-based provider connection trust (JWT)**. Token based authentication is the preferred way to setup push notifications. This method is easy to setup and provides strong security.

## Setting up token based authentication <br/> Step 1. Retrieve Your Team ID

Sign in to your [Apple Developer Account](https://developer.apple.com/account/) and then navigate to Membership. Copy your `Team ID` and store it somewhere safe.

## Step 2. Retrieving your Bundle ID

1. From [App Store Connect](https://appstoreconnect.apple.com), navigate to [My Apps](https://appstoreconnect.apple.com/apps)
2. Select the app you are using Stream Chat with
3. Make sure the App Store tab is selected and navigate to App Information on the left bar
4. In the **General Information** section find `Bundle ID` and copy it

## Step 3. Generating a Token

1. From your [Apple Developer Account](https://developer.apple.com/account/#/overview/) overview, navigate to **Certificates, Identifiers & Providers**
2. Select **Keys** on the navigation pane on the left
3. Click on the **+** button to Add a new key
4. In the **Name** field input a name for your key. In services table select **Apple Push Notifications service (APNs)** and then click on **Continue**
5. Copy your **Key ID** and store it somewhere safe
6. Save the key

## Step 4. Uploading the Key Credentials to Stream Chat

Uploading can be completed using the CLI. To install the CLI, simply run

    npm install -g getstream-cli
or

    yarn global add getstream-cli

:::info
More information on initializing the CLI can be found [here](https://getstream.io/chat/docs/ios-swift/cli_introduction/?language=swift).
:::

Authorize in **Stream CLI**:
      
    stream config:set

Upload the `TeamID`, `KeyID`, `Key` and `BundleID` from the previous steps using a setup wizzard:

    stream chat:push:apn

Or specify all the parameters manually:
   
    stream chat:push:apn -a Key.p8 -b io.team.iOS.BundleID -k KeyID -t TeamID

To check out all the available options run:

    stream chat:push:apn -h


## Setting APN Push Using Certificate Authentication

If token based authentication is not an option, you can setup APN with Certificate Authentication. You will need to generate a valid .p12 certificate for your application and upload it to Stream Chat.

## Step 1. Creating a Certificate Signing Request (CSR)

1. On your Mac, open **Keychain Access**
2. From the top menu go to **Keychain Access > Certificate Assistant > Request a Certificate from a Certificate Authority**
3. Fill out the information in the Certificate Information window:
     * User Email Address
     * Your name
     * In the Request group select **Save to disk**
     * Click **Continue** and save the file on your hard drive in secure area

## Step 2. Creating a Push Notification SSL Certificate

1. Sign in to your [Apple Developer Account](https://developer.apple.com/account/) and then navigate to **Certificates, Identifiers & Providers**
2. Go to **Certificates** tab
3. Click on the **+** button to Add a new certificate
4. In the **Services** section, select Apple Push Notification service SSL (Sandbox) and then click on Continue
5. Select your app in the dropdown list and then click on **Continue**
6. You will see instructions on how to generate a `.certSigningRequest` file. This was already covered in the previous section. Click on **Continue**
7. Click on **Choose File** and then navigate to where you have saved the `.certSigningRequest` file from the previous section, then click on **Continue**
8. Click on **Download** to save your certificate to your hard drive

## Step 3. Export the Certificate in .p12 Format

1. On your mac, navigate to where you have saved the `.cer` file from the previous section and double click on the file. This will add it to your macOS Keychain.
2. Go to **Keychain Access**
3. At the top left, select **Keychains > Login**
4. Then, at the bottom left, select **Category > Certificates**
5. Select the certificate you've created in the previous step. It should look like `Apple Development IOS Push Services: YOUR_APP_NAME` and expand it to see the private key(it should be named after the Name you provided when creating the `Certificate Signing Request`
6. Right-click the private key and click on **Export**. In the **File** format section select **Personal Information Exchange (.p12)** and save the file on your hard drive
  
## Step 4. Uploading the Certificate to Stream Chat

Certificate uploading process is the same regardless of authentication method and was [covered in detail above](#step-4-uploading-the-key-credentials-to-stream-chat).

Essentially you just need to run a setup wizzard:

    stream chat:push:apn


## Testing Push Notifications setup

First of all make sure you have at least one [device associated](#managing-users-for-testing-purposes).

If the device you want to test notifications on is already added to the list, you can now test pushes:

    stream chat:push:test

This will do several things for you:

1. Pick a random message from a channel that this user is part of
2. Use the notification templates configured for your push providers to render the payload using this message
3. Send this payload to all of the user's devices
   
## Managing users for testing purposes

For testing purposes you can manage users using Stream CLI:

### Adding users
    stream chat:push:device:add


### Removing users
    stream chat:push:device:delete

### Getting the list of all devices registered for pushes
    stream chat:push:device:get

## Managing users in client code

### Adding users

```swift
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    chatClient.currentUserController().addDevice(token: deviceToken)
    // or
    chatClient.currentUserController().addDevice(token: deviceToken) { error in
        if let error = error {
            // handle error
            print(error)
        }
    }
}
```

### Removing users

```swift
let deviceId = chatClient.currentUserController().currentUser!.devices.last!.id

chatClient.currentUserController().removeDevice(id: deviceId)
// or
chatClient.currentUserController().removeDevice(id: deviceId) { error in
    if let error = error {
        // handle error
        print(error)
    }
}
```

## Push Delivery Logic

Only new messages are pushed to mobile devices, all other chat events are only send to WebSocket clients and webhook endpoints if configured.

Push message delivery follows the following logic:

* Only channel members can receive push messages
* Members that are currently online do not receive push messages
* Messages added within a thread are only sent to users that are part of that thread (they posted at least one message or were mentioned)
* Messages from muted users are not sent
* Messages are sent to all registered devices for a user (up to 25)
* Don't try to register devices for anonymous users (API will ignore but will eat from rate limit budget)
* Up to 100 members of a channel will receive push notifications
* If `skip_push` parameter for a message was set for `true`, there will be no push
* `push_notifications` should be enabled (default) on the channel