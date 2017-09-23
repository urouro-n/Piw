//
//  Bookmark.swift
//  Pics
//
//  Created by Kenta on 2017/06/16.
//  Copyright © 2017 UROURO. All rights reserved.
//

import Foundation
import RealmSwift

class Bookmark: Object {

    dynamic var bookmarkID: String = UUID().uuidString
    dynamic var url: String = ""
    dynamic var order: Int = 0

    override static func primaryKey() -> String? {
        return "bookmarkID"
    }

}
