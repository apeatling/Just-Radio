//
//  Track.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-04.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation
import UIKit

struct Track {
    var title: String
    var artist: String
    var artworkImage: UIImage?
    var artworkLoaded = false
    var isStationFallback = false
    
    init(title: String, artist: String, isStationFallback: Bool = false) {
        self.title = title
        self.artist = artist
        self.isStationFallback = isStationFallback
    }
}
