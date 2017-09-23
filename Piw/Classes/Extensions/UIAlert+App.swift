//
//  UIAlert+App.swift
//  Pics
//
//  Created by Kenta on 6/27/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import NativePopup
import UIKit

extension AppExtension where Base: UIViewController {

    func showAlert(title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        base.present(alert, animated: true, completion: nil)
    }

    func showFeedback(title: String? = nil, success: Bool = true) {
        NativePopup.show(image: success ? Preset.Feedback.done : Preset.Feedback.cross,
                         title: title,
                         message: nil,
                         initialEffectType: .fadeIn)
    }

    func alertDisablingMobileNetwork(okHandler: (() -> Void)? = nil) {
        let title = "モバイルネットワークで画像ダウンロードを行う場合は、左上の設定メニューから設定を変更してください"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            if let okHandler = okHandler {
                okHandler()
            }
        }))
        base.present(alert, animated: true, completion: nil)
    }

}
