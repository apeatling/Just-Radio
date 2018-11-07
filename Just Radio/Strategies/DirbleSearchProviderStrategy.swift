//
//  DirbleSearchProviderStrategy.swift
//  SwiftRadio
//
//  Created by Andy Peatling on 2018-10-31.
//  Copyright © 2018 matthewfecher.com. All rights reserved.
//

import Foundation

enum DirbleSearchProviderStrategyError: Error {
    case noValidResults
}

public class DirbleSearchProviderStrategy: SearchProviderStrategy {
    public var serviceName = "Dirble"
    private var apiKey = "1b8f8a137a2777dd203532aa0d"
    
    public init() {}
    
    public func getStations(for searchTerms: String, completion: @escaping ([Station]?, _ error: Error?) -> ()) {
        let url = URL(string: "http://api.dirble.com/v2/search?token=\(apiKey)")!
        var radioStations:[Station] = []
        
        // TODO: Guard that search terms is a string
        
        DataManager.request(url: url, params: ["query": searchTerms]) { (response, error) in
            if error != nil {
                completion(nil, error)
                
                if kDebugLog { print("SEARCH PROVIDER ERROR: \(error!)") }
                return
            }
            
            guard let stationsResponse = response else {
                completion(nil, DirbleSearchProviderStrategyError.noValidResults)
                
                if kDebugLog { print("SEARCH PROVIDER ERROR: \(DirbleSearchProviderStrategyError.noValidResults)") }
                return
            }

            for radioStationJsonObject in stationsResponse {
                guard let name = radioStationJsonObject["name"],
                      let streams = radioStationJsonObject["streams"] as? [[String:Any]],
                      let firstStream = streams.first,
                      let streamURL = firstStream["stream"]
                else {
                    if kDebugLog { print("SEARCH PROVIDER: Skipped station in API response") }
                    continue
                }
                
                var stationImageURL = ""
                if  let imageContainer = radioStationJsonObject["image"] as? [String:Any],
                    let imageURL = imageContainer["url"] {
                    
                    if String(describing: imageURL) != "<null>" {
                       stationImageURL = String(describing: imageURL)
                    }
                }
                
                var stationDescription = ""
                if let description = radioStationJsonObject["description"] {
                    stationDescription = String(describing: description)
                }
                
                radioStations.append(Station(name: String(describing: name),
                                             url: String(describing: streamURL),
                                             image: stationImageURL,
                                             description: stationDescription,
                                             city: "",
                                             region: "",
                                             country: ""))
            }
            
            completion(radioStations, nil)
        }
    }
}
