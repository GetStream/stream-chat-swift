import WidgetKit
import SwiftUI
import Intents
import StreamChat
import StreamChatUI

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
        
        if let credentials = UserCredentials.getLatest() {
            var config = ChatClientConfig(apiKey: .init(credentials.apiKey))
            config.localStorageFolderURL = FileManager.default.groupContainerURL
            let chatClient = ChatClient(config: config, tokenProvider: .static(Token.init(stringLiteral: credentials.token)))
            let channels = chatClient.channelListController(query: .init(filter: .containMembers(userIds: [credentials.id]))).channels.map { $0 }
            
            if !channels.isEmpty {
                entries = [SimpleEntry(date: .init(), configuration: configuration, channels: channels)]
            }
        }

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
        return ChatChannelNamer().name(for: self, as: nil)
    }
}

struct ChatWidgetEntryView : SwiftUI.View {
    @Environment(\.widgetFamily) var widgetFamily
    
    var entry: Provider.Entry

    func channelView(index: Int, isSmall: Bool = false) -> some SwiftUI.View {
        let url = URL(string: "demoapp://\(entry.channels[index].cid.id)")!
        
        return Link(destination: url) {
            VStack {
                Spacer().frame(height: 20)
                NetworkImage(url: entry.channels[index].imageURL)
                    .frame(width: 72, height: 72, alignment: .center)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(36)
                Text(entry.channels[index].displayName)
                    .lineLimit(3)
                    .font(.caption)
                    .frame(width: 100)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }.widgetURL(isSmall ? url : nil)
    }

    var body: some SwiftUI.View {
        VStack {
            HStack {
                if entry.channels.count > 0 {
                    channelView(index: 0, isSmall: widgetFamily == .systemSmall)
                }
                if [.systemMedium, .systemLarge].contains(widgetFamily) {
                    if entry.channels.count > 1 {
                        Divider()
                        channelView(index: 1)
                    }
                    if entry.channels.count > 2 {
                        Divider()
                        channelView(index: 2)
                    }
                }
            }
            
            if widgetFamily == .systemLarge {
                HStack {
                    if entry.channels.count > 3 {
                        channelView(index: 3)
                    }
                    if entry.channels.count > 4 {
                        Divider()
                        channelView(index: 4)
                    }
                    if entry.channels.count > 5 {
                        Divider()
                        channelView(index: 5)
                    }
                }
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
    static var previews: some SwiftUI.View {
        ChatWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), channels: []))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
