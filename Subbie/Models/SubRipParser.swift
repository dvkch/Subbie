//
//  SubRipParser.swift
//  Subbie
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import Foundation

struct SubRipParser {
    // MARK: Disable init
    private init() {}
    
    // MARK: Parsing/Writing
    enum ParserState {
        case readingIndex
        case readingTimings
        case readingContent
    }
    
    static func parse(data: Data) throws -> [Subtitle.Line] {
        let sourceLines = (String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii))!
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        
        var parsedLines = [Subtitle.Line]()

        var parserState = ParserState.readingIndex
        var currentLineTimings: (TimeInterval, TimeInterval) = (0, 0)
        var currentLineText = ""
        
        for (offset, sourceLine) in sourceLines.enumerated() {
            switch parserState {
            case .readingIndex:
                // we don't really care about indices tbh...
                parserState = .readingTimings

            case .readingTimings:
                let timingStrings = sourceLine
                    .components(separatedBy: timestampsSeparator)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

                if timingStrings.count != 2 {
                    throw AppError.invalidTimingsFormat(sourceLine)
                }

                currentLineTimings = (
                    try timestamp(from: timingStrings[0]),
                    try timestamp(from: timingStrings[1])
                )
                parserState = .readingContent

            case .readingContent:
                if !sourceLine.isEmpty || offset == sourceLines.count - 1 {
                    if currentLineText == "" {
                        currentLineText = sourceLine
                    }
                    else {
                        currentLineText += "\n" + sourceLine
                    }
                }
                if sourceLine.isEmpty || offset == sourceLines.count - 1 {
                    // end of block
                    parsedLines.append(Subtitle.Line(text: currentLineText, timeStart: currentLineTimings.0, timeEnd: currentLineTimings.1))
                    currentLineText = ""
                    parserState = .readingIndex
                }
            }
        }
        
        return parsedLines
    }
    
    static func write(lines: [Subtitle.Line]) throws -> Data {
        let content = lines.enumerated().map { line in
            [
                String(line.offset + 1),
                [
                    string(from: line.element.timeStart),
                    string(from: line.element.timeEnd)
                ].joined(separator: timestampsSeparator),
                line.element.text
            ].joined(separator: "\n")
        }.joined(separator: "\n\n")
        return content.data(using: .utf8)!
    }
    
    // MARK: Formatting
    private static let timestampsSeparator = " --> "
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss,SSS"
        return formatter
    }()
    
    private static func string(from timestamp: TimeInterval) -> String {
        return String(
            format: "%02d:%02d:%02d,%03d",
            Int(timestamp) / 3600,
            (Int(timestamp) % 3600) / 60,
            Int(timestamp) % 60,
            Int(round(timestamp.truncatingRemainder(dividingBy: 1) * 1000))
        )
    }
    
    private static func timestamp(from string: String) throws -> TimeInterval {
        let parts = string.components(separatedBy: CharacterSet(charactersIn: ":,"))
        if parts.count != 4 {
            throw AppError.invalidTimingsFormat(string)
        }
        
        let doubleParts: [Double] = parts.map { Double($0)! }
        return Double(doubleParts[0] * 3600) + Double(doubleParts[1] * 60) + Double(doubleParts[2]) + Double(doubleParts[3] / 1000)
    }
}
