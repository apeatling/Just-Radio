//
//  LastPlayedStationCaretaker.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-13.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation

public final class LastPlayedStationCaretaker {
    // MARK: - Properties
    private let key = "LastPlayedStation"
    public var station:Station?
    
    public init() {
        do {
            self.station = try UserDefaultsCaretaker.retrieve(Station.self, key: key)
        } catch {
            self.station = nil
        }
    }

    // MARK: - Instance Methods
    public func save() throws {
        try UserDefaultsCaretaker.save(station, key: key)
    }
}
