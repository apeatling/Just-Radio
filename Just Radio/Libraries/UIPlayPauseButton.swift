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
    func setPlay() {
        self.setImage(UIImage(named: "Play"), for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 0)
    }
    
    func setPause() {
        self.setImage(UIImage(named: "Pause"), for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
