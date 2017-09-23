//
//  URLBlocker.swift
//  Pics
//
//  Created by Kenta on 2017/06/15.
//  Copyright © 2017 UROURO. All rights reserved.
//

import UIKit
import WebKit

class URLBlocker {

    class func blockerScript() -> WKUserScript {
        let list = URLBlocker.blackList()
        var source = ""

        // TODO: Move to external config file
        let excludesClassNames: [String] = [
            "sp_ad",
            "ad1",
            "ad2",
            "-ad",
            "admax-banner"
        ]

        // swiftlint:disable line_length
        source += "var elms = document.querySelectorAll(\"[id='ad']\"); for (var i = 0; i < elms.length; i++) { elms[i].style.display = \"none\"; }"
        source += "var elms = document.querySelectorAll(\"[id*='imobile_adspot']\"); for (var i = 0; i < elms.length; i++) { elms[i].style.display = \"none\"; }"

        for excludeClassName in excludesClassNames {
            source += "var elms = document.querySelectorAll(\"[class*='" + excludeClassName + "']\"); for (var i = 0; i < elms.length; i++) { elms[i].style.display = \"none\"; }"
        }
        for excludeString in list {
            source += "var elms = document.querySelectorAll(\"a[href*='" + excludeString + "']\"); for (var i = 0; i < elms.length; i++) { elms[i].style.display = \"none\"; }"
            source += "var elms = document.querySelectorAll(\"img[src*='" + excludeString + "']\"); for (var i = 0; i < elms.length; i++) { elms[i].style.display = \"none\"; }"
            source += "var elms = document.querySelectorAll(\"iframe[src*='" + excludeString + "']\"); for (var i = 0; i < elms.length; i++) { elms[i].style.display = \"none\"; }"

        }
        // swiftlint:enable line_length

        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        return script
    }

    class func blackList () -> [String] {
        guard let path = Bundle.main.path(forResource: "BlackList", ofType: "txt") else {
            log.warning("Nothing file BlackList.txt.")
            return []
        }

        do {
            let content = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
            return content.components(separatedBy: "\n")
        } catch {
            log.error("Error: \(error)")
            return []
        }
    }

}
