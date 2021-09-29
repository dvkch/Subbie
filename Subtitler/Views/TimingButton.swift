//
//  PressButton.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import Cocoa

protocol PressButtonDelegate: NSObjectProtocol {
    func pressButtonBeganPress(_ pressButton: PressButton)
    func pressButtonCanceledPress(_ pressButton: PressButton)
    func pressButtonEndedPress(_ pressButton: PressButton)
}

class PressButton: NSButton {

    // MARK: Init
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        addSubview(tapView)
        tapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let gesture = NSPressGestureRecognizer(target: self, action: #selector(self.gestureRecognizerEvent(_:)))
        gesture.minimumPressDuration = 0
        tapView.addGestureRecognizer(gesture)
    }

    // MARK: Properties
    weak var delegate: PressButtonDelegate?

    // MARK: Views
    private let tapView = NSView()

    // MARK: Actions
    @objc private func gestureRecognizerEvent(_ gesture: NSGestureRecognizer) {
        guard isEnabled else { return }

        switch gesture.state {
        case .began:
            state = .on
            isHighlighted = true
            delegate?.pressButtonBeganPress(self)

        case .ended:
            state = .off
            isHighlighted = false
            
            if bounds.contains(gesture.location(in: self)) {
                delegate?.pressButtonEndedPress(self)
            }
            else {
                delegate?.pressButtonCanceledPress(self)
            }

        default:
            break
        }
    }
}
