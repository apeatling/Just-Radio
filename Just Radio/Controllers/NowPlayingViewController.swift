//
//  NowPlayingViewController.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-04.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//
import UIKit

class NowPlayingViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var airplayButton: UIButton!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    // MARK: - Properties
    var fpc: FloatingPanelController!
    var stationsVC: StationsViewController!
    
    let radioPlayer = FRadioPlayer.shared
    
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
        
        radioPlayer.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fpc.addPanel(toParent: self, animated: true)
        
        stationsVC.searchBar.delegate = self
        stationsVC.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove the views managed by the `FloatingPanelController` object from self.view.
        fpc.removePanelFromParent(animated: true)
    }
    
    // MARK: - Actions
    @IBAction func tappedPlayButton(_ sender: Any) {
        
    }

    @IBAction func tappedPauseButton(_ sender: Any) {
        
    }
}

extension NowPlayingViewController: StationsViewControllerDelegate {
    func stationsViewController(_ viewController: StationsViewController, didSelectStation station: Station) {
        trackNameLabel.text = station.name
        artistLabel.text = station.description

        if let url = URL(string: (station.image as NSString) as String) {
            albumArtImageView.loadImageWithURL(url: url) { (image) in
                self.backgroundImageView.image = image
            }
        }
        albumArtImageView.layer.cornerRadius = 24
        
        radioPlayer.radioURL = URL(string: station.url)
        radioPlayer.play()
    }
    
    func stationsViewController(_ viewController: StationsViewController, didFavStation station: Station) {
        
    }
    
    func stationsViewController(_ viewController: StationsViewController, didUnFavStation station: Station) {
        
    }
}

extension NowPlayingViewController: FRadioPlayerDelegate {
    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayerState) {
        switch state {
        case .loading:
            print( "playerStateDidChange: LOADING" )
            break
            
        case .loadingFinished:
            print( "playerStateDidChange: LOADING FINISHED" )
            break
            
        case .readyToPlay:
            print( "playerStateDidChange: READY TO PLAY" )
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
    
    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlaybackState) {
        switch state {
        case .paused:
            print( "playbackStateDidChange: PAUSED" )
            break
            
        case .playing:
            print( "playbackStateDidChange: PLAYING" )
            break
            
        case .stopped:
            print( "playbackStateDidChange: STOPPED" )
            break
            
        default:
            break
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange rawValue: String?) {
        print( "metadataDidChange:", rawValue )
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
        switch newCollection.verticalSizeClass {
        case .compact:
            fpc.surfaceView.borderWidth = 1.0 / traitCollection.displayScale
            fpc.surfaceView.borderColor = UIColor.black.withAlphaComponent(0.2)
            return nil
            //return SearchPanelLandscapeLayout()
        default:
            fpc.surfaceView.borderWidth = 0.0
            fpc.surfaceView.borderColor = nil
            return nil
        }
    }
    
    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        let y = vc.surfaceView.frame.origin.y
        let tipY = vc.originYOfSurface(for: .tip)
        if y > tipY - 44.0 {
            let progress = max(0.0, min((tipY  - y) / 44.0, 1.0))
            self.stationsVC.tableView.alpha = progress
        }
    }
    
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.position == .full {
            stationsVC.searchBar.showsCancelButton = false
            stationsVC.searchBar.resignFirstResponder()
        }
    }

    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        UIView.animate(withDuration: 0.25,
                       delay: 0.0,
                       options: .allowUserInteraction,
                       animations: {
                        if targetPosition == .tip {
                            self.stationsVC.tableView.alpha = 0.0
                        } else {
                            self.stationsVC.tableView.alpha = 1.0
                        }
        }, completion: nil)
    }
}
