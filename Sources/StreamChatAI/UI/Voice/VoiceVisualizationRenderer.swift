//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Metal
import StreamCore

// Draws a voice visualization's shader over a whole render target. All visualizations share
// one. The shaders compile once, off the main thread, and nothing is drawn until they have.
@MainActor
final class VoiceVisualizationRenderer {
    nonisolated static let pixelFormat = MTLPixelFormat.bgra8Unorm

    // Nil without Metal, which leaves the visualizations empty.
    static let shared: VoiceVisualizationRenderer? = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            log.error("Voice visualizations can't render without Metal")
            return nil
        }
        return VoiceVisualizationRenderer(device: device)
    }()

    let device: any MTLDevice
    private let queue: (any MTLCommandQueue)?
    private var pipelines: [VoiceVisualizationStyle: any MTLRenderPipelineState] = [:]
    private var loading: Task<Void, Never>?

    init(device: any MTLDevice) {
        self.device = device
        queue = device.makeCommandQueue()
    }

    func canDraw(_ style: VoiceVisualizationStyle) -> Bool {
        queue != nil && pipelines[style] != nil
    }

    // Starts compiling the shaders, unless they are compiled or compiling.
    func prepare() {
        guard loading == nil else { return }
        let device = UncheckedSendable(device)
        loading = Task {
            do {
                let compiled = try await Task.detached(priority: .userInitiated) {
                    try Self.compile(on: device.value)
                }.value
                pipelines = compiled.value
            } catch {
                log.error("Voice visualizations can't render", error: error)
            }
        }
    }

    // Waits for the shaders to compile.
    func load() async {
        prepare()
        await loading?.value
    }

    // A command buffer that draws `style` into `pass`, for the caller to present and commit.
    func commandBuffer(
        drawing style: VoiceVisualizationStyle,
        with uniforms: VoiceVisualizationUniforms,
        into pass: MTLRenderPassDescriptor
    ) -> (any MTLCommandBuffer)? {
        guard
            let pipeline = pipelines[style],
            let buffer = queue?.makeCommandBuffer(),
            let encoder = buffer.makeRenderCommandEncoder(descriptor: pass)
        else { return nil }
        var uniforms = uniforms
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<VoiceVisualizationUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        return buffer
    }

    nonisolated static func compile(
        on device: any MTLDevice
    ) throws -> UncheckedSendable<[VoiceVisualizationStyle: any MTLRenderPipelineState]> {
        let library = try device.makeLibrary(source: VoiceVisualizationShaders.source, options: nil)
        var pipelines: [VoiceVisualizationStyle: any MTLRenderPipelineState] = [:]
        for style in VoiceVisualizationStyle.allCases {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "voiceVisualizationVertex")
            descriptor.fragmentFunction = library.makeFunction(name: style.fragmentFunction)
            descriptor.colorAttachments[0].pixelFormat = pixelFormat
            pipelines[style] = try device.makeRenderPipelineState(descriptor: descriptor)
        }
        return UncheckedSendable(pipelines)
    }
}

// Carries Metal objects, which are thread-safe, between threads on SDKs that don't mark them
// Sendable.
struct UncheckedSendable<Value>: @unchecked Sendable {
    let value: Value

    init(_ value: Value) {
        self.value = value
    }
}
