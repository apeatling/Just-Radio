//
//  UIView+AddBorder.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-22.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    enum borderLocations {
        case top, right, bottom, left
    }
    
    private func addTopBorder(color: UIColor, width: CGFloat) {
        let border = CALayer()
            border.backgroundColor = color.cgColor
            border.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: width)
        
        self.layer.addSublayer(border)
    }
    
    private func addRightBorder(color: UIColor, width: CGFloat) {
        let border = CALayer()
            border.backgroundColor = color.cgColor
            border.frame = CGRect(x: self.frame.size.width - width, y: 0, width: width, height: self.frame.size.height)
        
        self.layer.addSublayer(border)
    }
    
    private func addBottomBorder(color: UIColor, width: CGFloat) {
        let border = CALayer()
            border.backgroundColor = color.cgColor
            border.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: width)
        
        self.layer.addSublayer(border)
    }
    
    private func addLeftBorder(color: UIColor, width: CGFloat) {
        let border = CALayer()
            border.backgroundColor = color.cgColor
            border.frame = CGRect(x: 0, y: 0, width: width, height: self.frame.size.height)
        
        self.layer.addSublayer(border)
    }
    
    func addBorder(_ locations: [borderLocations], color: UIColor, width: CGFloat) {
        for location in locations {
            switch location {
            case .top:
                addTopBorder(color: color, width: width)
                break
            case .right:
                addRightBorder(color: color, width: width)
                break
            case .bottom:
                addBottomBorder(color: color, width: width)
                break
            case .left:
                addBottomBorder(color: color, width: width)
                break
            }
        }
    }
}
