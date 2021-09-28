//
//  ViewController.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import Cocoa
import AVKit
import SnapKit

// TODO: enable timing button only if playing
// TODO: implement save
// TODO: show subtitles in video player
// TODO: implement undo
// TODO: allow text editing
// TODO: allow text suppression
// TODO: allow text reordering

class ViewController: NSViewController {

    // MARK: VC
    override func viewDidLoad() {
        super.viewDidLoad()
        representedObject = representedObject ?? Subtitle()
        playerView.delegate = self
        timingButton.delegate = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if subtitleURL == nil {
            //openSubtitle(sender: nil)
        }
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

    // MARK: Views
    @IBOutlet private var tableView: NSTableView!
    @IBOutlet private var textfield: NSTextField!
    @IBOutlet private var playerView: PlayerView!
    @IBOutlet private var timingButton: PressButton!

    // MARK: Actions
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
    
    @IBAction private func textfieldDidReturn(sender: AnyObject?) {
        let string = textfield.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !string.isEmpty else { return }
        let addedIndex = subtitle.add(line: string)
        tableView.insertRows(at: IndexSet(integer: addedIndex), withAnimation: .slideDown)
        textfield.stringValue = ""
    }
    
    private func handlePlayerKeyPress(event: NSEvent) -> Bool {
        guard let player = playerView.player else { return false }
        
        if event.keyCode == 49 && !event.isARepeat {
            // space bar
            if player.rate > 0 {
                player.pause()
            }
            else {
                player.play()
            }
            return true
        }

        switch event.keyCode {
        case 123:
            player.seek(to: CMTime(seconds: player.currentTime().seconds - 5, preferredTimescale: player.currentTime().timescale))
            return true

        case 124:
            player.seek(to: CMTime(seconds: player.currentTime().seconds + 5, preferredTimescale: player.currentTime().timescale))
            return true

        default:
            return false
        }
    }
    
    override func keyDown(with event: NSEvent) {
        guard textfield.currentEditor() == nil else {
            super.keyDown(with: event)
            return
        }

        if !handlePlayerKeyPress(event: event) {
            super.keyDown(with: event)
        }
    }
    
    // MARK: Content
    private func updateContent() {
        if #available(macOS 11.0, *) {
            view.window?.subtitle = subtitleURL?.lastPathComponent ?? ""
        }
        tableView.reloadData()
        updateVideoView()
        updateTimingButton()
    }
    
    private func updateVideoView() {
        if let url = videoURL {
            playerView.player = AVPlayer(url: url)
        } else {
            playerView.player = nil
        }

        // https://github.com/w0lfschild/macOS_headers/blob/a5c2da62810189aa7ea71e6a3e1c98d98bb6620e/macOS/Frameworks/AVKit/587/AVPlayerView.h#L277
        // toggle to force reloading
        playerView.setValue(true, forKey: "canHideControls")
        playerView.setValue(false, forKey: "canHideControls")
    }
    
    private func updateTimingButton() {
        timingButton.isEnabled = playerView.player != nil && tableView.selectedRow >= 0 && playerView.isPlaying
    }
}

extension ViewController: PlayerViewDelegate {
    func playerViewPlayingStatusChanged(_ playerView: PlayerView, playingStatus: Bool) {
        updateTimingButton()
    }
}

extension ViewController: PressButtonDelegate {
    func pressButtonBeganPress(_ pressButton: PressButton) {
        timingButtonPressStart = playerView.player?.currentTime()
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
}
