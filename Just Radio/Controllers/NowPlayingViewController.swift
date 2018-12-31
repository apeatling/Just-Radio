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

protocol NowPlayingViewControllerDelegate: class {
    func nowPlayingViewController(_ viewController: NowPlayingViewController, didFavStation station: Station)
    func nowPlayingViewController(_ viewController: NowPlayingViewController, didUnFavStation station: Station)
}

class NowPlayingViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIPlayPauseButton!
    @IBOutlet weak var favButton: UIReactiveButton!
    @IBOutlet weak var moreButton: UIReactiveButton!
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
    var radioPlayer: RadioPlayer!
    
    // MARK: - Properties
    var delegate: NowPlayingViewControllerDelegate?
    var fpc: FloatingPanelController!
    var stationsVC: StationsViewController!
    var currentStation: Station!
    var currentTrack: Track!
    var isShowingTrackLabel = false
    var favoriteStationsCaretaker = FavoriteStationsCaretaker()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up Stations View Controller
        stationsVC = storyboard?.instantiateViewController(withIdentifier: "StationsViewController") as? StationsViewController
        stationsVC.nowPlayingVC = self
        stationsVC.radioPlayer = self.radioPlayer
        stationsVC.favoriteStationsCaretaker = self.favoriteStationsCaretaker
        
        setCurrentStation(station: nil, autoPlay: false)
 
        // Set up floating panel for stations
        fpc = FloatingPanelController()
        fpc.delegate = self
        fpc.surfaceView.backgroundColor = .clear
        fpc.surfaceView.cornerRadius = 9.0
        fpc.surfaceView.shadowHidden = false
        fpc.set(contentViewController: stationsVC)
        fpc.track(scrollView: stationsVC.tableView)
        
        // Setup album art
        albumArtImageView.layer.cornerRadius = 10
        albumArtImageView.clipsToBounds = true

        // Speak to the remote commmand center
        setupRemoteCommandCenter()
        
        // Set up Airplay status
        setActiveAirplayDevice()
        listenForAirplayChange()
        setupAirplayPicker()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fpc.addPanel(toParent: self, animated: false)

        radioPlayer.delegate = self
        
        stationsVC.searchBar.delegate = self
        stationsVC.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove the views managed by the `FloatingPanelController` object from self.view.
        fpc.removePanelFromParent(animated: true)
    }
    
    private func setCurrentStation(station: Station?, autoPlay: Bool = true) {
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
        radioPlayer.fplayer.isAutoPlay = true
        
        if !autoPlay {
            radioPlayer.fplayer.isAutoPlay = false
        }
        
        if StationHelper.isFav(currentStation, favoriteStationsCaretaker: favoriteStationsCaretaker) {
            selectFavButton()
        } else {
            deselectFavButton()
        }
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
        
        // Add handler for Play/Pause toggle Command
        commandCenter.togglePlayPauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if self.radioPlayer.fplayer.isPlaying {
                self.radioPlayer.fplayer.stop()
            } else {
                self.radioPlayer.fplayer.play()
            }
            
            return .success
        }
        
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
        
        // Add handler for Stop Command
        commandCenter.stopCommand.addTarget { event in
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
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = ""
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func listenForAirplayChange() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(airplayChanged),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance())
    }
    
    @objc func airplayChanged() {
        print( "*************\n", "Airplay Changed", "\n****************" )
        self.setActiveAirplayDevice()
    }
    
    func setActiveAirplayDevice() {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            self.portDidChange(portType: output.portType, portName: output.portName)
        }
    }

    func setupAirplayPicker() {
        self.airplayStackView.isHidden = false

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
    
    func selectFavButton() {
        favButton.setImage(UIImage(named: "Fav On"), for: .normal)
        favButton.layer.opacity = 1
    }
    
    func deselectFavButton() {
        favButton.setImage(UIImage(named: "Fav Off"), for: .normal)
        favButton.layer.opacity = 0.5
    }
    
    // MARK: - Actions
    @IBAction func tappedPlayPauseButton(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        if radioPlayer.fplayer.isPlaying {
            radioPlayer.fplayer.stop()
            playPauseButton.setPlay()
        } else {
            radioPlayer.fplayer.play()
            playPauseButton.setPause()
        }
    }
    
    @IBAction func tappedFavButton(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        if let favStations = favoriteStationsCaretaker.stations, let station = self.currentStation {
            if favStations.contains(station) {
                StationHelper.unfav(station, favoriteStationsCaretaker: favoriteStationsCaretaker)
                deselectFavButton()
                
                delegate?.nowPlayingViewController(self, didUnFavStation: station)
            } else {
                StationHelper.fav(station, favoriteStationsCaretaker: favoriteStationsCaretaker)
                selectFavButton()
                
                delegate?.nowPlayingViewController(self, didFavStation: station)
            }
        }
    }
    
    @IBAction func tappedMoreButton(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension NowPlayingViewController: StationsViewControllerDelegate {
    func stationsViewController(_ viewController: StationsViewController, didSelectStation station: Station) {
        currentStation = nil

        if StationHelper.isFav(station, favoriteStationsCaretaker: favoriteStationsCaretaker) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.fpc.move(to: .half, animated: true)
                self.stationsVC.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
            }
        }

        setCurrentStation(station: station)
        radioPlayer.fplayer.play()
    }
    
    func stationsViewController(_ viewController: StationsViewController, didFavStation station: Station) {
        selectFavButton()
    }
    
    func stationsViewController(_ viewController: StationsViewController, didUnFavStation station: Station) {
        deselectFavButton()
    }
}

extension NowPlayingViewController: RadioPlayerDelegate {
    func playerStateDidChange(_ playerState: FRadioPlayerState) {}
    
    func playbackStateDidChange(_ playbackState: FRadioPlaybackState) {
        switch playbackState {
        case .paused, .stopped:
            playPauseButton.setPlay()
            break
        case .playing:
            playPauseButton.setPause()
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
        stationsVC.searchBar.resignFirstResponder()
        stationsVC.searchBar.setShowsCancelButton(false, animated: true)
        fpc.move(to: .half, animated: true)
        self.stationsVC.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
        searchBar.text? = ""
        
        self.stationsVC.recommendedStations = []
        self.stationsVC.foundStations = []
        self.favoriteStationsCaretaker.reload()
        self.stationsVC.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        stationsVC.searchBar.setShowsCancelButton(true, animated: true)
        fpc.move(to: .full, animated: true)
        self.stationsVC.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
        
        if !self.stationsVC.recommendedStations.isEmpty {
            return
        }
        
        RadioTimeStationProviderStrategy().getRecommendedStations { (stations, error) in
            guard let stations = stations else { return }
            self.stationsVC.recommendedStations = stations
            
            DispatchQueue.main.async {
                self.stationsVC.tableView.reloadData()
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            self.stationsVC.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
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
            stationsVC.searchBar.setShowsCancelButton(false, animated: true)
            stationsVC.searchBar.resignFirstResponder()
        }
    }
    
    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        if targetPosition != .full {
            stationsVC.foundStations = []
            stationsVC.recommendedStations = []
            
            self.favoriteStationsCaretaker.reload()
            stationsVC.tableView.reloadData()
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
