import Foundation
import UIKit
import Lottie

private let blue = UIColor(rgb: 0x007fff)
private let grey = UIColor(rgb: 0xb2b7bd)

extension ChatListPullToArchiveNode {
    
    final class ElasticLineView: UIView {
        
        private enum Constant {
            static let arrowCircleMaskInsets = 3.0
            static let elasticLineOpacity: Float = 0.5
        }
        
        private let arrowCircleAnimView = AnimationView(name: "anim_archive")
        private let elasticLineLayer = CAShapeLayer()
        
        init() {
            super.init(frame: .zero)
            
            setupView()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            updateLauout()
        }
        
        func apply(state: ChatListPullToArchiveNode.State) {
            let arrowCircleInitialTransform: CATransform3D = (arrowCircleAnimView.layer.presentation() ?? arrowCircleAnimView.layer).transform
            let arrowCircleFinalTransform: CATransform3D
            var duration: TimeInterval = 0.2
            
            switch state {
            case .inactive:
                arrowCircleAnimView.setValueProvider(
                    ColorValueProvider(grey.lottieColorValue),
                    keypath: AnimationKeypath(keypath: "Arrow 1.**.Color")
                )
                arrowCircleFinalTransform = CATransform3DMakeRotation(-.pi, .zero, .zero, 1.0)
            case .active:
                arrowCircleAnimView.setValueProvider(
                    ColorValueProvider(blue.lottieColorValue),
                    keypath: AnimationKeypath(keypath: "Arrow 1.**.Color")
                )
                arrowCircleFinalTransform = CATransform3DIdentity
            case .transform:
                let yOffset = frame.height - 43.0
                duration = 0.4
                arrowCircleFinalTransform = CATransform3DMakeTranslation(.zero, -yOffset, 1.0)
                elasticLineLayer.opacity = .zero
                arrowCircleAnimView.play()
            }
            
            let arrowCircleAnim = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.transform))
            arrowCircleAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            arrowCircleAnim.duration = duration
            arrowCircleAnim.fromValue = arrowCircleInitialTransform
            arrowCircleAnim.toValue = arrowCircleFinalTransform
            
            arrowCircleAnimView.layer.transform = arrowCircleFinalTransform
            arrowCircleAnimView.layer.add(arrowCircleAnim, forKey: "arrowCircleLayer\(#keyPath(CAShapeLayer.transform))")
        }
        
        private func setupView() {
            elasticLineLayer.anchorPoint = .zero
            elasticLineLayer.lineCap = .round
            elasticLineLayer.strokeColor = UIColor.white.cgColor
            
            arrowCircleAnimView.setValueProvider(
                ColorValueProvider(UIColor.white.lottieColorValue),
                keypath: AnimationKeypath(keypath: "**.Fill 1.Color")
            )
            
            layer.addSublayer(elasticLineLayer)
            addSubview(arrowCircleAnimView)
            
            setupInitialState()
        }
        
        func setupInitialState() {
            arrowCircleAnimView.setValueProvider(
                ColorValueProvider(grey.lottieColorValue),
                keypath: AnimationKeypath(keypath: "Arrow 1.**.Color")
            )
            
            elasticLineLayer.opacity = Constant.elasticLineOpacity
            arrowCircleAnimView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.6)
            arrowCircleAnimView.layer.transform = CATransform3DMakeRotation(-.pi, .zero, .zero, 1.0)
            arrowCircleAnimView.animationSpeed = 0.9
            arrowCircleAnimView.play(fromFrame: 0.016, toFrame: 0.016)
        }
        
        private func updateLauout() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            let arrowCircleSize = CGSize(width: bounds.width, height: bounds.width)
            let arrowFrame = CGRect(
                origin: CGPoint(
                    x: bounds.midX - arrowCircleSize.width * 0.5,
                    y: bounds.maxY - arrowCircleSize.height
                ),
                size: arrowCircleSize
            )
            
            elasticLineLayer.lineWidth = min(arrowFrame.height, bounds.height)
            
            let stratchLinePath = CGMutablePath()
            stratchLinePath.move(to: CGPoint(x: arrowFrame.midX, y: elasticLineLayer.lineWidth * 0.5))
            stratchLinePath.addLine(to: CGPoint(x: arrowFrame.midX, y: arrowFrame.midY))
            
            elasticLineLayer.path = UIBezierPath(cgPath: stratchLinePath).cgPath
            arrowCircleAnimView.frame = arrowFrame.insetBy(dx: -Constant.arrowCircleMaskInsets, dy: -Constant.arrowCircleMaskInsets)
            
            CATransaction.commit()
        }
        
    }
    
}
