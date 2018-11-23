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
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var airplayStackView: UIStackView!
    @IBOutlet weak var airplayButton: UIButton!
    @IBOutlet weak var airplayLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var backgroundVisualEffectView: UIVisualEffectView!
    
    // MARK: - Constraint Outlets
    @IBOutlet weak var albumArtHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumArtWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumArtBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var trackNameTopConstraint: NSLayoutConstraint!
    
    // MARK: - Injected Dependencies
    var radioPlayer:RadioPlayer!
    
    // MARK: - Properties
    var fpc: FloatingPanelController!
    var stationsVC: StationsViewController!
    var currentStation:Station!
    var currentTrack:Track!
    var isShowingTrackLabel = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        stationsVC = storyboard?.instantiateViewController(withIdentifier: "StationsViewController") as? StationsViewController
        stationsVC.radioPlayer = self.radioPlayer
        
        setCurrentStation(station: nil)
 
        fpc = FloatingPanelController()
        fpc.delegate = self
        fpc.surfaceView.backgroundColor = .clear
        fpc.surfaceView.cornerRadius = 9.0
        fpc.surfaceView.shadowHidden = false
        fpc.set(contentViewController: stationsVC)
        fpc.track(scrollView: stationsVC.tableView)

        albumArtImageView.layer.cornerRadius = 10
        albumArtImageView.clipsToBounds = true

        setupRemoteCommandCenter()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fpc.addPanel(toParent: self, animated: false)
        radioPlayer.delegate = self
        
        stationsVC.searchBar.delegate = self
        stationsVC.delegate = self
        
        getActiveAirplayDevice()
        setupAirplayPicker()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove the views managed by the `FloatingPanelController` object from self.view.
        fpc.removePanelFromParent(animated: true)
    }
    
    private func setCurrentStation(station: Station?) {
        let lastPlayedStationCaretaker = LastPlayedStationCaretaker()
        
        if station == nil {
            guard let lastPlayedStation = lastPlayedStationCaretaker.station else { return }
            currentStation = lastPlayedStation
        } else {
            currentStation = station
            
            lastPlayedStationCaretaker.station = station
            try? lastPlayedStationCaretaker.save()
        }

        stationsVC.currentStation = currentStation
        radioPlayer.station = currentStation
        radioPlayer.fplayer.radioURL = URL(string: currentStation.url)
    }
    
    private func setCurrentTrack(track: Track) {
        currentTrack = track

        let fullTrackTitle = currentTrack.artist.capitalized + " — " + currentTrack.title.capitalized
        let attributedString = NSMutableAttributedString(string: fullTrackTitle,
                                                         attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)])
        
        let boldFontAttribute = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 22)]
        let boldRange = (fullTrackTitle as NSString).range(of: currentTrack.artist.capitalized)
        attributedString.addAttributes(boldFontAttribute, range: boldRange)
        
        let colorAttribute = [NSAttributedString.Key.foregroundColor: UIColor.black.withAlphaComponent(0.75)]
        let colorRange = (fullTrackTitle as NSString).range(of: " — " + currentTrack.title.capitalized)
        attributedString.addAttributes(colorAttribute, range: colorRange)
        
        trackNameLabel.attributedText = attributedString
        
        UIView.transition(with: albumArtImageView,
                          duration: 0.17,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.albumArtImageView.image = self.currentTrack.artworkImage
                          },
                          completion: nil)

        UIView.transition(with: backgroundImageView,
                          duration: 0.17,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.backgroundImageView.image = self.currentTrack.artworkImage
                          },
                          completion: nil)
        
        (currentTrack.isStationFallback) ? hideTrackLabel() : showTrackLabel()
        
        // Set colors
        //        albumArtImageView.image?.getColors(quality: .low, { (colors) in
        //            self.artistLabel.textColor = colors.primary
        //        })
        
        updateNowPlayingInfo(artist: currentTrack.artist, title: currentTrack.title, image: currentTrack.artworkImage)
    }

    func setupRemoteCommandCenter() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { event in
            self.radioPlayer.fplayer.play()
            return .success
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { event in
            self.radioPlayer.fplayer.stop()
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
    
    func getActiveAirplayDevice() {
        guard let activeRoute = radioPlayer.fplayer.getCurrentRoute() else { return }
        self.portDidChange(portType: activeRoute.portType, portName: activeRoute.portName)
    }
    
    func setupAirplayPicker() {
        self.airplayStackView.isHidden = false

// TURNED OFF - API DOES NOT SEEM RELIABLE
//        let routeDetector = AVRouteDetector()
//            routeDetector.isRouteDetectionEnabled = true
//
//        if !routeDetector.multipleRoutesDetected {
//            print( "NO AIRPLAY ROUTES: HIDE PICKER" )
//            self.airplayStackView.isHidden = true
//        }

        // Add airplay picker to button
        self.airplayStackView.subviews.forEach({ if $0 is AVRoutePickerView { $0.removeFromSuperview() } })
        self.airplayStackView.autoresizesSubviews = true
        
        let routePickerView = AVRoutePickerView(frame: self.airplayStackView.bounds)
            routePickerView.tintColor = .clear
            routePickerView.activeTintColor = .clear
            routePickerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.airplayStackView.addSubview(routePickerView)
    }
    
    func showTrackLabel() {
        if isShowingTrackLabel { return }
        if currentTrack.artist == currentTrack.title { return }
        
        isShowingTrackLabel = true
        toggleTrackLabel(shouldShow: true, distanceToMove: 42, delay: 0.15)
    }

    func hideTrackLabel() {
        if !isShowingTrackLabel { return }
        
        isShowingTrackLabel = false
        toggleTrackLabel(shouldShow: false, distanceToMove: -42)
    }

    func toggleTrackLabel(shouldShow: Bool, distanceToMove: CGFloat, delay: Double = 0) {
        let distanceToMove:CGFloat = distanceToMove
        self.albumArtHeightConstraint.constant = self.albumArtHeightConstraint.constant - distanceToMove
        self.albumArtWidthConstraint.constant = self.albumArtWidthConstraint.constant - distanceToMove
        self.albumArtBottomSpaceConstraint.constant = self.albumArtBottomSpaceConstraint.constant + distanceToMove
        self.trackNameTopConstraint.constant = self.trackNameTopConstraint.constant + distanceToMove
        
        if shouldShow {
            self.trackNameLabel.isHidden = false
        } else {
            self.trackNameLabel.isHidden = true
            self.trackNameLabel.layer.opacity = 0
        }
        
        UIView.animate(withDuration: 0.6,
                       delay: delay,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.7,
                       options: [.curveEaseInOut],
                       animations: {
                        if shouldShow { self.trackNameLabel.layer.opacity = 1 }
                        self.view.layoutIfNeeded()
        }) { (complete) in }
    }
    
    // MARK: - Actions
    @IBAction func tappedPlayPauseButton(_ sender: Any) {
        if radioPlayer.fplayer.isPlaying {
            radioPlayer.fplayer.stop()
        } else {
            radioPlayer.fplayer.play()
        }
    }
}

extension NowPlayingViewController: StationsViewControllerDelegate {
    func stationsViewController(_ viewController: StationsViewController, didSelectStation station: Station, isFavStation: Bool) {
        currentStation = nil
        
        if isFavStation {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.fpc.move(to: .half, animated: true)
            }
        }
        
        setCurrentStation(station: station)
        radioPlayer.fplayer.play()
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
        setCurrentTrack(track: track)
    }
    
    func trackArtworkDidUpdate(_ track: Track?) {
        guard let track = track else { return }
        setCurrentTrack(track: track)
    }
    
    func portDidChange(portType: AVAudioSession.Port?, portName: String?) {
        guard let portType = portType, let portName = portName else { return }
        
        DispatchQueue.main.async {
            switch portType.rawValue {
            case "Speaker":
                self.airplayLabel.text = ""
                break
            case "AirPlay":
                self.airplayLabel.text = UIDevice.current.model + " → " + portName
                break
            default:
                self.airplayLabel.text = portName
                break
            }

            self.setupAirplayPicker()
        }
    }
    
    func rawMetadataDidChange(_ metadata: String?) {
        //guard let metadata = metadata else { return }
    }
}

