//
//  FRadioPlayer+getCurrentRoute.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-12-22.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation
import AVKit

extension FRadioPlayer {
    func getCurrentRoute() -> (portType: AVAudioSession.Port, portName: String)? {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            return (output.portType, output.portName)
        }
        
        return nil
    }
}
