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
}
