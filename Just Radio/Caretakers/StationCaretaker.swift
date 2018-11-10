//
//  StationCaretaker.swift
//  SwiftRadio
//
//  Created by Andy Peatling on 2018-11-02.
//  Copyright © 2018 matthewfecher.com. All rights reserved.
//

import Foundation

public final class StationCaretaker {
    // MARK: - Properties
    private let fileName = "StationData"
    public var stations: [Station] = []
    
    // MARK: - Object Lifecycle
    public init() {
        loadStations()
    }

    private func loadStations() {
        if let stations =
            try? DiskCaretaker.retrieve([Station].self,
                                        from: fileName) {
            self.stations = stations
        } else {
            let bundle = Bundle.main
            let url = bundle.url(forResource: fileName,
                                 withExtension: "json")!
            self.stations = try!
                DiskCaretaker.retrieve([Station].self, from: url)
            try! save()
        }
    }
    
    // MARK: - Instance Methods
    public func save() throws {
        try DiskCaretaker.save(stations, to: fileName)
    }
}
