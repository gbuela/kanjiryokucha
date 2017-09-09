//
//  DebugLogsManager.swift
//  KanjiRyokucha
//
//  Created by German Buela on 8/22/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation

struct DebugLogsManager {
    
    private let fileName = "krlogs.txt"
    
    func readLogs() -> String {
        if let path = logUrl()  {
            return (try? String(contentsOf: path)) ?? ""
        }
        return ""
    }
    
    func write(log: String) {
        let dump = readLogs()
        
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd H:m:ss.SSSS"
        
        let date = df.string(from: Date())

        if let path = logUrl()  {
            do {
                try "\(dump)\n\(date): \(log)".write(to: path, atomically: true, encoding: .utf8)
            } catch {
                print("Failed writing log: \(error.localizedDescription)")
            }
        }
    }
    
    func clear() {
        if let path = logUrl()  {
            try? FileManager.default.removeItem(at: path)
        }
    }
    
    private func logUrl() -> URL? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            
        return dir?.appendingPathComponent(fileName)
    }
}
