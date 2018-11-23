//
//  StationTableViewCell.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-08.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class StationTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var stationNameLabel: UILabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var stationImageView: UIImageView!
    @IBOutlet weak var stationPlayingStatusView: NVActivityIndicatorView!
    @IBOutlet weak var favButton: UIButton!

    @IBOutlet weak var statusViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    var station:Station!
    var border:CALayer!

    var isCurrentStation = false {
        didSet {
            if isCurrentStation {
                isRadioPlaying ? setPlayingIndicator() : setLoadingIndicator()
                
                NotificationCenter.default.addObserver(self,
                   selector: #selector(playerStateDidChange),
                   name: NSNotification.Name(rawValue: "RadioPlayer.playerStateDidChange"),
                   object: nil
                )
                
                NotificationCenter.default.addObserver(self,
                   selector: #selector(playbackStateDidChange),
                   name: NSNotification.Name(rawValue: "RadioPlayer.playbackStateDidChange"),
                   object: nil
                )
                
            } else {
                hideStatusIndicator()
                NotificationCenter.default.removeObserver(self)
            }
        }
    }
    var hideFavButton = true
    var isRadioPlaying = false
    
    func configure(station: Station) {
        self.station = station
        
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.addBorder()
        
        stationNameLabel.text = station.name
        stationDescLabel.text = station.description

        station.getImage { (image) in
            self.stationImageView.image = image
        }
        stationImageView.layer.cornerRadius = 10
        
        favButton.isHidden = true
        favButton.imageView?.contentMode = .scaleAspectFit
        
        if !hideFavButton {
            favButton.isHidden = false
            station.isFav ? selectFavButton() : deselectFavButton()
        }
    }
    
    @IBAction func favButtonTapped(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        selectFavButton()
        
        let favoriteStationsCaretaker = FavoriteStationsCaretaker()
            favoriteStationsCaretaker.stations?.append(self.station)
        
        try? favoriteStationsCaretaker.save()
    }
    
    func selectFavButton() {
        favButton.setImage(UIImage(named: "Fav On"), for: .normal)
        favButton.layer.opacity = 1
    }
    
    func deselectFavButton() {
        favButton.setImage(UIImage(named: "Fav Off"), for: .normal)
        favButton.layer.opacity = 0.25
    }
    
    func showStatusIndicator() {
        stationPlayingStatusView.isHidden = false
        stationPlayingStatusView.layer.opacity = 1
    }
    
    func hideStatusIndicator() {
        stationPlayingStatusView.isHidden = true
        stationPlayingStatusView.layer.opacity = 0
    }
    
    func setLoadingIndicator() {
        showStatusIndicator()
        
        self.stationPlayingStatusView.stopAnimating()
        
        self.statusViewHeightConstraint.constant = 15
        self.statusViewWidthConstraint.constant = 15
        
        self.stationPlayingStatusView.type = .ballScale
        self.stationPlayingStatusView.color = UIColor.darkGray
        
        self.stationPlayingStatusView.startAnimating()
    }
    
    func setPlayingIndicator() {
        showStatusIndicator()
        
        self.stationPlayingStatusView.stopAnimating()
        
        self.statusViewHeightConstraint.constant = 12
        self.statusViewWidthConstraint.constant = 20
        
        self.stationPlayingStatusView.type = .audioEqualizer
        self.stationPlayingStatusView.color = UIColor.gray
        
        self.stationPlayingStatusView.startAnimating()
    }
    
    func addBorder() {
        self.border = CALayer()
        self.border.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor
        self.border.frame = CGRect(x: 85, y: self.frame.size.height - 0.5, width: self.frame.size.width, height: 0.5)

        self.layer.addSublayer(border)
    }
    
    @objc private func playerStateDidChange(_ notification: Notification) {
        if !isCurrentStation { return }
        
        guard let state = notification.object as? FRadioPlayerState else {
            let object = notification.object as Any
            assertionFailure("Invalid object: \(object)")
            return
        }
        
        if state == .loading {
            setLoadingIndicator()
        }
        
        if state == .readyToPlay {
            setPlayingIndicator()
        }

        if state == .error || state == .urlNotSet {
            hideStatusIndicator()
        }
    }
    
    @objc private func playbackStateDidChange(_ notification: Notification) {
        if !isCurrentStation { return }
        
        guard let state = notification.object as? FRadioPlaybackState else {
            let object = notification.object as Any
            assertionFailure("Invalid object: \(object)")
            return
        }
        
        if state == .paused || state == .stopped {
            hideStatusIndicator()
        }
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        stationNameLabel.text  = nil
        stationDescLabel.text  = nil
        stationImageView.image = nil
        isCurrentStation = false
        stationPlayingStatusView.isHidden = true
        stationPlayingStatusView.layer.opacity = 0
        favButton.layer.opacity = 0.25
        favButton.isHidden = false
        self.border.removeFromSuperlayer()
    }
}
