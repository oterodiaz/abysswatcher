//
//  abysswatcher.swift
//  AbyssWatcher
//
//  Created by Otero Díaz on 2023-02-28.
//

import Cocoa

@main
public struct AbyssWatcher {
    public static func main() {
        let script = parseArguments()

        // Run the user's script
        runProcess(path: script)

        // Add an observer to re-run the script whenever the system's theme changes
        DistributedNotificationCenter
            .default()
            .addObserver(forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
                         object:  nil,
                         queue:   nil
            ) { _ in
                runProcess(path: script)
            }

        // Add an observer to re-run the script if the system's theme changed during sleep
        // (i.e. closed lid)
        NSWorkspace
            .shared
            .notificationCenter
            .addObserver(forName: NSWorkspace.didWakeNotification,
                         object:  nil,
                         queue:   nil
            ) { _ in
                runProcess(path: script)
            }

        NSApplication.shared.run()
    }

    /// Run a user-provided script whenever the system's theme changes.
    ///
    /// The script will be run with the DARK\_MODE environment variable set to 1 when the system is in dark mode,
    /// or with the variable unset if in light mode.
    ///
    /// - Finding the current system theme from within a POSIX shell script:
    /// ```shell
    /// if [ -n "${DARK_MODE+set}" ]; then
    ///     # System is in dark mode
    /// else
    ///     # System is in light mode
    /// fi
    /// ```
    private static func runProcess(path script: [String]) {
        let isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        let process = Process()

        // Set or unset the DARK_MODE environment variable
        var env = ProcessInfo.processInfo.environment
        env["DARK_MODE"] = isDark ? "1" : nil

        process.arguments = script
        process.environment = env
        process.executableURL = URL(string: "file:///usr/bin/env")
        process.standardError = FileHandle.standardError
        process.standardOutput = FileHandle.standardOutput

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("There was an error running the script. Maybe the path is incorrect?")
            exit(1)
        }
    }

    private static func parseArguments() -> [String] {
        var arguments = CommandLine.arguments
        let programName = (arguments.remove(at: 0) as NSString).lastPathComponent
        guard arguments.count >= 1 else {
            printHelp(programName: programName)
            exit(1)
        }

        if arguments[0] == "-h" || arguments[0] == "--help" {
            printHelp(programName: programName)
            exit(0)
        }

        var script_path = arguments.remove(at: 0)
        if script_path.contains("~") {
            script_path = (script_path as NSString).expandingTildeInPath
        }

        return [script_path] + arguments
    }

    private static func printHelp(programName: String) {
        print("Usage: \(programName) [-h, --help] [path to script]\n")
        print("Watch for system theme changes and run a script in response.")
        print("Options:")
        print("-h, --help: Show usage information")
    }
}
