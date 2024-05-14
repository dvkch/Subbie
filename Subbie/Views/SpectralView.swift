//
//  SpectralView.swift
//  Subbie
//
//  Created by Stanislas Chevallier on 10/10/2021.
//

import Cocoa
import AVFAudio
import AVFoundation
import SwiftUI
import DSWaveformImage
import DSWaveformImageViews
import SnapKit

// https://github.com/dmrschmidt/DSWaveformImage
// https://betterprogramming.pub/audio-visualization-in-swift-using-metal-accelerate-part-1-390965c095d7
// https://stackoverflow.com/a/46431542/1439489
protocol SpectralViewDelegate: NSObjectProtocol {
    func spectralView(_ spectralView: SpectralView, selectedPosition position: TimeInterval)
}

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
        scrollView.backgroundColor = .windowBackgroundColor
        scrollView.borderType = .noBorder
        scrollView.hasHorizontalScroller = true
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.contentView = clipView
        clipView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
        }
        
        scrollView.documentView = documentView
        documentView.snp.makeConstraints { make in
            make.top.left.bottom.equalTo(scrollView)
        }

        progressView.wantsLayer = true
        progressView.layer?.backgroundColor = NSColor.systemYellow.cgColor
        progressView.layer?.compositingFilter = "subtractBlendMode" // darkenBlendMode and multiplyBlendMode also look nice
        progressView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(progressView)
    }
    
    // MARK: Properties
    weak var delegate: SpectralViewDelegate?
    struct Source: Equatable {
        let url: URL
        let duration: TimeInterval
    }
    var source: Source? {
        didSet {
            guard source != oldValue else { return }
            updateContent()
            position = 0
        }
    }
    private let resolutionMSecPerPoint: Double = 20
    var position: TimeInterval = 0 {
        didSet {
            updateProgress()
        }
    }
    
    // MARK: Views
    private let scrollView = NSScrollView()
    private let clipView = NSClipView()
    private let documentView = NSView()
    private let progressView = NSView()
    private var waveformView: WaveformView<AnyView>?
    private var hostingView: NSHostingView<WaveformView<AnyView>>?
    
    // MARK: Content
    private func updateContent() {
        hostingView?.removeFromSuperview()
        hostingView = nil
        waveformView = nil
        
        guard let source else { return }
        
        let waveformView = WaveformView(audioURL: source.url, configuration: .init(style: .filled(.white)), renderer: LinearWaveformRenderer())
        let hostingView = NSHostingView(rootView: waveformView)
        hostingView.frame = .init(x: 0, y: 0, width: 100, height: 100)
        documentView.addSubview(hostingView, positioned: .below, relativeTo: progressView)
        hostingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.waveformView = waveformView
        self.hostingView = hostingView
        
        needsLayout = true
        needsUpdateConstraints = true
    }
    
    private func updateProgress() {
        guard let duration = source?.duration, let hostingView else { return }
        let percent = (position / duration)
        progressView.frame = .init(x: 0, y: 0, width: hostingView.bounds.width * percent, height: hostingView.bounds.height)
        ensureCursorIsVisible()
    }
    
    private func ensureCursorIsVisible() {
        let progressCursor = CGPoint(x: progressView.bounds.maxX, y: 0)
        let cursorIsVisible = scrollView.documentVisibleRect.contains(progressCursor)
        if !cursorIsVisible && !isDragging {
            scrollView.documentOffset.x = max(0, progressCursor.x - 20)
        }
    }
    
    // MARK: Actions
    private var isDragging: Bool = false
    override func mouseDragged(with event: NSEvent) {
        isDragging = true
        if updatePosition(from: event, final: false) {
            return
        }
        super.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        if updatePosition(from: event, final: true) {
            return
        }
        super.mouseUp(with: event)
    }
    
    private func updatePosition(from event: NSEvent, final: Bool) -> Bool {
        guard let source, let hostingView else { return false }
        let waveformX = hostingView.convert(event.locationInWindow, from: window?.contentView).x
        let correspondingTime = min(source.duration, max(0, waveformX * source.duration / hostingView.bounds.width))
        delegate?.spectralView(self, selectedPosition: correspondingTime)
        
        if final {
            ensureCursorIsVisible()
        }

        return true
    }
    
    // MARK: Layout
    private var prevSize: CGSize = .zero
    override func layout() {
        super.layout()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(.init(rect: bounds, options: [.activeInKeyWindow, .inVisibleRect, .enabledDuringMouseDrag, .mouseEnteredAndExited, .mouseMoved], owner: self))
        
        if prevSize != bounds.size {
            prevSize = bounds.size
            needsUpdateConstraints = true
        }
    }
    
    override func updateConstraints() {
        super.updateConstraints()

        guard let duration = source?.duration else {
            documentView.snp.removeConstraints()
            return
        }
        
        let preferredWidth = duration * 1000 / resolutionMSecPerPoint
        let width = max(bounds.width, preferredWidth)
        documentView.snp.remakeConstraints { make in
            make.height.equalToSuperview()
            make.width.equalTo(width)
        }
    }
}
