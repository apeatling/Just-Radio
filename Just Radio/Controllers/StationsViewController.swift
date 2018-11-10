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

class StationsViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    // MARK: - Properties
    let stationCaretaker = StationCaretaker()
    var stations:[Station] {
        get { return stationCaretaker.stations }
        set { stationCaretaker.stations = newValue }
    }
    var delegate: StationsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        
        searchBar.placeholder = "Search for a radio station"
        let textField = searchBar.value(forKey: "_searchField") as! UITextField
            textField.font = UIFont(name: textField.font!.fontName, size: 17.0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        visualEffectView.layer.cornerRadius = 9.0
        visualEffectView.clipsToBounds = true
    }
}

extension StationsViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !stations.isEmpty else {
            let cell = UITableViewCell()
            cell.backgroundColor = .clear
            cell.isUserInteractionEnabled = false
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "StationTableViewCell", for: indexPath) as! StationTableViewCell
        let station = stations[indexPath.row]
        
        cell.configure(station: station)
        
        return cell
    }
}

extension StationsViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let station = stations[indexPath.row]
        delegate?.stationsViewController(self, didSelectStation: station)
    }
}


//        let bbc5live = Station(name: "BBC Radio 5 Live",
//                               url: "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio5live_mf_p",
//                               image: "https://cdn-radiotime-logos.tunein.com/s24943d.png",
//                               description: "Live news, live sport, from the BBC.",
//                               city: "London",
//                               region: "",
//                               country: "UK",
//                               tags: ["news", "sport"]
//        )
//        stations.append(bbc5live)

//        let talksport = Station(name: "TalkSPORT",
//                               url: "https://radio.talksport.com/stream?awparams=platform:ts-web&aw_0_req.gdpr=true",
//                               image: "http://cdn-radiotime-logos.tunein.com/s17077d.png",
//                               description: "Live Premier League football coverage, breaking sports news, transfer rumours & exclusive interviews.",
//                               city: "London",
//                               region: "",
//                               country: "UK",
//                               tags: ["sport"]
//        )
//        stations.append(talksport)
//
//        try? stationCaretaker.save()
