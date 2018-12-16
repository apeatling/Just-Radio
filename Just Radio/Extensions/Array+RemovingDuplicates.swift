//
//  Array+RemovingDuplicates.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-12-14.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    
    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
