//
//  AnimatedImage.swift
//  Kaabii
//
//  Created by Drew Fitzpatrick on 9/6/18.
//  Copyright © 2018 Andrew Fitzpatrick. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreServices
import ImageIO
import UIKit

private class ImageSource {
    let imageSource: CGImageSource
    init?(data: Data) {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: kCFBooleanFalse] as CFDictionary) else {
            return nil
        }
        self.imageSource = imageSource
    }

    func conforms(to type: CFString) -> Bool {
        guard let imageSourceContainerType = CGImageSourceGetType(imageSource) else {
            return false
        }
        return UTTypeConformsTo(imageSourceContainerType, type)
    }

    func properties() -> NSDictionary? {
        return CGImageSourceCopyProperties(imageSource, nil)

    }

    func properties(for type: CFString) -> NSDictionary? {
        return properties()?[type] as? NSDictionary
    }

    var count: Int {
        return CGImageSourceGetCount(imageSource)
    }

    func image(at index: Int) -> UIImage? {
        guard let cgRef = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
            return nil
        }
        return UIImage(cgImage: cgRef)
    }

    func properties(at index: Int) -> NSDictionary? {
        return CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil)
    }

    func property(_ name: CFString, at index: Int) -> Any? {
        return properties(at: index)?[name]
    }
}

extension CGImage {
    var uiImage: UIImage {
        return UIImage(cgImage: self)
    }
}

final class AnimatedImage {

    let posterImage: UIImage?
    let loopCount: UInt

    let duration: Float
    let frames: [CGImage]
    let keyTimes: [NSNumber]

    init?(gifData: Data) {
        guard let imageSource = ImageSource(data: gifData),
            imageSource.conforms(to: kUTTypeGIF),
            let imageProperties = imageSource.properties(for: kCGImagePropertyGIFDictionary) else {
                return nil
        }

        guard let loopCount = imageProperties[kCGImagePropertyGIFLoopCount] as? UInt else {
                return nil
        }
        self.loopCount = loopCount

        let imageCount = imageSource.count
        var delayTimes = [Float]()
        var frames = [CGImage]()

        for index in 0..<imageCount {
            guard let frame = imageSource.image(at: index) else {
                continue
            }

            guard let gifProperties = imageSource.property(kCGImagePropertyGIFDictionary, at: index) as? NSDictionary else {
                continue
            }

            var delayTime: NSNumber?
            delayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber
            if delayTime == nil {
                delayTime = gifProperties[kCGImagePropertyGIFDelayTime] as? NSNumber
            }

            let defaultDelay: Float = 1.0 / 60.0 // default to 60fps for gifs because why not
            if delayTime == nil {
                delayTime = NSNumber(value: delayTimes.last ?? defaultDelay)
            }

            delayTime = NSNumber(value: max(delayTime!.floatValue, defaultDelay))

            delayTimes.append(delayTime!.floatValue)
            frames.append(frame.cgImage!)
        }

        guard delayTimes.isEmpty == false else {
            return nil
        }

        var accumulator: Float = 0.0
        let unscaledKeyTimes = delayTimes.map({ (f) -> Float in
            defer { accumulator = accumulator + f }
            return accumulator
        })
        self.keyTimes = unscaledKeyTimes.map { $0 / accumulator } as [NSNumber]
        self.duration = accumulator
        self.posterImage = frames.lazy.map { UIImage(cgImage: $0) }.first
        self.frames = frames
    }
}
