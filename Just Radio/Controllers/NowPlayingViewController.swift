//
//  NowPlayingViewController.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-04.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//
import UIKit
import MediaPlayer
import AVKit

class NowPlayingViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var airplayButton: UIButton!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var backgroundVisualEffectView: UIVisualEffectView!
    
    // MARK: - Properties
    var fpc: FloatingPanelController!
    var stationsVC: StationsViewController!
    
    let radioPlayer = RadioPlayer()
    var currentStation:Station!
    var currentTrack:Track! {
        didSet {
            currentTrackDidUpdate(previousTrack: oldValue)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fpc = FloatingPanelController()
        fpc.delegate = self
        
        // Initialize FloatingPanelController and add the view
        fpc.surfaceView.backgroundColor = .clear
        fpc.surfaceView.cornerRadius = 9.0
        fpc.surfaceView.shadowHidden = false

        // Set a content view controller.
        stationsVC = storyboard?.instantiateViewController(withIdentifier: "StationsViewController") as? StationsViewController
       
        // Track a scroll view(or the siblings) in the content view controller.
        fpc.set(contentViewController: stationsVC)
        fpc.track(scrollView: stationsVC.tableView)
        
        setupRemoteCommandCenter()
        
        // Add airplay picker
        let routePickerView = AVRoutePickerView(frame: airplayButton.bounds)
            routePickerView.backgroundColor = UIColor.clear
        
        airplayButton.addSubview(routePickerView)
        
        // Detect if there are routes, to show the picker or not.
        let routeDetector = AVRouteDetector()
            routeDetector.isRouteDetectionEnabled = true
        
        print("Routes detected?", routeDetector.multipleRoutesDetected)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fpc.addPanel(toParent: self, animated: true)
        
        stationsVC.searchBar.delegate = self
        stationsVC.delegate = self
        radioPlayer.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove the views managed by the `FloatingPanelController` object from self.view.
        fpc.removePanelFromParent(animated: true)
    }
    
    private func currentTrackDidUpdate(previousTrack: Track?) {
        artistLabel.text = currentTrack.artist
        trackNameLabel.text = currentTrack.title
        
        albumArtImageView.image = currentTrack.artworkImage
        backgroundImageView.image = currentTrack.artworkImage

        updateNowPlayingInfo(artist: currentTrack.artist, title: currentTrack.title, image: currentTrack.artworkImage)
    }
    
    func setupRemoteCommandCenter() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { event in
            return .success
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { event in
            return .success
        }

        // Add handler for Next Command
        commandCenter.nextTrackCommand.addTarget { event in
            return .success
        }

        // Add handler for Previous Command
        commandCenter.previousTrackCommand.addTarget { event in
            return .success
        }
    }
    
    func updateNowPlayingInfo(artist: String, title: String, image: UIImage?) {
        var nowPlayingInfo = [String : Any]()

        if let image = image {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size -> UIImage in
                return image
            })
        }

        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Actions
    @IBAction func tappedPlayButton(_ sender: Any) {
        
    }

    @IBAction func tappedPauseButton(_ sender: Any) {
        
    }
}

extension NowPlayingViewController: StationsViewControllerDelegate {
    func stationsViewController(_ viewController: StationsViewController, didSelectStation station: Station) {
        currentStation = station
        
        trackNameLabel.text = currentStation.name
        artistLabel.text = currentStation.description

        currentStation.getImage { (image) in
            self.albumArtImageView.image = image
            self.backgroundImageView.image = image
        }
        albumArtImageView.layer.cornerRadius = 24
        
        radioPlayer.station = currentStation
        radioPlayer.player.radioURL = URL(string: currentStation.url)
        radioPlayer.player.play()
    }
    
    func stationsViewController(_ viewController: StationsViewController, didFavStation station: Station) {
        
    }
    
    func stationsViewController(_ viewController: StationsViewController, didUnFavStation station: Station) {
        
    }
}

extension NowPlayingViewController: RadioPlayerDelegate {
    func playerStateDidChange(_ playerState: FRadioPlayerState) {
        switch playerState {
        case .loading:
            print( "playerStateDidChange: LOADING" )
            break
            
        case .loadingFinished:
            print( "playerStateDidChange: LOADING FINISHED" )
            break
            
        case .readyToPlay:
            print( "playerStateDidChange: READY TO PLAY" )
            playPauseButton.setImage(UIImage(named: "Pause"), for: .normal)
            break
            
        case .urlNotSet:
            print( "playerStateDidChange: URL NOT SET" )
            break
            
        case .error:
            print( "playerStateDidChange: RADIO PLAYER ERROR" )
            break
            
        default:
            break
        }
    }
    
    func playbackStateDidChange(_ playbackState: FRadioPlaybackState) {
        switch playbackState {
        case .paused:
            print( "playbackStateDidChange: PAUSED" )
            playPauseButton.setImage(UIImage(named: "Play"), for: .normal)
            break
            
        case .playing:
            print( "playbackStateDidChange: PLAYING" )
            break
            
        case .stopped:
            print( "playbackStateDidChange: STOPPED" )
            playPauseButton.setImage(UIImage(named: "Play"), for: .normal)
            break
            
        default:
            break
        }
    }
    
    func trackDidUpdate(_ track: Track?) {
        guard let track = track else { return }
        currentTrack = track
    }
    
    func trackArtworkDidUpdate(_ track: Track?) {
        guard let track = track else { return }
        currentTrack = track
    }
    
    func rawMetadataDidChange(_ metadata: String?) {
        guard let metadata = metadata else { return }
    }
}

extension NowPlayingViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton  = false
        fpc.move(to: .half, animated: true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        stationsVC.tableView.alpha = 1.0
        fpc.move(to: .full, animated: true)
    }
}

extension NowPlayingViewController: FloatingPanelControllerDelegate {
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return NowPlayingFloatingPanelLayout()
    }
    
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.position == .full {
            stationsVC.searchBar.showsCancelButton = false
            stationsVC.searchBar.resignFirstResponder()
        }
    }
}

class NowPlayingFloatingPanelLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .half
    }
    
    var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .half]
    }
    
    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0 // A top inset from safe area
        case .half: return 245.0 // A bottom inset from the safe area
        case .tip: return 0 // A bottom inset from the safe area
        }
    }
}
