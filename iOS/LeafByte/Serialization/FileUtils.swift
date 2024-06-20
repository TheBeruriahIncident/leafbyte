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
    // swiftlint:disable:next force_unwrapping
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
    // there should always be an app support directory
    FileManager().urls(for: .applicationSupportDirectory, in: .userDomainMask).first! // swiftlint:disable:this force_unwrapping
}

// Throws if creating the file fails
func initializeFileIfNonexistant(_ url: URL, withData data: Data) throws {
    if !FileManager().fileExists(atPath: url.path) {
        try data.write(to: url)
    }
}

func appendToFile(_ url: URL, data: Data) throws {
    let fileHandle = try FileHandle(forWritingTo: url)
    defer {
        fileHandle.closeFile()
    }

    fileHandle.seekToEndOfFile()
    fileHandle.write(data)
}
