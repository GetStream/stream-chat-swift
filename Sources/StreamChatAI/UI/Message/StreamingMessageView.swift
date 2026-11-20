//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
public struct StreamingMessageView: View {
    var content: String
    var isGenerating: Bool
    
    private let letterInterval: TimeInterval
    
    @State private var displayedText: String
    @State private var characterQueue: [Character] = []
    @State private var typingTimer: Timer?
    // Whether the reply is finished, which the typing timer reads: it was made with an earlier
    // copy of the view, whose `isGenerating` it keeps.
    @State private var isFinished: Bool

    @Environment(\.aiThinkingTurn) private var turn
    @Injected(\.aiAppearance.colors) private var colors
    
    private static let supportedChartLanguages = ["json", "chart", "chartjs", "echarts", "highcharts", "vega-lite", "vegalite"]
    
    public init(
        content: String,
        isGenerating: Bool,
        letterInterval: TimeInterval = 0.005
    ) {
        self.content = content
        self.isGenerating = isGenerating
        self.letterInterval = letterInterval
        // A finished reply shows its text from its first layout: a row that starts out empty has
        // no height, so a list makes many more rows than fit, and they grow as they scroll in.
        _displayedText = State(initialValue: isGenerating ? "" : content)
        _isFinished = State(initialValue: !isGenerating)
    }
    
    public var body: some View {
        Markdown(displayedText)
            .markdownBlockStyle(\.codeBlock) { cfg in
                if #available(iOS 16.0, *), let spec = Self.chartSpec(cfg) {
                    USpecChartView(spec: spec)
                } else {
                    // Not a chart language, not valid ChartSpec JSON, or Swift Charts is unavailable: render as code block
                    CodeBlockView(configuration: cfg)
                }
            }
            .markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
            .onAppear {
                isFinished = !isGenerating
                if !isGenerating {
                    self.characterQueue = []
                    self.displayedText = content
                    return
                }
                // The text shown before it disappeared stays: only the rest is typed.
                queueRest(of: content)
                startTypingTimer()
            }
            .onDisappear {
                stopTypingTimer()
            }
            .transformPreference(AnswerWritingKey.self) { writing in
                writing = (writing ?? false) || isGenerating || !characterQueue.isEmpty
            }
            .onChange(of: characterQueue, perform: { _ in
                if characterQueue.isEmpty && !isGenerating {
                    finishTyping()
                }
            })
            .addChangeListeners(
                content: content,
                isGenerating: isGenerating,
                onContentChange: { _, newValue in
                    // A finished reply can still change, such as when its last words arrive late.
                    if !isGenerating && characterQueue.isEmpty {
                        self.displayedText = newValue
                    } else {
                        queueRest(of: newValue)
                    }
                },
                onIsGeneratingChange: { oldValue, newValue in
                    isFinished = !newValue
                    if newValue {
                        queueRest(of: content)
                        if typingTimer == nil {
                            startTypingTimer()
                        }
                    } else if oldValue {
                        queueRest(of: content)
                        if characterQueue.isEmpty {
                            finishTyping()
                        }
                    }
                }
            )
    }

    // What `newText` adds after the text it shares with `oldText`. It compares Unicode scalars,
    // since a chunk can end inside a character, such as an emoji and its skin tone.
    func getNewChunk(oldText: String, newText: String) -> String {
        let old = oldText.unicodeScalars
        let new = newText.unicodeScalars
        var oldIndex = old.startIndex
        var newIndex = new.startIndex
        while oldIndex != old.endIndex, newIndex != new.endIndex, old[oldIndex] == new[newIndex] {
            old.formIndex(after: &oldIndex)
            new.formIndex(after: &newIndex)
        }
        return String(String.UnicodeScalarView(new[newIndex...]))
    }

    // Queues what `text` adds to the text shown and queued. Text that doesn't carry on from what
    // is shown replaces it at once.
    private func queueRest(of text: String) {
        let typed = displayedText + String(characterQueue)
        if text.unicodeScalars.starts(with: typed.unicodeScalars) {
            characterQueue.append(contentsOf: getNewChunk(oldText: typed, newText: text))
        } else if text.unicodeScalars.starts(with: displayedText.unicodeScalars) {
            characterQueue = Array(getNewChunk(oldText: displayedText, newText: text))
        } else {
            characterQueue = []
            displayedText = text
        }
    }

    private func finishTyping() {
        if displayedText != content {
            displayedText = content
        }
        stopTypingTimer()
    }

    func startTypingTimer() {
        typingTimer?.invalidate()
        let count = Self.charactersPerTick(letterInterval: letterInterval)
        let timer = Timer.scheduledTimer(withTimeInterval: Self.tickInterval(letterInterval: letterInterval), repeats: true) { _ in
            // Scheduled on the main run loop.
            MainActor.assumeIsolated {
                guard !self.characterQueue.isEmpty else {
                    // Typed out after the reply finished, in case that went by between updates.
                    if self.isFinished {
                        self.stopTypingTimer()
                    }
                    return
                }
                let next = self.characterQueue.prefix(count)
                self.displayedText.append(contentsOf: next)
                self.characterQueue.removeFirst(next.count)
            }
        }
        // In a list, an answer waits for the reasoning above it to show and fold first.
        if let start = turn.flatMap({ $0.clock.answerStart(in: $0.key) }), start > Date() {
            timer.fireDate = start
        }
        typingTimer = timer
    }

    private func stopTypingTimer() {
        typingTimer?.invalidate()
        typingTimer = nil
    }

    // The text is shown at most once a frame, a few letters at a time, at the pace of
    // `letterInterval`: a tick lasts as long as the letters it shows.
    static func tickInterval(letterInterval: TimeInterval) -> TimeInterval {
        guard letterInterval.isFinite, letterInterval > 0 else { return 1.0 / 60 }
        return max(letterInterval * Double(charactersPerTick(letterInterval: letterInterval)), 1.0 / 60)
    }

    static func charactersPerTick(letterInterval: TimeInterval) -> Int {
        guard letterInterval > 0, letterInterval.isFinite else { return letterInterval > 0 ? 1 : .max }
        let count = (1.0 / 60 / letterInterval).rounded(.up)
        return Int(min(count, 10000))
    }

    /// The chart a code block describes: its language is one charts are written in, and its
    /// JSON is a chart spec.
    private static func chartSpec(_ configuration: CodeBlockConfiguration) -> USpec? {
        guard let language = configuration.language, supportedChartLanguages.contains(language.lowercased()),
              let data = configuration.content.data(using: .utf8) else { return nil }
        return try? ChartSpecParser.parse(data)
    }

    private var theme: SplashTheme {
        SplashTheme(
            font: .init(size: 16),
            plainTextColor: colors.codeText,
            tokenColors: [
                .keyword: colors.codeKeyword,
                .string: colors.codeString,
                .type: colors.codeType,
                .call: colors.codeCall,
                .number: colors.codeNumber,
                .comment: colors.codeComment,
                .property: colors.codeProperty,
                .dotAccess: colors.codeDotAccess,
                .preprocessing: colors.codePreprocessing
            ],
            backgroundColor: colors.codeBlockHeaderBackground
        )
    }
}
