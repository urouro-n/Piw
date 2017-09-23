//
//  HomeViewController.swift
//  Pics
//
//  Created by Kenta on 2017/06/08.
//  Copyright © 2017 UROURO. All rights reserved.
//

import EasyTipView
import GoogleMobileAds
import MBProgressHUD
import Reachability
import RealmSwift
import RxSwift
import UIKit
import Zip

class HomeViewController: UIViewController {

    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var newSiteButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var adBannerView: GADBannerView!

    fileprivate lazy var settingsButton: UIBarButtonItem = {
        let image = UIImage.ionicon(with: .iosGearOutline,
                                    textColor: UIColor.black,
                                    size: CGSize(width: 30.0, height: 30.0))
        let button = UIBarButtonItem(image: image,
                               style: .plain,
                               target: nil,
                               action: nil)
        return button
    }()

    fileprivate var newSiteTextField: UITextField?

    let disposeBag = DisposeBag()

    fileprivate var bookmarks: Results<Bookmark>?

}

// MARK: - View Lifecycles
extension HomeViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        newSiteButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.addNewSite()
            })
            .addDisposableTo(disposeBag)
        settingsButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showSettings()
            })
            .addDisposableTo(self.disposeBag)

        configureUI()

        adBannerView.adUnitID = AppConfig.AdMob.adUnitId
        adBannerView.rootViewController = self
        adBannerView.load(AppConfig.AdMob.request)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reload()

        let r = Reachability()!

        if !UserDefaultsHandler.GuidedMobileNetworkDefaultIsDisabled.get() &&
            !UserDefaultsHandler.EnableMobileNetwork.get() &&
            r.currentReachabilityStatus == .reachableViaWWAN {
            app.alertDisablingMobileNetwork {
                UserDefaultsHandler.GuidedMobileNetworkDefaultIsDisabled.set(true)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !UserDefaultsHandler.ShowedStartBrowseTooltip.get() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let `self` = self else { return }

                var preferences = EasyTipView.globalPreferences
                preferences.animating.showInitialTransform = CGAffineTransform(translationX: -32.0, y: 0.0)
                preferences.animating.showFinalTransform = CGAffineTransform(translationX: -8.0, y: 0.0)
                preferences.drawing.arrowPosition = .right
                EasyTipView.show(animated: true,
                                 forItem: self.newSiteButton,
                                 withinSuperview: self.view,
                                 text: "ブラウズを開始",
                                 preferences: preferences,
                                 delegate: self)
            }
        }
    }

}

// MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let bookmarks = bookmarks else { return 0 }
        return bookmarks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let bookmarks = bookmarks else { fatalError() }

        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeListCell")!

        cell.textLabel?.text = bookmarks[indexPath.row].url

        return cell
    }

}

// MARK: - UITableViewDelegate
extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let bookmarks = bookmarks else { fatalError() }

        tableView.deselectRow(at: indexPath, animated: true)

        let controller = WebBrowserController.navigationController(url: bookmarks[indexPath.row].url)
        present(controller, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let bookmarks = bookmarks else { fatalError() }

        return [
            UITableViewRowAction(style: .destructive,
                                 title: "削除",
                                 handler: { [weak self] (_, indexPath) in

                                    guard let `self` = self else { return }
                                    let bookmark = bookmarks[indexPath.row]

                                    // swiftlint:disable:next force_try
                                    let realm = try! Realm()
                                    // swiftlint:disable:next force_try
                                    try! realm.write {
                                        realm.delete(bookmark)
                                    }

                                    self.reload()
            })
        ]
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // swiftlint:disable:next force_try
        let realm = try! Realm()
        guard let originalBookmarks = bookmarks else { fatalError() }
        var tempBookmarks: [Bookmark] = []

        for bookmark in originalBookmarks {
            tempBookmarks.append(bookmark)
        }

        let movedBookmark = originalBookmarks[sourceIndexPath.row]
        tempBookmarks.remove(at: sourceIndexPath.row)
        tempBookmarks.insert(movedBookmark, at: destinationIndexPath.row)

        var index = 0

        // swiftlint:disable:next force_try
        try! realm.write {
            for bookmark in tempBookmarks {
                bookmark.order = index
                realm.add(bookmark, update: true)

                index += 1
            }
        }
    }

}

// MARK: - EasyTipViewDelegate
extension HomeViewController: EasyTipViewDelegate {

    func easyTipViewDidDismiss(_ tipView: EasyTipView) {
        UserDefaultsHandler.ShowedStartBrowseTooltip.set(true)
    }

}

// MARK: - Private
fileprivate extension HomeViewController {

    func configureUI() {
        navigationItem.leftBarButtonItem = settingsButton

        let editButton: UIBarButtonItem

        if tableView.isEditing {
            editButton = UIBarButtonItem(title: "完了", style: .done, target: nil, action: nil)
            editButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.reload()
                    self?.tableView.setEditing(false, animated: true)
                    self?.configureUI()
                })
                .addDisposableTo(disposeBag)
        } else {
            editButton = UIBarButtonItem(title: "編集", style: .plain, target: nil, action: nil)
            editButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.tableView.setEditing(true, animated: true)
                    self?.configureUI()
                })
                .addDisposableTo(disposeBag)
        }

        navigationItem.setRightBarButton(editButton, animated: true)
    }

    func reload() {
        // swiftlint:disable:next force_try
        let realm = try! Realm()
        bookmarks =  realm.objects(Bookmark.self).sorted(byKeyPath: "order")

        tableView.reloadData()
    }

    func addNewSite() {
        let controller = WebBrowserController.navigationController()
        present(controller, animated: true, completion: nil)
    }

    func showSettings() {
        let controller = SettingsViewController.controller()
        let nav = UINavigationController(rootViewController: controller)
        present(nav, animated: true, completion: nil)
    }
}
