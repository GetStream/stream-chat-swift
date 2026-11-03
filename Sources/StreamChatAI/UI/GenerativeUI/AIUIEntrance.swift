//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public extension View {
    /// Brings a part of a reply's generated UI in when it shows, such as when the agent writes
    /// it: the part fades in, rising into place and coming into focus, after the parts that came
    /// in just before it. What shows together with the reply's UI, or with a part around it,
    /// comes in with that, so a reply written before it showed shows at once.
    ///
    /// Renderers give it to each part they place. Every app component has it.
    func aiUIEntrance() -> some View {
        modifier(AIUIEntrance())
    }
}

// A part of a reply's generated UI, which comes in when it shows after the part around it.
struct AIUIEntrance: ViewModifier {
    @State private var hasShown = false

    @Environment(\.aiUIStage) private var stage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .environment(\.aiUIStage, stage?.carrying(!hasShown))
            .modifier(AIUIEntranceEffect(isHidden: !hasShown && stage?.isCarried == false, reduceMotion: reduceMotion))
            .onAppear {
                guard !hasShown else { return }
                guard let stage, !stage.isCarried else {
                    hasShown = true
                    return
                }
                withAnimation(AIUIEntranceEffect.animation(reduceMotion: reduceMotion).delay(stage.cascade.delay())) {
                    hasShown = true
                }
            }
    }
}

// A reply's generated UI as a whole. It comes in when it first shows while the agent writes it,
// and what shows with it comes in with it. A part that shows after it comes in on its own.
struct AIUIEntranceStage: ViewModifier {
    let isStreaming: Bool

    @State private var cascade = AIUICascade()
    @State private var hasShown = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .environment(\.aiUIStage, AIUIStage(isCarried: !hasShown, cascade: cascade))
            .modifier(AIUIEntranceEffect(isHidden: !hasShown && isStreaming, reduceMotion: reduceMotion))
            .onAppear {
                guard !hasShown else { return }
                guard isStreaming else {
                    hasShown = true
                    return
                }
                withAnimation(AIUIEntranceEffect.animation(reduceMotion: reduceMotion).delay(cascade.delay())) {
                    hasShown = true
                }
            }
    }
}

// How a part looks on its way in: clear, a little lower and smaller, and out of focus. With
// motion reduced it only fades.
struct AIUIEntranceEffect: ViewModifier {
    let isHidden: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        let moves = isHidden && !reduceMotion
        return content
            .opacity(isHidden ? 0 : 1)
            .blur(radius: moves ? 8 : 0)
            .scaleEffect(moves ? 0.97 : 1, anchor: .top)
            .offset(y: moves ? 16 : 0)
    }

    static func animation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.3) : .spring(response: 0.7, dampingFraction: 0.88)
    }
}

// How the parts of a reply's generated UI come in: whether one shows together with a part
// around it, which brings it in, and the cascade the parts that come in on their own follow.
struct AIUIStage: Equatable {
    var isCarried: Bool
    let cascade: AIUICascade

    // The stage of what a part holds, which comes in with the part while it first shows.
    func carrying(_ carries: Bool) -> AIUIStage {
        AIUIStage(isCarried: isCarried || carries, cascade: cascade)
    }

    static func == (lhs: AIUIStage, rhs: AIUIStage) -> Bool {
        lhs.isCarried == rhs.isCarried && lhs.cascade === rhs.cascade
    }
}

private struct AIUIStageKey: EnvironmentKey {
    static let defaultValue: AIUIStage? = nil
}

extension EnvironmentValues {
    var aiUIStage: AIUIStage? {
        get { self[AIUIStageKey.self] }
        set { self[AIUIStageKey.self] = newValue }
    }
}

// Spaces out the parts of a reply's generated UI that come in at once, so they follow one
// another, without keeping any of them waiting long.
@MainActor
final class AIUICascade {
    static let step: TimeInterval = 0.1
    static let longestWait: TimeInterval = 0.4

    private var next: TimeInterval = 0

    nonisolated init() { /* Nothing to set up. */ }

    // How long a part that comes in at `now` waits for the parts that came in before it.
    func delay(at now: TimeInterval = ProcessInfo.processInfo.systemUptime) -> TimeInterval {
        let start = min(max(now, next), now + Self.longestWait)
        next = start + Self.step
        return start - now
    }
}
