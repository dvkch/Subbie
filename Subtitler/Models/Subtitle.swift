//
//  Document.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import Cocoa

class Subtitle: NSDocument {

    // MARK: Document
    override init() {
        super.init()
        self.isTransient = true
    }

    override class var autosavesInPlace: Bool {
        return true
    }
    
    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        let contentViewController = windowController.contentViewController as! ViewController
        contentViewController.representedObject = self
        self.addWindowController(windowController)
    }

    override func data(ofType typeName: String) throws -> Data {
        switch typeName {
        case "public.plain-text":
            return lines.map(\.text).joined(separator: "\n").data(using: .utf8)!
            
        case "public.srt":
            // TODO: proper implementation
            return lines.map(\.text).joined(separator: "\n").data(using: .utf8)!

        default:
            throw AppError.invalidFileType
        }
    }

    override func read(from data: Data, ofType typeName: String) throws {
        switch typeName {
        case "public.plain-text":
            let lines = String(data: data, encoding: .utf8)!.split(separator: "\n")
            self.lines = lines.enumerated().map { line in
                Line(text: String(line.element), timeStart: TimeInterval(line.offset), timeEnd: TimeInterval(line.offset))
            }
            isTransient = false
            fileURL = nil
            fileType = "public.srt"

        case "public.srt":
            // TODO: proper implementation
            let lines = String(data: data, encoding: .utf8)!.split(separator: "\n")
            self.lines = lines.enumerated().map { line in
                Line(text: String(line.element), timeStart: TimeInterval(line.offset), timeEnd: TimeInterval(line.offset))
            }
            isTransient = false

        default:
            throw AppError.invalidFileType
        }
    }

    // MARK: Types
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

    // MARK: Properties
    private(set) var isTransient: Bool = false
    private(set) var lines: [Line] = []
    var isEmpty: Bool {
        return lines.isEmpty
    }

    // MARK: Actions
    func add(line: String) -> Int {
        isTransient = false
        updateChangeCount(.changeDone)
        
        let currentMax = lines.map(\.timeStart).max() ?? TimeInterval(-1)
        lines.append(Line(text: line, timeStart: currentMax + 1, timeEnd: currentMax + 1))
        return lines.count - 1
    }
    
    func updateTimings(for lineIndex: Int, start: TimeInterval, end: TimeInterval) {
        isTransient = false
        updateChangeCount(.changeDone)

        lines[lineIndex].timeStart = start
        lines[lineIndex].timeEnd = end
    }
    
    func removeLine(at index: Int) {
        isTransient = false
        updateChangeCount(.changeDone)

        lines.remove(at: index)
    }
}
