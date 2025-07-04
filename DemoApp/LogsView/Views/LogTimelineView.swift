//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 16.0, *)
struct LogTimelineView: View {
    let logs: [LogEntry]
    let searchText: String
    
    // Filter to only show HTTP requests with duration
    var httpLogs: [LogEntry] {
        logs.filter { log in
            log.subsystems.contains(.httpRequests) && log.duration != nil
        }
        .sorted { $0.timestamp > $1.timestamp }
    }
    
    // Group logs within 3-second windows
    var logGroups: [[LogEntry]] {
        guard !httpLogs.isEmpty else { return [] }
        
        let sortedLogs = httpLogs.sorted { $0.timestamp < $1.timestamp }
        let groupingWindow: TimeInterval = 3.0
        
        var groups: [[LogEntry]] = []
        var currentGroup: [LogEntry] = []
        var currentGroupStartTime: Date?
        
        for log in sortedLogs {
            if let startTime = currentGroupStartTime {
                // Check if this log is within the 3-second window
                if log.timestamp.timeIntervalSince(startTime) <= groupingWindow {
                    currentGroup.append(log)
                } else {
                    // Start a new group
                    if !currentGroup.isEmpty {
                        groups.append(currentGroup)
                    }
                    currentGroup = [log]
                    currentGroupStartTime = log.timestamp
                }
            } else {
                // First log
                currentGroup = [log]
                currentGroupStartTime = log.timestamp
            }
        }
        
        // Add the last group
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }
        
        return groups
    }
    
    var body: some View {
        if httpLogs.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("No HTTP requests found")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("HTTP requests with duration will appear here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 300)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(logGroups.enumerated()), id: \.offset) { groupIndex, group in
                        TimelineGroupView(
                            logs: group,
                            searchText: searchText,
                            groupIndex: groupIndex
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

@available(iOS 16.0, *)
struct TimelineGroupView: View {
    let logs: [LogEntry]
    let searchText: String
    let groupIndex: Int
    
    private var groupTimeRange: (start: Date, end: Date) {
        guard !logs.isEmpty else { return (Date(), Date()) }
        let start = logs.map(\.timestamp).min() ?? Date()
        let end = start.addingTimeInterval(3.0) // Always 3 seconds from start
        return (start, end)
    }
    
    private var groupTimeSpan: TimeInterval {
        3.0 // Always 3 seconds
    }
    
    private var timelineWidth: CGFloat {
        // Use available screen width minus the column widths for edge-to-edge timeline
        let screenWidth = UIScreen.main.bounds.width
        let columnWidth: CGFloat = 80 // For timestamp/duration column
        let padding: CGFloat = 48 // Total horizontal padding (24 per side)
        return max(screenWidth - columnWidth - padding, 200) // Minimum 200px
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Group header
            HStack {
                Text(Self.timeFormatter.string(from: groupTimeRange.start))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("→")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(Self.timeFormatter.string(from: groupTimeRange.end))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(logs.count) request\(logs.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Scrollable timeline for this group
            VStack(alignment: .leading, spacing: 6) {
                // Timeline header
                TimelineGroupHeaderView(
                    timeRange: groupTimeRange,
                    timeSpan: groupTimeSpan,
                    timelineWidth: timelineWidth
                )

                // Timeline bars
                ForEach(logs) { log in
                    TimelineBarView(
                        log: log,
                        searchText: searchText,
                        timeRange: groupTimeRange,
                        timeSpan: groupTimeSpan,
                        timelineWidth: timelineWidth
                    )
                }
            }.padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .opacity(0.5)
        )
    }
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

@available(iOS 16.0, *)
struct TimelineGroupHeaderView: View {
    let timeRange: (start: Date, end: Date)
    let timeSpan: TimeInterval
    let timelineWidth: CGFloat
    
    private var timeMarkers: [(time: Date, position: CGFloat)] {
        guard timeSpan > 0 else { return [] }
        
        // Create markers every 1 second for the 3-second timeline
        let markerInterval: TimeInterval = 1.0
        var markers: [(time: Date, position: CGFloat)] = []
        
        for i in 0...2 { // 0, 1, 2 seconds
            let currentTime = timeRange.start.addingTimeInterval(TimeInterval(i) * markerInterval)
            let offset = currentTime.timeIntervalSince(timeRange.start)
            let position = CGFloat(offset / timeSpan) * timelineWidth
            markers.append((currentTime, position))
        }
        
        return markers
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Duration")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: timelineWidth, height: 16)
                
                ForEach(Array(timeMarkers.enumerated()), id: \.offset) { _, marker in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(Self.timeFormatter.string(from: marker.time))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 1, height: 6)
                    }
                    .offset(x: marker.position)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.S"
        return formatter
    }()
}

@available(iOS 16.0, *)
struct TimelineBarView: View {
    let log: LogEntry
    let searchText: String
    let timeRange: (start: Date, end: Date)
    let timeSpan: TimeInterval
    let timelineWidth: CGFloat
    
    private var duration: TimeInterval {
        log.duration ?? 0.0
    }
    
    private var barStartPosition: CGFloat {
        let timeOffset = log.timestamp.timeIntervalSince(timeRange.start)
        // Clamp to 3-second range
        let clampedOffset = max(0, min(timeOffset, 3.0))
        // Position relative to the timeline width
        return CGFloat(clampedOffset / 3.0) * timelineWidth
    }
    
    private var barWidth: CGFloat {
        guard duration > 0 else { return 2 }
        // Scale duration relative to the 3-second timeline width
        let pixelsPerSecond = timelineWidth / 3.0
        return max(CGFloat(duration) * pixelsPerSecond, 2)
    }
    
    private var statusColor: Color {
        switch log.level {
        case .error: return .red
        case .warning: return .orange
        case .info: return .green
        case .debug: return .blue
        }
    }
    
    private var durationText: String {
        if duration < 1.0 {
            return String(format: "%.0fms", duration * 1000)
        } else {
            return String(format: "%.2fs", duration)
        }
    }
    
    private var firstLineText: String {
        let lines = log.description.components(separatedBy: .newlines)
        return lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    var body: some View {
        NavigationLink(destination: LogDetailView(log: log)) {
            VStack(alignment: .leading, spacing: 2) {
                // First line of log description above the timeline
                HStack {
                    Spacer()
                        .frame(width: 80) // Align with column
                    
                    HighlightedSearchText(
                        text: firstLineText,
                        searchText: searchText
                    )
                    .font(.caption2)
                    .foregroundColor(statusColor)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack(spacing: 2) {
                    VStack(spacing: 2) {
                        // Timestamp
                        Text(Self.timeFormatter.string(from: log.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)

                        // Duration on the left
                        Text(durationText)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(statusColor)
                            .frame(width: 80, alignment: .leading)
                    }
                    
                    // Timeline area
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: timelineWidth, height: 30)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(statusColor)
                            .frame(width: barWidth, height: 26)
                            .offset(x: barStartPosition)
                    }
                }
            }
            .padding(.vertical, 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
