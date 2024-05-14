//
//  ViewController.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import Cocoa
import AVKit
import SnapKit

// TODO: allow timing editing as text ? with validation using binding and value transformer ?

class ViewController: NSViewController {

    // MARK: VC
    override func viewDidLoad() {
        super.viewDidLoad()
        representedObject = representedObject ?? Subtitle()
        tableView.registerForDraggedTypes([subtitleLineKind])
        tableView.doubleAction = #selector(tableViewDoubleClicked(sender:))
        playerView.playerDelegate = self
        spectralView.delegate = self
        playerControlsView.delegate = self
        timingButton.delegate = self
        
        textfield.placeholderString = L10n.Input.placeholder
        timingButton.title = L10n.Action.updateTiming
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
    @IBOutlet private var spectralView: SpectralView!
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
        panel.prompt = L10n.Dialog.OpenVideo.title
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .video, .audio]
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
    
    @IBAction private func matchEndTimeToNextStart(sender: AnyObject?) {
        guard tableView.selectedRow >= 0 && tableView.selectedRow < subtitle.lines.count - 1 else { return }

        subtitle.updateTimings(
            for: tableView.selectedRow,
            start: subtitle.lines[tableView.selectedRow].timeStart,
            end: subtitle.lines[tableView.selectedRow + 1].timeStart
        )
        tableView.reloadData(forRowIndexes: IndexSet(integer: tableView.selectedRow), columnIndexes: IndexSet(integersIn: 0...2))
        selectNextRow(deselectIfLast: false, scrollToCenter: true, animated: false)
    }
    
    @IBAction private func delaySubtitles(sender: AnyObject?) {
        let alert = NSAlert()

        let okButton = alert.addButton(withTitle: L10n.Action.delay)
        let cancelButton = alert.addButton(withTitle: L10n.Action.cancel)
        alert.messageText = L10n.Dialog.DelaySubtitles.title
        alert.informativeText = L10n.Dialog.DelaySubtitles.subtitle
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 120, height: NSTextField().intrinsicContentSize.height))
        textField.stringValue = "0.000"
        textField.isBezeled = true
        textField.bezelStyle = .roundedBezel

        alert.accessoryView = textField
        alert.window.initialFirstResponder = alert.accessoryView
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            textField.nextKeyView = okButton
            cancelButton.nextKeyView = textField
        }

        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            let value = TimeInterval(textField.stringValue) ?? 0
            subtitle.offsetAllLines(delay: value)
        }
    }
    
    private func selectNextRow(deselectIfLast: Bool, scrollToCenter: Bool, animated: Bool) {
        if tableView.selectedRow < tableView.numberOfRows - 1 {
            tableView.selectRowIndexes(IndexSet(integer: tableView.selectedRow + 1), byExtendingSelection: false)
            let rowRect = tableView.frameOfCell(atColumn: 0, row: tableView.selectedRow)
            if scrollToCenter, let scrollView = tableView.enclosingScrollView, rowRect != .zero {
                let centeredPoint = NSMakePoint(0.0, rowRect.minY + (rowRect.height / 2) - ((scrollView.frame.height) / 2))
                if animated {
                    scrollView.contentView.animator().setBoundsOrigin(centeredPoint)
                } else {
                    tableView.scroll(centeredPoint)
                }
            }
            else if !scrollToCenter {
                tableView.scrollRowToVisible(tableView.selectedRow)
            }
        }
        else if deselectIfLast {
            tableView.deselectAll(nil)
        }
    }
    
    // MARK: Content
    private func updateContent() {
        updateTableView()
        updateSpectralAndVideoView()
        updateTimingButton()
    }
    
    func updateTableView() {
        tableView.reloadData()
    }
    
    private func updateSpectralAndVideoView() {
        if let videoURL {
            playerView.player = AVPlayer(url: videoURL)
            playerView.preferredSpeed = playerControlsView.selectedSpeed
        } else {
            playerView.player = nil
        }
        // spectral view will be updated via the playerView delegate once the item is loaded
    }
    
    private func updateTimingButton() {
        playerControlsView.isEnabled = playerView.player != nil
        timingButton.isEnabled = playerView.player != nil && tableView.selectedRow >= 0 && playerView.isPlaying
    }
}

extension ViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(delaySubtitles(sender:)):
            return true
        case #selector(openVideo(sender:)):
            return true
        case #selector(playPause(sender:)):
            return playerView.player != nil && textfield.currentEditor() == nil
        case #selector(seekForward(sender:)):
            return playerView.player != nil && textfield.currentEditor() == nil
        case #selector(seekBackward(sender:)):
            return playerView.player != nil && textfield.currentEditor() == nil
        case #selector(removeLine(sender:)):
            return tableView.selectedRow >= 0
        case #selector(matchEndTimeToNextStart(sender:)):
            return tableView.selectedRow >= 0 && tableView.selectedRow < subtitle.lines.count - 1
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
    
    func playerViewCurrentItemChanged(_ playerView: PlayerView, url: URL?, duration: TimeInterval?) {
        if let url, let duration {
            spectralView.source = .init(url: url, duration: duration)
        }
        else {
            spectralView.source = nil
        }
    }
    
    func playerViewPositionChanged(_ playerView: PlayerView, position: TimeInterval) {
        spectralView.position = position
    }
}

extension ViewController: SpectralViewDelegate {
    func spectralView(_ spectralView: SpectralView, selectedPosition position: TimeInterval) {
        if (playerView.player?.rate ?? 0) > 0 {
            playerView.player?.pause()
        }
        let time = CMTime(value: Int64(position * 1000), timescale: 1000)
        let precision = CMTime(value: 1, timescale: 100) // precise to 10ms
        playerView.player?.seek(to: time, toleranceBefore: precision, toleranceAfter: precision)
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
        selectNextRow(deselectIfLast: true, scrollToCenter: true, animated: true)
        
        // reset state
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
    
    @objc func tableViewDoubleClicked(sender: AnyObject) {
        guard tableView.selectedRow >= 0, let player = playerView.player, let maxTime = player.currentItem?.duration else { return }
        
        let desiredTime = CMTime(seconds: subtitle.lines[tableView.selectedRow].timeStart, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: min(desiredTime, maxTime))
    }

    @IBAction private func tableViewLineTextFieldChanged(sender: AnyObject?) {
        guard let field = sender as? NSTextField else { return }
        let row = tableView.row(for: field)
        guard row >= 0 else { return }

        subtitle.updateText(for: row, text: field.stringValue)
        
        // the commited text may differ from the input text, let's make sure the row is up to date
        tableView.reloadData(forRowIndexes: IndexSet(integer: tableView.selectedRow), columnIndexes: IndexSet(integersIn: 0...2))
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
