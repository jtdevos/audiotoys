# 🎧 AudioToys

> Fun, whimsical, minimalist 3D spatial audio toys designed for headphones and AirPods Pro on macOS.

AudioToys is built in **Swift** using Apple's native **AVFoundation** (`AVAudioEngine`, `AVAudioEnvironmentNode`) with high-definition **HRTF (Head-Related Transfer Function)** binaural spatial audio rendering.

---

## ✨ Features & Capabilities

- **Real-Time 3D Spatial Audio**: Utilizes Apple's native `.HRTFHQ` algorithm optimized specifically for AirPods and headphones. Sounds emanate from exact 3D coordinates $(x, y, z)$ in meters around your head.
- **Layered Audio**: Multi-source polyphonic audio combining ambient background beds, orbiting procedural synthesis, and triggered audio file samples.
- **Procedural Audio Engine**: Sample-accurate real-time DSP synthesis running on high-priority audio threads:
  - **FM Bell / Bowl Voice**: Crystalline singing bowls and glass chimes with harmonic/inharmonic frequency modulation.
  - **Karplus-Strong Plucked Strings**: Tactile physical modeling of resonant harps, kotos, and kalimbas.
  - **Filtered Noise Generator**: Pink/brown/white noise with resonant biquad filtering for breathing breezes and ocean surf.
  - **Granular Impulses**: Stochastic Poisson pulse generation for raindrops tapping surfaces, campfire embers, and clock ticks.
  - **Subtractive Drone**: Detuned multi-oscillator warm analog bass and cosmic synth pads.
- **Audio File & Sample Playback**: Native WAV/AIFF/CAF/MP3 audio playback with continuous looping or periodic triggers, fully spatialized in 3D space. Includes built-in algorithmic reference sample generators.
- **Spatial Motion Scripting Language (Stretch Goal)**:
  - Programmatic trajectory controllers: `orbit`, `spiral`, `lissajous`, `pendulum`, `wander`, `flyby`, `static`.
  - Custom mathematical expression parsing: e.g. `expr x=2.5*cos(0.6*t); y=0.4*sin(1.2*t); z=2.0*sin(0.6*t)` with variable `t` (elapsed seconds), operators, and trigonometric functions.
- **Minimalist UI**:
  - **3D Spatial Radar**: Concentric range rings (1m, 2m, 3m, 4m), central listener glyph with AirPods indicator, animated breadcrumb trails, and glowing source nodes.
  - **Tactile Drag-and-Drop**: Click and drag any audio source on the radar to move it in real-time, hearing the audio instantly pan and track across your ears.
  - **Live Script Inspector**: Inspect and live-edit motion scripts with 1-click preset buttons.
  - **Reverb Environment Selector**: Cathedral, Large Chamber, Medium Room, Small Room, Plate Reverb.
  - **Terminal Mode**: Live ANSI terminal radar screen with real-time coordinate telemetry.

---

## 🚀 Quick Start

### 1. Launch the Native macOS GUI

```bash
# Build and run the macOS app
make run
# Or directly run the binary:
./audiotoys
```

### 2. Run in the Terminal (Interactive ANSI Radar)

```bash
# List all available themes
./audiotoys list

# Play any theme in your terminal:
./audiotoys play nostromo
./audiotoys play midnight-meadow
./audiotoys play celestial-orbits
./audiotoys play rain-on-skylight
./audiotoys play clockwork-attic
./audiotoys play quantum-voyage
```

---

## 🎨 Built-in Themes

| Theme ID | Title | Description | Key Layers |
| :--- | :--- | :--- | :--- |
| `nostromo` | **Nostromo** | USCSS Commercial Freighter 180286 • MU-TH-UR 6000 | Front Winchester drive seeks, tape spindle spin-up rack, MU-TH-UR query chirps, sub-deck fusion rumble, overhead coolant vents, avionics sweep |
| `midnight-meadow` | **Midnight Meadow** | Bioluminescent crickets & wandering fireflies | Pink noise breeze, FM bell firefly (Lissajous), meadow harp, spatial field crickets |
| `celestial-orbits` | **Celestial Orbits** | Harmonic planetary spheres & stardust harp | Cosmic sub-drone, Tibetan singing bowl (orbit), crystal chimes (counter-orbit), stardust harp (spiral) |
| `rain-on-skylight` | **Rain on the Skylight** | Cozy fireside sanctuary & rolling thunder | Granular rain on overhead glass, hearthside ember crackles, sweeping horizon thunder |
| `clockwork-attic` | **Clockwork Attic** | Antique escapements & swinging pendulum | Grandfather clock (static left), pocket watch (pendulum), automaton music box (orbit) |
| `quantum-voyage` | **Quantum Voyage** | Sci-fi tachyon sweeps & orbital probes | Pulsing warp core drone, ion probe flybys, spiraling tachyon signal |

