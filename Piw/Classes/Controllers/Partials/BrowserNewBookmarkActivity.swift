//
//  BrowserNewBookmarkActivity.swift
//  Pics
//
//  Created by Kenta on 7/19/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import RealmSwift
import UIKit

class BrowserNewBookmarkActivity: UIActivity {

    override var activityTitle: String? {
        return "ブックマークに追加"
    }

    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "net.urouro.piw.addBookmark")
    }

    override var activityImage: UIImage? {
        return UIImage.ionicon(with: .plusRound,
                               textColor: UIColor.black,
                               size: CGSize(width: 43.0, height: 43.0))
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if let string = item as? String, URL(string: string) != nil {
                return true
            }
            if (item as? URL) != nil {
                return true
            }
        }

        return false
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        // swiftlint:disable:next force_try
        let realm = try! Realm()
        let bookmarks = realm.objects(Bookmark.self)
        var added = 0

        for item in activityItems {
            let url: URL
            if let string = item as? String, let castURL = URL(string: string) {
                url = castURL
            } else if let castURL = item as? URL {
                url = castURL
            } else {
                continue
            }

            let bookmark = Bookmark()
            bookmark.url = url.absoluteString
            bookmark.order = bookmarks.count + added

            // swiftlint:disable:next force_try
            try! realm.write {
                realm.add(bookmark)
            }

            added += 1
        }
    }

}
