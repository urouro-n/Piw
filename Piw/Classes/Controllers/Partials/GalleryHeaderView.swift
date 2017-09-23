//
//  GalleryHeaderView.swift
//  Pics
//
//  Created by Kenta on 6/27/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import UIKit

class GalleryHeaderView: UIView {

    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var sizeLabel: UILabel!

    var currentIndex: Int = 0 {
        didSet {
            let text = String(format: "%d of %d", arguments: [currentIndex + 1, max])

            if counterLabel != nil {
                counterLabel.text = text
            }
        }
    }
    private var max: Int = 0

    var imageSize: CGSize? {
        didSet {
            let text: String

            if let imageSize = imageSize {
                text = String(format: "%.0f x %.0f",
                              arguments: [imageSize.width, imageSize.height])
            } else {
                text = ""
            }

            if sizeLabel != nil {
                sizeLabel.text = text
            }
        }
    }

    class func create(max: Int, currentIndex: Int = 0) -> GalleryHeaderView {
        // swiftlint:disable:next force_cast
        let view = Bundle.main.loadNibNamed("GalleryHeaderView", owner: self, options: nil)?[0] as! GalleryHeaderView

        view.currentIndex = currentIndex
        view.max = max

        return view
    }

}
