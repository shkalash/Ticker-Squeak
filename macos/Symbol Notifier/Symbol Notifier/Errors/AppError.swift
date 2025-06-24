//
//  AppError.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/24/25.
//


import Foundation

/// Defines custom, user-friendly errors for the application.
enum AppError: LocalizedError {
    case networkError(description: String)
    case fileAccessError(path: String)
    case chartUrlError(data:String)
    case serverError(code: Int)
    case generalError(description:String)
    case unknownError(underlyingError: Error?)

    /// Provides a human-readable description for each error case.
    var errorDescription: String? {
        switch self {
        case .networkError(let description):
            return "A network error occurred: \(description)"
        case .fileAccessError(let path):
            return "Could not access a required file at path: \(path)."
        case .generalError(description: let description):
                fallthrough
        case .chartUrlError(let description):
            return description
        case .serverError(let code):
            return "The server responded with an error (Code: \(code)). Please try again later."
        case .unknownError(let underlyingError):
            if let error = underlyingError {
                return "An unexpected error occurred: \(error.localizedDescription)"
            }
            return "An unexpected error occurred."
        }
    }
}
