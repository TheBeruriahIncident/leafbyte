//
//  FileUtils.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/20/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import Foundation

// These functions refer to visible and invisible files: this refers to visibility to the end user.
// E.g. the end user should see saved data, but not the settings file.

func getUrlForVisibleFiles() -> URL {
    FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
}

// Throws if creating the directory fails
func getUrlForVisibleFolder(named folderName: String) throws -> URL {
    let url = getUrlForVisibleFiles().appendingPathComponent(folderName)
    if !FileManager().fileExists(atPath: url.path) {
        try FileManager().createDirectory(at: url, withIntermediateDirectories: false)
    }

    return url
}

func getUrlForInvisibleFiles() -> URL {
    FileManager().urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
}

// Throws if creating the file fails
func initializeFileIfNonexistant(_ url: URL, withData data: Data) throws {
    if !FileManager().fileExists(atPath: url.path) {
        try data.write(to: url)
    }
}

func appendToFile(_ url: URL, data: Data) {
    let fileHandle = FileHandle(forWritingAtPath: url.path)!
    defer {
        fileHandle.closeFile()
    }

    fileHandle.seekToEndOfFile()
    fileHandle.write(data)
}
