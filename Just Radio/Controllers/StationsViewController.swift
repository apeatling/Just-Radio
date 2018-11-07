//
//  StationsViewController.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-05.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation
import UIKit

class StationsViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
            cell.backgroundColor = .clear
        
        return cell
    }
}

extension StationsViewController: UITableViewDelegate {
}
