//
//  FileIOController.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation
struct JSONFileIO {
    var manager = FileManager.default

    func write<T: Encodable>(
        _ object: T,
        toDocumentNamed documentName: String,
        encodedUsing encoder: JSONEncoder = .init()
    ) throws {
        let rootFolderURL = try manager.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )

        let nestedFolderURL = rootFolderURL.appendingPathComponent("Lidar-Data")
        if !manager.fileExists(atPath: nestedFolderURL.relativePath) {
            try manager.createDirectory(
                at: nestedFolderURL,
                withIntermediateDirectories: false,
                attributes: nil
            )
        }
        let fileURL = nestedFolderURL.appendingPathComponent(documentName).appendingPathExtension("json")
        let data = try encoder.encode(object)
        try data.write(to: fileURL)
    }
    
    
    func read<T: Decodable>(
        _ type: T.Type,
        toDocumentNamed documentName: String,
        decodeUsing decoder: JSONDecoder = .init()
    )  throws -> T {
        let rootFolderURL = try manager.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )

        let nestedFolderURL = rootFolderURL.appendingPathComponent("Lidar-Data")
        let fileURL = nestedFolderURL.appendingPathComponent(documentName).appendingPathExtension("json")
        let jsonData = try Data(contentsOf: fileURL)
        let decodedData = try decoder.decode(type, from: jsonData)
        return decodedData
    }
}