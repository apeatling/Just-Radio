//
//  Station.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-04.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation

public struct Station: Codable {
    var name: String
    var url: String
    var image: String
    var description: String
    
    var city: String
    var region: String
    var country: String
    
    var tags: [String]
    
    init(name: String, url: String, image: String, description: String, city: String, region: String, country: String, tags: [String] = []) {
        self.name = name
        self.url = url
        self.image = image
        self.description = description
        
        self.city = city
        self.region = region
        self.country = country
        
        self.tags = tags
    }
}
