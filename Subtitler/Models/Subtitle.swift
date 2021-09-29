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
        self.hasUndoManager = true
    }

    override class var autosavesInPlace: Bool {
        return true
    }
    
    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        contentViewController = windowController.contentViewController as? ViewController
        contentViewController?.representedObject = self
        self.addWindowController(windowController)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        switch typeName {
        case "public.plain-text":
            self.lines = String(data: data, encoding: .utf8)!
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .enumerated()
                .map { line in Line(text: String(line.element), timeStart: TimeInterval(line.offset), timeEnd: TimeInterval(line.offset)) }

            isTransient = false
            fileURL = nil
            fileType = "public.srt"

        case "public.srt":
            self.lines = try SubRipParser.parse(data: data)
            isTransient = false

        default:
            throw AppError.invalidFileType
        }
    }

    override func data(ofType typeName: String) throws -> Data {
        switch typeName {
        case "public.srt":
            return try SubRipParser.write(lines: lines)

        default:
            throw AppError.invalidFileType
        }
    }

    // MARK: Types
    struct Line: Codable, Equatable {
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
    private weak var contentViewController: ViewController?
    var isEmpty: Bool {
        return lines.isEmpty
    }

    // MARK: Actions
    func add(line: String, timingStart: TimeInterval? = nil, timingEnd: TimeInterval? = nil) -> Int {
        isTransient = false
        updateChangeCount(.changeDone)
        
        let currentMax = lines.map(\.timeStart).max() ?? TimeInterval(0)
        let line = Line(text: line, timeStart: timingStart ?? currentMax, timeEnd: timingEnd ?? currentMax)
        lines.append(line)
        let newLineIndex = lines.count - 1

        undoManager?.registerUndo(withTarget: self, handler: { selfTarget in
            selfTarget.removeLine(at: newLineIndex)
            selfTarget.contentViewController?.updateTableView()
        })
        undoManager?.setActionName("Add line")

        return newLineIndex
    }
    
    func updateText(for lineIndex: Int, text: String) {
        isTransient = false
        updateChangeCount(.changeDone)
        
        var newText = text
        while newText.contains("\n\n") {
            newText = newText.replacingOccurrences(of: "\n\n", with: "\n")
        }

        let previousText = lines[lineIndex].text
        lines[lineIndex].text = newText

        undoManager?.registerUndo(withTarget: self, handler: { selfTarget in
            selfTarget.updateText(for: lineIndex, text: previousText)
            selfTarget.contentViewController?.updateTableView()
        })
        undoManager?.setActionName("Update text")
    }
    
    func updateTimings(for lineIndex: Int, start: TimeInterval, end: TimeInterval) {
        isTransient = false
        updateChangeCount(.changeDone)
        
        let previousTimeStart = lines[lineIndex].timeStart
        let previousTimeEnd = lines[lineIndex].timeEnd

        lines[lineIndex].timeStart = start
        lines[lineIndex].timeEnd = end

        undoManager?.registerUndo(withTarget: self, handler: { selfTarget in
            selfTarget.updateTimings(for: lineIndex, start: previousTimeStart, end: previousTimeEnd)
            selfTarget.contentViewController?.updateTableView()
        })
        undoManager?.setActionName("Update timings")
    }

    func move(from originalIndex: Int, to destinationIndex: Int) {
        isTransient = false
        updateChangeCount(.changeDone)

        let item = lines.remove(at: originalIndex)
        lines.insert(item, at: destinationIndex)

        undoManager?.registerUndo(withTarget: self, handler: { selfTarget in
            selfTarget.move(from: destinationIndex, to: originalIndex)
            selfTarget.contentViewController?.updateTableView()
        })
        undoManager?.setActionName("Move line")
    }
    
    func removeLine(at index: Int) {
        isTransient = false
        updateChangeCount(.changeDone)

        let removedLine = lines[index]
        lines.remove(at: index)

        undoManager?.registerUndo(withTarget: self, handler: { selfTarget in
            _ = selfTarget.add(line: removedLine.text, timingStart: removedLine.timeStart, timingEnd: removedLine.timeEnd)
            selfTarget.contentViewController?.updateTableView()
        })
        undoManager?.setActionName("Remove line")
    }
}