extension NowPlayingViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton  = false
        fpc.move(to: .half, animated: true)
        
        self.stationsVC.recommendedStations = []
        self.stationsVC.favoriteStationsCaretaker.reload()
        self.stationsVC.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        fpc.move(to: .full, animated: true)
        
        RadioTimeStationProviderStrategy().getRecommendedStations { (stations, error) in
            guard let stations = stations else { return }
            self.stationsVC.recommendedStations = stations
            
            DispatchQueue.main.async {
                self.stationsVC.tableView.reloadData()
            }
        }
        
        //stationsVC.tableViewTopConstraint.constant = stationsVC.tableViewTopConstraint.constant + 15
//        UIView.animate(withDuration: 0, delay: 0, animations: {
//            self.stationsVC.tableView.layoutIfNeeded()
//            self.stationsVC.tableView.layer.opacity = 0
//        }) { (result) in
//            //self.stationsVC.tableViewTopConstraint.constant = self.stationsVC.tableViewTopConstraint.constant - 15
//
//            UIView.animate(withDuration: 0.2, delay: 0, animations: {
//                self.stationsVC.tableView.layoutIfNeeded()
//                self.stationsVC.tableView.layer.opacity = 1
//            })
//        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            stationsVC.foundStations = []
            stationsVC.tableView.reloadData()
            return
        }
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.reload(_:)), object: searchBar)
        perform(#selector(self.reload(_:)), with: searchBar, afterDelay: 0.65)
    }
    
    @objc func reload(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        
        RadioTimeStationProviderStrategy().getStations(for: searchText) { radioStations, error in
            if error != nil {
                return
            }
            
            if let results = radioStations {
                self.stationsVC.foundStations = results
                
                DispatchQueue.main.async {
                    self.stationsVC.tableView.reloadData()
                }
            }
        }
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
        case .half: return 290.0 // A bottom inset from the safe area
        case .tip: return 0 // A bottom inset from the safe area
        }
    }
}
