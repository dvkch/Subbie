//
//  ViewController.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import Cocoa
import AVKit
import SnapKit

// TODO: show subtitles in video player
// TODO: allow text editing (timings too ? with validation using binding and value transformer ?)
// TODO: selectionner plusieurs lignes et demander de mapper time End = (n-1).timeStart
// TODO: scroll dans le player sur selection d'une ligne

class ViewController: NSViewController {

    // MARK: VC
    override func viewDidLoad() {
        super.viewDidLoad()
        representedObject = representedObject ?? Subtitle()
        tableView.registerForDraggedTypes([subtitleLineKind])
        playerView.delegate = self
        playerControlsView.delegate = self
        timingButton.delegate = self
    }

    override var representedObject: Any? {
        didSet {
            updateContent()
        }
    }

    // MARK: Properties
    private var subtitleURL: URL?
    private var videoURL: URL?
    private var subtitle: Subtitle {
        get { representedObject as! Subtitle }
        set { representedObject = newValue }
    }
    private var timingButtonPressStart: CMTime?
    private var timingButtonPressEnd: CMTime?
    private let subtitleLineKind = NSPasteboard.PasteboardType(rawValue: "me.syan.Subtitler.Line")

    // MARK: Views
    @IBOutlet private var tableView: NSTableView!
    @IBOutlet private var textfield: NSTextField!
    @IBOutlet private var playerView: PlayerView!
    @IBOutlet private var playerControlsView: PlayerControlsView!
    @IBOutlet private var timingButton: PressButton!

    // MARK: Table Actions
    @IBAction private func textfieldDidReturn(sender: AnyObject?) {
        let string = textfield.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !string.isEmpty else { return }
        let addedIndex = subtitle.add(line: string)
        tableView.insertRows(at: IndexSet(integer: addedIndex), withAnimation: .slideDown)
        textfield.stringValue = ""
    }
    
    @IBAction private func removeLine(sender: AnyObject?) {
        guard tableView.selectedRow >= 0 else { return }
        let removedIndex = tableView.selectedRow
        subtitle.removeLine(at: removedIndex)
        tableView.removeRows(at: IndexSet(integer: removedIndex), withAnimation: .slideUp)

        if removedIndex - 1 >= 0 && tableView.numberOfRows > 0 {
            tableView.selectRowIndexes(IndexSet(integer: removedIndex - 1), byExtendingSelection: false)
        }
        else if tableView.numberOfRows > 0 {
            tableView.selectRowIndexes(IndexSet(integer: removedIndex), byExtendingSelection: false)
        }
    }

    // MARK: Video Actions
    @IBAction private func openVideo(sender: AnyObject?) {
        guard let window = view.window else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.resolvesAliases = true
        panel.prompt = "Open video file"
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["mp4", "mov"]
        panel.beginSheetModal(for: window) { response in
            if (response == .OK) {
                self.videoURL = panel.url
                self.updateContent()
            }
        }
    }
    
    @IBAction private func playPause(sender: AnyObject?) {
        if playerView.isPlaying {
            playerView.pause()
        }
        else {
            playerView.play()
        }
    }
    
    @IBAction private func seekForward(sender: AnyObject?) {
        guard let player = playerView.player else { return }
        player.seek(to: CMTime(seconds: player.currentTime().seconds + 5, preferredTimescale: player.currentTime().timescale))
    }
    
    @IBAction private func seekBackward(sender: AnyObject?) {
        guard let player = playerView.player else { return }
        player.seek(to: CMTime(seconds: player.currentTime().seconds - 5, preferredTimescale: player.currentTime().timescale))
    }
    
    override func keyDown(with event: NSEvent) {
        if textfield.currentEditor() == nil && event.keyCode == 49 && !event.isARepeat {
            playPause(sender: event)
            return
        }
        super.keyDown(with: event)
    }
    
    // MARK: Content
    private func updateContent() {
        updateTableView()
        updateVideoView()
        updateTimingButton()
    }
    
    func updateTableView() {
        tableView.reloadData()
    }
    
    private func updateVideoView() {
        if let url = videoURL {
            playerView.player = AVPlayer(url: url)
            playerView.preferredSpeed = playerControlsView.selectedSpeeds
        } else {
            playerView.player = nil
        }
    }
    
