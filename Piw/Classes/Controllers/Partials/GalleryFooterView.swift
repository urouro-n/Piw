//
//  GalleryFooterView.swift
//  Pics
//
//  Created by Kenta on 2017/06/15.
//  Copyright © 2017年 UROURO. All rights reserved.
//

import UIKit

class GalleryFooterView: UIView {

    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!

    class func create() -> GalleryFooterView {
        // swiftlint:disable:next force_cast
        let view = Bundle.main.loadNibNamed("GalleryFooterView", owner: self, options: nil)?[0] as! GalleryFooterView

        view.menuButton.setTitle(nil, for: .normal)
        view.menuButton.setImage(UIImage.ionicon(with: .iosMore,
                                                 textColor: UIColor.black,
                                                 size: CGSize(width: 30.0, height: 30.0)),
                                 for: .normal)

        view.shareButton.setTitle(nil, for: .normal)
        view.shareButton.setImage(UIImage.ionicon(with: .iosUploadOutline,
                                                  textColor: UIColor.black,
                                                  size: CGSize(width: 30.0, height: 30.0)),
                                  for: .normal)

        return view
    }

}
