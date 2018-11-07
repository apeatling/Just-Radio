//
//  SearchProviderStrategy.swift
//  SwiftRadio
//
//  Created by Andy Peatling on 2018-10-31.
//  Copyright © 2018 matthewfecher.com. All rights reserved.
//

import Foundation

public protocol SearchProviderStrategy: class {
    var serviceName: String { get }
    
    func getStations(for searchTerms: String,
                     completion: @escaping (_ stations: [Station]?, _ error: Error?) -> ())
}
