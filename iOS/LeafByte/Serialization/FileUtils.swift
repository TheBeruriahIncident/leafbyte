//
//  FileUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/20/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Foundation

func getUrlForVisibleFiles() -> URL {
    return FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
}

func getUrlForVisibleFolder(named folderName: String) -> URL {
    let url = getUrlForVisibleFiles().appendingPathComponent(folderName)
    if !FileManager().fileExists(atPath: url.path) {
        try! FileManager().createDirectory(at: url, withIntermediateDirectories: false)
    }
    
    return url
}

func getUrlForInvisibleFiles() -> URL {
    return FileManager().urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
}

func initializeFileIfNonexistant(_ url: URL, withData data: Data) {
    if !FileManager().fileExists(atPath: url.path) {
        try! data.write(to: url)
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
