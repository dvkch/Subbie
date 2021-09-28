//
//  PlayerView.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import AVKit

protocol PlayerViewDelegate: NSObjectProtocol {
    func playerViewPlayingStatusChanged(_ playerView: PlayerView, playingStatus: Bool)
}

class PlayerView: AVPlayerView {
    
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
        }
    }
    var isPlaying: Bool {
        return (player?.rate ?? 0) > 0
    }

    // MARK: Observers
    private func addStatusObservers(to player: AVPlayer) {
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: .new, context: nil)
    }

    private func removeStatusObservers(from player: AVPlayer) {
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate), context: nil)
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
