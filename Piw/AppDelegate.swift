//
//  AppDelegate.swift
//  Pics
//
//  Created by Kenta on 2017/06/08.
//  Copyright © 2017 UROURO. All rights reserved.
//

import Crashlytics
import EasyTipView
import Fabric
import FirebaseCore
import GoogleMobileAds
import SwiftyBeaver
import UIKit
import RealmSwift
import WebKit

let log = SwiftyBeaver.self
let processPool = WKProcessPool()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let console = ConsoleDestination()
        log.addDestination(console)

        setUpFabric()
        setUpAppearance()
        setUpRealm()
        setUpGoogleMobileAds()

        return true
    }

}

// MARK: - Private
fileprivate extension AppDelegate {

    func setUpAppearance() {
        UINavigationBar.appearance().tintColor = UIColor.app.theme
        UIToolbar.appearance().tintColor = UIColor.app.theme

        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = UIFont.systemFont(ofSize: 18.0)
        preferences.drawing.foregroundColor = UIColor.white
        preferences.drawing.backgroundColor = UIColor.black
        EasyTipView.globalPreferences = preferences
    }

    func setUpRealm() {
        let directory = documentDirectoryURL().appendingPathComponent(".realm")

        do {
            try FileManager.default.createDirectory(at: directory,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            log.warning("\(error)")
        }

        let fileURL = directory.appendingPathComponent("default.realm")
        let config = Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: 5,
            migrationBlock: { migration, oldSchemaVersion in
                // swiftlint:disable control_statement
                if (oldSchemaVersion < 2) {
                    migration.enumerateObjects(ofType: IgnoreURL.className()) { _, newObject in
                        newObject!["type"] = IgnoreURL.URLType.Full
                    }
                }
                if (oldSchemaVersion < 4) {
                    migration.enumerateObjects(ofType: Bookmark.className()) { _, newObject in
                        newObject!["order"] = 0
                    }
                }
                if (oldSchemaVersion < 5) {
                    migration.enumerateObjects(ofType: Bookmark.className()) { _, newObject in
                        newObject!["bookmarkID"] = UUID().uuidString
                    }
                }
                // swiftlint:enable control_statement
        })
        Realm.Configuration.defaultConfiguration = config
    }

    func setUpGoogleMobileAds() {
        GADMobileAds.configure(withApplicationID: AppConfig.AdMob.applicationId)
    }

    func setUpFabric() {
        Fabric.with([Crashlytics.self])
    }

    func setUpFirebase() {
        FirebaseApp.configure()
    }

}
