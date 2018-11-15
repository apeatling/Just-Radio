//
//  RadioPlayer.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-04.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import UIKit
import AVFoundation

//*****************************************************************
// RadioPlayerDelegate: Sends FRadioPlayer and Station/Track events
//*****************************************************************

protocol RadioPlayerDelegate: class {
    func playerStateDidChange(_ playerState: FRadioPlayerState)
    func playbackStateDidChange(_ playbackState: FRadioPlaybackState)
    func trackDidUpdate(_ track: Track?)
    func trackArtworkDidUpdate(_ track: Track?)
    
    func portDidChange(portType: AVAudioSession.Port?, portName: String?)
    func rawMetadataDidChange(_ metadata: String?)
}

//*****************************************************************
// RadioPlayer: App Radio Player
//*****************************************************************

class RadioPlayer {
    weak var delegate: RadioPlayerDelegate?
    
    let player = FRadioPlayer.shared
    
    var station: Station? {
        didSet { resetTrack(with: station) }
    }
    
    private(set) var track: Track?
    
    init() {
        player.delegate = self
    }
    
    func resetRadioPlayer() {
        station = nil
        track = nil
        player.radioURL = nil
    }
    
    //*****************************************************************
    // MARK: - Track loading/updates
    //*****************************************************************
    
    // Update the track with an artist name and track name
    func updateTrackMetadata(artistName: String, trackName: String, isStationFallback: Bool = false) {
        if track == nil {
            track = Track(title: trackName, artist: artistName, isStationFallback: isStationFallback)
        } else {
            track?.title = trackName
            track?.artist = artistName
            track?.isStationFallback = isStationFallback
        }
        
        delegate?.trackDidUpdate(track)
    }
    
    // Update the track artwork with a UIImage
    func updateTrackArtwork(with image: UIImage, artworkLoaded: Bool) {
        track?.artworkImage = image
        track?.artworkLoaded = artworkLoaded
        delegate?.trackArtworkDidUpdate(track)
    }
    
    // Reset the track metadata and artwork to use the current station infos
    func resetTrack(with station: Station?) {
        guard let station = station else { track = nil; return }
        updateTrackMetadata(artistName: station.description, trackName: station.name, isStationFallback: true)
        resetArtwork(with: station)
    }
    
    // Reset the track Artwork to current station image
    func resetArtwork(with station: Station?) {
        guard let station = station else { track = nil; return }
        getStationImage(from: station) { image in
            self.updateTrackArtwork(with: image, artworkLoaded: false)
        }
    }
    
    //*****************************************************************
    // MARK: - Private helpers
    //*****************************************************************
    
    private func getStationImage(from station: Station, completionHandler: @escaping (_ image: UIImage) -> ()) {
        
        station.getImage { (image) in
            guard let image = image else { return }
            
            completionHandler(image)
        }
    }
}

extension RadioPlayer: FRadioPlayerDelegate {
    
    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayerState) {
        delegate?.playerStateDidChange(state)
    }
    
    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlaybackState) {
        delegate?.playbackStateDidChange(state)
    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange artistName: String?, trackName: String?) {
        guard
            let artistName = artistName, !artistName.isEmpty,
            let trackName = trackName, !trackName.isEmpty else {
                resetTrack(with: station)
                return
        }
        
        updateTrackMetadata(artistName: artistName, trackName: trackName)
    }
    
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        guard let artworkURL = artworkURL else { resetArtwork(with: station); return }
        
        ImageLoader.sharedLoader.imageForUrl(urlString: artworkURL.absoluteString) { (image, stringURL) in
            guard let image = image else { self.resetArtwork(with: self.station); return }
            self.updateTrackArtwork(with: image, artworkLoaded: true)
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange rawValue: String?) {
        guard let rawValue = rawValue else { return }
        
        delegate?.rawMetadataDidChange(rawValue)
    }
    
    func radioPlayer(_ player: FRadioPlayer, portDidChange portType: AVAudioSession.Port?, portName: String?) {
        guard let portType = portType, let portName = portName else { return }
        
        delegate?.portDidChange(portType: portType, portName: portName)
    }
}
