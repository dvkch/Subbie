//
//  PlayerControlsView.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import Cocoa
import SnapKit

protocol PlayerControlsViewDelegate: NSObjectProtocol {
    func playerControlsView(_ playerControlsView: PlayerControlsView, changedSpeedTo speed: Float)
}

class PlayerControlsView: NSControl {
    
    // MARK: Init
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        speedSegmentedControl.selectedSegment = 1
        speedSegmentedControl.target = self
        addSubview(speedSegmentedControl)
        speedSegmentedControl.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
    }
    
    // MARK: Properties
    weak var delegate: PlayerControlsViewDelegate?
    override var isEnabled: Bool {
        didSet {
            speedSegmentedControl.isEnabled = isEnabled
        }
    }
    var selectedSpeed: Float = 1 {
        didSet {
            delegate?.playerControlsView(self, changedSpeedTo: selectedSpeed)
        }
    }
    
    // MARK: Views
    private let speedSegmentedControl = NSSegmentedControl(labels: ["2x", "1x", "0.5x", "0.25x"], trackingMode: .selectOne, target: nil, action: #selector(speedSegmentedControlChanged))
    
    // MARK: Actions
    @objc private func speedSegmentedControlChanged() {
        let speeds: [Float] = [2, 1, 0.5, 0.25]
        selectedSpeed = speeds[speedSegmentedControl.selectedSegment]
    }
}
