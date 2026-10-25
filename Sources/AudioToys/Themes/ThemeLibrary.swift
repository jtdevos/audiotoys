import Foundation

public struct ThemeLibrary {
    public static var defaultThemes: [Theme] {
        return [
            Theme(
                id: "nostromo",
                title: "Nostromo",
                subtitle: "USCSS Commercial Freighter 180286 • MU-TH-UR 6000",
                moodDescription: "Echoing industrial corridors of the Nostromo: chunky Winchester drive head seeks, MU-TH-UR 6000 data chirps, tape spindles spinning up, and the deep subterranean vibration of the fusion engines through the metal deck plates.",
                reverbPreset: "Large Chamber",
                layers: [
                    LayerDefinition(
                        name: "MU-TH-UR Terminal",
                        colorHex: "#FFE600",
                        volume: 0.85,
                        source: .audioFile(path: "Resources/Samples/nostromo_drive_seek.wav", isLooping: true, interval: 0),
                        motionScript: "static x=0.0 y=0.15 z=-1.2"
                    ),
                    LayerDefinition(
                        name: "Drive Rack Spindles",
                        colorHex: "#00F0FF",
                        volume: 0.75,
                        source: .audioFile(path: "Resources/Samples/nostromo_drive_spinup.wav", isLooping: true, interval: 0),
                        motionScript: "expr x=1.8+0.06*sin(0.4*t); y=-0.1; z=-1.4+0.06*cos(0.5*t)"
                    ),
                    LayerDefinition(
                        name: "MU-TH-UR Query Beeps",
                        colorHex: "#FF9900",
                        volume: 0.70,
                        source: .audioFile(path: "Resources/Samples/nostromo_muthur_beeps.wav", isLooping: false, interval: 5.5),
                        motionScript: "static x=-0.8 y=0.35 z=-1.3"
                    ),
                    LayerDefinition(
                        name: "Reactor Floor Rumble",
                        colorHex: "#FF3B30",
                        volume: 0.80,
                        source: .audioFile(path: "Resources/Samples/nostromo_hull_rumble.wav", isLooping: true, interval: 0),
                        motionScript: "static x=0.0 y=-1.8 z=0.0"
                    ),
                    LayerDefinition(
                        name: "Overhead Coolant Duct",
                        colorHex: "#34C759",
                        volume: 0.65,
                        source: .audioFile(path: "Resources/Samples/nostromo_coolant_vent.wav", isLooping: false, interval: 7.5),
                        motionScript: "static x=0.0 y=2.2 z=-0.4"
                    ),
                    LayerDefinition(
                        name: "Avionics Scanner Sweep",
                        colorHex: "#5AC8FA",
                        volume: 0.50,
                        source: .procedural(.fmBell(baseFreq: 940.0, modRatio: 1.0, interval: 4.0)),
                        motionScript: "flyby start=[-2.2, 0.3, -1.1] end=[2.2, 0.3, -1.1] duration=8.0 pause=4.0"
                    )
                ]
            ),
            Theme(
                id: "midnight-meadow",
                title: "Midnight Meadow",
                subtitle: "Bioluminescent crickets & wandering fireflies",
                moodDescription: "A serene nocturnal meadow where soft breezes drift past your ears, crickets rustle in the grass, and a glowing musical firefly orbits overhead.",
                reverbPreset: "Large Chamber",
                layers: [
                    LayerDefinition(
                        name: "Midnight Breeze",
                        colorHex: "#38EF7D",
                        volume: 0.45,
                        source: .procedural(.filteredNoise(type: "pink", cutoff: 650.0, resonance: 2.2)),
                        motionScript: "wander radius=2.5 speed=0.35 jitter=0.2"
                    ),
                    LayerDefinition(
                        name: "Wandering Firefly",
                        colorHex: "#FFD200",
                        volume: 0.75,
                        source: .procedural(.fmBell(baseFreq: 440.0, modRatio: 2.756, interval: 3.2)),
                        motionScript: "lissajous xR=2.2 yR=0.7 zR=1.8 xF=0.4 yF=0.7 zF=0.3"
                    ),
                    LayerDefinition(
                        name: "Meadow Harp",
                        colorHex: "#00E5FF",
                        volume: 0.65,
                        source: .procedural(.pluckedString(baseFreq: 220.0, interval: 2.8)),
                        motionScript: "orbit radius=2.8 speed=0.18 height=0.3 phase=1.5"
                    ),
                    LayerDefinition(
                        name: "Field Crickets",
                        colorHex: "#8AE234",
                        volume: 0.55,
                        source: .audioFile(path: "Resources/Samples/cricket_chirp.wav", isLooping: true, interval: 0),
                        motionScript: "static x=-2.2 y=-0.6 z=1.2"
                    )
                ]
            ),
            Theme(
                id: "celestial-orbits",
                title: "Celestial Orbits",
                subtitle: "Harmonic planetary spheres & stardust harp",
                moodDescription: "Float in deep space encircled by singing bowls, crystalline harmonic rings, and deep sub-space vibrations.",
                reverbPreset: "Cathedral",
                layers: [
                    LayerDefinition(
                        name: "Deep Cosmic Drone",
                        colorHex: "#6A11CB",
                        volume: 0.55,
                        source: .procedural(.subtractiveDrone(fundamental: 65.4, detune: 7.0)),
                        motionScript: "static x=0.0 y=-0.5 z=0.0"
                    ),
                    LayerDefinition(
                        name: "Tibetan Singing Bowl",
                        colorHex: "#F7971E",
                        volume: 0.8,
                        source: .procedural(.fmBell(baseFreq: 261.6, modRatio: 1.414, interval: 4.5)),
                        motionScript: "orbit radius=1.6 speed=0.3 height=0.0 phase=0.0"
                    ),
                    LayerDefinition(
                        name: "Crystalline Chimes",
                        colorHex: "#00F2FE",
                        volume: 0.7,
                        source: .procedural(.fmBell(baseFreq: 587.3, modRatio: 3.1415, interval: 2.6)),
                        motionScript: "orbit radius=2.7 speed=-0.22 height=0.8 phase=3.14"
                    ),
                    LayerDefinition(
                        name: "Stardust Harp",
                        colorHex: "#FA709A",
                        volume: 0.65,
                        source: .procedural(.pluckedString(baseFreq: 330.0, interval: 2.2)),
                        motionScript: "spiral min=0.8 max=3.2 speed=0.25 vSpeed=0.15 vAmp=0.6"
                    )
                ]
            ),
            Theme(
                id: "rain-on-skylight",
                title: "Rain on the Skylight",
                subtitle: "Cozy fireside sanctuary & rolling thunder",
                moodDescription: "Curled up under a glass skylight hearing raindrops tap above your head, an ember-crackling fire by your side, and rolling thunder sweeping the horizon.",
                reverbPreset: "Medium Room",
                layers: [
                    LayerDefinition(
                        name: "Skylight Raindrops",
                        colorHex: "#4FACFE",
                        volume: 0.75,
                        source: .procedural(.granularImpulse(type: "raindrop", density: 24.0)),
                        motionScript: "expr x=1.2*sin(t*0.5); y=1.8+0.2*sin(t*1.2); z=1.2*cos(t*0.5)"
                    ),
                    LayerDefinition(
                        name: "Hearthside Embers",
                        colorHex: "#FF416C",
                        volume: 0.7,
                        source: .procedural(.granularImpulse(type: "campfire", density: 16.0)),
                        motionScript: "static x=1.6 y=-0.4 z=0.9"
                    ),
                    LayerDefinition(
                        name: "Rolling Thunder",
                        colorHex: "#434343",
                        volume: 0.65,
                        source: .audioFile(path: "Resources/Samples/distant_thunder.wav", isLooping: false, interval: 8.0),
                        motionScript: "flyby start=[-10, 2, 8] end=[10, 1, 8] duration=5.0 pause=3.0"
                    )
                ]
            ),
            Theme(
                id: "clockwork-attic",
                title: "Clockwork Attic",
                subtitle: "Antique escapements & swinging pendulum",
                moodDescription: "Step into an eccentric horologist’s attic where pocket watches swing past your face, grandfather clocks chime in corners, and musical automatons circle.",
                reverbPreset: "Small Room",
                layers: [
                    LayerDefinition(
                        name: "Grandfather Clock",
                        colorHex: "#B78628",
                        volume: 0.6,
                        source: .audioFile(path: "Resources/Samples/clock_tick.wav", isLooping: true, interval: 0),
                        motionScript: "static x=-2.0 y=0.0 z=0.6"
                    ),
                    LayerDefinition(
                        name: "Swinging Pocket Watch",
                        colorHex: "#FCCF31",
                        volume: 0.75,
                        source: .procedural(.granularImpulse(type: "clocktick", density: 2.0)),
                        motionScript: "pendulum length=1.8 angle=42 freq=0.9 axis=x"
                    ),
                    LayerDefinition(
                        name: "Automaton Music Box",
                        colorHex: "#F5576C",
                        volume: 0.7,
                        source: .procedural(.pluckedString(baseFreq: 523.25, interval: 1.6)),
                        motionScript: "orbit radius=1.9 speed=0.45 height=0.1 phase=0.8"
                    )
                ]
            ),
            Theme(
                id: "quantum-voyage",
                title: "Quantum Voyage",
                subtitle: "Sci-fi tachyon sweeps & orbital probes",
                moodDescription: "An exhilarating sonic journey through an exotic energy field with warp drones, ion probes darting by, and spiraling tachyon signals.",
                reverbPreset: "Plate Reverb",
                layers: [
                    LayerDefinition(
                        name: "Warp Core",
                        colorHex: "#7F00FF",
                        volume: 0.65,
                        source: .procedural(.subtractiveDrone(fundamental: 58.0, detune: 12.0)),
                        motionScript: "static x=0 y=-0.8 z=0"
                    ),
                    LayerDefinition(
                        name: "Ion Probe Flyby",
                        colorHex: "#00F260",
                        volume: 0.8,
                        source: .procedural(.filteredNoise(type: "white", cutoff: 1400.0, resonance: 4.5)),
                        motionScript: "flyby start=[-7, 0.4, 1.6] end=[7, -0.4, 1.6] duration=3.5 pause=1.5"
                    ),
                    LayerDefinition(
                        name: "Tachyon Beacon",
                        colorHex: "#0575E6",
                        volume: 0.7,
                        source: .procedural(.fmBell(baseFreq: 880.0, modRatio: 3.82, interval: 1.8)),
                        motionScript: "spiral min=0.5 max=3.5 speed=0.45 vSpeed=0.25 vAmp=0.8"
                    )
                ]
            )
        ]
    }
}
