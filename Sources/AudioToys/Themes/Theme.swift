import Foundation

public struct LayerDefinition: Codable, Identifiable {
    public var id: String = UUID().uuidString
    public var name: String
    public var colorHex: String
    public var volume: Float
    public var source: LayerSource
    public var motionScript: String

    public init(name: String, colorHex: String, volume: Float = 1.0, source: LayerSource, motionScript: String) {
        self.name = name
        self.colorHex = colorHex
        self.volume = volume
        self.source = source
        self.motionScript = motionScript
    }
}

public struct Theme: Codable, Identifiable {
    public var id: String
    public var title: String
    public var subtitle: String
    public var moodDescription: String
    public var reverbPreset: String
    public var layers: [LayerDefinition]

    public init(id: String, title: String, subtitle: String, moodDescription: String, reverbPreset: String, layers: [LayerDefinition]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.moodDescription = moodDescription
        self.reverbPreset = reverbPreset
        self.layers = layers
    }
}
