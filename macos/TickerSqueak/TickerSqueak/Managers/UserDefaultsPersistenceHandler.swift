//
//  UserDefaultsPersistenceHandler.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//

import Foundation

class UserDefaultsPersistenceHandler: PersistenceHandling {
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func save<T: Codable>(object: T?, for key: PersistenceKey<T>) {
        if let object = object, let data = try? encoder.encode(object) {
            userDefaults.set(data, forKey: key.name)
        } else {
            userDefaults.removeObject(forKey: key.name)
        }
    }

    func load<T: Codable>(for key: PersistenceKey<T>) -> T? {
        guard let data = userDefaults.data(forKey: key.name) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func save<T>(value: T?, for key: PersistenceKey<T>) {
        if let value = value {
            userDefaults.set(value, forKey: key.name)
        } else {
            userDefaults.removeObject(forKey: key.name)
        }
    }

    func load<T>(for key: PersistenceKey<T>) -> T? {
        return userDefaults.object(forKey: key.name) as? T
    }
}
