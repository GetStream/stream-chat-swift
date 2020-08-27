//
//  ChannelListView.swift
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 13, *)
struct ChannelListView: View {
    @State
    var channels = [String]()
    @State
    var createTrigger = false
    @State
    var searchTerm = ""
    
    var body: some View {
        VStack {
            List(channels, id: \.self) { channelId in
                NavigationLink(destination: ChatView(channelId: channelId)) {
                    Text(channelId)
                }
            }.onAppear(perform: loadChannels)
        }.navigationBarTitle("Channels")
    }
    
    func loadChannels() {
        channels = ["# StreamChat", "# Foobar", "# Appleseed"]
    }
}
