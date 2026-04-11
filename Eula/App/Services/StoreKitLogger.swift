import Foundation

class StoreKitLogger {
    static let shared = StoreKitLogger()
    
    private let fileManager = FileManager.default
    private let logFileName = "storekit.log"
    private let maxFileSize: Int64 = 5 * 1024 * 1024
    private let maxBackupFiles = 3
    
    private var logFileURL: URL {
        let logsDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Logs", isDirectory: true)
        
        if !fileManager.fileExists(atPath: logsDirectory.path) {
            try? fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        }
        
        return logsDirectory.appendingPathComponent(logFileName)
    }
    
    private init() {}
    
    func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(timestamp)] [\(fileName):\(line)] \(message)\n"
        
        #if DEBUG
        print("[StoreKit] \(message)")
        #endif
        
        writeToLogFile(logMessage)
    }
    
    private func writeToLogFile(_ message: String) {
        checkAndRotateLogFile()
        
        guard let data = message.data(using: .utf8) else { return }
        
        if fileManager.fileExists(atPath: logFileURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                try? fileHandle.close()
            }
        } else {
            try? data.write(to: logFileURL)
        }
    }
    
    private func checkAndRotateLogFile() {
        guard let attributes = try? fileManager.attributesOfItem(atPath: logFileURL.path),
              let fileSize = attributes[.size] as? Int64,
              fileSize > maxFileSize else {
            return
        }
        
        rotateLogFiles()
    }
    
    private func rotateLogFiles() {
        let logsDirectory = logFileURL.deletingLastPathComponent()
        
        for i in stride(from: maxBackupFiles - 1, through: 1, by: -1) {
            let oldFile = logsDirectory.appendingPathComponent("storekit.\(i).log")
            let newFile = logsDirectory.appendingPathComponent("storekit.\(i + 1).log")
            
            if fileManager.fileExists(atPath: oldFile.path) {
                try? fileManager.moveItem(at: oldFile, to: newFile)
            }
        }
        
        let backupFile = logsDirectory.appendingPathComponent("storekit.1.log")
        try? fileManager.moveItem(at: logFileURL, to: backupFile)
    }
    
    func getLogFilePath() -> URL {
        return logFileURL
    }
    
    func getAllLogFileURLs() -> [URL] {
        let logsDirectory = logFileURL.deletingLastPathComponent()
        var logFiles: [URL] = [logFileURL]
        
        for i in 1...maxBackupFiles {
            let backupFile = logsDirectory.appendingPathComponent("storekit.\(i).log")
            if fileManager.fileExists(atPath: backupFile.path) {
                logFiles.append(backupFile)
            }
        }
        
        return logFiles.sorted { $0.path > $1.path }
    }
    
    func readLogFile() -> String? {
        return try? String(contentsOf: logFileURL, encoding: .utf8)
    }
    
    func clearLogs() {
        let logsDirectory = logFileURL.deletingLastPathComponent()
        
        try? fileManager.removeItem(at: logFileURL)
        
        for i in 1...maxBackupFiles {
            let backupFile = logsDirectory.appendingPathComponent("storekit.\(i).log")
            try? fileManager.removeItem(at: backupFile)
        }
    }
    
    func exportLogs() -> URL? {
        let logsDirectory = logFileURL.deletingLastPathComponent()
        let exportFile = logsDirectory.appendingPathComponent("storekit_export_\(Date().timeIntervalSince1970).log")
        
        var allLogs = ""
        let logFiles = getAllLogFileURLs().reversed()
        
        for logFile in logFiles {
            if let content = try? String(contentsOf: logFile, encoding: .utf8) {
                allLogs += "=== \(logFile.lastPathComponent) ===\n"
                allLogs += content
                allLogs += "\n\n"
            }
        }
        
        do {
            try allLogs.write(to: exportFile, atomically: true, encoding: .utf8)
            return exportFile
        } catch {
            return nil
        }
    }
}

extension StoreKitLogger {
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("ℹ️ \(message)", file: file, function: function, line: line)
    }
    
    func success(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("✅ \(message)", file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("⚠️ \(message)", file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("❌ \(message)", file: file, function: function, line: line)
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("🔍 \(message)", file: file, function: function, line: line)
    }
}
