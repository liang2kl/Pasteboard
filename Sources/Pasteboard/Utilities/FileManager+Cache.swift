//
//  FileManager+createTempFile.swift
//  Pasteboard
//
//  Created by liang2kl on 2021/8/3.
//

import Foundation

extension FileManager {
    
    func createTempFile(contents: Data) -> URL? {
        let cachesDirectory = self.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let path = cachesDirectory.appendingPathComponent("\(UUID())")
        if self.createFile(atPath: path.path, contents: contents, attributes: nil) {
            return path
        }
        return nil
    }
    
    func removeCache() {
        let cachesDirectory = self.urls(for: .cachesDirectory, in: .userDomainMask).first!
        guard let urls = try? self.contentsOfDirectory(atPath: cachesDirectory.path) else { return }
        urls.map { cachesDirectory.appendingPathComponent($0) }.forEach { try? removeItem(at: $0) }
    }
}
