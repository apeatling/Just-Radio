//
//  StationsViewController.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-05.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation
import UIKit

protocol StationsViewControllerDelegate: class {
    func stationsViewController(_ viewController: StationsViewController, didSelectStation station: Station)
    func stationsViewController(_ viewController: StationsViewController, didFavStation station: Station)
    func stationsViewController(_ viewController: StationsViewController, didUnFavStation station: Station)
}

enum StationsTableViewSections: Int {
    case nowPlaying
    case searchResults
    case recommended
    case favorites
    
    init?(indexPath: NSIndexPath) {
        self.init(rawValue: indexPath.section)
    }
    
    static var numberOfSections: Int { return 4 }
}

class StationsViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var searchBarContainerView: UIView!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    
    // MARK: - Injected Dependencies
    weak var radioPlayer:RadioPlayer!
    var nowPlayingVC: NowPlayingViewController!
    var currentStation: Station!
    var favoriteStationsCaretaker: FavoriteStationsCaretaker!
    
    // MARK: - Properties
    var favoriteStations:[Station] {
        get {
            guard let stations = favoriteStationsCaretaker.stations else { return [] }
            return stations
        }
        set {
            favoriteStationsCaretaker.stations = newValue
            try? favoriteStationsCaretaker.save()
        }
    }
    
    var foundStations:[Station] = []
    var recommendedStations:[Station] = []
    
    let searchProviderStrategy = RadioTimeStationProviderStrategy()
    var delegate: StationsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 11))
        
        searchBarContainerView.addBorder([.bottom], color: UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.1), width: 0.5)
        let textField = searchBar.value(forKey: "_searchField") as! UITextField
            textField.font = UIFont.systemFont(ofSize: 17)
        
        nowPlayingVC.delegate = self
    }
    
    func favStation() {
        // These updates only apply to the favorite stations screen
        if self.tableView.numberOfRows(inSection: StationsTableViewSections.recommended.rawValue) > 0 { return }
        
        self.tableView.beginUpdates()
        
        if self.tableView.numberOfRows(inSection: StationsTableViewSections.nowPlaying.rawValue) > 0 {
            self.tableView.moveRow(at: IndexPath(row: 0, section: StationsTableViewSections.nowPlaying.rawValue), to: IndexPath(row: 0, section: StationsTableViewSections.favorites.rawValue))
            
            self.favoriteStationsCaretaker.reload()
        }
        
        self.tableView.endUpdates()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: StationsTableViewSections.favorites.rawValue)], with: .fade)
        }
    }
    
    func unFavStation() {
        // These updates only apply to the favorite stations screen
        if self.tableView.numberOfRows(inSection: StationsTableViewSections.recommended.rawValue) > 0 { return }
        
        self.tableView.beginUpdates()
        
        if self.tableView.numberOfRows(inSection: StationsTableViewSections.nowPlaying.rawValue) == 0 {
            self.tableView.moveRow(at: IndexPath(row: 0, section: StationsTableViewSections.favorites.rawValue), to: IndexPath(row: 0, section: StationsTableViewSections.nowPlaying.rawValue))
            
            self.favoriteStationsCaretaker.reload()
        }
        
        self.tableView.endUpdates()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: StationsTableViewSections.nowPlaying.rawValue)], with: .fade)
        }
    }
}

