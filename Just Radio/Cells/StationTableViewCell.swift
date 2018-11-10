//
//  StationTableViewCell.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-08.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation
import UIKit

class StationTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var stationNameLabel: UILabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var stationImageView: UIImageView!
    
    var downloadTask: URLSessionDownloadTask?

    func configure(station: Station) {
        self.backgroundColor = .clear
        
        stationNameLabel.text = station.name
        stationDescLabel.text = station.description

        if let url = URL(string: (station.image as NSString) as String) {
            stationImageView.loadImageWithURL(url: url) { (image) in }
        }
        
        stationImageView.layer.cornerRadius = 10
        
//        } else if imageURL != "" {
//            stationImageView.image = UIImage(named: imageURL as String)
//        } else {
//            stationImageView.image = UIImage(named: "stationImage")
//        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        downloadTask?.cancel()
        downloadTask = nil
        stationNameLabel.text  = nil
        stationDescLabel.text  = nil
        stationImageView.image = nil
    }
}
