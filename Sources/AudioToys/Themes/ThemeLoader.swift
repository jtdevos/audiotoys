import Foundation

public struct ThemeLoader {
    public static func syncDefaultThemesToDisk(directory: URL) {
        try? FileManager.default.createDirectory(at: dirPath(directory), withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        for theme in ThemeLibrary.defaultThemes {
            let fileUrl = directory.appendingPathComponent("\(theme.id).json")
            if !FileManager.default.fileExists(atPath: fileUrl.path) {
                if let data = try? encoder.encode(theme) {
                    try? data.write(to: fileUrl)
                }
            }
        }
    }

    private static func dirPath(_ url: URL) -> URL {
        return url
    }

    public static func loadThemes(from directory: URL) -> [Theme] {
        var themes: [Theme] = []
        let fm = FileManager.default

        if let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            let decoder = JSONDecoder()
            for file in files where file.pathExtension == "json" {
                if let data = try? Data(contentsOf: file),
                   let theme = try? decoder.decode(Theme.self, from: data) {
                    themes.append(theme)
                }
            }
        }

        if themes.isEmpty {
            return ThemeLibrary.defaultThemes
        }
        return themes
    }

    public static func instantiate(theme: Theme) -> [AudioLayer] {
        return theme.layers.map { def in
            let motion = MotionScript()
            motion.parse(script: def.motionScript)
            return AudioLayer(
                id: def.id,
                name: def.name,
                colorHex: def.colorHex,
                source: def.source,
                motionScript: motion,
                volume: def.volume
            )
        }
    }
}
