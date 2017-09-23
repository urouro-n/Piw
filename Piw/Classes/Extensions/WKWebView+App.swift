//
//  WKWebView+App.swift
//  Pics
//
//  Created by Kenta on 2017/06/15.
//  Copyright © 2017 UROURO. All rights reserved.
//

import Foundation
import Kanna
import RealmSwift
import WebKit

extension AppExtension where Base: WKWebView {

    typealias ParseImageURLHandler = ([String]?) -> Void

    func parseImageURLs(completion: @escaping ParseImageURLHandler) {
        base.evaluateJavaScript("document.body.innerHTML") { (html, error) in
            guard let html = html else {
                log.error("Nothing html string. Error: \(String(describing: error))")
                completion(nil)
                return
            }

            guard let htmlString = html as? String else {
                log.error("Cannot cast html to string.")
                completion(nil)
                return
            }

            guard let doc = HTML(html: htmlString, encoding: .utf8) else {
                log.error("HTML cannot objectize.")
                completion(nil)
                return
            }

            var imageURLs: [String] = []

            for image in doc.css("img") {
                if let src = image["src"] {
                    if !imageURLs.contains(src) {
                        imageURLs.append(src)
                    }
                }
            }

            for anchor in doc.css("a") {
                if let image = anchor.xpath("img").first,
                    let src = image["src"] {
                    if let href = anchor["href"] {
                        if href.hasSuffix(".jpeg") ||
                            href.hasSuffix(".jpg") ||
                            href.hasSuffix(".png") ||
                            href.hasSuffix(".gif") {
                            for (i, url) in imageURLs.enumerated() {
                                if url == src {
                                    imageURLs.remove(at: i)
                                    break
                                }
                            }

                            if !imageURLs.contains(href) {
                                imageURLs.append(href)
                            }
                        } else {
                            if !imageURLs.contains(src) {
                                imageURLs.append(src)
                            }
                        }
                    } else {
                        if !imageURLs.contains(src) {
                            imageURLs.append(src)
                        }
                    }
                }
            }

            let filteredImageURLs = self.filter(URLs: imageURLs)
            completion(filteredImageURLs)
        }
    }

    private func filter(URLs: [String]) -> [String] {
        var filteredURLs: [String] = []
        let blackList = URLBlocker.blackList()

        // swiftlint:disable:next force_try
        let realm = try! Realm()
        let ignoreURLs = realm.objects(IgnoreURL.self)

        for url in URLs {
            if !isBlack(url, blackList) &&
                !isIgnored(url, ignoreURLs) {
                filteredURLs.append(url)
            }
        }

        return filteredURLs
    }

    private func isBlack(_ url: String, _ blackList: [String]) -> Bool {
        for blackURL in blackList {
            // log.debug("url=\(url), blackURL=\(blackURL)")
            if url.contains(blackURL) {
                return true
            }
        }

        return false
    }

    private func isIgnored(_ url: String, _ ignoreURLs: Results<IgnoreURL>) -> Bool {
        for ignoreURL in ignoreURLs {
            if ignoreURL.type == IgnoreURL.URLType.Full &&  url == ignoreURL.url {
                return true
            }
            if ignoreURL.type == IgnoreURL.URLType.Domain && url.contains(ignoreURL.url) {
                return true
            }
            if ignoreURL.type == IgnoreURL.URLType.Keyword && url.contains(ignoreURL.url) {
                return true
            }
        }

        return false
    }

}