    private func updateTimingButton() {
        playerControlsView.isEnabled = playerView.player != nil
        timingButton.isEnabled = playerView.player != nil && tableView.selectedRow >= 0 && playerView.isPlaying
    }
}

extension ViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(playPause(sender:)):
            return playerView.player != nil && textfield.currentEditor() == nil
        case #selector(seekForward(sender:)):
            return playerView.player != nil && textfield.currentEditor() == nil
        case #selector(seekBackward(sender:)):
            return playerView.player != nil && textfield.currentEditor() == nil
        case #selector(removeLine(sender:)):
            return tableView.selectedRow >= 0
        default:
            return false
        }
    }
}

extension ViewController: PlayerViewDelegate {
    func playerViewPlayingStatusChanged(_ playerView: PlayerView, playingStatus: Bool) {
        updateTimingButton()
    }
    
    func playerViewRequestsSubtitle(_ playerView: PlayerView, time: TimeInterval) -> String? {
        if timingButtonPressStart != nil && tableView.selectedRow >= 0 {
            return subtitle.lines[tableView.selectedRow].text
        }
        return subtitle.lines.first(where: { $0.timeStart <= time && time <= $0.timeEnd })?.text
    }
}

extension ViewController: PlayerControlsViewDelegate {
    func playerControlsView(_ playerControlsView: PlayerControlsView, changedSpeedTo speed: Float) {
        playerView.preferredSpeed = playerControlsView.selectedSpeed
    }
}

extension ViewController: PressButtonDelegate {
    func pressButtonBeganPress(_ pressButton: PressButton) {
        timingButtonPressStart = playerView.player?.currentTime()
        view.window?.makeFirstResponder(tableView)
    }
    
    func pressButtonEndedPress(_ pressButton: PressButton) {
        timingButtonPressEnd = playerView.player?.currentTime()

        // update subtitle
        guard let start = timingButtonPressStart?.seconds, let end = timingButtonPressEnd?.seconds, tableView.selectedRow >= 0 else { return }
        subtitle.updateTimings(for: tableView.selectedRow, start: start, end: end)
        tableView.reloadData(forRowIndexes: IndexSet(integer: tableView.selectedRow), columnIndexes: IndexSet(integersIn: 0...2))
        
        // update selection
        if tableView.selectedRow < tableView.numberOfRows - 1 {
            tableView.selectRowIndexes(IndexSet(integer: tableView.selectedRow + 1), byExtendingSelection: false)
        }
        else {
            tableView.deselectAll(nil)
        }
        
        timingButtonPressStart = nil
        timingButtonPressEnd = nil
    }
    
    func pressButtonCanceledPress(_ pressButton: PressButton) {
        timingButtonPressStart = nil
        timingButtonPressEnd = nil
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return subtitle.lines.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        switch tableColumn?.identifier.rawValue {
        case "TEXT":
            return subtitle.lines[row].text
            
        case "START":
            return Subtitle.Line.format(time: subtitle.lines[row].timeStart)

        case "END":
            return Subtitle.Line.format(time: subtitle.lines[row].timeEnd)
            
        default:
            return nil
        }
    }
}

extension ViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateTimingButton()
    }

    // https://samwize.com/2018/11/27/drag-and-drop-to-reorder-nstableview/
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setData(try! subtitle.lines[row].asJSON(), forType: subtitleLineKind)
        return pasteboardItem
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
       if dropOperation == .above {
           return .move
       } else {
           return []
       }
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let item = info.draggingPasteboard.pasteboardItems?.first,
            let data = item.data(forType: subtitleLineKind),
            let line = try? Subtitle.Line.fromJSON(data),
            let originalLineIndex = subtitle.lines.firstIndex(of: line)
        else {
            return false
        }

        var newRow = row

        // When you drag an item downwards, the "new row" index is actually --1. Remember dragging operation is `.above`.
        if originalLineIndex < newRow {
            newRow = row - 1
        }
        
        // Persist data
        subtitle.move(from: originalLineIndex, to: newRow)

        // Animate the rows
        tableView.beginUpdates()
        tableView.moveRow(at: originalLineIndex, to: newRow)
        tableView.endUpdates()

        return true
    }
}
