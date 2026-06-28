//
//  TerminalOpener.swift
//  JobsTerminalFinderSync
//
//  Created by Jobs on 2026年6月28日，星期日.
//

import AppKit

struct TerminalOpener {
    func openTerminal(from fileURL: URL) throws -> URL {
        let standardizedURL = fileURL.standardizedFileURL
        guard standardizedURL.isFileURL else {
            throw TerminalOpenError.unsupportedURL(fileURL)
        }

        let directoryURL = terminalWorkingDirectory(from: standardizedURL)
        let commandURL = try temporaryCommandURL(directoryURL: directoryURL)
        let terminalURL = try terminalApplicationURL()
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open(
            [commandURL],
            withApplicationAt: terminalURL,
            configuration: configuration,
            completionHandler: nil
        );return directoryURL
    }
}

private extension TerminalOpener {
    enum TerminalOpenError: LocalizedError {
        case unsupportedURL(URL)
        case missingTerminal
        case commandScriptFailed(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedURL(let url):
                return "不是本地文件路径：\(url.absoluteString)"
            case .missingTerminal:
                return "没有找到系统 Terminal.app"
            case .commandScriptFailed(let message):
                return message
            }
        }
    }

    func terminalWorkingDirectory(from fileURL: URL) -> URL {
        if let values = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey]),
           values.isDirectory == true,
           values.isPackage != true {
            return fileURL
        };return fileURL.deletingLastPathComponent()
    }

    func terminalApplicationURL() throws -> URL {
        if let terminalURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") {
            return terminalURL
        }

        let candidateURLs = [
            URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app", isDirectory: true),
            URL(fileURLWithPath: "/Applications/Utilities/Terminal.app", isDirectory: true)
        ]

        for candidateURL in candidateURLs where FileManager.default.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        throw TerminalOpenError.missingTerminal
    }

    func temporaryCommandURL(directoryURL: URL) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("JobsTerminalOpener", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw TerminalOpenError.commandScriptFailed("创建临时脚本目录失败：\(error.localizedDescription)")
        }

        let commandURL = directory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("command")
        let command = """
        #!/bin/zsh
        cd \(shellQuoted(directoryURL.path)) || exit 1
        exec "${SHELL:-/bin/zsh}" -l
        """

        do {
            try command.write(to: commandURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: commandURL.path)
            return commandURL
        } catch {
            throw TerminalOpenError.commandScriptFailed("写入临时启动脚本失败：\(error.localizedDescription)")
        }
    }

    func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
