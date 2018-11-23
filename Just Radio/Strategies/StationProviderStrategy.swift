//
//  StationProviderStrategy.swift
//  SwiftRadio
//
//  Created by Andy Peatling on 2018-10-31.
//

import Foundation

public protocol StationProviderStrategy: class {
    var serviceName: String { get }
    
    func getStations(for searchTerms: String,
                     completion: @escaping (_ stations: [Station]?, _ error: Error?) -> ())
    
    func getRecommendedStations(completion: @escaping (_ stations: [Station]?, _ error: Error?) -> ())
}
