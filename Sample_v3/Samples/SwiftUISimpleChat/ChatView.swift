//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import SwiftUI

@available(iOS 13, *)
struct ChatView: View {
    @State var channelId: ChannelId
    @State var text: String = ""
    @State var messages: [String] = []
    
    var body: some View {
        VStack {
            List(messages.reversed(), id: \.self) { (message: String) in
                Text(message)
                    .scaleEffect(x: 1, y: -1, anchor: .center)
            }
            .scaleEffect(x: 1, y: -1, anchor: .center)
            .offset(x: 0, y: 2)
            
            HStack {
                TextField("Type a message", text: $text)
                Button(action: self.send) {
                    Text("Send")
                }
            }.padding()
        }
        .navigationBarTitle(Text(channelId.id), displayMode: .inline)
        .onAppear(perform: onAppear)
    }
    
    func send() {
        // send message
        messages += [text]
        text = ""
    }
    
    func onAppear() {
        // load messages
        messages = ["Hello World!", "This is a test", "Mock message"]
    }
}
