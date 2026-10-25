import Foundation

public struct ThemeLoader {
    public static func syncDefaultThemesToDisk(directory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        for theme in ThemeLibrary.defaultThemes {
            let fileUrl = directory.appendingPathComponent("\(theme.id).json")
            if let data = try? encoder.encode(theme) {
                try? data.write(to: fileUrl)
            }
        }
    }

    public static func loadThemes(from directory: URL) -> [Theme] {
        var loadedById: [String: Theme] = [:]
        let fm = FileManager.default

        if let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            let decoder = JSONDecoder()
            for file in files where file.pathExtension == "json" {
                if let data = try? Data(contentsOf: file),
                   let theme = try? decoder.decode(Theme.self, from: data) {
                    loadedById[theme.id] = theme
                }
            }
        }

        if loadedById.isEmpty {
            return ThemeLibrary.defaultThemes
        }

        // Preserve curated order for built-in themes, then append any custom user JSON themes
        var ordered: [Theme] = []
        let defaultIds = Set(ThemeLibrary.defaultThemes.map { $0.id })
        for def in ThemeLibrary.defaultThemes {
            if let t = loadedById[def.id] {
                ordered.append(t)
            } else {
                ordered.append(def)
            }
        }
        for (id, customTheme) in loadedById where !defaultIds.contains(id) {
            ordered.append(customTheme)
        }
        return ordered
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
