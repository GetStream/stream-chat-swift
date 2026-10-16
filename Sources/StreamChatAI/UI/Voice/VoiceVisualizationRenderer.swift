//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

#if compiler(>=6.2)
import Metal
#else
// Xcode 16's SDKs do not mark Metal's devices, libraries and pipelines Sendable yet.
@preconcurrency import Metal
#endif
import StreamCore

// Draws a voice visualization's shader over a whole render target. All visualizations share
// one. The shaders compile once, asynchronously, and nothing is drawn until they have.
@MainActor
final class VoiceVisualizationRenderer {
    static let pixelFormat = MTLPixelFormat.bgra8Unorm

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
        loading = Task {
            do {
                pipelines = try await Self.compile(on: device)
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

    // Metal compiles on its own threads; the main actor only waits for the results.
    static func compile(on device: any MTLDevice) async throws -> [VoiceVisualizationStyle: any MTLRenderPipelineState] {
        let library = try await device.makeLibrary(source: VoiceVisualizationShaders.source, options: nil)
        var pipelines: [VoiceVisualizationStyle: any MTLRenderPipelineState] = [:]
        for style in VoiceVisualizationStyle.allCases {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "voiceVisualizationVertex")
            descriptor.fragmentFunction = library.makeFunction(name: style.fragmentFunction)
            descriptor.colorAttachments[0].pixelFormat = pixelFormat
            pipelines[style] = try await device.makeRenderPipelineState(descriptor: descriptor)
        }
        return pipelines
    }
}
