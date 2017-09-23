//
//  ImageManager.swift
//  Pics
//
//  Created by Kenta on 7/13/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import UIKit

class ImageManager {

    class var baseURL: URL {
        // return documentDirectoryURL().appendingPathComponent("images")
        return documentDirectoryURL()
    }

    // swiftlint:disable:next identifier_name
    class func save(_ image: UIImage, via url_: URL, completion: ((Bool) -> Void)? = nil) {
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        var url: URL = url_

        do {
            try FileManager.default.createDirectory(at: baseURL,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            log.error("Cannot create directory. Error: \(error)")

            if let completion = completion {
                completion(false)
            }
            return
        }

        if url.pathExtension == "" {
            url.appendPathExtension("jpg")
        }

        let fileName = url.lastPathComponent
        var imagePath = baseURL.appendingPathComponent(fileName)

        var renamedCount = 0
        while FileManager.default.fileExists(atPath: imagePath.path) {
            renamedCount += 1
            let ext = url.pathExtension.characters.count > 0 ? "." + url.pathExtension : ""
            let renamedName = fileName.replacingOccurrences(of: ext, with: "")
                + "-" + String(renamedCount) + ext
            imagePath = baseURL.appendingPathComponent(renamedName)
        }

        do {
            try imageData?.write(to: imagePath, options: .atomicWrite)
        } catch {
            log.error("Error: \(error)")

            if let completion = completion {
                completion(false)
            }
            return
        }

        if let completion = completion {
            completion(true)
        }
    }

    class func moveImagesInSharedContainerToAppContainer() {
        guard let containerURL = FileManager
            .default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.net.urouro.piw") else {
                fatalError("Unexpected")
        }

        let containerImageURL = containerURL.appendingPathComponent("images")

        let contents: [String]
        do {
            contents = try FileManager
                .default
                .contentsOfDirectory(atPath: containerImageURL.path)
        } catch {
            log.error("Cannot find images directory on containerURL. Error: \(error)")
            return
        }

        log.debug("contents=\(contents)")

        for content in contents {
            let url = containerImageURL.appendingPathComponent(content)

            guard let image = UIImage(contentsOfFile: url.path) else {
                log.warning("Not a image. URL: \(url)")
                continue
            }

            ImageManager.save(image, via: url, completion: { result in
                if result == true {
                    do {
                        try FileManager.default.removeItem(at: url)
                    } catch {
                        log.warning("Cannot remove a image file. URL: \(url), Error: \(error)")
                    }
                }
            })
        }
    }

}
