//
//  FavoriteStationsCaretaker.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-04.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation

public final class FavoriteStationsCaretaker {
    // MARK: - Properties
    private let key = "FavoriteStations"
    public var stations:[Station]?
    
    // MARK: - Object Lifecycle
    public init() {
        do {
            self.stations = try UserDefaultsCaretaker.retrieve([Station].self, key: key)
        } catch {
            self.stations = nil
        }
    }

    // MARK: - Instance Methods
    public func save() throws {
        try UserDefaultsCaretaker.save(stations, key: key)
    }
}