---

## 📜 Motion Scripting Reference

Audio sources can be scripted using simple commands or custom math expressions:

### Trajectory Primitives

- **Orbit**: Circle horizontally around the listener
  ```
  orbit radius=2.5 speed=0.4 height=0.2 phase=0.0
  ```
- **Spiral**: Inward and outward expanding/contracting spiral
  ```
  spiral min=0.5 max=3.5 speed=0.3 vSpeed=0.15 vAmp=0.8
  ```
- **Lissajous**: 3D harmonic knot / figure-eight motion (great for fireflies and spirits)
  ```
  lissajous xR=2.2 yR=0.7 zR=1.8 xF=0.4 yF=0.7 zF=0.3
  ```
- **Pendulum**: Swings back and forth like a pocket watch or chandelier
  ```
  pendulum length=2.0 angle=45 freq=0.8 axis=x
  ```
- **Wander**: Natural, smooth organic Brownian wandering
  ```
  wander radius=3.0 speed=0.4 jitter=0.2
  ```
- **Flyby**: Sweeps from a starting point past the listener to an ending point
  ```
  flyby start=[-7, 0.5, 2] end=[7, -0.5, 2] duration=4.0 pause=2.0
  ```
- **Static**: Fixed point in 3D space
  ```
  static x=1.5 y=0.0 z=-2.0
  ```

### Parametric Math Expressions

Use the `expr` prefix to write custom functions of time `t`:
```
expr x = 2.5 * cos(0.6 * t); y = 0.4 * sin(1.2 * t); z = 2.0 * sin(0.6 * t)
```
Supported functions: `sin`, `cos`, `tan`, `abs`, `sqrt`, `noise`, `clamp`, `min`, `max`, and operators `+`, `-`, `*`, `/`, `^`.

---

## 🛠️ Architecture

```
audiotoys/
├── Makefile                          # Build, package, run, test targets
├── AudioToys.app/                    # Packaged native macOS app bundle
├── Sources/
│   └── AudioToys/
│       ├── Main.swift                # App launcher (handles CLI and GUI flags)
│       ├── Audio/
│       │   ├── SpatialAudioEngine.swift  # AVAudioEngine + AVAudioEnvironmentNode (HRTFHQ)
│       │   ├── AudioLayer.swift          # Layer node binding, volume, trails
│       │   ├── ProceduralSynthesis.swift # DSP: FM Bell, Karplus-Strong, Noise, Granular, Drone
│       │   └── SampleGenerator.swift     # Built-in reference audio sample generator
│       ├── Motion/
│       │   ├── Vector3.swift             # 3D coordinates (meters relative to listener)
│       │   ├── MotionScript.swift        # Trajectory parser and evaluator
│       │   └── ExpressionEvaluator.swift # Recursive-descent math parser
│       ├── Themes/
│       │   ├── Theme.swift               # Declarative theme data model
│       │   ├── ThemeLibrary.swift        # 5 built-in spatial themes
│       │   └── ThemeLoader.swift         # JSON persistence and file loading
│       ├── UI/
│       │   ├── AudioToysApp.swift        # NSApplication & Main SwiftUI window
│       │   ├── AppState.swift            # Central ObservableObject application state
│       │   ├── RadarView.swift           # 3D Spatial Radar with real-time drag & trails
│       │   ├── LayerListView.swift       # Layer controls: Mute, Solo, Volume, 3D readout
│       │   ├── ScriptEditorView.swift    # Live trajectory script editor & preset pills
│       │   ├── ThemePickerView.swift     # Horizontal theme pills & mood descriptions
│       │   └── MinimalistTheme.swift     # Obsidian & neon glass styling
│       └── CLI/
│           └── TerminalUI.swift          # ANSI 3D Spatial Radar terminal runner
└── Resources/
    ├── Themes/                           # JSON theme definitions
    └── Samples/                          # Reference audio samples (.wav)
```

---

## 💡 Custom Themes (JSON)

Themes are automatically synced to `Resources/Themes/<id>.json`. You can drop your own JSON themes or edit existing ones directly.
Example `Resources/Themes/my-custom-theme.json`:

```json
{
  "id": "mystic-cave",
  "title": "Mystic Cave",
  "subtitle": "Echoing water drops & underground chimes",
  "moodDescription": "A cavernous acoustic space with reverberant drops.",
  "reverbPreset": "Cathedral",
  "layers": [
    {
      "name": "Echo Drops",
      "colorHex": "#00F0FF",
      "volume": 0.8,
      "source": {
        "procedural": {
          "granularImpulse": {
            "type": "raindrop",
            "density": 12.0
          }
        }
      },
      "motionScript": "wander radius=2.0 speed=0.3 jitter=0.2"
    }
  ]
}
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
