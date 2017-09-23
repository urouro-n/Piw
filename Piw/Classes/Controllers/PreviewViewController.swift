//
//  PreviewViewController.swift
//  Pics
//
//  Created by Kenta on 7/18/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import AudioToolbox
import EasyTipView
import ImageViewer
import Kingfisher
import RealmSwift
import RxSwift
import UIKit

protocol PreviewDataSource: GalleryItemsDataSource {
    func previewItem(at index: Int) -> DataItem
}

protocol PreviewDelegate: GalleryItemsDelegate {}

class PreviewViewController: GalleryViewController {

    var url: URL?

    fileprivate lazy var footer: UIView = {
        return GalleryFooterView.create()
    }()
    fileprivate var header: GalleryHeaderView?
    fileprivate var previewDataSource: PreviewDataSource?
    fileprivate var previewDelegate: PreviewDelegate?
    fileprivate var asFileBrowser: Bool = false

    let disposeBag: DisposeBag = DisposeBag()

    private static let configuration: GalleryConfiguration = [
        GalleryConfigurationItem.deleteButtonMode(.none),
        GalleryConfigurationItem.thumbnailsButtonMode(.none),
        GalleryConfigurationItem.swipeToDismissMode(.vertical)
    ]

    // swiftlint:disable:next function_body_length
    class func create(items: [DataItem],
                      dataSource: PreviewDataSource,
                      delegate: PreviewDelegate? = nil,
                      startIndex: Int = 0) -> PreviewViewController {
        let controller = PreviewViewController(startIndex: startIndex,
                                            itemsDataSource: dataSource,
                                            itemsDelegate: delegate,
                                            configuration: configuration)
        let header = GalleryHeaderView.create(max: items.count)

        controller.previewDataSource = dataSource
        controller.previewDelegate = delegate
        controller.header = header
        controller.headerView = header
        controller.footerView = controller.footer

        controller.landedPageAtIndexCompletion = { index in
            controller.header?.currentIndex = index
            controller.header?.imageSize = nil

            guard let item = controller.previewDataSource?.previewItem(at: index) else {
                return
            }

            ImageDownloader
                .default
                .downloadImage(with: item.imageURL,
                               options: [],
                               progressBlock: nil) { image, _, _, _ in
                                if let image = image {
                                    controller.header?.imageSize = image.size
                                }
            }
        }

        if let footer = controller.footer as? GalleryFooterView {
            footer.menuButton.rx.tap
                .subscribe(onNext: {
                    guard let item = controller.previewDataSource?.previewItem(at: controller.currentIndex) else {
                        return
                    }

                    let urlString = item.rawURL.absoluteString
                    let action = UIAlertController(title: urlString,
                                                   message: nil,
                                                   preferredStyle: .actionSheet)
                    action.addAction(UIAlertAction(title: "この画像を非表示", style: .default, handler: { _ in
                        // swiftlint:disable:next force_try
                        let realm = try! Realm()
                        let ignoreURL = IgnoreURL()
                        ignoreURL.url = urlString
                        ignoreURL.type = IgnoreURL.URLType.Full
                        // swiftlint:disable:next force_try
                        try! realm.write {
                            realm.add(ignoreURL)
                        }
                    }))

                    if let host = item.rawURL.host {
                        action.addAction(UIAlertAction(title: host + " の画像を非表示", style: .default, handler: { _ in
                            // swiftlint:disable:next force_try
                            let realm = try! Realm()
                            let ignoreURL = IgnoreURL()
                            ignoreURL.url = host
                            ignoreURL.type = IgnoreURL.URLType.Domain
                            // swiftlint:disable:next force_try
                            try! realm.write {
                                realm.add(ignoreURL)
                            }
                        }))
                    }

                    action.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
                    action.popoverPresentationController?.sourceView = controller.view
                    action.popoverPresentationController?.sourceRect = CGRect(
                        x: footer.frame.origin.x + footer.menuButton.frame.origin.x,
                        y: footer.frame.origin.y,
                        width: footer.menuButton.frame.size.width,
                        height: footer.menuButton.frame.size.height
                    )

                    controller.present(action, animated: true, completion: nil)
                })
                .addDisposableTo(controller.disposeBag)
            footer.shareButton.rx.tap
                .subscribe(onNext: {
                    if let url = controller.url {
                        controller.share(page: url)
                    }
                })
                .addDisposableTo(controller.disposeBag)
        }

        return controller
    }

    func downloadCurrentImage() {
        guard let item = previewDataSource?.previewItem(at: currentIndex) else {
            return
        }

        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

        let url = item.imageURL
        ImageDownloader
            .default
            .downloadImage(with: url, options: [], progressBlock: nil) { [weak self] image, _, url, _ in
                guard let image = image, let url = url else {
                    log.warning("image or url is nil.")
                    return
                }

                ImageManager.save(image, via: url) { result in
                    if result == false {
                        let alert = UIAlertController(title: "保存に失敗", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self?.present(alert, animated: true, completion: nil)
                    }
                }
        }
    }

    func deleteCurrentImage() {
        let action = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        action.addAction(UIAlertAction(title: "削除する", style: .destructive, handler: { [weak self] _ in
            if let `self` = self {
                self.previewDelegate?.removeGalleryItem(at: self.currentIndex)
            }
        }))
        action.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        present(action, animated: true, completion: nil)
    }

    func share(page: URL) {
        let action = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        action.addAction(UIAlertAction(title: "Safariで開く", style: .default, handler: { _ in
            if UIApplication.shared.canOpenURL(page) {
                UIApplication.shared.open(page, options: [:], completionHandler: nil)
            }
        }))
        action.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        present(action, animated: true, completion: nil)
    }

}

// MARK: - EasyTipViewDelegate
extension PreviewViewController: EasyTipViewDelegate {

    func easyTipViewDidDismiss(_ tipView: EasyTipView) {
        UserDefaultsHandler.ShowedDownloadImageTooltip.set(true)
    }

}
