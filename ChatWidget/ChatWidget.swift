//
//  ChatWidget.swift
//  ChatWidget
//
//  Created by Matheus Cardoso on 29/01/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import StreamChat

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent(), channels: [])
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration, channels: [])
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = [.init(date: Date(), configuration: configuration, channels: [])]
        
        //-> Create Chat Client
        if let credentials = UserCredentials.getLatest() {
            var config = ChatClientConfig(apiKey: .init(credentials.apiKey))
            config.localStorageFolderURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: UserDefaults.groupId)
            let chatClient = ChatClient(config: config, tokenProvider: .static(Token.init(stringLiteral: credentials.token)))
            let channels = chatClient.channelListController(query: .init(filter: .containMembers(userIds: [credentials.id]))).channels
            
            if !channels.isEmpty {
                entries = [SimpleEntry(date: .init(), configuration: configuration, channels: channels)]
            }
        }
        
        
        
        //<-

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        /*let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }*/

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let channels: [ChatChannel]
}

extension ChatChannel {
    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        } else {
            return cid.id
        }
    }
}

struct ChatWidgetEntryView : View {
    var entry: Provider.Entry
    
    @State var images = [
        Image(systemName: "person"),
        Image(systemName: "person"),
        Image(systemName: "person"),
        Image(systemName: "person"),
        Image(systemName: "person"),
        Image(systemName: "person")
    ]
    
    func channelView(index: Int) -> some View {
        Link(destination: URL(string: "demoapp://\(entry.channels[index].cid.id)")!) {
            VStack {
                images[index].frame(width: 72, height: 72, alignment: .center).background(Color.gray.opacity(0.5)).cornerRadius(36)
                Text(entry.channels[index].displayName).lineLimit(1).font(.caption).frame(maxWidth: 72)
            }
        }
    }

    var body: some View {
        HStack {
            if entry.channels.count > 0 {
                channelView(index: 0)
            }
            if entry.channels.count > 1 {
                channelView(index: 1)
            }
            if entry.channels.count > 2 {
                channelView(index: 2)
            }
        }
    }
}

@main
struct ChatWidget: Widget {
    let kind: String = "ChatWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            ChatWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct ChatWidget_Previews: PreviewProvider {
    static var previews: some View {
        ChatWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), channels: []))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
