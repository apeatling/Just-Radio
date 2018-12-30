//
//  UIPlayPauseButton.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-12-24.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation
import UIKit

class UIPlayPauseButton: UIReactiveButton {
    var loadingView:NVActivityIndicatorView!
    
    func setPlay() {
        self.hideLoadingView()
        self.setImage(UIImage(named: "Play"), for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 0)
    }
    
    func setPause() {
        self.hideLoadingView()
        self.setImage(UIImage(named: "Pause"), for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func setLoading() {
        self.setPause()
        
//        guard let imageView = self.imageView else { return }
//
//        self.loadingView = NVActivityIndicatorView(frame: CGRect(x: 5, y: 3, width: imageView.frame.width + 15, height: imageView.frame.height + 15), type: .circleStrokeSpin, color: UIColor.init(red: 0.24, green: 0.25, blue: 0.25, alpha: 1), padding: 0)
//
//        self.loadingView.startAnimating()
//        self.loadingView.isHidden = false
//
//        self.setImage(UIImage(), for: .normal)
//        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//
//        self.loadingView.removeFromSuperview()
//        self.addSubview(self.loadingView)
    }
    
    private func hideLoadingView() {
        if let loadingView = self.loadingView {
            loadingView.isHidden = true
            //self.backgroundColor = .clear
        }
    }
}
