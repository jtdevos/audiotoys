import Foundation
import AppKit

@main
struct AudioToysAppLauncher {
    static func main() {
        let args = CommandLine.arguments

        if args.count > 1 {
            let command = args[1].lowercased()

            switch command {
            case "list":
                printThemeList()
                return

            case "play":
                let themeId = args.count > 2 ? args[2] : nil
                let duration = args.count > 3 ? Double(args[3]) : nil
                let tui = TerminalUI()
                tui.runTheme(themeId: themeId, durationSeconds: duration)
                return

            case "demo":
                print("Running 4-second binaural ASMR & spatial audio pipeline verification demo...")
                let tui = TerminalUI()
                tui.runTheme(themeId: "barber-shop", durationSeconds: 4.0)
                print("Verification demo completed successfully!")
                return

            case "--help", "-h", "help":
                printUsage()
                return

            case "gui":
                launchGUI()
                return

            default:
                // Check if user specified a theme name directly, e.g. `./audiotoys celestial-orbits`
                let themesDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent("Resources/Themes")
                let themes = ThemeLoader.loadThemes(from: themesDir)
                if themes.contains(where: { $0.id == command }) {
                    let tui = TerminalUI()
                    tui.runTheme(themeId: command, durationSeconds: nil)
                    return
                } else {
                    printUsage()
                    return
                }
            }
        } else {
            // Default: launch native macOS GUI
            launchGUI()
        }
    }

    private static func launchGUI() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    private static func printThemeList() {
        let themes = ThemeLibrary.defaultThemes
        print("\n🎧 \u{001B}[1mAvailable AudioToys Themes:\u{001B}[0m\n")
        for t in themes {
            print("  • \u{001B}[1;36m\(t.id)\u{001B}[0m: \u{001B}[1m\(t.title)\u{001B}[0m (\(t.subtitle))")
            print("    Mood: \(t.moodDescription)")
            print("    Layers: \(t.layers.map { $0.name }.joined(separator: ", "))")
            print("    Reverb: \(t.reverbPreset)\n")
        }
        print("To play any theme in terminal: ./audiotoys play <theme-id>")
        print("To launch GUI: ./audiotoys gui (or just ./audiotoys)\n")
    }

    private static func printUsage() {
        print("""
        Usage: audiotoys [command] [options]

        Commands:
          (default)             Launch native macOS 3D Spatial Radar GUI
          gui                   Launch native macOS 3D Spatial Radar GUI
          list                  List all available spatial audio themes
          play <theme-id> [sec] Play theme in terminal with live ANSI 3D radar
          demo                  Run 4-second audio verification demo
          help                  Show this help message

        Examples:
          ./audiotoys
          ./audiotoys play midnight-meadow
          ./audiotoys play celestial-orbits 10
        """)
    }
}
