//
//  PickerOptionsProviding.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/5/25.
//


/// Defines a contract for a service that provides lists of options for dynamic pickers.
protocol PickerOptionsProviding {
    /// Returns the array of string options for a given key.
    func options(for key: String) -> [String]
}