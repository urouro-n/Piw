//
//  IgnoredListViewController.swift
//  Pics
//
//  Created by Kenta on 7/5/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import RealmSwift
import RxSwift
import UIKit

class IgnoredListViewController: UIViewController {

    @IBOutlet fileprivate weak var tableView: UITableView!

    var ignoreURLs: Results<IgnoreURL>?
    var ignoreDomains: Results<IgnoreURL>?

    fileprivate let disposeBag: DisposeBag = DisposeBag()

}

// MARK: - View Lifecycles
extension IgnoredListViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "非表示リスト"

        configureUI()
        reload()
    }

}

// MARK: - UITableViewDataSource
extension IgnoredListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let ignoreURLs = ignoreURLs, let ignoreDomains = ignoreDomains else { fatalError() }

        if section == 0 {
            return ignoreURLs.count
        } else {
            return ignoreDomains.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "非表示にした画像"
        } else {
            return "非表示にしたドメイン"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let ignoreURLs = ignoreURLs, let ignoreDomains = ignoreDomains else { fatalError() }

        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "IgnoredListCell") as! IgnoredListCell

        if indexPath.section == 0 {
            let ignoreURL = ignoreURLs[indexPath.row]
            cell.urlLabel.text = ignoreURL.url
            return cell
        } else {
            let ignoreDomain = ignoreDomains[indexPath.row]
            cell.urlLabel.text = ignoreDomain.url
            return cell
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return tableView.isEditing
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let ignoreURLs = ignoreURLs, let ignoreDomains = ignoreDomains else { fatalError() }

        return [
            UITableViewRowAction(style: .destructive, title: "削除", handler: { [unowned self] (action, indexPath) in
                log.debug("action=\(action), indexPath=\(indexPath)")

                // swiftlint:disable:next force_try
                let realm = try! Realm()

                if indexPath.section == 0 {
                    let ignoreURL = ignoreURLs[indexPath.row]

                    // swiftlint:disable:next force_try
                    try! realm.write {
                        realm.delete(ignoreURL)
                    }
                } else {
                    let ignoreDomain = ignoreDomains[indexPath.row]

                    // swiftlint:disable:next force_try
                    try! realm.write {
                        realm.delete(ignoreDomain)
                    }
                }

                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            })
        ]
    }

}

// MARK: - UITableViewDelegate
extension IgnoredListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }

}

// MARK: - Private
fileprivate extension IgnoredListViewController {

    func reload() {
        // swiftlint:disable:next force_try
        let realm = try! Realm()

        let urlPredicate = NSPredicate(format: "type = %d", IgnoreURL.URLType.Full)
        ignoreURLs = realm.objects(IgnoreURL.self).filter(urlPredicate).sorted(byKeyPath: "url")

        let domainPredicate = NSPredicate(format: "type = %d", IgnoreURL.URLType.Domain)
        ignoreDomains = realm.objects(IgnoreURL.self).filter(domainPredicate).sorted(byKeyPath: "url")

        tableView.reloadData()
    }

    func configureUI() {
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

}
