//
//  ProgramShortcut.swift
//  Whisky
//
//  Created by Isaac Marovitz on 10/09/2023.
//

import Foundation
import AppKit
import QuickLookThumbnailing

class ProgramShortcut {
    public static func createShortcut(_ program: Program, app: URL, name: String) async {
        let contents = app.appending(path: "Contents")
        let macos = contents.appending(path: "MacOS")
        do {
            try FileManager.default.createDirectory(at: macos, withIntermediateDirectories: true)

            // First create shell script
            let script = """
            #!/bin/bash
            \(program.generateTerminalCommand())
            """
            let scriptUrl = macos.appending(path: "launch")
            try script.write(to: scriptUrl,
                             atomically: false,
                             encoding: .utf8)

            // Make shell script runable
            try FileManager.default.setAttributes([.posixPermissions: 0o777],
                                                  ofItemAtPath: scriptUrl.path(percentEncoded: false))

            // Create Info.plist (set category for Game mode)
            let info = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>CFBundleExecutable</key>
                <string>launch</string>
                <key>CFBundleSupportedPlatforms</key>
                <array>
                    <string>MacOSX</string>
                </array>
                <key>LSMinimumSystemVersion</key>
                <string>14.0</string>
                <key>LSApplicationCategoryType</key>
                <string>public.app-category.games</string>
            </dict>
            </plist>
            """
            try info.write(to: contents.appending(path: "Info")
                                       .appendingPathExtension("plist"),
                           atomically: false,
                           encoding: .utf8)

            // Set bundle icon
            let request = QLThumbnailGenerator.Request(fileAt: program.url,
                                                       size: CGSize(width: 512, height: 512),
                                                       scale: 2.0,
                                                       representationTypes: .thumbnail)
            let thumbnail = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            NSWorkspace.shared.setIcon(thumbnail.nsImage,
                                       forFile: app.path(percentEncoded: false),
                                       options: NSWorkspace.IconCreationOptions())
            NSWorkspace.shared.activateFileViewerSelecting([app])
        } catch {
            print(error)
        }
    }
}
