//
//  RadioStationCaretaker.swift
//  SwiftRadio
//
//  Created by Andy Peatling on 2018-11-02.
//  Copyright © 2018 matthewfecher.com. All rights reserved.
//

import Foundation

public final class RadioStationCaretaker {
    // MARK: - Properties
    private let fileName = "RadioStationData"
    public var radioStations: [Station] = []
    
    // MARK: - Object Lifecycle
    public init() {
        loadRadioStations()
    }
    
    private func loadRadioStations() {
        if let radioStations =
            try? DiskCaretaker.retrieve([Station].self,
                                        from: fileName) {
            self.radioStations = radioStations
        } else {
            let bundle = Bundle.main
            let url = bundle.url(forResource: fileName,
                                 withExtension: "json")!
            self.radioStations = try!
                DiskCaretaker.retrieve([Station].self, from: url)
            try! save()
        }
    }
    
    // MARK: - Instance Methods
    public func save() throws {
        try DiskCaretaker.save(radioStations, to: fileName)
    }
}
