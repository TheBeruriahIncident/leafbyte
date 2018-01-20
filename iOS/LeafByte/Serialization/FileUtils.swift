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

func getUrlForInvisibleFiles() -> URL {
    return FileManager().urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
}
