//
//  SettingsViewController.swift
//  Pics
//
//  Created by Kenta on 6/22/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import RxSwift
import StoreKit
import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet fileprivate weak var enableMobileNetworkSwitch: UISwitch!

    fileprivate lazy var closeButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "閉じる",
                               style: .plain,
                               target: nil,
                               action: nil)
    }()

    let disposeBag = DisposeBag()

    class func controller() -> SettingsViewController {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        // swiftlint:disable:next force_cast
        return storyboard.instantiateInitialViewController() as! SettingsViewController
    }

}

// MARK: - View Lifecycles
extension SettingsViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "設定"
        enableMobileNetworkSwitch.isOn = UserDefaultsHandler.EnableMobileNetwork.get()

        closeButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .addDisposableTo(disposeBag)

        navigationItem.leftBarButtonItem = closeButton

        enableMobileNetworkSwitch.rx.value
            .subscribe(onNext: { value in
                UserDefaultsHandler.EnableMobileNetwork.set(value)
            })
            .addDisposableTo(disposeBag)
    }

}

// MARK: - UITableViewDelegate
extension SettingsViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 2 {
            if indexPath.row == 0 {
                // アプリを評価する
                let storeURL = "itms-apps://itunes.apple.com/app/id1249209151?action=write-review"
                guard let url = URL(string: storeURL) else {
                    fatalError("Maybe mistaked implementation.")
                }

                UIApplication.shared.open(url, options: [:])
            }
        }
    }

}
