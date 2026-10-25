import Foundation

public struct ThemeLibrary {
    public static var defaultThemes: [Theme] {
        return [
            // 1. STRETCH GOAL & FLAGSHIP: Binaural Barber Shop ASMR
            Theme(
                id: "barber-shop",
                title: "Barber Shop",
                subtitle: "Binaural Haircut ASMR • Japanese Shears, Clippers, Mist & Brush",
                moodDescription: "Sink into a vintage leather barber chair. Crisp Japanese steel shears snip inches from your ears, cordless rotary clippers hum warmly around your nape with near-field proximity bass, a fine-tooth comb glides across your crown, cool water mist spritzes overhead, and a soft badger-hair brush dusts your collar.",
                reverbPreset: "Small Room",
                layers: [
                    LayerDefinition(
                        name: "Japanese Steel Shears",
                        colorHex: "#00F5D4",
                        volume: 0.88,
                        source: .audioFile(path: "Resources/Samples/barber_scissors.wav", isLooping: true, interval: 0),
                        motionScript: "orbit radius=0.26 speed=0.11 height=0.05 phase=0.0"
                    ),
                    LayerDefinition(
                        name: "Detail Layering Snips",
                        colorHex: "#5AC8FA",
                        volume: 0.68,
                        source: .procedural(.granularImpulse(type: "scissors", density: 3.5)),
                        motionScript: "lissajous xR=0.24 yR=0.08 zR=0.22 xF=0.16 yF=0.27 zF=0.13"
                    ),
                    LayerDefinition(
                        name: "Cordless Rotary Clippers",
                        colorHex: "#FF9F1C",
                        volume: 0.72,
                        source: .audioFile(path: "Resources/Samples/barber_clippers.wav", isLooping: true, interval: 0),
                        motionScript: "expr x=0.24*sin(0.19*t); y=-0.06+0.04*cos(0.31*t); z=0.18+0.12*cos(0.19*t)"
                    ),
                    LayerDefinition(
                        name: "Fine-Tooth Barber Comb",
                        colorHex: "#FFD166",
                        volume: 0.78,
                        source: .audioFile(path: "Resources/Samples/barber_comb_bristles.wav", isLooping: false, interval: 2.8),
                        motionScript: "wander radius=0.25 speed=0.24 jitter=0.15"
                    ),
                    LayerDefinition(
                        name: "Atomizer Water Mist",
                        colorHex: "#38EF7D",
                        volume: 0.76,
                        source: .audioFile(path: "Resources/Samples/barber_spray.wav", isLooping: false, interval: 6.5),
                        motionScript: "expr x=0.18*sin(0.15*t); y=0.20; z=-0.18+0.10*cos(0.15*t)"
                    ),
                    LayerDefinition(
                        name: "Badger-Hair Neck Duster",
                        colorHex: "#F72585",
                        volume: 0.74,
                        source: .audioFile(path: "Resources/Samples/barber_brush.wav", isLooping: false, interval: 5.2),
                        motionScript: "expr x=0.22*sin(0.45*t); y=-0.12; z=0.20"
                    ),
                    LayerDefinition(
                        name: "Scalp Fingertip Massage",
                        colorHex: "#B5179E",
                        volume: 0.58,
                        source: .audioFile(path: "Resources/Samples/barber_scalp_massage.wav", isLooping: false, interval: 6.0),
                        motionScript: "orbit radius=0.19 speed=-0.15 height=0.12 phase=1.57"
                    )
                ]
            ),

            // 2. Tactile ASMR Study (Close-Mic Foley Triggers)
            Theme(
                id: "tactile-study",
                title: "Tactile Study",
                subtitle: "Close-Mic ASMR • Graphite Sketching, Page Turns, Wood Taps & Purr",
                moodDescription: "An intimate candlelit study designed for deep sensory tingles: a graphite pencil sketches on heavy cotton paper by your right ear, crisp book pages turn to your left, resonant hardwood blocks tap softly, a bamboo rainstick cascades, and a warm cat purrs on your shoulder.",
                reverbPreset: "Small Room",
                layers: [
                    LayerDefinition(
                        name: "Graphite Pencil Sketching",
                        colorHex: "#FFE66D",
                        volume: 0.85,
                        source: .audioFile(path: "Resources/Samples/pencil_sketching.wav", isLooping: true, interval: 0),
                        motionScript: "expr x=0.26+0.05*sin(0.6*t); y=-0.05; z=-0.18+0.05*cos(0.5*t)"
                    ),
                    LayerDefinition(
                        name: "Crisp Book Page Turns",
                        colorHex: "#4ECDC4",
                        volume: 0.82,
                        source: .audioFile(path: "Resources/Samples/page_turning.wav", isLooping: false, interval: 4.4),
                        motionScript: "expr x=-0.28+0.06*sin(0.3*t); y=-0.04; z=-0.20"
                    ),
                    LayerDefinition(
                        name: "Hollow Hardwood Tapping",
                        colorHex: "#FF6B6B",
                        volume: 0.76,
                        source: .audioFile(path: "Resources/Samples/wood_tapping.wav", isLooping: false, interval: 5.5),
                        motionScript: "orbit radius=0.32 speed=0.14 height=-0.02 phase=2.1"
                    ),
                    LayerDefinition(
                        name: "Bamboo Seed Rainstick",
                        colorHex: "#00F5D4",
                        volume: 0.68,
                        source: .audioFile(path: "Resources/Samples/rainstick_seeds.wav", isLooping: true, interval: 0),
                        motionScript: "spiral min=0.25 max=0.65 speed=0.12 vSpeed=0.10 vAmp=0.18"
                    ),
                    LayerDefinition(
                        name: "Sleeping Cat Purr",
                        colorHex: "#C77DFF",
                        volume: 0.72,
                        source: .audioFile(path: "Resources/Samples/cat_purr.wav", isLooping: true, interval: 0),
                        motionScript: "static x=-0.22 y=-0.14 z=0.08"
                    )
                ]
            ),

            // 3. Rain on the Skylight (Grounded Field Recordings + Hearth Foley)
            Theme(
                id: "rain-on-skylight",
                title: "Rain on Skylight",
                subtitle: "Real Window Rain, Crackling Hearth Wood & Rolling Thunder",
                moodDescription: "Curled up beneath a glass skylight as real raindrops patter and streak across the pane overhead, resinous logs crackle and pop in the hearth beside you, and deep thunder rolls across the distant horizon.",
                reverbPreset: "Medium Room",
                layers: [
                    LayerDefinition(
                        name: "Windowpane Rain Shower",
                        colorHex: "#4FACFE",
                        volume: 0.85,
                        source: .audioFile(path: "Resources/Samples/rain_window.wav", isLooping: true, interval: 0),
                        motionScript: "expr x=0.55*sin(t*0.22); y=0.65+0.10*sin(t*0.5); z=-0.45*cos(t*0.22)"
                    ),
                    LayerDefinition(
                        name: "Crackling Hearth Fire",
                        colorHex: "#FF5E3A",
                        volume: 0.82,
                        source: .audioFile(path: "Resources/Samples/hearth_fire_crackle.wav", isLooping: true, interval: 0),
                        motionScript: "static x=0.52 y=-0.18 z=-0.32"
                    ),
                    LayerDefinition(
                        name: "Close Glass Droplets",
                        colorHex: "#00F2FE",
                        volume: 0.62,
                        source: .procedural(.granularImpulse(type: "raindrop", density: 18.0)),
                        motionScript: "wander radius=0.48 speed=0.22 jitter=0.15"
                    ),
                    LayerDefinition(
                        name: "Distant Horizon Thunder",
                        colorHex: "#A18CD1",
                        volume: 0.75,
                        source: .audioFile(path: "Resources/Samples/distant_thunder.wav", isLooping: false, interval: 10.5),
                        motionScript: "flyby start=[-3.2, 0.8, -2.5] end=[3.2, 0.6, -2.5] duration=7.0 pause=3.5"
                    )
                ]
            ),

            // 4. Midnight Meadow (Real Woodland Brook, Crickets Choir & Breeze)
            Theme(
                id: "midnight-meadow",
                title: "Midnight Meadow",
                subtitle: "Woodland Brook, Nocturnal Crickets & Cedar Harp",
                moodDescription: "A tranquil moonlit clearing where a close-mic'd woodland brook trickles over mossy stones, a real choir of field crickets sings in the tall grass, gentle pine breezes drift past your ears, and a resonant cedar harp floats in the night air.",
                reverbPreset: "Medium Room",
                layers: [
                    LayerDefinition(
                        name: "Mossy Woodland Brook",
                        colorHex: "#00E5FF",
                        volume: 0.82,
                        source: .audioFile(path: "Resources/Samples/woodland_brook.wav", isLooping: true, interval: 0),
                        motionScript: "expr x=0.45+0.12*sin(0.25*t); y=-0.15; z=-0.38+0.10*cos(0.20*t)"
                    ),
                    LayerDefinition(
                        name: "Nocturnal Cricket Choir",
                        colorHex: "#8AE234",
                        volume: 0.68,
                        source: .audioFile(path: "Resources/Samples/cricket_chirp.wav", isLooping: true, interval: 0),
                        motionScript: "static x=-0.65 y=-0.20 z=0.42"
                    ),
                    LayerDefinition(
                        name: "Gentle Pine Breeze",
                        colorHex: "#38EF7D",
                        volume: 0.70,
                        source: .audioFile(path: "Resources/Samples/forest_breeze.wav", isLooping: true, interval: 0),
                        motionScript: "wander radius=0.60 speed=0.18 jitter=0.15"
                    ),
                    LayerDefinition(
                        name: "Cedar Soundboard Harp",
                        colorHex: "#FFD200",
                        volume: 0.62,
                        source: .procedural(.pluckedString(baseFreq: 220.0, interval: 3.0)),
                        motionScript: "orbit radius=0.75 speed=0.14 height=0.15 phase=1.2"
                    )
                ]
            ),

            // 5. Tibetan Sanctuary (Real Tibetan Singing Bowl & Koshi Chimes)
            Theme(
                id: "celestial-orbits",
                title: "Tibetan Sanctuary",
                subtitle: "Hand-Hammered Singing Bowl, Koshi Chimes & Harmonium",
                moodDescription: "Surrounded by authentic acoustic resonance: a real 4.5-inch hand-hammered Tibetan singing bowl and bamboo Koshi wind chimes orbit gently around your head over a warm acoustic harmonium drone.",
                reverbPreset: "Large Chamber",
                layers: [
                    LayerDefinition(
                        name: "Tibetan Singing Bowl (4.5\")",
                        colorHex: "#F7971E",
                        volume: 0.84,
                        source: .audioFile(path: "Resources/Samples/singing_bowl.wav", isLooping: false, interval: 9.0),
                        motionScript: "orbit radius=0.48 speed=0.14 height=0.05 phase=0.0"
                    ),
                    LayerDefinition(
                        name: "Bamboo Koshi Wind Chimes",
                        colorHex: "#00F2FE",
                        volume: 0.80,
                        source: .audioFile(path: "Resources/Samples/koshi_chimes.wav", isLooping: true, interval: 0),
                        motionScript: "orbit radius=0.56 speed=-0.11 height=0.18 phase=3.14"
                    ),
                    LayerDefinition(
                        name: "Modal Bronze Harmonics",
                        colorHex: "#FA709A",
                        volume: 0.65,
                        source: .procedural(.fmBell(baseFreq: 261.6, modRatio: 2.756, interval: 4.5)),
                        motionScript: "spiral min=0.35 max=0.95 speed=0.15 vSpeed=0.12 vAmp=0.25"
                    ),
                    LayerDefinition(
                        name: "Warm Harmonium Drone",
                        colorHex: "#6A11CB",
                        volume: 0.52,
                        source: .procedural(.subtractiveDrone(fundamental: 65.4, detune: 5.5)),
                        motionScript: "static x=0.0 y=-0.35 z=-0.40"
                    )
                ]
            ),

            // 6. Horologist's Workshop (Real Clocks, Watch Winding & Music Box)
            Theme(
                id: "clockwork-attic",
                title: "Clockwork Attic",
                subtitle: "Antique Escapements, Crown Winding & Mechanical Music Box",
                moodDescription: "Step inside a quiet master horologist's bench: a close-up pocket watch ticks past your ears, a mechanical watch crown winds with crisp ratchet clicks, a grandfather clock resonates in the corner, and an antique wound-up music box plays.",
                reverbPreset: "Small Room",
                layers: [
                    LayerDefinition(
                        name: "Close Pocket Watch Tick",
                        colorHex: "#FCCF31",
                        volume: 0.84,
                        source: .audioFile(path: "Resources/Samples/clock_tick.wav", isLooping: true, interval: 0),
                        motionScript: "expr x=0.32*sin(0.35*t); y=-0.04; z=-0.26*cos(0.35*t)"
                    ),
                    LayerDefinition(
                        name: "Crown Ratchet Winding",
                        colorHex: "#00F5D4",
                        volume: 0.76,
                        source: .audioFile(path: "Resources/Samples/watch_winding.wav", isLooping: false, interval: 6.5),
                        motionScript: "static x=0.24 y=-0.08 z=-0.16"
                    ),
                    LayerDefinition(
                        name: "Corner Grandfather Clock",
                        colorHex: "#B78628",
                        volume: 0.72,
                        source: .audioFile(path: "Resources/Samples/grandfather_clock.wav", isLooping: true, interval: 0),
                        motionScript: "static x=-0.85 y=0.05 z=-0.65"
                    ),
                    LayerDefinition(
                        name: "Wound-Up Music Box",
                        colorHex: "#F5576C",
                        volume: 0.66,
                        source: .audioFile(path: "Resources/Samples/music_box_lullaby.wav", isLooping: true, interval: 0),
                        motionScript: "orbit radius=0.65 speed=0.16 height=0.08 phase=1.2"
                    )
                ]
            ),

            // 7. Nostromo (Real Hard Drive Seeks, Platter Spinup & Steam Venting)
            Theme(
                id: "nostromo",
                title: "Nostromo",
                subtitle: "USCSS Commercial Freighter 180286 • Real Drive Seeks & Steam",
                moodDescription: "Inside the MU-TH-UR 6000 mainframe room: real mechanical hard disk head seek retries, heavy Toshiba disk platters spinning up, pressurized steam coolant vents overhead, and deep subterranean reactor rumble.",
                reverbPreset: "Medium Room",
                layers: [
                    LayerDefinition(
                        name: "Mechanical HDD Head Seeks",
                        colorHex: "#FFE600",
                        volume: 0.84,
                        source: .audioFile(path: "Resources/Samples/nostromo_drive_seek.wav", isLooping: true, interval: 0),
                        motionScript: "static x=-0.32 y=0.06 z=-0.42"
                    ),
                    LayerDefinition(
                        name: "Platter Spindle Spin-Up",
                        colorHex: "#00F0FF",
                        volume: 0.78,
                        source: .audioFile(path: "Resources/Samples/nostromo_drive_spinup.wav", isLooping: true, interval: 0),
                        motionScript: "expr x=0.38+0.05*sin(0.4*t); y=-0.05; z=-0.45+0.05*cos(0.5*t)"
                    ),
                    LayerDefinition(
                        name: "Pressurized Coolant Steam",
                        colorHex: "#34C759",
                        volume: 0.72,
                        source: .audioFile(path: "Resources/Samples/nostromo_coolant_vent.wav", isLooping: false, interval: 7.0),
                        motionScript: "static x=0.0 y=0.65 z=-0.25"
                    ),
                    LayerDefinition(
                        name: "Reactor Deck Sub-Rumble",
                        colorHex: "#FF3B30",
                        volume: 0.75,
                        source: .audioFile(path: "Resources/Samples/nostromo_hull_rumble.wav", isLooping: true, interval: 0),
                        motionScript: "static x=0.0 y=-0.75 z=0.0"
                    ),
                    LayerDefinition(
                        name: "MU-TH-UR Query Telemetry",
                        colorHex: "#FF9900",
                        volume: 0.58,
                        source: .audioFile(path: "Resources/Samples/nostromo_muthur_beeps.wav", isLooping: false, interval: 6.5),
                        motionScript: "static x=-0.28 y=0.14 z=-0.38"
                    )
                ]
            )
        ]
    }
}
