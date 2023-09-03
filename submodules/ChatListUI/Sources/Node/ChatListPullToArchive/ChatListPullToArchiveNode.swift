import Foundation
import UIKit
import AsyncDisplayKit
import Display

private let blue = UIColor(rgb: 0x007fff)
private let lightBlue = UIColor(rgb: 0x00affe)
private let grey = UIColor(rgb: 0xb2b7bd)
private let lightGrey = UIColor(rgb: 0xc2c6cc)
private let textFont = Font.with(size: 17.0, design: .regular, weight: .semibold)

final class ChatListPullToArchiveNode: ASDisplayNode, UIScrollViewDelegate {
    
    enum State {
        case inactive
        case active
        case transform
    }
    
    var unarchiveIfNeede: (() -> Void)?
    let activeTriggerHeight: CGFloat = 75.0
    
    var isDragging: Bool = false {
        didSet {
            guard isDragging != oldValue else { return }
            
            didTouchRelease()
        }
    }
    
    private(set) var state: State = .inactive {
        didSet {
            guard state != oldValue else { return }
            
            apply(state: state)
        }
    }
    
    private let elasticLineLayer = ElasticLineView()
    private let inactiveBackgrounLayer = CAGradientLayer()
    private let activeBackgroundLayer = CAGradientLayer()
    private let backgrounMaskLayer = CAShapeLayer()
    private let textInactiveState = CATextLayer()
    private let textActiveState = CATextLayer()
    private let textContainerLayer = CALayer()
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    public override init() {
        super.init()
        
        setupView()
    }
    
    private func setupView() {
        clipsToBounds = true
        layer.masksToBounds = true
        
        setupGradients()
        setupElasticLine()
        setupTextLayer()
    }
    
    private func setupGradients() {
        inactiveBackgrounLayer.colors = [grey.cgColor, lightGrey.cgColor]
        inactiveBackgrounLayer.startPoint = CGPoint(x: .zero, y: 0.5)
        inactiveBackgrounLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        inactiveBackgrounLayer.drawsAsynchronously = true
        
        activeBackgroundLayer.colors = [blue.cgColor, lightBlue.cgColor]
        activeBackgroundLayer.startPoint = CGPoint(x: .zero, y: 0.5)
        activeBackgroundLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        activeBackgroundLayer.drawsAsynchronously = true
        activeBackgroundLayer.mask = backgrounMaskLayer
        
        layer.addSublayer(inactiveBackgrounLayer)
        layer.addSublayer(activeBackgroundLayer)
    }
    
    private func setupElasticLine() {
        view.addSubview(elasticLineLayer)
    }
    
    private func setupTextLayer() {
        textInactiveState.string = "Swipe down for archive"
        textActiveState.string = "Release for archive"
        
        textInactiveState.foregroundColor = UIColor.white.cgColor
        textInactiveState.font = textFont.withSize(17.0)
        textInactiveState.alignmentMode = .center
        textInactiveState.fontSize = 17
        textInactiveState.contentsScale = UIScreen.main.scale
        
        textActiveState.foregroundColor = UIColor.white.cgColor
        textActiveState.font = textFont.withSize(17.0)
        textActiveState.alignmentMode = .center
        textActiveState.fontSize = 17
        textActiveState.contentsScale = UIScreen.main.scale
        textActiveState.opacity = .zero
        
        layer.addSublayer(textContainerLayer)
        textContainerLayer.addSublayer(textInactiveState)
        textContainerLayer.addSublayer(textActiveState)
    }
    
    private func didTouchRelease() {
        guard state == .active else { return }
        
        unarchiveIfNeede?()
        state = .transform
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.state = .inactive
            self.alpha = 1.0
            self.frame = .zero
            self.elasticLineLayer.setupInitialState()
        }
    }
    
    private func apply(state: State) {
        var animTextContainer = layer.convert(layer.bounds, to: textContainerLayer)
        animTextContainer.size.height = textContainerLayer.bounds.height
        Animator.animateText(
            swipeTextLayer: textInactiveState,
            releaseTextLayer: textActiveState,
            state: state,
            containerRect: textContainerLayer.bounds,
            centerPoint: layer.convert(CGPoint(x: bounds.midX, y: bounds.midY), to: textContainerLayer)
        )
        switch state {
        case .active, .inactive:
            inactiveBackgrounLayer.opacity = 1.0
            Animator.animateBackground(for: backgrounMaskLayer, state: state, containerRect: bounds)
        case .transform:
            inactiveBackgrounLayer.opacity = .zero
            backgrounMaskLayer.frame = CGRect(x: 10.0, y: 8.0, width: .zero, height: .zero)
            Animator.animateBackground(for: backgrounMaskLayer, state: state, containerRect: bounds)
            break
        }
        
        elasticLineLayer.apply(state: state)
        
        if isDragging || state == .transform {
            hapticGenerator.impactOccurred()
        }
    }
    
    public func updateFrame(frame: CGRect) {
        let validFrame = CGRect(
            x: frame.minX,
            y: frame.minY,
            width: max(frame.width, .zero),
            height: max(frame.height, .zero)
        )
        
        guard state != .transform else {
            self.frame = CGRect(x: validFrame.minX, y: validFrame.minY, width: validFrame.width, height: self.frame.height)
            updateElasticLineFrame()
            return
        }
        
        guard self.frame != validFrame else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        self.frame = validFrame
        inactiveBackgrounLayer.frame = bounds
        activeBackgroundLayer.frame = inactiveBackgrounLayer.bounds
        
        updateElasticLineFrame()
        backgrounMaskLayer.frame = CGRect(
            x: elasticLineLayer.frame.midX,
            y: elasticLineLayer.frame.maxY - 10.0,
            width: .zero,
            height: .zero
        )
        textContainerLayer.frame = CGRect(
            x: elasticLineLayer.frame.maxX,
            y: elasticLineLayer.frame.maxY - 20.0,
            width: bounds.width,
            height: 20.0
        )
        
        if textInactiveState.frame == .zero {
            textInactiveState.frame = textContainerLayer.bounds
            textActiveState.frame = textContainerLayer.bounds
        }
        
        if elasticLineLayer.bounds.size.height >= activeTriggerHeight && isDragging {
            state = .active
        } else {
            state = .inactive
        }
        
        CATransaction.commit()
    }
    
    private func updateElasticLineFrame() {
        let newFrame = CGRect(
            x: 28.0,
            y: min(bounds.height - 8.0, 8.0),
            width: 22.0,
            height: bounds.height - 16.0
        )
        
        elasticLineLayer.frame = newFrame
        elasticLineLayer.layoutIfNeeded()
    }
    
}
