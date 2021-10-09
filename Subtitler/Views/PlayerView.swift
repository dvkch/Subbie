//
//  PlayerView.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import AVKit
import SnapKit

protocol PlayerViewDelegate: NSObjectProtocol {
    func playerViewPlayingStatusChanged(_ playerView: PlayerView, playingStatus: Bool)
    func playerViewRequestsSubtitle(_ playerView: PlayerView, time: TimeInterval) -> String?
}

class PlayerView: AVPlayerView {
    
    // MARK: Init
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        subtitleView.text = nil
        addSubview(subtitleView)
        subtitleView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(8)
            make.bottom.lessThanOrEqualToSuperview().offset(-50)
        }
    }
    
    // MARK: Properties
    weak var delegate: PlayerViewDelegate?
    override var player: AVPlayer? {
        didSet {
            if let oldValue = oldValue {
                removeStatusObservers(from: oldValue)
            }
            if let player = player {
                addStatusObservers(to: player)
            }
            delegate?.playerViewPlayingStatusChanged(self, playingStatus: isPlaying)

            // https://github.com/w0lfschild/macOS_headers/blob/a5c2da62810189aa7ea71e6a3e1c98d98bb6620e/macOS/Frameworks/AVKit/587/AVPlayerView.h#L277
            // toggle to force reloading
            setValue(true, forKey: "canHideControls")
            setValue(false, forKey: "canHideControls")
        }
    }
    var isPlaying: Bool {
        return (player?.rate ?? 0) > 0
    }
    var preferredSpeed: Float = 1 {
        didSet {
            if isPlaying {
                player?.rate = preferredSpeed
            }
        }
    }
    
    // MARK: Views
    private let subtitleView = SubtitleView()
    
    // MARK: Actions
    func play() {
        player?.play()
        player?.rate = preferredSpeed
    }
    
    func pause() {
        player?.pause()
    }
    
    // MARK: Layout
    override func layout() {
        bringSubviewToFront(subtitleView)
        super.layout()
    }

    // MARK: Observers
    private var timeObserver: Any?
    private func addStatusObservers(to player: AVPlayer) {
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: .new, context: nil)
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { time in
            self.subtitleView.text = self.delegate?.playerViewRequestsSubtitle(self, time: time.seconds)
        }
    }

    private func removeStatusObservers(from player: AVPlayer) {
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate), context: nil)
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayer.rate) {
            DispatchQueue.main.async {
                self.delegate?.playerViewPlayingStatusChanged(self, playingStatus: self.isPlaying)
            }
            return
        }
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
}
