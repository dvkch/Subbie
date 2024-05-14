//
//  SpectralView.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 10/10/2021.
//

import Cocoa
import AVFAudio
import AVFoundation

// TODO: finish work on spectral audio view
// https://betterprogramming.pub/audio-visualization-in-swift-using-metal-accelerate-part-1-390965c095d7
class SpectralView: NSView {

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
        /*
        _ = engine.mainMixerNode
        engine.prepare()

        do {
            try engine.start()
        } catch {
            print(error)
        }
        
        //now we need to create our player node
        let player = AVAudioPlayerNode()
        
        do {
            //player nodes have a few ways to play-back music, the easiest way is from an AVAudioFile
            let audioFile = try AVAudioFile(forReading: url)
            
            //audio always has a format, lets keep track of what the format is as an AVAudioFormat
            let format = audioFile.processingFormat
            print(format)
            
            //we now need to connect add the node to our engine. This part is a little weird but we first need
            //to attach it to the engine itself before connecting it to the mainMixerNode. Recall that the
            //mainMixerNode connects to the default outputNode, so now we'll have a complete playback path from
            //our file to the outputNode!
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            
            //let's play the file!
            //note: player must be attached first before scheduling a file to play
            player.scheduleFile(audioFile, at: nil, completionHandler: nil)
        } catch let error {
            print(error.localizedDescription)
        }
        
        //tap it to get the buffer data at playtime
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { (buffer, time) in

        }
        
        //start playing the music!
        player.play()
         */
    }

    // MARK: Properties
    private let engine = AVAudioEngine()
    
    // MARK: Content
    /*
    func load(url: URL) {
        let node = AVAudioPlayerNode()
        node.
        engine.attach()
    }
    
    func
     */
}
