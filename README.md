# 🎧 AudioToys — Binaural ASMR & 3D Spatial Audio Studio

> Grounded, intimate, close-mic'd 3D spatial audio & ASMR soundscapes designed for AirPods Pro and headphones on macOS.

AudioToys is built in **Swift** using Apple's native **AVFoundation** (`AVAudioEngine`, `AVAudioEnvironmentNode`) with **`.HRTFHQ` (High-Quality Head-Related Transfer Function)** binaural rendering, a **5-Stage Per-Layer Acoustic DSP Filter Chain**, and **Mastered Close-Mic Public-Domain Foley & Field Recordings**.

---

## ✨ Key Features & Architecture

1. **Real Close-Mic Foley & Field Recordings (`PDsounds.org` / CC0)**:
   - Replaced synthetic sine-wave placeholders with 28 mastered, denoised, EQ-sculpted 44.1kHz mono acoustic recordings (`Resources/Samples/`): real Japanese steel scissors snipping, cordless rotary hair clippers, atomizer water mist spritzes, fine-tooth comb bristles, badger-hair neck brushes, scalp fingertip massage, graphite pencil sketching, book page turns, hardwood tapping, bamboo seed rainsticks, sleeping cat purrs, rain on glass windows, crackling hearth wood fires, woodland brooks, Tibetan singing bowls, Koshi wind chimes, antique clocks, and mechanical hard drive head seeks.
2. **Real-Time 5-Stage Per-Layer Acoustic DSP Filter Chain (`AcousticFilterChain.swift`)**:
   - **Stage 1 — High-Pass Sub-Rumble Filter**: 2nd-order Butterworth HPF tailored per material profile (`28 Hz – 135 Hz`).
   - **Stage 2 — Dynamic Binaural Proximity Bass Shelf (`165 Hz`)**: Automatically boosts warm near-field body resonance (up to `+7.5 dB`) as a sound source moves within `12cm – 85cm` of your ears—recreating the physical acoustic proximity effect of binaural 3Dio/KU100 ASMR microphones.
   - **Stage 3 — Material Formant Parametric EQ**: Sculpted profiles for `Crisp Steel Shears`, `Warm Rotary Clippers`, `Velvet Brush & Comb`, `Intimate ASMR`, `Resonant Wood & Hearth`, `Crystalline Harmonic`, `Deep Subterranean`, and `Natural Studio Foley`.
   - **Stage 4 — Near-Field Air Exciter (`7.5 kHz`) + Pinna Front/Back Shadow & Distance Air Absorption**: Enhances crisp micro-transients when close to the ear canal while casting a natural pinna high-frequency shadow (`-2.8 dB` above `5.5 kHz`) when sources move behind the nape of your neck (`+Z`), eliminating front-back headphone ambiguity.
   - **Stage 5 — Micro-Transient Shaper & Warm Triode/Tape Soft-Clipper (`tanh`)**: Brings out tactile scissor snips, bristle clicks, and ember pops without harsh digital clipping.
3. **Humanized Organic Sample Streamer (`OrganicSampleStreamer.swift`)**:
   - 4-point Hermite cubic-interpolated varispeed (`±4.5%` organic micro-pitch variation per trigger/pass), multi-slice round-robin windowing, and seamless equal-power cosine crossfaded looping eliminate loop seams and "machine-gun" sample repetition.
4. **Grounded Physical & Modal Synthesis (`ProceduralSynthesis.swift`)**:
   - Dispersive metallic waveguide modes for detail barber shears, 8-mode inharmonic modal resonators with natural beating doublets for singing bowls, cedar-soundboard coupled Karplus-Strong strings, and Velvet-Noise acoustic impact models.

---

## 🚀 Quick Start

### 1. Launch the Native macOS GUI

```bash
# Build and launch AudioToys.app
make run
# Or run the compiled binary directly:
./audiotoys
```

### 2. Run in the Terminal (Live ANSI Near-Field Radar)

```bash
# List all themes and layers
./audiotoys list

# Play the Barber Shop Haircut ASMR theme in your terminal:
./audiotoys play barber-shop

# Or play any other theme:
./audiotoys play tactile-study
./audiotoys play rain-on-skylight
./audiotoys play midnight-meadow
./audiotoys play celestial-orbits
./audiotoys play clockwork-attic
./audiotoys play nostromo
```

---

## 💈 Built-in Spatial & ASMR Themes

| Theme ID | Title | Description | Key Layers & DSP Profiles |
| :--- | :--- | :--- | :--- |
| `barber-shop` | **Barber Shop (ASMR)** | Binaural Haircut • Japanese Shears, Clippers, Mist & Brush | Japanese Steel Shears (`Crisp Steel Shears`), Detail Layering Snips, Cordless Rotary Clippers (`Warm Rotary Clippers`), Fine-Tooth Comb (`Velvet Brush & Comb`), Atomizer Water Mist (`Intimate ASMR`), Badger-Hair Neck Duster, Scalp Fingertip Massage |
| `tactile-study` | **Tactile Study (ASMR)** | Close-Mic Foley • Graphite Sketching, Page Turns, Wood Taps & Purr | Graphite Pencil Sketching, Crisp Book Page Turns, Hollow Hardwood Tapping, Bamboo Seed Rainstick, Sleeping Cat Purr |
| `rain-on-skylight` | **Rain on Skylight** | Real Window Rain, Crackling Hearth Wood & Rolling Thunder | Windowpane Rain Shower, Crackling Hearth Fire, Close Glass Droplets, Distant Horizon Thunder |
| `midnight-meadow` | **Midnight Meadow** | Woodland Brook, Nocturnal Crickets & Cedar Harp | Mossy Woodland Brook, Nocturnal Cricket Choir, Gentle Pine Breeze, Cedar Soundboard Harp |
| `celestial-orbits` | **Tibetan Sanctuary** | Hand-Hammered Singing Bowl, Koshi Chimes & Harmonium | 4.5" Tibetan Singing Bowl, Bamboo Koshi Wind Chimes, Modal Bronze Harmonics, Warm Harmonium Drone |
| `clockwork-attic` | **Clockwork Attic** | Antique Escapements, Crown Winding & Mechanical Music Box | Close Pocket Watch Tick, Crown Ratchet Winding, Corner Grandfather Clock, Wound-Up Music Box |
| `nostromo` | **Nostromo** | USCSS Commercial Freighter 180286 • Real Drive Seeks & Steam | Mechanical HDD Head Seeks, Platter Spindle Spin-Up, Pressurized Coolant Steam, Reactor Deck Sub-Rumble, MU-TH-UR Telemetry |

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
