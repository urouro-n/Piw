//
//  IgnoreURL.swift
//  Pics
//
//  Created by Kenta on 6/27/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import Foundation
import RealmSwift

class IgnoreURL: Object {

    dynamic var url: String = ""
    dynamic var type = 0

    struct URLType {
        static let Full: Int = 0
        static let Domain: Int = 1
        static let Keyword: Int = 2
    }

}
