//
//  UserDefaultsCaretaker.swift
//  Just Radio
//
//  Created by Andy Peatling on 2018-11-04.
//  Copyright © 2018 Andy Peatling. All rights reserved.
//

import Foundation

enum UserDefaultsCaretakerError: Error {
    case noData
}

public final class UserDefaultsCaretaker {
    public static let decoder = JSONDecoder()
    public static let encoder = JSONEncoder()
    public static let userDefaults = UserDefaults.standard
    
    public static func save<T: Codable>(_ object: T, key: String) throws {
        do {
            let data = try encoder.encode(object)
            userDefaults.set(data, forKey: key)
        } catch (let error) {
            print("Save failed: Object: `\(object)`, " + "Error: `\(error)`")
            throw error
        }
    }
    
    public static func retrieve<T: Codable>(_ type: T.Type, key: String) throws -> T {
        do {
            guard let data = userDefaults.data(forKey: key) else { throw UserDefaultsCaretakerError.noData }
            return try decoder.decode(T.self, from: data)
        } catch (let error) {
            print("Retrieve failed: `\(key)`, Error: `\(error)`")
            throw error
        }
    }
}
