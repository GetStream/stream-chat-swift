//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CallSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var audio: AudioSettingsResponse
    var backstage: BackstageSettingsResponse
    var broadcasting: BroadcastSettingsResponse
    var frameRecording: FrameRecordingSettingsResponse
    var geofencing: GeofenceSettingsResponse
    var individualRecording: IndividualRecordingSettingsResponse
    var ingress: IngressSettingsResponse?
    var limits: LimitsSettingsResponse
    var rawRecording: RawRecordingSettingsResponse
    var recording: RecordSettingsResponse
    var ring: RingSettingsResponse
    var screensharing: ScreensharingSettingsResponse
    var session: SessionSettingsResponse
    var thumbnails: ThumbnailsSettingsResponse
    var transcription: TranscriptionSettingsResponse
    var video: VideoSettingsResponse

    init(audio: AudioSettingsResponse, backstage: BackstageSettingsResponse, broadcasting: BroadcastSettingsResponse, frameRecording: FrameRecordingSettingsResponse, geofencing: GeofenceSettingsResponse, individualRecording: IndividualRecordingSettingsResponse, ingress: IngressSettingsResponse? = nil, limits: LimitsSettingsResponse, rawRecording: RawRecordingSettingsResponse, recording: RecordSettingsResponse, ring: RingSettingsResponse, screensharing: ScreensharingSettingsResponse, session: SessionSettingsResponse, thumbnails: ThumbnailsSettingsResponse, transcription: TranscriptionSettingsResponse, video: VideoSettingsResponse) {
        self.audio = audio
        self.backstage = backstage
        self.broadcasting = broadcasting
        self.frameRecording = frameRecording
        self.geofencing = geofencing
        self.individualRecording = individualRecording
        self.ingress = ingress
        self.limits = limits
        self.rawRecording = rawRecording
        self.recording = recording
        self.ring = ring
        self.screensharing = screensharing
        self.session = session
        self.thumbnails = thumbnails
        self.transcription = transcription
        self.video = video
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case audio
        case backstage
        case broadcasting
        case frameRecording = "frame_recording"
        case geofencing
        case individualRecording = "individual_recording"
        case ingress
        case limits
        case rawRecording = "raw_recording"
        case recording
        case ring
        case screensharing
        case session
        case thumbnails
        case transcription
        case video
    }

    static func == (lhs: CallSettingsResponse, rhs: CallSettingsResponse) -> Bool {
        lhs.audio == rhs.audio &&
            lhs.backstage == rhs.backstage &&
            lhs.broadcasting == rhs.broadcasting &&
            lhs.frameRecording == rhs.frameRecording &&
            lhs.geofencing == rhs.geofencing &&
            lhs.individualRecording == rhs.individualRecording &&
            lhs.ingress == rhs.ingress &&
            lhs.limits == rhs.limits &&
            lhs.rawRecording == rhs.rawRecording &&
            lhs.recording == rhs.recording &&
            lhs.ring == rhs.ring &&
            lhs.screensharing == rhs.screensharing &&
            lhs.session == rhs.session &&
            lhs.thumbnails == rhs.thumbnails &&
            lhs.transcription == rhs.transcription &&
            lhs.video == rhs.video
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(audio)
        hasher.combine(backstage)
        hasher.combine(broadcasting)
        hasher.combine(frameRecording)
        hasher.combine(geofencing)
        hasher.combine(individualRecording)
        hasher.combine(ingress)
        hasher.combine(limits)
        hasher.combine(rawRecording)
        hasher.combine(recording)
        hasher.combine(ring)
        hasher.combine(screensharing)
        hasher.combine(session)
        hasher.combine(thumbnails)
        hasher.combine(transcription)
        hasher.combine(video)
    }
}
