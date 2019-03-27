//
//  UISpringyButton.swift
//  v1.0
//
//  Created by Andy Peatling
//  https://apeatling.com
//

import Foundation
import UIKit

class UISpringyButton: UIButton {
    private var animator = UIViewPropertyAnimator()
    private var originalFrame:CGRect!
    
    private let normalColor = UIColor.clear
    private let highlightedColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)
    private let animationDelay = 0.2
    private var longPress = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        sharedInit()
    }
    
    func sharedInit() {
        self.originalFrame = self.frame
        addTarget(self, action: #selector(touchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchCancel])
        addTarget(self, action: #selector(dragExit), for: [.touchDragExit])
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
            longPress.cancelsTouchesInView = false
        
        self.addGestureRecognizer(longPress)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        imageView?.contentMode = .center
    }
    
    @objc private func touchDown() {
        self.animator.stopAnimation(true)
        self.depressButton(scaleX: 0.9, scaleY: 0.9)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.animationDelay) {
            self.animator.startAnimation()
        }
    }
    
    @objc private func touchUp() {
        if !self.longPress {
            self.depressButton(scaleX: 0.85, scaleY: 0.85)
            self.animator.startAnimation()
        }
        
        self.releaseButton()
        self.longPress = false
    }
 
    @objc private func dragExit() {
        self.releaseButton()
    }
    
    @objc private func longPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.began {
            self.longPress = true
        }
    }
    
    private func depressButton(scaleX: CGFloat, scaleY: CGFloat) {
        self.animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut, animations: {
            self.backgroundColor = self.highlightedColor
            self.imageView?.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        })
    }
    
    private func releaseButton() {
        self.animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut, animations: {
            self.backgroundColor = self.normalColor
            self.transform = .identity
            self.imageView?.transform = .identity
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.animationDelay) {
            self.animator.startAnimation()
        }
    }
}
