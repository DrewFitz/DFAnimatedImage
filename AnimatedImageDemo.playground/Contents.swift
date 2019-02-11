import UIKit
import PlaygroundSupport

var str = "Hello, playground"

let gifURL = Bundle.main.url(forResource: "DaftPunkLove", withExtension: "gif")!
let gifData = try! Data(contentsOf: gifURL)

let image = AnimatedImage(gifData: gifData)
let view = AnimatedImageView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))

view.animatedImage = image
view.startAnimating()

PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = view

