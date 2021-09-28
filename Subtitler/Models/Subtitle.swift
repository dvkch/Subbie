//
//  Subtitle.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import Foundation

struct Subtitle {
    private(set) var lines: [Line]

    struct Line {
        var text: String
        var timeStart: TimeInterval
        var timeEnd: TimeInterval

        private static let durationFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.zeroFormattingBehavior = .pad
            formatter.allowsFractionalUnits = true
            formatter.unitsStyle = .positional
            return formatter
        }()
        
        private static let fractionalSecondsFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.maximumIntegerDigits = 0
            formatter.minimumFractionDigits = 3
            formatter.maximumFractionDigits = 3
            formatter.alwaysShowsDecimalSeparator = false
            return formatter
        }()
        
        static func format(time: TimeInterval) -> String {
            let fractionalPart = NSNumber(value: time.truncatingRemainder(dividingBy: 1))
            return durationFormatter.string(from: time)! + fractionalSecondsFormatter.string(from: fractionalPart)!
        }
    }
    
    mutating func add(line: String) -> Int {
        let currentMax = lines.map(\.timeStart).max() ?? TimeInterval(-1)
        lines.append(Line(text: line, timeStart: currentMax + 1, timeEnd: currentMax + 1))
        return lines.count - 1
    }
    
    mutating func updateTimings(for lineIndex: Int, start: TimeInterval, end: TimeInterval) {
        lines[lineIndex].timeStart = start
        lines[lineIndex].timeEnd = end
    }
}

extension Subtitle {
    init(from url: URL) {
        let lines = try! String(contentsOf: url).split(separator: "\n")
        self.lines = lines.enumerated().map { line in
            Line(text: String(line.element), timeStart: TimeInterval(line.offset), timeEnd: TimeInterval(line.offset))
        }
    }
}
