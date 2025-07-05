//
//  LocalChecklistTemplateProvider.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import Foundation

/// A concrete implementation of `ChecklistTemplateProviding` that loads checklist templates from the local file system.
///
/// This provider first looks for a JSON template in the app's Application Support directory. If the file is not found,
/// it falls back to a default version bundled with the app and copies it to the Application Support directory for future use.
/// Errors encountered during this process are reported via the `ErrorManager`.
class LocalChecklistTemplateProvider: ChecklistTemplateProviding {

    /// Custom errors that this provider can throw.
    enum TemplateError: Error, LocalizedError {
        case bundleResourceMissing(String)
        case directoryCreationFailed

        var errorDescription: String? {
            switch self {
            case .bundleResourceMissing(let name):
                return "A required template resource, '\(name).json', was not found in the app bundle. Please check the project configuration."
            case .directoryCreationFailed:
                return "Failed to create the necessary checklists directory in Application Support."
            }
        }
    }

    // MARK: - Dependencies

    private let fileLocationProvider: FileLocationProviding
    private let fileManager: FileManager
    private let decoder: JSONDecoder

    // MARK: - Initialization

    /// Initializes the provider with its dependencies.
    /// - Parameters:
    ///   - fileLocationProvider: A service that provides the URL for the checklists directory.
    ///   - fileManager: The file manager to use for file operations. Defaults to `FileManager.default`.
    init(fileLocationProvider: FileLocationProviding, fileManager: FileManager = .default) {
        self.fileLocationProvider = fileLocationProvider
        self.fileManager = fileManager
        self.decoder = JSONDecoder()
    }

    // MARK: - ChecklistTemplateProviding Conformance

    /// Asynchronously loads and decodes a checklist template from a given file name.
    func loadChecklistTemplate(forName name: String) async throws -> Checklist {
        do {
            // 1. Get the URL where the user's checklist should be.
            let userChecklistURL = try fileLocationProvider.getChecklistsDirectory()
                .appendingPathComponent(name)
                .appendingPathExtension("json")

            // 2. If the user's checklist doesn't exist, create it from the bundled default.
            if !fileManager.fileExists(atPath: userChecklistURL.path) {
                try copyDefaultTemplate(forName: name, to: userChecklistURL)
            }

            // 3. Read the data from the file URL.
            let data = try Data(contentsOf: userChecklistURL)

            // 4. Decode the data into a Checklist object and return it.
            let checklist = try decoder.decode(Checklist.self, from: data)
            return checklist
            
        } catch {
            // --- MODIFIED SECTION ---
            // Any error thrown in the `do` block will be caught here.
            
            // 1. Report the error using the shared ErrorManager.
            // This will trigger the dialog presentation for the user.
            ErrorManager.shared.report(error)
            
            // 2. Re-throw the error so the caller (e.g., the ViewModel) knows the operation failed
            // and can update its state accordingly (e.g., stop a loading indicator).
            throw error
            // --- END MODIFIED SECTION ---
        }
    }

    // MARK: - Private Helpers

    /// Copies the default template from the app's bundle to the user's Application Support directory.
    private func copyDefaultTemplate(forName name: String, to destinationURL: URL) throws {
        // Find the default template file included in the app's build.
        guard let bundledTemplateURL = Bundle.main.url(forResource: name, withExtension: "json") else {
            // This is a critical developer error; the app is missing a required resource.
            throw TemplateError.bundleResourceMissing(name)
        }

        // Ensure the destination directory exists before trying to copy the file.
        let directoryURL = destinationURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Copy the default file to the user's directory.
        try fileManager.copyItem(at: bundledTemplateURL, to: destinationURL)
    }
}