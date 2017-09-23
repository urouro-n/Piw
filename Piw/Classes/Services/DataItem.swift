//
//  DataItem.swift
//  Pics
//
//  Created by Kenta on 9/6/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import Foundation
import ImageViewer

struct DataItem {

    let imageURL: URL
    let rawURL: URL
    let galleryItem: GalleryItem

    init(imageURL: URL, rawURL: URL, galleryItem: GalleryItem) {
        self.imageURL = imageURL
        self.rawURL = rawURL
        self.galleryItem = galleryItem
    }

}
