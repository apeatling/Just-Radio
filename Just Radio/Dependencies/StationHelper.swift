//
//  StationHelper.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-12-15.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation

class StationHelper {
    static func isFav(_ station: Station, favoriteStationsCaretaker: FavoriteStationsCaretaker) -> Bool {
        if let favStations = favoriteStationsCaretaker.stations {
            if favStations.contains(station) {
                return true
            }
        }
        
        return false
    }
    
    static func fav(_ station: Station, favoriteStationsCaretaker: FavoriteStationsCaretaker) {
        let favStationsCaretaker = FavoriteStationsCaretaker()
        favStationsCaretaker.stations?.insert(station, at: 0)
        
        try? favStationsCaretaker.save()
    }
    
    static func unfav(_ station: Station, favoriteStationsCaretaker: FavoriteStationsCaretaker) {
        let favStationsCaretaker = FavoriteStationsCaretaker()
        var stationIndex:Int?
        
        guard let favStations = favStationsCaretaker.stations else { return }
        
        for (index, favStation) in favStations.enumerated() {
            if favStation == station {
                stationIndex = index
            }
        }
        
        if let stationIndex = stationIndex {
            favStationsCaretaker.stations?.remove(at: stationIndex)
        }
        
        try? favStationsCaretaker.save()
    }
}
