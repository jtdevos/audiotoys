import Foundation

public struct ThemeLoader {
    /// Writes default theme JSON files to disk only if they do not already exist
    /// (unless `overwriteExisting` is explicitly set to `true`).
    public static func syncDefaultThemesToDisk(directory: URL, overwriteExisting: Bool = false) {
        let fm = FileManager.default
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        for theme in ThemeLibrary.defaultThemes {
            let fileUrl = directory.appendingPathComponent("\(theme.id).json")
            if overwriteExisting || !fm.fileExists(atPath: fileUrl.path) {
                if let data = try? encoder.encode(theme) {
                    try? data.write(to: fileUrl)
                }
            }
        }
    }

    @discardableResult
    public static func saveTheme(_ theme: Theme, to directory: URL) -> Bool {
        let fm = FileManager.default
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let fileUrl = directory.appendingPathComponent("\(theme.id).json")
        guard let data = try? encoder.encode(theme) else { return false }
        do {
            try data.write(to: fileUrl, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    public static func resetTheme(withId id: String, in directory: URL) -> Theme? {
        guard let defaultTheme = ThemeLibrary.defaultThemes.first(where: { $0.id == id }) else {
            return nil
        }
        _ = saveTheme(defaultTheme, to: directory)
        return defaultTheme
    }

    public static func captureTheme(base: Theme, activeLayers: [AudioLayer], reverb: ReverbEnvironmentPreset) -> Theme {
        let layerDefs = activeLayers.map { layer in
            LayerDefinition(
                id: layer.id,
                name: layer.name,
                colorHex: layer.colorHex,
                volume: layer.volume,
                source: layer.source,
                motionScript: layer.motionScript.rawScript
            )
        }
        return Theme(
            id: base.id,
            title: base.title,
            subtitle: base.subtitle,
            moodDescription: base.moodDescription,
            reverbPreset: reverb.rawValue,
            layers: layerDefs
        )
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
        for (id, customTheme) in loadedById.sorted(by: { $0.key < $1.key }) where !defaultIds.contains(id) {
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
