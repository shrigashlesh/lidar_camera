//
//  FileIOController.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation
struct BinaryFileIO {
    var manager = FileManager.default

    func write(
        _ data: Data,
        folder folderName: String,
        toDocumentNamed documentName: String
    ) throws {
        let rootFolderURL = try manager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )

        let nestedFolderURL = rootFolderURL.appendingPathComponent(folderName)
        if !manager.fileExists(atPath: nestedFolderURL.relativePath) {
            try manager.createDirectory(
                at: nestedFolderURL,
                withIntermediateDirectories: false,
                attributes: nil
            )
        }
        let fileURL = nestedFolderURL.appendingPathComponent(documentName).appendingPathExtension("bin")
        try data.write(to: fileURL)
    }
    
    func read(
           folder folderName: String,
           fromDocumentNamed documentName: String
       ) throws -> Data {
           let rootFolderURL = try manager.url(
               for: .documentDirectory,
               in: .userDomainMask,
               appropriateFor: nil,
               create: false
           )

           let nestedFolderURL = rootFolderURL.appendingPathComponent(folderName)
           let fileURL = nestedFolderURL.appendingPathComponent(documentName).appendingPathExtension("bin")
           let data = try Data(contentsOf: fileURL)
           return data
       }
}
