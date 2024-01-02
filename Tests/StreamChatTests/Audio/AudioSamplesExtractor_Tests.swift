//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamChat
import XCTest

final class AudioSamplesExtractor_Tests: XCTestCase {
    private lazy var subject: AudioSamplesExtractor! = .init()
    private lazy var sampleBuffer: Data! = .init()

    override func tearDown() {
        sampleBuffer = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - extractSamples(from:sampleBuffer:samplesPerPixel:)

    func testExtractSamples_withNoSampleBuffer() throws {
        var sampleBuffer = Data()
        let readSampleBuffer = makeReadSampleBuffer(
            data: sampleBuffer,
            formatDescription: makeFormatDescription()
        )

        let result = subject.extractSamples(
            from: readSampleBuffer,
            sampleBuffer: &sampleBuffer,
            downsamplingRate: 2
        )

        XCTAssertEqual(result.samplesToProcess, 0)
        XCTAssertEqual(result.downSampledLength, 0)
    }

    func testExtractSamples_withValidSampleBuffer_downsamplingIs2_returnsResultWithExpectedProperties() {
        let audioData: [Int16] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let readSampleBuffer = makeReadSampleBuffer(
            data: audioData.withUnsafeBufferPointer { Data(buffer: $0) },
            formatDescription: makeFormatDescription()
        )
        var sampleBuffer = Data()

        let result = subject.extractSamples(
            from: readSampleBuffer,
            sampleBuffer: &sampleBuffer,
            downsamplingRate: 2
        )

        XCTAssertEqual(.init(samplesToProcess: 10, downSampledLength: 5), result)
    }

    func testExtractSamples_withValidSampleBuffer_downsamplingIsHalfTheSizeOfAudioData_returnsResultWithExpectedProperties() {
        let audioData: [Int16] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let readSampleBuffer = makeReadSampleBuffer(
            data: audioData.withUnsafeBufferPointer { Data(buffer: $0) },
            formatDescription: makeFormatDescription()
        )
        var sampleBuffer = Data()

        let result = subject.extractSamples(
            from: readSampleBuffer,
            sampleBuffer: &sampleBuffer,
            downsamplingRate: audioData.count / 2
        )

        XCTAssertEqual(.init(samplesToProcess: 10, downSampledLength: 2), result)
    }

    // MARK: - Private Helpers

    /// Creates a new CMSampleBuffer with the specified parameters.
    private func makeReadSampleBuffer(
        data: Data,
        formatDescription: CMFormatDescription
    ) -> CMSampleBuffer? {
        var timing = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: .invalid,
            decodeTimeStamp: .invalid
        )
        var sampleBuffer: CMSampleBuffer?
        let blockBufferLength = data.count
        var blockBuffer: CMBlockBuffer?
        guard CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: UnsafeMutableRawPointer(mutating: data.withUnsafeBytes { $0.baseAddress! }),
            blockLength: blockBufferLength,
            blockAllocator: kCFAllocatorNull,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: blockBufferLength,
            flags: 0,
            blockBufferOut: &blockBuffer
        ) == kCMBlockBufferNoErr
        else {
            return nil
        }
        let status = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleCount: 1,
            sampleTimingEntryCount: 0,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 1,
            sampleSizeArray: [data.count],
            sampleBufferOut: &sampleBuffer
        )
        return status == noErr ? sampleBuffer : nil
    }

    /// Creates a new CMAudioFormatDescription with the specified parameters.
    private func makeFormatDescription(
        mediaType: CMMediaType = kCMMediaType_Audio,
        mediaSubType: FourCharCode = kAudioFormatMPEG4AAC,
        frameRate: Float64 = 44100,
        channels: UInt32 = 1,
        interleaved: Bool = false
    ) -> CMFormatDescription {
        var audioStreamBasicDescription = AudioStreamBasicDescription(
            mSampleRate: frameRate,
            mFormatID: mediaSubType,
            mFormatFlags: 0,
            mBytesPerPacket: 2 * channels,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2 * channels,
            mChannelsPerFrame: channels,
            mBitsPerChannel: 16,
            mReserved: 0
        )

        var formatDescription: CMFormatDescription!
        let status = CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &audioStreamBasicDescription,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )

        assert(status == noErr)

        return formatDescription
    }
}