extension StationsViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.tableView(tableView, numberOfRowsInSection: section) == 0 || section == StationsTableViewSections.nowPlaying.rawValue {
            return .leastNormalMagnitude
        }
        return 30.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if self.tableView(tableView, numberOfRowsInSection: section) == 0 {
            return .leastNormalMagnitude
        }
        return 20.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return StationsTableViewSections.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch StationsTableViewSections(rawValue: section) {
            case .nowPlaying?:
                guard let currentStation = currentStation else { return 0 }
                if favoriteStations.contains(currentStation) || recommendedStations.count > 0 { return 0 }
                return 1
            case .searchResults?: return foundStations.count
            case .favorites?:
                if recommendedStations.count > 0 || foundStations.count > 0 { return 0 }
                return favoriteStations.count
            case .recommended?: return recommendedStations.count
            case .none: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.tableView(tableView, numberOfRowsInSection: section) == 0 {
            return nil
        }
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 25))
        let label = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.frame.size.width, height: 25))
            label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        
        switch StationsTableViewSections(rawValue: section) {
        case .nowPlaying?: label.text = ""
        case .searchResults?: label.text = "Matching Stations"
        case .favorites?: label.text = "Favorite Stations"
        case .recommended?: label.text = "Recommended Stations"
        case .none: label.text = ""
        }

        view.addSubview(label)
        return view
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch StationsTableViewSections(rawValue: indexPath.section) {
            case .nowPlaying?:
                guard let currentStation = currentStation else { return emptyCell() }
                if favoriteStations.contains(currentStation) || recommendedStations.count > 0 { return emptyCell() }
                return getCell(stations: [currentStation], indexPath: indexPath)
            case .searchResults?: return getCell(stations: foundStations, indexPath: indexPath)
            case .favorites?:
                if recommendedStations.count > 0 || foundStations.count > 0 { return emptyCell() }
                return getCell(stations: favoriteStations, indexPath: indexPath)
            case .recommended?: return getCell(stations: recommendedStations, indexPath: indexPath)
            case .none: return emptyCell()
        }
    }
    
    private func getCell(stations: [Station], indexPath: IndexPath) -> UITableViewCell {
        if stations.isEmpty {
            return emptyCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "StationTableViewCell", for: indexPath) as! StationTableViewCell
        let station = stations[indexPath.row]
        
        let showBorder = (tableView.numberOfRows(inSection: indexPath.section) - 1) != indexPath.row
        
        cell.configure(stationForCell: station,
                       radioPlayer: radioPlayer,
                       currentStation: currentStation,
                       favoriteStationsCaretaker: favoriteStationsCaretaker,
                       showBorder: showBorder)
        
        cell.delegate = self
 
        UIView.setAnimationsEnabled(false)
        cell.favButton.isHidden = false
        if StationsTableViewSections(rawValue: indexPath.section) == .favorites {
            cell.favButton.isHidden = true
        }
        UIView.setAnimationsEnabled(true)
        
        return cell
    }
    
    private func emptyCell() -> UITableViewCell {
        let cell = UITableViewCell(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        cell.backgroundColor = .clear
        cell.isUserInteractionEnabled = false
        
        return cell
    }
}

extension StationsViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBar.resignFirstResponder()
        
        var station:Station!
        var moveStationToTop = false
        
        switch StationsTableViewSections(rawValue: indexPath.section) {
        case .nowPlaying?:
            station = currentStation
            break
        case .searchResults?:
            station = foundStations[indexPath.row]
            break
        case .favorites?:
            station = favoriteStations[indexPath.row]
            
            moveStationToTop = true
            break
        case .recommended?:
            station = recommendedStations[indexPath.row]
            break
        case .none:
            return
        }
        
        let cells = tableView.visibleCells as! Array<StationTableViewCell>
        for cell in cells {
            cell.isCurrentStation = false
        }

        let cell = tableView.cellForRow(at: indexPath) as! StationTableViewCell
            cell.isCurrentStation = true
            cell.isRadioPlaying = radioPlayer.fplayer.isPlaying
        
        if moveStationToTop {
            self.tableView.isUserInteractionEnabled = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.tableView.beginUpdates()
                
                if self.tableView.numberOfRows(inSection: StationsTableViewSections.nowPlaying.rawValue) > 0 {
                    self.tableView.deleteRows(at: [IndexPath(row: 0, section: StationsTableViewSections.nowPlaying.rawValue)], with: .automatic)
                }
                
                self.tableView.moveRow(at: indexPath, to: IndexPath(row: 0, section: indexPath.section))
                self.favoriteStations.remove(at: indexPath.row)
                self.favoriteStations.insert(station, at: 0)
                try? self.favoriteStationsCaretaker.save()

                self.tableView.endUpdates()
                self.tableView.isUserInteractionEnabled = true
            }
        }
        
        delegate?.stationsViewController(self, didSelectStation: station)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch StationsTableViewSections(rawValue: indexPath.section) {
            case .favorites?: return true
            default: return false
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let remove = UITableViewRowAction(style: .destructive, title: "Remove") { (action, indexPath) in
            // delete item at indexPath
            self.favoriteStations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        remove.backgroundColor = UIColor(red:0.82, green:0.12, blue:0.36, alpha:1)
        
        return [remove]
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }
}

extension StationsViewController: StationTableViewCellDelegate {
    func StationTableViewCell(_ cell: StationTableViewCell, didFavStation station: Station) {
        favStation()
        delegate?.stationsViewController(self, didFavStation: station)
    }
    
    func StationTableViewCell(_ cell: StationTableViewCell, didUnFavStation station: Station) {
        unFavStation()
        delegate?.stationsViewController(self, didUnFavStation: station)
    }
}

extension StationsViewController: NowPlayingViewControllerDelegate {
    func nowPlayingViewController(_ viewController: NowPlayingViewController, didFavStation station: Station) {
        favStation()
    }
    
    func nowPlayingViewController(_ viewController: NowPlayingViewController, didUnFavStation station: Station) {
        unFavStation()
    }
}
