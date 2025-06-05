//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 16.0, *)
struct LogDetailView: View {
    let log: LogEntry
    @State private var isCopied = false
    @State private var isCurlCopied = false
    @State private var isJsonCopied = false
    
    // Check if this log contains extractable data
    private var isHttpResponse: Bool {
        log.description.contains("URL request response:") && log.description.contains("Status Code:")
    }
    
    private var isWebSocketEvent: Bool {
        log.description.contains("Event received:")
    }
    
    private var hasJsonData: Bool {
        isHttpResponse || isWebSocketEvent
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: log.level.icon)
                                .foregroundColor(log.level.color)
                                .font(.title2)

                            Text(log.level.displayName)
                                .font(.title2.weight(.semibold))
                                .foregroundColor(log.level.color)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Self.dateFormatter.string(from: log.timestamp))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(Self.timeFormatter.string(from: log.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Information grid
                    VStack(alignment: .leading, spacing: 12) {
                        if !log.subsystems.displayNames.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Subsystems")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)

                                HStack(spacing: 6) {
                                    ForEach(log.subsystems.displayNames, id: \.self) { subsystem in
                                        Text(subsystem)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(6)
                                    }
                                    Spacer()
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("File")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Text("\(log.fileName):\(log.lineNumber)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Function")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            Text(log.functionName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Description section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Log Message")
                            .font(.headline)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            // Copy button
                            Button(action: {
                                UIPasteboard.general.string = log.description
                                isCopied = true
                                
                                // Reset after 1.5 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    isCopied = false
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    Text(isCopied ? "Copied!" : "Copy")
                                }
                                .font(.caption)
                                .foregroundColor(isCopied ? .green : .blue)
                            }
                            
                            // cURL button (only for HTTP responses)
                            if isHttpResponse {
                                Button(action: {
                                    if let curlCommand = generateCurlCommand(from: log.description) {
                                        UIPasteboard.general.string = curlCommand
                                        isCurlCopied = true
                                        
                                        // Reset after 1.5 seconds
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            isCurlCopied = false
                                        }
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: isCurlCopied ? "checkmark" : "terminal")
                                        Text(isCurlCopied ? "Copied!" : "cURL")
                                    }
                                    .font(.caption)
                                    .foregroundColor(isCurlCopied ? .green : .orange)
                                }
                            }
                            
                            // JSON button (for both HTTP responses and WebSocket events)
                            if hasJsonData {
                                Button(action: {
                                    if let jsonData = extractJsonData(from: log.description) {
                                        UIPasteboard.general.string = jsonData
                                        isJsonCopied = true
                                        
                                        // Reset after 1.5 seconds
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            isJsonCopied = false
                                        }
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: isJsonCopied ? "checkmark" : "curlybraces")
                                        Text(isJsonCopied ? "Copied!" : "JSON")
                                    }
                                    .font(.caption)
                                    .foregroundColor(isJsonCopied ? .green : .purple)
                                }
                            }
                        }
                    }

                    SelectableTextView(text: log.description)
                        .frame(minHeight: 200)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
            }
            .padding()
        }
        .navigationTitle("Log Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private func generateCurlCommand(from logText: String) -> String? {
        guard let url = extractUrl(from: logText),
              let headers = extractHeaders(from: logText) else {
            return nil
        }
        
        let method = extractMethod(from: logText) ?? "GET"
        var curlCommand = "curl -X \(method) \\\n  '\(url)'"
        
        // Add headers
        for (key, value) in headers {
            // Skip some response-only headers that shouldn't be in requests
            let skipHeaders = [
                "content-length",
                "date",
                "server",
                "access-control-allow-origin",
                
                "access-control-allow-headers",
                "access-control-allow-methods",
                
                "access-control-max-age",
                "x-envoy-upstream-service-time",
                
                "x-ratelimit-limit",
                "x-ratelimit-remaining",
                "x-ratelimit-reset"
            ]
            
            if !skipHeaders.contains(key.lowercased()) {
                curlCommand += " \\\n  -H '\(key): \(value)'"
            }
        }
        
        // Add data if this was a POST/PUT/PATCH request
        if ["POST", "PUT", "PATCH"].contains(method.uppercased()) {
            if let jsonData = extractJsonData(from: logText) {
                curlCommand += " \\\n  -d '\(jsonData.replacingOccurrences(of: "'", with: "\\'"))'"
            }
        }
        
        return curlCommand
    }
    
    private func extractUrl(from logText: String) -> String? {
        let pattern = #"URL: ([^}]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: logText, range: NSRange(logText.startIndex..., in: logText)) else {
            return nil
        }
        
        let urlRange = Range(match.range(at: 1), in: logText)!
        return String(logText[urlRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractMethod(from logText: String) -> String? {
        // Try to infer method from status code context or default to GET
        if logText.contains("Status Code: 201") {
            return "POST"
        } else if logText.contains("Status Code: 200") && logText.contains("data:") {
            return "GET"
        }
        return "GET"
    }
    
    private func extractHeaders(from logText: String) -> [String: String]? {
        let pattern = #"Headers \{([^}]+)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
              let match = regex.firstMatch(in: logText, range: NSRange(logText.startIndex..., in: logText)) else {
            return nil
        }
        
        let headersRange = Range(match.range(at: 1), in: logText)!
        let headersText = String(logText[headersRange])
        
        var headers: [String: String] = [:]
        
        // Parse header format: "Header-Name" = ( "value" );
        let headerPattern = #""([^"]+)"\s*=\s*\(\s*"([^"]+)""#
        guard let headerRegex = try? NSRegularExpression(pattern: headerPattern) else {
            return headers
        }
        
        let matches = headerRegex.matches(in: headersText, range: NSRange(headersText.startIndex..., in: headersText))
        for match in matches {
            if let keyRange = Range(match.range(at: 1), in: headersText),
               let valueRange = Range(match.range(at: 2), in: headersText) {
                let key = String(headersText[keyRange])
                let value = String(headersText[valueRange])
                headers[key] = value
            }
        }
        
        return headers
    }
    
    private func extractJsonData(from logText: String) -> String? {
        var dataText: String?
        
        // Handle WebSocket events
        if let eventIndex = logText.range(of: "Event received:")?.upperBound {
            dataText = String(logText[eventIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Handle HTTP responses
        else if let httpDataIndex = logText.range(of: "}, data:")?.upperBound ?? logText.range(of: "data:")?.upperBound {
            dataText = String(logText[httpDataIndex...])
        }
        
        guard let text = dataText else {
            return nil
        }
        
        // Find the JSON object - look for the first { and match braces
        guard let startIndex = text.firstIndex(of: "{") else {
            return nil
        }
        
        var braceCount = 0
        var endIndex = startIndex
        
        for index in text[startIndex...].indices {
            let char = text[index]
            if char == "{" {
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if braceCount == 0 {
                    endIndex = index
                    break
                }
            }
        }
        
        let jsonText = String(text[startIndex...endIndex])
        
        // Pretty format the JSON
        if let data = jsonText.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let formattedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let formattedString = String(data: formattedData, encoding: .utf8) {
            return formattedString
        }
        
        return jsonText
    }
}
