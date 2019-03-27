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

protocol StationTableViewCellDelegate: class {
    func StationTableViewCell(_ cell: StationTableViewCell, didFavStation station: Station)
    func StationTableViewCell(_ cell: StationTableViewCell, didUnFavStation station: Station)
}

class StationTableViewCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var stationNameLabel: UILabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var stationImageView: UIImageView!
    @IBOutlet weak var stationPlayingStatusView: UIView!
    @IBOutlet weak var favButton: UISpringyButton!

    @IBOutlet weak var statusViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    var delegate: StationTableViewCellDelegate?
    var station:Station!
    var border:CALayer!
    var favoriteStationsCaretaker: FavoriteStationsCaretaker!

    var isCurrentStation = false {
        didSet {
            if isCurrentStation {
                if isRadioPlaying { setPlayingIndicator() }
                
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
    var showFavButton = false
    var isRadioPlaying = false
    
    func configure(stationForCell: Station, radioPlayer: RadioPlayer, currentStation: Station?, favoriteStationsCaretaker: FavoriteStationsCaretaker, showBorder: Bool) {
        
        self.favoriteStationsCaretaker = favoriteStationsCaretaker
        self.station = stationForCell
        self.isRadioPlaying = radioPlayer.fplayer.isPlaying
        
        self.selectionStyle = .none
        self.backgroundColor = .clear
        
        if showBorder {
            self.addBorder()
        }
        
        stationNameLabel.text = station.name
        stationDescLabel.text = station.description

        station.getImage { (image) in
            self.stationImageView.image = image
        }
        stationImageView.layer.cornerRadius = 10
        
        favButton.imageView?.contentMode = .scaleAspectFit
        
        if let favStations = favoriteStationsCaretaker.stations {
            ( favStations.contains(self.station) ) ? selectFavButton() : deselectFavButton()
        }
        
        if let currentStation = currentStation {
            if currentStation == self.station {
                self.isCurrentStation = true
            }
        }
    }
    
    @IBAction func favButtonTapped(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        if let favStations = favoriteStationsCaretaker.stations {
            if favStations.contains(self.station) {
                StationHelper.unfav(station, favoriteStationsCaretaker: favoriteStationsCaretaker)
                
                delegate?.StationTableViewCell(self, didUnFavStation: self.station)
                deselectFavButton()
            } else {
                StationHelper.fav(station, favoriteStationsCaretaker: favoriteStationsCaretaker)
                
                delegate?.StationTableViewCell(self, didFavStation: self.station)
                selectFavButton()
            }
            
            favoriteStationsCaretaker.reload()
        }
    }
    
    func selectFavButton() {
        favButton.setImage(UIImage(named: "Fav On"), for: .normal)
        favButton.layer.opacity = 1
    }
    
    func deselectFavButton() {
        favButton.setImage(UIImage(named: "Fav Off"), for: .normal)
        favButton.layer.opacity = 0.3
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
        
        let frame = CGRect(x: 2, y: 0, width: self.stationPlayingStatusView.bounds.width, height: self.stationPlayingStatusView.bounds.height)
        let loadingIndicator = NVActivityIndicatorView(frame: frame, type: .ballScale, color: UIColor.darkGray, padding: 0)
        
        self.stationPlayingStatusView.subviews.forEach { $0.removeFromSuperview() }
        self.stationPlayingStatusView.addSubview(loadingIndicator)

        loadingIndicator.startAnimating()
    }
    
    func setPlayingIndicator() {
        showStatusIndicator()
        
        let frame = CGRect(x: 5, y: 0, width: self.stationPlayingStatusView.bounds.width, height: self.stationPlayingStatusView.bounds.height)
        let playingIndicator = NVActivityIndicatorView(frame: frame, type: .audioEqualizer, color: UIColor.gray, padding: 1)
        
        self.stationPlayingStatusView.subviews.forEach { $0.removeFromSuperview() }
        self.stationPlayingStatusView.addSubview(playingIndicator)

        playingIndicator.startAnimating()
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
        
        if state == .playing {
            setPlayingIndicator()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        stationNameLabel.text  = nil
        stationDescLabel.text  = nil
        stationImageView.image = nil
        isCurrentStation = false
        
        if let border = self.border {
            border.removeFromSuperlayer()
        }
    }
}
