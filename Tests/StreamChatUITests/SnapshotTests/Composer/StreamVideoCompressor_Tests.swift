//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamChat
@testable import StreamChatUI
import XCTest

@MainActor final class StreamVideoCompressor_Tests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDown() {
        temporaryDirectories.forEach { try? FileManager.default.removeItem(at: $0) }
        temporaryDirectories = []
        super.tearDown()
    }

    func test_compressVideo_whenQualityIsLow_thenTheResultIsASmallerPlayableVideo() async throws {
        let videoURL = try await makeVideo(width: 640, height: 480, numberOfFrames: 20, bitRate: 8_000_000)
        let compressor = StreamVideoCompressor(progressUpdateInterval: 0.01)
        nonisolated(unsafe) var reportedProgress: [Double] = []

        let compressedURL = try await compressor.compressVideo(at: videoURL, quality: .low) {
            reportedProgress.append($0)
        }
        temporaryDirectories.append(compressedURL.deletingLastPathComponent())

        XCTAssertEqual(compressedURL.pathExtension, "mp4")
        XCTAssertEqual(reportedProgress.last, 1)
        // The progress must be polled while the export runs, not only reported once it finished.
        XCTAssertGreaterThan(reportedProgress.count, 1)
        XCTAssertTrue(reportedProgress.allSatisfy { $0 >= 0 && $0 <= 1 })
        let compressedTrack = await videoTrack(of: compressedURL)
        XCTAssertNotNil(compressedTrack)
        XCTAssertLessThan(try fileSize(of: compressedURL), try fileSize(of: videoURL))
    }

    func test_compressVideo_whenTheContentCompressesPoorly_thenTheWholeDurationIsExported() async throws {
        let videoURL = try await makeVideo(width: 640, height: 480, numberOfFrames: 90, bitRate: 20_000_000)
        let compressor = StreamVideoCompressor()

        let compressedURL = try await compressor.compressVideo(at: videoURL, quality: .high) { _ in }
        temporaryDirectories.append(compressedURL.deletingLastPathComponent())

        let sourceDuration = await duration(of: videoURL)
        let compressedDuration = await duration(of: compressedURL)
        XCTAssertEqual(compressedDuration, sourceDuration, accuracy: 0.1)
    }

    func test_quality_thenEachTierScalesToAnExplicitResolution() {
        XCTAssertEqual(VideoCompressionQuality.low.exportPreset, AVAssetExportPreset640x480)
        XCTAssertEqual(VideoCompressionQuality.medium.exportPreset, AVAssetExportPreset1280x720)
        XCTAssertEqual(VideoCompressionQuality.high.exportPreset, AVAssetExportPreset1920x1080)
    }

    func test_estimatedFileLength_thenItUsesTheBitRateOfTheConfiguredQuality() {
        let duration = CMTime(seconds: 89.09, preferredTimescale: 600)
        XCTAssertEqual(
            StreamVideoCompressor.estimatedFileLength(for: duration, quality: .high),
            169_271_000
        )
        XCTAssertEqual(
            StreamVideoCompressor.estimatedFileLength(for: duration, quality: .medium),
            118_044_250
        )
        XCTAssertEqual(
            StreamVideoCompressor.estimatedFileLength(for: duration, quality: .low),
            30_067_875
        )
    }

    func test_estimatedFileLength_thenALowerQualityAlwaysEstimatesASmallerFile() throws {
        let duration = CMTime(seconds: 60, preferredTimescale: 600)
        let low = try XCTUnwrap(StreamVideoCompressor.estimatedFileLength(for: duration, quality: .low))
        let medium = try XCTUnwrap(StreamVideoCompressor.estimatedFileLength(for: duration, quality: .medium))
        let high = try XCTUnwrap(StreamVideoCompressor.estimatedFileLength(for: duration, quality: .high))

        XCTAssertLessThan(low, medium)
        XCTAssertLessThan(medium, high)
    }

    func test_estimatedFileLength_whenTheVideoIsLong_thenTheEstimateExceedsTheUploadLimit() {
        let estimate = StreamVideoCompressor.estimatedFileLength(
            for: CMTime(seconds: 600, preferredTimescale: 1),
            quality: .high
        )
        XCTAssertEqual(estimate, 1_140_000_000)
        XCTAssertGreaterThan(try XCTUnwrap(estimate), 100 * 1024 * 1024)
    }

    func test_compressVideo_whenTwoVideosAreCompressed_thenBothReportProgressBeforeEitherFinishes() async throws {
        let firstURL = try await makeVideo(width: 640, height: 480, numberOfFrames: 30, bitRate: 4_000_000)
        let secondURL = try await makeVideo(width: 640, height: 480, numberOfFrames: 30, bitRate: 4_000_000)
        let compressor = StreamVideoCompressor(progressUpdateInterval: 0.01)
        let lock = NSLock()
        nonisolated(unsafe) var firstStarted = false
        nonisolated(unsafe) var secondStarted = false
        nonisolated(unsafe) var bothWereInFlight = false

        async let first = compressor.compressVideo(at: firstURL, quality: .high) { _ in
            lock.lock()
            firstStarted = true
            if secondStarted { bothWereInFlight = true }
            lock.unlock()
        }
        async let second = compressor.compressVideo(at: secondURL, quality: .high) { _ in
            lock.lock()
            secondStarted = true
            if firstStarted { bothWereInFlight = true }
            lock.unlock()
        }
        _ = try await (first, second)

        XCTAssertTrue(bothWereInFlight)
    }

    func test_compressVideo_whenTheQualityIsNotSupported_thenAnErrorIsThrown() async throws {
        let videoURL = try await makeVideo(width: 640, height: 480, numberOfFrames: 5, bitRate: 1_000_000)
        let compressor = StreamVideoCompressor()

        do {
            _ = try await compressor.compressVideo(
                at: videoURL,
                quality: .init(exportPreset: "StreamNotAnExportPreset")
            ) { _ in }
            XCTFail("The compression was expected to fail")
        } catch {
            XCTAssertTrue(error is VideoCompressionError)
        }
    }

    // MARK: - Helpers

    private func fileSize(of url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return try XCTUnwrap(attributes[.size] as? NSNumber).int64Value
    }

    private func duration(of url: URL) async -> TimeInterval {
        await withCheckedContinuation { continuation in
            StreamAssetPropertyLoader().loadProperties(
                [AssetProperty(\AVURLAsset.duration)],
                of: AVURLAsset(url: url)
            ) { result in
                guard case .success(let asset) = result else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: CMTimeGetSeconds(asset.duration))
            }
        }
    }

    private func videoTrack(of url: URL) async -> AVAssetTrack? {
        let asset = AVURLAsset(url: url)
        return await withCheckedContinuation { continuation in
            nonisolated(unsafe) let unsafeAsset = asset
            StreamAssetPropertyLoader().loadProperties([AssetProperty(\AVURLAsset.tracks)], of: asset) { _ in
                continuation.resume(returning: unsafeAsset.tracks(withMediaType: .video).first)
            }
        }
    }

    private func makeVideo(width: Int, height: Int, numberOfFrames: Int, bitRate: Int) async throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        temporaryDirectories.append(directory)
        let url = directory.appendingPathComponent("source.mov")

        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: bitRate]
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        writer.add(input)
        XCTAssertTrue(writer.startWriting())
        writer.startSession(atSourceTime: .zero)

        for frame in 0..<numberOfFrames {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 1_000_000)
            }
            let buffer = try makeNoisePixelBuffer(width: width, height: height)
            adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: 30))
        }
        input.markAsFinished()
        await writer.finishWriting()
        XCTAssertEqual(writer.status, .completed)
        return url
    }

    /// Creates a frame filled with noise, so that the video does not compress to almost nothing.
    private func makeNoisePixelBuffer(width: Int, height: Int) throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
        XCTAssertEqual(status, kCVReturnSuccess)
        let buffer = try XCTUnwrap(pixelBuffer)

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let base = try XCTUnwrap(CVPixelBufferGetBaseAddress(buffer))
        arc4random_buf(base, CVPixelBufferGetBytesPerRow(buffer) * height)
        return buffer
    }
}
