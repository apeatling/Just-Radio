//
//  RadioTimeSearchProviderStrategy.swift
//  SwiftRadio
//
//  Created by Andy Peatling on 2018-11-01.
//  Copyright © 2018 matthewfecher.com. All rights reserved.
//

// Playing help
// https://stackoverflow.com/questions/52754263/playing-a-live-tunein-radio-url-ios-swift

import Foundation

enum RadioTimeSearchProviderStrategyError: Error {
    case noValidResults
    case invalidURL
}

public class RadioTimeSearchProviderStrategy: SearchProviderStrategy {
    public var serviceName = "RadioTime"
    public init() {}
    
    public func getStations(for searchTerms: String, completion: @escaping ([Station]?, _ error: Error?) -> ()) {
        guard let searchTermsEncoded = searchTerms.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let url = URL(string: "http://opml.radiotime.com/Search.ashx?filter=s:bit32*&render=json&query=\(searchTermsEncoded)") else {
            
            if kDebugLog { print( "invalid API URL" ) }
            completion(nil, RadioTimeSearchProviderStrategyError.invalidURL)
            return
        }

        var radioStations:[Station] = []

        DataManager.request(url: url, params: nil) { (response, error) in
            if error != nil {
                completion(nil, error)
                
                if kDebugLog { print("SEARCH PROVIDER ERROR: \(error!)") }
                return
            }
            
            guard let stationsResponse = response, let responseBody = stationsResponse.first?["body"] else {
                completion(nil, RadioTimeSearchProviderStrategyError.noValidResults)
                
                if kDebugLog { print("SEARCH PROVIDER ERROR: \(RadioTimeSearchProviderStrategyError.noValidResults)") }
                return
            }

            for radioStationJsonObject in responseBody as! NSArray {
                let station = radioStationJsonObject as! [String:Any]
                
                guard let name = station["text"], let streamURL = station["URL"], let type = station["type"] else {
                    if kDebugLog { print("SEARCH PROVIDER: Skipped station in API response") }
                    continue
                }
                
                if String(describing: type) != "audio" {
                    continue
                }

                var stationImageURL = ""
                if let imageURL = station["image"] {
                    stationImageURL = String(describing: imageURL)
                }

                var stationDescription = ""
                if let description = station["subtext"] {
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

