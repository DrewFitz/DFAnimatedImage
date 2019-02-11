//
//  AnimatedImageView.swift
//  Kaabii
//
//  Created by Drew Fitzpatrick on 9/11/18.
//  Copyright © 2018 Andrew Fitzpatrick. All rights reserved.
//

import UIKit

class AnimatedImageView: UIImageView {

    /// The key for our layer's keyframe animation
    static let animationKey = "com.drewfitz.AnimatedImageView.AnimationKey"

    /// Used to signify to that the animation should be restarted in cases where
    /// it may have been interrupted.
    private var wantsAnimation: Bool = false

    /// The animated image displayed in the image view.
    var animatedImage: AnimatedImage? {
        didSet {
            if isAnimating, animatedImage !== oldValue {
                // image changed so we need to reload or stop
                if animatedImage == nil {
                    stopAnimating()
                } else {
                    reloadAnimation()
                }
            }
        }
    }

    // MARK: - Overrides

    override var accessibilityIgnoresInvertColors: Bool {
        get {
            return true
        }
        set {}
    }

    override func startAnimating() {
        guard self.animatedImage != nil else {
            super.startAnimating()
            return
        }

        wantsAnimation = true
        beginAnimation()

        NotificationCenter.default.addObserver(self, selector: #selector(beginAnimation), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(endAnimation), name: UIApplication.willResignActiveNotification, object: nil)
    }

    override var isAnimating: Bool {
        if layer.animation(forKey: AnimatedImageView.animationKey) != nil {
            return true
        } else {
            return super.isAnimating
        }
    }

    override func stopAnimating() {
        wantsAnimation = false
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)

        if  self.animatedImage != nil {
            endAnimation()
        } else {
            super.stopAnimating()
        }
    }

    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            // highlighting goofs up our whole situation
            if animatedImage == nil {
                super.isHighlighted = newValue
            } else {
                super.isHighlighted = false
            }
        }
    }

    // MARK: - Private animation management utilities

    /// Check if we want to animated, have something to animate, and are visible
    private var shouldAnimate: Bool {
        return wantsAnimation       // We want to animate
            && animatedImage != nil // We have an image to animate
            && isHidden == false    // We are visisble
            && alpha > 0            // For real
            && window != nil        // For really real
    }

    /// Check if we should animate and, if so, start animating again
    private func restartAnimationIfNeeded() {
        if shouldAnimate {
            startAnimating()
        }
    }

    /// DO NOT CALL THESE DIRECTLY
    /// THEY SHOULD ONLY BE CALLED IN START AND STOP ANIMATING
    @objc private func beginAnimation() {
        if shouldAnimate, let animatedImage = self.animatedImage {
            let keyframeAnimation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.contents))
            keyframeAnimation.values = animatedImage.frames
            keyframeAnimation.keyTimes = animatedImage.keyTimes
            keyframeAnimation.duration = Double(animatedImage.duration)

            let loops = animatedImage.loopCount == 0 ? .greatestFiniteMagnitude : Float(animatedImage.loopCount)
            keyframeAnimation.repeatCount = loops
            keyframeAnimation.calculationMode = .discrete

            layer.add(keyframeAnimation, forKey: AnimatedImageView.animationKey)
        }
    }

    /// DO NOT CALL THESE DIRECTLY
    /// THEY SHOULD ONLY BE CALLED IN START AND STOP ANIMATING
    @objc private func endAnimation() {
        layer.removeAnimation(forKey: AnimatedImageView.animationKey)

        if let contents = layer.presentation()?.contents {
            image = UIImage(cgImage: contents as! CGImage)
        }
    }

    private func reloadAnimation() {
        endAnimation()
        beginAnimation()
    }

    // MARK: - Keep on animating

    override func didMoveToWindow() {
        super.didMoveToWindow()
        restartAnimationIfNeeded()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        restartAnimationIfNeeded()
    }

    override var isHidden: Bool {
        didSet {
            restartAnimationIfNeeded()
        }
    }

    override var alpha: CGFloat {
        didSet {
            restartAnimationIfNeeded()
        }
    }
}
