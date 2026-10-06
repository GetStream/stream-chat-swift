//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
internal import MarkdownUI
internal import Splash

public struct StreamingMessageView: View {
    var content: String
    var isGenerating: Bool
    
    private let letterInterval: TimeInterval
    
    @State private var displayedText: String = ""
    @State private var characterQueue: [Character] = []
    @State private var typingTimer: Timer?
    @State var queue = DispatchQueue(label: "com.streamai.textview")
    
    private static let supportedChartLanguages = ["json", "chart", "chartjs", "echarts", "highcharts", "vega-lite", "vegalite"]
    
    public init(
        content: String,
        isGenerating: Bool,
        letterInterval: TimeInterval = 0.005
    ) {
        self.content = content
        self.isGenerating = isGenerating
        self.letterInterval = letterInterval
    }
    
    public var body: some View {
        Markdown(displayedText)
            .markdownBlockStyle(\.codeBlock) { cfg in
                if #available(iOS 16.0, *), let spec = Self.chartSpec(cfg) {
                    USpecChartView(spec: spec)
                } else {
                    // Not a chart language, not valid ChartSpec JSON, or Swift Charts is unavailable: render as code block
                    CodeBlockView(configuration: cfg, theme: theme)
                }
            }
            .markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
            .onAppear {
                if !isGenerating {
                    self.displayedText = content
                    return
                }
                if self.characterQueue.isEmpty {
                    self.characterQueue.append(contentsOf: content)
                }
                startTypingTimer()
            }
            .onDisappear {
                typingTimer?.invalidate()
                typingTimer = nil
            }
            .onChange(of: characterQueue, perform: { _ in
                if characterQueue.isEmpty && !isGenerating {
                    self.displayedText = content
                }
            })
            .addChangeListeners(
                content: content,
                isGenerating: isGenerating,
                onContentChange: { oldValue, newValue in
                    queue.sync {
                        if !isGenerating {
                            if oldValue.isEmpty && !newValue.isEmpty {
                                self.displayedText = newValue
                            }
                            return
                        }
                        let newChunk = getNewChunk(oldText: oldValue, newText: newValue)
                        self.characterQueue.append(contentsOf: newChunk)
                    }
                },
                onIsGeneratingChange: { oldValue, newValue in
                    queue.sync {
                        if newValue {
                            if typingTimer == nil {
                                if self.characterQueue.isEmpty {
                                    self.characterQueue.append(contentsOf: content)
                                }
                                startTypingTimer()
                            }
                        } else if oldValue && !newValue {
                            let inQueue = String(characterQueue)
                            let newChunk = getNewChunk(oldText: displayedText + inQueue, newText: content)
                            self.characterQueue.append(contentsOf: newChunk)
                        }
                    }
                }
            )
    }
    
    func getNewChunk(oldText: String, newText: String) -> String {
        if newText.hasPrefix(oldText) {
            // Old text is a prefix of new text
            let startIndex = newText.index(newText.startIndex, offsetBy: oldText.count)
            let newChunk = String(newText[startIndex...])
            return newChunk
        } else {
            // Find the longest common prefix
            let commonPrefix = oldText.commonPrefix(with: newText)
            let startIndex = newText.index(newText.startIndex, offsetBy: commonPrefix.count)
            let newChunk = String(newText[startIndex...])
            return newChunk
        }
    }
    
    func startTypingTimer() {
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: letterInterval, repeats: true) { _ in
            // Scheduled on the main run loop.
            MainActor.assumeIsolated {
                guard !self.characterQueue.isEmpty else { return }
                let nextCharacter = self.characterQueue.removeFirst()
                self.displayedText.append(nextCharacter)
            }
        }
    }

    /// The chart a code block describes: its language is one charts are written in, and its
    /// JSON is a chart spec.
    private static func chartSpec(_ configuration: CodeBlockConfiguration) -> USpec? {
        guard let language = configuration.language, supportedChartLanguages.contains(language.lowercased()),
              let data = configuration.content.data(using: .utf8) else { return nil }
        return try? parseUSpec(from: data)
    }

    private var theme: Splash.Theme {
        .sunset(withFont: .init(size: 16))
    }
}
