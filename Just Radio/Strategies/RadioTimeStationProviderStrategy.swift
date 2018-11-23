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

enum RadioTimeStationProviderStrategyError: Error {
    case noValidResults
    case invalidURL
}

public class RadioTimeStationProviderStrategy: StationProviderStrategy {
    public var serviceName = "RadioTime"
    public init() {}
    
    public func getStations(for searchTerms: String, completion: @escaping ([Station]?, _ error: Error?) -> ()) {
        guard let searchTermsEncoded = searchTerms.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let url = URL(string: "http://opml.radiotime.com/Search.ashx?filter=s:bit32*&render=json&query=\(searchTermsEncoded)") else {
            
            if kDebugLog { print( "invalid API URL" ) }
            completion(nil, RadioTimeStationProviderStrategyError.invalidURL)
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
                completion(nil, RadioTimeStationProviderStrategyError.noValidResults)
                
                if kDebugLog { print("SEARCH PROVIDER ERROR: \(RadioTimeStationProviderStrategyError.noValidResults)") }
                return
            }

            radioStations = self.parseResponse(responseBody)
            completion(radioStations, nil)
        }
    }
    
    public func getRecommendedStations(completion: @escaping ([Station]?, Error?) -> ()) {
        guard let url = URL(string: "http://opml.radiotime.com/Browse.ashx?c=trending&render=json") else {
                if kDebugLog { print( "invalid API URL" ) }
                completion(nil, RadioTimeStationProviderStrategyError.invalidURL)
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
                completion(nil, RadioTimeStationProviderStrategyError.noValidResults)
                
                if kDebugLog { print("SEARCH PROVIDER ERROR: \(RadioTimeStationProviderStrategyError.noValidResults)") }
                return
            }
            
            radioStations = self.parseResponse(responseBody)
            completion(radioStations, nil)
        }
    }
    
    private func parseResponse(_ responseBody: Any) -> [Station] {
        var radioStations:[Station] = []
        
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
            
            let stationURL = String(describing: streamURL)
            var isFavStation = false
            
            // Is this a fav station?
            let stationCaretaker = FavoriteStationsCaretaker()
            
            if let favStations = stationCaretaker.stations {
                for favStation in favStations {
                    if favStation.url == stationURL {
                        isFavStation = true
                    }
                }
            }

            radioStations.append(Station(name: String(describing: name),
                                         url: stationURL,
                                         image: stationImageURL,
                                         description: stationDescription,
                                         city: "",
                                         region: "",
                                         country: "",
                                         tags: [],
                                         isFav: isFavStation))
        }
        
        return radioStations
    }
}

