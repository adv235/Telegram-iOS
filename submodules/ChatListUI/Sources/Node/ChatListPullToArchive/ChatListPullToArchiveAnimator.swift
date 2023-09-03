import Foundation
import UIKit

extension ChatListPullToArchiveNode {
    
    struct Animator {
        
        static func animateBackground(for layer: CAShapeLayer, state: State, containerRect: CGRect) {
            let fromValue = layer.presentation()?.path ?? CGPath(ellipseIn: .zero, transform: .none)
            let toValue: CGPath
            
            switch state {
            case .inactive:
                toValue = CGPath(ellipseIn: .zero, transform: .none)
            case .active:
                let pathRectSize = CGSize(width: max(containerRect.width, containerRect.height) * 3.0, height: max(containerRect.width, containerRect.height) * 3.0)
                let pathRectOrigin = CGPoint(x: -pathRectSize.width * 0.5, y: -pathRectSize.height * 0.5)
                
                toValue = CGPath(ellipseIn: CGRect(origin: pathRectOrigin, size: pathRectSize), transform: .none)
            case .transform:
                toValue = CGPath(ellipseIn: CGRect(x: .zero, y: .zero, width: 60.0, height: 60.0), transform: nil)
            }
            
            let anim = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            anim.fromValue = fromValue
            anim.toValue = toValue
            anim.duration = state == .transform ? 0.5 : 0.3
            
            layer.path = toValue
            layer.add(anim, forKey: "animateBackground_\(#keyPath(CAShapeLayer.path))")
        }
        
        static func animateText(
            swipeTextLayer: CATextLayer,
            releaseTextLayer: CATextLayer,
            state: State,
            containerRect: CGRect,
            centerPoint: CGPoint
        ) {
            let swipeTextToValue: (opacity: Float, position: CGPoint)
            let releaseTextToValue: (opacity: Float, position: CGPoint)
            
            switch state {
            case .inactive:
                swipeTextToValue = (
                    opacity: 1.0,
                    position: CGPoint(x: centerPoint.x, y: containerRect.midY)
                )
                releaseTextToValue = (
                    opacity: .zero,
                    position: CGPoint(x: containerRect.minX, y: containerRect.midY)
                )
            case .active:
                swipeTextToValue = (
                    opacity: .zero,
                    position: CGPoint(x: containerRect.maxX, y: containerRect.midY)
                )
                releaseTextToValue = (
                    opacity: 1.0,
                    position: CGPoint(x: centerPoint.x, y: containerRect.midY)
                )
            case .transform:
                releaseTextToValue = (
                    opacity: .zero,
                    position: CGPoint(x: centerPoint.x, y: containerRect.midY)
                )
                swipeTextToValue = (
                    opacity: .zero,
                    position: CGPoint(x: containerRect.maxX, y: containerRect.midY)
                )
            }
            
            let animations = [swipeTextLayer: swipeTextToValue, releaseTextLayer: releaseTextToValue].map {
                let layerPresentation = $0.key.presentation()
                let positionAnim = CASpringAnimation(keyPath: #keyPath(CATextLayer.position))
                positionAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
                positionAnim.duration = 1.0
                positionAnim.fromValue = layerPresentation?.position ?? $0.key.position
                positionAnim.toValue = $0.value.position
                positionAnim.stiffness = .zero
                positionAnim.damping = 15
                
                let opacityAnim = CABasicAnimation(keyPath: #keyPath(CATextLayer.opacity))
                opacityAnim.duration = 0.15
                opacityAnim.fromValue = layerPresentation?.opacity ?? $0.key.opacity
                opacityAnim.toValue = $0.value.opacity
                
                return [$0.key: [positionAnim, opacityAnim]]
            }.flatMap { $0 }
            
            swipeTextLayer.position = swipeTextToValue.position
            releaseTextLayer.position = releaseTextToValue.position
            
            swipeTextLayer.opacity = swipeTextToValue.opacity
            releaseTextLayer.opacity = releaseTextToValue.opacity
            
            animations.forEach { (layer, animatins) in
                let group = CAAnimationGroup()
                group.duration = 1.0
                group.animations = animatins
                layer.add(group, forKey: "animateText_\(layer.hashValue)")
            }
        }
    }
    
}
