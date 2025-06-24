import AppKit

public extension NSSound {
    static var systemSoundNames: [String] {
        let soundDirs = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Sounds"),
            URL(fileURLWithPath: "/Library/Sounds"),
            URL(fileURLWithPath: "/System/Library/Sounds")
        ]

        var names = Set<String>()

        for dir in soundDirs {
            if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for url in files where url.pathExtension == "aiff" || url.pathExtension == "wav" || url.pathExtension == "caf" {
                    let name = url.deletingPathExtension().lastPathComponent
                    if let sound = NSSound(named: name), let validName = sound.name {
                        names.insert(validName)
                    }
                }
            }
        }

        return Array(names).sorted()
    }
    static var bundledSoundNames: [String] {
        // 1. Define the path to our special sounds folder relative to the bundle's root.
        // We are no longer looking in the default "Resources" directory.
        let soundsSubdirectory = "Contents/Library/Sounds"
        
        // 2. Construct the full URL to that directory.
        let soundsURL = Bundle.main.bundleURL
                .appendingPathComponent(soundsSubdirectory)
        do {
            // 3. Use FileManager to get the URLs of all items inside the Sounds directory.
            let soundFileURLs = try FileManager.default.contentsOfDirectory(at: soundsURL,
                                                                             includingPropertiesForKeys: nil,
                                                                             options: .skipsHiddenFiles)
            
            // 4. Map the URLs to sound names, filtering for valid sound file types.
            return soundFileURLs.compactMap { url in
                let fileExtension = url.pathExtension.lowercased()
                
                // Accept both wav and aiff files now.
                if fileExtension == "wav" || fileExtension == "aiff" {
                    // Return the name of the sound (filename without extension)
                    return url.deletingPathExtension().lastPathComponent
                }
                return nil
            }
            .sorted() // Sort the names alphabetically.

        } catch {
            ErrorManager.shared.report(AppError.fileAccessError(path: "Error reading contents of Sounds directory: \(error.localizedDescription)"))
            return []
        }
    }

}
