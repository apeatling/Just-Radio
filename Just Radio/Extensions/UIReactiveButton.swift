//
//  UIReactiveButton.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-12-16.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation
import UIKit

class UIReactiveButton: UIButton {
    private var animator = UIViewPropertyAnimator()
    private var originalFrame:CGRect!
    
    private let normalColor = UIColor.clear
    private let highlightedColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
    
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
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchDragExit, .touchCancel])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }
    
    @objc private func touchDown() {
        animator.stopAnimation(true)

        self.backgroundColor = self.highlightedColor

        animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut, animations: {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.animator.startAnimation()
        }
    }
    
    @objc private func touchUp() {
        animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut, animations: {
            self.backgroundColor = self.normalColor
            self.transform = .identity
        })
        animator.startAnimation()
    }
}
