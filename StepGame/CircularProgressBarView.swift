//
//  CircularProgressBarView.swift
//  StepGame
//
//  Created by Tyler Eaden on 10/24/24.
//

import Foundation
import UIKit

// Code Source Citation: https://ruslandzhafarov.medium.com/circular-progress-bar-with-uikit-on-ios-5ced613850ef
final class CircularProgressBarView: UIView {

    // MARK: - Constants

    private struct Appearance {
        static let lineWidth: CGFloat = 10.0
        static let backgroundColor = UIColor.gray
        static let progressColor = UIColor.systemBlue
    }

    // MARK: - Layers

    private lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = Appearance.lineWidth
        layer.lineCap = .round
        layer.strokeStart = 0
        layer.strokeEnd = 0
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = Appearance.progressColor.cgColor

        return layer
    }()

    private lazy var backgroundLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = Appearance.lineWidth
        layer.lineCap = .round
        layer.strokeStart = 0
        layer.strokeEnd = 1
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = Appearance.backgroundColor.cgColor

        return layer
    }()

    // MARK: - Lifecycle
    
    init() {
        super.init(frame: .zero)
        loadLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func loadLayout() {
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: (bounds.width - Appearance.lineWidth) / 2,
            startAngle: -CGFloat.pi / 2,
            endAngle: CGFloat.pi * 3 / 2,
            clockwise: true
        ).cgPath

        backgroundLayer.path = circlePath
        progressLayer.path = circlePath
    }

    // MARK: - Public

    func setProgress(_ progress: CGFloat, animated: Bool) {
        // Ensure progress is between 0 and 1
        let clampedProgress = max(min(progress, 1), 0)

        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = clampedProgress
            animation.duration = 0.5
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            progressLayer.removeAnimation(forKey: "progress")
            progressLayer.add(animation, forKey: "progress")
        }

        progressLayer.strokeEnd = clampedProgress
    }
}
