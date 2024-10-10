//
//  FileIOController.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation

struct BinaryFileIO {
    var manager = FileManager.default
    func folderExists(folder folderName: String) throws -> Bool {
          let rootFolderURL = try manager.url(
              for: .documentDirectory,
              in: .userDomainMask,
              appropriateFor: nil,
              create: false
          )

          let nestedFolderURL = rootFolderURL.appendingPathComponent(folderName)
          return manager.fileExists(atPath: nestedFolderURL.relativePath)
      }
    
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
       ) throws -> (Data, URL) {
           let rootFolderURL = try manager.url(
               for: .documentDirectory,
               in: .userDomainMask,
               appropriateFor: nil,
               create: false
           )

           let nestedFolderURL = rootFolderURL.appendingPathComponent(folderName)
           let fileURL = nestedFolderURL.appendingPathComponent(documentName).appendingPathExtension("bin")
           let data = try Data(contentsOf: fileURL)
           return (data, fileURL)
       }
    
    
    func deleteFolder(folder folderName: String) throws {
            let rootFolderURL = try manager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            
            let nestedFolderURL = rootFolderURL.appendingPathComponent(folderName)
            
            // Check if folder exists before attempting deletion
            if manager.fileExists(atPath: nestedFolderURL.relativePath) {
                // Recursively delete the folder and its contents
                try manager.removeItem(at: nestedFolderURL)
            } else {
                throw NSError(domain: "lidar_plugin", code: 404, userInfo: [NSLocalizedDescriptionKey: "Folder not found"])
            }
        }
}
